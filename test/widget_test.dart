import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jeeny_auto_clicker/main.dart';

void main() {
  testWidgets('JeenyAutoClickerApp boots without throwing',
      (WidgetTester tester) async {
    await tester.pumpWidget(const JeenyAutoClickerApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
