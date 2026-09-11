import '../models/camp_site.dart';

abstract interface class SiteRepository {
  List<CampSite> get sites;

  Future<List<CampSite>> load();
  Future<CampSite> update(CampSite site);
}
