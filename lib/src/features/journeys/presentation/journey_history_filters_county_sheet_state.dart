part of 'journey_history_filters.dart';

class _CountySheetState extends State<_CountySheet> {
  late final Set<String> _selected = Set.of(widget.current);

  void _toggle(String name) {
    setState(() {
      if (!_selected.remove(name)) _selected.add(name);
    });
  }

  static String _tripsLabel(int count) =>
      count == 1 ? '1 trip' : '$count trips';

  @override
  Widget build(BuildContext context) {
    final shownCount = widget.countTripsFor(_selected);
    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Expanded(
                    child: Text('Counties', style: AppTypeScale.sectionTitle),
                  ),
                  Text(
                    "You've been to ${widget.counties.length} of "
                    '${CountyPaths.all.length}',
                    style: AppTypeScale.meta.copyWith(
                      color: AppColors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.cardBorder),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: widget.counties.length,
                separatorBuilder: (context, index) => const Divider(
                  height: 1,
                  color: AppColors.cardBorder,
                  indent: 20,
                  endIndent: 20,
                ),
                itemBuilder: (context, index) {
                  final county = widget.counties[index];
                  final isSelected = _selected.contains(county.name);
                  return InkWell(
                    onTap: () => _toggle(county.name),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 30,
                            child: Text(
                              county.code.toString().padLeft(3, '0'),
                              style: AppTypeScale.meta.copyWith(
                                color: AppColors.mutedForeground,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              county.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypeScale.cardTitle,
                            ),
                          ),
                          Text(
                            _tripsLabel(county.tripCount),
                            style: AppTypeScale.meta.copyWith(
                              color: AppColors.mutedForeground,
                            ),
                          ),
                          const SizedBox(width: 14),
                          _CheckDot(selected: isSelected),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(_selected),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: const StadiumBorder(),
                  ),
                  child: Text(
                    'Show ${_tripsLabel(shownCount)}',
                    style: AppTextStyles.buttonLabel.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
