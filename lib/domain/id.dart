// lib/domain/id.dart — pure Dart, keeps lib/domain/ Flutter-free (D-31).
//
// Resolves the "Claude's Discretion" item from 01-CONTEXT.md: §5.2 calls
// newId() and §4.2 comments "nanoid / uuid v4" but no id package appears in
// §3.1. `uuid` has no Flutter dependency, so it doesn't violate D-31, and
// it avoids hand-rolling a generator inside a `utils/` directory §12 forbids.
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

String newId() => _uuid.v4();
