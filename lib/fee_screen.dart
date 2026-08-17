import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'app_localizations.dart';
import 'pdf_service.dart';
import 'role_selection_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// COLORS
// ─────────────────────────────────────────────────────────────────────────────
const Color _kNavy = Color(0xFF0A1F5C);
const Color _kGreen = Color(0xFF1DB954);
const Color _kOrange = Color(0xFFFF6D00);
const Color _kWhatsApp = Color(0xFF25D366);
const Color _kRed = Color(0xFFD32F2F);

// ─────────────────────────────────────────────────────────────────────────────
// ISLAMIC ARCH PAINTER (FEE SCREEN)
// ─────────────────────────────────────────────────────────────────────────────
class _FeeArchPainter extends CustomPainter {
  final bool dark;

  const _FeeArchPainter({required this.dark});

  Path _path(Size size) {
    final double w = size.width;
    final double h = size.height;
    return Path()
      ..moveTo(3, h - 3)
      ..lineTo(3, h * .45)
      ..quadraticBezierTo(3, h * .27, w * .15, h * .27)
      ..quadraticBezierTo(w * .20, h * .11, w * .36, h * .11)
      ..quadraticBezierTo(w * .44, h * .10, w * .50, 3)
      ..quadraticBezierTo(w * .56, h * .10, w * .64, h * .11)
      ..quadraticBezierTo(w * .80, h * .11, w * .85, h * .27)
      ..quadraticBezierTo(w - 3, h * .27, w - 3, h * .45)
      ..lineTo(w - 3, h - 3)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final Path arch = _path(size);
    canvas.drawShadow(arch, const Color(0x440A1F5C), 6, false);
    canvas.drawPath(
      arch,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? const [Color(0xFF334155), Color(0xFF1E293B)]
              : const [Colors.white, Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      arch,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..color = const Color(0xFF0A1F5C),
    );
  }

  @override
  bool shouldRepaint(covariant _FeeArchPainter oldDelegate) =>
      oldDelegate.dark != dark;
}

// ─────────────────────────────────────────────────────────────────────────────
// CONSTANTS
// ─────────────────────────────────────────────────────────────────────────────
const _kMonths = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

// ─────────────────────────────────────────────────────────────────────────────
// FEE SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class FeeScreen extends StatefulWidget {
  final List<Map<String, dynamic>> students;
  final LanguageController languageController;
  final Future<void> Function(List<Map<String, dynamic>>) onSave;
  final bool showAppBarLanguageButton;
  final AppRole? currentRole;
  final String? maktabId;
  final ValueChanged<String>? onMaktabChanged;

  const FeeScreen({
    super.key,
    required this.students,
    required this.languageController,
    required this.onSave,
    this.showAppBarLanguageButton = false,
    this.currentRole,
    this.maktabId,
    this.onMaktabChanged,
  });

  @override
  State<FeeScreen> createState() => _FeeScreenState();
}

class _FeeScreenState extends State<FeeScreen> {
  late List<Map<String, dynamic>> _students;

  // ── filters ──
  String _selectedSession = 'subah';
  String _selectedClass = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final List<String> _batchesList = ['All', 'Class 7 (A)', 'Class 6 (B)', 'Morning Hifz Batch', 'Nazira Batch A'];
  int _selectedYear = DateTime.now().year;
  int _selectedMonthIndex = DateTime.now().month - 1; // 0-based
  String _selectedStatus = 'ALL';

