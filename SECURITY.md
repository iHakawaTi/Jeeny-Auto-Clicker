# Security Policy

## Reporting a vulnerability

If you find a security issue that could affect users of this app — credential
leakage, RLS bypass, click-hijacking, anything unauthorized — **please do NOT
file a public GitHub issue**. Report it privately by opening a
[GitHub Security Advisory](https://github.com/YOUR_ORG/YOUR_REPO/security/advisories/new)
or emailing the maintainer at `SECURITY_CONTACT_EMAIL@example.com`.

We'll acknowledge within 72 hours and coordinate a fix before public disclosure.

## Scope

**In scope:**

- Client-side vulnerabilities in the Flutter Dart / Android Kotlin code
- Supabase RLS policy or SECURITY DEFINER SQL bugs
- Anything that lets a non-admin gain admin privileges, one user read another
  user's data, or a signed-out client access authenticated data

**Out of scope:**

- The Supabase anon (publishable) key being visible in the shipped APK — this
  is by design. Row Level Security is the guard, not the key.
- Reports that require physical device access with USB debugging enabled
- Social-engineering attacks against the admin

## Hardening this project already ships

- Row Level Security enabled on every table
- All admin RPCs check `public.is_admin()` before doing anything
- All `SECURITY DEFINER` functions set `search_path = public` (blocks
  search-path hijacking)
- Device fingerprint uses `Settings.Secure.ANDROID_ID` (unique per
  physical device, resets only on factory reset) — a single account
  cannot be shared across devices
- Client-side pre-check for duplicate device binding, with a server-side
  UNIQUE index as the race-safe backstop
