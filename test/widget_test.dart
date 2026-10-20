import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omniconvert/app/app.dart';

void main() {
  testWidgets('a guest can move between recent tasks, tools, and settings', (
    tester,
  ) async {
    await tester.pumpWidget(const OmniConvertApp());

    expect(find.text('还没有任务'), findsOneWidget);

    await tester.tap(find.byKey(const Key('navigation-tools')));
    await tester.pumpAndSettle();
    expect(find.text('选择工具'), findsOneWidget);

    await tester.tap(find.byKey(const Key('navigation-settings')));
    await tester.pumpAndSettle();
    expect(find.text('本地工具无需登录'), findsOneWidget);

    await tester.tap(find.byKey(const Key('navigation-tasks')));
    await tester.pumpAndSettle();
    expect(find.text('任务记录'), findsOneWidget);
  });
}
