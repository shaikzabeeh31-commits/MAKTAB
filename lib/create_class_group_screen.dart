import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_localizations.dart';
import 'shift_manager.dart';

class CreateClassGroupScreen extends StatefulWidget {
  final List<Map<String, dynamic>> students;
  final LanguageController languageController;
  final Future<void> Function(List<Map<String, dynamic>> updatedStudents) onSave;
  final String maktabId;
  final Future<void> Function()? onAddStudent;

  const CreateClassGroupScreen({
    super.key,
    required this.students,
    required this.languageController,
    required this.onSave,
    this.maktabId = 'legacy_maktab',
    this.onAddStudent,
  });

  @override
  State<CreateClassGroupScreen> createState() =>
      _CreateClassGroupScreenState();
}

class _CreateClassGroupScreenState extends State<CreateClassGroupScreen> {
  String get _classesKey => 'maktab_classes_v2_${widget.maktabId}';
  String get _holidayKey => 'maktab_holiday_v1_${widget.maktabId}';

  final _maktabName = TextEditingController();
  final _maktabSectionName = TextEditingController();
  final _teacherName = TextEditingController();
  final _holidayReason = TextEditingController();
  final _search = TextEditingController();
  final Set<String> _selectedIds = {};
  final Set<int> _days = {1, 2, 3, 4, 5, 6};

