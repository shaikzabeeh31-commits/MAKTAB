import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_localizations.dart';
import 'role_selection_screen.dart';
import 'shift_manager.dart';
import 'theme_controller.dart';

class AttendanceScreen extends StatefulWidget {
  final List<Map<String, dynamic>> students;
  final LanguageController languageController;
  final ThemeController? themeController;
  final AppRole? currentRole;
  final Function(List<Map<String, dynamic>> updatedStudents)? onSave;
  final String? maktabId;

  const AttendanceScreen({
    super.key,
    required this.students,
    required this.languageController,
    this.themeController,
    this.currentRole,
    this.onSave,
    this.maktabId,
  });

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceArchPainter extends CustomPainter {
  final bool dark;

  const _AttendanceArchPainter({required this.dark});

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
    canvas.drawShadow(arch, const Color(0x44065F46), 6, false);
    canvas.drawPath(
      arch,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? const [Color(0xFF334155), Color(0xFF172033)]
              : const [Colors.white, Color(0xFFF1FAF5), Color(0xFFE2F3EA)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      arch,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..color = const Color(0xFF08734B),
    );
    final Path inner = Path.from(arch);
    canvas.save();
    canvas.translate(0, 3);
    canvas.drawPath(
      inner,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = .8
        ..color = const Color(0xFF68AD91),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _AttendanceArchPainter oldDelegate) =>
      oldDelegate.dark != dark;
}

class _IslamicCapIcon extends StatelessWidget {
  final Color color;
  final double size;

  const _IslamicCapIcon({required this.color, this.size = 18});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size * .72),
      painter: _IslamicCapPainter(color),
    );
  }
}

class _IslamicCapPainter extends CustomPainter {
  final Color color;

  const _IslamicCapPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(size.width * .08, size.height * .82)
      ..quadraticBezierTo(size.width * .10, size.height * .28,
          size.width * .50, size.height * .12)
      ..quadraticBezierTo(size.width * .90, size.height * .28,
          size.width * .92, size.height * .82)
      ..quadraticBezierTo(size.width * .50, size.height * .96,
          size.width * .08, size.height * .82)
      ..close();
    canvas.drawPath(path, paint);
    canvas.drawLine(
      Offset(size.width * .13, size.height * .66),
      Offset(size.width * .87, size.height * .66),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _IslamicCapPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  static const String _studentsStorageKey = 'students_data';

  List<MaktabShift> _shifts = ShiftStore.defaults;
  List<Map<String, dynamic>> _students = <Map<String, dynamic>>[];

  DateTime _selectedDate = DateTime.now();
  String _selectedShiftId = 'morning';
  String _classHeading = 'مکتب اطفال';
  String _teacherHeading = 'معلم/معلمہ کا نام';
  String _institutionName = 'مکتب الفاروق';
  String _institutionAddress = 'مدینہ مسجد، خنّاپیٹ، ڈون';
  bool _isLoading = true;
  bool _isWorking = false;
  bool _detailsExpanded = false;
  bool _headerExpanded = true;
  bool _teacherPresent = false;
  String _teacherAttendanceTime = '';
  String _holidayNotice = '';
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadStudentsAndAttendance();
  }

  @override
  void didUpdateWidget(covariant AttendanceScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // A newly admitted student is saved by the parent screen and then passed
    // back to this already-open AttendanceScreen. Refresh the local list when
    // that parent list changes; initState alone only runs the first time.
    if (!identical(oldWidget.students, widget.students) ||
        oldWidget.students.length != widget.students.length) {
      _loadStudentsAndAttendance();
    }
  }

