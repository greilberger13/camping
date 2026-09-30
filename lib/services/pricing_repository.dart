import '../models/pricing.dart';

abstract interface class PricingRepository {
  Pricing get current;

  Future<Pricing> load();
  Future<Pricing> save(Pricing pricing);
}