  List<Map<String, dynamic>> _classes = [];
  String? _classId;
  String _shiftId = 'morning';
  List<MaktabShift> _shifts = ShiftStore.defaults;
  String _filter = 'all';
  String _query = '';
  TimeOfDay _start = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 8, minute: 0);
  bool _holidayEnabled = false;
  bool _studentStep = false;
  int? _weeklyHolidayDay;
  bool _loading = true;
  int _idSequence = 0;

  String get _selectedClassName {
    final matches = _classes.where((item) => item['id']?.toString() == _classId);
    return matches.isEmpty ? 'کلاس منتخب نہیں' : matches.first['name'].toString();
  }

  String get _selectedShiftName {
    final matches = _shifts.where((shift) => shift.id == _shiftId);
    return matches.isEmpty ? 'شفٹ منتخب نہیں' : matches.first.name;
  }

  void _openStudentStep() {
    if (_maktabName.text.trim().isEmpty) {
      _message('ادارے یا مدرسے کا مکمل عنوان درج کریں۔', error: true);
      return;
    }
    if (_maktabSectionName.text.trim().isEmpty) {
      _message('مکتب کا نام درج کریں۔', error: true);
      return;
    }
    if (_classId == null) {
      _message('کلاس منتخب کریں۔', error: true);
      return;
    }
    if (_teacherName.text.trim().isEmpty) {
      _message('استاد کا نام درج کریں۔', error: true);
      return;
    }
    if (_days.isEmpty) {
      _message('کم از کم ایک دن منتخب کریں۔', error: true);
      return;
    }
    setState(() => _studentStep = true);
  }

  static const _dayNames = {
    1: 'پیر',
    2: 'منگل',
    3: 'بدھ',
    4: 'جمعرات',
    5: 'جمعہ',
    6: 'ہفتہ',
    7: 'اتوار',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _maktabName.dispose();
    _maktabSectionName.dispose();
    _teacherName.dispose();
    _holidayReason.dispose();
    _search.dispose();
    super.dispose();
  }

  String _id(String prefix) {
    _idSequence++;
    return '${prefix}_${DateTime.now().microsecondsSinceEpoch}_$_idSequence';
  }

  String _studentId(Map<String, dynamic> student) {
    final id = student['id']?.toString().trim() ?? '';
    if (id.isNotEmpty) return id;
    return '${student['name'] ?? ''}|${student['fatherPhone'] ?? ''}';
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _shifts = await ShiftStore.load();
    if (_shifts.every((shift) => shift.id != _shiftId)) {
      _shiftId = _shifts.first.id;
    }
    try {
      final classData = prefs.getString(_classesKey);
      List<Map<String, dynamic>> profiles = <Map<String, dynamic>>[];
      final profilesRaw = prefs.getString('maktab_profiles_v1');
      if (profilesRaw != null) {
        profiles = (jsonDecode(profilesRaw) as List)
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
      }
      final matches = profiles
          .where((item) => item['id']?.toString() == widget.maktabId)
          .toList();
      final profile = matches.isEmpty ? <String, dynamic>{} : matches.first;
      _maktabName.text = profile['name']?.toString() ?? '';
      _maktabSectionName.text =
          profile['sectionName']?.toString() ?? 'مکتب اطفال';
      _teacherName.text = profile['teacherName']?.toString() ?? '';
      if (classData != null) {
        _classes = (jsonDecode(classData) as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
      // Repair IDs written by older versions where multiple rapidly-created
      // dropdown items could accidentally receive the same value.
      final seenClassIds = <String>{};
      for (final item in _classes) {
        final oldId = item['id']?.toString() ?? '';
        if (oldId.isEmpty || !seenClassIds.add(oldId)) {
          final newId = _id('class');
          item['id'] = newId;
          seenClassIds.add(newId);
        }
      }
      final holidayRaw = prefs.getString(_holidayKey);
      if (holidayRaw != null) {
        final holiday = Map<String, dynamic>.from(jsonDecode(holidayRaw) as Map);
        _holidayEnabled = holiday['enabled'] == true;
        _holidayReason.text = holiday['reason']?.toString() ?? '';
        _weeklyHolidayDay = holiday['weeklyDay'] as int?;
      }
    } catch (_) {
      _classes = [];
    }
    if (_classes.isEmpty) {
      _classes = ['قاعدہ', 'ناظرہ', 'حفظ', 'تجوید']
          .map<Map<String, dynamic>>((name) => <String, dynamic>{'id': _id('class'), 'name': name, 'archived': false})
          .toList();
      await _saveDefinitions();
    } else {
      await _saveDefinitions();
    }
    for (final item in _classes) {
      if (item['archived'] != true) {
        _classId = item['id'].toString();
        break;
      }
    }
    _loadClassSelection();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _saveDefinitions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_classesKey, jsonEncode(_classes));
  }

  Future<String?> _askName(String title, {String initial = ''}) async {
    final controller = TextEditingController(text: initial);
    final value = await showDialog<String>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'نام درج کریں',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('منسوخ'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    return value;
  }

  Future<void> _addClass() async {
    final name = await _askName('نئی کلاس بنائیں');
    if (name == null || name.isEmpty) return;
    if (_classes.any((e) => e['name'] == name && e['archived'] != true)) {
      _message('یہ کلاس پہلے سے موجود ہے۔', error: true);
      return;
    }
    final item = {'id': _id('class'), 'name': name, 'archived': false};
    setState(() {
      _classes.add(item);
      _classId = item['id'].toString();
      _selectedIds.clear();
    });
    await _saveDefinitions();
  }

  List<Map<String, dynamic>> _memberships(Map<String, dynamic> student) {
    return (student['groupMemberships'] as List?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        [];
  }

  bool _assignedInCurrentClassShift(Map<String, dynamic> student) {
    if (_classId == null) return false;
    final matches = _classes
        .where((item) => item['id']?.toString() == _classId)
        .toList();
    final className =
        matches.isEmpty ? '' : matches.first['name']?.toString() ?? '';
    if ((student['className'] ?? student['class'])?.toString() == className) {
      return true;
    }
    return _memberships(student).any((e) =>
        e['classId'] == _classId &&
        (e['shiftId'] ?? ShiftStore.legacyId(e['shift']?.toString() ?? '')) ==
            _shiftId &&
        e['active'] != false);
  }

  List<Map<String, dynamic>> get _maktabStudents => widget.students.where((student) {
        final ownerId = student['maktabId']?.toString();
        return ownerId == null ||
            ownerId.isEmpty ||
            ownerId == widget.maktabId;
      }).toList();

  List<Map<String, dynamic>> get _visibleStudents {
    final q = _query.trim().toLowerCase();
    return _maktabStudents.where((student) {
      final id = _studentId(student);
      final assigned = _assignedInCurrentClassShift(student);
      final text = '${student['name'] ?? ''} ${student['fatherName'] ?? ''} '
              '${student['fatherPhone'] ?? ''}'
          .toLowerCase();
      if (!text.contains(q)) return false;
      if (_filter == 'remaining') return !assigned;
      if (_filter == 'selected') return _selectedIds.contains(id);
      if (_filter == 'assigned') return assigned;
      return true;
    }).toList();
  }

  String _membershipText(Map<String, dynamic> student) {
    final active = _memberships(student).where((e) => e['active'] != false);
    if (active.isEmpty) return 'ابھی کسی کلاس میں شامل نہیں';
    return active
        .map((e) => '${e['shiftName'] ?? e['shift']}: ${e['className']}')
        .join(' | ');
  }

  Future<void> _pickTime(bool start) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: start ? _start : _end,
    );
    if (picked == null) return;
    setState(() => start ? _start = picked : _end = picked);
  }

  String _time(TimeOfDay value) =>
      '${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}';

  void _loadClassSelection() {
    _selectedIds.clear();
    if (_classId == null) return;
    final matches = _classes
        .where((item) => item['id']?.toString() == _classId)
        .toList();
    if (matches.isEmpty) return;
    final className = matches.first['name']?.toString() ?? '';
    if (className.isEmpty) return;
    for (final student in widget.students) {
      final ownerId = student['maktabId']?.toString();
      if (ownerId != null &&
          ownerId.isNotEmpty &&
          ownerId != widget.maktabId) {
        continue;
      }
      final direct = (student['className'] ?? student['class'])?.toString();
      final membership = _memberships(student).any((item) =>
          item['active'] != false &&
          (item['classId']?.toString() == _classId ||
              item['className']?.toString() == className));
      if (direct == className || membership) {
        _selectedIds.add(_studentId(student));
      }
    }
  }

  Future<void> _deleteCurrentClass() async {
    if (_classId == null) return;
    final current = _classes.firstWhere((e) => e['id'].toString() == _classId);
    final className = current['name']?.toString() ?? '';
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('کلاس حذف کریں؟'),
        content: Text('$className کی طلبہ سے وابستگی بھی ختم ہوجائے گی۔'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('نہیں')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('ہاں')),
        ],
      ),
    );
    if (yes != true) return;
    final updated = widget.students.map((source) {
      final student = Map<String, dynamic>.from(source);
      final ownerId = student['maktabId']?.toString();
      if (ownerId != null &&
          ownerId.isNotEmpty &&
          ownerId != widget.maktabId) {
        return student;
      }
      if ((student['className'] ?? student['class'])?.toString() == className) {
        student.remove('className');
        student.remove('class');
      }
      final memberships = _memberships(student);
      for (final item in memberships) {
        if (item['classId']?.toString() == _classId ||
            item['className']?.toString() == className) {
          item['active'] = false;
        }
      }
      student['groupMemberships'] = memberships;
      return student;
    }).toList();
    setState(() {
      current['archived'] = true;
      final remaining = _classes.where((e) => e['archived'] != true).toList();
      _classId = remaining.isEmpty ? null : remaining.first['id'].toString();
      _loadClassSelection();
    });
    await _saveDefinitions();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('maktab_classes_v2', jsonEncode(_classes));
    if (prefs.getString('current_class_name') == className) {
      if (_classId == null) {
        await prefs.remove('current_class_name');
      } else {
        final replacement = _classes
            .firstWhere((item) => item['id']?.toString() == _classId);
        await prefs.setString(
            'current_class_name', replacement['name']?.toString() ?? '');
      }
    }
    await widget.onSave(updated);
  }

  Future<void> _saveClass() async {
    if (_classId == null) {
      _message('کلاس منتخب کریں۔', error: true);
      return;
    }
    if (_selectedIds.isEmpty) {
      _message('کم از کم ایک طالب علم منتخب کریں۔', error: true);
      return;
    }
    if (_days.isEmpty) {
      _message('کم از کم ایک دن منتخب کریں۔', error: true);
      return;
    }

    final className = _classes
        .firstWhere((e) => e['id'] == _classId)['name']
        .toString();
    final currentClass = _classes.firstWhere((e) => e['id'] == _classId);
    currentClass['teacherName'] = _teacherName.text.trim();
    currentClass['shiftId'] = _shiftId;
    currentClass['shiftName'] = _shifts.firstWhere((s) => s.id == _shiftId).name;
    currentClass['startTime'] = _time(_start);
    currentClass['endTime'] = _time(_end);
    currentClass['days'] = _days.toList()..sort();
    currentClass['studentIds'] = _selectedIds.toList();
    currentClass['updatedAt'] = DateTime.now().toIso8601String();

    final updated = widget.students.map((source) {
      final student = Map<String, dynamic>.from(source);
      final ownerId = student['maktabId']?.toString();
      if (ownerId != null &&
          ownerId.isNotEmpty &&
          ownerId != widget.maktabId) {
        return student;
      }
      final selected = _selectedIds.contains(_studentId(student));
      final oldClass = (student['className'] ?? student['class'])?.toString();
      if (!selected && oldClass == className) {
        student.remove('className');
        student.remove('class');
      }
      final memberships = _memberships(student);
      if (!selected) {
        // Keep legacy students attached to this Maktab even when they are not
        // selected for the current class. This prevents them disappearing
        // from Student/Attendance/Fee lists after setup.
        if (ownerId == null || ownerId.isEmpty) {
          student['maktabId'] = widget.maktabId;
        }
        for (final item in memberships) {
          if (item['classId']?.toString() == _classId ||
              item['className']?.toString() == className) {
            item['active'] = false;
          }
        }
        student['groupMemberships'] = memberships;
        return student;
      }
      memberships.removeWhere((e) =>
          e['classId']?.toString() == _classId && e['source'] == 'class_setup');
      memberships.add({
        'id': _id('membership'),
        'classId': _classId,
        'className': className,
        'shiftId': _shiftId,
        'shiftName': _shifts.firstWhere((s) => s.id == _shiftId).name,
        'teacherName': _teacherName.text.trim(),
        'source': 'class_setup',
        'active': true,
      });
      student['groupMemberships'] = memberships;
      student['maktabId'] = widget.maktabId;
      student['className'] = className;
      final shiftIds = ShiftStore.studentShiftIds(student)..add(_shiftId);
      student['shiftIds'] = shiftIds.toList();
      student['shifts'] = shiftIds.toList();
      student['shiftId'] = _shiftId;
      student['shift'] =
          _shifts.firstWhere((shift) => shift.id == _shiftId).name;
      student['teacherName'] = _teacherName.text.trim();
      return student;
    }).toList();

    await _saveDefinitions();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('maktab_setup_complete', true);
    await prefs.setBool('post_setup_open_attendance', true);
    await prefs.setString('maktab_classes_v2', jsonEncode(_classes));
    await prefs.setString('active_maktab_id', widget.maktabId);
    await prefs.remove('pending_maktab_id');
    List<Map<String, dynamic>> profiles = <Map<String, dynamic>>[];
    try {
      final raw = prefs.getString('maktab_profiles_v1');
      if (raw != null) {
        profiles = (jsonDecode(raw) as List)
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
      }
    } catch (_) {}
    profiles.removeWhere((item) => item['id']?.toString() == widget.maktabId);
    profiles.add({
      'id': widget.maktabId,
      'name': _maktabName.text.trim(),
      'sectionName': _maktabSectionName.text.trim(),
      'teacherName': _teacherName.text.trim(),
      'currentClassName': className,
      'updatedAt': DateTime.now().toIso8601String(),
    });
    await prefs.setString('maktab_profiles_v1', jsonEncode(profiles));
    await prefs.setString('current_class_name', className);
    await prefs.setString('maktab_name', _maktabName.text.trim());
    await prefs.setString(
        'maktab_section_name', _maktabSectionName.text.trim());
    await prefs.setString('shared_teacher_name', _teacherName.text.trim());
    await prefs.setString('lesson_teacher_name', _teacherName.text.trim());
    for (final shift in _shifts) {
      await prefs.setString('attendance_class_heading_${shift.id}',
          _maktabSectionName.text.trim());
      await prefs.setString(
          'attendance_teacher_heading_${shift.id}', _teacherName.text.trim());
    }
    await prefs.setString(
      _holidayKey,
      jsonEncode({
        'enabled': _holidayEnabled,
        'reason': _holidayReason.text.trim(),
        'weeklyDay': _weeklyHolidayDay,
        'updatedAt': DateTime.now().toIso8601String(),
      }),
    );
    await prefs.setString(
      'maktab_holiday_v1',
      jsonEncode({
        'enabled': _holidayEnabled,
        'reason': _holidayReason.text.trim(),
        'weeklyDay': _weeklyHolidayDay,
        'updatedAt': DateTime.now().toIso8601String(),
      }),
    );
    await widget.onSave(updated);
    if (context.mounted) {
      _message('$className محفوظ ہوگئی؛ طلبہ: ${_selectedIds.length}');
      Navigator.of(context).pop(true);
    }
  }

  void _message(String text, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(text),
      backgroundColor: error ? Colors.red.shade700 : Colors.green.shade700,
    ));
  }

  static const _green = Color(0xFF08734B);
  static const _darkGreen = Color(0xFF045C3B);
  static const _gold = Color(0xFFD6A52D);
  static const _cream = Color(0xFFFFFDF8);

  InputDecoration _input(String label, IconData icon) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF52635B)),
        prefixIcon: Icon(icon, color: _green),
        filled: true,
        fillColor: const Color(0xFFFCFDFB),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFFB8D8C9), width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: _green, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFFD8DED9)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7F5),
        appBar: AppBar(
          elevation: 6,
          shadowColor: Colors.black38,
          centerTitle: true,
          title: Text(_studentStep ? 'طلبہ شامل کریں' : 'مکتب شامل کریں',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 24)),
          backgroundColor: _darkGreen,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.home_rounded, color: Colors.white),
              tooltip: 'ہوم ڈیش بورڈ (Return to Home)',
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.popUntil(context, (route) => route.isFirst);
                }
              },
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 28),
          children: [
            _progressStrip(),
            const SizedBox(height: 16),
            if (!_studentStep) ...[
            _sectionCard(
              number: '1',
              title: 'ادارے کا نام شامل کریں',
              icon: Icons.account_balance_rounded,
              child: Column(children: [
                TextField(
                  controller: _maktabName,
                  decoration: _input('ادارے / مدرسے کا مکمل عنوان',
                      Icons.location_on_rounded),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _maktabSectionName,
                  decoration: _input('مکتب کا نام، مثلاً مکتب اطفال',
                      Icons.menu_book_rounded),
                ),
              ]),
            ),
            _sectionCard(
              number: '2',
              title: 'کلاس منتخب کریں',
              icon: Icons.school_rounded,
              child: Column(children: [
                DropdownButtonFormField<String>(
                  initialValue: _classId,
                  decoration: _input('کلاس', Icons.school_rounded),
                  items: _classes
                      .where((e) => e['archived'] != true)
                      .map((e) => DropdownMenuItem(
                            value: e['id'].toString(),
                            child: Text(e['name'].toString()),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() {
                    _classId = value;
                    _loadClassSelection();
                  }),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: _raisedAction(
                      label: 'نئی کلاس',
                      icon: Icons.add_circle_rounded,
                      color: _green,
                      onPressed: _addClass,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _raisedAction(
                      label: 'حذف کریں',
                      icon: Icons.delete_rounded,
                      color: const Color(0xFFC83B3B),
                      outlined: true,
                      onPressed: _deleteCurrentClass,
                    ),
                  ),
                ]),
              ]),
            ),
            _sectionCard(
              number: '3',
              title: 'استاد کا نام',
              icon: Icons.person_rounded,
              child: TextField(
                controller: _teacherName,
                decoration: _input('استاد کا نام درج کریں', Icons.person_rounded),
              ),
            ),
            _sectionCard(
              number: '4',
              title: 'شفٹ، وقت اور ہفتے کے دن',
              icon: Icons.schedule_rounded,
              child: Column(children: [
                Row(children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _shiftId,
                      decoration: _input('شفٹ', Icons.schedule_rounded),
                      items: _shifts
                          .map((shift) => DropdownMenuItem(
                                value: shift.id,
                                child: Text(shift.name),
                              ))
                          .toList(),
                      onChanged: (value) => setState(() {
                        _shiftId = value!;
                        _selectedIds.clear();
                      }),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _squareButton(
                    tooltip: 'شفٹیں بنائیں یا تبدیل کریں',
                    icon: Icons.edit_calendar_rounded,
                    onPressed: () async {
                      await showShiftManager(context);
                      final loaded = await ShiftStore.load();
                      if (!mounted) return;
                      setState(() {
                        _shifts = loaded;
                        if (_shifts.every((shift) => shift.id != _shiftId)) {
                          _shiftId = _shifts.first.id;
                        }
                      });
                    },
                  ),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _timeButton('شروع', _start, () => _pickTime(true))),
                  const SizedBox(width: 10),
                  Expanded(child: _timeButton('اختتام', _end, () => _pickTime(false))),
                ]),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: _dayNames.entries.map((entry) => FilterChip(
                        label: Text(entry.value,
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                        selected: _days.contains(entry.key),
                        selectedColor: _green,
                        checkmarkColor: Colors.white,
                        labelStyle: TextStyle(
                          color: _days.contains(entry.key)
                              ? Colors.white
                              : const Color(0xFF34463D),
                        ),
                        elevation: _days.contains(entry.key) ? 4 : 1,
                        onSelected: (yes) => setState(() => yes
                            ? _days.add(entry.key)
                            : _days.remove(entry.key)),
                      )).toList(),
                ),
              ]),
            ),
            _sectionCard(
              number: '5',
              title: 'چھٹی کا اعلان',
              icon: Icons.event_busy_rounded,
              child: Column(children: [
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  activeColor: _green,
                  value: _holidayEnabled,
                  onChanged: (value) =>
                      setState(() => _holidayEnabled = value),
                  title: Text(
                    _holidayEnabled ? 'آج چھٹی ہے' : 'آج چھٹی نہیں ہے',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: _holidayEnabled
                          ? const Color(0xFFB3261E)
                          : _darkGreen,
                    ),
                  ),
                  subtitle: const Text(
                      'یہ اطلاع حاضری، سبق اور فیس کی اسکرین پر دکھائی جائے گی'),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: _holidayEnabled
                      ? const EdgeInsets.all(12)
                      : EdgeInsets.zero,
                  decoration: BoxDecoration(
                    color: _holidayEnabled
                        ? const Color(0xFFFFF3F2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    border: _holidayEnabled
                        ? Border.all(color: const Color(0xFFF1B8B4))
                        : null,
                  ),
                  child: _holidayEnabled
                      ? Column(children: [
                          TextField(
                            controller: _holidayReason,
                            decoration: _input(
                                'چھٹی کی وجہ لکھیں', Icons.edit_rounded),
                          ),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<int?>(
                            initialValue: _weeklyHolidayDay,
                            decoration: _input('ہفتہ وار چھٹی کا دن',
                                Icons.event_busy_rounded),
                            items: <DropdownMenuItem<int?>>[
                              const DropdownMenuItem<int?>(
                                  value: null,
                                  child: Text('کوئی مقرر دن نہیں')),
                              ..._dayNames.entries.map((entry) =>
                                  DropdownMenuItem<int?>(
                                    value: entry.key,
                                    child: Text(entry.value),
                                  )),
                            ],
                            onChanged: (value) =>
                                setState(() => _weeklyHolidayDay = value),
                          ),
                        ])
                      : const SizedBox.shrink(),
                ),
              ]),
            ),
            _raisedAction(
              label: 'آگے بڑھیں',
              icon: Icons.arrow_back_rounded,
              color: _green,
              height: 58,
              onPressed: _openStudentStep,
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text('مرحلہ 1 از 2',
                  style: TextStyle(
                      color: _darkGreen, fontWeight: FontWeight.w700)),
            ),
            ],
            if (_studentStep) ...[
            _studentSummaryCard(),
            const SizedBox(height: 4),
            _sectionCard(
              number: '6',
              title: 'نیا داخلہ اور طلبہ منتخب کریں',
              icon: Icons.groups_rounded,
              child: Column(children: [
                if (widget.onAddStudent != null) ...[
                  _raisedAction(
                    label: 'نیا داخلہ شامل کریں',
                    icon: Icons.person_add_alt_1_rounded,
                    color: _green,
                    outlined: true,
                    onPressed: () async {
                      final beforeIds = widget.students
                          .map(_studentId)
                          .toSet();
                      await widget.onAddStudent!();
                      if (!mounted) return;
                      setState(() {
                        // Newly admitted students should immediately appear
                        // and be selected for this class, otherwise the user
                        // can save a student but still see an empty selection.
                        for (final student in widget.students) {
                          final id = _studentId(student);
                          if (!beforeIds.contains(id)) {
                            _selectedIds.add(id);
                          }
                        }
                        _filter = 'all';
                        _query = '';
                        _search.clear();
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: _search,
                  onChanged: (value) => setState(() => _query = value),
                  decoration: _input(
                      'طالب علم، والد یا فون تلاش کریں', Icons.search_rounded),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    _filterChip('تمام', 'all'),
                    _filterChip('باقی', 'remaining'),
                    _filterChip('منتخب', 'selected'),
                    _filterChip('پہلے سے شامل', 'assigned'),
                  ],
                ),
                const SizedBox(height: 4),
                Row(children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () => setState(() => _selectedIds
                        ..clear()
                        ..addAll(_visibleStudents.map(_studentId))),
                      icon: const Icon(Icons.select_all_rounded),
                      label: const Text('تمام ظاہر طلبہ منتخب کریں'),
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(_selectedIds.clear),
                    child: const Text('انتخاب ختم کریں'),
                  ),
                ]),
              ]),
            ),
            ..._visibleStudents.map((student) {
              final id = _studentId(student);
              final selected = _selectedIds.contains(id);
              return Card(
                elevation: 2,
                shadowColor: Colors.black26,
                color: selected ? const Color(0xFFEAF7F0) : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: selected
                        ? _green
                        : const Color(0xFFD8E5DE),
                  ),
                ),
                child: CheckboxListTile(
                  value: selected,
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: (yes) => setState(() => yes == true
                      ? _selectedIds.add(id)
                      : _selectedIds.remove(id)),
                  title: Text(
                    student['name']?.toString() ?? 'طالب علم',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'والد: ${student['fatherName'] ?? '-'}\n'
                    '${_membershipText(student)}',
                  ),
                  secondary: _assignedInCurrentClassShift(student)
                      ? const Icon(Icons.groups, color: Colors.blue)
                      : const Icon(Icons.person_outline, color: Colors.grey),
                ),
              );
            }),
            if (_visibleStudents.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('اس Filter میں کوئی طالب علم نہیں ہے۔')),
              ),
            const SizedBox(height: 18),
            _raisedAction(
              label: 'مکتب مکمل کریں اور محفوظ کریں',
              icon: Icons.save_as_rounded,
              color: _green,
              height: 58,
              onPressed: _saveClass,
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text('محفوظ کرتے ہی حاضری کی اسکرین کھل جائے گی',
                  style: TextStyle(color: Color(0xFF607168))),
            ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _progressStrip() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(color: Color(0x24000000), blurRadius: 12, offset: Offset(0, 5)),
          ],
        ),
        child: Row(
          children: List.generate(5, (index) {
            final active = _studentStep ? index == 4 : index == 0;
            final complete = _studentStep && index < 4;
            return Expanded(
              child: Row(children: [
                if (index > 0)
                  const Expanded(child: Divider(color: Color(0xFFC9D4CE))),
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (active || complete)
                        ? _green
                        : const Color(0xFFF6F6F3),
                    border: Border.all(
                        color: active ? _gold : const Color(0xFFCCD6D0),
                        width: active ? 2 : 1),
                    boxShadow: active
                        ? const [BoxShadow(color: Color(0x44000000), blurRadius: 5, offset: Offset(0, 3))]
                        : null,
                  ),
                  child: complete
                      ? const Icon(Icons.check_rounded,
                          color: Colors.white, size: 20)
                      : Text('${index + 1}',
                          style: TextStyle(
                              color: active ? Colors.white : _darkGreen,
                              fontWeight: FontWeight.bold)),
                ),
              ]),
            );
          }),
        ),
      );

  Widget _studentSummaryCard() => Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _cream,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFC7D9CF)),
          boxShadow: const [
            BoxShadow(
                color: Color(0x26000000),
                blurRadius: 13,
                offset: Offset(0, 6)),
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Row(children: [
            Icon(Icons.account_balance_rounded, color: _gold, size: 27),
            SizedBox(width: 9),
            Text('منتخب مکتب',
                style: TextStyle(
                    color: _darkGreen,
                    fontSize: 21,
                    fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 13),
          _summaryLine(Icons.menu_book_rounded,
              _maktabSectionName.text.trim()),
          const SizedBox(height: 8),
          _summaryLine(Icons.school_rounded, 'کلاس: $_selectedClassName'),
          const SizedBox(height: 8),
          _summaryLine(Icons.schedule_rounded,
              'شفٹ: $_selectedShiftName  ${_time(_start)} تا ${_time(_end)}'),
          const SizedBox(height: 12),
          _raisedAction(
            label: 'ترمیم کریں',
            icon: Icons.edit_rounded,
            color: _green,
            outlined: true,
            onPressed: () => setState(() => _studentStep = false),
          ),
        ]),
      );

  Widget _summaryLine(IconData icon, String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: const Color(0xFFD3E1DA)),
          boxShadow: const [
            BoxShadow(
                color: Color(0x18000000),
                blurRadius: 5,
                offset: Offset(0, 3)),
          ],
        ),
        child: Row(children: [
          Icon(icon, color: _green),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ]),
      );

  Widget _sectionCard({
    required String number,
    required String title,
    required IconData icon,
    required Widget child,
  }) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
        decoration: BoxDecoration(
          color: _cream,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFC7D9CF)),
          boxShadow: const [
            BoxShadow(color: Color(0x26000000), blurRadius: 13, offset: Offset(0, 6)),
            BoxShadow(color: Colors.white, blurRadius: 2, offset: Offset(0, -1)),
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _darkGreen,
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [
                  BoxShadow(color: Color(0x33000000), blurRadius: 5, offset: Offset(0, 3)),
                ],
              ),
              child: Text(number,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 10),
            Icon(icon, color: _gold, size: 25),
            const SizedBox(width: 8),
            Expanded(
              child: Text(title,
                  style: const TextStyle(
                      color: _darkGreen, fontSize: 20, fontWeight: FontWeight.w800)),
            ),
          ]),
          const SizedBox(height: 14),
          child,
        ]),
      );

  Widget _raisedAction({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    bool outlined = false,
    double height = 50,
  }) => SizedBox(
        width: double.infinity,
        height: height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(color: Color(0x38000000), blurRadius: 7, offset: Offset(0, 4)),
            ],
          ),
          child: outlined
              ? OutlinedButton.icon(
                  onPressed: onPressed,
                  icon: Icon(icon),
                  label: Text(label,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: color,
                    backgroundColor: Colors.white,
                    side: BorderSide(color: color, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                )
              : FilledButton.icon(
                  onPressed: onPressed,
                  icon: Icon(icon),
                  label: Text(label,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  style: FilledButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
        ),
      );

  Widget _squareButton({
    required String tooltip,
    required IconData icon,
    required VoidCallback onPressed,
  }) => Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: _green,
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 6, offset: Offset(0, 4))],
        ),
        child: IconButton(
          tooltip: tooltip,
          onPressed: onPressed,
          color: Colors.white,
          icon: Icon(icon),
        ),
      );

  Widget _filterChip(String label, String value) => ChoiceChip(
        label: Text(label),
        selected: _filter == value,
        selectedColor: _green,
        checkmarkColor: Colors.white,
        labelStyle: TextStyle(
          color: _filter == value ? Colors.white : _darkGreen,
          fontWeight: FontWeight.w700,
        ),
        onSelected: (_) => setState(() => _filter = value),
      );

  Widget _timeButton(String label, TimeOfDay value, VoidCallback onTap) =>
      OutlinedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.access_time_rounded),
        label: Text('$label: ${_time(value)}',
            style: const TextStyle(fontWeight: FontWeight.w800)),
        style: OutlinedButton.styleFrom(
          foregroundColor: _green,
          backgroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
          side: const BorderSide(color: Color(0xFF9CC7B2), width: 1.3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 2,
        ),
      );
}
