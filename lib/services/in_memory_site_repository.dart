import '../models/camp_site.dart';
import 'site_repository.dart';

class InMemorySiteRepository implements SiteRepository {
  InMemorySiteRepository({List<CampSite>? initial})
      : _sites = [
          for (final site in initial ?? CampSite.samples)
            initial == null ? site.copyWith(status: 'Frei') : site,
        ];

  final List<CampSite> _sites;

  @override
  List<CampSite> get sites => List.unmodifiable(_sites);

  @override
  Future<List<CampSite>> load() async => sites;

  @override
  Future<CampSite> update(CampSite site) async {
    final index = _sites.indexWhere((item) => item.number == site.number);
    if (index == -1) {
      throw StateError('Site not found: ${site.number}');
    }
    _sites[index] = site;
    return site;
  }
}
