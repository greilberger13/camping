import '../models/stay_note.dart';

abstract interface class StayNoteRepository {
  List<StayNote> get notes;

  Future<List<StayNote>> load();
  Future<StayNote> create(StayNote note);
  Future<void> delete(StayNote note);
}
