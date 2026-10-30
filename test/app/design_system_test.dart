import 'dart:ui' show Canvas, PictureRecorder;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omniconvert/app/icons/oc_icons.dart';
import 'package:omniconvert/app/theme/app_theme.dart';
import 'package:omniconvert/app/theme/tokens.dart';
import 'package:omniconvert/app/widgets/surface_card.dart';
import 'package:omniconvert/app/widgets/tone.dart';
import 'package:omniconvert/core/tools/tool_registry.g.dart';

double _contrastRatio(Color a, Color b) {
  final luminanceA = a.computeLuminance();
  final luminanceB = b.computeLuminance();
  final lighter = luminanceA > luminanceB ? luminanceA : luminanceB;
  final darker = luminanceA > luminanceB ? luminanceB : luminanceA;
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  group('tokens', () {
    test('spacing and radius scales follow the design baseline', () {
      expect(
        [OcSpace.xxs, OcSpace.xs, OcSpace.sm, OcSpace.md, OcSpace.lg],
        <double>[4, 8, 12, 16, 24],
      );
      expect(OcRadius.card, 16);
      expect(OcRadius.button, 10);
      expect(OcType.caption, 12);
      expect(OcType.display, 44);
      expect(OcBreakpoints.rail, 840);
    });

    test('type scale is strictly increasing', () {
      const scale = <double>[
        OcType.caption,
        OcType.label,
        OcType.body,
        OcType.subhead,
        OcType.heading,
        OcType.title,
        OcType.display,
      ];
      for (var index = 1; index < scale.length; index++) {
        expect(scale[index], greaterThan(scale[index - 1]));
      }
    });

    test('both color schemes keep text contrast above 4.5:1', () {
      for (final scheme in <ColorScheme>[OcScheme.light(), OcScheme.dark()]) {
        expect(
          _contrastRatio(scheme.onSurface, scheme.surface),
          greaterThanOrEqualTo(4.5),
          reason: '正文对比度 ${scheme.brightness}',
        );
        expect(
          _contrastRatio(scheme.onSurfaceVariant, scheme.surface),
          greaterThanOrEqualTo(4.5),
          reason: '次要文本对比度 ${scheme.brightness}',
        );
        expect(
          _contrastRatio(scheme.onPrimary, scheme.primary),
          greaterThanOrEqualTo(4.5),
          reason: '主按钮对比度 ${scheme.brightness}',
        );
      }
    });

    test('dark scheme is actually dark and light scheme is light', () {
      expect(OcScheme.dark().surface.computeLuminance(), lessThan(0.1));
      expect(OcScheme.light().surface.computeLuminance(), greaterThan(0.8));
    });

    test('theme builds without throwing for both brightnesses', () {
      expect(OcTheme.light().colorScheme.brightness, Brightness.light);
      expect(OcTheme.dark().colorScheme.brightness, Brightness.dark);
      expect(OcTheme.light().textTheme.bodyLarge?.height, greaterThanOrEqualTo(1.7));
    });
  });

  group('icon set', () {
    test('covers navigation, all six tools and the brand glyph', () {
      expect(OcIcons.all, hasLength(greaterThanOrEqualTo(20)));

      final navNames = <String>{
        OcIcons.home.name,
        OcIcons.tools.name,
        OcIcons.tasks.name,
        OcIcons.settings.name,
      };
      expect(navNames, hasLength(4));

      final toolNames = <String>{
        OcIcons.convert.name,
        OcIcons.image.name,
        OcIcons.compress.name,
        OcIcons.imageToPdf.name,
        OcIcons.document.name,
        OcIcons.book.name,
      };
      expect(toolNames, hasLength(6));

      // 每个工具的图标必须真的不同，不能全都复用同一个图形。
      expect(toolNames.length, kToolDefinitions.length);
    });

    test('every icon paints at 16px without throwing', () {
      for (final icon in OcIcons.all) {
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        expect(
          () => paintOcIcon(
            canvas,
            icon,
            const Size(16, 16),
            color: const Color(0xFF0B1220),
          ),
          returnsNormally,
          reason: 'icon ${icon.name}',
        );
        recorder.endRecording().dispose();
      }
    });
  });

  group('components', () {
    testWidgets('format badges render uppercase monospace labels', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: OcTheme.light(),
          home: const Scaffold(
            body: Row(
              children: [
                FormatBadge('png'),
                FormatBadge('jpeg'),
                FormatBadge('pdf'),
              ],
            ),
          ),
        ),
      );
      expect(find.text('PNG'), findsOneWidget);
      expect(find.text('JPG'), findsOneWidget);
      expect(find.text('PDF'), findsOneWidget);
    });

    testWidgets('status pills expose their tone colours', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: OcTheme.dark(),
          home: const Scaffold(
            body: StatusPill(label: '本机处理', tone: OcTone.success),
          ),
        ),
      );
      expect(find.text('本机处理'), findsOneWidget);
      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(StatusPill),
              matching: find.byType(Container),
            )
            .first,
      );
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.color, OcSemantics.dark.successContainer);
    });
  });
}