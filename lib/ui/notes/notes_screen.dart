// lib/ui/notes/notes_screen.dart — NOTE-02. Pinned-first note list. This
// plan's task 1 wires the shell (list + sort + empty state); task 2 gives
// the empty state its final copy.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/misc.dart';
import '../../state/app_state.dart';

class NotesScreen extends ConsumerWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = sortedNotes(ref.watch(appProvider).notes);

    return Scaffold(
      appBar: AppBar(title: const Text('Ghi chú')),
      body: SafeArea(
        child: notes.isEmpty
            ? const _EmptyNotes()
            : ListView(
                children: [
                  for (final note in notes)
                    ListTile(
                      title: Text(_noteDisplayTitle(note)),
                      trailing: note.pinned ? const Icon(Icons.push_pin) : null,
                    ),
                ],
              ),
      ),
    );
  }
}

/// A **total** comparator over a copy of [notes]: pinned strictly before
/// unpinned, then `updatedAt` descending, then `id` ascending. The `id`
/// tie-break is not optional — Dart's `List.sort` is not stable, and two
/// notes sharing both `pinned` and `updatedAt` would otherwise land in an
/// unspecified order that could reshuffle between rebuilds
/// (`dueItemsProvider` carries the identical hardening for the identical
/// reason — see `lib/state/derived.dart`).
List<Note> sortedNotes(List<Note> notes) {
  final sorted = [...notes];
  sorted.sort((a, b) {
    if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
    final byUpdatedAt = b.updatedAt.compareTo(a.updatedAt);
    if (byUpdatedAt != 0) return byUpdatedAt;
    return a.id.compareTo(b.id);
  });
  return sorted;
}

/// The note's title, or the first line of its body when the title is null —
/// rows are not yet tappable, since the editor arrives in plan 05.
String _noteDisplayTitle(Note note) {
  final title = note.title;
  if (title != null && title.isNotEmpty) return title;
  if (note.body.isEmpty) return '';
  return note.body.split('\n').first;
}

/// Final copy (Claude's Discretion per 03-CONTEXT.md — the empty state's
/// wording was explicitly left to planning, unlike every other string in
/// this phase, which ships verbatim from the source document). Follows
/// `welcome_screen.dart`'s centred-column idiom.
class _EmptyNotes extends StatelessWidget {
  const _EmptyNotes();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Ghi lại điều bạn muốn nhớ sẵn khi đứng trước xe — ở tiệm sửa '
          'hay bất cứ đâu.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
