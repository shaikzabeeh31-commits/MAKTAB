import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'app_localizations.dart';
import 'shift_manager.dart';

class LessonScreen extends StatefulWidget {
  final List<Map<String, dynamic>> students;
  final LanguageController? languageController;
  final String? maktabId;

  const LessonScreen({
    super.key,
    this.students = const <Map<String, dynamic>>[],
    this.languageController,
    this.maktabId,
  });

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonArchPainter extends CustomPainter {
  final bool dark;
  const _LessonArchPainter({required this.dark});

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
    final Path path = _path(size);
    canvas.drawShadow(path, const Color(0x44065F46), 6, false);
    canvas.drawPath(
      path,
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
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..color = const Color(0xFF08734B),
    );
    canvas.save();
    canvas.translate(0, 3);
    canvas.drawPath(
      Path.from(path),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = .8
        ..color = const Color(0xFF68AD91),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LessonArchPainter oldDelegate) =>
      oldDelegate.dark != dark;
}

class _LessonScreenState extends State<LessonScreen> {
  static const _green = Color(0xFF08734B);
  static const _studentsKey = 'students_data';
  static const _subjectsKey = 'lesson_subjects_v2';
  String get _repeatKey =>
      'lesson_repeat_queue_v2_${widget.maktabId ?? 'legacy'}';
  String get _groupsKey =>
      'lesson_subject_groups_v2_${widget.maktabId ?? 'legacy'}';
  String get _selectedGroupKey =>
      'lesson_selected_group_v1_${widget.maktabId ?? 'legacy'}';
  String _selectedGroupForShiftKey(String shiftId) =>
      '${_selectedGroupKey}_$shiftId';

  final stt.SpeechToText _speech = stt.SpeechToText();
  final TextEditingController _commonLessonController =
      TextEditingController();

  List<MaktabShift> _shifts = ShiftStore.defaults;
  List<String> _subjects = <String>[
    'ناظرہ قرآن',
    'قاعدہ',
    'حفظ قرآن',
    'تجوید',
    'دعائیں',
  ];
  List<Map<String, dynamic>> _students = <Map<String, dynamic>>[];
  final Map<String, TextEditingController> _lessonControllers = {};
  final Map<String, String> _statuses = {};
  final Set<String> _absentStudentIds = <String>{};
  final Map<String, String> _lessonImagePaths = {};
  final Map<String, Map<String, dynamic>> _repeatQueue = {};
  final ImagePicker _imagePicker = ImagePicker();
  List<Map<String, dynamic>> _groups = <Map<String, dynamic>>[];
  String? _selectedGroupId;

  DateTime _selectedDate = DateTime.now();
  String _selectedShiftId = 'morning';
  String _selectedSubject = 'ناظرہ قرآن';
  String _maktabName = 'مکتب الفاروق';
  String _maktabAddress = 'مدینہ مسجد، محلہ، گاؤں/شہر';
  String _holidayNotice = '';
  String _teacherName = 'معلم/معلمہ کا نام';
  bool _loading = true;
  bool _listeningCommon = false;
  bool _controlsExpanded = true;
  String? _listeningStudentId;

  String get _dateKey =>
      '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

  MaktabShift get _selectedShift => _shifts.firstWhere(
        (shift) => shift.id == _selectedShiftId,
        orElse: () => _shifts.first,
      );

  String get _recordKey =>
      'lesson_${widget.maktabId ?? 'legacy'}_${_dateKey}_${_selectedShiftId}_${base64Url.encode(utf8.encode(_selectedSubject))}';

  List<Map<String, dynamic>> get _shiftStudents =>
      _students.where((student) {
        if (student['isActive'] == false || student['active'] == false) {
          return false;
        }
        final currentMaktab = widget.maktabId ?? '';
        if (currentMaktab.isNotEmpty) {
          final ownerId = student['maktabId']?.toString();
          if (ownerId != null && ownerId.isNotEmpty && ownerId != currentMaktab) {
            return false;
          }
        }
        return ShiftStore.studentShiftIds(student).contains(_selectedShiftId);
      }).toList();

  List<Map<String, dynamic>> get _lessonStudents {
    // The main Lesson Target list must never show every admitted student.
    // All students are available only inside the group editor. Here we show
    // members of the group explicitly selected by the teacher.
    if (_selectedGroupId == null || _groups.isEmpty) return _shiftStudents;
    Map<String, dynamic>? group;
    for (final item in _groups) {
      if (item['id'] == _selectedGroupId) {
        group = item;
        break;
      }
    }
    if (group == null) return const <Map<String, dynamic>>[];
    final ids = ((group['studentIds'] as List?) ?? const <dynamic>[])
        .map((item) => item.toString())
        .toSet();
    return _shiftStudents
        .where((student) => ids.contains(_studentId(student)))
        .toList();
  }

  String get _selectedGroupName {
    if (_selectedGroupId == null) return 'گروپ بنائیں';
    for (final group in _groups) {
      if (group['id']?.toString() == _selectedGroupId) {
        return group['name']?.toString().trim().isNotEmpty == true
            ? group['name'].toString().trim()
            : 'گروپ منتخب کریں';
      }
    }
    return 'گروپ منتخب کریں';
  }

  @override
  void initState() {
    super.initState();
    _loadEverything();
  }

