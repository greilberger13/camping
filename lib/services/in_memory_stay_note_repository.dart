import '../models/stay_note.dart';
import 'stay_note_repository.dart';

class InMemoryStayNoteRepository implements StayNoteRepository {
  final _notes = <StayNote>[];

  @override
  List<StayNote> get notes => List.unmodifiable(_notes);

  @override
  Future<List<StayNote>> load() async => notes;

  @override
  Future<StayNote> create(StayNote note) async {
    final stored = note.copyWith(id: _newId());
    _notes.add(stored);
    return stored;
  }

  @override
  Future<void> delete(StayNote note) async {
    _notes.removeWhere((item) => item.id == note.id);
  }

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();
}
