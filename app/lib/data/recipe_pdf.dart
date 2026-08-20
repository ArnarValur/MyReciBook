// Recipe → PDF (export track, D1). The document a non-technical user actually
// wants: something they can mail, print, or drop in a shared folder without
// anyone asking what a .json is.
//
// Deliberately dumb: it takes lines of text that the CALLER already rendered
// through convertUnits + linkedIngredientLine, so the page says exactly what
// the screen said — unit toggle and pantry links included. No parsing here.

import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// The per-serving block, already worded by the caller so the page repeats
/// the screen's honesty contract verbatim: '~' on every number unless every
/// ingredient is covered, and a note saying how many were. On paper this
/// matters more than on screen — nobody can tap a printed number to find out
/// it was estimated from 3 of 11 ingredients.
class NutritionBlock {
  final String headline;
  final String macros;
  final String note;

  const NutritionBlock({
    required this.headline,
    required this.macros,
    required this.note,
  });
}

/// One recipe, already rendered to display strings by the screen.
class RecipePdfData {
  final String title;
  final String? servings;
  final String? time;
  final String? sourceLine;
  final String? notes;

  /// Ingredient display lines, in order. A null entry is a group heading
  /// carried in [groupBefore] — kept as parallel data so the caller does not
  /// have to invent a marker syntax.
  final List<String> ingredients;

  /// index in [ingredients] → the group heading printed above it.
  final Map<int, String> groupBefore;

  final List<String> steps;

  /// Cover image bytes (jpg/png) or null. Scaled to fit, never cropped.
  final Uint8List? cover;

  /// Null when the recipe has no serving count or no linked ingredient —
  /// then the page says nothing at all rather than an empty promise.
  final NutritionBlock? nutrition;

  const RecipePdfData({
    required this.title,
    required this.ingredients,
    required this.steps,
    this.groupBefore = const {},
    this.servings,
    this.time,
    this.sourceLine,
    this.notes,
    this.cover,
    this.nutrition,
  });
}

/// A4 by default; the print dialog can re-flow to Letter without us caring.
Future<Uint8List> buildRecipePdf(RecipePdfData r,
    {PdfPageFormat format = PdfPageFormat.a4}) async {
  final doc = pw.Document(title: r.title);

  final meta = [
    if (r.servings != null && r.servings!.isNotEmpty) r.servings!,
    if (r.time != null && r.time!.isNotEmpty) r.time!,
  ].join('  ·  ');

  doc.addPage(
    pw.MultiPage(
      pageFormat: format.copyWith(
        marginLeft: 2.2 * PdfPageFormat.cm,
        marginRight: 2.2 * PdfPageFormat.cm,
        marginTop: 2.0 * PdfPageFormat.cm,
        marginBottom: 2.0 * PdfPageFormat.cm,
      ),
      footer: (context) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 12),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Made with MyReciBook',
                style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
            pw.Text('${context.pageNumber} / ${context.pagesCount}',
                style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
          ],
        ),
      ),
      build: (context) => [
        pw.Text(r.title,
            style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
        if (meta.isNotEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 4),
            child: pw.Text(meta,
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          ),
        if (r.cover != null)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 14),
            child: pw.ClipRRect(
              horizontalRadius: 6,
              verticalRadius: 6,
              child: pw.Image(pw.MemoryImage(r.cover!),
                  height: 190, fit: pw.BoxFit.cover),
            ),
          ),
        pw.SizedBox(height: 20),
        if (r.ingredients.isNotEmpty) ...[
          _sectionLabel('Ingredients'),
          pw.SizedBox(height: 6),
          ..._ingredientBlock(r),
          pw.SizedBox(height: 18),
        ],
        if (r.steps.isNotEmpty) ...[
          _sectionLabel('Method'),
          pw.SizedBox(height: 6),
          for (var i = 0; i < r.steps.length; i++)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 9),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.SizedBox(
                    width: 22,
                    child: pw.Text('${i + 1}.',
                        style: pw.TextStyle(
                            fontSize: 11, fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Expanded(
                    child: pw.Text(r.steps[i],
                        style: const pw.TextStyle(fontSize: 11, lineSpacing: 2)),
                  ),
                ],
              ),
            ),
        ],
        if (r.notes != null && r.notes!.trim().isNotEmpty) ...[
          pw.SizedBox(height: 12),
          _sectionLabel('Notes'),
          pw.SizedBox(height: 6),
          pw.Text(r.notes!.trim(),
              style: const pw.TextStyle(fontSize: 11, lineSpacing: 2)),
        ],
        if (r.nutrition != null) ...[
          pw.SizedBox(height: 18),
          _nutritionBox(r.nutrition!),
        ],
        if (r.sourceLine != null && r.sourceLine!.isNotEmpty) ...[
          pw.SizedBox(height: 18),
          pw.Text(r.sourceLine!,
              style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
        ],
      ],
    ),
  );

  return doc.save();
}

pw.Widget _nutritionBox(NutritionBlock n) => pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400, width: 0.8),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(n.headline,
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
          if (n.macros.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 3),
              child: pw.Text(n.macros, style: const pw.TextStyle(fontSize: 10)),
            ),
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 5),
            child: pw.Text(n.note,
                style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
          ),
        ],
      ),
    );

pw.Widget _sectionLabel(String text) => pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(text.toUpperCase(),
            style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 1.1,
                color: PdfColors.grey800)),
        pw.SizedBox(height: 3),
        pw.Container(height: 0.8, color: PdfColors.grey400),
      ],
    );

List<pw.Widget> _ingredientBlock(RecipePdfData r) {
  final out = <pw.Widget>[];
  for (var i = 0; i < r.ingredients.length; i++) {
    final group = r.groupBefore[i];
    if (group != null) {
      out.add(pw.Padding(
        padding: pw.EdgeInsets.only(top: out.isEmpty ? 0 : 8, bottom: 3),
        child: pw.Text(group,
            style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey800)),
      ));
    }
    out.add(pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 3,
            height: 3,
            margin: const pw.EdgeInsets.only(top: 4.5, right: 8),
            decoration: const pw.BoxDecoration(
                color: PdfColors.grey700, shape: pw.BoxShape.circle),
          ),
          pw.Expanded(
            child: pw.Text(r.ingredients[i],
                style: const pw.TextStyle(fontSize: 11, lineSpacing: 1.5)),
          ),
        ],
      ),
    ));
  }
  return out;
}
