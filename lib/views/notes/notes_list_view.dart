import 'package:flutter/material.dart';
import 'package:learningfirebase/services/crud/notes_service.dart';
import 'package:learningfirebase/utilities/dialogs/delete_dialog.dart';

typedef DeleteNoteCallabck = void Function(DatabaseNote note);

class NotesListView extends StatelessWidget {
  final List<DatabaseNote> notes;
  final DeleteNoteCallabck onDeleteNote;

  const NotesListView({
    super.key,
    required this.notes,
    required this.onDeleteNote,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        return ListTile(
          title: Text(
            note.text,
            maxLines: 1,
            softWrap: true,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: IconButton(onPressed: () async {
            final shouldDelete = await showDeleteDialog(context);
            if (shouldDelete){
              onDeleteNote(note);
            }
          }, icon: const Icon(Icons.delete)),
        );
      },
    );
  }
}
