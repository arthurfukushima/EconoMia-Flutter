import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/api_client.dart';
import '../../data/economia_api.dart';
import '../../data/models/app_location.dart';
import '../../data/prefs.dart';

/// The saved search centre — null until the user sets one by CEP or GPS.
/// [LocationController] is the only writer; every screen that needs "nearby"
/// reads this.
final locationControllerProvider = NotifierProvider<LocationController, AppLocation?>(
  LocationController.new,
);

/// A CEP/GPS request in flight. Kept out of [locationControllerProvider]'s own
/// state so a request that's still running never blanks out a location that
/// already works.
final locationBusyProvider = StateProvider<bool>((ref) => false);

/// The last CEP/GPS failure, cleared at the start of every new request.
final locationErrorProvider = StateProvider<ApiException?>((ref) => null);

class LocationController extends Notifier<AppLocation?> {
  @override
  AppLocation? build() => ref.read(prefsProvider).location;

  Future<void> _persist(AppLocation loc) async {
    state = loc;
    await ref.read(prefsProvider).setLocation(loc);
  }

  Future<void> _run(Future<void> Function() body) async {
    ref.read(locationErrorProvider.notifier).state = null;
    ref.read(locationBusyProvider.notifier).state = true;
    try {
      await body();
    } on ApiException catch (e) {
      ref.read(locationErrorProvider.notifier).state = e;
    } finally {
      ref.read(locationBusyProvider.notifier).state = false;
    }
  }

  /// CEP → search centre. Keeps the current raio, or the 50km default for a
  /// first-ever location.
  Future<void> setCep(String cepInput) => _run(() async {
        final loc = await ref.read(economiaApiProvider).resolveCep(cepInput);
        await _persist(loc.copyWith(raio: state?.raio ?? 50));
      });

  /// GPS fix, reverse-geocoded to a city/CEP label. The fix is kept even when
  /// the label lookup fails — it's the expensive, real part; the label is
  /// cosmetic (see [EconomiaApi.resolveCoords]).
  Future<void> useGps() => _run(() async {
        final pos = await _currentPosition();
        var loc = AppLocation(
          lat: pos.latitude,
          lng: pos.longitude,
          precise: true,
          cep: state?.cep,
          city: state?.city,
          state: state?.state,
          raio: state?.raio ?? 50,
        );
        try {
          final place = await ref.read(economiaApiProvider).resolveCoords(pos.latitude, pos.longitude);
          loc = place.copyWith(raio: loc.raio);
        } on ApiException catch (e) {
          ref.read(locationErrorProvider.notifier).state = e;
        }
        await _persist(loc);
      });

  /// No-ops until a location exists — the picker only appears once one does.
  Future<void> setRaio(int raio) async {
    final current = state;
    if (current == null) return;
    await _persist(current.copyWith(raio: raio));
  }

  Future<Position> _currentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const ApiException('geo_unsupported');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      throw const ApiException('geo_denied');
    }
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } catch (_) {
      throw const ApiException('geo_failed');
    }
  }
}
