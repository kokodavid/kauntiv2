/// Release notes split into display lines. Bullet markers ("-", "*", "•")
/// are stripped so the UI draws its own dots; other lines stay as text.
List<String> parseUpdateNotes(String? notes) {
  if (notes == null) return const [];
  return [
    for (final line in notes.split(RegExp(r'\r?\n')))
      if (line.replaceFirst(RegExp(r'^\s*[-*•]\s*'), '').trim().isNotEmpty)
        line.replaceFirst(RegExp(r'^\s*[-*•]\s*'), '').trim(),
  ];
}
