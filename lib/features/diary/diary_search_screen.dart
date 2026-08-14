import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/radius.dart';
import '../../core/utils/search_debouncer.dart';
import '../../data/database/traum_database.dart';
import '../../l10n/app_localizations.dart';
import 'diary_provider.dart';

class DiarySearchScreen extends ConsumerStatefulWidget {
  const DiarySearchScreen({super.key});

  @override
  ConsumerState<DiarySearchScreen> createState() => _DiarySearchScreenState();
}

class _DiarySearchScreenState extends ConsumerState<DiarySearchScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  final _searchDebounce = SearchDebouncer();

  @override
  void dispose() {
    _searchDebounce.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce(value, (settled) {
      if (mounted) setState(() => _query = settled);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final diaryId = ref.watch(activeDiaryProvider);
    final resultsAsync = ref.watch(
      diarySearchResultsProvider((diaryId, _query)),
    );

    return Scaffold(
      backgroundColor: TraumColors.background,
      appBar: AppBar(
        backgroundColor: TraumColors.background,
        elevation: 0,
        leading: IconButton(
          tooltip: l10n.back,
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: TraumColors.onBackground,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: TextField(
          controller: _searchCtrl,
          autofocus: true,
          style: const TextStyle(
            color: TraumColors.onBackground,
            fontFamily: 'DMSans',
          ),
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: l10n.searchHint,
            hintStyle: const TextStyle(
              color: TraumColors.onBackgroundSubtle,
              fontFamily: 'DMSans',
            ),
          ),
          onChanged: _onSearchChanged,
        ),
      ),
      body: _query.trim().isEmpty
          ? Center(
              child: Text(
                l10n.searchHint,
                style: const TextStyle(
                  color: TraumColors.onBackgroundSubtle,
                  fontFamily: 'DMSans',
                ),
              ),
            )
          : resultsAsync.when(
              data: (results) {
                if (results.isEmpty) {
                  return Center(
                    child: Text(
                      l10n.noResultsForQuery(_query),
                      style: const TextStyle(
                        color: TraumColors.onBackgroundMuted,
                        fontFamily: 'DMSans',
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: results.length,
                  itemBuilder: (context, i) =>
                      _DiarySearchResultTile(entry: results[i]),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: TraumColors.lavender),
              ),
              error: (e, _) => Center(child: Text('$e')),
            ),
    );
  }
}

class _DiarySearchResultTile extends StatelessWidget {
  const _DiarySearchResultTile({required this.entry});

  final DiaryEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final d = DateTime.tryParse(entry.date);
    final months = [
      l10n.monthShortJan,
      l10n.monthShortFeb,
      l10n.monthShortMar,
      l10n.monthShortApr,
      l10n.monthShortMay,
      l10n.monthShortJun,
      l10n.monthShortJul,
      l10n.monthShortAug,
      l10n.monthShortSep,
      l10n.monthShortOct,
      l10n.monthShortNov,
      l10n.monthShortDec,
    ];
    final dateLabel = d == null
        ? entry.date
        : '${d.day}. ${months[d.month - 1]} ${d.year}';

    return Material(
      color: TraumColors.surface,
      borderRadius: BorderRadius.circular(TraumRadius.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(TraumRadius.card),
        onTap: () => context.go('/diary/entry/${entry.date}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dateLabel,
                style: const TextStyle(
                  color: TraumColors.lavender,
                  fontFamily: 'DMSans',
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                entry.note,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: TraumColors.onBackground,
                  fontFamily: 'DMSans',
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
