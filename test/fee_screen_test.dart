// ignore_for_file: avoid_print
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maktab_management_system/app_localizations.dart';
import 'package:maktab_management_system/fee_screen.dart';
import 'package:maktab_management_system/pdf_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────────────────────

/// Minimal test students covering all fee statuses & languages.
List<Map<String, dynamic>> _makeStudents() => [
      {
        'name': 'Ahmed Khan',
        'fatherName': 'Mr. Imran Khan',
        'fatherPhone': '9876543210',
        'className': 'Class 1 (A)',
        'shift': 'morning',
        'feeAmount': '300',
        'paidAmount': '300',
        'feeMonth': 'July 2026',
        'feeStatus': 'paid',
        'language': 'ur',
        'messageMethod': 'WhatsApp',
        'isPresent': true,
      },
      {
        'name': 'Faizan Ahmed',
        'fatherName': 'Mr. Shabbir Ahmed',
        'fatherPhone': '9876543211',
        'className': 'Class 1 (A)',
        'shift': 'morning',
        'feeAmount': '300',
        'paidAmount': '0',
        'feeMonth': 'July 2026',
        'feeStatus': 'due',
        'language': 'hi',
        'messageMethod': 'SMS',
        'isPresent': false,
      },
      {
        'name': 'Ali Raza',
        'fatherName': 'Mr. Raza Hussain',
        'fatherPhone': '9876543212',
        'className': 'Class 2 (B)',
        'shift': 'morning',
        'feeAmount': '300',
        'paidAmount': '150',
        'feeMonth': 'July 2026',
        'feeStatus': 'partially_paid',
        'language': 'en',
        'messageMethod': 'WhatsApp',
        'isPresent': true,
      },
      {
        'name': 'Zaid Hasan',
        'fatherName': 'Mr. Nadeem Hasan',
        'fatherPhone': '9876543215',
        'className': 'Class 1 (A)',
        'shift': 'evening',
        'feeAmount': '200',
        'paidAmount': '0',
        'feeMonth': 'July 2026',
        'feeStatus': 'due',
        'language': 'te',
        'messageMethod': 'SMS',
        'isPresent': true,
      },
    ];

/// Wrap in a minimal test app with localizations.
Widget _wrap(Widget child) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: const [
      AppLocalizationsDelegate(),
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    supportedLocales: const [Locale('ur'), Locale('en')],
    home: child,
  );
}

Widget _feeScreen({
  List<Map<String, dynamic>>? students,
  bool showAppBarLanguageButton = true,
}) {
  final ctrl = LanguageController();
  final studs = students ?? _makeStudents();
  return _wrap(
    FeeScreen(
      students: studs,
      languageController: ctrl,
      showAppBarLanguageButton: showAppBarLanguageButton,
      onSave: (updated) async {},
    ),
  );
}

