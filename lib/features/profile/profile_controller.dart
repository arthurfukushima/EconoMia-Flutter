import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../data/models/user_profile.dart';
import '../../data/prefs.dart';

final profileControllerProvider =
    NotifierProvider<ProfileController, UserProfile?>(ProfileController.new);

class ProfileController extends Notifier<UserProfile?> {
  @override
  UserProfile? build() => ref.read(prefsProvider).userProfile;

  bool get hasProfile => state != null;

  Future<bool> createLocalProfile(String displayName) async {
    final name = displayName.trim();
    if (name.isEmpty) return false;
    final profile = UserProfile(
      displayName: name,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      authMode: UserProfile.localAuthMode,
    );
    state = profile;
    await ref.read(prefsProvider).setUserProfile(profile);
    return true;
  }

  Future<void> clear() async {
    state = null;
    await ref.read(prefsProvider).clearUserProfile();
  }
}
