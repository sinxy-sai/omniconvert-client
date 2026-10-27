String defaultOutputFileName(String inputName, String extension) {
  final base = inputName.split(RegExp(r'[\\/]')).last;
  final withoutExtension = base.replaceFirst(RegExp(r'\.[^.]+$'), '');
  return '$withoutExtension.$extension';
}
