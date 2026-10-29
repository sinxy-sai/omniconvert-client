import 'package:flutter/material.dart';

/// OmniConvert 设计 token。
///
/// 数值来源：`.work/design-brief.md` 第 4–6 节。
/// 页面与组件只允许引用这里的 token，不允许再出现魔法数字/随手色值。
abstract final class OcColor {
  // ---- 品牌 ----
  static const brand = Color(0xFF4F46E5);
  static const brandStrong = Color(0xFF3730A3);
  static const accent = Color(0xFF06B6D4);

  // ---- 文本与表面（浅色）----
  static const ink = Color(0xFF0B1220);
  static const inkSoft = Color(0xFF475569);
  static const line = Color(0xFFE2E8F0);
  static const bg = Color(0xFFF7F9FC);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceSunken = Color(0xFFF1F5F9);
  static const surfaceRaised = Color(0xFFE9EFF7);
  static const outline = Color(0xFFCBD5E1);

  // ---- 状态（浅色）----
  static const success = Color(0xFF059669);
  static const successContainer = Color(0xFFECFDF5);
  static const onSuccessContainer = Color(0xFF065F46);
  static const warning = Color(0xFFB45309);
  static const warningContainer = Color(0xFFFFFBEB);
  static const onWarningContainer = Color(0xFF92400E);
  static const danger = Color(0xFFDC2626);
  static const dangerContainer = Color(0xFFFEF2F2);
  static const onDangerContainer = Color(0xFF991B1B);
  static const infoContainer = Color(0xFFEFF6FF);
  static const onInfoContainer = Color(0xFF1E40AF);

  // ---- 容器（浅色）----
  static const brandContainer = Color(0xFFEEF2FF);
  static const onBrandContainer = Color(0xFF312E81);
  static const accentContainer = Color(0xFFECFEFF);
  static const onAccentContainer = Color(0xFF155E75);

  // ---- 等宽文本 ----
  static const monoSurface = Color(0xFF0F172A);
  static const onMonoSurface = Color(0xFFE2E8F0);

  // ---- 暗色 ----
  static const darkBg = Color(0xFF0B1220);
  static const darkSurface = Color(0xFF111A2C);
  static const darkSurfaceContainer = Color(0xFF151F33);
  static const darkSurfaceRaised = Color(0xFF1B2740);
  static const darkLine = Color(0xFF1E293B);
  static const darkInk = Color(0xFFE2E8F0);
  static const darkInkSoft = Color(0xFF94A3B8);
  static const darkOutline = Color(0xFF334155);
  static const darkBrand = Color(0xFF818CF8);
  static const darkBrandContainer = Color(0xFF2A2A5E);
  static const darkOnBrandContainer = Color(0xFFC7D2FE);
  static const darkAccent = Color(0xFF22D3EE);
  static const darkAccentContainer = Color(0xFF0E3A44);
  static const darkOnAccentContainer = Color(0xFFA5F3FC);
  static const darkSuccess = Color(0xFF34D399);
  static const darkSuccessContainer = Color(0xFF064E3B);
  static const darkOnSuccessContainer = Color(0xFFD1FAE5);
  static const darkWarning = Color(0xFFFBBF24);
  static const darkWarningContainer = Color(0xFF451A03);
  static const darkOnWarningContainer = Color(0xFFFDE68A);
  static const darkDanger = Color(0xFFF87171);
  static const darkDangerContainer = Color(0xFF450A0A);
  static const darkOnDangerContainer = Color(0xFFFEE2E2);
  static const darkInfoContainer = Color(0xFF172554);
  static const darkOnInfoContainer = Color(0xFFBFDBFE);

  // ---- 渐变 ----
  static const gradientBrand = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brand, accent],
  );
}

/// 间距阶梯：4 / 8 / 12 / 16 / 24 / 32 / 48 / 64 / 96。
abstract final class OcSpace {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xl2 = 48.0;
  static const xl3 = 64.0;
  static const xl4 = 96.0;
}

/// 圆角：卡片 16 / 按钮 10 / 输入 10 / 徽标 pill。
abstract final class OcRadius {
  static const card = 16.0;
  static const panel = 20.0;
  static const button = 10.0;
  static const input = 10.0;
  static const chip = 8.0;
  static const iconTile = 12.0;
  static const pill = 999.0;

  static const cardBorder = BorderRadius.all(Radius.circular(card));
  static const panelBorder = BorderRadius.all(Radius.circular(panel));
  static const buttonBorder = BorderRadius.all(Radius.circular(button));
  static const inputBorder = BorderRadius.all(Radius.circular(input));
  static const chipBorder = BorderRadius.all(Radius.circular(chip));
  static const iconTileBorder = BorderRadius.all(Radius.circular(iconTile));
}

abstract final class OcDuration {
  static const fast = Duration(milliseconds: 150);
  static const base = Duration(milliseconds: 200);
  static const slow = Duration(milliseconds: 220);

