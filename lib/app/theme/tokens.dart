import 'package:flutter/material.dart';

/// OmniConvert 设计 token —— 颜色 / 间距 / 圆角 / 阴影 / 字号 / 动效。
///
/// 约束：页面与组件只允许引用这里的 token，不允许再出现魔法数字或随手色值。
/// 字号阶梯 12 / 14 / 16 / 20 / 24 / 32 / 44；
/// 间距阶梯 4 / 8 / 12 / 16 / 24 / 32 / 48 / 64；
/// 卡片圆角 16、按钮 10、徽标 pill。
abstract final class OcColor {
  // ---- 品牌 ----
  static const brand = Color(0xFF4F46E5);
  static const brandStrong = Color(0xFF3730A3);
  static const brandDeep = Color(0xFF312E81);
  static const accent = Color(0xFF06B6D4);
  static const accentDeep = Color(0xFF0E7490);

  // ---- 文本与表面（浅色）----
  static const ink = Color(0xFF0B1220);
  static const inkSoft = Color(0xFF475569);
  static const inkMuted = Color(0xFF64748B);
  static const line = Color(0xFFE2E8F0);
  static const lineSoft = Color(0xFFEDF1F7);
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

  // ---- 格式徽标专用（12px 也需要 4.5:1）----
  static const formatPngFg = Color(0xFF0F766E);
  static const formatPngBg = Color(0xFFE6FBF7);
  static const formatJpgFg = Color(0xFF92400E);
  static const formatJpgBg = Color(0xFFFFF6E5);
  static const formatPdfFg = Color(0xFF9F1239);
  static const formatPdfBg = Color(0xFFFFEEF2);
  static const formatDocFg = Color(0xFF1E40AF);
  static const formatDocBg = Color(0xFFEEF3FF);
  static const formatBookFg = Color(0xFF5B21B6);
  static const formatBookBg = Color(0xFFF4EEFF);

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
  static const darkInkSoft = Color(0xFF9AA9BF);
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
  static const gradientBrandVertical = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
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

/// 字号阶梯（与 `app_theme.dart` 的 TextTheme 一一对应，供固定尺寸场景使用）。
abstract final class OcType {
  static const display = 44.0;
  static const title = 32.0;
  static const heading = 24.0;
  static const subhead = 20.0;
  static const body = 16.0;
  static const label = 14.0;
  static const caption = 12.0;

  /// 标题字距 -0.02em ≈ -0.02 × fontSize。
  static const tightTracking = -0.02;

  /// 中文正文行高下限。
  static const bodyHeight = 1.7;
}

abstract final class OcDuration {
  static const fast = Duration(milliseconds: 150);
  static const base = Duration(milliseconds: 200);
  static const slow = Duration(milliseconds: 220);

  /// brief 指定：cubic-bezier(.2,.8,.2,1)。
  static const curve = Cubic(0.2, 0.8, 0.2, 1);
}

abstract final class OcBreakpoints {
  /// 页面内两栏 / 多列布局切换点。
  static const tablet = 600.0;

  /// 工具页「工具列 + 工作区」双栏切换点。
  static const split = 1040.0;

