import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/profile/domain/username.dart';
import 'package:kaunti47_v2/src/features/profile/domain/username_chooser_state.dart';

void main() {
  group('UsernameCheck', () {
    test('parses the server codes, unknown means invalid', () {
      expect(UsernameCheck.parse('available'), UsernameCheck.available);
      expect(UsernameCheck.parse('yours'), UsernameCheck.yours);
      expect(UsernameCheck.parse('taken'), UsernameCheck.taken);
      expect(UsernameCheck.parse('reserved'), UsernameCheck.reserved);
      expect(UsernameCheck.parse('blocked'), UsernameCheck.blocked);
      expect(UsernameCheck.parse('nonsense'), UsernameCheck.invalid);
      expect(UsernameCheck.parse(null), UsernameCheck.invalid);
    });

    test('only available and yours can be saved', () {
      for (final check in UsernameCheck.values) {
        final usable =
            check == UsernameCheck.available || check == UsernameCheck.yours;
        expect(check.isUsable, usable);
        expect(check.problemMessage == null, usable);
      }
    });
  });

  group('normalizeUsername', () {
    test('trims and lowercases', () {
      expect(normalizeUsername('  Nyati7 '), 'nyati7');
    });
  });

  group('UsernameChooserState.chosen', () {
    test('a picked suggestion is the choice', () {
      const state = UsernameChooserState(
        suggestions: ['nyati7', 'chui12'],
        isLoading: false,
        selected: 'chui12',
      );
      expect(state.chosen, 'chui12');
      expect(state.canSave, isTrue);
    });

    test('own text counts only once the server says it is free', () {
      const typing = UsernameChooserState(
        isLoading: false,
        isCustom: true,
        customText: ' Simba-Fan ',
        isChecking: true,
      );
      expect(typing.chosen, isNull);

      final taken = typing.copyWith(
        isChecking: false,
        customCheck: () => UsernameCheck.taken,
      );
      expect(taken.chosen, isNull);

      final free = typing.copyWith(
        isChecking: false,
        customCheck: () => UsernameCheck.available,
      );
      expect(free.chosen, 'simba-fan');
    });

    test('nothing can be saved while saving', () {
      const state = UsernameChooserState(
        isLoading: false,
        selected: 'nyati7',
        isSaving: true,
      );
      expect(state.canSave, isFalse);
    });
  });
}
