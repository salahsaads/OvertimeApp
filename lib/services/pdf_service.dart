// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/overtime_entry.dart';

class PdfService {
  static Future<String> generatePdf(List<OvertimeEntry> entries) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('yyyy/MM/dd');
    final nowFormat = DateFormat('yyyy-MM-dd HH:mm');

    final totalHours = entries.fold(0.0, (sum, e) => sum + e.hours);
    final totalPay = entries.fold(0.0, (sum, e) => sum + e.totalPay);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Overtime Hours Report',
                    style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                pw.Text('Generated: ${nowFormat.format(DateTime.now())}',
                    style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
              ],
            ),
            pw.Divider(color: PdfColors.blue800, thickness: 2),
            pw.SizedBox(height: 8),
          ],
        ),
        footer: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Overtime Calculator', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey500)),
            pw.Text('Page \${context.pageNumber} of \${context.pagesCount}',
                style: pw.TextStyle(fontSize: 9, color: PdfColors.grey500)),
          ],
        ),
        build: (context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
            children: [
              _summaryCard('Total Records', '\${entries.length}', PdfColors.blue50, PdfColors.blue800),
              _summaryCard('Total Hours', '\${totalHours.toStringAsFixed(1)} hrs', PdfColors.green50, PdfColors.green800),
              if (totalPay > 0)
                _summaryCard('Total Pay', '\$\${totalPay.toStringAsFixed(2)}', PdfColors.orange50, PdfColors.orange800),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Text('Detailed Records',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(1.5),
              1: const pw.FlexColumnWidth(1.5),
              2: const pw.FlexColumnWidth(0.8),
              3: const pw.FlexColumnWidth(2.5),
              4: const pw.FlexColumnWidth(1),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.blue800),
                children: [_tableHeader('Start Date'), _tableHeader('End Date'), _tableHeader('Hours'), _tableHeader('Tasks Completed'), _tableHeader('Pay')],
              ),
              ...entries.asMap().entries.map((entry) {
                final e = entry.value;
                final isEven = entry.key % 2 == 0;
                return pw.TableRow(
                  decoration: pw.BoxDecoration(color: isEven ? PdfColors.white : PdfColors.grey50),
                  children: [
                    _tableCell(dateFormat.format(e.startDate)),
                    _tableCell(dateFormat.format(e.endDate)),
                    _tableCell('\${e.hours.toStringAsFixed(1)}'),
                    _tableCell(e.tasks),
                    _tableCell(e.totalPay > 0 ? '\$\${e.totalPay.toStringAsFixed(2)}' : '-'),
                  ],
                );
              }),
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.blue100),
                children: [
                  _tableCellBold('TOTAL'), _tableCellBold(''),
                  _tableCellBold('\${totalHours.toStringAsFixed(1)}'), _tableCellBold(''),
                  _tableCellBold(totalPay > 0 ? '\$\${totalPay.toStringAsFixed(2)}' : '-'),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    final bytes = await pdf.save();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = 'overtime_report_\$timestamp.pdf';
    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..click();
    html.Url.revokeObjectUrl(url);
    return fileName;
  }

  static pw.Widget _summaryCard(String label, String value, PdfColor bg, PdfColor fg) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: pw.BoxDecoration(color: bg, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)), border: pw.Border.all(color: fg.shade(.3), width: 1)),
      child: pw.Column(children: [
        pw.Text(value, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: fg)),
        pw.SizedBox(height: 4),
        pw.Text(label, style: pw.TextStyle(fontSize: 9, color: fg)),
      ]),
    );
  }

  static pw.Widget _tableHeader(String text) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(text, style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10)));

  static pw.Widget _tableCell(String text) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 9)));

  static pw.Widget _tableCellBold(String text) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(text, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)));
}
