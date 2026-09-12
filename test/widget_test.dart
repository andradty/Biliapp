import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:biliapp/main.dart';

void main() {
  testWidgets('Landing page menampilkan judul BILINOVA', (WidgetTester tester) async {
    await tester.pumpWidget(const BilinovaApp());

    expect(find.text('BILINOVA'), findsOneWidget);
  });
}