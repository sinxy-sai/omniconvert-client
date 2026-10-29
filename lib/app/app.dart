import 'package:flutter/material.dart';

import '../core/ocr/custom_ocr_provider.dart';
import '../core/ocr/ocr_provider.dart';
import '../core/ocr/provider_settings.dart';
import '../core/tasks/task_repository.dart';
import '../core/tools/tool_execution_service.dart';
import '../core/tools/tool_runner.dart';
import '../core/tools/tool_runner_factory_native.dart'
    if (dart.library.js_interop) '../core/tools/tool_runner_factory_web.dart'
    as tool_runner_factory;
import 'router.dart';
import 'theme/app_theme.dart';
import 'theme/tokens.dart';
import 'widgets/oc_brand.dart';
import 'widgets/oc_surface.dart';

class OmniConvertApp extends StatefulWidget {
  const OmniConvertApp({super.key, this.taskRepository, this.toolRunner});

  final TaskRepository? taskRepository;
  final ToolRunner? toolRunner;

  @override
  State<OmniConvertApp> createState() => _OmniConvertAppState();
}

class _OmniConvertAppState extends State<OmniConvertApp> {
  late final TaskRepository _taskRepository =
      widget.taskRepository ?? InMemoryTaskRepository();
  late final ToolExecutionService _toolService = ToolExecutionService(
    _taskRepository,
    widget.toolRunner ?? tool_runner_factory.createToolRunner(),
  );
  late final OcrProviderSettingsStore _providerSettings =
      OcrProviderSettingsStore();
  OcrProvider? _ocrProvider;

  AppDependencies get _dependencies => AppDependencies(
    taskRepository: _taskRepository,
    toolService: _toolService,
    ocrProvider: _ocrProvider,
    providerSettings: _providerSettings,
  );

  @override
  void initState() {
    super.initState();
    _loadProvider();
  }

  Future<void> _loadProvider() async {
    final endpoint = await _providerSettings.loadCustomEndpoint();
    if (!mounted || endpoint == null) return;
    setState(() => _ocrProvider = CustomOcrProvider(endpoint));
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'OmniConvert',
    debugShowCheckedModeBanner: false,
    theme: OcTheme.light(),
    darkTheme: OcTheme.dark(),
    themeMode: ThemeMode.system,
    initialRoute: AppDestination.home.path,
    onGenerateRoute: (settings) {
      final destination = AppDestination.fromPath(settings.name);
      return _fadeRoute(
        destination: destination,
        dependencies: _dependencies,
      );
    },
  );

  PageRoute<void> _fadeRoute({
    required AppDestination destination,
    required AppDependencies dependencies,
  }) => PageRouteBuilder<void>(
    settings: RouteSettings(name: destination.path),
    transitionDuration: OcDuration.base,
    reverseTransitionDuration: OcDuration.fast,
    pageBuilder: (_, _, _) =>
        _AppShell(destination: destination, dependencies: dependencies),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: OcDuration.curve,
      );
      return FadeTransition(opacity: curved, child: child);
    },
  );
}

class _AppShell extends StatelessWidget {
  const _AppShell({required this.destination, required this.dependencies});

  final AppDestination destination;
  final AppDependencies dependencies;

  void _navigate(BuildContext context, int index) {
    final next = AppDestination.values[index];
    if (next == destination) return;
    Navigator.of(context).pushReplacementNamed(next.path);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= OcBreakpoints.rail;
        final page = KeyedSubtree(
          key: ValueKey<String>(destination.path),
          child: destination.buildPage(dependencies),
        );
        if (wide) {
          return Scaffold(
            backgroundColor: scheme.surfaceContainerLowest,
            body: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SideRail(
                  destination: destination,
                  onSelected: (index) => _navigate(context, index),
                ),
                Expanded(child: page),
              ],
            ),
          );
        }
        return Scaffold(
          backgroundColor: scheme.surfaceContainerLowest,
          appBar: AppBar(
            titleSpacing: OcSpace.md,
            title: const OcBrandLockup(markSize: 28),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: OcSpace.md),
                child: Center(
                  child: OcPill(
                    label: '访客模式',
                    dense: true,
                    icon: Icons.person_outline_rounded,
                  ),
                ),
              ),
            ],
          ),
          body: page,
          bottomNavigationBar: NavigationBar(
            selectedIndex: destination.index,
            onDestinationSelected: (index) => _navigate(context, index),
            destinations: [
              for (final item in AppDestination.values)
                NavigationDestination(
                  icon: Icon(
                    item.icon,
                    key: Key('navigation-${item.name}'),
                  ),
                  selectedIcon: Icon(
                    item.selectedIcon,
                    key: Key('navigation-${item.name}'),
                  ),
                  label: item.label,
                ),
            ],
          ),
        );
      },
    );
  }
}

/// ≥ 840dp 的侧边导航：品牌区 + NavigationRail + 可信提示页脚。
class _SideRail extends StatelessWidget {
  const _SideRail({required this.destination, required this.onSelected});

  final AppDestination destination;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 248,
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(right: BorderSide(color: scheme.outlineVariant)),
      ),
      child: SafeArea(
        right: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(
                OcSpace.lg,
                OcSpace.lg,
                OcSpace.lg,
                OcSpace.sm,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: OcBrandLockup(markSize: 38, showTagline: true),
              ),
            ),
            Expanded(
              child: NavigationRail(
                extended: true,
                labelType: NavigationRailLabelType.none,
                minExtendedWidth: 248,
                groupAlignment: -0.92,
                selectedIndex: destination.index,
                onDestinationSelected: onSelected,
                destinations: [
                  for (final item in AppDestination.values)
                    NavigationRailDestination(
                      icon: Icon(
                        item.icon,
                        key: Key('navigation-${item.name}'),
                      ),
                      selectedIcon: Icon(
                        item.selectedIcon,
                        key: Key('navigation-${item.name}'),
                      ),
                      label: Text(item.label),
                    ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(
                OcSpace.md,
                OcSpace.sm,
                OcSpace.md,
                OcSpace.lg,
              ),
              child: _RailFooter(),
            ),
          ],
        ),
      ),
    );
  }
}

class _RailFooter extends StatelessWidget {
  const _RailFooter();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(OcSpace.sm),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(OcRadius.chip),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: 14,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                '本地优先',
                style: textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '文件默认在本机处理，不上传。',
            style: textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}