  /// brief 指定：cubic-bezier(.2,.8,.2,1)。
  static const curve = Cubic(0.2, 0.8, 0.2, 1);
}

abstract final class OcBreakpoints {
  /// 页面内两栏/多列布局切换点。
  static const tablet = 600.0;

  /// ≥ 840dp 使用 NavigationRail。
  static const rail = 840.0;

  /// 桌面宽屏（多列内容、侧栏辅助信息）。
  static const desktop = 1080.0;
}

/// brief 指定字体栈；不引入联网字体与字体包。
const ocFontFallback = <String>[
  'PingFang SC',
  'Microsoft YaHei UI',
  'Microsoft YaHei',
  'Noto Sans SC',
  'Noto Sans CJK SC',
  'Source Han Sans SC',
  'Heiti SC',
  'sans-serif',
];

const ocMonoFallback = <String>[
  'JetBrains Mono',
  'Cascadia Mono',
  'SFMono-Regular',
  'Consolas',
  'Menlo',
  'monospace',
];

/// ColorScheme 之外、but 仍然需要的语义色（success / warning / brand 容器 / 阴影）。
@immutable
class OcSemantics {
  const OcSemantics({
    required this.brightness,
    required this.success,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.warning,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.danger,
    required this.dangerContainer,
    required this.onDangerContainer,
    required this.infoContainer,
    required this.onInfoContainer,
    required this.brandContainer,
    required this.onBrandContainer,
    required this.accentContainer,
    required this.onAccentContainer,
    required this.monoSurface,
    required this.onMonoSurface,
    required this.cardShadow,
    required this.brandGradient,
    required this.brandSoftGradient,
  });

  static const light = OcSemantics(
    brightness: Brightness.light,
    success: OcColor.success,
    successContainer: OcColor.successContainer,
    onSuccessContainer: OcColor.onSuccessContainer,
    warning: OcColor.warning,
    warningContainer: OcColor.warningContainer,
    onWarningContainer: OcColor.onWarningContainer,
    danger: OcColor.danger,
    dangerContainer: OcColor.dangerContainer,
    onDangerContainer: OcColor.onDangerContainer,
    infoContainer: OcColor.infoContainer,
    onInfoContainer: OcColor.onInfoContainer,
    brandContainer: OcColor.brandContainer,
    onBrandContainer: OcColor.onBrandContainer,
    accentContainer: OcColor.accentContainer,
    onAccentContainer: OcColor.onAccentContainer,
    monoSurface: OcColor.monoSurface,
    onMonoSurface: OcColor.onMonoSurface,
    cardShadow: [
      BoxShadow(
        color: Color(0x0A0B1220),
        blurRadius: 2,
        offset: Offset(0, 1),
      ),
      BoxShadow(
        color: Color(0x0F0B1220),
        blurRadius: 32,
        offset: Offset(0, 12),
      ),
    ],
    brandGradient: OcColor.gradientBrand,
    brandSoftGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0x144F46E5), Color(0x1206B6D4)],
    ),
  );

  static const dark = OcSemantics(
    brightness: Brightness.dark,
    success: OcColor.darkSuccess,
    successContainer: OcColor.darkSuccessContainer,
    onSuccessContainer: OcColor.darkOnSuccessContainer,
    warning: OcColor.darkWarning,
    warningContainer: OcColor.darkWarningContainer,
    onWarningContainer: OcColor.darkOnWarningContainer,
    danger: OcColor.darkDanger,
    dangerContainer: OcColor.darkDangerContainer,
    onDangerContainer: OcColor.darkOnDangerContainer,
    infoContainer: OcColor.darkInfoContainer,
    onInfoContainer: OcColor.darkOnInfoContainer,
    brandContainer: OcColor.darkBrandContainer,
    onBrandContainer: OcColor.darkOnBrandContainer,
    accentContainer: OcColor.darkAccentContainer,
    onAccentContainer: OcColor.darkOnAccentContainer,
    monoSurface: Color(0xFF020617),
    onMonoSurface: Color(0xFFCBD5E1),
    cardShadow: <BoxShadow>[],
    brandGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [OcColor.darkBrand, OcColor.darkAccent],
    ),
    brandSoftGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0x26818CF8), Color(0x1F22D3EE)],
    ),
  );

  final Brightness brightness;
  final Color success;
  final Color successContainer;
  final Color onSuccessContainer;
  final Color warning;
  final Color warningContainer;
  final Color onWarningContainer;
  final Color danger;
  final Color dangerContainer;
  final Color onDangerContainer;
  final Color infoContainer;
  final Color onInfoContainer;
  final Color brandContainer;
  final Color onBrandContainer;
  final Color accentContainer;
  final Color onAccentContainer;
  final Color monoSurface;
  final Color onMonoSurface;
  final List<BoxShadow> cardShadow;
  final LinearGradient brandGradient;
  final LinearGradient brandSoftGradient;

  bool get isDark => brightness == Brightness.dark;

  static OcSemantics of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}