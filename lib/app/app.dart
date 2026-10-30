import 'package:flutter/material.dart';

import '../core/tasks/task_repository.dart';
import '../core/tools/tool_execution_service.dart';
import '../core/tools/tool_runner.dart';
import '../core/tools/tool_runner_factory_native.dart'
    if (dart.library.js_interop) '../core/tools/tool_runner_factory_web.dart'
    as tool_runner_factory;
import 'navigation.dart';
import 'router.dart';
import 'theme/app_theme.dart';
import 'theme/tokens.dart';
import 'widgets/app_shell.dart';

class OmniConvertApp extends StatefulWidget {
  const OmniConvertApp({
    super.key,
    this.taskRepository,
    this.toolRunner,
    this.initialThemeMode = ThemeMode.system,
  });

  final TaskRepository? taskRepository;
  final ToolRunner? toolRunner;
  final ThemeMode initialThemeMode;

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
  late ThemeMode _themeMode = widget.initialThemeMode;

  AppDependencies get _dependencies => AppDependencies(
    taskRepository: _taskRepository,
    toolService: _toolService,
    themeMode: _themeMode,
    onThemeModeChanged: (mode) => setState(() => _themeMode = mode),
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OmniConvert',
      debugShowCheckedModeBanner: false,
      theme: OcTheme.light(),
      darkTheme: OcTheme.dark(),
      themeMode: _themeMode,
      onGenerateInitialRoutes: (platformRoute) => [
        _route(AppSection.fromPath(resolveInitialPath(platformRoute))),
      ],
      onGenerateRoute: (settings) =>
          _route(AppSection.fromPath(settings.name)),
    );
  }

  Route<void> _route(AppSection section) {
    return PageRouteBuilder<void>(
      settings: RouteSettings(name: section.path),
      transitionDuration: OcDuration.base,
      reverseTransitionDuration: OcDuration.fast,
      pageBuilder: (context, _, _) => _ShellRoute(
        section: section,
        dependencies: _dependencies,
      ),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
          return child;
        }
        final curved = CurvedAnimation(
          parent: animation,
          curve: OcDuration.curve,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.008),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }
}

class _ShellRoute extends StatelessWidget {
  const _ShellRoute({required this.section, required this.dependencies});

  final AppSection section;
  final AppDependencies dependencies;

  void _select(BuildContext context, AppSection next) {
    if (next == section) return;
    Navigator.of(context).pushReplacementNamed(next.path);
  }

  @override
  Widget build(BuildContext context) => AppShell(
    current: section,
    onSelect: (next) => _select(context, next),
    child: buildSectionPage(section, dependencies),
  );
}