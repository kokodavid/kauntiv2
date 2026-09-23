import 'dart:ui';

abstract final class AppSvgPath {
  static Path parse(String data) {
    final path = Path();
    final tokens = RegExp(
      r'[MmLlZz]|-?(?:\d+\.?\d*|\.\d+)',
    ).allMatches(data).map((match) => match.group(0)!).toList();

    var index = 0;
    var command = '';
    var current = Offset.zero;
    var subpathStart = Offset.zero;

    while (index < tokens.length) {
      final token = tokens[index];
      if (_isCommand(token)) {
        command = token;
        index += 1;
      }

      switch (command) {
        case 'M':
        case 'm':
          final first = _readPoint(tokens, index);
          index += 2;
          current = command == 'm' ? current + first : first;
          subpathStart = current;
          path.moveTo(current.dx, current.dy);
          command = command == 'm' ? 'l' : 'L';
        case 'L':
        case 'l':
          while (index + 1 < tokens.length && !_isCommand(tokens[index])) {
            final point = _readPoint(tokens, index);
            index += 2;
            current = command == 'l' ? current + point : point;
            path.lineTo(current.dx, current.dy);
          }
        case 'Z':
        case 'z':
          path.close();
          current = subpathStart;
          index += 0;
          command = '';
        default:
          throw FormatException('Unsupported SVG path command "$command".');
      }
    }

    return path;
  }

  static bool _isCommand(String token) {
    return token.length == 1 && 'MmLlZz'.contains(token);
  }

  static Offset _readPoint(List<String> tokens, int index) {
    return Offset(double.parse(tokens[index]), double.parse(tokens[index + 1]));
  }
}
