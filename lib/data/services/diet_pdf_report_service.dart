import 'dart:io';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/meal_plan_model.dart';
import '../models/patient_model.dart';

class DietPdfReportService {
  Future<File> generate({
    required PatientModel patient,
    required MealPlanModel plan,
  }) async {
    final document = pw.Document(
      title: 'Plano alimentar - ${patient.name}',
      author: 'NutriFlow Pro',
    );

    final generatedAt = DateTime.now();
    final green = PdfColor.fromHex('#2E7D32');
    final lightGreen = PdfColor.fromHex('#E8F5E9');
    final grey = PdfColor.fromHex('#5F6368');
    final fontTheme = _loadFontTheme();

    document.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: const pw.EdgeInsets.all(32),
          theme: fontTheme,
        ),
        header: (context) => _Header(green: green),
        footer: (context) => _Footer(
          pageNumber: context.pageNumber,
          pagesCount: context.pagesCount,
          grey: grey,
        ),
        build: (context) => [
          pw.SizedBox(height: 18),
          _ReportTitle(
            patient: patient,
            generatedAt: generatedAt,
            green: green,
          ),
          pw.SizedBox(height: 16),
          _PatientSummary(patient: patient, green: green, grey: grey),
          pw.SizedBox(height: 16),
          _PlanSummary(
            plan: plan,
            generatedAt: generatedAt,
            green: green,
            lightGreen: lightGreen,
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            'Plano alimentar',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: green,
            ),
          ),
          pw.SizedBox(height: 10),
          ...plan.meals.map((meal) => _MealSection(meal: meal, green: green)),
          pw.SizedBox(height: 16),
          _NotesBox(green: green, lightGreen: lightGreen),
        ],
      ),
    );

    final directory = Directory('nutriflow_exports');
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }

    final fileName =
        'plano_alimentar_${_slug(patient.name)}_${_dateStamp(generatedAt)}.pdf';
    final file = File('${directory.path}${Platform.pathSeparator}$fileName');
    await file.writeAsBytes(await document.save());
    return file;
  }

  pw.ThemeData _loadFontTheme() {
    final baseFont = _loadFont([
      r'C:\Windows\Fonts\arial.ttf',
      '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',
      '/System/Library/Fonts/Supplemental/Arial.ttf',
    ]);
    final boldFont = _loadFont([
      r'C:\Windows\Fonts\arialbd.ttf',
      '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf',
      '/System/Library/Fonts/Supplemental/Arial Bold.ttf',
    ]);

    return pw.ThemeData.withFont(
      base: baseFont ?? pw.Font.helvetica(),
      bold: boldFont ?? pw.Font.helveticaBold(),
    );
  }

  pw.Font? _loadFont(List<String> paths) {
    for (final path in paths) {
      final file = File(path);
      if (file.existsSync()) {
        final bytes = file.readAsBytesSync();
        return pw.Font.ttf(_asByteData(bytes));
      }
    }

    return null;
  }

  ByteData _asByteData(Uint8List bytes) {
    return bytes.buffer.asByteData(bytes.offsetInBytes, bytes.lengthInBytes);
  }

  String _slug(String value) {
    final normalized = value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');

    return normalized.isEmpty ? 'paciente' : normalized;
  }

  String _dateStamp(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$year$month${day}_$hour$minute';
  }
}

class _Header extends pw.StatelessWidget {
  final PdfColor green;

  _Header({required this.green});

