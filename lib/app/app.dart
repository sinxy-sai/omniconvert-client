import 'package:flutter/material.dart';

import '../core/tasks/task_repository.dart';
import '../core/ocr/custom_ocr_provider.dart';
import '../core/ocr/provider_settings.dart';
import '../core/ocr/ocr_provider.dart';
import '../core/tools/tool_execution_service.dart';
import '../core/tools/tool_runner.dart';
import '../core/tools/tool_runner_factory_native.dart'
    if (dart.library.js_interop) '../core/tools/tool_runner_factory_web.dart'
    as tool_runner_factory;
import 'router.dart';

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
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563B8)),
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF7F9FC),
    ),
    initialRoute: AppDestination.home.path,
    onGenerateRoute: (settings) {
      final destination = AppDestination.fromPath(settings.name);
      return MaterialPageRoute<void>(
        settings: RouteSettings(name: destination.path),
        builder: (_) => _AppShell(
          destination: destination,
          taskRepository: _taskRepository,
          toolService: _toolService,
          ocrProvider: _ocrProvider,
          providerSettings: _providerSettings,
        ),
      );
    },
  );
}

class _AppShell extends StatelessWidget {
  const _AppShell({
    required this.destination,
    required this.taskRepository,
    required this.toolService,
    required this.ocrProvider,
    required this.providerSettings,
  });
  final AppDestination destination;
  final TaskRepository taskRepository;
  final ToolExecutionService toolService;
  final OcrProvider? ocrProvider;
  final OcrProviderSettingsStore providerSettings;

  void _navigate(BuildContext context, int index) {
    final next = AppDestination.values[index];
    if (next != destination) {
      Navigator.of(context).pushReplacementNamed(next.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        final content = Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: destination.buildPage(
              taskRepository,
              toolService,
              ocrProvider,
              providerSettings,
            ),
          ),
        );
        return Scaffold(
          appBar: AppBar(
            backgroundColor: scheme.surface,
            title: const Text('OmniConvert'),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Text(
                    '访客模式',
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                ),
              ),
            ],
          ),
          body: wide
              ? Row(
                  children: [
                    NavigationRail(
                      selectedIndex: destination.index,
                      onDestinationSelected: (index) =>
                          _navigate(context, index),
                      labelType: NavigationRailLabelType.all,
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
                    const VerticalDivider(width: 1),
                    Expanded(child: content),
                  ],
                )
              : content,
          bottomNavigationBar: wide
              ? null
              : NavigationBar(
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
