import '../core/supabase_database.dart';
import '../models/stay_note.dart';
import 'stay_note_repository.dart';

class SupabaseStayNoteRepository implements StayNoteRepository {
  SupabaseStayNoteRepository(this.database);

  final SupabaseDatabase database;
  final cache = <StayNote>[];

  @override
  List<StayNote> get notes => List.unmodifiable(cache);

  @override
  Future<List<StayNote>> load() async {
    final rows = await database.client
      .from('stay_notes')
      .select('*, site:camp_sites(site_number)')
      .order('created_at');
    cache
      ..clear()
      ..addAll(rows.map(_fromRow));
    return notes;
  }

  @override
  Future<StayNote> create(StayNote note) async {
    final siteId = await _siteIdForNumber(note.siteNumber);
    final row = await database.client
        .from('stay_notes')
        .insert({
          'site_id': siteId,
          'category': _categoryValue(note.category),
          'note_text': note.text,
        })
        .select()
        .single();
    final stored = _fromRow(row);
    cache.add(stored);
    return stored;
  }

  @override
  Future<void> delete(StayNote note) async {
    if (note.id == null) {
      throw StateError('Cannot delete a note without an id.');
    }
    await database.client.from('stay_notes').delete().eq('id', note.id!);
    cache.removeWhere((item) => item.id == note.id);
  }

  StayNote _fromRow(Map<String, dynamic> row) {
    final site = row['site'] as Map<String, dynamic>?;
    return StayNote(
      id: row['id'] as String?,
      siteNumber: site?['site_number'] as int? ?? 0,
      text: row['note_text'] as String,
      category: _categoryFromValue(row['category'] as String),
    );
  }

  Future<String> _siteIdForNumber(int siteNumber) async {
    final row = await database.client
        .from('camp_sites')
        .select('id')
        .eq('site_number', siteNumber)
        .single();
    return row['id'] as String;
  }

  String _categoryValue(StayNoteCategory category) {
    switch (category) {
      case StayNoteCategory.bakery:
        return 'bakery';
      case StayNoteCategory.foodAndDrinks:
        return 'food_and_drinks';
      case StayNoteCategory.general:
        return 'general';
    }
  }

  StayNoteCategory _categoryFromValue(String value) {
    switch (value) {
      case 'bakery':
        return StayNoteCategory.bakery;
      case 'food_and_drinks':
        return StayNoteCategory.foodAndDrinks;
      default:
        return StayNoteCategory.general;
    }
  }
}