  @override
  void dispose() {
    _speech.stop();
    _commonLessonController.dispose();
    for (final controller in _lessonControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadEverything() async {
    final prefs = await SharedPreferences.getInstance();
    if (widget.students.isNotEmpty) {
      _students = widget.students
          .map((student) => Map<String, dynamic>.from(student))
          .toList();
    }
    _shifts = List<MaktabShift>.from(await ShiftStore.load());
    if (_shifts.isEmpty) _shifts = ShiftStore.defaults;
    if (!_shifts.any((shift) => shift.id == _selectedShiftId)) {
      _selectedShiftId = _shifts.first.id;
    }
    _subjects = prefs.getStringList(_subjectsKey) ?? _subjects;
    if (_subjects.isEmpty) _subjects = <String>['ناظرہ قرآن'];
    if (!_subjects.contains(_selectedSubject)) {
      _selectedSubject = _subjects.first;
    }
    _maktabName = prefs.getString('maktab_name') ??
        prefs.getString('attendance_institution_name') ??
        _maktabName;
    _maktabAddress = prefs.getString('maktab_address') ?? _maktabAddress;
    _teacherName = prefs.getString('lesson_teacher_name') ?? _teacherName;
    _holidayNotice = '';
    final holidayRaw = prefs.getString('maktab_holiday_v1');
    if (holidayRaw != null) {
      try {
        final holiday =
            Map<String, dynamic>.from(jsonDecode(holidayRaw) as Map);
        final weeklyDay = holiday['weeklyDay'] as int?;
        if (holiday['enabled'] == true || weeklyDay == _selectedDate.weekday) {
          final reason = holiday['reason']?.toString().trim() ?? '';
          _holidayNotice = reason.isEmpty ? 'چھٹی' : 'چھٹی: $reason';
        }
      } catch (_) {}
    }

    try {
      final rawStudents = prefs.getString(_studentsKey);
      if (_students.isEmpty && rawStudents != null) {
        _students = (jsonDecode(rawStudents) as List)
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
      }
    } catch (_) {}
    try {
      final rawGroups = prefs.getString(_groupsKey);
      if (rawGroups != null) {
        _groups = (jsonDecode(rawGroups) as List)
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
      }
    } catch (_) {}
    final rememberedGroupId =
        prefs.getString(_selectedGroupForShiftKey(_selectedShiftId)) ??
            prefs.getString(_selectedGroupKey);
    final rememberedGroups = _groups.where(
      (group) => group['id']?.toString() == rememberedGroupId,
    );
    if (rememberedGroups.isNotEmpty) {
      final remembered = rememberedGroups.first;
      _selectedGroupId = remembered['id']?.toString();
      final rememberedShift = remembered['shiftId']?.toString() ?? '';
      final rememberedSubject = remembered['subject']?.toString() ?? '';
      if (rememberedShift.isNotEmpty &&
          _shifts.any((shift) => shift.id == rememberedShift)) {
        _selectedShiftId = rememberedShift;
      }
      if (rememberedSubject.isNotEmpty &&
          _subjects.contains(rememberedSubject)) {
        _selectedSubject = rememberedSubject;
      }
    }
    if (_students.isEmpty) {
      _students = <Map<String, dynamic>>[
        {'id': 'demo_1', 'name': 'احمد رضا', 'shiftId': 'morning'},
        {'id': 'demo_2', 'name': 'محمد علی', 'shiftId': 'morning'},
        {'id': 'demo_3', 'name': 'عبداللہ خان', 'shiftId': 'morning'},
        {'id': 'demo_4', 'name': 'حسن محمود', 'shiftId': 'morning'},
        {'id': 'demo_5', 'name': 'زید حسن', 'shiftId': 'morning'},
      ];
    }
    await _loadRepeatQueue(prefs);
    await _loadDayRecords(prefs);
    if (mounted) setState(() => _loading = false);
  }

  String _studentId(Map<String, dynamic> student) {
    final id = student['id']?.toString().trim() ?? '';
    if (id.isNotEmpty) return id;
    return '${student['name'] ?? ''}-${student['fatherPhone'] ?? ''}';
  }

  String _studentNameKey(Map<String, dynamic> student) =>
      (student['name'] ?? '').toString().trim().toLowerCase();

  String _studentClass(Map<String, dynamic> student) =>
      (student['className'] ?? student['class'] ?? student['group'] ?? '')
          .toString();

  TextDirection _textDirectionFor(String text) =>
      RegExp(r'[\u0600-\u06FF]').hasMatch(text)
          ? TextDirection.rtl
          : TextDirection.ltr;

  TextEditingController _controllerFor(Map<String, dynamic> student) {
    final id = _studentId(student);
    return _lessonControllers.putIfAbsent(
      id,
      () => TextEditingController(),
    );
  }

  Future<void> _loadRepeatQueue(SharedPreferences prefs) async {
    _repeatQueue.clear();
    try {
      final decoded = jsonDecode(prefs.getString(_repeatKey) ?? '{}') as Map;
      for (final entry in decoded.entries) {
        _repeatQueue[entry.key.toString()] =
            Map<String, dynamic>.from(entry.value as Map);
      }
    } catch (_) {}
  }

  Future<void> _loadDayRecords([SharedPreferences? suppliedPrefs]) async {
    final prefs = suppliedPrefs ?? await SharedPreferences.getInstance();
    _statuses.clear();
    _lessonImagePaths.clear();
    _absentStudentIds.clear();
    for (final controller in _lessonControllers.values) {
      controller.clear();
    }
    // Attendance and Lesson use the same date, shift and student id. Only
    // explicitly absent students are blocked; missing attendance data keeps
    // the existing default-present behaviour.
    try {
      final rawAttendance =
          prefs.getString('attendance_${_dateKey}_$_selectedShiftId') ??
              prefs.getString('attendance_$_dateKey');
      if (rawAttendance != null && rawAttendance.isNotEmpty) {
        final attendance = jsonDecode(rawAttendance) as Map;
        for (final entry in attendance.entries) {
          if (entry.value is! Map) continue;
          final record = Map<String, dynamic>.from(entry.value as Map);
          final status = record['attendanceStatus']?.toString();
          if (status == 'absent' || record['isPresent'] == false) {
            _absentStudentIds.add(entry.key.toString());
          }
        }
      }
    } catch (_) {}
    try {
      final decoded = jsonDecode(prefs.getString(_recordKey) ?? '{}') as Map;
      for (final student in _lessonStudents) {
        final id = _studentId(student);
        if (_absentStudentIds.contains(id)) {
          _controllerFor(student).clear();
          _statuses[id] = 'absent';
          continue;
        }
        final record = decoded[id];
        if (record is Map) {
          final map = Map<String, dynamic>.from(record);
          _controllerFor(student).text = map['lesson']?.toString() ?? '';
          _statuses[id] = map['status']?.toString() ?? '';
          final imagePath = map['imagePath']?.toString() ?? '';
          if (imagePath.isNotEmpty) _lessonImagePaths[id] = imagePath;
        }
      }
    } catch (_) {}

    for (final student in _lessonStudents) {
      final id = _studentId(student);
      if (_absentStudentIds.contains(id)) continue;
      final repeat = _repeatQueue[id];
      final controller = _controllerFor(student);
      if (controller.text.trim().isEmpty &&
          repeat != null &&
          repeat['subject'] == _selectedSubject) {
        controller.text = repeat['lesson']?.toString() ?? '';
        _statuses[id] = 'repeat';
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _saveLesson({bool showMessage = true}) async {
    final prefs = await SharedPreferences.getInstance();
    final records = <String, dynamic>{};
    try {
      final oldRecords = jsonDecode(prefs.getString(_recordKey) ?? '{}') as Map;
      for (final entry in oldRecords.entries) {
        records[entry.key.toString()] = entry.value;
      }
    } catch (_) {}
    for (final student in _lessonStudents) {
      final id = _studentId(student);
      final isAbsent = _absentStudentIds.contains(id);
      records[id] = <String, dynamic>{
        'name': student['name']?.toString() ?? '',
        'lesson': isAbsent ? '' : _controllerFor(student).text.trim(),
        'status': isAbsent ? 'absent' : (_statuses[id] ?? ''),
        'imagePath': _lessonImagePaths[id] ?? '',
        'subject': _selectedSubject,
        'date': _dateKey,
        'shiftId': _selectedShiftId,
      };
    }
    await prefs.setString(_recordKey, jsonEncode(records));
    await prefs.setString(_repeatKey, jsonEncode(_repeatQueue));
    if (showMessage && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('سبق کی تفصیل محفوظ ہوگئی۔')),
      );
    }
  }

  Future<void> _setStatus(
    Map<String, dynamic> student,
    String status,
  ) async {
    final id = _studentId(student);
    if (_absentStudentIds.contains(id)) {
      _notice('یہ طالب علم آج غیر حاضر ہے، اس پر سبق درج نہیں ہوگا۔');
      return;
    }
    final lesson = _controllerFor(student).text.trim();
    setState(() {
      _statuses[id] = status;
      if (status == 'repeat' && lesson.isNotEmpty) {
        _repeatQueue[id] = <String, dynamic>{
          'lesson': lesson,
          'subject': _selectedSubject,
          'sourceDate': _dateKey,
        };
      } else if (status == 'remembered') {
        _repeatQueue.remove(id);
      }
    });
    await _saveLesson(showMessage: false);
    if (status == 'repeat') {
      _notice('اعادہ مقرر ہوگیا: یاد نہیں بھی درج ہوا اور یہی سبق اگلے دن آجائے گا۔');
    }
  }

  Future<void> _captureLessonImage(Map<String, dynamic> student) async {
    final id = _studentId(student);
    if (_absentStudentIds.contains(id)) {
      _notice('غیر حاضر طالب علم کے لیے سبق کی تصویر شامل نہیں ہوسکتی۔');
      return;
    }
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 82,
        maxWidth: 1600,
      );
      if (image == null || !mounted) return;
      setState(() => _lessonImagePaths[id] = image.path);
      await _saveLesson(showMessage: false);
      _notice('سبق کی تصویر محفوظ ہوگئی۔');
    } catch (_) {
      _notice('کیمرہ نہیں کھل سکا۔ موبائل کی Camera permission چیک کریں۔');
    }
  }

  Future<void> _listenInto(
    TextEditingController controller, {
    String? studentId,
  }) async {
    if (studentId != null && _absentStudentIds.contains(studentId)) {
      _notice('غیر حاضر طالب علم کے لیے سبق درج نہیں ہوسکتا۔');
      return;
    }
    if (_speech.isListening) {
      await _speech.stop();
      if (mounted) {
        setState(() {
          _listeningCommon = false;
          _listeningStudentId = null;
        });
      }
      return;
    }
    try {
      final available = await _speech.initialize(
        onStatus: (status) {
          if ((status == 'done' || status == 'notListening') && mounted) {
            setState(() {
              _listeningCommon = false;
              _listeningStudentId = null;
            });
          }
        },
        onError: (errorNotification) {
          if (mounted) {
            setState(() {
              _listeningCommon = false;
              _listeningStudentId = null;
            });
            _notice('مائیک کا مسئلہ: ${errorNotification.errorMsg}۔ براہِ کرم فون کی Microphone permission آن کریں۔');
          }
        },
      );

      if (!available) {
        if (mounted) {
          _notice('مائیک شروع نہیں ہو سکا۔ فون کی سیٹنگز سے مائیک کی پرمیشن (Microphone Permission) آن کریں۔');
        }
        return;
      }

      if (!mounted) return;
      setState(() {
        _listeningCommon = studentId == null;
        _listeningStudentId = studentId;
      });

      _notice('مائیک چالو ہو گیا ہے، بولنا شروع کریں...');

      String selectedLocale = 'ur_PK';
      try {
        final systemLocales = await _speech.locales();
        for (final loc in systemLocales) {
          if (loc.localeId.toLowerCase().startsWith('ur')) {
            selectedLocale = loc.localeId;
            break;
          }
        }
      } catch (_) {}

      await _speech.listen(
        localeId: selectedLocale,
        partialResults: true,
        onResult: (result) {
          if (!mounted) return;
          final words = result.recognizedWords.trim();
          if (words.isNotEmpty) {
            controller
              ..text = words
              ..selection = TextSelection.collapsed(offset: words.length);
          }
          if (result.finalResult) {
            setState(() {
              _listeningCommon = false;
              _listeningStudentId = null;
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _listeningCommon = false;
          _listeningStudentId = null;
        });
        _notice('مائیک پرمیشن ایرر: براہِ کرم فون سیٹنگز سے ایپ کو مائیک (Microphone) کی اجازت دیں۔');
      }
    }
  }

  Future<void> _applyCommonLesson() async {
    final lesson = _commonLessonController.text.trim();
    if (lesson.isEmpty) {
      _notice('پہلے سبق، پارہ یا صفحہ درج کریں۔');
      return;
    }
    final hasExisting = _lessonStudents.any(
      (student) => !_absentStudentIds.contains(_studentId(student)) &&
          _controllerFor(student).text.trim().isNotEmpty,
    );
    bool onlyEmpty = false;
    if (hasExisting) {
      final choice = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('تمام طلبہ پر لاگو کریں'),
          content: const Text(
            'کچھ طلبہ کا سبق پہلے سے درج ہے۔ اعادہ یا الگ سبق کو محفوظ رکھنے کے لیے مناسب انتخاب کریں۔',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('منسوخ'),
            ),
            OutlinedButton(
              onPressed: () => Navigator.pop(ctx, 'empty'),
              child: const Text('صرف خالی خانوں پر'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, 'all'),
              child: const Text('تمام پر'),
            ),
          ],
        ),
      );
      if (choice == null) return;
      onlyEmpty = choice == 'empty';
    }
    setState(() {
      for (final student in _lessonStudents) {
        if (_absentStudentIds.contains(_studentId(student))) continue;
        final controller = _controllerFor(student);
        if (!onlyEmpty || controller.text.trim().isEmpty) {
          controller.text = lesson;
        }
      }
    });
    final absentCount = _lessonStudents
        .where((student) => _absentStudentIds.contains(_studentId(student)))
        .length;
    await _saveLesson(showMessage: false);
    _notice(absentCount == 0
        ? 'سبق طلبہ کی فہرست میں لاگو ہوگیا۔'
        : 'سبق حاضر طلبہ پر لاگو ہوگیا؛ $absentCount غیر حاضر طلبہ چھوڑ دیے گئے۔');
  }

