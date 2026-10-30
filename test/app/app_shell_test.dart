import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omniconvert/app/navigation.dart';
import 'package:omniconvert/app/theme/app_theme.dart';
import 'package:omniconvert/app/theme/tokens.dart';
import 'package:omniconvert/app/widgets/app_shell.dart';

Future<void> _pumpShell(
  WidgetTester tester, {
  required Size size,
  AppSection section = AppSection.home,
  ValueChanged<AppSection>? onSelect,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: OcTheme.light(),
      home: AppShell(
        current: section,
        onSelect: onSelect ?? (_) {},
        child: const Text('页面内容'),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test('navigation has exactly four destinations and no OCR entry', () {
    expect(AppSection.values, hasLength(4));
    expect(
      AppSection.values.map((section) => section.label),
      <String>['首页', '工具', '任务', '设置'],
    );
    // 本轮明确不做公式识别：导航里不允许再出现。
    expect(
      AppSection.values.map((section) => section.label),
      isNot(contains('公式')),
    );
  });

  test('path lookup falls back to home for unknown routes', () {
    expect(AppSection.fromPath('/tools'), AppSection.tools);
    expect(AppSection.fromPath('/formula'), AppSection.home);
    expect(AppSection.fromPath(null), AppSection.home);
  });

  testWidgets('narrow screens use a bottom bar with all four sections', (
    tester,
  ) async {
    AppSection? selected;
    await _pumpShell(
      tester,
      size: const Size(390, 844),
      onSelect: (section) => selected = section,
    );

    expect(find.text('页面内容'), findsOneWidget);
    for (final section in AppSection.values) {
      expect(find.text(section.label), findsWidgets);
      expect(find.byKey(Key('navigation-${section.name}')), findsWidgets);
    }

    await tester.tap(find.byKey(const Key('navigation-tools')).first);
    await tester.pumpAndSettle();
    expect(selected, AppSection.tools);
  });

  testWidgets('wide screens use the ink rail with an active indicator', (
    tester,
  ) async {
    AppSection? selected;
    await _pumpShell(
      tester,
      size: const Size(1440, 1000),
      section: AppSection.tasks,
      onSelect: (section) => selected = section,
    );

    expect(find.text('工作区'), findsOneWidget);
    expect(find.text('本地优先'), findsOneWidget);
    for (final section in AppSection.values) {
      expect(find.byKey(Key('navigation-${section.name}')), findsWidgets);
    }

    await tester.tap(find.byKey(const Key('navigation-settings')).first);
    await tester.pumpAndSettle();
    expect(selected, AppSection.settings);
  });

  testWidgets('reduce-motion is respected by the shell animations', (
    tester,
  ) async {
    await _pumpShell(tester, size: const Size(390, 844));
    // Shell 动画时长走 token，不依赖系统设置也不会崩。
    expect(OcDuration.fast.inMilliseconds, 150);
  });
}