  /// ≥ 840dp 使用 NavigationRail（侧栏）。
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

/// ColorScheme 之外仍然需要的语义色（success / warning / 品牌容器 / 导航 / 阴影）。
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
    required this.navSurface,
    required this.navBorder,
    required this.navInk,
    required this.navInkSoft,
    required this.navActiveSurface,
    required this.navActiveInk,
    required this.navActiveAccent,
    required this.heroSurface,
    required this.heroBorder,
    required this.gridDot,
    required this.cardShadow,
    required this.overlayShadow,
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
    navSurface: OcColor.ink,
    navBorder: Color(0xFF1B2740),
    navInk: Color(0xFFF1F5F9),
    navInkSoft: Color(0xFF9FB0C7),
    navActiveSurface: Color(0x24FFFFFF),
    navActiveInk: Color(0xFFFFFFFF),
    navActiveAccent: OcColor.darkBrand,
    heroSurface: Color(0xFFF3F5FF),
    heroBorder: Color(0xFFDFE4FB),
    gridDot: Color(0x0F4F46E5),
    cardShadow: [
      BoxShadow(
        color: Color(0x080B1220),
        blurRadius: 2,
        offset: Offset(0, 1),
      ),
      BoxShadow(
        color: Color(0x0F0B1220),
        blurRadius: 28,
        offset: Offset(0, 10),
      ),
    ],
    overlayShadow: [
      BoxShadow(
        color: Color(0x1A0B1220),
        blurRadius: 40,
        offset: Offset(0, 16),
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
    navSurface: Color(0xFF111A2C),
    navBorder: OcColor.darkLine,
    navInk: Color(0xFFE2E8F0),
    navInkSoft: Color(0xFF9AA9BF),
    navActiveSurface: Color(0x334F46E5),
    navActiveInk: Color(0xFFE9E7FF),
    navActiveAccent: OcColor.darkBrand,
    heroSurface: Color(0xFF131E36),
    heroBorder: Color(0xFF243251),
    gridDot: Color(0x1F818CF8),
    cardShadow: <BoxShadow>[],
    overlayShadow: <BoxShadow>[
      BoxShadow(
        color: Color(0x66000000),
        blurRadius: 48,
        offset: Offset(0, 18),
      ),
    ],
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

  /// 侧边导航（深墨底，浅色 / 暗色都保持同一套「工作台」观感）。
  final Color navSurface;
  final Color navBorder;
  final Color navInk;
  final Color navInkSoft;
  final Color navActiveSurface;
  final Color navActiveInk;
  final Color navActiveAccent;

  /// 首页 hero 与品牌区背景。
  final Color heroSurface;
  final Color heroBorder;
  final Color gridDot;
  final List<BoxShadow> cardShadow;
  final List<BoxShadow> overlayShadow;
  final LinearGradient brandGradient;
  final LinearGradient brandSoftGradient;

  bool get isDark => brightness == Brightness.dark;

  static OcSemantics of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

/// 浅色 / 暗色两套 ColorScheme；`app_theme.dart` 由它派生 ThemeData。
abstract final class OcScheme {
  static ColorScheme light() => const ColorScheme(
    brightness: Brightness.light,
    primary: OcColor.brand,
    onPrimary: Colors.white,
    primaryContainer: OcColor.brandContainer,
    onPrimaryContainer: OcColor.onBrandContainer,
    secondary: OcColor.accent,
    onSecondary: Color(0xFF042F37),
    secondaryContainer: OcColor.accentContainer,
    onSecondaryContainer: OcColor.onAccentContainer,
    tertiary: Color(0xFF0891B2),
    onTertiary: Colors.white,
    error: OcColor.danger,
    onError: Colors.white,
    errorContainer: OcColor.dangerContainer,
    onErrorContainer: OcColor.onDangerContainer,
    surface: OcColor.surface,
    onSurface: OcColor.ink,
    surfaceDim: Color(0xFFDDE5F0),
    surfaceBright: OcColor.surface,
    surfaceContainerLowest: OcColor.bg,
    surfaceContainerLow: Color(0xFFFAFBFD),
    surfaceContainer: OcColor.surfaceSunken,
    surfaceContainerHigh: OcColor.surfaceRaised,
    surfaceContainerHighest: OcColor.line,
    onSurfaceVariant: OcColor.inkSoft,
    outline: OcColor.outline,
    outlineVariant: OcColor.line,
    shadow: Color(0xFF0B1220),
    scrim: Color(0xFF0B1220),
    inverseSurface: OcColor.ink,
    onInverseSurface: Color(0xFFF7F9FC),
    inversePrimary: OcColor.darkBrand,
    surfaceTint: Colors.transparent,
  );

  static ColorScheme dark() => const ColorScheme(
    brightness: Brightness.dark,
    primary: OcColor.darkBrand,
    onPrimary: Color(0xFF12102E),
    primaryContainer: OcColor.darkBrandContainer,
    onPrimaryContainer: OcColor.darkOnBrandContainer,
    secondary: OcColor.darkAccent,
    onSecondary: Color(0xFF042F37),
    secondaryContainer: OcColor.darkAccentContainer,
    onSecondaryContainer: OcColor.darkOnAccentContainer,
    tertiary: OcColor.darkAccent,
    onTertiary: Color(0xFF042F37),
    error: OcColor.darkDanger,
    onError: Color(0xFF450A0A),
    errorContainer: OcColor.darkDangerContainer,
    onErrorContainer: OcColor.darkOnDangerContainer,
    surface: OcColor.darkSurface,
    onSurface: OcColor.darkInk,
    surfaceDim: OcColor.darkBg,
    surfaceBright: OcColor.darkSurfaceRaised,
    surfaceContainerLowest: OcColor.darkBg,
    surfaceContainerLow: Color(0xFF0E1729),
    surfaceContainer: OcColor.darkSurfaceContainer,
    surfaceContainerHigh: OcColor.darkSurfaceRaised,
    surfaceContainerHighest: Color(0xFF223052),
    onSurfaceVariant: OcColor.darkInkSoft,
    outline: OcColor.darkOutline,
    outlineVariant: OcColor.darkLine,
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: OcColor.darkInk,
    onInverseSurface: OcColor.darkBg,
    inversePrimary: OcColor.brand,
    surfaceTint: Colors.transparent,
  );
}