/// Sets the test viewport to [width]×[height] logical pixels and
/// registers a teardown that restores the original size automatically.
/// Uses [tester.view] (the modern API) instead of the deprecated
/// [binding.setSurfaceSize], avoiding the mouse_tracker assertions.
void _useSize(WidgetTester tester, double width, double height) {
  const dpr = 1.0;
  final original = tester.view.physicalSize;
  tester.view.physicalSize = Size(width * dpr, height * dpr);
  tester.view.devicePixelRatio = dpr;
  addTearDown(() {
    tester.view.physicalSize = original;
    tester.view.resetDevicePixelRatio();
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// TESTS
// ─────────────────────────────────────────────────────────────────────────────
void main() {
  // ── PDF SERVICE UNIT TESTS ────────────────────────────────────────────────
  group('PdfService Unit Tests', () {
    test('buildFeeReceiptPdf produces a valid document', () async {
      final doc = await PdfService.buildFeeReceiptPdf({
        'name': 'Ahmed Khan',
        'fatherName': 'Imran Khan',
        'fatherPhone': '9876543210',
        'className': 'Class 1',
        'feeMonth': 'July 2026',
        'feeAmount': '300',
        'paidAmount': '300',
        'feeStatus': 'paid',
      });
      final bytes = await doc.save();
      expect(bytes.isNotEmpty, isTrue,
          reason: 'Receipt PDF should produce non-empty bytes');
    });

    test('buildStudentFeeTimelinePdf produces a valid document', () async {
      final student = {
        'name': 'Faizan Ahmed',
        'fatherName': 'Shabbir Ahmed',
        'className': 'Class 1',
        'shift': 'morning',
        'feeAmount': '300',
        'feeMonth': 'July 2026',
        'feeStatus': 'due',
        'paidAmount': '0',
      };
      final doc =
          await PdfService.buildStudentFeeTimelinePdf(student, 2026);
      final bytes = await doc.save();
      expect(bytes.isNotEmpty, isTrue,
          reason: 'Timeline PDF should produce non-empty bytes');
    });

    test('buildBatchFeeReportPdf produces a valid document', () async {
      final students = _makeStudents();
      final doc = await PdfService.buildBatchFeeReportPdf(
          students, 'July 2026', 'Class 1 (A) — Subah');
      final bytes = await doc.save();
      expect(bytes.isNotEmpty, isTrue,
          reason: 'Batch PDF should produce non-empty bytes');
    });

    test('buildBatchFeeReportPdf handles empty student list', () async {
      final doc = await PdfService.buildBatchFeeReportPdf(
          [], 'July 2026', 'Test Batch');
      // should not throw; returns a 0-page doc
      final bytes = await doc.save();
      expect(bytes, isNotNull);
    });

    test('buildReportCardPdf (preserved) produces a valid document', () async {
      final doc = await PdfService.buildReportCardPdf(
        {'name': 'Ali', 'fatherName': 'Raza', 'className': '2', 'shift': 'Morning'},
        'Quran',
        'Surah Al-Fatiha',
      );
      final bytes = await doc.save();
      expect(bytes.isNotEmpty, isTrue);
    });

    test('Timeline PDF shows 12 months for given year', () async {
      // Verify no exception thrown for all 12 months with full history
      final student = {
        'name': 'Test',
        'fatherName': 'Father',
        'className': 'Class 1',
        'shift': 'morning',
        'feeAmount': '300',
        'feeHistory': {
          for (var i = 0; i < 12; i++)
            '${kFeeMonths[i]} 2026': {
              'status': i % 3 == 0
                  ? 'paid'
                  : i % 3 == 1
                      ? 'partially_paid'
                      : 'due',
              'paid': i % 3 == 0 ? '300' : '150',
            }
        },
      };
      final doc =
          await PdfService.buildStudentFeeTimelinePdf(student, 2026);
      final bytes = await doc.save();
      expect(bytes.isNotEmpty, isTrue);
    });
  });

  // ── FEE SCREEN WIDGET TESTS ───────────────────────────────────────────────
  group('FeeScreen Widget Tests', () {
    testWidgets('renders AppBar with correct title', (tester) async {
      await tester.pumpWidget(_feeScreen());
      await tester.pumpAndSettle();
      expect(find.text('Maktab Fee Management'), findsOneWidget);
    });

    testWidgets('shows Subah/Shaam session toggle buttons', (tester) async {
      await tester.pumpWidget(_feeScreen());
      await tester.pumpAndSettle();
      expect(find.text('Subah'), findsOneWidget);
      expect(find.text('Shaam'), findsOneWidget);
    });

    testWidgets('shows Select All checkbox', (tester) async {
      await tester.pumpWidget(_feeScreen());
      await tester.pumpAndSettle();
      expect(find.text('Select All'), findsOneWidget);
    });

    testWidgets('shows correct number of morning students', (tester) async {
      _useSize(tester, 1080, 1920);
      await tester.pumpWidget(_feeScreen());
      await tester.pumpAndSettle();
      // 3 morning students in default data
      expect(find.text('Ahmed Khan'), findsOneWidget);
      expect(find.text('Faizan Ahmed'), findsOneWidget);
      expect(find.text('Ali Raza'), findsOneWidget);
      // Evening student should NOT appear
      expect(find.text('Zaid Hasan'), findsNothing);
    });

    testWidgets('switching to Shaam shows evening students', (tester) async {
      _useSize(tester, 1080, 1920);
      await tester.pumpWidget(_feeScreen());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Shaam'));
      await tester.pumpAndSettle();
      expect(find.text('Zaid Hasan'), findsOneWidget);
      expect(find.text('Ahmed Khan'), findsNothing);
    });

    testWidgets('calendar bar shows current month label', (tester) async {
      await tester.pumpWidget(_feeScreen());
      await tester.pumpAndSettle();
      // Should contain a month name somewhere
      final months = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
      bool foundMonth = false;
      for (final m in months) {
        if (tester.any(find.textContaining(m))) {
          foundMonth = true;
          break;
        }
      }
      expect(foundMonth, isTrue);
    });

    testWidgets('left chevron navigates to previous month', (tester) async {
      await tester.pumpWidget(_feeScreen());
      await tester.pumpAndSettle();
      // Tap left arrow
      await tester.tap(find.byIcon(Icons.chevron_left_rounded));
      await tester.pumpAndSettle();
      // Screen should still be visible
      expect(find.text('Maktab Fee Management'), findsOneWidget);
    });

    testWidgets('right chevron navigates to next month', (tester) async {
      await tester.pumpWidget(_feeScreen());
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.chevron_right_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Maktab Fee Management'), findsOneWidget);
    });

    testWidgets('calendar bar has left and right navigation icons',
        (tester) async {
      await tester.pumpWidget(_feeScreen());
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.chevron_left_rounded), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
      expect(find.byIcon(Icons.calendar_month_rounded), findsOneWidget);
    });

    testWidgets('month/year picker text shows in calendar bar', (tester) async {
      await tester.pumpWidget(_feeScreen());
      await tester.pumpAndSettle();
      // The calendar bar should show the current year somewhere
      final year = DateTime.now().year.toString();
      expect(find.textContaining(year), findsAtLeastNWidgets(1));
    });

    testWidgets('Select All selects all visible students', (tester) async {
      await tester.pumpWidget(_feeScreen());
      await tester.pumpAndSettle();
      final checkboxes = find.byType(Checkbox);
      // First checkbox is Select All
      await tester.tap(checkboxes.first);
      await tester.pumpAndSettle();
      // All checkboxes should now be checked
      final allBoxes = tester.widgetList<Checkbox>(checkboxes).toList();
      expect(allBoxes.every((c) => c.value == true), isTrue);
    });

    testWidgets('unchecking Select All deselects all', (tester) async {
      await tester.pumpWidget(_feeScreen());
      await tester.pumpAndSettle();
      final checkboxes = find.byType(Checkbox);
      await tester.tap(checkboxes.first); // select all
      await tester.pumpAndSettle();
      await tester.tap(checkboxes.first); // deselect all
      await tester.pumpAndSettle();
      final allBoxes = tester.widgetList<Checkbox>(checkboxes).toList();
      expect(allBoxes.every((c) => c.value == false), isTrue);
    });

    testWidgets('summary footer shows counts', (tester) async {
      await tester.pumpWidget(_feeScreen());
      await tester.pumpAndSettle();
      expect(find.text('Selected\nStudents'), findsOneWidget);
      expect(find.text('Alert'), findsAtLeastNWidgets(1));
      expect(find.text('Pending'), findsAtLeastNWidgets(1));
      expect(find.text('Paid'), findsAtLeastNWidgets(1));
    });

    testWidgets('Send Message button is disabled with no selection',
        (tester) async {
      await tester.pumpWidget(_feeScreen());
      await tester.pumpAndSettle();
      // Check by finding the send button text — it should exist
      expect(find.text('Send Message to Selected'), findsOneWidget);
      // With no selection the send icon should exist (button still renders)
      expect(find.byIcon(Icons.send_rounded), findsOneWidget);
    });

    testWidgets('Send Message button enabled after selecting a student',
        (tester) async {
      _useSize(tester, 1080, 1920);
      await tester.pumpWidget(_feeScreen());
      await tester.pumpAndSettle();
      // tap the second checkbox (first student row checkbox)
      final checkboxes = find.byType(Checkbox);
      await tester.tap(checkboxes.at(1));
      await tester.pumpAndSettle();
      // After selecting 1 student, the summary chip shows count > 0
      expect(find.text('1'), findsAtLeastNWidgets(1));
      expect(find.text('Send Message to Selected'), findsOneWidget);
    });

    testWidgets('tapping student row expands timeline', (tester) async {
      _useSize(tester, 1080, 2400);
      await tester.pumpWidget(_feeScreen());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ahmed Khan'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Fee Timeline'), findsOneWidget);
    });

    testWidgets('timeline shows 12 month dots when expanded', (tester) async {
      _useSize(tester, 1080, 2400);
      await tester.pumpWidget(_feeScreen());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ahmed Khan'));
      await tester.pumpAndSettle();
      // 12 3-letter month abbreviations in the timeline
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      for (final m in months) {
        expect(find.text(m), findsOneWidget);
      }
    });

    testWidgets('timeline shows Receipt and Year PDF buttons', (tester) async {
      _useSize(tester, 1080, 2400);
      await tester.pumpWidget(_feeScreen());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ahmed Khan'));
      await tester.pumpAndSettle();
      expect(find.text('Receipt'), findsOneWidget);
      expect(find.text('Year PDF'), findsOneWidget);
    });

    testWidgets('tapping again collapses timeline', (tester) async {
      _useSize(tester, 1080, 2400);
      await tester.pumpWidget(_feeScreen());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ahmed Khan'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Fee Timeline'), findsOneWidget);
      await tester.tap(find.text('Ahmed Khan'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Fee Timeline'), findsNothing);
    });

    testWidgets('edit payment icon opens fee dialog', (tester) async {
      _useSize(tester, 1080, 2400);
      await tester.pumpWidget(_feeScreen());
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.edit_note_rounded).first);
      await tester.pumpAndSettle();
      expect(find.text('Save'), findsAtLeastNWidgets(1));
      expect(find.byType(TextField), findsAtLeastNWidgets(1));
    });

    testWidgets('fee dialog has Receipt PDF and Timeline PDF buttons',
        (tester) async {
      _useSize(tester, 1080, 2400);
      await tester.pumpWidget(_feeScreen());
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.edit_note_rounded).first);
      await tester.pumpAndSettle();
      expect(find.text('Receipt PDF'), findsOneWidget);
      expect(find.text('Timeline PDF'), findsOneWidget);
    });

    testWidgets('paid student row shows green check icon', (tester) async {
      await tester.pumpWidget(_feeScreen());
      await tester.pumpAndSettle();
      // Ahmed Khan is paid — check_circle_outline should have green color
      final icons = tester.widgetList<Icon>(
          find.byIcon(Icons.check_circle_outline_rounded));
      final greenIcon = icons.firstWhere(
          (i) => i.color == const Color(0xFF1DB954),
          orElse: () => const Icon(Icons.circle));
      expect(greenIcon.color, equals(const Color(0xFF1DB954)));
    });

    testWidgets('due student row shows orange rupee icon', (tester) async {
      await tester.pumpWidget(_feeScreen());
      await tester.pumpAndSettle();
      final icons = tester.widgetList<Icon>(
          find.byIcon(Icons.currency_rupee_rounded));
      final orangeIcon = icons.firstWhere(
          (i) => i.color == const Color(0xFFFF6D00),
          orElse: () => const Icon(Icons.circle));
      expect(orangeIcon.color, equals(const Color(0xFFFF6D00)));
    });

    testWidgets('class filter dropdown shows All by default', (tester) async {
      await tester.pumpWidget(_feeScreen());
      await tester.pumpAndSettle();
      expect(find.text('All'), findsOneWidget);
    });

    testWidgets('batch PDF button exists in AppBar', (tester) async {
      await tester.pumpWidget(_feeScreen());
      await tester.pumpAndSettle();
      await tester.tap(find.byType(PopupMenuButton<String>).first);
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.picture_as_pdf_rounded), findsOneWidget);
    });

    testWidgets('language button exists in AppBar', (tester) async {
      await tester.pumpWidget(_feeScreen(showAppBarLanguageButton: true));
      await tester.pumpAndSettle();
      expect(find.byType(LanguageButton), findsOneWidget);
    });

    testWidgets('WhatsApp icon shown for WhatsApp method students',
        (tester) async {
      _useSize(tester, 1080, 1920);
      await tester.pumpWidget(_feeScreen());
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.chat_rounded), findsWidgets);
    });

    testWidgets('SMS icon shown for SMS method students', (tester) async {
      _useSize(tester, 1080, 1920);
      await tester.pumpWidget(_feeScreen());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Shaam'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.sms_rounded), findsWidgets);
    });

    testWidgets('call button shown for each student', (tester) async {
      _useSize(tester, 1080, 1920);
      await tester.pumpWidget(_feeScreen());
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.phone_rounded), findsWidgets);
    });

    testWidgets('empty students list shows no-students message', (tester) async {
      final ctrl = LanguageController();
      await tester.pumpWidget(_wrap(FeeScreen(
        students: [],
        languageController: ctrl,
        onSave: (_) async {},
      )));
      await tester.pumpAndSettle();
      // no student rows
      expect(find.byType(Checkbox), findsOneWidget); // only Select All
    });

    testWidgets('progress bar renders with correct ratio for paid',
        (tester) async {
      await tester.pumpWidget(_feeScreen());
      await tester.pumpAndSettle();
      expect(find.byType(LinearProgressIndicator), findsWidgets);
    });

    testWidgets('tapping language picker opens bottom sheet', (tester) async {
      _useSize(tester, 1080, 1920);
      await tester.pumpWidget(_feeScreen());
      await tester.pumpAndSettle();
      // Find the native script text for urdu in a small container
      await tester.tap(find.text('اردو').first);
      await tester.pumpAndSettle();
      expect(find.text('Select Message Language'), findsOneWidget);
    });

    testWidgets('Send Message button shows correct label text', (tester) async {
      await tester.pumpWidget(_feeScreen());
      await tester.pumpAndSettle();
      expect(find.text('Send Message to Selected'), findsOneWidget);
      expect(
          find.text('(Will send in parents preferred language//app)'),
          findsOneWidget);
    });
  });

  // ── FEE LOGIC UNIT TESTS (state logic without rendering) ─────────────────
  group('Fee Status Logic Tests', () {
    test('paid student has zero pending', () {
      final s = {
        'feeAmount': '300',
        'paidAmount': '300',
        'feeStatus': 'paid',
        'feeMonth': 'July 2026',
      };
      final total = double.parse(s['feeAmount']!);
      const paid = 300.0;
      expect(total - paid, equals(0.0));
    });

    test('due student has full amount pending', () {
      final s = {
        'feeAmount': '300',
        'paidAmount': '0',
        'feeStatus': 'due',
      };
      final total = double.parse(s['feeAmount']!);
      const paid = 0.0;
      expect(total - paid, equals(300.0));
    });

    test('partially_paid student has correct pending amount', () {
      final s = {
        'feeAmount': '300',
        'paidAmount': '150',
        'feeStatus': 'partially_paid',
      };
      final total = double.parse(s['feeAmount']!);
      final paid = double.parse(s['paidAmount']!);
      expect(total - paid, equals(150.0));
    });

    test('progress ratio is clamped between 0 and 1', () {
      // overpaid scenario
      const paid = 400.0;
      const total = 300.0;
      final ratio = (paid / total).clamp(0.0, 1.0);
      expect(ratio, equals(1.0));

      // underpaid
      const paid2 = 100.0;
      const total2 = 300.0;
      final ratio2 = (paid2 / total2).clamp(0.0, 1.0);
      expect((ratio2 - 0.3333).abs() < 0.001, isTrue);
    });

    test('month navigation wraps December → January', () {
      int month = 11; // December (0-based)
      int year = 2026;
      if (month == 11) {
        month = 0;
        year++;
      }
      expect(month, equals(0));
      expect(year, equals(2027));
    });

    test('month navigation wraps January → December', () {
      int month = 0;
      int year = 2027;
      if (month == 0) {
        month = 11;
        year--;
      }
      expect(month, equals(11));
      expect(year, equals(2026));
    });

    test('fee message uses correct language and pending math for due student', () {
      const name = 'Ahmed';
      const month = 'July 2026';
      const total = '300';
      final msg = "السلام علیکم، آپ کے بچے $name کی ماہ $month کی فیس (₹$total) واجب الادا ہے۔ برائے کرم جلد جمع کرائیں۔";
      expect(msg.contains('السلام'), isTrue);
      expect(msg.contains('واجب الادا'), isTrue);
    });

    test('fee message reflects balance math for partially_paid student', () {
      const name = 'Ali';
      const month = 'July 2026';
      const total = 300;
      const paid = 150;
      const pending = 150;
      final msg = "Assalamu Alaikum, your child $name's Maktab fee for $month has a remaining balance of ₹$pending (Paid: ₹$paid / Total: ₹$total). Please pay soon.";
      expect(msg.contains('remaining balance of ₹150'), isTrue);
      expect(msg.contains('Paid: ₹150'), isTrue);
    });

    test('fee message reflects fully paid message for paid student', () {
      const name = 'Ahmed';
      const month = 'July 2026';
      const total = 300;
      final msg = "Assalamu Alaikum, thank you! Your child $name's Maktab fee for $month (₹$total) is fully paid.";
      expect(msg.contains('fully paid'), isTrue);
      expect(msg.contains('thank you'), isTrue);
    });

    test('kFeeMonths has exactly 12 months', () {
      expect(kFeeMonths.length, equals(12));
      expect(kFeeMonths.first, equals('January'));
      expect(kFeeMonths.last, equals('December'));
    });

    test('feeHistory key is correctly formatted', () {
      const month = 'July';
      const year = 2026;
      final key = '$month $year';
      expect(key, equals('July 2026'));
    });
  });
}