  String get _dateKey {
    final String year = _selectedDate.year.toString();
    final String month = _selectedDate.month.toString().padLeft(2, '0');
    final String day = _selectedDate.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  String get _attendanceStorageKey =>
      'attendance_${widget.maktabId ?? 'legacy'}_${_dateKey}_$_selectedShiftId';

  String get _legacyAttendanceStorageKey => 'attendance_$_dateKey';

  String get _classHeadingStorageKey =>
      'attendance_class_heading_${widget.maktabId ?? 'legacy'}_$_selectedShiftId';

  String get _teacherHeadingStorageKey =>
      'attendance_teacher_heading_${widget.maktabId ?? 'legacy'}_$_selectedShiftId';

  String get _teacherAttendanceStorageKey =>
      'teacher_attendance_${widget.maktabId ?? 'legacy'}_${_dateKey}_$_selectedShiftId';

  MaktabShift get _selectedShift => _shifts.firstWhere(
        (shift) => shift.id == _selectedShiftId,
        orElse: () => _shifts.first,
      );

  List<Map<String, dynamic>> get _visibleStudents {
    return _students.where((Map<String, dynamic> student) {
      final bool correctShift =
          ShiftStore.studentShiftIds(student).contains(_selectedShiftId);
      return correctShift && _isActiveStudent(student);
    }).toList();
  }

  bool _isActiveStudent(Map<String, dynamic> student) {
    if (student['isActive'] == false || student['active'] == false) return false;
    final String status = (student['studentStatus'] ?? student['status'] ?? '')
        .toString()
        .trim()
        .toLowerCase();
    return status != 'inactive' &&
        status != 'left' &&
        status != 'deleted' &&
        status != 'غیر فعال' &&
        status != 'ترک';
  }

  List<Map<String, dynamic>> get _selectedAbsentees {
    return _visibleStudents.where((Map<String, dynamic> student) {
      return _hasParentMessageIssue(student) &&
          student['selectedForMessage'] == true;
    }).toList();
  }

  bool _hasParentMessageIssue(Map<String, dynamic> student) {
    final status = _attendanceStatus(student);
    return status == 'absent' ||
        status == 'late' ||
        student['hasCap'] == false ||
        student['hasUniform'] == false ||
        student['hasBooks'] == false;
  }

  String _parentMessage(Map<String, dynamic> student) {
    final name = student['name']?.toString().trim() ?? 'آپ کا لڑکا';
    final messages = <String>[];
    final status = _attendanceStatus(student);
    if (status == 'absent') {
      messages.add('آج $name مکتب میں غیر حاضر رہا۔ براہ کرم غیر حاضری کی وجہ بتائیں۔');
    } else if (status == 'late') {
      messages.add('آج $name مکتب میں تاخیر سے پہنچا۔ براہ کرم اسے وقت پر بھیجیں۔');
    }
    if (student['hasCap'] == false) {
      messages.add('آج آپ کا لڑکا $name مکتب آتے وقت گھر سے ٹوپی پہن کر نہیں آیا۔');
    }
    if (student['hasUniform'] == false) {
      messages.add('آج آپ کا لڑکا $name مکتب کا مقررہ لباس پہن کر نہیں آیا۔');
    }
    if (student['hasBooks'] == false) {
      messages.add('آج آپ کا لڑکا $name مکتب کی ضروری کتاب ساتھ لے کر نہیں آیا۔');
    }
    return 'السلام علیکم، ${messages.join(' ')} براہِ کرم توجہ دیں۔';
  }

  String _parentPhone(Map<String, dynamic> student) {
    return (student['fatherPhone'] ??
            student['parentPhone'] ??
            student['phone'] ??
            '')
        .toString();
  }

  Future<void> _sendReportBySms(Map<String, dynamic> student) async {
    final phone = _parentPhone(student).replaceAll(RegExp(r'[^0-9+]'), '');
    if (phone.isEmpty) {
      _showMessage('اس طالب علم کے والدین کا فون نمبر موجود نہیں ہے۔', isError: true);
      return;
    }
    final uri = Uri(
      scheme: 'sms',
      path: phone,
      queryParameters: <String, String>{'body': _parentMessage(student)},
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _showMessage('SMS App نہیں کھل سکی۔', isError: true);
    }
  }

  Future<void> _sendReportByWhatsApp(Map<String, dynamic> student) async {
    var phone = _parentPhone(student).replaceAll(RegExp(r'[^0-9]'), '');
    if (phone.isEmpty) {
      _showMessage('اس طالب علم کے والدین کا فون نمبر موجود نہیں ہے۔', isError: true);
      return;
    }
    if (phone.length == 10) phone = '91$phone';
    final uri = Uri.parse(
      'https://wa.me/$phone?text=${Uri.encodeComponent(_parentMessage(student))}',
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _showMessage('WhatsApp نہیں کھل سکا۔', isError: true);
    }
  }

  int get _presentCount => _visibleStudents
      .where((student) => _attendanceStatus(student) == 'present')
      .length;
  int get _absentCount => _visibleStudents
      .where((student) => _attendanceStatus(student) == 'absent')
      .length;
  int get _lateCount => _visibleStudents
      .where((student) => _attendanceStatus(student) == 'late')
      .length;

  String _studentClass(Map<String, dynamic> student) {
    return (student['className'] ??
            student['class'] ??
            student['selectedClass'] ??
            student['grade'] ??
            // Legacy records used group as the class field.
            student['group'])
            ?.toString()
            .trim() ??
        '';
  }

  String _attendanceStatus(Map<String, dynamic> student) {
    final String? status = student['attendanceStatus']?.toString();
    if (status == 'present' || status == 'absent' || status == 'late') {
      return status!;
    }
    return student['isPresent'] == false ? 'absent' : 'present';
  }

  String _studentId(Map<String, dynamic> student) {
    final String savedId = student['id']?.toString().trim() ?? '';
    if (savedId.isNotEmpty) return savedId;

    final String name = student['name']?.toString().trim() ?? '';
    final String phone = student['fatherPhone']?.toString().trim() ?? '';
    return '$name-$phone';
  }

  Future<void> _loadStudentsAndAttendance() async {
    if (mounted) setState(() => _isLoading = true);

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      _shifts = await ShiftStore.load();
      if (_shifts.every((shift) => shift.id != _selectedShiftId)) {
        _selectedShiftId = _shifts.first.id;
      }
      final String? rawStudents = prefs.getString(_studentsStorageKey);
      final String? rawAttendance = prefs.getString(_attendanceStorageKey) ??
          prefs.getString(_legacyAttendanceStorageKey);
      final String? academicYear = prefs.getString('academic_year_${widget.maktabId}') ??
          prefs.getString('academic_year');
      if (academicYear != null && academicYear.trim().isNotEmpty) {
        _classHeading = academicYear.trim();
      } else if (prefs.getString(_classHeadingStorageKey)?.trim().isNotEmpty == true) {
        _classHeading = prefs.getString(_classHeadingStorageKey)!.trim();
      } else {
        _classHeading = 'مکتب اطفال';
      }
      final String? loggedTeacher = prefs.getString('logged_in_user_name') ??
          prefs.getString('cred_user_name') ??
          prefs.getString('user_full_name') ??
          prefs.getString('teacher_name') ??
          prefs.getString(_teacherHeadingStorageKey);
      if (loggedTeacher != null && loggedTeacher.trim().isNotEmpty) {
        _teacherHeading = loggedTeacher.trim();
      } else {
        _teacherHeading = 'معلم/معلمہ کا نام';
      }
      _teacherPresent =
          prefs.getBool(_teacherAttendanceStorageKey) ?? false;
      _teacherAttendanceTime = prefs.getString('${_teacherAttendanceStorageKey}_time') ??
          prefs.getString('last_teacher_attendance_timestamp') ?? '';
      final String? savedInstitution = prefs.getString('cred_maktab_name') ??
          prefs.getString('maktab_name') ??
          prefs.getString('mosque_name');
      if (savedInstitution != null && savedInstitution.trim().isNotEmpty) {
        _institutionName = savedInstitution.trim();
      }
      _institutionAddress =
          prefs.getString('maktab_address')?.trim().isNotEmpty == true
              ? prefs.getString('maktab_address')!.trim()
              : 'مدینہ مسجد، خنّاپیٹ، ڈون';
      _holidayNotice = '';
      final holidayRaw = prefs.getString('maktab_holiday_v1');
      if (holidayRaw != null) {
        final holiday =
            Map<String, dynamic>.from(jsonDecode(holidayRaw) as Map);
        final weeklyDay = holiday['weeklyDay'] as int?;
        if (holiday['enabled'] == true || weeklyDay == _selectedDate.weekday) {
          final reason = holiday['reason']?.toString().trim() ?? '';
          _holidayNotice = reason.isEmpty ? 'چھٹی' : 'چھٹی: $reason';
        }
      }

      final Map<String, dynamic> attendance =
          rawAttendance == null || rawAttendance.isEmpty
          ? <String, dynamic>{}
          : Map<String, dynamic>.from(jsonDecode(rawAttendance) as Map);

      final List<Map<String, dynamic>> loaded = <Map<String, dynamic>>[];

      // Merge both sources so every newly admitted/saved student remains
      // visible in attendance; lesson groups must never hide a student here.
      final storedStudents = rawStudents != null && rawStudents.isNotEmpty
          ? (jsonDecode(rawStudents) as List<dynamic>)
          : <dynamic>[];
      final mergedById = <String, Map<String, dynamic>>{};
      for (final source in <List<dynamic>>[storedStudents, widget.students]) {
        for (final item in source) {
          if (item is! Map) continue;
          final student = Map<String, dynamic>.from(item);
          final id = _studentId(student);
          mergedById[id] = <String, dynamic>{
            ...?mergedById[id],
            ...student,
          };
        }
      }
      final List<dynamic> decoded = mergedById.values.toList();

      final String? currentMaktab = widget.maktabId ?? prefs.getString('active_maktab_id');
      for (final dynamic item in decoded) {
          final Map<String, dynamic> student =
              Map<String, dynamic>.from(item as Map);

          if (currentMaktab != null && currentMaktab.isNotEmpty) {
            final ownerId = student['maktabId']?.toString();
            if (ownerId != null && ownerId.isNotEmpty && ownerId != currentMaktab) {
              continue;
            }
          }

          final dynamic savedValue = attendance[_studentId(student)];
          final Map<String, dynamic>? saved = savedValue is Map
              ? Map<String, dynamic>.from(savedValue)
              : null;

          final String? savedStatus = saved?['attendanceStatus']?.toString();
          student['attendanceStatus'] = savedStatus == 'present' ||
                  savedStatus == 'absent' ||
                  savedStatus == 'late'
              ? savedStatus
              : (saved?['isPresent'] == false ? 'absent' : 'present');
          student['isPresent'] = student['attendanceStatus'] != 'absent';
          student['selectedForMessage'] =
              saved?['selectedForMessage'] ?? false;
          student['hasCap'] = saved?['hasCap'] ?? student['hasCap'] ?? true;
          student['hasUniform'] =
              saved?['hasUniform'] ?? student['hasUniform'] ?? true;
          student['hasBooks'] =
              saved?['hasBooks'] ?? student['hasBooks'] ?? true;
          loaded.add(student);
      }

      if (!mounted) return;
      setState(() {
        _students = loaded;
      });
    } catch (error) {
      _showMessage('طلبہ کی فہرست لوڈ نہیں ہوسکی: $error', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveAttendance({bool showConfirmation = true}) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> record = <String, dynamic>{};

      for (final Map<String, dynamic> student in _visibleStudents) {
        record[_studentId(student)] = <String, dynamic>{
          'attendanceStatus': _attendanceStatus(student),
          'isPresent': _attendanceStatus(student) != 'absent',
          'selectedForMessage': student['selectedForMessage'] == true,
          'hasCap': student['hasCap'] as bool? ?? true,
          'hasUniform': student['hasUniform'] as bool? ?? true,
          'hasBooks': student['hasBooks'] as bool? ?? true,
        };
      }

      await prefs.setString(_attendanceStorageKey, jsonEncode(record));
      widget.onSave?.call(_students);
      if (showConfirmation) _showMessage('$_dateKey کی حاضری محفوظ ہوگئی۔');
    } catch (error) {
      _showMessage('حاضری محفوظ نہیں ہوسکی: $error', isError: true);
    }
  }

  Future<void> _toggleTeacherAttendance() async {
    if (_teacherPresent) {
      final bool? remove = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('استاد کی حاضری'),
          content: const Text('کیا اس تاریخ اور شفٹ کی حاضری ہٹانی ہے؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('نہیں'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('ہاں، ہٹائیں'),
            ),
          ],
        ),
      );
      if (remove != true) return;
    }
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool value = !_teacherPresent;
    await prefs.setBool(_teacherAttendanceStorageKey, value);
    if (value) {
      final now = DateTime.now();
      final timeStr = '${now.day}/${now.month}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      await prefs.setString('${_teacherAttendanceStorageKey}_time', timeStr);
      await prefs.setString('last_teacher_attendance_timestamp', timeStr);
      await prefs.setString('last_teacher_attendance_name', _teacherHeading);
      if (mounted) setState(() => _teacherAttendanceTime = timeStr);
    } else {
      await prefs.remove('${_teacherAttendanceStorageKey}_time');
      await prefs.remove('last_teacher_attendance_timestamp');
      if (mounted) setState(() => _teacherAttendanceTime = '');
    }
    if (!mounted) return;
    setState(() => _teacherPresent = value);
    _showMessage(value
        ? 'استاد کی حاضری محفوظ ہوگئی۔'
        : 'استاد کی حاضری ہٹا دی گئی۔');
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2040),
      helpText: 'حاضری کی تاریخ منتخب کریں',
      cancelText: 'منسوخ',
      confirmText: 'منتخب کریں',
    );

    if (picked == null || !mounted) return;
    setState(() => _selectedDate = picked);
    await _loadStudentsAndAttendance();
  }

  void _markAttendance(Map<String, dynamic> student, String status) {
    setState(() {
      student['attendanceStatus'] = status;
      student['isPresent'] = status != 'absent';
      student['selectedForMessage'] = _hasParentMessageIssue(student);
    });
  }

  void _toggleMessageSelection(
    Map<String, dynamic> student,
    bool? selected,
  ) {
    if (!_hasParentMessageIssue(student)) {
      _showMessage('اس طالب علم کے لیے کوئی شکایت موجود نہیں ہے۔', isError: true);
      return;
    }
    setState(() => student['selectedForMessage'] = selected ?? false);
  }

  void _markAllPresent() {
    setState(() {
      for (final Map<String, dynamic> student in _visibleStudents) {
        student['isPresent'] = true;
        student['attendanceStatus'] = 'present';
        student['selectedForMessage'] = _hasParentMessageIssue(student);
      }
    });
  }

  Future<void> _openMessageSheet() async {
    final List<Map<String, dynamic>> selected = _selectedAbsentees;
    if (selected.isEmpty) {
      _showMessage('میسج کے لیے کوئی شکایت منتخب نہیں ہے۔',
          isError: true);
      return;
    }

    await _saveAttendance(showConfirmation: false);
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext sheetContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            child: SizedBox(
              height: MediaQuery.sizeOf(sheetContext).height * 0.68,
              child: Column(
                children: <Widget>[
                  Text(
                    'والدین کے لیے تیار پیغامات (${selected.length})',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView.separated(
                      itemCount: selected.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (BuildContext context, int index) {
                        final Map<String, dynamic> student = selected[index];
                        return ListTile(
                          leading: CircleAvatar(child: Text('${index + 1}')),
                          title: Text(
                            student['name']?.toString() ?? 'طالب علم',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(_parentMessage(student)),
                          trailing: PopupMenuButton<String>(
                            tooltip: 'پیغام بھیجنے کا طریقہ',
                            icon: const Icon(Icons.send_rounded,
                                color: Colors.green),
                            onSelected: (method) {
                              if (method == 'whatsapp') {
                                _sendReportByWhatsApp(student);
                              } else {
                                _sendReportBySms(student);
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: 'whatsapp',
                                child: Row(children: [
                                  Icon(Icons.chat_rounded, color: Colors.green),
                                  SizedBox(width: 10),
                                  Text('WhatsApp'),
                                ]),
                              ),
                              PopupMenuItem(
                                value: 'sms',
                                child: Row(children: [
                                  Icon(Icons.sms_rounded, color: Colors.orange),
                                  SizedBox(width: 10),
                                  Text('SMS'),
                                ]),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          _showMessage('تمام رپورٹس تیار ہیں۔ ہر نام کے سامنے Send دبائیں۔');
                        },
                        icon: const Icon(Icons.send),
                        label: const Text('تمام رپورٹس تیار ہیں'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<Uint8List> _createAttendancePdf() async {
    final pw.Document document = pw.Document();
    final pw.Font regularFont = await PdfGoogleFonts.notoSansArabicRegular();
    final pw.Font boldFont = await PdfGoogleFonts.notoSansArabicBold();
    final List<Map<String, dynamic>> students = _visibleStudents;

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
        textDirection: pw.TextDirection.rtl,
        margin: const pw.EdgeInsets.all(28),
        build: (pw.Context context) => <pw.Widget>[
          pw.Text(
            'طلبہ کی حاضری',
            style: pw.TextStyle(font: boldFont, fontSize: 22),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            '$_institutionName\n$_institutionAddress\nمکتب: $_classHeading   |   معلم/معلمہ: $_teacherHeading   |   تاریخ: $_dateKey   |   شفٹ: ${_selectedShift.name}',
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'کل طلبہ: ${students.length} | حاضر: $_presentCount | غیر حاضر: $_absentCount | تاخیر: $_lateCount',
          ),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            context: context,
            headerStyle: pw.TextStyle(font: boldFont, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.green700),
            cellAlignment: pw.Alignment.centerRight,
            headers: <String>[
              'نمبر',
              'طالب علم',
              'کلاس',
              'والد کا نام',
              'حاضری',
            ],
            data: List<List<String>>.generate(students.length, (int index) {
              final Map<String, dynamic> student = students[index];
              return <String>[
                '${index + 1}',
                student['name']?.toString() ?? '-',
                _studentClass(student).isEmpty
                    ? 'مقرر نہیں'
                    : _studentClass(student),
                student['fatherName']?.toString() ?? '-',
                _attendanceStatus(student) == 'absent'
                    ? 'غیر حاضر'
                    : _attendanceStatus(student) == 'late'
                        ? 'تاخیر'
                        : 'حاضر',
              ];
            }),
          ),
        ],
      ),
    );

    return document.save();
  }

  Future<void> _sharePdf() async {
    if (_visibleStudents.isEmpty) {
      _showMessage('اس شفٹ میں PDF بنانے کے لیے کوئی طالب علم نہیں ہے۔',
          isError: true);
      return;
    }

    setState(() => _isWorking = true);
    try {
      await _saveAttendance(showConfirmation: false);
      final Uint8List pdf = await _createAttendancePdf();
      await Printing.sharePdf(
        bytes: pdf,
        filename: 'attendance_${_selectedShift.name}_$_dateKey.pdf',
      );
    } catch (error) {
      _showMessage('PDF تیار نہیں ہوسکی: $error', isError: true);
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
      ),
    );
  }

  Future<void> _pickShift() async {
    final value = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text('شفٹ منتخب کریں', textAlign: TextAlign.center),
            ),
            for (final shift in _shifts)
              ListTile(
                leading: Icon(shift.id == 'morning'
                    ? Icons.wb_sunny_outlined
                    : Icons.nightlight_outlined),
                title: Text(shift.name),
                subtitle: shift.startTime.isEmpty && shift.endTime.isEmpty
                    ? null
                    : Text('${shift.startTime} تا ${shift.endTime}'),
                trailing: shift.id == _selectedShiftId
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : null,
                onTap: () => Navigator.pop(ctx, shift.id),
              ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.edit_calendar_rounded),
              title: const Text('شفٹیں بنائیں یا تبدیل کریں'),
              onTap: () => Navigator.pop(ctx, '__manage__'),
            ),
          ],
        ),
      ),
    );
    if (value == '__manage__' && mounted) {
      await showShiftManager(context);
      await _loadStudentsAndAttendance();
      return;
    }
    if (value != null && mounted && value != _selectedShiftId) {
      setState(() => _selectedShiftId = value);
      await _loadStudentsAndAttendance();
    }
  }

  Future<void> _editInstitutionName() async {
    final controller = TextEditingController(text: _institutionName);
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('مکتب کا نام'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textDirection: TextDirection.rtl,
          maxLines: 1,
          maxLength: 50,
          decoration: const InputDecoration(
            labelText: 'مثلاً: مکتب الفاروق',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('منسوخ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('محفوظ کریں'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null || value.isEmpty || !mounted) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('maktab_name', value);
    if (mounted) setState(() => _institutionName = value);
  }

  Future<void> _editInstitutionAddress() async {
    final TextEditingController controller =
        TextEditingController(text: _institutionAddress);
    final String? value = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('مسجد، محلہ، گاؤں یا شہر کا پتہ'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textDirection: TextDirection.rtl,
          maxLines: 2,
          maxLength: 100,
          decoration: const InputDecoration(
            labelText: 'مثلاً: مدینہ مسجد، خنّاپیٹ، ڈون',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('منسوخ'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('محفوظ کریں'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null || value.isEmpty || !mounted) return;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('maktab_address', value);
    if (mounted) setState(() => _institutionAddress = value);
  }

  Future<void> _editClassHeading() async {
    final TextEditingController controller =
        TextEditingController(text: _classHeading);
    final String? value = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('مکتب کی قسم لکھیں'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textDirection: TextDirection.rtl,
          maxLength: 30,
          decoration: const InputDecoration(
            labelText: 'مثلاً: مکتب اطفال، مکتب نسواں یا مکتب رجال',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (String text) =>
              Navigator.pop(dialogContext, text.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('منسوخ'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('محفوظ کریں'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null || value.isEmpty || !mounted) return;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_classHeadingStorageKey, value);
    if (mounted) setState(() => _classHeading = value);
  }

  Future<void> _editTeacherHeading() async {
    final TextEditingController controller =
        TextEditingController(text: _teacherHeading);
    final String? value = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('معلم یا معلمہ کا نام لکھیں'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textDirection: TextDirection.rtl,
          maxLength: 50,
          decoration: const InputDecoration(
            labelText: 'مثلاً: مولانا احمد یا معلمہ فاطمہ',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (String text) =>
              Navigator.pop(dialogContext, text.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('منسوخ'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('محفوظ کریں'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null || value.isEmpty || !mounted) return;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_teacherHeadingStorageKey, value);
    if (mounted) setState(() => _teacherHeading = value);
  }

  Future<void> _openAttendanceSettings() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text('مکتب اور حاضری کی ترتیب',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: const Icon(Icons.mosque_rounded),
              title: const Text('مکتب کا نام'),
              subtitle: Text(_institutionName),
              onTap: () {
                Navigator.pop(sheetContext);
                _editInstitutionName();
              },
            ),
            ListTile(
              leading: const Icon(Icons.location_on_rounded),
              title: const Text('مسجد اور پتہ'),
              subtitle: Text(_institutionAddress),
              onTap: () {
                Navigator.pop(sheetContext);
                _editInstitutionAddress();
              },
            ),
            ListTile(
              leading: const Icon(Icons.school_rounded),
              title: const Text('مکتب کی قسم'),
              subtitle: Text(_classHeading),
              onTap: () {
                Navigator.pop(sheetContext);
                _editClassHeading();
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_rounded),
              title: const Text('معلم یا معلمہ'),
              subtitle: Text(_teacherHeading),
              onTap: () {
                Navigator.pop(sheetContext);
                _editTeacherHeading();
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_calendar_rounded),
              title: const Text('شفٹیں بنائیں یا تبدیل کریں'),
              onTap: () async {
                Navigator.pop(sheetContext);
                await showShiftManager(context);
                await _loadStudentsAndAttendance();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _callParent(Map<String, dynamic> student) async {
    final phone = (student['fatherPhone'] ??
            student['parentPhone'] ??
            student['phone'] ??
            '')
        .toString()
        .replaceAll(RegExp(r'[^0-9+]'), '');
    if (phone.isEmpty) {
      _showMessage('والدین کا فون نمبر موجود نہیں ہے۔', isError: true);
      return;
    }
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _deleteStudent(Map<String, dynamic> student) async {
    final isEn = AppLocalizations.of(context).locale.languageCode == 'en';
    final name = student['name']?.toString() ?? (isEn ? 'Student' : 'طالب علم');
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEn ? 'Delete Student' : 'طالب علم کو حذف کریں'),
        content: Text(isEn
            ? 'Are you sure you want to delete "$name"? This action cannot be undone.'
            : 'کیا آپ واقعی "$name" کو حذف کرنا چاہتے ہیں؟ یہ عمل واپس نہیں ہوسکتا۔'),
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
      _students.remove(student);
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('students_data', jsonEncode(_students));
    widget.onSave?.call(_students);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEn ? '"$name" has been deleted.' : '"$name" حذف ہوگیا۔'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  BoxDecoration _threeD({double radius = 14}) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: dark
            ? const [Color(0xFF334155), Color(0xFF172033)]
            : const [Colors.white, Color(0xFFF5FCF8), Color(0xFFE3F2EA)],
      ),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: const Color(0xFF68AD91)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x33065F46),
          blurRadius: 9,
          offset: Offset(0, 5),
        ),
      ],
    );
  }

  Widget _fit(String text, {Color? color, double size = 11}) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        text,
        maxLines: 1,
        softWrap: false,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _topBox(Widget child, VoidCallback onTap, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 5),
          decoration: _threeD(),
          child: Center(child: child),
        ),
      ),
    );
  }

  Widget _infoBox({
    required Widget child,
    required VoidCallback onTap,
    double height = 42,
    bool holiday = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 7),
        decoration: holiday
            ? BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFF1F1), Color(0xFFFFCDD2)],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFD32F2F), width: 1.5),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x44D32F2F),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              )
            : _threeD(radius: 12),
        child: Center(child: child),
      ),
    );
  }

  Widget _identityArch(bool dark) {
    final isEn = AppLocalizations.of(context).locale.languageCode == 'en';
    return Container(
      margin: const EdgeInsets.fromLTRB(6, 4, 6, 6),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF1E293B) : Colors.white,
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
          // Header Collapse / Expand Arrow Button
          GestureDetector(
            onTap: () => setState(() => _headerExpanded = !_headerExpanded),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _headerExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: const Color(0xFF074E32),
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _headerExpanded ? (isEn ? 'Hide Header' : 'ہیڈر تفصیلات چھپائیں') : (isEn ? 'Show Header' : 'ہیڈر تفصیلات دکھائیں'),
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF074E32)),
                  ),
                ],
              ),
            ),
          ),
          if (_headerExpanded) ...[
            // Top Institution Address Banner
            InkWell(
              onTap: _editInstitutionAddress,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
                alignment: Alignment.center,
                child: Text(
                  _institutionAddress.isNotEmpty
                      ? _institutionAddress
                      : 'مکتب قاسم العلوم مدینہ مسجد کدہ پیٹ، ڈون، ندیال، آندھرا پردیش',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: dark ? Colors.white : const Color(0xFF074E32),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 5),
            // Row 1: Teacher Name & Maktab Department
            Row(
              children: [
                Expanded(
                  child: _archMiniBox(
                    text: _teacherHeading.isNotEmpty ? _teacherHeading : 'معلم/معلمہ کا نام',
                    icon: Icons.fingerprint_rounded,
                    onTap: _editTeacherHeading,
                    dark: dark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _archMiniBox(
                    text: _classHeading.isNotEmpty ? _classHeading : 'مکتب اطفال',
                    icon: Icons.person_rounded,
                    onTap: _editClassHeading,
                    dark: dark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            // Row 2: Shift Dropdown & Date Picker
            Row(
              children: [
                Expanded(
                  child: _archMiniBox(
                    text: _selectedShiftId == 'shabina' ? 'شبینہ' : 'صبح',
                    icon: Icons.wb_sunny_outlined,
                    hasDropdown: true,
                    onTap: () {
                      setState(() {
                        _selectedShiftId = _selectedShiftId == 'subah' ? 'shabina' : 'subah';
                      });
                    },
                    dark: dark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _archMiniBox(
                    text: '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                    icon: Icons.calendar_today_rounded,
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) setState(() => _selectedDate = picked);
                    },
                    dark: dark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            // Row 3: Wide Filter Selector
            Container(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: dark ? const Color(0xFF0F172A) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF074E32), width: 1.2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      'داخل ، غیر حاضر ، حاضر ، کل طلبا',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: dark ? Colors.white : const Color(0xFF074E32),
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_drop_down_rounded, color: dark ? Colors.white70 : const Color(0xFF074E32)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _archMiniBox({
    required String text,
    required IconData icon,
    required VoidCallback onTap,
    required bool dark,
    bool hasDropdown = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: dark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF074E32), width: 1.2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: dark ? Colors.white70 : const Color(0xFF074E32)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: dark ? Colors.white : const Color(0xFF074E32),
                ),
              ),
            ),
            if (hasDropdown)
              Icon(Icons.arrow_drop_down_rounded, color: dark ? Colors.white70 : const Color(0xFF074E32)),
          ],
        ),
      ),
    );
  }

  Widget _header(Widget child, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Container(
        height: 43,
        padding: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          color: const Color(0xFF074E32),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(child: child),
      ),
    );
  }

  Widget _combinedDetailsPanel({
    required List<Map<String, dynamic>> visible,
    required bool allSelected,
    required List<Map<String, dynamic>> messageCandidates,
  }) {
    void toggle() => setState(() => _detailsExpanded = !_detailsExpanded);
    final isEn = AppLocalizations.of(context).locale.languageCode == 'en';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Summary stays hidden until the arrow bar is opened.
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: toggle,
            onVerticalDragEnd: (details) {
              final velocity = details.primaryVelocity ?? 0;
              if (velocity > 120 && !_detailsExpanded) toggle();
              if (velocity < -120 && _detailsExpanded) toggle();
            },
            child: Container(
              height: 25,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF7F0),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF074E32)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _detailsExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 16,
                    color: const Color(0xFF074E32),
                  ),
                  const SizedBox(width: 3),
                  _fit(
                    _detailsExpanded
                        ? (isEn ? 'Hide Details' : 'تفصیل چھپائیں')
                        : (isEn ? 'Show Details' : 'تفصیل دکھائیں'),
                    size: 10.5,
                    color: const Color(0xFF074E32),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            child: _detailsExpanded
                ? Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Container(
                      decoration: _threeD(radius: 13),
                      clipBehavior: Clip.antiAlias,
                      child: Row(
                        children: [
                          _summaryBox(isEn ? 'Present' : 'حاضر', _presentCount, Colors.green,
                              Icons.check_circle),
                          const SizedBox(
                              height: 28, child: VerticalDivider(width: 1)),
                          _summaryBox(isEn ? 'Absent' : 'غیر حاضر', _absentCount, Colors.red,
                              Icons.cancel),
                          const SizedBox(
                              height: 28, child: VerticalDivider(width: 1)),
                          _summaryBox('تاخیر', _lateCount, Colors.orange,
                              Icons.schedule),
                          const SizedBox(
                              height: 28, child: VerticalDivider(width: 1)),
                          _summaryBox('کل طلبہ', visible.length, Colors.blue,
                              Icons.groups),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 4),

          // This header is always visible. The first checkbox is Select All.
          Row(
            textDirection: TextDirection.ltr,
            children: [
              SizedBox(
                width: 32,
                child: Container(
                  height: 43,
                  decoration: BoxDecoration(
                    color: const Color(0xFF074E32),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Transform.scale(
                          scale: .58,
                          child: Checkbox(
                            value: allSelected,
                            fillColor: WidgetStateProperty.all(Colors.white),
                            checkColor: const Color(0xFF074E32),
                            onChanged: (value) {
                              setState(() {
                                for (final student in messageCandidates) {
                                  student['selectedForMessage'] = value == true;
                                }
                              });
                            },
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                        _fit(isEn ? 'All' : 'منتخب', color: Colors.white, size: 7.2),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              _header(
                _fit(isEn ? 'Student Name / Class' : 'نام طالب علم / درجہ', color: Colors.white, size: 10.5),
                flex: 11,
              ),
              const SizedBox(width: 4),
              _header(_fit(isEn ? 'Attendance' : 'حاضری', color: Colors.white, size: 10.5), flex: 3),
              const SizedBox(width: 4),
              _header(_fit(isEn ? 'Cap' : 'ٹوپی', color: Colors.white, size: 9.5), flex: 2),
              const SizedBox(width: 4),
              _header(_fit(isEn ? 'Uniform' : 'لباس', color: Colors.white, size: 9.5), flex: 2),
              const SizedBox(width: 4),
              _header(_fit(isEn ? 'Book' : 'کتاب', color: Colors.white, size: 9.5), flex: 2),
              const SizedBox(width: 4),
              _header(_fit(isEn ? 'Call' : 'کال', color: Colors.white, size: 10.5), flex: 2),
            ],
          ),
        ],
      ),
    );
  }

  ({String label, IconData icon, Color color}) _attendanceVisual(
    String status,
  ) {
    final loc = AppLocalizations.of(context);
    if (status == 'absent') {
      return (
        label: loc.translate('absent'),
        icon: Icons.cancel_rounded,
        color: Colors.red,
      );
    }
    if (status == 'late') {
      return (
        label: loc.translate('late'),
        icon: Icons.schedule_rounded,
        color: Colors.orange,
      );
    }
    return (
      label: loc.translate('present'),
      icon: Icons.check_circle_rounded,
      color: Colors.green,
    );
  }

  void _cycleAttendance(Map<String, dynamic> student) {
    final String current = _attendanceStatus(student);
    final String next = current == 'present'
        ? 'absent'
        : current == 'absent'
            ? 'late'
            : 'present';
    _markAttendance(student, next);
  }

  Future<void> _chooseAttendance(Map<String, dynamic> student) async {
    final String? value = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text('حاضری منتخب کریں', textAlign: TextAlign.center),
            ),
            for (final entry in const [
              ('present', 'حاضر', Icons.check_circle_rounded, Colors.green),
              ('absent', 'غیر حاضر', Icons.cancel_rounded, Colors.red),
              ('late', 'دیر حاضر', Icons.schedule_rounded, Colors.orange),
            ])
              ListTile(
                leading: Icon(entry.$3, color: entry.$4),
                title: Text(entry.$2),
                trailing: _attendanceStatus(student) == entry.$1
                    ? Icon(Icons.check, color: entry.$4)
                    : null,
                onTap: () => Navigator.pop(sheetContext, entry.$1),
              ),
          ],
        ),
      ),
    );
    if (value != null && mounted) _markAttendance(student, value);
  }

  Widget _attendanceCycleButton(Map<String, dynamic> student) {
    final visual = _attendanceVisual(_attendanceStatus(student));
    return Tooltip(
      message: 'کلک سے حالت بدلیں، دیر تک دبانے سے براہِ راست منتخب کریں',
      child: Material(
        color: visual.color.withValues(alpha: .13),
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          onTap: () {
            if (widget.currentRole == AppRole.mutawalli) return;
            _cycleAttendance(student);
          },
          onLongPress: () {
            if (widget.currentRole == AppRole.mutawalli) return;
            _chooseAttendance(student);
          },
          borderRadius: BorderRadius.circular(9),
          child: Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: visual.color, width: 1.2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              textDirection: TextDirection.rtl,
              children: [
                Icon(visual.icon, size: 16, color: visual.color),
                const SizedBox(width: 2),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      visual.label,
                      maxLines: 1,
                      style: TextStyle(
                        color: visual.color,
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _itemButton(
    Map<String, dynamic> student,
    String key,
    IconData? icon,
    String tooltip,
  ) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ok = student[key] as bool? ?? true;
    final color = ok ? Colors.green : Colors.red;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () {
          if (widget.currentRole == AppRole.mutawalli) return;
          setState(() {
            student[key] = !ok;
            student['selectedForMessage'] = _hasParentMessageIssue(student);
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 1),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              icon == null
                  ? _IslamicCapIcon(color: color, size: 20)
                  : Icon(icon, size: 20, color: color),
              Text(
                tooltip,
                style: TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.bold,
                  color: dark ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryBox(String title, int value, Color color, IconData icon) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 2),
        child: _fit('$title: $value', color: color, size: 11.5),
      ),
    );
  }

  Widget _studentCard(Map<String, dynamic> student, int index) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final selected = student['selectedForMessage'] == true;
    final studentName =
        student['name']?.toString().trim() ?? 'بے نام طالب علم';
    final admissionNo = student['admissionNo']?.toString().trim() ?? '';
    final fatherName = (student['fatherName'] ?? student['parentName'] ?? '')
        .toString()
        .trim();
    final nameDirection = RegExp(r'[\u0600-\u06FF]').hasMatch(studentName)
        ? TextDirection.rtl
        : TextDirection.ltr;
    final String sId = student['id']?.toString() ?? student['admissionNo']?.toString() ?? '$index';
    return Dismissible(
      key: Key('att_student_${sId}_$index'),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.green.shade600,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: const [
            Icon(Icons.send_rounded, color: Colors.white, size: 18),
            SizedBox(width: 4),
            Text('پیغام (Send)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10.5)),
          ],
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.red.shade600,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: const [
            Text('حذف (Delete)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10.5)),
            SizedBox(width: 4),
            Icon(Icons.delete_forever_rounded, color: Colors.white, size: 18),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          _sendReportByWhatsApp(student);
          return false;
        } else if (direction == DismissDirection.endToStart) {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text('طالب علم ($studentName) کو حذف کریں؟'),
              content: const Text('کیا آپ اس طالب علم کو حاضری فہرست سے ختم کرنا چاہتے ہیں؟'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('منسوخ')),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('حذف کریں'),
                ),
              ],
            ),
          );
          if (confirm == true) {
            setState(() {
              _students.remove(student);
            });
            await _saveAttendance(showConfirmation: false);
          }
          return false;
        }
        return false;
      },
      child: Container(
        height: 56,
        margin: const EdgeInsets.fromLTRB(7, 1, 7, 1),
        decoration: BoxDecoration(
          color: dark
              ? (index.isEven
                  ? const Color(0xFF111C30)
                  : const Color(0xFF172238))
              : (index.isEven ? Colors.white : const Color(0xFFF7FAF9)),
          border: Border(
            bottom: BorderSide(
              color: dark ? const Color(0xFF334155) : Colors.black12,
            ),
          ),
        ),
        child: Row(
          textDirection: TextDirection.ltr,
          children: [
            SizedBox(
              width: 32,
              child: Center(
                child: Transform.scale(
                  scale: .72,
                  child: Checkbox(
                    value: selected,
                    onChanged: (value) => _toggleMessageSelection(student, value),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              flex: 11,
              child: InkWell(
                onTap: () => _toggleMessageSelection(student, !selected),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        studentName,
                        maxLines: 1,
                        softWrap: false,
                        textAlign: TextAlign.left,
                        textDirection: nameDirection,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: dark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        [
                          if (admissionNo.isNotEmpty) 'داخلہ نمبر: $admissionNo',
                          if (fatherName.isNotEmpty) 'والد: $fatherName',
                        ].join('  •  '),
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                        softWrap: false,
                        textAlign: TextAlign.left,
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: dark ? Colors.white70 : const Color(0xFF047857),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              flex: 3,
              child: _attendanceCycleButton(student),
            ),
            const SizedBox(width: 4),
            Expanded(
              flex: 2,
              child: Center(child: _itemButton(student, 'hasCap', null, 'ٹوپی')),
            ),
            const SizedBox(width: 4),
            Expanded(
              flex: 2,
              child: Center(child: _itemButton(student, 'hasUniform', Icons.checkroom, 'لباس')),
            ),
            const SizedBox(width: 4),
            Expanded(
              flex: 2,
              child: Center(child: _itemButton(student, 'hasBooks', Icons.menu_book_rounded, 'کتاب')),
            ),
            const SizedBox(width: 4),
            Expanded(
              flex: 2,
              child: IconButton(
                onPressed: () => _callParent(student),
                tooltip: 'کال',
                icon: const Icon(Icons.call_rounded, color: Colors.blue, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shiftButton(MaktabShift shift) {
    return Expanded(
      child: OutlinedButton(
        onPressed: () async {
          if (shift.id == _selectedShiftId) return;
          setState(() => _selectedShiftId = shift.id);
          await _loadStudentsAndAttendance();
        },
        child: Text(shift.name),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final visible = _visibleStudents;
    final messageCandidates = visible
        .where((student) => _hasParentMessageIssue(student))
        .toList();
    final allSelected = messageCandidates.isNotEmpty &&
        messageCandidates.every((student) => student['selectedForMessage'] == true);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Use the exact same arch positioning system as the Lesson
                  // Target screen so both headers meet the green app bar at
                  // the same visual height on web and mobile.
                  Padding(
                    padding: EdgeInsets.only(
                      top: MediaQuery.paddingOf(context).top + 2,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _identityArch(dark),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(7, 0, 7, 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: _infoBox(
                            height: 34,
                            onTap: _pickDate,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.calendar_month_rounded,
                                    size: 15, color: Color(0xFF047857)),
                                const SizedBox(width: 4),
                                Flexible(child: _fit(_dateKey, size: 11)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _infoBox(
                            height: 34,
                            holiday: _holidayNotice.isNotEmpty,
                            onTap: _pickShift,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.schedule_rounded,
                                  size: 16,
                                  color: _holidayNotice.isNotEmpty
                                      ? const Color(0xFFD32F2F)
                                      : const Color(0xFF047857),
                                ),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: _fit(
                                    _holidayNotice.isEmpty
                                        ? _selectedShift.name
                                        : '${_selectedShift.name} • $_holidayNotice',
                                    size: 12,
                                    color: _holidayNotice.isNotEmpty
                                        ? const Color(0xFFD32F2F)
                                        : null,
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_drop_down_rounded,
                                  size: 18,
                                  color: _holidayNotice.isNotEmpty
                                      ? const Color(0xFFD32F2F)
                                      : const Color(0xFF047857),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _combinedDetailsPanel(
                    visible: visible,
                    allSelected: allSelected,
                    messageCandidates: messageCandidates,
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: visible.isEmpty
                        ? Center(
                            child: Text(
                                '${_selectedShift.name} کی شفٹ میں کوئی طالب علم موجود نہیں ہے۔'),
                          )
                        : Stack(
                            children: [
                              ListView.builder(
                                controller: _scrollController,
                                itemCount: visible.length,
                                itemBuilder: (_, index) =>
                                    _studentCard(visible[index], index),
                              ),
                              Positioned(
                                bottom: 12,
                                right: 12,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    FloatingActionButton.small(
                                      heroTag: 'att_scroll_up',
                                      backgroundColor: const Color(0xFF074E32),
                                      foregroundColor: Colors.white,
                                      onPressed: () {
                                        if (_scrollController.hasClients) {
                                          _scrollController.animateTo(
                                            0,
                                            duration: const Duration(milliseconds: 300),
                                            curve: Curves.easeOut,
                                          );
                                        }
                                      },
                                      child: const Icon(Icons.arrow_upward_rounded, size: 18),
                                    ),
                                    const SizedBox(height: 6),
                                    FloatingActionButton.small(
                                      heroTag: 'att_scroll_down',
                                      backgroundColor: const Color(0xFF074E32),
                                      foregroundColor: Colors.white,
                                      onPressed: () {
                                        if (_scrollController.hasClients) {
                                          _scrollController.animateTo(
                                            _scrollController.position.maxScrollExtent,
                                            duration: const Duration(milliseconds: 300),
                                            curve: Curves.easeOut,
                                          );
                                        }
                                      },
                                      child: const Icon(Icons.arrow_downward_rounded, size: 18),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
        bottomNavigationBar: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _openMessageSheet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF047857),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.send_rounded, size: 16),
                  label: Text(
                    'پیغام (${_selectedAbsentees.length})',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _saveAttendance,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF074E32),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.save_rounded, size: 16),
                  label: const Text(
                    'حاضری محفوظ کریں',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


}
