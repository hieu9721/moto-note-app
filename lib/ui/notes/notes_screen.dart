// lib/ui/notes/notes_screen.dart — NOTE-02. Pinned-first note list. Plan 01
// wired the shell (list + sort + empty state); this plan (03-05) makes every
// row tappable into `note_editor_screen.dart` and adds the AppBar create
// action — per 03-UI-SPEC.md's H6 `interactive-control` row, the create
// affordance is an AppBar action rather than a FloatingActionButton (the FAB
// slot and colorScheme.primary are reserved for the home screen's "Cập nhật
// số km" — see 03-05-PLAN.md's "Reconciliation with 03-UI-SPEC.md"), and
// pinning is toggled only from inside the editor — the trailing pin `Icon`
// below keeps its shipped slot/tint with no `onTap` of its own; tapping it
// simply falls through to the row's own `onTap`.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/misc.dart';
import '../../state/app_state.dart';
import '../widgets/empty_state.dart';

class NotesScreen extends ConsumerWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = sortedNotes(ref.watch(appProvider).notes);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ghi chú'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Ghi chú mới',
            onPressed: () => context.push('/notes/new'),
          ),
        ],
      ),
      body: SafeArea(
        child: notes.isEmpty
            ? const EmptyState(
                icon: Icons.note_outlined,
                message:
                    'Ghi lại điều bạn muốn nhớ sẵn khi đứng trước xe — ở tiệm sửa '
                    'hay bất cứ đâu.',
              )
            : ListView(
                children: [
                  for (final note in notes)
                    ListTile(
                      title: Text(noteDisplayTitle(note)),
                      trailing: note.pinned ? const Icon(Icons.push_pin) : null,
                      onTap: () => context.push('/notes/${note.id}'),
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

/// The note's title, or the first line of its body when the title is null.
/// Public so plan 06's pinned-notes block on the home screen can reuse this
/// exact function rather than duplicating the title-or-first-line-of-body
/// fallback (03-UI-SPEC.md, Home screen assembly step 7).
String noteDisplayTitle(Note note) {
  final title = note.title;
  if (title != null && title.isNotEmpty) return title;
  if (note.body.isEmpty) return '';
  return note.body.split('\n').first;
}
