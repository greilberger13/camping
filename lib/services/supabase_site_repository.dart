import 'package:flutter/material.dart';

import '../core/supabase_database.dart';
import '../models/camp_site.dart';
import 'site_repository.dart';

class SupabaseSiteRepository implements SiteRepository {
  SupabaseSiteRepository(this.database);

  final SupabaseDatabase database;
  final cache = <CampSite>[];

  @override
  List<CampSite> get sites => List.unmodifiable(cache);

  @override
  Future<List<CampSite>> load() async {
    final rows = await database.client.from('camp_sites').select().order('site_number');
    cache
      ..clear()
      ..addAll(rows.map(_fromRow));
    return sites;
  }

  @override
  Future<CampSite> update(CampSite site) async {
    final row = await database.client
        .from('camp_sites')
        .update({'status': _statusValue(site.status)})
        .eq('site_number', site.number)
        .select()
        .single();
    final updated = _fromRow(row);
    final index = cache.indexWhere((item) => item.number == site.number);
    if (index != -1) cache[index] = updated;
    return updated;
  }

  CampSite _fromRow(Map<String, dynamic> row) {
    return CampSite(
      row['site_number'] as int,
      _displayType(row['site_type'] as String),
      _displayStatus(row['status'] as String),
      _parseColor(row['default_color'] as String),
    );
  }

  Color _parseColor(String value) {
    final hex = value.replaceFirst('#', '');
    return Color(int.parse('ff$hex', radix: 16));
  }

  String _displayType(String value) {
    switch (value) {
      case 'car_van':
        return 'Auto / Van';
      case 'tent':
        return 'Zelt';
      case 'car_with_trailer':
        return 'Auto mit Anhänger';
      default:
        return 'Wohnmobil';
    }
  }

  String _displayStatus(String value) {
    switch (value) {
      case 'occupied':
        return 'Belegt';
      case 'reserved':
        return 'Reserviert';
      case 'blocked':
        return 'Gesperrt';
      default:
        return 'Frei';
    }
  }

  String _statusValue(String value) {
    switch (value) {
      case 'Belegt':
        return 'occupied';
      case 'Reserviert':
        return 'reserved';
      case 'Gesperrt':
        return 'blocked';
      default:
        return 'free';
    }
  }
}