  void _notice(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _editText({
    required String title,
    required String current,
    required ValueChanged<String> onSave,
    String? storageKey,
  }) async {
    final controller = TextEditingController(text: current);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          textDirection: TextDirection.rtl,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('منسوخ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('محفوظ کریں'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result == null || result.isEmpty) return;
    onSave(result);
    if (storageKey != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(storageKey, result);
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null) return;
    setState(() => _selectedDate = date);
    await _loadDayRecords();
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'remembered':
        return 'یاد ہے';
      case 'partial':
        return 'کم یاد ہے';
      case 'notRemembered':
        return 'یاد نہیں';
      case 'repeat':
        return 'یاد نہیں + اعادہ';
      case 'absent':
        return 'غیر حاضر';
      default:
        return '-';
    }
  }

  Future<Uint8List> _createPdf() async {
    final document = pw.Document();
    final regular = await PdfGoogleFonts.notoSansArabicRegular();
    final bold = await PdfGoogleFonts.notoSansArabicBold();
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: regular, bold: bold),
        margin: const pw.EdgeInsets.all(28),
        build: (_) => <pw.Widget>[
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.teal800,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(
              children: [
                pw.Text(_maktabName,
                    style: pw.TextStyle(font: bold, fontSize: 18, color: PdfColors.white)),
                pw.SizedBox(height: 3),
                pw.Text('روزانہ اسباق و تلاوت رپورٹ',
                    style: pw.TextStyle(font: bold, fontSize: 14, color: PdfColors.amber200)),
              ],
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('معلم: $_teacherName', style: pw.TextStyle(font: regular, fontSize: 10)),
              pw.Text('شفٹ: ${_selectedShift.name}', style: pw.TextStyle(font: regular, fontSize: 10)),
              pw.Text('مضمون: $_selectedSubject', style: pw.TextStyle(font: regular, fontSize: 10)),
              pw.Text('تاریخ: $_dateKey', style: pw.TextStyle(font: regular, fontSize: 10)),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.TableHelper.fromTextArray(
            headers: const ['نمبر', 'طالب علم کا نام', 'داخلہ / والد', 'سبق / تلاوت', 'کیفیت'],
            data: List<List<String>>.generate(_lessonStudents.length, (index) {
              final student = _lessonStudents[index];
              final id = _studentId(student);
              final isAbsent = _absentStudentIds.contains(id);
              final admNo = (student['admissionNo'] ?? student['rollNo'] ?? student['id'] ?? '').toString().trim();
              final fatherName = (student['fatherName'] ?? student['parentName'] ?? '').toString().trim();
              final info = [if (admNo.isNotEmpty) 'داخلہ: $admNo', if (fatherName.isNotEmpty) 'والد: $fatherName'].join('  •  ');
              final lesson = isAbsent ? 'غیر حاضر' : (_controllerFor(student).text.trim().isEmpty ? 'درج نہیں' : _controllerFor(student).text.trim());
              final status = isAbsent ? 'غیر حاضر' : _statusLabel(_statuses[id] ?? '');
              return <String>[
                '${index + 1}',
                student['name']?.toString() ?? 'طالب علم',
                info.isEmpty ? '-' : info,
                lesson,
                status,
              ];
            }),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.teal700),
            headerStyle: pw.TextStyle(font: bold, color: PdfColors.white, fontSize: 10),
            cellStyle: pw.TextStyle(font: regular, fontSize: 9.5),
            cellAlignment: pw.Alignment.centerRight,
          ),
        ],
      ),
    );
    return document.save();
  }

  Future<void> _printPdf() async {
    await _saveLesson(showMessage: false);
    final bytes = await _createPdf();
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  Future<void> _shareReport() async {
    await _saveLesson(showMessage: false);
    try {
      final bytes = await _createPdf();
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'daily_lessons_${_selectedShift.name}_$_dateKey.pdf',
      );
    } catch (e) {
      _notice('PDF شیئر کرنے میں مسئلہ آیا: $e');
    }
  }

  BoxDecoration _box({double radius = 12}) => BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1E293B)
            : const Color(0xFFF4FBF7),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: const Color(0xFF68AD91)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x17065F46),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      );

  Widget _archBox(
    String text,
    VoidCallback onTap, {
    IconData? icon,
    Widget? action,
    int flex = 1,
    bool holiday = false,
  }) => Expanded(
        flex: flex,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(9),
          child: Container(
            height: 31,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: holiday ? const Color(0xFFFFE4E6) : Colors.white70,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: holiday
                    ? const Color(0xFFD32F2F)
                    : const Color(0xFF68AD91),
                width: holiday ? 1.5 : 1,
              ),
              boxShadow: holiday
                  ? const [
                      BoxShadow(
                        color: Color(0x44D32F2F),
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon,
                      size: 14,
                      color: holiday ? const Color(0xFFD32F2F) : _green),
                  const SizedBox(width: 4),
                ],
                Flexible(
                  child: Text(
                    text,
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: holiday ? const Color(0xFFD32F2F) : null,
                    ),
                  ),
                ),
                if (action != null) ...[
                  const SizedBox(width: 3),
                  action,
                ],
              ],
            ),
          ),
        ),
      );

  Widget _identityArch() {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 108,
      width: double.infinity,
      child: CustomPaint(
        painter: _LessonArchPainter(dark: dark),
        child: Stack(
          children: [
            Positioned(
              top: 2,
              left: 4,
              child: IconButton(
                icon: const Icon(Icons.home_rounded, color: Colors.white, size: 20),
                tooltip: 'ہوم ڈیش بورڈ (Return to Home)',
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  }
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(7, 8, 7, 4),
              child: Column(
                children: [
                  SizedBox(
                    height: 28,
                    child: InkWell(
                      onTap: () => _editText(
                        title: 'مکتب کا نام',
                        current: _maktabName,
                        storageKey: 'maktab_name',
                        onSave: (value) => setState(() => _maktabName = value),
                      ),
                      child: Container(
                        width: double.infinity,
                        alignment: Alignment.center,
                        child: Transform.translate(
                          // Keep the arch itself fixed and move only the
                          // institute title slightly down into its free space.
                          offset: const Offset(0, 4),
                          child: Text(
                            _maktabName,
                            maxLines: 1,
                            overflow: TextOverflow.fade,
                            softWrap: false,
                            style: const TextStyle(
                              color: _green,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  SizedBox(
                    height: 21,
                    child: InkWell(
                      onTap: () => _editText(
                        title: 'مسجد، محلہ، گاؤں یا شہر کی تفصیل',
                        current: _maktabAddress,
                        storageKey: 'maktab_address',
                        onSave: (value) =>
                            setState(() => _maktabAddress = value),
                      ),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: double.infinity,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          _maktabAddress,
                          maxLines: 1,
                          overflow: TextOverflow.fade,
                          softWrap: false,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF334155),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Row(
                      children: [
                        _archBox(
                          _teacherName,
                          () => _editText(
                            title: 'استاد کا نام',
                            current: _teacherName,
                            storageKey: 'lesson_teacher_name',
                            onSave: (value) =>
                                setState(() => _teacherName = value),
                          ),
                          flex: 4,
                        ),
                        const SizedBox(width: 4),
                        _archBox(_dateKey, _pickDate,
                            icon: Icons.calendar_month_rounded, flex: 3),
                        const SizedBox(width: 4),
                        _archBox(
                            _holidayNotice.isEmpty
                                ? _selectedShift.name
                                : '${_selectedShift.name} • $_holidayNotice',
                            _pickShift,
                            holiday: _holidayNotice.isNotEmpty,
                            icon: Icons.schedule_rounded, flex: 2),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickShift() async {
    final selected = await showModalBottomSheet<MaktabShift>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ..._shifts.map(
                (shift) => ListTile(
                  leading: const Icon(Icons.schedule_rounded),
                  title: Text(shift.name),
                  subtitle: shift.startTime.isEmpty && shift.endTime.isEmpty
                      ? null
                      : Text('${shift.startTime} تا ${shift.endTime}'),
                  onTap: () => Navigator.pop(ctx, shift),
                ),
              ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.add_circle_rounded, color: _green),
              title: const Text('نئی شفٹ بنائیں'),
              subtitle: const Text('نام، شروع اور اختتام کا وقت منتخب کریں'),
              onTap: () async {
                Navigator.pop(ctx);
                await _createShift();
              },
            ),
          ],
        ),
      ),
    );
    if (selected == null) return;
    setState(() {
      _selectedShiftId = selected.id;
    });
    await _restoreGroupForShift(selected.id);
    await _loadDayRecords();
  }

  Future<void> _createShift() async {
    final nameController = TextEditingController();
    TimeOfDay? startTime;
    TimeOfDay? endTime;
    final created = await showDialog<MaktabShift>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, updateDialog) => AlertDialog(
          title: const Text('نئی شفٹ بنائیں'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                textDirection: TextDirection.rtl,
                decoration: const InputDecoration(
                  labelText: 'شفٹ کا نام',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.schedule_rounded),
                      label: Text(startTime == null
                          ? 'شروع کا وقت'
                          : startTime!.format(context)),
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: startTime ?? TimeOfDay.now(),
                        );
                        if (picked != null) {
                          updateDialog(() => startTime = picked);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.schedule_rounded),
                      label: Text(endTime == null
                          ? 'اختتام کا وقت'
                          : endTime!.format(context)),
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: endTime ?? startTime ?? TimeOfDay.now(),
                        );
                        if (picked != null) updateDialog(() => endTime = picked);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('منسوخ'),
            ),
            FilledButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty ||
                    startTime == null ||
                    endTime == null) {
                  _notice('شفٹ کا نام اور دونوں اوقات منتخب کریں۔');
                  return;
                }
                Navigator.pop(
                  dialogContext,
                  MaktabShift(
                    id: 'shift_${DateTime.now().microsecondsSinceEpoch}',
                    name: nameController.text.trim(),
                    startTime: startTime!.format(context),
                    endTime: endTime!.format(context),
                  ),
                );
              },
              child: const Text('محفوظ کریں'),
            ),
          ],
        ),
      ),
    );
    nameController.dispose();
    if (created == null) return;
    setState(() {
      _shifts.add(created);
      _selectedShiftId = created.id;
      _selectedGroupId = null;
    });
    await ShiftStore.save(_shifts);
    await _loadDayRecords();
    _notice('نئی شفٹ محفوظ ہوگئی۔');
  }

  Future<void> _saveGroups() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_groupsKey, jsonEncode(_groups));
  }

  Future<void> _rememberSelectedGroup() async {
    final id = _selectedGroupId;
    if (id == null || id.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedGroupKey, id);
    await prefs.setString(_selectedGroupForShiftKey(_selectedShiftId), id);
  }

  Future<void> _restoreGroupForShift(String shiftId) async {
    final prefs = await SharedPreferences.getInstance();
    final remembered = prefs.getString(_selectedGroupForShiftKey(shiftId));
    Map<String, dynamic>? group;
    for (final item in _groups) {
      if (item['id']?.toString() == remembered &&
          item['shiftId']?.toString() == shiftId) {
        group = item;
        break;
      }
    }
    if (!mounted) return;
    setState(() {
      _selectedGroupId = group?['id']?.toString();
      final subject = group?['subject']?.toString() ?? '';
      if (subject.isNotEmpty && _subjects.contains(subject)) {
        _selectedSubject = subject;
      }
    });
  }

  Future<void> _createGroup([Map<String, dynamic>? existingGroup]) async {
    if (_shiftStudents.isEmpty) {
      _notice('اس شفٹ میں گروپ بنانے کے لیے کوئی طالب علم موجود نہیں ہے۔');
      return;
    }
    final isEditing = existingGroup != null;
    final nameController = TextEditingController(
      text: existingGroup?['name']?.toString() ?? '$_selectedSubject گروپ',
    );
    final savedStudentIds = <String>{
      ...((existingGroup?['studentIds'] as List?) ?? const <dynamic>[])
          .map((item) => item.toString()),
    };
    final savedStudentNames = <String>{
      ...((existingGroup?['studentNames'] as List?) ?? const <dynamic>[])
          .map((item) => item.toString().trim().toLowerCase()),
    };
    // Restore ticks for both new groups (stable id + name backup) and
    // legacy groups whose fallback id was "name-phone".
    final selectedIds = <String>{};
    if (isEditing) {
      for (final student in _shiftStudents) {
        final id = _studentId(student);
        final nameKey = _studentNameKey(student);
        final legacyIdMatch = nameKey.isNotEmpty &&
            savedStudentIds.any((savedId) =>
                savedId.toLowerCase().startsWith('$nameKey-'));
        if (savedStudentIds.contains(id) ||
            savedStudentNames.contains(nameKey) ||
            legacyIdMatch) {
          selectedIds.add(id);
        }
      }
    }
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, updateDialog) => AlertDialog(
          title: Text(isEditing ? 'گروپ میں ترمیم کریں' : 'نیا گروپ بنائیں'),
          content: SizedBox(
            width: 430,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  textDirection: TextDirection.rtl,
                  decoration: const InputDecoration(
                    labelText: 'گروپ کا نام',
                    border: OutlineInputBorder(),
                  ),
                ),
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('تمام طلبہ منتخب کریں'),
                  value: selectedIds.length == _shiftStudents.length,
                  tristate: selectedIds.isNotEmpty &&
                      selectedIds.length != _shiftStudents.length,
                  onChanged: (value) => updateDialog(() {
                    selectedIds.clear();
                    if (value == true) {
                      selectedIds.addAll(_shiftStudents.map(_studentId));
                    }
                  }),
                ),
                SizedBox(
                  height: 260,
                  child: ListView.builder(
                    itemCount: _shiftStudents.length,
                    itemBuilder: (_, index) {
                      final student = _shiftStudents[index];
                      final id = _studentId(student);
                      return CheckboxListTile(
                        dense: true,
                        controlAffinity: ListTileControlAffinity.leading,
                        value: selectedIds.contains(id),
                        title: Text(student['name']?.toString() ?? 'بے نام'),
                        subtitle: Text([
                          if (_studentClass(student).isNotEmpty)
                            _studentClass(student),
                          if (selectedIds.contains(id)) 'پہلے سے شامل',
                        ].join(' • ')),
                        onChanged: (checked) => updateDialog(() {
                          checked == true
                              ? selectedIds.add(id)
                              : selectedIds.remove(id);
                        }),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('منسوخ'),
            ),
            FilledButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty || selectedIds.isEmpty) {
                  _notice('گروپ کا نام لکھیں اور کم از کم ایک طالب علم منتخب کریں۔');
                  return;
                }
                Navigator.pop(dialogContext, true);
              },
              child: Text(isEditing ? 'تبدیلی محفوظ کریں' : 'گروپ محفوظ کریں'),
            ),
          ],
        ),
      ),
    );
    if (saved == true) {
      // A group automatically belongs to the subject currently open on the
      // Lesson screen. No duplicate subject field is needed in this dialog.
      final groupSubject =
          existingGroup?['subject']?.toString() ?? _selectedSubject;
      final normalizedName = nameController.text.trim().toLowerCase();
      final duplicateIndex = isEditing
          ? -1
          : _groups.indexWhere((group) =>
              (group['name']?.toString().trim().toLowerCase() ?? '') ==
                  normalizedName &&
              group['subject']?.toString() == groupSubject &&
              group['shiftId']?.toString() == _selectedShiftId);
      final groupId = existingGroup?['id']?.toString() ??
          (duplicateIndex >= 0
              ? _groups[duplicateIndex]['id']?.toString()
              : null) ??
          'lesson_group_${DateTime.now().microsecondsSinceEpoch}';
      setState(() {
        if (!_subjects.contains(groupSubject)) _subjects.add(groupSubject);
        _selectedSubject = groupSubject;
        final updatedGroup = <String, dynamic>{
          'id': groupId,
          'name': nameController.text.trim(),
          'subject': groupSubject,
          'shiftId': _selectedShiftId,
          'studentIds': selectedIds.toList(),
          'studentNames': _shiftStudents
              .where((student) => selectedIds.contains(_studentId(student)))
              .map(_studentNameKey)
              .toList(),
        };
        if (isEditing || duplicateIndex >= 0) {
          final index = _groups.indexWhere(
              (group) => group['id']?.toString() == groupId);
          if (index >= 0) _groups[index] = updatedGroup;
        } else {
          _groups.add(updatedGroup);
        }
        _selectedGroupId = groupId;
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_subjectsKey, _subjects);
      await _saveGroups();
      await _rememberSelectedGroup();
      await _loadDayRecords();
      _notice(isEditing ? 'گروپ کی تبدیلی محفوظ ہوگئی۔' : 'گروپ محفوظ ہوگیا۔');
    }
    nameController.dispose();
  }

  Future<void> _deleteGroup(Map<String, dynamic> group) async {
    final name = group['name']?.toString() ?? 'گروپ';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('گروپ حذف کریں؟'),
        content: Text('کیا آپ “$name” کو حذف کرنا چاہتے ہیں؟ طلبہ حذف نہیں ہوں گے۔'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('نہیں'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('گروپ حذف کریں'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final id = group['id']?.toString();
    setState(() {
      _groups.removeWhere((item) => item['id']?.toString() == id);
      if (_selectedGroupId == id) _selectedGroupId = null;
    });
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(_selectedGroupKey) == id) {
      await prefs.remove(_selectedGroupKey);
    }
    for (final shift in _shifts) {
      final key = _selectedGroupForShiftKey(shift.id);
      if (prefs.getString(key) == id) await prefs.remove(key);
    }
    await _saveGroups();
    await _loadDayRecords();
    _notice('گروپ حذف ہوگیا، طلبہ کی اصل فہرست محفوظ ہے۔');
  }

  Future<void> _openGroup(Map<String, dynamic> group) async {
    await _saveLesson(showMessage: false);
    final subject = group['subject']?.toString() ?? _selectedSubject;
    final shiftId = group['shiftId']?.toString() ?? '';
    setState(() {
      if (_subjects.contains(subject)) _selectedSubject = subject;
      if (shiftId.isNotEmpty &&
          _shifts.any((shift) => shift.id == shiftId)) {
        _selectedShiftId = shiftId;
      }
      _selectedGroupId = group['id']?.toString();
    });
    await _rememberSelectedGroup();
    await _loadDayRecords();
  }

  Future<void> _showGroupSelector() async {
    if (_groups.isEmpty) {
      _notice('ابھی کوئی گروپ نہیں بنا۔ پہلے “گروپ بنائیں” سے گروپ بنائیں۔');
      return;
    }
    final selected = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(
              title: Text(
                'گروپ منتخب کریں',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            ..._groups.map((group) => ListTile(
                  leading: const Icon(Icons.groups_rounded, color: _green),
                  title: Text(group['name']?.toString() ?? 'گروپ'),
                  trailing: group['id']?.toString() == _selectedGroupId
                      ? const Icon(Icons.check_circle_rounded, color: _green)
                      : null,
                  onTap: () => Navigator.pop(
                      sheetContext, Map<String, dynamic>.from(group)),
                )),
          ],
        ),
      ),
    );
    if (selected != null) await _openGroup(selected);
  }

  Future<void> _showGroupMenu() async {
    if (_groups.isEmpty) {
      await _createGroup();
      return;
    }
    final action = await showModalBottomSheet<Object>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(
              title: Text('گروپ منتخب کریں',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            ..._groups.map((group) {
              final name = group['name']?.toString() ?? 'گروپ';
              final subject = group['subject']?.toString() ?? '';
              return ListTile(
                leading: const Icon(Icons.groups_rounded, color: _green),
                title: Text(name),
                subtitle: subject.isEmpty ? null : Text(subject),
                trailing: Wrap(
                  spacing: 2,
                  children: [
                    IconButton(
                      tooltip: 'طلبہ یا گروپ میں ترمیم',
                      icon: const Icon(Icons.edit_rounded, color: _green),
                      onPressed: () => Navigator.pop(sheetContext,
                          <String, dynamic>{'action': 'edit', 'group': group}),
                    ),
                    IconButton(
                      tooltip: 'گروپ حذف کریں',
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: Colors.red),
                      onPressed: () => Navigator.pop(sheetContext,
                          <String, dynamic>{'action': 'delete', 'group': group}),
                    ),
                  ],
                ),
                onTap: () => Navigator.pop(sheetContext, group),
              );
            }),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.group_add_rounded, color: _green),
              title: const Text('نیا گروپ بنائیں'),
              onTap: () => Navigator.pop(sheetContext, '__create__'),
            ),
          ],
        ),
      ),
    );
    if (action == '__create__') {
      await _createGroup();
    } else if (action is Map) {
      final map = Map<String, dynamic>.from(action);
      if (map['action'] == 'edit' && map['group'] is Map) {
        await _createGroup(Map<String, dynamic>.from(map['group'] as Map));
      } else if (map['action'] == 'delete' && map['group'] is Map) {
        await _deleteGroup(Map<String, dynamic>.from(map['group'] as Map));
      } else {
        await _openGroup(map);
      }
    }
  }

  Widget _subjectAndCommonEntry() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: _showGroupSelector,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  alignment: Alignment.center,
                  decoration: _box(),
                  child: Text(
                    _selectedGroupName == 'گروپ بنائیں'
                        ? 'گروپ / مضمون منتخب کریں'
                        : _selectedGroupName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF065F46),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            SizedBox(
              height: 44,
              child: OutlinedButton.icon(
                onPressed: _showGroupMenu,
                icon: const Icon(Icons.group_add_rounded, size: 16),
                label: const Text('گروپ بنائیں', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _green,
                  side: const BorderSide(color: Color(0xFF68AD91)),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 44,
                decoration: _box(),
                child: TextField(
                  controller: _commonLessonController,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'بول کر یا لکھ کر پارہ، صفحہ اور سبق درج کریں',
                    hintStyle: const TextStyle(fontSize: 11),
                    border: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    prefixIcon: IconButton(
                      tooltip: 'مائیک',
                      onPressed: () =>
                          _listenInto(_commonLessonController),
                      icon: Icon(
                        _listeningCommon
                            ? Icons.stop_circle_rounded
                            : Icons.mic_rounded,
                        color: _listeningCommon ? Colors.red : _green,
                        size: 19,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            SizedBox(
              height: 44,
              child: FilledButton(
                onPressed: _applyCommonLesson,
                style: FilledButton.styleFrom(
                  backgroundColor: _green,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('لاگو کریں', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _statusButton(
    Map<String, dynamic> student,
    String value,
    String label,
    Color color,
    IconData icon,
  ) {
    final currentStatus = _statuses[_studentId(student)];
    final selected = currentStatus == value ||
        (currentStatus == 'repeat' && value == 'notRemembered');

    final baseColor = color;
    final darkShadow = selected
        ? HSLColor.fromColor(color)
            .withLightness((HSLColor.fromColor(color).lightness - 0.22).clamp(0.0, 1.0))
            .toColor()
        : const Color(0xFFC0C7D0);

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 1.5),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 27,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7),
            gradient: selected
                ? LinearGradient(
                    colors: [
                      baseColor,
                      HSLColor.fromColor(baseColor)
                          .withLightness((HSLColor.fromColor(baseColor).lightness - 0.1).clamp(0.0, 1.0))
                          .toColor(),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  )
                : const LinearGradient(
                    colors: [Color(0xFFFFFFFF), Color(0xFFF1F5F9)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
            boxShadow: [
              BoxShadow(
                color: darkShadow,
                offset: const Offset(0, 2.5),
                blurRadius: 0,
              ),
              if (selected)
                BoxShadow(
                  color: baseColor.withValues(alpha: 0.35),
                  offset: const Offset(0, 4),
                  blurRadius: 4,
                ),
            ],
            border: Border.all(
              color: selected ? darkShadow : const Color(0xFFCBD5E1),
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _setStatus(student, value),
              borderRadius: BorderRadius.circular(7),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 10,
                      color: selected ? Colors.white : baseColor,
                    ),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                        softWrap: false,
                        style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.bold,
                          color: selected ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _studentCard(Map<String, dynamic> student, int index) {
    final id = _studentId(student);
    final controller = _controllerFor(student);
    final repeat = _repeatQueue[id];
    final isAbsent = _absentStudentIds.contains(id);
    return Container(
      margin: const EdgeInsets.fromLTRB(5, 2, 5, 2),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      decoration: BoxDecoration(
        color: index.isEven ? Colors.white : const Color(0xFFF7FAF9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD7E6DF)),
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 140,
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFF4FBF7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFC8E2D6)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    student['name']?.toString() ?? 'بے نام طالب علم',
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                    textAlign: TextAlign.left,
                    textDirection: _textDirectionFor(
                        student['name']?.toString() ?? ''),
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    [
                      if ((student['admissionNo'] ?? student['rollNo'] ?? student['id'] ?? '').toString().trim().isNotEmpty)
                        'داخلہ نمبر: ${(student['admissionNo'] ?? student['rollNo'] ?? student['id']).toString().trim()}',
                      if ((student['fatherName'] ?? student['parentName'] ?? '').toString().trim().isNotEmpty)
                        'والد: ${(student['fatherName'] ?? student['parentName']).toString().trim()}',
                    ].join('  •  '),
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    textAlign: TextAlign.left,
                    style: const TextStyle(fontSize: 9.5, color: _green, fontWeight: FontWeight.w600),
                  ),
                  if (repeat != null && _statuses[id] == 'repeat')
                    const Text('اعادہ: گزشتہ سبق',
                        style: TextStyle(
                            fontSize: 8.5,
                            color: Colors.deepPurple,
                            fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 38,
                      child: TextField(
                        controller: controller,
                        enabled: !isAbsent,
                        textDirection: TextDirection.rtl,
                        style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700),
                        onChanged: (_) =>
                            _saveLesson(showMessage: false),
                        decoration: InputDecoration(
                          hintText: isAbsent
                              ? 'غیر حاضر'
                              : 'پارہ، صفحہ، سبق',
                          hintStyle: TextStyle(
                            fontSize: isAbsent ? 12 : 10.5,
                            color: isAbsent ? Colors.red : null,
                            fontWeight: isAbsent
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          filled: isAbsent,
                          fillColor: isAbsent
                              ? Colors.red.withValues(alpha: .06)
                              : null,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 9),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    if (isAbsent)
                      Container(
                        height: 24,
                        width: double.infinity,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: .10),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade300),
                        ),
                        child: const Text(
                          'غیر حاضر',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else
                      Row(
                        children: [
                          _statusButton(student, 'remembered', 'یاد ہے',
                              Colors.green, Icons.check_circle_rounded),
                          _statusButton(student, 'partial', 'کم یاد',
                              Colors.orange, Icons.error_rounded),
                          _statusButton(student, 'notRemembered', 'یاد نہیں',
                              Colors.red, Icons.cancel_rounded),
                          _statusButton(student, 'repeat', 'اعادہ',
                              Colors.deepPurple, Icons.replay_rounded),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomActions() {
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _saveLesson,
              icon: const Icon(Icons.save_rounded, size: 17),
              label: const Text('محفوظ کریں'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.green,
                elevation: 6,
                shadowColor: Colors.green.shade900,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _shareReport,
              icon: const Icon(Icons.share_rounded, size: 17),
              label: const Text('رپورٹ شیئر'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.blue,
                elevation: 6,
                shadowColor: Colors.blue.shade900,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _printPdf,
              icon: const Icon(Icons.picture_as_pdf_rounded, size: 17),
              label: const Text('PDF بنائیں'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.deepPurple,
                elevation: 6,
                shadowColor: Colors.deepPurple.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _controlsToggle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 2, 6, 2),
      child: InkWell(
        onTap: () => setState(() => _controlsExpanded = !_controlsExpanded),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 27,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF8FFFB), Color(0xFFE5F4EC)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF68AD91)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33065F46),
                blurRadius: 5,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Icon(
            _controlsExpanded
                ? Icons.keyboard_arrow_up_rounded
                : Icons.keyboard_arrow_down_rounded,
            color: _green,
            size: 25,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Padding(
                    padding: EdgeInsets.only(
                      top: MediaQuery.paddingOf(context).top + 2,
                    ),
                    child: SizedBox(
                      height: 93,
                      child: OverflowBox(
                        alignment: Alignment.topCenter,
                        minHeight: 108,
                        maxHeight: 108,
                        child: Transform.translate(
                          offset: const Offset(0, -15),
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 7),
                            child: _identityArch(),
                          ),
                        ),
                      ),
                    ),
                  ),
                  _controlsToggle(),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: _controlsExpanded
                        ? Padding(
                            key: const ValueKey('lesson_controls_open'),
                            padding: const EdgeInsets.fromLTRB(6, 4, 6, 3),
                            child: _subjectAndCommonEntry(),
                          )
                        : const SizedBox.shrink(
                            key: ValueKey('lesson_controls_closed'),
                          ),
                  ),
                  Expanded(
                    child: _lessonStudents.isEmpty
                        ? Center(
                            child: Text(
                              _selectedGroupId == null
                                  ? 'سبق سنانے کے لیے پہلے “گروپ بنائیں” سے گروپ منتخب کریں۔'
                                  : 'اس گروپ میں کوئی طالب علم منتخب نہیں ہے۔',
                              textAlign: TextAlign.center,
                            ),
                          )
                        : ListView.builder(
                            padding: EdgeInsets.zero,
                            itemCount: _lessonStudents.length,
                            itemBuilder: (_, index) =>
                                _studentCard(_lessonStudents[index], index),
                          ),
                  ),
                ],
              ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.fromLTRB(4, 1, 4, 1),
          child: _bottomActions(),
        ),
      ),
    );
  }
}
