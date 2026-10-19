import 'package:flutter/material.dart';

import '../../../core/widgets/saved_chip.dart';
import '../../../design/app_text_styles.dart';
import '../domain/passport_book.dart';
import 'passport_filter_bar.dart';
import 'passport_palette.dart';
import 'passport_region_section.dart';
import 'passport_summary_card.dart';
import 'passport_text.dart';

/// The Passport's landing: the user's progress, a suggestion, search and
/// filters, then every county by region.
class PassportLanding extends StatelessWidget {
  const PassportLanding({
    super.key,
    required this.book,
    required this.filter,
    required this.query,
    required this.controller,
    required this.onFilter,
    required this.onQuery,
    required this.onOpenCounty,
    this.holderName,
  });

  final PassportBook book;
  final PassportFilter filter;
  final String query;
  final ScrollController controller;
  final ValueChanged<PassportFilter> onFilter;
  final ValueChanged<String> onQuery;
  final void Function(int countyCode) onOpenCounty;

  /// The traveller's name, once it has loaded.
  final String? holderName;

  @override
  Widget build(BuildContext context) {
    final regions = book.regions(filter: filter, query: query);
    return ListView(
      controller: controller,
      physics: const AlwaysScrollableScrollPhysics(),
      // Room at the bottom for the floating tab bar.
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 120),
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 10),
          child: Text('Passport', style: AppTextStyles.headingForeground),
        ),
        if (book.isSavedCopy) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: SavedChip(savedAt: book.savedAt!),
          ),
        ],
        const SizedBox(height: 14),
        PassportSummaryCard(book: book, holderName: holderName),
        const SizedBox(height: 14),
        PassportFilterBar(
          book: book,
          filter: filter,
          query: query,
          onFilter: onFilter,
          onQuery: onQuery,
        ),
        const SizedBox(height: 20),
        if (regions.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(
                query.trim().isEmpty
                    ? 'No counties here yet.'
                    : 'No counties match “${query.trim()}”.',
                style: passportText(13, color: PassportInk.tertiary),
              ),
            ),
          ),
        for (final entry in regions.entries) ...[
          PassportRegionSection(
            region: entry.key,
            counties: entry.value,
            stamped: book.stampedIn(entry.key),
            total: book.totalIn(entry.key),
            onOpen: onOpenCounty,
          ),
          const SizedBox(height: 22),
        ],
      ],
    );
  }
}
