
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Months list used across the app for fee history timelines.
const List<String> kFeeMonths = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

class PdfService {
  // ─────────────────────────────────────────────────────────────────────────
  // 1. INDIVIDUAL FEE RECEIPT  (existing, preserved)
  // ─────────────────────────────────────────────────────────────────────────
  static Future<pw.Document> buildFeeReceiptPdf(
      Map<String, dynamic> student) async {
    final pdf = pw.Document();

    final studentName = student['name']?.toString() ?? 'N/A';
    final fatherName = student['fatherName']?.toString() ?? 'N/A';
    final fatherPhone = student['fatherPhone']?.toString() ?? 'N/A';
    final className = student['className']?.toString() ?? 'N/A';
    final feeMonth = student['feeMonth']?.toString() ?? 'N/A';
    final feeAmount = student['feeAmount']?.toString() ?? '0';
    final feeStatus = student['feeStatus']?.toString() ?? 'Due';
    final paidAmount = student['paidAmount']?.toString() ?? '0';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(32),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.green700, width: 2),
              borderRadius: pw.BorderRadius.circular(12),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text(
                    'MAKTAB MANAGEMENT SYSTEM',
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green800,
                    ),
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Center(
                  child: pw.Text(
                    'FEE PAYMENT RECEIPT',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey700,
                    ),
                  ),
                ),
                pw.Divider(thickness: 1, color: PdfColors.grey400),
                pw.SizedBox(height: 12),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                        'Receipt No: #${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}'),
                    pw.Text(
                        'Date: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}'),
                  ],
                ),
                pw.SizedBox(height: 20),
                _buildPdfRow('Student Name:', studentName),
                pw.SizedBox(height: 8),
                _buildPdfRow("Father's Name:", fatherName),
                pw.SizedBox(height: 8),
                _buildPdfRow('Phone Number:', fatherPhone),
                pw.SizedBox(height: 8),
                _buildPdfRow('Class / Grade:', className),
                pw.SizedBox(height: 8),
                _buildPdfRow('Fee Month:', feeMonth),
                pw.SizedBox(height: 8),
                _buildPdfRow('Total Amount:', 'Rs. $feeAmount'),
                pw.SizedBox(height: 8),
                _buildPdfRow('Paid Amount:', 'Rs. $paidAmount'),
                pw.SizedBox(height: 8),
                _buildPdfRow('Payment Mode:', student['paymentMode']?.toString() ?? 'Cash'),
                pw.SizedBox(height: 8),
                _buildPdfRow('Status:', feeStatus.toUpperCase()),
                pw.SizedBox(height: 32),
                pw.Divider(thickness: 1, color: PdfColors.grey300),
                pw.SizedBox(height: 24),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Parent Signature: ____________'),
                    pw.Text('Authorized Signature: ____________'),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 2. STUDENT FEE TIMELINE PDF  (12-month history for one student)
  // ─────────────────────────────────────────────────────────────────────────
  static Future<pw.Document> buildStudentFeeTimelinePdf(
    Map<String, dynamic> student,
    int year,
  ) async {
    final pdf = pw.Document();

    final studentName = student['name']?.toString() ?? 'N/A';
    final fatherName = student['fatherName']?.toString() ?? 'N/A';
    final className = student['className']?.toString() ?? 'N/A';
    final shift = student['shift']?.toString() ?? 'Morning';
    final feeAmount =
        double.tryParse(student['feeAmount']?.toString() ?? '0') ?? 0;

    // feeHistory: Map<"January 2026", {'status': 'paid'|'due'|'partially_paid', 'paid': '200'}>
    final history = _getFeeHistory(student, year);

    double totalPaid = 0;
    double totalPending = 0;
    for (final m in kFeeMonths) {
      final rec = history[m];
      final status = rec?['status'] ?? 'due';
      final paid = double.tryParse(rec?['paid']?.toString() ?? '0') ?? 0;
      if (status == 'paid') {
        totalPaid += feeAmount;
      } else if (status == 'partially_paid') {
        totalPaid += paid;
        totalPending += (feeAmount - paid);
      } else {
        totalPending += feeAmount;
      }
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Center(
                child: pw.Text(
                  'MAKTAB MANAGEMENT SYSTEM',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.indigo900,
                  ),
                ),
              ),
              pw.Center(
                child: pw.Text(
                  'Student Fee Timeline — $year',
                  style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
                ),
              ),
              pw.Divider(color: PdfColors.grey400),
              pw.SizedBox(height: 10),
              // Student info
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.indigo50,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildPdfRow('Student:', studentName),
                    pw.SizedBox(height: 4),
                    _buildPdfRow("Father:", fatherName),
                    pw.SizedBox(height: 4),
                    _buildPdfRow('Class:', className),
                    pw.SizedBox(height: 4),
                    _buildPdfRow('Shift:', shift),
                    pw.SizedBox(height: 4),
                    _buildPdfRow('Monthly Fee:', 'Rs. ${feeAmount.toInt()}'),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),
              // Timeline table header
              pw.Text('Fee Payment Timeline',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 14)),
              pw.SizedBox(height: 8),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                columnWidths: {
                  0: const pw.FixedColumnWidth(120),
                  1: const pw.FixedColumnWidth(80),
                  2: const pw.FixedColumnWidth(80),
                  3: const pw.FixedColumnWidth(80),
                  4: const pw.FlexColumnWidth(),
                },
                children: [
                  // Header row
                  pw.TableRow(
                    decoration:
                        const pw.BoxDecoration(color: PdfColors.indigo900),
                    children: [
                      _tableCell('Month', isHeader: true),
                      _tableCell('Total (Rs)', isHeader: true),
                      _tableCell('Paid (Rs)', isHeader: true),
                      _tableCell('Pending (Rs)', isHeader: true),
                      _tableCell('Status', isHeader: true),
                    ],
                  ),
                  // Month rows
                  ...kFeeMonths.map((month) {
                    final rec = history[month];
                    final status = rec?['status'] ?? 'due';
                    final paid = status == 'paid'
                        ? feeAmount
                        : double.tryParse(
                                rec?['paid']?.toString() ?? '0') ??
                            0;
                    final pending = feeAmount - paid;
                    final color = status == 'paid'
                        ? PdfColors.green50
                        : status == 'partially_paid'
                            ? PdfColors.orange50
                            : PdfColors.red50;
                    final statusLabel = status == 'paid'
                        ? 'PAID'
                        : status == 'partially_paid'
                            ? 'PARTIAL'
                            : 'DUE';
                    return pw.TableRow(
                      decoration: pw.BoxDecoration(color: color),
                      children: [
                        _tableCell('$month $year'),
                        _tableCell(feeAmount.toInt().toString()),
                        _tableCell(paid.toInt().toString()),
                        _tableCell(pending.toInt().toString()),
                        _tableCell(statusLabel,
                            bold: true,
                            textColor: status == 'paid'
                                ? PdfColors.green800
                                : status == 'partially_paid'
                                    ? PdfColors.orange800
                                    : PdfColors.red800),
                      ],
                    );
                  }),
                ],
              ),
              pw.SizedBox(height: 16),
              // Summary
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                children: [
                  _summaryBox(
                      'Total Paid', 'Rs. ${totalPaid.toInt()}', PdfColors.green800),
                  _summaryBox(
                      'Total Pending', 'Rs. ${totalPending.toInt()}', PdfColors.red800),
                ],
              ),
              pw.Spacer(),
              pw.Divider(),
              pw.Text(
                  'Generated: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                  style: const pw.TextStyle(fontSize: 10)),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 3. BATCH FEE REPORT PDF  (all students for a given month)
  // ─────────────────────────────────────────────────────────────────────────
  static Future<pw.Document> buildBatchFeeReportPdf(
    List<Map<String, dynamic>> students,
    String monthLabel, // e.g. "July 2026"
    String batchTitle, // e.g. "Class 1(A) – Subah"
  ) async {
    final pdf = pw.Document();

    double grandTotalFee = 0;
    double grandPaid = 0;
    double grandPending = 0;

    for (final s in students) {
      final total = double.tryParse(s['feeAmount']?.toString() ?? '0') ?? 0;
      final status = s['feeStatus'] ?? 'due';
      final paid = status == 'paid'
          ? total
          : double.tryParse(s['paidAmount']?.toString() ?? '0') ?? 0;
      grandTotalFee += total;
      grandPaid += paid;
      grandPending += (total - paid);
    }

    // Split into pages of 20 students
    const pageSize = 20;
    final pages = (students.length / pageSize).ceil();

    for (int p = 0; p < pages; p++) {
      final chunk = students.skip(p * pageSize).take(pageSize).toList();
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          build: (ctx) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Center(
                  child: pw.Text(
                    'MAKTAB MANAGEMENT SYSTEM',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.indigo900,
                    ),
                  ),
                ),
                pw.Center(
                  child: pw.Text(
                    'Batch Fee Report — $monthLabel',
                    style: pw.TextStyle(
                        fontSize: 13, color: PdfColors.grey700),
                  ),
                ),
                pw.Center(
                  child: pw.Text(
                    batchTitle,
                    style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.indigo800),
                  ),
                ),
                pw.Divider(color: PdfColors.grey400),
                pw.SizedBox(height: 8),
                // Table
                pw.Table(
                  border:
                      pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                  columnWidths: {
                    0: const pw.FixedColumnWidth(22),
                    1: const pw.FlexColumnWidth(2),
                    2: const pw.FlexColumnWidth(2),
                    3: const pw.FixedColumnWidth(55),
                    4: const pw.FixedColumnWidth(55),
                    5: const pw.FixedColumnWidth(55),
                    6: const pw.FixedColumnWidth(60),
                  },
                  children: [
                    pw.TableRow(
                      decoration:
                          const pw.BoxDecoration(color: PdfColors.indigo900),
                      children: [
                        _tableCell('#', isHeader: true),
                        _tableCell('Student', isHeader: true),
                        _tableCell('Father', isHeader: true),
                        _tableCell('Total', isHeader: true),
                        _tableCell('Paid', isHeader: true),
                        _tableCell('Pending', isHeader: true),
                        _tableCell('Status', isHeader: true),
                      ],
                    ),
                    ...chunk.asMap().entries.map((entry) {
                      final i = entry.key + p * pageSize + 1;
                      final s = entry.value;
                      final total =
                          double.tryParse(s['feeAmount']?.toString() ?? '0') ??
                              0;
                      final status = s['feeStatus'] ?? 'due';
                      final paid = status == 'paid'
                          ? total
                          : double.tryParse(
                                  s['paidAmount']?.toString() ?? '0') ??
                              0;
                      final pending = total - paid;
                      final color = status == 'paid'
                          ? PdfColors.green50
                          : status == 'partially_paid'
                              ? PdfColors.orange50
                              : PdfColors.white;
                      return pw.TableRow(
                        decoration: pw.BoxDecoration(color: color),
                        children: [
                          _tableCell('$i'),
                          _tableCell(s['name']?.toString() ?? '-'),
                          _tableCell(s['fatherName']?.toString() ?? '-'),
                          _tableCell(total.toInt().toString()),
                          _tableCell(paid.toInt().toString()),
                          _tableCell(pending.toInt().toString()),
                          _tableCell(
                            status == 'paid'
                                ? 'PAID'
                                : status == 'partially_paid'
                                    ? 'PARTIAL'
                                    : 'DUE',
                            bold: true,
                            textColor: status == 'paid'
                                ? PdfColors.green800
                                : status == 'partially_paid'
                                    ? PdfColors.orange800
                                    : PdfColors.red800,
                          ),
                        ],
                      );
                    }),
                  ],
                ),
                // Grand total on last page
                if (p == pages - 1) ...[
                  pw.SizedBox(height: 12),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                    children: [
                      _summaryBox('Students', '${students.length}',
                          PdfColors.indigo800),
                      _summaryBox('Total Fee',
                          'Rs. ${grandTotalFee.toInt()}', PdfColors.grey800),
                      _summaryBox(
                          'Collected', 'Rs. ${grandPaid.toInt()}', PdfColors.green800),
                      _summaryBox(
                          'Pending', 'Rs. ${grandPending.toInt()}', PdfColors.red800),
                    ],
                  ),
                ],
                pw.Spacer(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                        'Page ${p + 1} of $pages',
                        style: const pw.TextStyle(fontSize: 9)),
                    pw.Text(
                        'Generated: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                        style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
              ],
            );
          },
        ),
      );
    }

    return pdf;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 4. REPORT CARD PDF  (existing, preserved)
  // ─────────────────────────────────────────────────────────────────────────
  static Future<pw.Document> buildReportCardPdf(
    Map<String, dynamic> student,
    String currentSubject,
    String todayTopic,
  ) async {
    final pdf = pw.Document();

    final studentName = student['name']?.toString() ?? 'N/A';
    final fatherName = student['fatherName']?.toString() ?? 'N/A';
    final className = student['className']?.toString() ?? 'N/A';
    final shift = student['shift']?.toString() ?? 'Morning';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(32),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text(
                    'MAKTAB ACADEMIC REPORT CARD',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green900,
                    ),
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Divider(),
                pw.SizedBox(height: 16),
                _buildPdfRow('Student Name:', studentName),
                pw.SizedBox(height: 6),
                _buildPdfRow("Father's Name:", fatherName),
                pw.SizedBox(height: 6),
                _buildPdfRow('Class:', className),
                pw.SizedBox(height: 6),
                _buildPdfRow('Shift:', shift),
                pw.SizedBox(height: 6),
                _buildPdfRow('Subject:', currentSubject),
                pw.SizedBox(height: 16),
                pw.Text(
                  'Lesson Target / Sabaq Details:',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 14),
                ),
                pw.SizedBox(height: 8),
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Text(
                    todayTopic.isNotEmpty
                        ? todayTopic
                        : 'Regular Sabaq evaluation in progress.',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                ),
                pw.Spacer(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                        'Date: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}'),
                    pw.Text('Teacher Signature: ____________'),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 5. DARS & LESSON EVALUATION REPORT PDF
  // ─────────────────────────────────────────────────────────────────────────
  static Future<pw.Document> buildDarsReportPdf({
    required String subject,
    required String dateLabel,
    required String todayLesson,
    required List<Map<String, dynamic>> studentDarsList,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  'MADRASA AIB — DARS & LESSON EVALUATION REPORT',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.green900,
                  ),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Center(
                child: pw.Text(
                  'Subject: $subject | Date: $dateLabel',
                  style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                ),
              ),
              pw.Divider(color: PdfColors.green700, thickness: 1),
              pw.SizedBox(height: 8),
              pw.Text('Today Class Lesson / Target:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(8),
                margin: const pw.EdgeInsets.only(top: 4, bottom: 12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.green50,
                  border: pw.Border.all(color: PdfColors.green300),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Text(
                  todayLesson.isNotEmpty ? todayLesson : 'General Sabaq Evaluation',
                  style: const pw.TextStyle(fontSize: 11),
                ),
              ),
              pw.Text('Student Performance Summary:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
              pw.SizedBox(height: 6),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
                columnWidths: {
                  0: const pw.FixedColumnWidth(25),
                  1: const pw.FlexColumnWidth(2),
                  2: const pw.FlexColumnWidth(3),
                  3: const pw.FixedColumnWidth(80),
                  4: const pw.FlexColumnWidth(2),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.green800),
                    children: [
                      _tableCell('#', isHeader: true),
                      _tableCell('Student', isHeader: true),
                      _tableCell('Assigned Sabaq', isHeader: true),
                      _tableCell('Rating', isHeader: true),
                      _tableCell('Remarks / Quality', isHeader: true),
                    ],
                  ),
                  ...studentDarsList.asMap().entries.map((entry) {
                    final i = entry.key + 1;
                    final s = entry.value;
                    final rating = s['rating']?.toString() ?? 'Yaad Hai';
                    final remarks = s['remarks']?.toString() ?? '-';
                    final studentLesson = s['lesson']?.toString() ?? todayLesson;

                    final color = rating == 'Yaad Hai'
                        ? PdfColors.green50
                        : rating == 'Kam Yaad Hai'
                            ? PdfColors.orange50
                            : rating == 'Yaad Nahi'
                                ? PdfColors.red50
                                : PdfColors.blue50;

                    return pw.TableRow(
                      decoration: pw.BoxDecoration(color: color),
                      children: [
                        _tableCell('$i'),
                        _tableCell(s['name']?.toString() ?? 'Student', bold: true),
                        _tableCell(studentLesson.isNotEmpty ? studentLesson : todayLesson),
                        _tableCell(rating, bold: true),
                        _tableCell(remarks),
                      ],
                    );
                  }),
                ],
              ),
              pw.Spacer(),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Report Generated: ${DateTime.now().toString().split('.')[0]}',
                      style: const pw.TextStyle(fontSize: 9)),
                  pw.Text('Teacher Signature: ____________',
                      style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PRINT / SHARE
  // ─────────────────────────────────────────────────────────────────────────
  static Future<void> printOrSharePdf(pw.Document doc, String title) async {
    final bytes = await doc.save();
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => bytes,
      name: title,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────────────────

  /// Extract per-month fee history from student data.
  /// Looks for student['feeHistory'] as Map of month-key to status-map,
  /// and falls back to the single feeMonth/feeStatus record.
  static Map<String, Map<String, dynamic>> _getFeeHistory(
      Map<String, dynamic> student, int year) {
    final Map<String, Map<String, dynamic>> result = {};
    // stored history (if exists)
    final raw = student['feeHistory'];
    if (raw is Map) {
      for (final month in kFeeMonths) {
        final key = '$month $year';
        final entry = raw[key];
        if (entry is Map) {
          result[month] = Map<String, dynamic>.from(entry);
        }
      }
    }
    // also apply current single record if present
    final singleMonth = student['feeMonth']?.toString() ?? '';
    final singleStatus = student['feeStatus']?.toString() ?? 'due';
    final paidAmt = student['paidAmount']?.toString() ?? '0';
    for (final month in kFeeMonths) {
      if (singleMonth.startsWith(month) && !result.containsKey(month)) {
        result[month] = {'status': singleStatus, 'paid': paidAmt};
      }
    }
    return result;
  }

  static pw.Widget _buildPdfRow(String label, String value) {
    return pw.Row(
      children: [
        pw.SizedBox(
          width: 140,
          child: pw.Text(
            label,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.Expanded(child: pw.Text(value)),
      ],
    );
  }

  static pw.Widget _tableCell(
    String text, {
    bool isHeader = false,
    bool bold = false,
    PdfColor? textColor,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 9 : 8,
          fontWeight:
              (isHeader || bold) ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader ? PdfColors.white : (textColor ?? PdfColors.black),
        ),
        maxLines: 2,
      ),
    );
  }

  static pw.Widget _summaryBox(String label, String value, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: color),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(children: [
        pw.Text(label,
            style: pw.TextStyle(
                fontSize: 9, fontWeight: pw.FontWeight.bold, color: color)),
        pw.Text(value,
            style: pw.TextStyle(
                fontSize: 13, fontWeight: pw.FontWeight.bold, color: color)),
      ]),
    );
  }
}
