import '../models/pricing.dart';
import 'pricing_repository.dart';

class InMemoryPricingRepository implements PricingRepository {
  Pricing _current = Pricing.initial;

  @override
  Pricing get current => _current;

  @override
  Future<Pricing> load() async => _current;

  @override
  Future<Pricing> save(Pricing pricing) async {
    if (!pricing.isValid) throw StateError('Ungültige Tarife.');
    _current = pricing;
    return _current;
  }
}