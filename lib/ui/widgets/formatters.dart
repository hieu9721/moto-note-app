// lib/ui/widgets/formatters.dart — the one file in `lib/ui/` that owns
// `intl` (HOME-01/HOME-02, 03-RESEARCH.md Pattern 7). Four top-level
// functions, each wrapping a private, module-level format object so the
// underlying `NumberFormat`/`DateFormat` is constructed exactly once.
//
// Deliberate asymmetry, verified this session against the installed
// `intl-0.20.3` package source (03-RESEARCH.md Pattern 7), not assumed from
// habit: `NumberFormat`'s locale-symbol map is a plain, eagerly-populated
// `Map<String, NumberSymbols>` compiled into the package — `'vi_VN'`
// canonicalises down to the `'vi'` entry with no initialisation call, so both
// number formatters below take the locale argument. `DateFormat`'s
// locale-symbol table is an `UninitializedLocaleData` sentinel that throws
// `LocaleDataException` for any locale other than `en_US` until
// `initializeDateFormatting()` has run. Both date skeletons this phase needs
// (`dd/MM/yyyy`, `dd/MM`) are purely numeric — no month or weekday name — so
// their digit output under the always-available `en_US` fallback is
// identical to `vi_VN`'s. Passing no locale argument avoids depending on
// `initializeDateFormatting()` having already run for these two formats.
//
// Both date functions take LOCAL `DateTime`s: callers convert from the
// stored UTC value before formatting, because a civil date is a local
// concept (see `lib/domain/due.dart`'s own `_dateOnly` rationale) — this
// file does no UTC-to-local conversion itself.
import 'package:intl/intl.dart';

final NumberFormat _kmFmt = NumberFormat.decimalPattern('vi_VN');
final NumberFormat _vndFmt = NumberFormat.currency(
  locale: 'vi_VN',
  symbol: '₫',
  decimalDigits: 0,
);
final DateFormat _dateFmt = DateFormat('dd/MM/yyyy');
final DateFormat _shortDateFmt = DateFormat('dd/MM');

/// "18420" → "18.420" — dot thousands separator, no decimals.
String formatKm(int km) => _kmFmt.format(km);

/// "130000" → "130.000 ₫" — VND has no minor unit.
String formatVnd(int vnd) => _vndFmt.format(vnd);

/// A local [DateTime] → "28/08/2026".
String formatDate(DateTime d) => _dateFmt.format(d);

/// A local [DateTime] → "02/06" — LOG-04's "↳ giống lần trước (02/06)".
String formatShortDate(DateTime d) => _shortDateFmt.format(d);
