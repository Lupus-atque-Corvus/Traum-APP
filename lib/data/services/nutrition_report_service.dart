import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../database/traum_database.dart';
import 'nutrition_report_data.dart';

/// Maps a [MealEntry] row (already fetched for a date range) plus its
/// (possibly missing) [FoodProduct] into a [ReportEntry].
///
/// `MealEntries.calories/protein/carbs/fat` are already the *scaled*
/// macros for the logged `amountGrams` (computed once at log time in
/// `AmountEntrySheet._save()` as `product.xPer100g * grams / 100` and
/// persisted on the entry) — so this mapper reads them directly from the
/// entry instead of recomputing `per100g * grams / 100` from the joined
/// product. That is both simpler and more correct: it reflects what the
/// user actually logged even if the product's per-100g values were edited
/// afterwards. The joined [FoodProduct] is only used for its display name.
///
/// Pure (no DB/IO), so it is unit-testable without spinning up a database.
ReportEntry mapToReportEntry(MealEntry entry, FoodProduct? product) {
  return ReportEntry(
    day: DateTime.parse(entry.date),
    meal: entry.mealType,
    foodName: product?.name ?? 'Unbekanntes Produkt',
    grams: entry.amountGrams,
    kcal: entry.calories,
    protein: entry.protein,
    carbs: entry.carbs,
    fat: entry.fat,
  );
}

class NutritionReportService {
  final TraumDatabase _db;
  NutritionReportService(this._db);

  Future<List<ReportEntry>> _loadEntries(DateTime from, DateTime to) async {
    final entries = await _db.mealEntriesDao.getEntriesBetween(from, to);
    if (entries.isEmpty) return const [];
    // Bulk-load all products once instead of N+1 lookups per entry.
    final products = await _db.foodProductsDao.getAll();
    final productById = {for (final p in products) p.id: p};
    return entries
        .map((e) => mapToReportEntry(e, productById[e.productId]))
        .toList();
  }

  Future<File> generatePdf({required DateTime from, required DateTime to}) async {
    final entries = await _loadEntries(from, to);
    final sections = buildDailySections(entries);

    final fontRegular =
        pw.Font.ttf(await rootBundle.load('assets/fonts/DMSans-Regular.ttf'));
    final fontBold =
        pw.Font.ttf(await rootBundle.load('assets/fonts/DMSans-Bold.ttf'));

    final doc = pw.Document();
    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
      build: (ctx) => [
        pw.Header(level: 0, text: 'Ernährungsprotokoll'),
        pw.Paragraph(
            text: 'Zeitraum: ${_fmt(from)} – ${_fmt(to)} · '
                'erstellt mit TRAUM am ${_fmt(DateTime.now())}'),
        _summaryTable(sections),
        ...sections.map(_daySection),
      ],
    ));

    final dir = await getTemporaryDirectory();
    final file = File(
        '${dir.path}/ernaehrung_${_fileStamp(from)}_${_fileStamp(to)}.pdf');
    await file.writeAsBytes(await doc.save());
    return file;
  }

  pw.Widget _summaryTable(List<DailySection> sections) {
    final days = sections.length;
    double avg(double Function(DailySection) f) => days == 0
        ? 0
        : sections.fold(0.0, (a, s) => a + f(s)) / days;
    return pw.TableHelper.fromTextArray(
      headers: ['Ø pro Tag', 'Kalorien', 'Protein', 'Kohlenhydrate', 'Fett'],
      data: [[
        '$days Tage',
        '${avg((s) => s.totalKcal).toStringAsFixed(0)} kcal',
        '${avg((s) => s.totalProtein).toStringAsFixed(0)} g',
        '${avg((s) => s.totalCarbs).toStringAsFixed(0)} g',
        '${avg((s) => s.totalFat).toStringAsFixed(0)} g',
      ]],
    );
  }

  pw.Widget _daySection(DailySection s) {
    const mealLabels = {
      'breakfast': 'Frühstück', 'lunch': 'Mittagessen',
      'dinner': 'Abendessen', 'snack': 'Snacks',
    };
    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.SizedBox(height: 12),
      pw.Header(level: 1, text: _fmt(s.day)),
      for (final meal in s.meals.entries) ...[
        pw.Text(mealLabels[meal.key] ?? meal.key,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.TableHelper.fromTextArray(
          headers: ['Lebensmittel', 'Menge', 'kcal', 'P', 'K', 'F'],
          data: meal.value
              .map((e) => [
                    e.foodName,
                    '${e.grams.toStringAsFixed(0)} g',
                    e.kcal.toStringAsFixed(0),
                    '${e.protein.toStringAsFixed(1)} g',
                    '${e.carbs.toStringAsFixed(1)} g',
                    '${e.fat.toStringAsFixed(1)} g',
                  ])
              .toList(),
        ),
        pw.SizedBox(height: 6),
      ],
      pw.Text(
          'Tagessumme: ${s.totalKcal.toStringAsFixed(0)} kcal · '
          'Protein ${s.totalProtein.toStringAsFixed(0)} g · '
          'KH ${s.totalCarbs.toStringAsFixed(0)} g · '
          'Fett ${s.totalFat.toStringAsFixed(0)} g',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
    ]);
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
  String _fileStamp(DateTime d) =>
      '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';
}
