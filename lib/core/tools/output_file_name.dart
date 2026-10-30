import 'tool_registry.g.dart';

/// Computes the default output file name for a tool + input file pair.
///
/// This is the **only** place that knows how a tool maps an input name to an
/// output name; the UI must call it whenever the tool or the selected file
/// changes instead of hand-rolling suffixes.
///
/// Rules (all derived from `tool_registry.g.dart`, never hard-coded):
/// * the directory part of [inputFileName] is dropped — output names are bare
///   file names;
/// * the extension is replaced by the registry `outputExtension`;
/// * tools with `outputExtension: "same"` keep the input extension, with
///   `jpeg` normalised to `jpg`;
/// * a name without an extension simply gets the target extension appended;
/// * an unknown tool id leaves the name untouched (defensive: never invent a
///   suffix for a tool the registry does not know).
String outputFileNameFor({
  required String toolId,
  required String inputFileName,
}) {
  final name = baseFileName(inputFileName);
  if (name.isEmpty) return name;
  final definition = toolDefinitionFor(toolId);
  if (definition == null) return name;

  final hasExtension = _hasExtension(name);
  final extension = hasExtension
      ? name.substring(name.lastIndexOf('.') + 1)
      : '';
  final rawBase = hasExtension ? name.substring(0, name.lastIndexOf('.')) : name;
  // "photo." is a trailing dot, not an extension: normalise it away.
  final base = rawBase.endsWith('.')
      ? rawBase.substring(0, rawBase.length - 1)
      : rawBase;
  if (base.isEmpty) return name;

  // Format-preserving tools cannot invent an extension out of thin air.
  if (definition.keepsFormat && extension.isEmpty) return name;

  final resolved = definition.resolveOutputExtension(extension);
  if (resolved.isEmpty || resolved == 'same') return name;
  return '$base.$resolved';
}

/// Strips any directory component from [path] and returns the bare file name.
String baseFileName(String path) {
  final trimmed = path.trim();
  if (trimmed.isEmpty) return '';
  final separator = trimmed.lastIndexOf(RegExp(r'[\\/]'));
  return separator < 0 ? trimmed : trimmed.substring(separator + 1);
}

bool _hasExtension(String name) {
  final dot = name.lastIndexOf('.');
  // A leading dot (".gitignore") is a hidden name, not an extension.
  return dot > 0 && dot < name.length - 1;
}

/// Legacy helper kept for callers that already resolved the extension
/// themselves. Prefer [outputFileNameFor], which reads the registry.
String defaultOutputFileName(String inputName, String extension) {
  final base = baseFileName(inputName);
  if (base.isEmpty) return base;
  final withoutExtension = base.replaceFirst(RegExp(r'\.[^.]+$'), '');
  return '$withoutExtension.$extension';
}