import '../core/supabase_database.dart';
import '../models/pricing.dart';
import 'pricing_repository.dart';

class SupabasePricingRepository implements PricingRepository {
  SupabasePricingRepository(this.database);

  final SupabaseDatabase database;
  Pricing _current = Pricing.initial;

  @override
  Pricing get current => _current;

  @override
  Future<Pricing> load() async {
    final row = await database.client
        .from('pricing')
        .select()
        .eq('id', 1)
        .single();
    _current = _fromRow(row);
    return _current;
  }

  @override
  Future<Pricing> save(Pricing pricing) async {
    if (!pricing.isValid) throw StateError('Ungültige Tarife.');
    final row = await database.client
        .from('pricing')
        .update({
          'site_per_night': pricing.sitePerNight,
          'adult_per_stay': pricing.adultPerStay,
          'child_per_stay': pricing.childPerStay,
        })
        .eq('id', 1)
        .select()
        .single();
    _current = _fromRow(row);
    return _current;
  }

  Pricing _fromRow(Map<String, dynamic> row) => Pricing(
        sitePerNight: (row['site_per_night'] as num).toDouble(),
        adultPerStay: (row['adult_per_stay'] as num).toDouble(),
        childPerStay: (row['child_per_stay'] as num).toDouble(),
      );
}