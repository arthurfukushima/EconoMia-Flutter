import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_location.freezed.dart';
part 'app_location.g.dart';

/// The search centre for everything "nearby".
///
/// Comes from `/api/cep` in both directions — a CEP resolves to coordinates,
/// and GPS coordinates reverse-resolve to a city label. Pricing always uses the
/// raw [lat]/[lng]; [city], [state] and [cep] are cosmetic.
@freezed
abstract class AppLocation with _$AppLocation {
  const factory AppLocation({
    required double lat,
    required double lng,
    String? cep,
    String? city,
    String? state,

    /// Search radius in km, from the picker's `[1, 5, 10, 15, 25, 50]`.
    /// The backend defaults to 25 but the client always sends this explicitly —
    /// 50 is the widest Menor Preço accepts and the honest default for a CEP
    /// centroid.
    @Default(50) int raio,

    /// True when [lat]/[lng] came from GPS rather than a CEP centroid.
    /// A precise fix is what lets "which market am I in?" narrow its radius
    /// instead of dragging in a whole city.
    @Default(false) bool precise,
  }) = _AppLocation;

  factory AppLocation.fromJson(Map<String, dynamic> json) =>
      _$AppLocationFromJson(json);
}