  @override
  pw.Widget build(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 12),
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: green, width: 1.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'NutriFlow Pro',
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                  color: green,
                ),
              ),
              pw.Text('Plano alimentar personalizado'),
            ],
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: pw.BoxDecoration(
              color: green,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(
              'PDF',
              style: pw.TextStyle(
                color: PdfColors.white,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportTitle extends pw.StatelessWidget {
  final PatientModel patient;
  final DateTime generatedAt;
  final PdfColor green;

  _ReportTitle({
    required this.patient,
    required this.generatedAt,
    required this.green,
  });

  @override
  pw.Widget build(pw.Context context) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Dieta pronta para envio',
          style: pw.TextStyle(
            fontSize: 26,
            fontWeight: pw.FontWeight.bold,
            color: green,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Paciente: ${patient.name} | Data: ${_formatDate(generatedAt)}',
          style: const pw.TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}

class _Footer extends pw.StatelessWidget {
  final int pageNumber;
  final int pagesCount;
  final PdfColor grey;

  _Footer({
    required this.pageNumber,
    required this.pagesCount,
    required this.grey,
  });

  @override
  pw.Widget build(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 12),
      child: pw.Text(
        'Pagina $pageNumber de $pagesCount',
        style: pw.TextStyle(fontSize: 9, color: grey),
      ),
    );
  }
}

class _PatientSummary extends pw.StatelessWidget {
  final PatientModel patient;
  final PdfColor green;
  final PdfColor grey;

  _PatientSummary({
    required this.patient,
    required this.green,
    required this.grey,
  });

  @override
  pw.Widget build(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            patient.name,
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: green,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Wrap(
            spacing: 18,
            runSpacing: 8,
            children: [
              _InfoItem(label: 'Objetivo', value: patient.goal, grey: grey),
              _InfoItem(
                label: 'Idade',
                value: '${patient.age} anos',
                grey: grey,
              ),
              _InfoItem(
                label: 'Peso',
                value: '${patient.weight.toStringAsFixed(1)} kg',
                grey: grey,
              ),
              _InfoItem(
                label: 'Altura',
                value: '${patient.height.toStringAsFixed(0)} cm',
                grey: grey,
              ),
              _InfoItem(
                label: 'IMC',
                value: patient.imc.toStringAsFixed(1),
                grey: grey,
              ),
              _InfoItem(
                label: 'Proxima consulta',
                value: patient.nextVisit,
                grey: grey,
              ),
            ],
          ),
          if (patient.observations.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Observacoes',
                    style: pw.TextStyle(
                      fontSize: 9,
                      color: grey,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(patient.observations),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PlanSummary extends pw.StatelessWidget {
  final MealPlanModel plan;
  final DateTime generatedAt;
  final PdfColor green;
  final PdfColor lightGreen;

  _PlanSummary({
    required this.plan,
    required this.generatedAt,
    required this.green,
    required this.lightGreen,
  });

  @override
  pw.Widget build(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: lightGreen,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          _SummaryMetric(
            label: 'Refeicoes',
            value: '${plan.meals.length}',
            green: green,
          ),
          _SummaryMetric(
            label: 'Alimentos',
            value: '${plan.foodsCount}',
            green: green,
          ),
          _SummaryMetric(
            label: 'Data do plano',
            value: _formatDate(generatedAt),
            green: green,
          ),
        ],
      ),
    );
  }
}

class _MealSection extends pw.StatelessWidget {
  final MealModel meal;
  final PdfColor green;

  _MealSection({required this.meal, required this.green});

  @override
  pw.Widget build(pw.Context context) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 14),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: pw.BoxDecoration(
              color: green,
              borderRadius: const pw.BorderRadius.only(
                topLeft: pw.Radius.circular(5),
                topRight: pw.Radius.circular(5),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  meal.name,
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  meal.time,
                  style: const pw.TextStyle(color: PdfColors.white),
                ),
              ],
            ),
          ),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            columnWidths: const {
              0: pw.FlexColumnWidth(3),
              1: pw.FlexColumnWidth(2),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                children: [
                  _tableCell('Alimento', isHeader: true),
                  _tableCell('Quantidade', isHeader: true),
                ],
              ),
              ...meal.foods.map(
                (food) => pw.TableRow(
                  children: [_tableCell(food.name), _tableCell(food.quantity)],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NotesBox extends pw.StatelessWidget {
  final PdfColor green;
  final PdfColor lightGreen;

  _NotesBox({required this.green, required this.lightGreen});

  @override
  pw.Widget build(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: lightGreen,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Text(
        'Orientacoes: siga os horarios combinados, mantenha boa hidratacao e leve duvidas para a proxima consulta.',
        style: pw.TextStyle(color: green, fontSize: 11),
      ),
    );
  }
}

class _InfoItem extends pw.StatelessWidget {
  final String label;
  final String value;
  final PdfColor grey;

  _InfoItem({required this.label, required this.value, required this.grey});

  @override
  pw.Widget build(pw.Context context) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 9, color: grey)),
        pw.Text(value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
      ],
    );
  }
}

class _SummaryMetric extends pw.StatelessWidget {
  final String label;
  final String value;
  final PdfColor green;

  _SummaryMetric({
    required this.label,
    required this.value,
    required this.green,
  });

  @override
  pw.Widget build(pw.Context context) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 9)),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: green,
          ),
        ),
      ],
    );
  }
}

pw.Widget _tableCell(String text, {bool isHeader = false}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
    child: pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: 10,
        fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
      ),
    ),
  );
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final year = date.year.toString().padLeft(4, '0');

  return '$day/$month/$year';
}
