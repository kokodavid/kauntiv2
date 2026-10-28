import 'username.dart';

/// What the username chooser shows: four suggestions, or the user's own
/// text with the server's verdict on it.
class UsernameChooserState {
  const UsernameChooserState({
    this.suggestions = const [],
    this.isLoading = true,
    this.loadFailed = false,
    this.selected,
    this.isCustom = false,
    this.customText = '',
    this.customCheck,
    this.isChecking = false,
    this.isSaving = false,
    this.userPicked = false,
    this.error,
  });

  final List<String> suggestions;
  final bool isLoading;
  final bool loadFailed;

  /// The suggestion that is picked, when not writing their own.
  final String? selected;
  final bool isCustom;
  final String customText;

  /// The server's answer for [customText]; null until it has been asked.
  final UsernameCheck? customCheck;
  final bool isChecking;
  final bool isSaving;

  /// The user has touched a suggestion or the field, as opposed to the
  /// pre-selected first suggestion.
  final bool userPicked;
  final String? error;

  /// The username Continue would save, or null when there is none yet.
  String? get chosen {
    if (!isCustom) return selected;
    final text = normalizeUsername(customText);
    return (customCheck?.isUsable ?? false) && !isChecking ? text : null;
  }

  bool get canSave => chosen != null && !isSaving;

  UsernameChooserState copyWith({
    List<String>? suggestions,
    bool? isLoading,
    bool? loadFailed,
    String? Function()? selected,
    bool? isCustom,
    String? customText,
    UsernameCheck? Function()? customCheck,
    bool? isChecking,
    bool? isSaving,
    bool? userPicked,
    String? Function()? error,
  }) => UsernameChooserState(
    suggestions: suggestions ?? this.suggestions,
    isLoading: isLoading ?? this.isLoading,
    loadFailed: loadFailed ?? this.loadFailed,
    selected: selected == null ? this.selected : selected(),
    isCustom: isCustom ?? this.isCustom,
    customText: customText ?? this.customText,
    customCheck: customCheck == null ? this.customCheck : customCheck(),
    isChecking: isChecking ?? this.isChecking,
    isSaving: isSaving ?? this.isSaving,
    userPicked: userPicked ?? this.userPicked,
    error: error == null ? this.error : error(),
  );
}
