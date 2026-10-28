import '../../../core/widgets/username_picker.dart';
import '../domain/username.dart';
import '../domain/username_chooser_state.dart';

/// How the typed username stands, for [UsernamePicker]'s line under the
/// field: the status icon and the message. Shared by setup step 3 and the
/// Change username sheet.
(UsernameFieldStatus, String?) usernameFieldStatus(UsernameChooserState state) {
  // The check runs quietly in the background: nothing is shown while it
  // does, and Save waits for it.
  if (state.isChecking) return (UsernameFieldStatus.idle, null);
  final check = state.customCheck;
  if (check == null) return (UsernameFieldStatus.idle, null);
  if (check.isUsable) {
    return (
      UsernameFieldStatus.ok,
      check == UsernameCheck.yours
          ? 'That is your current name.'
          : 'Nice, it is free.',
    );
  }
  return (UsernameFieldStatus.problem, check.problemMessage);
}
