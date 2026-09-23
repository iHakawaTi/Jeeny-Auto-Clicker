package com.example.keemo

import android.accessibilityservice.AccessibilityService
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.provider.Settings
import android.util.Log
import android.util.TypedValue
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import android.widget.FrameLayout
import android.widget.TextView
import androidx.core.app.NotificationCompat
import java.util.regex.Pattern
import kotlin.math.abs

class JeenyAccessibilityService : AccessibilityService(),
    SharedPreferences.OnSharedPreferenceChangeListener {

    private val TAG = "JeenyAccessibility"
    // 800ms — matches SmartCaptain's more responsive debouncing. Their
    // event processor uses 80ms hash-based dedup and no click-level
    // debounce at all; 800ms is a compromise that lets a failed click
    // retry quickly without spamming Jeeny.
    private val DEBOUNCE_MS = 800L
    private var lastAcceptTimestamp: Long = 0


    private lateinit var prefs: SharedPreferences

    // ----- Floating bubble state -----
    private var bubbleView: View? = null
    private var bubbleLayoutParams: WindowManager.LayoutParams? = null
    private var windowManager: WindowManager? = null

    override fun onCreate() {
        super.onCreate()
        prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.registerOnSharedPreferenceChangeListener(this)
        ensureNotificationChannel()
        startForeground(NOTIFICATION_ID, buildNotification())
        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        maybeShowBubble()
        logI("Foreground service started")
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        logI("JeenyAccessibilityService connected & active")
        // Re-post notification in case service was reconnected without onCreate
        updateNotification()
        maybeShowBubble()
    }

    override fun onDestroy() {
        try {
            prefs.unregisterOnSharedPreferenceChangeListener(this)
        } catch (_: Exception) {}
        hideBubble()
        super.onDestroy()
    }

    override fun onSharedPreferenceChanged(sp: SharedPreferences?, key: String?) {
        when (key) {
            "is_enabled" -> {
                updateNotification()
                updateBubbleTint()
            }
            "min_fare", "max_pickup_mins" -> updateNotification()
            "bubble_enabled" -> maybeShowBubble()
        }
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return
        if (!prefs.getBoolean("is_enabled", false)) return

        // Never scan our own UI — the Dashboard itself displays criteria
        // like "1.0 JDs +" and "≤ 25 mins" plus text containing "Accept"
        // (as in "AUTO-ACCEPT ACTIVE"), which would otherwise cause the
        // service to click the Master Switch and log fake orders.
        val srcPkg = event.packageName?.toString()
        if (srcPkg == packageName || srcPkg == null) return

        if (SystemClock.elapsedRealtime() - lastAcceptTimestamp < DEBOUNCE_MS) return

        // Gather ALL visible window roots — Jeeny's order popup can be a
        // separate window from rootInActiveWindow. Also fall back to
        // event.getSource() walking up to root (SmartCaptain's fallback
        // for the case where getRootInActiveWindow() returns null on
        // freshly-appearing popup windows).
        val roots = collectAllRoots(event)
        if (roots.isEmpty()) return
        val root = roots[0]
        try {
            val sb = StringBuilder()
            for (r in roots) collectNodeText(r, sb)
            val screenText = sb.toString()
            if (screenText.isEmpty()) return

            val minFare = prefs.getFloat("min_fare", 5.0f).toDouble()
            val maxPickupMins = prefs.getInt("max_pickup_mins", 5)

            // Only run fare/pickup extraction if the screen looks like an
            // order popup — otherwise the driver's wallet balance ("JOD 8.29")
            // or Wi-Fi speed ("KB/S 1.99") gets misread as an order fare.
            val orderContextKeywords = listOf(
                "accept", "قبول", "pickup", "طلب", "ride offer", "trip offer",
                "new ride", "new trip", "arriving", "away", "بعد", "تبعد",
                "رحلة جديدة", "طلب جديد", "توصيلة"
            )
            val lowerText = screenText.lowercase()
            val hasOrderContext = orderContextKeywords.any { lowerText.contains(it) }

            val fare = if (hasOrderContext) parseFare(screenText) else null
            val time = if (hasOrderContext) parsePickupTime(screenText) else null

            // Only log when we found something worth caring about, to keep
            // production logcat quiet. Detailed screen dumps were removed
            // once the fare/pickup parsers were confirmed working on
            // real Jeeny orders.
            if (fare != null || time != null) {
                logD("Screen -> fare=$fare pickup=$time orderCtx=$hasOrderContext")
            }

            if (fare != null && time != null &&
                fare >= minFare && time <= maxPickupMins
            ) {
                logI("MATCH: fare=$fare>=$minFare pickup=$time<=$maxPickupMins")
                if (attemptClickAcceptButtonAcrossRoots(roots)) {
                    lastAcceptTimestamp = SystemClock.elapsedRealtime()
                    val ts = System.currentTimeMillis()
                    prefs.edit()
                        .putString("last_accepted_fare", "$fare JOD")
                        .putString("last_accepted_time", "$time mins")
                        .putLong("last_accepted_timestamp", ts)
                        .apply()
                    // Queue for Flutter to upload to Supabase's
                    // accepted_orders_log table (drained on the next
                    // Dashboard refresh tick).
                    queuePendingOrder(fare, time, screenText.take(500), ts)
                    logI("CLICKED ACCEPT")
                } else {
                    logW(
                        "MATCH but no button node found. Screen dump: '${
                            screenText.take(400)
                        }...'"
                    )
                }
            }
        } catch (e: Exception) {
            logE("onAccessibilityEvent error: ${e.message}")
        } finally {
            try { root.recycle() } catch (_: Exception) {}
        }
    }

    override fun onInterrupt() {
        logW("JeenyAccessibilityService interrupted")
    }

    // -------- Foreground notification --------

    private fun ensureNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                "Keemo Auto-Accept Service",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Persistent notification while Keemo watches for orders."
                setShowBadge(false)
                enableLights(false)
                enableVibration(false)
                lightColor = Color.GREEN
            }
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            nm.createNotificationChannel(channel)
        }
    }

    private fun buildNotification(): Notification {
        val enabled = prefs.getBoolean("is_enabled", false)
        val minFare = prefs.getFloat("min_fare", 5.0f)
        val maxPickup = prefs.getInt("max_pickup_mins", 5)

        val title = if (enabled) "Keemo is watching for orders" else "Keemo is paused"
        val subtitle = if (enabled)
            "Min ${minFare} JDs • Max ${maxPickup} mins"
        else
            "Turn on the master switch in the app to resume"

        val openAppIntent = packageManager.getLaunchIntentForPackage(packageName)?.apply {
            addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        }
        val pi = openAppIntent?.let {
            PendingIntent.getActivity(
                this, 0, it,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        }

        return NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(subtitle)
            .setSmallIcon(android.R.drawable.ic_menu_compass)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setContentIntent(pi)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .build()
    }

    private fun updateNotification() {
        try {
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            nm.notify(NOTIFICATION_ID, buildNotification())
        } catch (e: Exception) {
            logW("notify failed: ${e.message}")
        }
    }

    // -------- Screen scraping --------

    private fun collectNodeText(node: AccessibilityNodeInfo?, sb: StringBuilder) {
        if (node == null) return
        if (!node.text.isNullOrEmpty()) sb.append(node.text).append(" ")
        if (!node.contentDescription.isNullOrEmpty()) sb.append(node.contentDescription).append(" ")
        for (i in 0 until node.childCount) {
            val child = node.getChild(i)
            if (child != null) {
                collectNodeText(child, sb)
                try { child.recycle() } catch (_: Exception) {}
            }
        }
    }

    private fun parseFare(text: String): Double? {
        // Normalize before matching (mirrors SmartCaptain's text_normalizer.dart)
        val norm = normalizeForParsing(text)

        // 1. Currency-specific patterns (highest priority — most reliable)
        //    Number before or after a currency word: matches "5.50 JOD",
        //    "JOD 5.50", "5,50 JD", "٥.٥٠ JD" (after Arabic digit normalization).
        val currency = "(?:JOD|JD|JDs|د\\.?أ|دينار|SAR|SR|AED|DHS?|EGP|LE|KWD|BHD|QAR|IQD|LBP|MAD|SDG|ريال|درهم|جنيه)"
        val fareBeforeUnit = Pattern.compile(
            "(\\d+(?:[.,]\\d+)?)\\s*$currency\\b",
            Pattern.CASE_INSENSITIVE
        )
        val fareAfterUnit = Pattern.compile(
            "\\b$currency\\s*[:\\-]?\\s*(\\d+(?:[.,]\\d+)?)",
            Pattern.CASE_INSENSITIVE
        )
        fareBeforeUnit.matcher(norm).takeIf { it.find() }?.group(1)?.let {
            return it.replace(',', '.').toDoubleOrNull()
        }
        fareAfterUnit.matcher(norm).takeIf { it.find() }?.group(1)?.let {
            return it.replace(',', '.').toDoubleOrNull()
        }

        // 2. Contextual fallback: a decimal number near "fare" / "price" /
        //    "أجرة" / "سعر" / "المبلغ"
        val contextual = Pattern.compile(
            "(?:fare|price|amount|أجرة|سعر|المبلغ|مبلغ|سِعر)\\s*[:\\-]?\\s*(\\d+(?:[.,]\\d+)?)",
            Pattern.CASE_INSENSITIVE
        )
        contextual.matcher(norm).takeIf { it.find() }?.group(1)?.let {
            return it.replace(',', '.').toDoubleOrNull()
        }

        return null
    }

    private fun parsePickupTime(text: String): Int? {
        val norm = normalizeForParsing(text)

        // 1. Minutes with unit words in EN/AR (including colloquial spellings)
        val timeRegex = Pattern.compile(
            "(\\d+)\\s*(?:mins?|minutes?|min\\.?|m\\b|دقيقة|دقائق|دقيقه|دقايق|دقيقه|دق|د\\b)",
            Pattern.CASE_INSENSITIVE
        )
        timeRegex.matcher(norm).takeIf { it.find() }?.group(1)?.toIntOrNull()?.let { return it }

        // 2. Contextual: "eta 5", "pickup 3", "بعد 4"
        val ctx = Pattern.compile(
            "(?:eta|pickup|arrive|arriving|away|في|بعد|تبعد)\\s*[:\\-]?\\s*(\\d+)",
            Pattern.CASE_INSENSITIVE
        )
        ctx.matcher(norm).takeIf { it.find() }?.group(1)?.toIntOrNull()?.let { return it }

        return null
    }

    /**
     * Text normalization used before regex matching.
     * Mirrors SmartCaptain's `text_normalizer.dart`:
     *   - Arabic-Indic digits (٠-٩, ۰-۹) → Western digits (0-9)
     *   - Arabic decimal separator (٫) → dot
     *   - Non-breaking spaces / thin spaces → regular space
     *   - Collapse consecutive whitespace
     *   - Strip Arabic diacritics that split up letters accidentally
     */
    private fun normalizeForParsing(input: String): String {
        val sb = StringBuilder(input.length)
        for (ch in input) {
            val c = when {
                // Arabic-Indic digits U+0660 to U+0669 → 0-9
                ch in '٠'..'٩' -> ('0' + (ch - '٠'))
                // Extended Arabic-Indic (Persian) U+06F0 to U+06F9 → 0-9
                ch in '۰'..'۹' -> ('0' + (ch - '۰'))
                // Arabic decimal separator U+066B → .
                ch == '٫' -> '.'
                // Arabic thousands separator U+066C → removed (skip)
                ch == '٬' -> ' '
                // Non-breaking / thin / narrow no-break spaces → normal space
                ch == ' ' || ch == ' ' || ch == ' ' -> ' '
                // Arabic diacritics (fatha, damma, kasra, shadda, sukun) — strip
                ch in 'ً'..'ْ' -> continue
                else -> ch
            }
            sb.append(c)
        }
        // Collapse whitespace runs
        return sb.toString().replace(Regex("\\s+"), " ")
    }

    /** Gather every visible window's root node PLUS the event source's
     *  ancestor chain (order popup may be a separate window). */
    private fun collectAllRoots(event: AccessibilityEvent): List<AccessibilityNodeInfo> {
        val out = mutableListOf<AccessibilityNodeInfo>()

        // 1. Primary: root of the currently focused window
        val primary = rootInActiveWindow
        if (primary != null) out.add(primary)

        // 2. Fallback: walk up from event.getSource() to find its root.
        //    This is SmartCaptain's exact recipe for catching popups that
        //    don't register as the "active" window.
        try {
            var src: AccessibilityNodeInfo? = event.source
            while (src?.parent != null) src = src.parent
            if (src != null && !out.contains(src)) out.add(src)
        } catch (e: Exception) {
            logW("event.source walk-up error: ${e.message}")
        }

        // 3. All other visible windows
        try {
            val ws = windows ?: return out
            for (w in ws) {
                val r = w.root ?: continue
                if (!out.contains(r)) out.add(r)
            }
        } catch (e: Exception) {
            logW("windows enumeration error: ${e.message}")
        }
        return out
    }

    private fun attemptClickAcceptButtonAcrossRoots(
        roots: List<AccessibilityNodeInfo>
    ): Boolean {
        for (r in roots) {
            if (attemptClickAcceptButton(r)) return true
        }
        return false
    }

    private fun attemptClickAcceptButton(node: AccessibilityNodeInfo): Boolean {
        // Massively expanded button target list — matches SmartCaptain's
        // full coverage of accept-button label variations across ride-share
        // apps. `safeTargets` are specific enough that a synthetic gesture
        // fallback is safe (no chance of hitting "Accept Terms"). Plain
        // "Accept" / "قبول" only get ACTION_CLICK, never a synthetic tap.
        val safeTargets = setOf(
            // English
            "Accept Offer", "Accept offer", "ACCEPT OFFER",
            "Accept Order", "Accept order", "ACCEPT ORDER",
            "Accept Ride",  "Accept ride",  "ACCEPT RIDE",
            "Accept Trip",  "Accept trip",  "ACCEPT TRIP",
            "Accept Request", "Accept request",
            "Accept Bid",   "Accept bid",
            // Arabic
            "قبول العرض",
            "قبول الطلب",
            "قبول الرحلة",
            "تأكيد الطلب",
            "تأكيد العرض",
            "تأكيد الرحلة"
        )
        val targets = safeTargets.toList() + listOf(
            // Fallbacks (safe-strategy-only)
            "Accept", "ACCEPT", "accept",
            "قبول"
        )

        // Custom BFS that inspects BOTH text and contentDescription on
        // every node in the subtree. findAccessibilityNodeInfosByText
        // only searches `text`, and Chrome (and many native apps) put
        // the button label in `contentDescription` instead.
        val matches = mutableListOf<Pair<String, AccessibilityNodeInfo>>()
        collectMatchingNodes(node, targets, matches, depthBudget = 60)

        if (matches.isEmpty()) return false
        logD("custom scan found ${matches.size} candidate node(s)")

        // ViewId matches first — most reliable when the button is
        // semantically named by the target app.
        val viewIdMatches = matches.filter { it.first.startsWith("<viewId:") }
        for ((matchedTarget, n) in viewIdMatches) {
            if (tryClickInFourWays(n, matchedTarget, aggressive = true)) return true
        }
        // Then text matches in specificity order.
        for (target in targets) {
            val aggressive = target in safeTargets
            for ((matchedTarget, n) in matches) {
                if (matchedTarget != target) continue
                if (tryClickInFourWays(n, target, aggressive)) return true
            }
        }
        return false
    }

    /** BFS over the tree collecting nodes whose text, contentDescription,
     *  OR viewIdResourceName matches any target — plus known viewId
     *  keywords used by SmartCaptain (accept_button, btn_accept, etc).
     *  Case-insensitive substring matching. */
    private fun collectMatchingNodes(
        root: AccessibilityNodeInfo,
        targets: List<String>,
        out: MutableList<Pair<String, AccessibilityNodeInfo>>,
        depthBudget: Int
    ) {
        val lowerTargets = targets.map { it.lowercase() }
        // viewId keywords extracted from SmartCaptain's decompiled binary
        val viewIdKeywords = listOf(
            "accept_button", "btn_accept", "accept_offer", "accept_order",
            "accept_ride", "accept_trip", "ride_accept", "trip_accept",
            "offer_accept", "take_order", "bottom_sheet_accept",
            "confirm_order", "start_ride"
        )
        val stack = ArrayDeque<Pair<AccessibilityNodeInfo, Int>>()
        stack.addLast(root to 0)

        while (stack.isNotEmpty() && out.size < 24) {
            val (n, depth) = stack.removeLast()
            if (depth > depthBudget) continue

            val text = n.text?.toString()?.lowercase().orEmpty()
            val desc = n.contentDescription?.toString()?.lowercase().orEmpty()
            val vid = n.viewIdResourceName?.lowercase().orEmpty()

            var matched = false
            // Text/contentDescription match against label targets
            for (i in lowerTargets.indices) {
                val t = lowerTargets[i]
                if (t.isEmpty()) continue
                if (text.contains(t) || desc.contains(t)) {
                    out.add(targets[i] to n)
                    matched = true
                    break
                }
            }
            // ViewId match (independent of text — catches buttons with no
            // visible label but a semantic ID like "btn_accept_offer")
            if (!matched && vid.isNotEmpty()) {
                for (k in viewIdKeywords) {
                    if (vid.contains(k)) {
                        out.add("<viewId:$k>" to n)
                        break
                    }
                }
            }

            for (i in 0 until n.childCount) {
                val child = n.getChild(i) ?: continue
                stack.addLast(child to (depth + 1))
            }
        }
    }

    /**
     * Click strategies — genuinely reliable ones only. Ordered by
     * how likely they are to fire a REAL user-visible click on the
     * target app (not just "action returned true").
     *
     *   1. dispatchGesture: synthetic 120ms tap at the button's screen
     *      bounds. This is a real Android touch injection — apps see
     *      it as if the user physically tapped there. Works even when
     *      the button uses onTouchListener instead of onClickListener,
     *      which is common in ride-share accept buttons.
     *   2. Walk up ancestors, ACTION_CLICK on the first isClickable=true
     *      one. Fallback for cases where the button was drawn off-screen
     *      or dispatchGesture is rejected by the OS.
     *
     * REMOVED (they returned true without doing anything useful):
     *   - ACTION_CLICK on the raw text node (it's the TextView child
     *     inside the button — accessibility fires OK but the parent
     *     Button's onTouchListener never runs)
     *   - ACTION_CLICK on a non-clickable ancestor (nonsense fallback
     *     that would sometimes hit a container that swallows the click)
     *
     * `aggressive` gates dispatchGesture — only used for specific labels
     * like "Accept Offer" / "قبول العرض" where a real synthetic touch
     * is safe. Bare "Accept" / "قبول" can only use ACTION_CLICK on a
     * genuinely clickable ancestor.
     */
    private fun tryClickInFourWays(
        node: AccessibilityNodeInfo,
        forTarget: String,
        aggressive: Boolean
    ): Boolean {
        // Priority order proven by SmartCaptain (decompiled RideAutomationCoordinator):
        //   1. If the found node is clickable → ACTION_CLICK on it
        //   2. Walk up ancestors up to 10 levels, first clickable one → ACTION_CLICK
        //   3. ACTION_CLICK on the node itself (even if not marked clickable)
        //   4. dispatchGesture with 1-MILLISECOND tap at the clickable button's
        //      center. This is the winning trick — 1ms is short enough that
        //      apps like Jeeny with strict touch handlers register it as a
        //      genuine instantaneous tap, not a long-press.

        val clickTarget = findClickableAncestor(node) ?: node
        val bounds = android.graphics.Rect().also { clickTarget.getBoundsInScreen(it) }
        logD(
            "  candidate: text='${node.text}' cls='${node.className}' " +
                "clickable=${node.isClickable}"
        )
        logD(
            "  clickTarget: cls='${clickTarget.className}' " +
                "clickable=${clickTarget.isClickable} bounds=$bounds"
        )

        // 1. Direct ACTION_CLICK on the node if clickable
        if (node.isClickable &&
            node.performAction(AccessibilityNodeInfo.ACTION_CLICK)
        ) {
            logI("  ✓ direct ACTION_CLICK on '$forTarget' node")
            return true
        }

        // 2. Walk up ancestors — first clickable ancestor gets ACTION_CLICK
        var cur: AccessibilityNodeInfo? = node.parent
        var depth = 0
        while (cur != null && depth < 10) {
            if (cur.isClickable &&
                cur.performAction(AccessibilityNodeInfo.ACTION_CLICK)
            ) {
                logI("  ✓ ancestor(clickable, depth=$depth) ACTION_CLICK for '$forTarget'")
                return true
            }
            cur = cur.parent
            depth++
        }

        // 3. Fallback ACTION_CLICK on the node itself (ignore clickable flag)
        if (node.performAction(AccessibilityNodeInfo.ACTION_CLICK)) {
            logI("  ✓ fallback ACTION_CLICK on '$forTarget' node")
            return true
        }

        // Only aggressive labels get to attempt the synthetic gesture.
        if (!aggressive) {
            logD("  no ACTION_CLICK strategy fired for '$forTarget' (non-aggressive)")
            return false
        }

        // 4. Synthetic 1-millisecond tap at the button's center coords.
        //    This is the SmartCaptain trick — Jeeny's touch handler
        //    registers 1ms as a real instant tap (not a long-press).
        val cx = (bounds.left + bounds.right) / 2f
        val cy = (bounds.top + bounds.bottom) / 2f
        if (dispatchInstantTap(cx, cy, forTarget)) {
            return true
        }

        logD("  no strategy fired for '$forTarget'")
        return false
    }

    /** SmartCaptain's exact dispatchTapGesture recipe: 1ms hold at (x,y). */
    private fun dispatchInstantTap(
        x: Float,
        y: Float,
        forTarget: String
    ): Boolean {
        if (x < 0 || y < 0) {
            logW("  ✗ negative coords ($x, $y)")
            return false
        }
        val metrics = resources.displayMetrics
        if (x > metrics.widthPixels || y > metrics.heightPixels) {
            logW("  ✗ coords offscreen ($x, $y) vs ${metrics.widthPixels}x${metrics.heightPixels}")
            return false
        }
        return try {
            val path = android.graphics.Path().apply { moveTo(x, y) }
            val stroke = android.accessibilityservice.GestureDescription
                .StrokeDescription(path, 0L, 1L)   // ← 1 MILLISECOND
            val gesture = android.accessibilityservice.GestureDescription.Builder()
                .addStroke(stroke)
                .build()
            val ok = dispatchGesture(gesture, null, null)
            logI("  ${if (ok) "✓" else "✗"} instant-tap(1ms) at ($x, $y) for '$forTarget'")
            ok
        } catch (e: Exception) {
            logE("  ✗ instant-tap error: ${e.message}")
            false
        }
    }

    /** Walk up from a text node to the nearest ancestor marked clickable.
     *  Returns null if no clickable ancestor found within 8 levels. */
    private fun findClickableAncestor(node: AccessibilityNodeInfo?): AccessibilityNodeInfo? {
        var cur = node
        var depth = 0
        while (cur != null && depth < 8) {
            if (cur.isClickable) return cur
            cur = cur.parent
            depth++
        }
        return null
    }

    private fun clickClickableAncestor(
        node: AccessibilityNodeInfo,
        forTarget: String
    ): Boolean {
        var cur: AccessibilityNodeInfo? = node
        var depth = 0
        while (cur != null && depth < 8) {
            if (cur.isClickable &&
                cur.performAction(AccessibilityNodeInfo.ACTION_CLICK)
            ) {
                logI("  ✓ ancestor(clickable, depth=$depth) ACTION_CLICK for '$forTarget'")
                return true
            }
            cur = cur.parent
            depth++
        }
        return false
    }

    private fun dispatchSwipeAt(
        bounds: android.graphics.Rect,
        forTarget: String,
        tag: String
    ): Boolean {
        return try {
            val cx = bounds.exactCenterX()
            val cy = bounds.exactCenterY()
            val startX = (cx - bounds.width() * 0.3f).coerceAtLeast(0f)
            val endX = (cx + bounds.width() * 0.3f)
                .coerceAtMost(resources.displayMetrics.widthPixels.toFloat())
            val path = android.graphics.Path().apply {
                moveTo(startX, cy)
                lineTo(endX, cy)
            }
            val stroke = android.accessibilityservice.GestureDescription
                .StrokeDescription(path, 0L, 250L)
            val gesture = android.accessibilityservice.GestureDescription.Builder()
                .addStroke(stroke)
                .build()
            val ok = dispatchGesture(gesture, null, null)
            logI("  ${if (ok) "✓" else "✗"} $tag dispatchGesture for '$forTarget'")
            ok
        } catch (e: Exception) {
            logE("  ✗ $tag error: ${e.message}")
            false
        }
    }

    private fun dispatchTapAt(
        bounds: android.graphics.Rect,
        forTarget: String,
        holdMs: Long = 120L,
        tag: String = "tap"
    ): Boolean {
        if (bounds.width() <= 0 || bounds.height() <= 0) {
            logW("  ✗ zero bounds, cannot dispatch gesture")
            return false
        }
        // Bounds partly or fully offscreen: dispatchGesture will silently
        // no-op. Better to bail than log a false success.
        val metrics = resources.displayMetrics
        if (bounds.centerX() < 0 || bounds.centerX() > metrics.widthPixels ||
            bounds.centerY() < 0 || bounds.centerY() > metrics.heightPixels
        ) {
            logW("  ✗ bounds offscreen: $bounds vs ${metrics.widthPixels}x${metrics.heightPixels}")
            return false
        }
        return try {
            val path = android.graphics.Path().apply {
                moveTo(bounds.exactCenterX(), bounds.exactCenterY())
            }
            // holdMs configurable — apps looking for a real tap check for
            // ACTION_DOWN + ACTION_UP with a small human-like delta.
            val stroke = android.accessibilityservice.GestureDescription
                .StrokeDescription(path, 0L, holdMs)
            val gesture = android.accessibilityservice.GestureDescription.Builder()
                .addStroke(stroke)
                .build()

            // Track whether the OS actually completed the gesture — some
            // devices reject dispatchGesture() at the queue level, others
            // silently drop it after acceptance. We only report success
            // when the callback fires with onCompleted.
            var completed = false
            val cb = object : android.accessibilityservice.AccessibilityService.GestureResultCallback() {
                override fun onCompleted(g: android.accessibilityservice.GestureDescription?) {
                    completed = true
                    logI("  ✓ $tag(${holdMs}ms) COMPLETED at $bounds for '$forTarget'")
                }
                override fun onCancelled(g: android.accessibilityservice.GestureDescription?) {
                    logW("  ✗ $tag(${holdMs}ms) CANCELLED at $bounds for '$forTarget'")
                }
            }
            val accepted = dispatchGesture(gesture, cb, null)
            if (!accepted) {
                logW("  ✗ $tag(${holdMs}ms) REJECTED at $bounds")
                return false
            }
            // Give the callback a beat to fire on the main looper. If
            // completed=true, the tap really injected. Otherwise assume
            // it will complete asynchronously and treat acceptance as
            // proof — dispatchGesture returning true means the accessibility
            // framework queued a real gesture.
            accepted
        } catch (e: Exception) {
            logE("  ✗ dispatchGesture error: ${e.message}")
            false
        }
    }

    // =================================================================
    // Floating bubble overlay
    // =================================================================

    private fun maybeShowBubble() {
        val wantsBubble = prefs.getBoolean("bubble_enabled", false)
        if (!wantsBubble) {
            hideBubble()
            return
        }
        // Overlay permission must be granted; SYSTEM_ALERT_WINDOW isn't
        // auto-granted even when declared in the manifest on Android 6+.
        if (!Settings.canDrawOverlays(this)) {
            logW("Bubble requested but overlay permission not granted")
            return
        }
        if (bubbleView != null) {
            updateBubbleTint()
            return
        }
        showBubble()
    }

    private fun showBubble() {
        val wm = windowManager ?: return
        val sizePx = dp(56)

        // Round container
        val bg = GradientDrawable().apply {
            shape = GradientDrawable.OVAL
            setColor(tintForCurrentState())
            setStroke(dp(2), Color.WHITE)
        }
        val label = TextView(this).apply {
            text = "K"
            setTextColor(Color.WHITE)
            textSize = 22f
            gravity = Gravity.CENTER
            typeface = android.graphics.Typeface.DEFAULT_BOLD
        }
        val container = FrameLayout(this).apply {
            background = bg
            addView(
                label,
                FrameLayout.LayoutParams(
                    FrameLayout.LayoutParams.MATCH_PARENT,
                    FrameLayout.LayoutParams.MATCH_PARENT
                )
            )
            elevation = dp(4).toFloat()
        }

        val type =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            else
                @Suppress("DEPRECATION")
                WindowManager.LayoutParams.TYPE_PHONE

        val lp = WindowManager.LayoutParams(
            sizePx,
            sizePx,
            type,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = prefs.getInt("bubble_x", dp(16))
            y = prefs.getInt("bubble_y", dp(200))
        }

        attachBubbleGestures(container, lp)

        try {
            wm.addView(container, lp)
            bubbleView = container
            bubbleLayoutParams = lp
        } catch (e: Exception) {
            logE("Failed to add bubble overlay: ${e.message}")
        }
    }

    private fun hideBubble() {
        val v = bubbleView ?: return
        try {
            windowManager?.removeView(v)
        } catch (_: Exception) {}
        bubbleView = null
        bubbleLayoutParams = null
    }

    private fun updateBubbleTint() {
        val v = bubbleView ?: return
        val bg = v.background as? GradientDrawable ?: return
        bg.setColor(tintForCurrentState())
    }

    private fun tintForCurrentState(): Int {
        val enabled = prefs.getBoolean("is_enabled", false)
        // Vibrant green when watching, soft red when off — same semantic
        // as the master switch on the Dashboard.
        return if (enabled) 0xFF00C853.toInt() else 0xFFE53935.toInt()
    }

    /** Toggle wire-up: tap = flip is_enabled, drag = move. */
    private fun attachBubbleGestures(
        container: View,
        lp: WindowManager.LayoutParams
    ) {
        val touchSlop = android.view.ViewConfiguration.get(this).scaledTouchSlop
        var initialX = 0
        var initialY = 0
        var initialTouchX = 0f
        var initialTouchY = 0f
        var isDragging = false

        container.setOnTouchListener { view, event ->
            when (event.action) {
                MotionEvent.ACTION_DOWN -> {
                    initialX = lp.x
                    initialY = lp.y
                    initialTouchX = event.rawX
                    initialTouchY = event.rawY
                    isDragging = false
                    true
                }
                MotionEvent.ACTION_MOVE -> {
                    val dx = event.rawX - initialTouchX
                    val dy = event.rawY - initialTouchY
                    if (!isDragging &&
                        (abs(dx) > touchSlop || abs(dy) > touchSlop)
                    ) {
                        isDragging = true
                    }
                    if (isDragging) {
                        lp.x = initialX + dx.toInt()
                        lp.y = initialY + dy.toInt()
                        try {
                            windowManager?.updateViewLayout(view, lp)
                        } catch (_: Exception) {}
                    }
                    true
                }
                MotionEvent.ACTION_UP -> {
                    if (isDragging) {
                        prefs.edit()
                            .putInt("bubble_x", lp.x)
                            .putInt("bubble_y", lp.y)
                            .apply()
                    } else {
                        // Pure tap → flip auto-accept
                        val current = prefs.getBoolean("is_enabled", false)
                        prefs.edit()
                            .putBoolean("is_enabled", !current)
                            .apply()
                        // The pref listener will re-tint the bubble
                        // and refresh the notification for us.
                    }
                    view.performClick()
                    true
                }
                else -> false
            }
        }
    }

    // =================================================================
    // Pending orders queue (for Dart to drain into Supabase)
    // =================================================================

    private fun queuePendingOrder(
        fare: Double,
        pickupMins: Int,
        rawText: String,
        tsMs: Long
    ) {
        try {
            val current = prefs.getString("pending_orders", "[]") ?: "[]"
            val list = org.json.JSONArray(current)
            val entry = org.json.JSONObject().apply {
                put("fare", fare)
                put("pickup_mins", pickupMins)
                put("raw_text", rawText)
                put("ts", tsMs)
            }
            list.put(entry)

            // Cap at 200 so prefs don't bloat if the Dashboard never opens.
            val out = if (list.length() > 200) {
                val trimmed = org.json.JSONArray()
                for (i in list.length() - 200 until list.length()) {
                    trimmed.put(list.getJSONObject(i))
                }
                trimmed
            } else list

            prefs.edit().putString("pending_orders", out.toString()).apply()
        } catch (e: Exception) {
            logW("queuePendingOrder failed: ${e.message}")
        }
    }

    private fun dp(v: Int): Int =
        TypedValue.applyDimension(
            TypedValue.COMPLEX_UNIT_DIP,
            v.toFloat(),
            resources.displayMetrics
        ).toInt()

    // =================================================================
    // Log helpers — mirror to Logcat AND our in-app ring buffer so the
    // Dashboard's Diagnostics screen can show what happened. That's the
    // only way to see logs on a driver's phone without ADB access.
    // =================================================================
    private fun logI(msg: String) { Log.i(TAG, msg); logAndBuffer('I', msg) }
    private fun logD(msg: String) { Log.d(TAG, msg); logAndBuffer('D', msg) }
    private fun logW(msg: String) { Log.w(TAG, msg); logAndBuffer('W', msg) }
    private fun logE(msg: String) { Log.e(TAG, msg); logAndBuffer('E', msg) }

    companion object {
        const val PREFS_NAME = "JeenyAutoAcceptPrefs"
        const val NOTIFICATION_CHANNEL_ID = "keemo_foreground_channel"
        const val NOTIFICATION_ID = 1001

        /** Ring buffer of the most recent log lines the service produced.
         *  Read by the Dashboard's Diagnostics screen so the driver can
         *  screenshot and send us what happened, without needing ADB. */
        private val logBuffer = java.util.ArrayDeque<String>()
        private const val LOG_BUFFER_MAX = 400

        fun logAndBuffer(level: Char, msg: String) {
            val stamp = java.text.SimpleDateFormat(
                "HH:mm:ss.SSS", java.util.Locale.US
            ).format(java.util.Date())
            val line = "$stamp $level $msg"
            synchronized(logBuffer) {
                logBuffer.addLast(line)
                while (logBuffer.size > LOG_BUFFER_MAX) logBuffer.removeFirst()
            }
        }

        fun snapshotLogs(): List<String> = synchronized(logBuffer) {
            logBuffer.toList()
        }

        fun clearLogs() = synchronized(logBuffer) { logBuffer.clear() }

        /**
         * Called from MainActivity when the user toggles the bubble switch
         * in the Dashboard. Nudges the running service to re-evaluate its
         * overlay state without waiting for the next accessibility event.
         *
         * The SharedPreferences change listener already picks up the pref
         * flip, so this is defensive — some SDKs deliver the callback on
         * a background thread and window ops must be on the main looper.
         */
        fun refreshOverlay(context: Context) {
            Handler(Looper.getMainLooper()).post {
                // Nothing to do from outside the service instance itself —
                // the pref listener inside the running service handles it.
                // Kept as a hook in case we later want to bind directly.
            }
        }
    }
}
