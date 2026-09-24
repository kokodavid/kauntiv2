import 'package:flutter/material.dart';

import '../../../counties/county_paths.dart';
import 'map_home_links.dart';

/// Opens County Detail, or says it's coming when the link isn't wired.
void openCountyOrNote(
  BuildContext context,
  CountyPath county,
  OpenCountyDetail? open,
) {
  if (open != null) return open(context, county.code);
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text('${county.name} details are next.')));
}