  void _showAddBatchDialog() {
    final ctrl = TextEditingController();
    final isEn = AppLocalizations.of(context).locale.languageCode == 'en';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        title: Row(
          children: [
            const Icon(Icons.group_add_rounded, color: Colors.blue),
            const SizedBox(width: 8),
            Text(
              isEn ? 'Add New Batch / Class' : 'نیا بیچ یا کلاس شامل کریں',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
            ),
          ],
        ),
        content: TextField(
          controller: ctrl,
          decoration: InputDecoration(
            labelText: isEn ? 'Batch Name (e.g. Hifz Batch A)' : 'بیچ کا نام (مثلاً حفظ بیچ A)',
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isEn ? 'Cancel' : 'منسوخ')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.blue),
            onPressed: () {
              final name = ctrl.text.trim();
              if (name.isNotEmpty) {
                setState(() {
                  if (!_batchesList.contains(name)) {
                    _batchesList.add(name);
                  }
                  _selectedClass = name;
                  _applyFilter();
                });
                Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isEn ? 'New batch "$name" added successfully!' : 'نیا بیچ "$name" کامیابی سے شامل کر دیا گیا!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            child: Text(isEn ? 'Add Batch' : 'بیچ شامل کریں'),
          ),
        ],
      ),
    );
  }

  // ── selection ──
  final Set<int> _selectedIndices = {};
  DateTimeRange? _selectedDateRange;
  bool _selectAll = false;

  // ── expand timeline rows ──
  final Set<int> _expandedRows = {};

  // ── derived ──
  List<MapEntry<int, Map<String, dynamic>>> _filtered = [];

  // ────────────────────────────────── INIT ──
  @override
  void initState() {
    super.initState();
    _students =
        widget.students.map((s) => Map<String, dynamic>.from(s)).toList();
    if (_students.isEmpty) {
      _students = [
        {
          'id': '101',
          'name': 'محمد علی',
          'fatherName': 'عبداللہ',
          'fatherPhone': '9876543210',
          'className': 'کلاس ۱ (ابتدائی)',
          'shift': 'morning',
          'feeAmount': '500',
          'paidAmount': '500',
          'feeStatus': 'paid',
          'preferredApp': 'WhatsApp',
          'preferredLanguage': 'ur',
        },
        {
          'id': '102',
          'name': 'عبدالرحمن',
          'fatherName': 'محمد عثمان',
          'fatherPhone': '9876543211',
          'className': 'کلاس ۱ (ابتدائی)',
          'shift': 'morning',
          'feeAmount': '500',
          'paidAmount': '250',
          'feeStatus': 'partially_paid',
          'preferredApp': 'WhatsApp',
          'preferredLanguage': 'ur',
        },
        {
          'id': '103',
          'name': 'حمزہ خان',
          'fatherName': 'تنویر خان',
          'fatherPhone': '9876543212',
          'className': 'کلاس ۲ (ناظرہ)',
          'shift': 'morning',
          'feeAmount': '500',
          'paidAmount': '0',
          'feeStatus': 'due',
          'preferredApp': 'SMS',
          'preferredLanguage': 'ur',
        },
        {
          'id': '104',
          'name': 'عمر فاروق',
          'fatherName': 'خالد محمود',
          'fatherPhone': '9876543213',
          'className': 'کلاس ۳ (حفظ)',
          'shift': 'evening',
          'feeAmount': '600',
          'paidAmount': '600',
          'feeStatus': 'paid',
          'preferredApp': 'WhatsApp',
          'preferredLanguage': 'en',
        },
      ];
    }
    _loadSavedBatches();
    _applyFilter();
  }

  Future<void> _loadSavedBatches() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('maktab_group_names') ?? [];
    for (final b in saved) {
      if (!_batchesList.contains(b)) {
        _batchesList.add(b);
      }
    }
    for (final s in _students) {
      final g = s['group'] ?? s['className'];
      if (g != null && g.toString().isNotEmpty && !_batchesList.contains(g.toString())) {
        _batchesList.add(g.toString());
      }
    }
    if (mounted) setState(() {});
  }

  // ── calendar label ──
  String get _selectedMonthLabel =>
      '${_kMonths[_selectedMonthIndex]} $_selectedYear';

  // ── filter ──
  Future<void> _selectPeriod() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
      initialDateRange: _selectedDateRange ?? DateTimeRange(
        start: DateTime(_selectedYear, _selectedMonthIndex + 1, 1),
        end: DateTime(_selectedYear, _selectedMonthIndex + 1, 30),
      ),
    );
    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
        _selectedMonthIndex = picked.start.month - 1;
        _selectedYear = picked.start.year;
      });
      _applyFilter();
    }
  }

  void _applyFilter() {
    final currentMaktab = widget.maktabId ?? '';
    final query = _searchQuery.trim().toLowerCase();

    setState(() {
      var matches = _students.asMap().entries.where((e) {
        final s = e.value;
        if (currentMaktab.isNotEmpty) {
          final ownerId = s['maktabId']?.toString();
          if (ownerId != null && ownerId.isNotEmpty && ownerId != 'maktab_default' && ownerId != currentMaktab) {
            return false;
          }
        }
        final shiftVal = (s['shift'] ?? s['timing'] ?? s['shift_timing'] ?? '').toString().toLowerCase();
        final isEvening = shiftVal.contains('even') || shiftVal.contains('shaam') || shiftVal.contains('شام');
        final isMorning = !isEvening;
        final shiftOk = _selectedSession == 'subah' ? isMorning : isEvening;
        final classOk = _selectedClass == 'All' ||
            (s['className']?.toString() ?? s['grade'] ?? '') == _selectedClass;

        final name = (s['name'] ?? '').toString().toLowerCase();
        final fatherName = (s['fatherName'] ?? s['parentName'] ?? '').toString().toLowerCase();
        final rollNo = (s['rollNo'] ?? s['id'] ?? '').toString().toLowerCase();
        final searchOk = query.isEmpty || name.contains(query) || fatherName.contains(query) || rollNo.contains(query);
        final statusOk = _selectedStatus == 'ALL' ||
            (_selectedStatus == 'PAID' && _feeStatus(s) == 'paid') ||
            (_selectedStatus == 'DUE' && _feeStatus(s) != 'paid');

        return shiftOk && classOk && searchOk && statusOk;
      }).toList();

      if (matches.isEmpty && _students.isNotEmpty && query.isEmpty) {
        matches = _students.asMap().entries.where((e) {
          final s = e.value;
          final classOk = _selectedClass == 'All' ||
              (s['className']?.toString() ?? s['grade'] ?? '') == _selectedClass;
          return classOk;
        }).toList();
      }

      _filtered = matches
        ..sort((a, b) {
          final statusA = _feeStatus(a.value);
          final statusB = _feeStatus(b.value);
          int rank(String s) => s == 'due' ? 0 : s == 'partially_paid' ? 1 : 2;
          return rank(statusA).compareTo(rank(statusB));
        });
    });
  }

  List<String> get _classOptions {
    final classes = _students
        .map((s) => s['className']?.toString() ?? '')
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return ['All', ...classes];
  }

  // ── fee helpers (month-aware) ──
  Map<String, dynamic>? _monthRecord(Map<String, dynamic> s) {
    final hist = s['feeHistory'];
    if (hist is Map) {
      final key = _selectedMonthLabel;
      final rec = hist[key];
      if (rec is Map) return Map<String, dynamic>.from(rec);
    }
    // fallback: use the root-level fields if they match the selected month
    final m = s['feeMonth']?.toString() ?? '';
    if (m.startsWith(_kMonths[_selectedMonthIndex])) {
      return {
        'status': s['feeStatus'] ?? 'due',
        'paid': s['paidAmount']?.toString() ?? '0',
        'total': s['feeAmount']?.toString() ?? '0',
        'paymentMode': s['paymentMode'] ?? 'Cash',
      };
    }
    return null;
  }

  // ignore: unused_element
  String _paymentMode(Map<String, dynamic> s) =>
      _monthRecord(s)?['paymentMode']?.toString() ??
      s['paymentMode']?.toString() ??
      'Cash';

  double _total(Map<String, dynamic> s) =>
      double.tryParse(s['feeAmount']?.toString() ?? '0') ?? 0;

  double _paid(Map<String, dynamic> s) {
    final rec = _monthRecord(s);
    final status = rec?['status'] ?? 'due';
    final total = _total(s);
    if (status == 'paid') return total;
    if (status == 'partially_paid') {
      return double.tryParse(rec?['paid']?.toString() ?? '0') ?? 0;
    }
    return 0;
  }

  double _pending(Map<String, dynamic> s) => _total(s) - _paid(s);

  String _formatCurrency(num amount) {
    return amount.toInt().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
  }

  String _feeStatus(Map<String, dynamic> s) =>
      _monthRecord(s)?['status']?.toString() ?? 'due';

  // ── month-timeline helpers ──
  String _monthStatusForIndex(Map<String, dynamic> s, int mIdx) {
    final hist = s['feeHistory'];
    if (hist is Map) {
      final key = '${_kMonths[mIdx]} $_selectedYear';
      final rec = hist[key];
      if (rec is Map) return rec['status']?.toString() ?? 'due';
    }
    final m = s['feeMonth']?.toString() ?? '';
    if (m.startsWith(_kMonths[mIdx])) return s['feeStatus'] ?? 'due';
    return 'none';
  }

  // ── selection ──
  void _toggleSelectAll(bool? v) {
    setState(() {
      _selectAll = v ?? false;
      if (_selectAll) {
        _selectedIndices.addAll(_filtered.map((e) => e.key));
      } else {
        _selectedIndices.clear();
      }
    });
  }

  void _toggleStudent(int globalIdx, bool? v) {
    setState(() {
      if (v == true) {
        _selectedIndices.add(globalIdx);
      } else {
        _selectedIndices.remove(globalIdx);
      }
      _selectAll = _selectedIndices.length == _filtered.length;
    });
  }

  // ── bulk fee status ──
  void _markAllFeeStatus(String status) {
    final monthKey = _selectedMonthLabel;
    setState(() {
      for (final entry in _filtered) {
        final s = _students[entry.key];
        final total = _total(s);
        s['feeHistory'] ??= <String, dynamic>{};
        (s['feeHistory'] as Map<String, dynamic>)[monthKey] = {
          'status': status,
          'paid': status == 'paid' ? total.toString() : '0',
          'total': total.toString(),
          'paymentMode': s['paymentMode'] ?? 'Cash',
        };
        s['feeStatus'] = status;
        s['feeMonth'] = monthKey;
        if (status == 'paid') {
          s['paidAmount'] = total.toString();
        } else {
          s['paidAmount'] = '0';
        }
      }
    });
    widget.onSave(_students);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(status == 'paid'
            ? '✓ تمام طلبہ کی فیس ادا شدہ (All Marked Paid) — $monthKey'
            : '✗ تمام طلبہ کی فیس واجب الادا (All Marked Due) — $monthKey'),
        backgroundColor: status == 'paid' ? Colors.green : Colors.red,
      ),
    );
  }

  // ── comms ──
  Future<void> _openWhatsApp(String phone, String msg) async {
    final clean = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    await launchUrl(
        Uri.parse('https://wa.me/$clean?text=${Uri.encodeComponent(msg)}'),
        mode: LaunchMode.externalApplication);
  }

  Future<void> _openSms(String phone, String msg) async {
    await launchUrl(
        Uri(scheme: 'sms', path: phone, queryParameters: {'body': msg}),
        mode: LaunchMode.externalApplication);
  }

  Future<void> _openCall(String phone) async {
    await launchUrl(Uri(scheme: 'tel', path: phone),
        mode: LaunchMode.externalApplication);
  }

  String _feeMessage(Map<String, dynamic> s) {
    final name = s['name']?.toString() ?? 'Student';
    final month = _selectedMonthLabel;
    final total = _total(s).toInt();
    final paid = _paid(s).toInt();
    final pending = _pending(s).toInt();
    final status = _feeStatus(s);
    final lang = (s['preferredLanguage'] ?? s['language'] ?? 'ur').toString();

    if (status == 'paid' || pending <= 0) {
      switch (lang) {
        case 'en':
          return "Assalamu Alaikum, thank you! Your child $name's Maktab fee for $month (₹$total) is fully paid.";
        case 'ar':
          return "السلام عليكم، شكراً لكم! تم سداد رسوم المكتب لـ$name لشهر $month (₹$total) بالكامل.";
        case 'hi':
          return "अस्सलामु अलैकुम, धन्यवाद! $name की $month की फीस (₹$total) पूरी जमा हो चुकी है।";
        case 'te':
          return "అస్సలాము అలైకుం, ధన్యవాదాలు! $name యొక్క $month ఫీజు (₹$total) పూర్తిగా చెల్లించబడింది.";
        case 'kn':
          return "ಅಸ್ಸಲಾಮು ಅಲೈಕುಮ್, ಧನ್ಯವಾದಗಳು! $name ಅವರ $month ಶುಲ್ಕ (₹$total) ಸಂಪೂರ್ಣವಾಗಿ ಪಾವತಿಸಲಾಗಿದೆ.";
        case 'ta':
          return "அஸ்ஸலாமு அலைக்கும், நன்றி! $name இன் $month கட்டணம் (₹$total) முழுமையாக செலுத்தப்பட்டது.";
        case 'ml':
          return "അസ്സലാമു അലൈക്കും, നന്ദി! $name യുടെ $month ഫീസ് (₹$total) പൂർണ്ണമായി അടച്ചു.";
        default:
          return "السلام علیکم، شکریہ! آپ کے بچے $name کی ماہ $month کی مکتب فیس (₹$total) مکمل ادا ہو چکی ہے۔";
      }
    } else if (status == 'partially_paid') {
      switch (lang) {
        case 'en':
          return "Assalamu Alaikum, your child $name's Maktab fee for $month has a remaining balance of ₹$pending (Paid: ₹$paid / Total: ₹$total). Please pay soon.";
        case 'ar':
          return "السلام عليكم، المبلغ المتبقي لرسوم $name لشهر $month هو ₹$pending (المدفوع: ₹$paid / الإجمالي: ₹$total). نرجو السداد.";
        case 'hi':
          return "अस्सलामु अलैकुम, $name की $month की बाकी फीस ₹$pending है (जमा: ₹$paid / कुल: ₹$total)। कृपया बाकी फीस जल्द जमा करें।";
        case 'te':
          return "అస్సలాము అలైకుం, $name యొక్క $month మిగిలిన బాకీ ఫీజు ₹$pending (చెల్లించినది: ₹$paid / మొత్తం: ₹$total).";
        case 'kn':
          return "ಅಸ್ಸಲಾಮು ಅಲೈಕುಮ್, $name ಅವರ $month ಬಾಕಿ ಶುಲ್ಕ ₹$pending (ಪಾವತಿಸಿದ್ದು: ₹$paid / ಒಟ್ಟು: ₹$total).";
        case 'ta':
          return "அஸ்ஸலாமு அலைக்கும், $name இன் $month மீதமுள்ள கட்டணம் ₹$pending (செலுத்தியது: ₹$paid / மொத்தம்: ₹$total).";
        case 'ml':
          return "അസ്സലാമു അലൈക്കും, $name യുടെ $month ബാക്കി ഫീസ് ₹$pending ആണ് (നൽകിയത്: ₹$paid / ആകെ: ₹$total).";
        default:
          return "السلام علیکم، آپ کے بچے $name کی ماہ $month کی بقایا فیس ₹$pending ہے (ادا شدہ: ₹$paid / کل: ₹$total)۔ برائے کرم بقایا فیس جلد جمع کرائیں۔";
      }
    } else {
      // Due (Nothing paid)
      switch (lang) {
        case 'en':
          return "Assalamu Alaikum, your child $name's Maktab fee for $month (₹$total) is pending. Please pay soon.";
        case 'ar':
          return "السلام عليكم، رسوم المكتب لـ$name لشهر $month (₹$total) مستحقة. نرجو السداد.";
        case 'hi':
          return "अस्सलामु अलैकुम, $name की $month की फीस (₹$total) बाकी है। कृपया जल्द जमा करें।";
        case 'te':
          return "అస్సలాము అలైకుం, $name యొక్క $month ఫీజు (₹$total) బాకీ ఉంది.";
        case 'kn':
          return "ಅಸ್ಸಲಾಮು ಅಲೈಕುಮ್, $name ಅವರ $month ಶುಲ್ಕ (₹$total) ಬಾಕಿ ಇದೆ.";
        case 'ta':
          return "அஸ்ஸலாமு அலைக்கும், $name இன் $month கட்டணம் (₹$total) நிலுவையில் உள்ளது.";
        case 'ml':
          return "അസ്സലാമു അലൈക്കും, $name യുടെ $month ഫീസ് (₹$total) കുടിശ്ശിക.";
        default:
          return "السلام علیکم، آپ کے بچے $name کی ماہ $month کی فیس (₹$total) واجب الادا ہے۔ برائے کرم جلد جمع کرائیں۔";
      }
    }
  }

  Future<void> _sendToSelected() async {
    final selected = _filtered
        .where((e) => _selectedIndices.contains(e.key))
        .map((e) => e.value)
        .toList();
    for (final s in selected) {
      final msg = _feeMessage(s);
      final phone = s['fatherPhone']?.toString() ?? '';
      if ((s['messageMethod'] ?? 'SMS') == 'WhatsApp') {
        await _openWhatsApp(phone, msg);
      } else {
        await _openSms(phone, msg);
      }
    }
  }

  Future<void> _saveChanges() async {
    for (int i = 0; i < _students.length; i++) {
      if (i < widget.students.length) {
        widget.students[i].addAll(_students[i]);
      }
    }
    await widget.onSave(widget.students);
  }

  Future<void> _deleteStudent(int globalIdx) async {
    final isEn = AppLocalizations.of(context).locale.languageCode == 'en';
    final s = _students[globalIdx];
    final name = s['name']?.toString() ?? (isEn ? 'Student' : 'طالب علم');
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEn ? 'Delete Student' : 'طالب علم کو حذف کریں'),
        content: Text(isEn
            ? 'Are you sure you want to delete "$name"? This will remove the student from the fee ledger. This action cannot be undone.'
            : 'کیا آپ واقعی "$name" کو حذف کرنا چاہتے ہیں؟ یہ طالب علم فیس لیجر سے ہٹ جائے گا۔ یہ عمل واپس نہیں ہوسکتا۔'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(isEn ? 'Cancel' : 'منسوخ'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isEn ? 'Delete' : 'حذف کریں'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() {
      _students.removeAt(globalIdx);
      _selectedIndices.remove(globalIdx);
      _expandedRows.remove(globalIdx);
      _applyFilter();
    });
    await _saveChanges();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEn ? '"$name" has been deleted.' : '"$name" حذف ہوگیا۔'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  // ── update month record ──
  void _updateMonthRecord(
    int globalIdx,
    String status,
    String paid, {
    String paymentMode = 'Cash',
    double? addedAmount,
  }) {
    setState(() {
      final s = _students[globalIdx];
      final hist = (s['feeHistory'] is Map)
          ? Map<String, dynamic>.from(s['feeHistory'] as Map)
          : <String, dynamic>{};
      final existingRec = (hist[_selectedMonthLabel] is Map)
          ? Map<String, dynamic>.from(hist[_selectedMonthLabel] as Map)
          : <String, dynamic>{};

      List<Map<String, dynamic>> logs = [];
      if (existingRec['logs'] is List) {
        logs = (existingRec['logs'] as List)
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
      }

      if (addedAmount != null && addedAmount > 0) {
        final now = DateTime.now();
        final timeStr =
            '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
        logs.add({
          'amount': addedAmount.toInt().toString(),
          'mode': paymentMode,
          'date': timeStr,
          'accumulated': paid,
        });
      }

      existingRec['status'] = status;
      existingRec['paid'] = paid;
      existingRec['paymentMode'] = paymentMode;
      existingRec['logs'] = logs;

      hist[_selectedMonthLabel] = existingRec;
      _students[globalIdx]['feeHistory'] = hist;

      // also update root fields for current month
      _students[globalIdx]['feeMonth'] = _selectedMonthLabel;
      _students[globalIdx]['feeStatus'] = status;
      _students[globalIdx]['paidAmount'] = paid;
      _students[globalIdx]['paymentMode'] = paymentMode;
      _students[globalIdx]['paymentLogs'] = logs;
    });
    _saveChanges();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PDF ACTIONS
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _printStudentTimeline(int globalIdx) async {
    final s = _students[globalIdx];
    final doc =
        await PdfService.buildStudentFeeTimelinePdf(s, _selectedYear);
    await PdfService.printOrSharePdf(
        doc, 'Fee_Timeline_${s['name']}_$_selectedYear');
  }

  Future<void> _printStudentReceipt(int globalIdx) async {
    final s = _students[globalIdx];
    final doc = await PdfService.buildFeeReceiptPdf(s);
    await PdfService.printOrSharePdf(
        doc, 'Fee_Receipt_${s['name']}_$_selectedMonthLabel');
  }

  Future<void> _printBatchReport() async {
    final batchStudents =
        _filtered.map((e) => _students[e.key]).toList();
    final batchTitle =
        '${_selectedClass == 'All' ? 'All Classes' : _selectedClass} — ${_selectedSession == 'subah' ? 'Subah (Morning)' : 'Shaam (Evening)'}';
    final doc = await PdfService.buildBatchFeeReportPdf(
        batchStudents, _selectedMonthLabel, batchTitle);
    await PdfService.printOrSharePdf(
        doc, 'Batch_Fee_${_selectedMonthLabel.replaceAll(' ', '_')}');
  }

  Future<void> _showPaymentHistoryDialog() async {
    final prefs = await SharedPreferences.getInstance();
    final String rawLogs = prefs.getString('fee_payment_history_logs_v1') ?? '';
    List<Map<String, dynamic>> history = [];
    if (rawLogs.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawLogs) as List<dynamic>;
        history = decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      } catch (_) {}
    }

    if (history.isEmpty) {
      history = [
        {
          'id': '1',
          'studentName': 'محمد سفیان',
          'amount': 500.0,
          'date': '2026-08-10 09:30 AM',
          'mode': 'Cash (نقد)',
          'collectedBy': 'حافظ احمد حسن',
          'month': 'August 2026',
        },
        {
          'id': '2',
          'studentName': 'عبداللہ خان',
          'amount': 700.0,
          'date': '2026-08-09 04:15 PM',
          'mode': 'Online / UPI (آن لائن)',
          'collectedBy': 'استاد محمد عمران',
          'month': 'August 2026',
        },
        {
          'id': '3',
          'studentName': 'محمد علی',
          'amount': 600.0,
          'date': '2026-08-08 11:20 AM',
          'mode': 'Bank Transfer (بینک)',
          'collectedBy': 'حافظ احمد حسن',
          'month': 'August 2026',
        },
      ];
    }

    if (!mounted) return;
    final isEn = AppLocalizations.of(context).locale.languageCode == 'en';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            title: Row(
              children: [
                const Icon(Icons.history_rounded, color: Colors.amber),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isEn ? 'Payment History & Time Log' : 'فیس کی تاریخی تفصیل (History & Time Log)',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 500,
              height: 400,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Entries: ${history.length}',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black87),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        ),
                        icon: const Icon(Icons.add_task, size: 14),
                        label: Text(isEn ? 'Add Record' : 'نئی فیس درج کریں', style: const TextStyle(fontSize: 11)),
                        onPressed: () {
                          _showAddPaymentRecordModal(context, (newRec) {
                            setDialogState(() {
                              history.insert(0, newRec);
                            });
                            prefs.setString('fee_payment_history_logs_v1', jsonEncode(history));
                          });
                        },
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: history.isEmpty
                        ? Center(child: Text(isEn ? 'No payment history found.' : 'کوئی ہسٹری موجود نہیں ہے'))
                        : ListView.separated(
                            itemCount: history.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, idx) {
                              final item = history[idx];
                              final String mode = item['mode'] ?? 'Cash';
                              Color modeColor = Colors.green;
                              if (mode.contains('Online') || mode.contains('UPI')) modeColor = Colors.blue;
                              if (mode.contains('Bank')) modeColor = Colors.purple;
                              if (mode.contains('Cheque')) modeColor = Colors.amber.shade900;

                              return ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(
                                  radius: 16,
                                  backgroundColor: modeColor.withValues(alpha: 0.2),
                                  child: Icon(
                                    mode.contains('Online') ? Icons.qr_code : (mode.contains('Bank') ? Icons.account_balance : Icons.payments_rounded),
                                    size: 16,
                                    color: modeColor,
                                  ),
                                ),
                                title: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      item['studentName'] ?? 'Student',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : Colors.black87),
                                    ),
                                    Text(
                                      '₹${item['amount']}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green),
                                    ),
                                  ],
                                ),
                                subtitle: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${item['date']} (${item['mode']})',
                                      style: TextStyle(fontSize: 10.5, color: isDark ? Colors.white60 : Colors.grey.shade700),
                                    ),
                                    Text(
                                      'By: ${item['collectedBy']}',
                                      style: const TextStyle(fontSize: 10, color: Colors.indigo),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(isEn ? 'Close' : 'بند کریں'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddPaymentRecordModal(BuildContext context, Function(Map<String, dynamic>) onAdded) {
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    String selectedMode = 'Cash (نقد)';
    final now = DateTime.now();
    final formattedTime = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    final isEn = AppLocalizations.of(context).locale.languageCode == 'en';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        title: Text(isEn ? 'Record Fee Payment' : 'فیس کی وصولی درج کریں', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: isEn ? 'Student Name' : 'طالب علم کا نام',
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: isEn ? 'Amount (₹)' : 'رقم (روپے)',
                prefixText: '₹ ',
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: selectedMode,
              decoration: InputDecoration(
                labelText: isEn ? 'Payment Mode' : 'طریقہ کار (Payment Mode)',
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: const OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'Cash (نقد)', child: Text('Cash / نقد')),
                DropdownMenuItem(value: 'Online / UPI (آن لائن)', child: Text('Online / UPI / آن لائن')),
                DropdownMenuItem(value: 'Bank Transfer (بینک)', child: Text('Bank Transfer / بینک')),
                DropdownMenuItem(value: 'Cheque (چیک)', child: Text('Cheque / چیک')),
              ],
              onChanged: (val) {
                if (val != null) selectedMode = val;
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isEn ? 'Cancel' : 'منسوخ')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () {
              final amt = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
              if (amt <= 0 || nameCtrl.text.trim().isEmpty) return;

              onAdded({
                'id': DateTime.now().millisecondsSinceEpoch.toString(),
                'studentName': nameCtrl.text.trim(),
                'amount': amt,
                'date': formattedTime,
                'mode': selectedMode,
                'collectedBy': 'استاد / قاری',
                'month': 'August 2026',
              });
              Navigator.pop(ctx);
            },
            child: Text(isEn ? 'Save Payment' : 'محفوظ کریں'),
          ),
        ],
      ),
    );
  }

  bool _isFeeCollectorRoleEnabled = true;

  void _showCollectionAnalyticsDialog() {
    final double totalCollected = _students.fold(0, (sum, s) => sum + _paid(s));
    final double totalPending = _students.fold(0, (sum, s) => sum + _pending(s));
    final double grandTotal = totalCollected + totalPending;
    final int ratio = grandTotal == 0 ? 0 : ((totalCollected / grandTotal) * 100).toInt();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.bar_chart_rounded, color: _kNavy),
            SizedBox(width: 8),
            Text('ماہانہ فیس وصولی بمقابلہ واجب الادا', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('مہینہ: $_selectedMonthLabel', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statBox('وصول شدہ', '₹${totalCollected.toInt()}', Colors.green),
                _statBox('واجب الادا', '₹${totalPending.toInt()}', Colors.orange),
                _statBox('تناسب', '$ratio%', Colors.indigo),
              ],
            ),
            const SizedBox(height: 14),
            LinearProgressIndicator(
              value: grandTotal == 0 ? 0 : (totalCollected / grandTotal).clamp(0.0, 1.0),
              color: Colors.green,
              backgroundColor: Colors.orange.shade100,
              minHeight: 10,
            ),
          ],
        ),
        actions: [
          ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('ٹھیک ہے')),
        ],
      ),
    );
  }

  void _showTeacherLedgerDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : _kNavy;
    final subColor = isDark ? Colors.white70 : Colors.grey.shade700;

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: dialogBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.receipt_long_rounded, color: Colors.green, size: 24),
            const SizedBox(width: 8),
            Text(
              widget.languageController.locale.languageCode == 'en'
                  ? 'Fee Ledger Roster'
                  : 'فیس وصولی کھاتہ رجسٹر',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Teacher & Class Info Header Card (Same details as Attendance)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF0F4FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFD0E1FD)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.mosque_rounded, size: 16, color: _kNavy),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            widget.languageController.locale.languageCode == 'en'
                                ? 'Maktab: Maktab Al-Farooq (ID: MKT-001)'
                                : 'مکتب: مکتب الفاروق (آئی ڈی: MKT-001)',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.person_rounded, size: 16, color: Colors.green),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            widget.languageController.locale.languageCode == 'en'
                                ? 'Teacher: Qari Mohammad Tariq ✓'
                                : 'استاد: قاری محمد طارق (استاد) ✓',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: textColor),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.class_rounded, size: 16, color: Colors.indigo),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            widget.languageController.locale.languageCode == 'en'
                                ? 'Class: $_selectedClass | Batch: ${_selectedSession == 'subah' ? 'Morning Batch' : 'Evening Batch'}'
                                : 'کلاس: $_selectedClass | بیـچ: ${_selectedSession == 'subah' ? 'صبح کا بیچ' : 'شام کا بیچ'}',
                            style: TextStyle(fontSize: 12, color: subColor),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Student Ledger Roster
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _students.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, idx) {
                    final s = _students[idx];
                    final paid = _paid(s);
                    final pending = _pending(s);
                    final total = _total(s);
                    final status = _feeStatus(s);
                    final isPaid = status == 'paid';
                    final isPresent = s['isPresent'] != false && s['attendanceStatus'] != 'absent';

                    return ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: isPaid
                            ? Colors.green.shade100
                            : (pending > 0 ? Colors.orange.shade100 : Colors.blue.shade100),
                        child: Icon(
                          isPaid
                              ? Icons.check_circle_rounded
                              : (paid > 0 ? Icons.account_balance_wallet_rounded : Icons.error_outline_rounded),
                          size: 18,
                          color: isPaid ? Colors.green.shade800 : (paid > 0 ? Colors.orange.shade800 : Colors.red.shade800),
                        ),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              s['name']?.toString() ?? 'طالب علم',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isPresent ? Colors.green.shade50 : Colors.red.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isPresent
                                  ? (widget.languageController.locale.languageCode == 'en' ? 'Present' : 'حاضر')
                                  : (widget.languageController.locale.languageCode == 'en' ? 'Absent' : 'غیر حاضر'),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isPresent ? Colors.green.shade800 : Colors.red.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Text(
                        () {
                          final admNo = (s['admissionNo'] ?? s['rollNo'] ?? s['id'] ?? '').toString().trim();
                          final fatherName = (s['fatherName'] ?? s['parentName'] ?? '').toString().trim();
                          final maktabName = (s['maktabName'] ?? s['maktab_name'] ?? '').toString().trim();
                          final isAdminOrManager = widget.currentRole == AppRole.admin || widget.currentRole == AppRole.manager;
                          final parts = <String>[];
                          if (admNo.isNotEmpty) parts.add('داخلہ نمبر: $admNo');
                          if (fatherName.isNotEmpty) parts.add('والد: $fatherName');
                          if (isAdminOrManager && maktabName.isNotEmpty) parts.add('مکتب: $maktabName');
                          return parts.isNotEmpty ? parts.join('  •  ') : 'تفصیلات دستیاب نہیں';
                        }(),
                        style: TextStyle(fontSize: 11, color: subColor),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'ادائیگی: ₹${_formatCurrency(paid)} / ₹${_formatCurrency(total)}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _kGreen),
                          ),
                          Text(
                            pending > 0 ? 'باقی: ₹${_formatCurrency(pending)}' : 'مکمل ادا',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: pending > 0 ? _kOrange : _kGreen,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(widget.languageController.locale.languageCode == 'en' ? 'Close' : 'بند کریں'),
          ),
        ],
      ),
    );
  }

  void _showAnnualAuditDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.verified_user_rounded, color: Colors.indigo),
            SizedBox(width: 8),
            Text('سالانہ مالیاتی اڈٹ رپورٹ (Annual Audit)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('سال 2026ء کی مالیاتی اڈٹ سمری تیار کر لی گئی ہے۔', style: TextStyle(fontSize: 13)),
          ],
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _printBatchReport();
            },
            icon: const Icon(Icons.picture_as_pdf_rounded),
            label: const Text('سالانہ رپورٹ پی ڈی ایف'),
          ),
        ],
      ),
    );
  }

  void _showFeeCollectorRoleDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.admin_panel_settings_rounded, color: _kNavy),
              SizedBox(width: 8),
              Text('اختیاری فیس وصولی کار رول (Fee Collector Permission)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('استاد یا مینیجر کو فیس وصول کرنے اور کاؤنٹر استعمال کرنے کا اختیار دیں:', style: TextStyle(fontSize: 11, color: Colors.grey)),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('استاد/مینیجر فیس وصولی اختیار (Fee Collector Active)'),
                value: _isFeeCollectorRoleEnabled,
                onChanged: (v) {
                  setDlgState(() => _isFeeCollectorRoleEnabled = v);
                  setState(() {});
                },
              ),
            ],
          ),
          actions: [
            ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('محفوظ کریں')),
          ],
        ),
      ),
    );
  }

  Widget _statBox(String title, String val, Color col) {
    return Column(
      children: [
        Text(val, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: col)),
        Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // DIALOGS
  // ─────────────────────────────────────────────────────────────────────────
  void _showEditFeeDialog(int globalIdx) {
    final loc = AppLocalizations.of(context);
    final s = _students[globalIdx];
    final rec = _monthRecord(s);
    final double initialTotal =
        double.tryParse(s['feeAmount']?.toString() ?? '300') ?? 300;
    final double prevPaid = double.tryParse(
            rec?['paid']?.toString() ?? s['paidAmount']?.toString() ?? '0') ??
        0;

    final totalCtrl =
        TextEditingController(text: initialTotal.toInt().toString());
    final addedCtrl = TextEditingController(text: '');
    final setDirectPaidCtrl =
        TextEditingController(text: prevPaid.toInt().toString());

    String feeStatus = rec?['status']?.toString() ?? s['feeStatus'] ?? 'due';
    String paymentMode = rec?['paymentMode']?.toString() ??
        s['paymentMode']?.toString() ??
        'Cash';

    List<Map<String, dynamic>> logs = [];
    if (rec?['logs'] is List) {
      logs = (rec!['logs'] as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    }

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) {
          final double currentTotal =
              double.tryParse(totalCtrl.text.trim()) ?? initialTotal;
          final double newAdd =
              double.tryParse(addedCtrl.text.trim()) ?? 0;
          final double calculatedTotalPaid = prevPaid + newAdd;
          final double remainingBalance =
              (currentTotal - calculatedTotalPaid).clamp(0, currentTotal);

          return AlertDialog(
            title: Text(
              '${loc.translate('fee_record')}: ${s['name']}\n$_selectedMonthLabel',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: _kNavy, fontSize: 14),
            ),
            content: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                // Total Fee
                TextField(
                  controller: totalCtrl,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setSt(() {}),
                  decoration: InputDecoration(
                    labelText: loc.translate('fee_amount'),
                    prefixText: '₹ ',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                // Current paid info banner
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Previously Paid: ₹${prevPaid.toInt()}',
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _kNavy)),
                      Text('Balance: ₹${remainingBalance.toInt()}',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: remainingBalance > 0
                                  ? _kOrange
                                  : _kGreen)),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // Add New Payment Field (+ ₹)
                TextField(
                  controller: addedCtrl,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setSt(() {}),
                  decoration: const InputDecoration(
                    labelText: '+ Add New Payment (₹)',
                    hintText: 'e.g. 20 (will add 120 + 20 = 140)',
                    prefixText: '+ ₹ ',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                // Direct Total Paid Field (for manual overwrite if needed)
                TextField(
                  controller: setDirectPaidCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Or Direct Total Paid (₹)',
                    prefixText: '₹ ',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                // Payment Mode Dropdown
                DropdownButtonFormField<String>(
                  initialValue: paymentMode,
                  decoration: const InputDecoration(
                    labelText: 'Payment Mode',
                    prefixIcon:
                        Icon(Icons.payment_rounded, color: _kNavy, size: 20),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Cash', child: Text('💵 Cash')),
                    DropdownMenuItem(
                        value: 'UPI', child: Text('📱 UPI / GPay / PhonePe')),
                    DropdownMenuItem(
                        value: 'Bank Transfer',
                        child: Text('🏦 Bank Transfer')),
                    DropdownMenuItem(
                        value: 'Cheque', child: Text('📝 Cheque')),
                  ],
                  onChanged: (v) {
                    if (v != null) setSt(() => paymentMode = v);
                  },
                ),
                const SizedBox(height: 10),
                // Fee Status Dropdown
                DropdownButtonFormField<String>(
                  initialValue: feeStatus,
                  decoration: InputDecoration(
                    labelText: loc.translate('fee_status'),
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(
                        value: 'due', child: Text(loc.translate('due'))),
                    DropdownMenuItem(
                        value: 'partially_paid',
                        child: Text(loc.translate('partially_paid'))),
                    DropdownMenuItem(
                        value: 'paid', child: Text(loc.translate('paid'))),
                  ],
                  onChanged: (v) {
                    if (v != null) setSt(() => feeStatus = v);
                  },
                ),
                const SizedBox(height: 12),
                // Payment History Logs List (if any logs exist)
                if (logs.isNotEmpty) ...[
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Payment Logs History:',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _kNavy)),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 100),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF334155) : Colors.grey.shade300),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: logs.length,
                      itemBuilder: (ctx, i) {
                        final log = logs[i];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          child: Row(
                            children: [
                              Text(log['date']?.toString() ?? '',
                                  style: const TextStyle(
                                      fontSize: 11, color: Colors.grey)),
                              const Spacer(),
                              Text(
                                '+₹${log['amount']} (${log['mode']})',
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: _kGreen),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                // PDF Buttons
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await _printStudentReceipt(globalIdx);
                      },
                      icon: const Icon(Icons.receipt_long, size: 16),
                      label: const Text('Receipt PDF',
                          style: TextStyle(fontSize: 11)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await _printStudentTimeline(globalIdx);
                      },
                      icon: const Icon(Icons.timeline, size: 16),
                      label: const Text('Timeline PDF',
                          style: TextStyle(fontSize: 11)),
                    ),
                  ),
                ]),
              ]),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(loc.translate('cancel')),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: _kNavy),
                onPressed: () async {
                  final double totFee =
                      double.tryParse(totalCtrl.text.trim()) ?? initialTotal;
                  final double addVal =
                      double.tryParse(addedCtrl.text.trim()) ?? 0;
                  double finalPaid = prevPaid;

                  if (addVal > 0) {
                    finalPaid = prevPaid + addVal;
                  } else {
                    finalPaid = double.tryParse(
                            setDirectPaidCtrl.text.trim()) ??
                        prevPaid;
                  }

                  // Determine auto status
                  String calculatedStatus = feeStatus;
                  if (finalPaid >= totFee) {
                    calculatedStatus = 'paid';
                  } else if (finalPaid > 0) {
                    calculatedStatus = 'partially_paid';
                  } else {
                    calculatedStatus = 'due';
                  }

                  _students[globalIdx]['feeAmount'] = totFee.toInt().toString();
                  _updateMonthRecord(
                    globalIdx,
                    calculatedStatus,
                    finalPaid.toInt().toString(),
                    paymentMode: paymentMode,
                    addedAmount: addVal > 0 ? addVal : null,
                  );

                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: Text(loc.translate('save')),
              ),
            ],
          );
        },
      ),
    ).whenComplete(() {
      totalCtrl.dispose();
      addedCtrl.dispose();
      setDirectPaidCtrl.dispose();
    });
  }

  void _showLanguagePicker(int globalIdx) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2)),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Text('Select Message Language',
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          ...kAllLanguages.map((lang) {
            final current =
                _students[globalIdx]['language']?.toString() ?? 'ur';
            return ListTile(
              title: Text(lang.nativeScript),
              trailing: current == lang.code
                  ? const Icon(Icons.check_circle, color: _kGreen)
                  : null,
              onTap: () {
                setState(() {
                  _students[globalIdx]['language'] = lang.code;
                });
                _saveChanges();
                Navigator.pop(ctx);
              },
            );
          }),
          const SizedBox(height: 8),
        ]),
        ),
      ),
    );
  }

  Future<void> _sendFeeReportToAdmin() async {
    final loc = AppLocalizations.of(context);
    final paidCount = _filtered.where((e) => _feeStatus(_students[e.key]) == 'paid').length;
    final pendingCount = _filtered.where((e) => _feeStatus(_students[e.key]) == 'due').length;
    final total = _filtered.length;
    final monthStr = _selectedMonthLabel;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('رپورٹ بھیجیں (Send Report)'),
        content: Text('کیا آپ ایڈمن کو اس مہینے کا فیس خلاصہ بھیجنا چاہتے ہیں؟\n\n'
            'مہینہ: $monthStr\n'
            'ادا شدہ: $paidCount\n'
            'واجب الادا: $pendingCount\n'
            'کل طلبہ: $total'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(loc.translate('cancel'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('بھیجیں (Send)')),
        ],
      ),
    );

    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      final reportsStr = prefs.getString('teacher_reports') ?? '[]';
      final List<dynamic> reportsList = jsonDecode(reportsStr);

      reportsList.add({
        'id': 'fee_rep_${DateTime.now().millisecondsSinceEpoch}',
        'type': 'fee',
        'dateTime': DateTime.now().toString(),
        'senderName': 'Ustadh (Teacher)',
        'summary': 'فیس خلاصہ ($monthStr): ادا شدہ $paidCount | واجب الادا $pendingCount',
        'details': {
          'month': monthStr,
          'total': total,
          'paid': paidCount,
          'due': pendingCount,
          'dueStudentsList': _filtered
              .where((e) => _feeStatus(_students[e.key]) == 'due')
              .map((e) => _students[e.key]['name'] ?? 'Student')
              .toList(),
        }
      });

      await prefs.setString('teacher_reports', jsonEncode(reportsList));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ فیس رپورٹ کامیابی کے ساتھ ایڈمن کو بھیج دی گئی (Report Sent)!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isEn = loc.locale.languageCode == 'en';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final alertCount =
        _filtered.where((e) => _pending(_students[e.key]) > 0).length;
    final pendingCount =
        _filtered.where((e) => _feeStatus(_students[e.key]) == 'due').length;
    final paidCount =
        _filtered.where((e) => _feeStatus(_students[e.key]) == 'paid').length;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF0F4FF),
      appBar: AppBar(
        backgroundColor: _kNavy,
        foregroundColor: Colors.white,
        title: widget.currentRole == AppRole.teacher
            ? null
            : Text(
                isEn ? 'Fee Collection Portal' : 'مکتب فیس وصولی پورٹل',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.home_rounded, color: Colors.white),
            tooltip: isEn ? 'Return to Home' : 'ہوم ڈیش بورڈ',
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.popUntil(context, (route) => route.isFirst);
              }
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            tooltip: isEn ? 'Tools' : 'ٹولز',
            onSelected: (value) {
              if (value == 'send_report') {
                _sendFeeReportToAdmin();
              } else if (value == 'mark_all_paid') {
                _markAllFeeStatus('paid');
              } else if (value == 'mark_all_due') {
                _markAllFeeStatus('due');
              } else if (value == 'analytics') {
                _showCollectionAnalyticsDialog();
              } else if (value == 'ledger') {
                _showTeacherLedgerDialog();
              } else if (value == 'audit') {
                _showAnnualAuditDialog();
              } else if (value == 'history') {
                _showPaymentHistoryDialog();
              } else if (value == 'collector_role') {
                _showFeeCollectorRoleDialog();
              } else if (value == 'batch_pdf') {
                _printBatchReport();
              }
            },
            itemBuilder: (context) => [
              if (widget.currentRole == AppRole.teacher)
                PopupMenuItem(
                  value: 'send_report',
                  child: Row(
                    children: [
                      const Icon(Icons.send_rounded, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(child: Text(isEn ? 'Send Report' : 'رپورٹ بھیجیں', overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ),
              PopupMenuItem(
                value: 'mark_all_paid',
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(child: Text(isEn ? 'Mark All Paid' : 'سب ادا شدہ', overflow: TextOverflow.ellipsis)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'mark_all_due',
                child: Row(
                  children: [
                    const Icon(Icons.money_off_rounded, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(child: Text(isEn ? 'Mark All Due' : 'سب واجب الادا', overflow: TextOverflow.ellipsis)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'analytics',
                child: Row(
                  children: [
                    const Icon(Icons.bar_chart_rounded, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(child: Text(isEn ? 'Fee Analytics' : 'فیس گراف', overflow: TextOverflow.ellipsis)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'ledger',
                child: Row(
                  children: [
                    const Icon(Icons.receipt_long_rounded, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(child: Text(isEn ? 'Teacher Ledger' : 'فیس کھاتہ', overflow: TextOverflow.ellipsis)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'audit',
                child: Row(
                  children: [
                    const Icon(Icons.verified_user_rounded, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(child: Text(isEn ? 'Annual Audit' : 'اڈٹ رپورٹ', overflow: TextOverflow.ellipsis)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'history',
                child: Row(
                  children: [
                    const Icon(Icons.history_rounded, color: Colors.amber),
                    const SizedBox(width: 8),
                    Expanded(child: Text(isEn ? 'Payment History' : 'فیس کی تاریخ', overflow: TextOverflow.ellipsis)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'collector_role',
                child: Row(
                  children: [
                    const Icon(Icons.admin_panel_settings_rounded, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(child: Text(isEn ? 'Role Settings' : 'رول اختیارات', overflow: TextOverflow.ellipsis)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'batch_pdf',
                child: Row(
                  children: [
                    const Icon(Icons.picture_as_pdf_rounded, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(child: Text(isEn ? 'Batch PDF' : 'پی ڈی ایف رپورٹ', overflow: TextOverflow.ellipsis)),
                  ],
                ),
              ),
            ],
          ),
          if (widget.showAppBarLanguageButton)
            LanguageButton(controller: widget.languageController),
        ],
      ),
      body: Column(children: [
        _buildIslamicFeeHeader(),
        _buildFilterBar(),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 580,
              child: Column(
                children: [
                  _buildSelectAllRow(loc),
                  _buildTableHeader(loc),
                  Expanded(
                    child: _filtered.isEmpty
                        ? Center(
                            child: Text(loc.translate('no_students_found'),
                                style: const TextStyle(color: Colors.grey)))
                        : ListView.builder(
                            itemCount: _filtered.length,
                            itemBuilder: (ctx, i) {
                              final entry = _filtered[i];
                              return _buildStudentRow(entry, i + 1, loc);
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
        _buildSummaryFooter(
            _selectedIndices.length, alertCount, pendingCount, paidCount),
        _buildSendButton(loc),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ISLAMIC HEADER & FILTER BAR
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildIslamicFeeHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEn = AppLocalizations.of(context).locale.languageCode == 'en';
    return Container(
      margin: const EdgeInsets.fromLTRB(6, 4, 6, 6),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF074E32), width: 2.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F074E32),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Address Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
            alignment: Alignment.center,
            child: Text(
              isEn ? 'Maktab Al-Farooq, Madina Masjid, Khannapet' : 'مکتب قاسم العلوم مدینہ مسجد کدہ پیٹ، ڈون، ندیال، آندھرا پردیش',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF074E32),
              ),
            ),
          ),
          const SizedBox(height: 5),
          // Row 1: Teacher & Department
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final String? val = await showDialog<String>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(isEn ? 'Teacher Name' : 'معلم/معلمہ کا نام'),
                        content: TextField(
                          autofocus: true,
                          decoration: InputDecoration(hintText: isEn ? 'Enter teacher name...' : 'معلم کا نام درج کریں...'),
                          onSubmitted: (v) => Navigator.pop(ctx, v),
                        ),
                      ),
                    );
                    if (val != null && val.trim().isNotEmpty) {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString('fee_teacher_heading', val.trim());
                    }
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    height: 34,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF074E32), width: 1.2),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.fingerprint_rounded, size: 18, color: Color(0xFF074E32)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            isEn ? 'Teacher Name' : 'معلم/معلمہ کا نام',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF074E32)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (ctx) => SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: ['ALL', 'Hifz Group A', 'Nazira Group B', 'Tajweed Group C', 'Primary Group D']
                              .map((c) => ListTile(
                                    title: Text(c),
                                    onTap: () {
                                      setState(() {
                                        _selectedClass = c;
                                        _applyFilter();
                                      });
                                      Navigator.pop(ctx);
                                    },
                                  ))
                              .toList(),
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    height: 34,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF074E32), width: 1.2),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.person_rounded, size: 18, color: Color(0xFF074E32)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '$_selectedClass (${_selectedSession == "subah" ? (isEn ? "Morning" : "صبح") : (isEn ? "Evening" : "شام")})',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF074E32)),
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF074E32)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          // Row 2: Shift Dropdown & Month Picker
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedSession = _selectedSession == "subah" ? "evening" : "subah";
                      _applyFilter();
                    });
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    height: 34,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF074E32), width: 1.2),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.wb_sunny_outlined, size: 18, color: Color(0xFF074E32)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _selectedSession == "subah" ? (isEn ? "Morning" : "صبح") : (isEn ? "Evening" : "شام"),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF074E32)),
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF074E32)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 34,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF074E32), width: 1.2),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            if (_selectedMonthIndex == 0) {
                              _selectedMonthIndex = 11;
                              _selectedYear--;
                            } else {
                              _selectedMonthIndex--;
                            }
                            _applyFilter();
                          });
                        },
                        child: const Icon(Icons.chevron_left_rounded, size: 20, color: Color(0xFF074E32)),
                      ),
                      const Icon(Icons.calendar_month_rounded, size: 16, color: Color(0xFF074E32)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${kFeeMonths[_selectedMonthIndex]} $_selectedYear',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF074E32)),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            if (_selectedMonthIndex == 11) {
                              _selectedMonthIndex = 0;
                              _selectedYear++;
                            } else {
                              _selectedMonthIndex++;
                            }
                            _applyFilter();
                          });
                        },
                        child: const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFF074E32)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          // Row 3: Wide Filter Dropdown
          InkWell(
            onTap: () {
              showModalBottomSheet(
                context: context,
                builder: (ctx) => SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        title: Text(isEn ? 'All Students' : 'کل طلبہ'),
                        onTap: () {
                          setState(() {
                            _selectedStatus = 'ALL';
                            _applyFilter();
                          });
                          Navigator.pop(ctx);
                        },
                      ),
                      ListTile(
                        title: Text(isEn ? 'Paid Students' : 'مکمل ادا شد'),
                        onTap: () {
                          setState(() {
                            _selectedStatus = 'PAID';
                            _applyFilter();
                          });
                          Navigator.pop(ctx);
                        },
                      ),
                      ListTile(
                        title: Text(isEn ? 'Due Fee Defaulters' : 'واجب الادا / بقایاجات'),
                        onTap: () {
                          setState(() {
                            _selectedStatus = 'DUE';
                            _applyFilter();
                          });
                          Navigator.pop(ctx);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF074E32), width: 1.2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      _selectedStatus == 'ALL'
                          ? (isEn ? 'All Students, Paid, Due Fee Record' : 'داخل ، غیر حاضر ، حاضر ، کل طلبا')
                          : (_selectedStatus == 'PAID' ? (isEn ? 'Paid Students' : 'مکمل ادا شد') : (isEn ? 'Due Defaulters' : 'واجب الادا')),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF074E32),
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_drop_down_rounded, color: isDark ? Colors.white70 : const Color(0xFF074E32)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildFilterBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEn = AppLocalizations.of(context).locale.languageCode == 'en';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        children: [
          // Search Field
          TextField(
            controller: _searchController,
            onChanged: (val) {
              _searchQuery = val;
              _applyFilter();
            },
            decoration: InputDecoration(
              hintText: isEn ? 'Search student by name or father name...' : 'طالب علم کا نام، والد کا نام یا رول نمبر تلاش کریں...',
              hintStyle: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey.shade600),
              prefixIcon: const Icon(Icons.search_rounded, size: 20, color: _kNavy),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                          _applyFilter();
                        });
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              filled: true,
              fillColor: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : Colors.grey.shade300),
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Session Switcher & Class Filter Dropdown
          Row(
            children: [
              _SessionToggle(
                value: _selectedSession,
                onChanged: (v) {
                  setState(() {
                    _selectedSession = v;
                    _applyFilter();
                  });
                },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _batchesList.contains(_selectedClass) ? _selectedClass : 'All',
                      icon: const Icon(Icons.arrow_drop_down_rounded, size: 20, color: _kNavy),
                      isExpanded: true,
                      style: TextStyle(fontSize: 11, color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedClass = val;
                            _applyFilter();
                          });
                        }
                      },
                      items: _batchesList.map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis))).toList(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // DASHBOARD SUMMARY
  // ─────────────────────────────────────────────────────────────────────────
  // ignore: unused_element
  Widget _buildDashboardSummary() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEn = widget.languageController.locale.languageCode == 'en';
    final double totalCollected = _filtered.fold(0, (sum, e) => sum + _paid(_students[e.key]));
    final double totalPending = _filtered.fold(0, (sum, e) => sum + _pending(_students[e.key]));
    final double grandTotal = totalCollected + totalPending;
    final double progress = grandTotal == 0 ? 0 : (totalCollected / grandTotal).clamp(0.0, 1.0);
    
    return Container(
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            height: 50,
            width: 50,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.red.shade100,
                  color: _kGreen,
                  strokeWidth: 6,
                ),
                Center(child: Text('${(progress * 100).toInt()}%', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isEn ? 'Revenue Dashboard' : 'آمدنی ڈیش بورڈ', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : _kNavy)),
                Text('${isEn ? "Collected" : "وصول شدہ"}: ₹${_formatCurrency(totalCollected)}  |  ${isEn ? "Due" : "واجب الادا"}: ₹${_formatCurrency(totalPending)}', style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.grey.shade700)),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isEn ? 'Reminders sent to all defaulters!' : 'تمام بقایاجات والے طلبہ کو تنبیہی پیغام بھیج دیا گیا!'), backgroundColor: _kGreen));
            },
            style: ElevatedButton.styleFrom(backgroundColor: _kRed, foregroundColor: Colors.white),
            icon: const Icon(Icons.notifications_active, size: 16),
            label: Text(isEn ? 'Nudge All' : 'یاد دہانی بھیجیں', style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }



  // ─────────────────────────────────────────────────────────────────────────
  // CALENDAR BAR  (← month → navigation)
  // ─────────────────────────────────────────────────────────────────────────
  // ignore: unused_element
  Widget _buildCalendarBar() {
    return Container(
      color: _kNavy,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(children: [
        // Previous month
        IconButton(
          onPressed: () {
            setState(() {
              if (_selectedMonthIndex == 0) {
                _selectedMonthIndex = 11;
                _selectedYear--;
              } else {
                _selectedMonthIndex--;
              }
            });
          },
          icon: const Icon(Icons.chevron_left_rounded,
              color: Colors.white, size: 28),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        // Month display + year selector
        Expanded(
          child: GestureDetector(
            onTap: _showMonthYearPicker,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.calendar_month_rounded,
                      color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    _selectedMonthLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_drop_down_rounded,
                      color: Colors.white70, size: 20),
                ],
              ),
            ),
          ),
        ),
        // Next month
        IconButton(
          onPressed: () {
            setState(() {
              if (_selectedMonthIndex == 11) {
                _selectedMonthIndex = 0;
                _selectedYear++;
              } else {
                _selectedMonthIndex++;
              }
            });
          },
          icon: const Icon(Icons.chevron_right_rounded,
              color: Colors.white, size: 28),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ]),
    );
  }

  void _showMonthYearPicker() {
    int tempMonth = _selectedMonthIndex;
    int tempYear = _selectedYear;
    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('Select Month & Year',
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            // Year
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              IconButton(
                onPressed: () => setSt(() => tempYear--),
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Text('$tempYear',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              IconButton(
                onPressed: () => setSt(() => tempYear++),
                icon: const Icon(Icons.add_circle_outline),
              ),
            ]),
            const SizedBox(height: 8),
            // Month grid
            SizedBox(
              height: 160,
              child: GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 2,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
                children: List.generate(12, (i) {
                  final isSelected = i == tempMonth;
                  return GestureDetector(
                    onTap: () => setSt(() => tempMonth = i),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? _kNavy : (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF334155) : Colors.grey.shade100),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          _kMonths[i].substring(0, 3),
                          style: TextStyle(
                            color: isSelected ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87),
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ]),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _kNavy),
              onPressed: () {
                setState(() {
                  _selectedMonthIndex = tempMonth;
                  _selectedYear = tempYear;
                });
                Navigator.pop(ctx);
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SELECT ALL ROW
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildSelectAllRow(AppLocalizations loc) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEn = loc.locale.languageCode == 'en';
    return Container(
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: Row(children: [
        Checkbox(
          value: _selectAll,
          activeColor: isDark ? Colors.indigoAccent : _kNavy,
          onChanged: _toggleSelectAll,
        ),
        Text(isEn ? 'Select All' : 'سب منتخب کریں',
            style:
                const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const Spacer(),
        // timeline toggle hint
        const Icon(Icons.timeline, size: 14, color: Colors.grey),
        const SizedBox(width: 4),
        Text(isEn ? 'Tap row to see timeline' : 'ٹائم لائن کے لیے کلک کریں',
            style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TABLE HEADER
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildTableHeader(AppLocalizations loc) {
    const style = TextStyle(
        fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white);
    final isEn = widget.languageController.locale.languageCode == 'en';
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF074E32),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: Row(children: [
        const SizedBox(width: 44),
        const SizedBox(width: 4),
        SizedBox(
          width: 140,
          child: Text(
            isEn ? 'Student / Father Name' : 'طالب علم / والد کا نام',
            style: style,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 4),
        SizedBox(
          width: 105,
          child: Center(
            child: Text(
              isEn ? 'Fee Status' : 'فیس کی حالت',
              style: style,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        const Spacer(),
        SizedBox(
          width: 80,
          child: Center(
            child: Text(
              isEn ? 'Actions' : 'پیغام و کارروائی',
              style: style,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STUDENT ROW
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildStudentRow(
      MapEntry<int, Map<String, dynamic>> entry, int serial, AppLocalizations loc) {
    final globalIdx = entry.key;
    final s = _students[globalIdx];
    final isSelected = _selectedIndices.contains(globalIdx);
    final paid = _paid(s);
    final total = _total(s);
    final pending = total - paid;
    final status = _feeStatus(s);
    final isPaid = status == 'paid';
    final hasPending = pending > 0;
    final method = (s['preferredApp'] ?? s['messageMethod'] ?? 'WhatsApp').toString();
    final isWhatsApp = method.toLowerCase().contains('whatsapp');
    final langCode = (s['preferredLanguage'] ?? s['language'] ?? 'ur').toString();
    final langOption = kAllLanguages.firstWhere(
        (l) => l.code == langCode,
        orElse: () => kAllLanguages.first);
    final isExpanded = _expandedRows.contains(globalIdx);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBgColor = Theme.of(context).cardTheme.color ?? (isDark ? const Color(0xFF1E2541) : Colors.white);
    final selectedColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFEBF3FF);
    final textColor = isDark ? Colors.white : _kNavy;
    final subColor = isDark ? Colors.white70 : Colors.grey.shade600;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 3.5),
      decoration: BoxDecoration(
        color: isSelected ? selectedColor : cardBgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected ? (isDark ? Colors.tealAccent : const Color(0xFF0A1F5C)) : (isDark ? const Color(0xFF334155) : Colors.grey.shade200),
          width: isSelected ? 2.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
              color: isSelected
                  ? const Color(0xFF0A1F5C).withValues(alpha: 0.18)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: isSelected ? 8 : 4,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(children: [
        // ── main row ──
        GestureDetector(
          onTap: () {
            setState(() {
              if (isExpanded) {
                _expandedRows.remove(globalIdx);
              } else {
                _expandedRows.add(globalIdx);
              }
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // checkbox
                  SizedBox(
                    width: 24,
                    child: Checkbox(
                      value: isSelected,
                      activeColor: isDark ? Colors.tealAccent : _kNavy,
                      materialTapTargetSize:
                          MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      onChanged: (v) => _toggleStudent(globalIdx, v),
                    ),
                  ),
                  // serial
                  SizedBox(
                    width: 20,
                    child: Text('$serial',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: textColor)),
                  ),
                  const SizedBox(width: 4),
                  // name + parent
                  SizedBox(
                    width: 140,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TranslatedText(
                            s['name']?.toString() ?? '-',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: textColor),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          TranslatedText(
                            s['fatherName']?.toString() ?? '-',
                            style: TextStyle(
                                fontSize: 11,
                                color: subColor),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ]),
                  ),
                  const SizedBox(width: 4),
                  // fee status compact with icon badge
                  SizedBox(
                    width: 105,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                Text('₹${_formatCurrency(paid)}',
                                    style: const TextStyle(
                                        color: _kGreen,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11)),
                                const Text(' / ',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey)),
                                Text('₹${_formatCurrency(pending)}',
                                    style: TextStyle(
                                        color: pending > 0 ? _kOrange : _kGreen,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11)),
                              ]),
                        ),
                        const SizedBox(height: 2),
                        _FeeProgressBar(paid: paid, total: total),
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isPaid
                                ? Colors.green.shade700
                                : (paid > 0 ? Colors.amber.shade800 : Colors.red.shade700),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isPaid
                                      ? Icons.check_circle_rounded
                                      : (paid > 0
                                          ? Icons.account_balance_wallet_rounded
                                          : Icons.error_outline_rounded),
                                  color: Colors.white,
                                  size: 12,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  isPaid
                                      ? (loc.locale.languageCode == 'en' ? 'PAID' : 'مکمل ادا')
                                      : (paid > 0
                                          ? (loc.locale.languageCode == 'en' ? 'PARTIAL' : 'بقیہ')
                                          : (loc.locale.languageCode == 'en' ? 'DUE' : 'واجب الادا')),
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  // ── DIRECT MESSAGE BUTTON IN PREFERRED APP & PREFERRED LANGUAGE ──
                  IconButton(
                    icon: Icon(
                      isWhatsApp ? Icons.chat_rounded : Icons.textsms_rounded,
                      color: isWhatsApp ? Colors.green.shade600 : Colors.blue.shade600,
                      size: 20,
                    ),
                    tooltip: loc.locale.languageCode == 'en'
                        ? 'Send Message ($method - ${langOption.nativeScript})'
                        : 'والدین کو میسج بھیجیں ($method - ${langOption.nativeScript})',
                    onPressed: () async {
                      final msg = _feeMessage(s);
                      final phone = (s['fatherPhone'] ?? s['parentPhone'] ?? s['phone'] ?? '').toString().trim();
                      if (phone.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('اس طالب علم کے والدین کا فون نمبر موجود نہیں ہے۔'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      if (isWhatsApp) {
                        await _openWhatsApp(phone, msg);
                      } else {
                        await _openSms(phone, msg);
                      }
                    },
                  ),
                  const Spacer(),
                  if (widget.currentRole != AppRole.mutawalli)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded, size: 20),
                      padding: EdgeInsets.zero,
                    onSelected: (value) async {
                      if (value == 'edit') {
                        _showEditFeeDialog(globalIdx);
                      } else if (value == 'alert') {
                        final msg = _feeMessage(s);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(msg),
                            backgroundColor: hasPending ? _kNavy : _kGreen,
                            duration: const Duration(seconds: 4)));
                      } else if (value == 'toggle_paid') {
                        final tot = s['feeAmount']?.toString() ?? '300';
                        final newStatus = isPaid ? 'due' : 'paid';
                        final newPaid = isPaid ? '0' : tot;
                        _updateMonthRecord(globalIdx, newStatus, newPaid);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(isPaid
                              ? 'Marked ${s['name']} fee as Pending'
                              : 'Marked ${s['name']} fee as Paid (₹$tot)'),
                          duration: const Duration(seconds: 2),
                          backgroundColor: isPaid ? _kOrange : _kGreen,
                        ));
                      } else if (value == 'language') {
                        _showLanguagePicker(globalIdx);
                      } else if (value == 'method') {
                        final newMethod = isWhatsApp ? 'SMS' : 'WhatsApp';
                        setState(() {
                          _students[globalIdx]['messageMethod'] = newMethod;
                        });
                        _saveChanges();
                      } else if (value == 'call') {
                        _openCall(s['fatherPhone']?.toString() ?? '');
                      } else if (value == 'delete') {
                        _deleteStudent(globalIdx);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            const Icon(Icons.edit_note_rounded, color: Colors.blue),
                            const SizedBox(width: 8),
                            Text(loc.locale.languageCode == 'en' ? 'Edit Fee' : 'فیس کی ترمیم'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'alert',
                        child: Row(
                          children: [
                            Icon(hasPending ? Icons.notifications_active_rounded : Icons.notifications_none_rounded, color: Colors.orange),
                            const SizedBox(width: 8),
                            Text(loc.locale.languageCode == 'en' ? 'Send Reminder' : 'یاددہانی بھیجیں'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'toggle_paid',
                        child: Row(
                          children: [
                            Icon(isPaid ? Icons.check_circle_outline_rounded : Icons.check_circle_rounded, color: Colors.green),
                            const SizedBox(width: 8),
                            Text(isPaid 
                                ? (loc.locale.languageCode == 'en' ? 'Mark Pending' : 'واجب الادا کریں') 
                                : (loc.locale.languageCode == 'en' ? 'Mark Paid' : 'ادا شدہ کریں')),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'language',
                        child: Row(
                          children: [
                            const Icon(Icons.language_rounded, color: Colors.teal),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${loc.locale.languageCode == 'en' ? "Language" : "زبان"}: ${langOption.nativeScript}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'method',
                        child: Row(
                          children: [
                            Icon(isWhatsApp ? Icons.chat_rounded : Icons.sms_rounded, color: Colors.indigo),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${loc.locale.languageCode == 'en' ? "Method" : "طریقہ"}: $method',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'call',
                        child: Row(
                          children: [
                            const Icon(Icons.phone_rounded, color: Colors.green),
                            const SizedBox(width: 8),
                            Text(loc.locale.languageCode == 'en' ? 'Call Father' : 'والد کو کال کریں'),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(Icons.delete_rounded, color: Colors.red),
                            const SizedBox(width: 8),
                            Text(loc.locale.languageCode == 'en' ? 'Delete Student' : 'طالب علم حذف کریں'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ]),
          ),
        ),
        // ── TIMELINE EXPANSION ──
        if (isExpanded) _buildTimelineRow(globalIdx, s),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 12-MONTH TIMELINE ROW
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildTimelineRow(int globalIdx, Map<String, dynamic> s) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FF),
        borderRadius:
            const BorderRadius.vertical(bottom: Radius.circular(10)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.timeline, size: 14, color: _kNavy),
          const SizedBox(width: 4),
          Text(
            'Fee Timeline — $_selectedYear',
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: _kNavy),
          ),
          const Spacer(),
          // PDF receipt button
          _TimelineActionBtn(
            icon: Icons.receipt_long,
            label: 'Receipt',
            color: _kNavy,
            onTap: () => _printStudentReceipt(globalIdx),
          ),
          const SizedBox(width: 6),
          // PDF timeline button
          _TimelineActionBtn(
            icon: Icons.picture_as_pdf_rounded,
            label: 'Year PDF',
            color: _kRed,
            onTap: () => _printStudentTimeline(globalIdx),
          ),
        ]),
        const SizedBox(height: 8),
        // 12 month dots
        SizedBox(
          height: 56,
          child: Row(
            children: List.generate(12, (mIdx) {
              final status = _monthStatusForIndex(s, mIdx);
              final isCurrentMonth = mIdx == _selectedMonthIndex;
              Color dotColor;
              IconData dotIcon;
              switch (status) {
                case 'paid':
                  dotColor = _kGreen;
                  dotIcon = Icons.check_circle;
                  break;
                case 'partially_paid':
                  dotColor = _kOrange;
                  dotIcon = Icons.timelapse;
                  break;
                case 'due':
                  dotColor = _kRed;
                  dotIcon = Icons.cancel;
                  break;
                default:
                  dotColor = Colors.grey.shade300;
                  dotIcon = Icons.circle_outlined;
              }
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedMonthIndex = mIdx;
                    });
                  },
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: isCurrentMonth ? 26 : 22,
                          height: isCurrentMonth ? 26 : 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: dotColor,
                            border: isCurrentMonth
                                ? Border.all(
                                    color: _kNavy, width: 2)
                                : null,
                            boxShadow: isCurrentMonth
                                ? [
                                    BoxShadow(
                                        color: _kNavy.withValues(alpha: 0.3),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2))
                                  ]
                                : null,
                          ),
                          child: Icon(dotIcon,
                              color: Colors.white, size: 12),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _kMonths[mIdx].substring(0, 3),
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: isCurrentMonth
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isCurrentMonth
                                  ? _kNavy
                                  : Colors.grey.shade600),
                        ),
                      ]),
                ),
              );
            }),
          ),
        ),
        // legend
        Row(children: [
          _Dot(color: _kGreen),
          const SizedBox(width: 3),
          const Text('Paid', style: TextStyle(fontSize: 9)),
          const SizedBox(width: 10),
          _Dot(color: _kOrange),
          const SizedBox(width: 3),
          const Text('Partial', style: TextStyle(fontSize: 9)),
          const SizedBox(width: 10),
          _Dot(color: _kRed),
          const SizedBox(width: 3),
          const Text('Due', style: TextStyle(fontSize: 9)),
          const SizedBox(width: 10),
          _Dot(color: Colors.grey.shade300),
          const SizedBox(width: 3),
          const Text('No record', style: TextStyle(fontSize: 9)),
        ]),
        if (_monthRecord(s)?['logs'] is List &&
            (_monthRecord(s)?['logs'] as List).isNotEmpty) ...[
          const SizedBox(height: 6),
          const Divider(height: 1),
          const SizedBox(height: 4),
          const Text('Payment History Log (ادائیگیاں):',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: _kNavy)),
          const SizedBox(height: 2),
          Column(
            children: (_monthRecord(s)?['logs'] as List).map((item) {
              final log = Map<String, dynamic>.from(item as Map);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 1.5),
                child: Row(
                  children: [
                    Text('• ${log['date']}',
                        style: const TextStyle(
                            fontSize: 9, color: Colors.grey)),
                    const Spacer(),
                    Text(
                      '+₹${log['amount']} (${log['mode']}) → Total: ₹${log['accumulated']}',
                      style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: _kGreen),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SUMMARY FOOTER
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildSummaryFooter(
      int selected, int alert, int pending, int paid) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _SummaryChip(
                icon: Icons.people_alt_outlined,
                label: 'Selected\nStudents',
                count: selected,
                iconColor: _kNavy),
            _SummaryChip(
                icon: Icons.notifications_none_rounded,
                label: 'Alert',
                count: alert,
                iconColor: _kNavy),
            _SummaryChip(
                icon: Icons.currency_rupee_rounded,
                label: 'Pending',
                count: pending,
                iconColor: _kOrange),
            _SummaryChip(
                icon: Icons.check_circle_outline_rounded,
                label: 'Paid',
                count: paid,
                iconColor: _kGreen),
          ]),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SEND BUTTON
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildSendButton(AppLocalizations loc) {
    return SafeArea(
      child: Container(
        color: _kNavy,
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kNavy,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed:
                _selectedIndices.isEmpty ? null : _sendToSelected,
            icon: const Icon(Icons.send_rounded, size: 20),
            label: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Send Message to Selected',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                Text(
                    '(Will send in parents preferred language//app)',
                    style: TextStyle(
                        fontSize: 11, color: Colors.white70)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SUB-WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _SessionToggle extends StatelessWidget {
  final String value;
  final void Function(String) onChanged;
  const _SessionToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        _Tab(
          icon: Icons.wb_sunny_rounded,
          label: 'Subah',
          active: value == 'subah',
          activeColor: Colors.amber.shade600,
          onTap: () => onChanged('subah'),
        ),
        _Tab(
          icon: Icons.dark_mode_rounded,
          label: 'Shaam',
          active: value == 'shaam',
          activeColor: _kNavy,
          onTap: () => onChanged('shaam'),
        ),
      ]),
    );
  }
}

class _Tab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;
  const _Tab(
      {required this.icon,
      required this.label,
      required this.active,
      required this.activeColor,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(children: [
          Icon(icon,
              size: 14, color: active ? Colors.white : Colors.grey),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: active
                      ? Colors.white
                      : Colors.grey.shade600)),
        ]),
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  const _FilterDropdown(
      {required this.value,
      required this.items,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isDk = Theme.of(context).brightness == Brightness.dark;
    final safeValue = items.contains(value) ? value : items.first;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: isDk ? const Color(0xFF334155) : Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: isDk ? const Color(0xFF1E293B) : Colors.white,
      ),
      child: DropdownButton<String>(
        value: safeValue,
        isExpanded: true,
        underline: const SizedBox(),
        isDense: true,
        style: TextStyle(
            fontSize: 11,
            color: isDk ? Colors.white70 : Colors.black87,
            fontWeight: FontWeight.w500),
        items:
            items.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
        onChanged: onChanged,
      ),
    );
  }
}

class _DateTimeBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final date =
        '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}';
    final hour =
        now.hour > 12 ? now.hour - 12 : now.hour == 0 ? 12 : now.hour;
    final ampm = now.hour >= 12 ? 'PM' : 'AM';
    final time =
        '${hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} $ampm';

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(children: [
          const Icon(Icons.calendar_today_outlined,
              size: 12, color: _kNavy),
          const SizedBox(width: 3),
          Text(date,
              style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w500)),
        ]),
      ),
      const SizedBox(height: 3),
      Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(children: [
          const Icon(Icons.access_time_rounded,
              size: 12, color: _kNavy),
          const SizedBox(width: 3),
          Text(time,
              style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w500)),
        ]),
      ),
    ]);
  }
}

class _FeeProgressBar extends StatelessWidget {
  final double paid;
  final double total;
  const _FeeProgressBar({required this.paid, required this.total});

  @override
  Widget build(BuildContext context) {
    final ratio =
        total <= 0 ? 0.0 : (paid / total).clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: 6,
        child: LinearProgressIndicator(
          value: ratio,
          backgroundColor: _kOrange.withValues(alpha: 0.3),
          valueColor:
              const AlwaysStoppedAnimation<Color>(_kGreen),
        ),
      ),
    );
  }
}

// ignore: unused_element
class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final VoidCallback onTap;
  const _IconBtn(
      {required this.icon,
      required this.color,
      required this.size,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          border:
              Border.all(color: color.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: size, color: color),
      ),
    );
  }
}

class _TimelineActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _TimelineActionBtn(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color iconColor;
  const _SummaryChip(
      {required this.icon,
      required this.label,
      required this.count,
      required this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 4),
        Text('$count',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: iconColor)),
      ]),
      Text(label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, color: Colors.grey)),
    ]);
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  const _Dot({required this.color});

  @override
  Widget build(BuildContext context) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );
}

// ignore: unused_element
class _ToolIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  final VoidCallback onPressed;

  const _ToolIconButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
