/// SwarnaLekh shared UI kit — the single canonical set of building blocks every
/// feature screen composes. Import this instead of reaching for bespoke
/// per-screen widgets, so the app stays visually uniform with zero duplication.
///
/// Canonical choices:
/// - Rows/list items  → [CompactDataRow]      (do not build custom DataTables)
/// - Stat summaries    → [CompactStatStrip]    (do not build StatCard grids)
/// - Module page shell → [AppSectionScaffold]  (header + section tabs + refresh)
/// - Async data body   → [AppStateView]        (loading / empty / error / data)
/// - Heavy forms       → [AppFormScaffold]     (full-screen route, never dialogs)
/// - Read-only detail  → [AppDetailSheet]
/// - Advanced filters  → [AppFilterSheet]      (search stays on-screen)
library;

export 'app_detail_sheet.dart';
export 'app_filter_sheet.dart';
export 'app_form_scaffold.dart';
export 'app_section_scaffold.dart';
export 'app_state_view.dart';
export 'common_widgets.dart';
export 'compact_data_row.dart';
export 'compact_stat_strip.dart';
export 'empty_state.dart';
export 'keyboard_aware.dart';
export 'search_filter_bar.dart';
export 'section_switch.dart';
export 'shimmer_loading.dart';
