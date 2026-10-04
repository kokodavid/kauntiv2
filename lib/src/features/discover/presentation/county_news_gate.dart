import 'package:flutter/widgets.dart';

class CountyNewsGate extends StatelessWidget {
  const CountyNewsGate({
    super.key,
    required this.enabled,
    required this.builder,
  });

  final Future<bool> enabled;
  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) => FutureBuilder<bool>(
    future: enabled,
    builder: (context, snapshot) =>
        snapshot.data == true ? builder(context) : const SizedBox.shrink(),
  );
}
