/// Why someone reports a public trip. The wire values are the server's
/// allowed list.
enum PublicTripReportReason {
  privacy(
    'privacy',
    'Shows a private place',
    'It reveals where someone lives, works or stays.',
  ),
  restrictedAccess(
    'restricted_access',
    'Unsafe or off-limits route',
    'It goes through private land or a restricted area.',
  ),
  misleading(
    'misleading',
    'Misleading or fake',
    'The title, route or photos are not what they claim.',
  ),
  abuse(
    'abuse',
    'Offensive or abusive',
    'The title or photos are inappropriate.',
  ),
  other('other', 'Something else', 'Tell us more below.');

  const PublicTripReportReason(this.wire, this.label, this.hint);

  final String wire;
  final String label;
  final String hint;
}
