import 'package:economia/data/prefs.dart';
import 'package:economia/data/models/user_profile.dart';
import 'package:economia/features/profile/profile_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<Prefs> _prefs({Map<String, Object> initial = const {}}) async {
  SharedPreferences.setMockInitialValues(initial);
  return Prefs(await SharedPreferences.getInstance());
}

void main() {
  test('starts with the saved local profile', () async {
    final prefs = await _prefs(
      initial: {
        'economia.userProfile':
            '{"displayName":"Ana","createdAt":123,"authMode":"local_v1"}',
      },
    );
    final container = ProviderContainer(
      overrides: [prefsProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    expect(container.read(profileControllerProvider)!.displayName, 'Ana');
  });

  test('saves a trimmed display name', () async {
    final prefs = await _prefs();
    final container = ProviderContainer(
      overrides: [prefsProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    final ok = await container
        .read(profileControllerProvider.notifier)
        .createLocalProfile('  Bruno  ');

    expect(ok, isTrue);
    expect(container.read(profileControllerProvider)!.displayName, 'Bruno');
    expect(prefs.userProfile!.displayName, 'Bruno');
    expect(prefs.userProfile!.authMode, UserProfile.localAuthMode);
  });

  test('rejects blank display names', () async {
    final prefs = await _prefs();
    final container = ProviderContainer(
      overrides: [prefsProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    final ok = await container
        .read(profileControllerProvider.notifier)
        .createLocalProfile('   ');

    expect(ok, isFalse);
    expect(container.read(profileControllerProvider), isNull);
    expect(prefs.userProfile, isNull);
  });
}
