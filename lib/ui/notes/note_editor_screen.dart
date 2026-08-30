// lib/ui/notes/note_editor_screen.dart — NOTE-01/NOTE-02. Create-and-edit
// screen for one [Note], reached either from the Ghi chú tab's AppBar create
// action (a blank note, no attachment) or from the item-detail screen's
// "Thêm ghi chú" action (`vehicleId`/`itemId` supplied, P3-D-15). There is no
// vehicle/item picker anywhere on this screen — attachment is reverse-only,
// exactly as P3-D-15 states, and the constructor parameters below are the
// only way `vehicleId`/`itemId` ever reach a [Note] this screen creates.
//
// Controller-per-field, seeded from the existing note and disposed in
// `dispose()` — the same shape as `step2_name_plate.dart`. Save/error/
// `_submitting` follows `onboarding_flow.dart`'s try/catch/finally shape with
// the bare `mounted` guard (CLAUDE.md's BuildContext-after-await trap).
//
// AppBar titles ("Ghi chú mới" / "Sửa ghi chú") and both field hints are
// [NEW, PROVISIONAL] — no verbatim source string exists for this screen;
// flagged in the SUMMARY for UAT (03-UI-SPEC.md).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/id.dart';
import '../../domain/models/maintenance_item.dart';
import '../../domain/models/misc.dart';
import '../../state/app_state.dart';

class NoteEditorScreen extends ConsumerStatefulWidget {
  const NoteEditorScreen({super.key, this.noteId, this.vehicleId, this.itemId});

  /// Null means "create a new note". Non-null edits the note with this id.
  final String? noteId;

  /// Only meaningful when [noteId] is null and this note is being created
  /// from the item-detail screen's "Thêm ghi chú" action (P3-D-15).
  final String? vehicleId;

  /// Same as [vehicleId] — supplied only on creation from an item.
  final String? itemId;

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;

  // Only consulted while `_isNew` — an already-saved note's pinned state is
  // read straight off the provider (via `toggleNotePinned`'s own persisted
  // result), never mirrored into local state, so the two can never drift.
  bool _pinned = false;

  bool _submitting = false;
  String? _error;

  bool get _isNew => widget.noteId == null;

  Note? _findNote(List<Note> notes, String id) {
    for (final n in notes) {
      if (n.id == id) return n;
    }
    return null;
  }

  MaintenanceItem? _findItem(List<MaintenanceItem> items, String id) {
    for (final i in items) {
      if (i.id == id) return i;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    final noteId = widget.noteId;
    final existing = noteId == null
        ? null
        : _findNote(ref.read(appProvider).notes, noteId);
    _titleController = TextEditingController(text: existing?.title ?? '');
    _bodyController = TextEditingController(text: existing?.body ?? '');
    _pinned = existing?.pinned ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _togglePin() async {
    if (_isNew) {
      setState(() => _pinned = !_pinned);
      return;
    }
    // Persists immediately — the whole point of this affordance living in
    // the AppBar rather than round-tripping the full Note through a save.
    await ref.read(appProvider.notifier).toggleNotePinned(widget.noteId!);
  }

  Future<void> _save(Note? existing) async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    // Belt and braces alongside the disabled `[ Lưu ]` button below — the
    // button's disable is what a later refactor drops first.
    if (title.isEmpty && body.isEmpty) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      if (existing == null) {
        final now = DateTime.now().toUtc();
        final note = Note(
          id: newId(),
          vehicleId: widget.vehicleId,
          itemId: widget.itemId,
          title: title.isEmpty ? null : title,
          body: body,
          pinned: _pinned,
          createdAt: now,
          updatedAt: now,
        );
        await ref.read(appProvider.notifier).addNote(note);
      } else {
        final updated = existing.copyWith(
          title: title.isEmpty ? null : title,
          body: body,
        );
        await ref.read(appProvider.notifier).updateNote(updated);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Không thể lưu ghi chú. Vui lòng thử lại.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  Future<void> _confirmDelete() async {
    final noteId = widget.noteId;
    if (noteId == null) return; // unreachable: the action is omitted when new
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xoá ghi chú?'),
        content: const Text('Không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Huỷ'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref.read(appProvider.notifier).deleteNote(noteId);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final notes = ref.watch(appProvider).notes;
    final existing = widget.noteId == null
        ? null
        : _findNote(notes, widget.noteId!);
    final pinned = _isNew ? _pinned : (existing?.pinned ?? false);

    final itemId = existing?.itemId ?? widget.itemId;
    final attachedItem = itemId == null
        ? null
        : _findItem(ref.watch(appProvider).items, itemId);

    final canSave =
        _titleController.text.trim().isNotEmpty ||
        _bodyController.text.trim().isNotEmpty;
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? 'Ghi chú mới' : 'Sửa ghi chú'),
        actions: [
          IconButton(
            icon: Icon(pinned ? Icons.push_pin : Icons.push_pin_outlined),
            tooltip: 'Ghim ghi chú',
            onPressed: _togglePin,
          ),
          // H7 destructive: conditionally omitted for a not-yet-saved draft
          // — not rendered with a null onPressed.
          if (!_isNew)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Xoá ghi chú',
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: SafeArea(
        // H7 overflow: tracks the soft keyboard the same way the service-log
        // sheet does, even though this is a Scaffold screen, not a sheet.
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            16 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (attachedItem != null) ...[
                Text(
                  'Đính kèm: ${attachedItem.name}',
                  style: TextStyle(fontSize: 12, color: onSurfaceVariant),
                ),
                const SizedBox(height: 16),
              ],
              TextField(
                controller: _titleController,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Tiêu đề (không bắt buộc)',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _bodyController,
                onChanged: (_) => setState(() {}),
                maxLines: null,
                decoration: const InputDecoration(
                  hintText: 'Viết điều bạn muốn nhớ…',
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton(
                // H7 empty: null while both trimmed fields are blank — the
                // handler's own early return above is belt-and-braces.
                onPressed: (_submitting || !canSave)
                    ? null
                    : () => _save(existing),
                child: const Text('Lưu'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
