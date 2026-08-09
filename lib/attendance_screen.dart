import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_localizations.dart';
import 'theme_controller.dart';
import 'role_selection_screen.dart';

class AttendanceScreen extends StatefulWidget {
  final List<Map<String, dynamic>> students;
  final LanguageController languageController;
  final ThemeController? themeController;
  final Function(List<Map<String, dynamic>> updatedStudents)? onSave;
  final AppRole? currentRole;

  const AttendanceScreen({
    super.key,
    required this.students,
    required this.languageController,
    this.themeController,
    this.onSave,
    this.currentRole,
  });

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  late List<Map<String, dynamic>> _students;
  DateTime _selectedDate = DateTime.now();
  DateTimeRange? _selectedDateRange;
  String _selectedClassFilter = 'All';
  final List<String> _batchesList = ['All', 'Class 7 (A)', 'Class 6 (B)', 'Morning Hifz Batch', 'Nazira Batch A'];
  String _selectedShiftSlot = 'morning';
  final Set<int> _selectedIndices = {};

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
            const Icon(Icons.group_add_rounded, color: Colors.indigo),
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
            style: FilledButton.styleFrom(backgroundColor: Colors.indigo),
            onPressed: () {
              final name = ctrl.text.trim();
              if (name.isNotEmpty) {
                setState(() {
                  if (!_batchesList.contains(name)) {
                    _batchesList.add(name);
                  }
                  _selectedClassFilter = name;
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

  void _editShiftSlotDialog() {
    final loc = AppLocalizations.of(context);
    final isEn = loc.locale.languageCode == 'en';
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
                const Icon(Icons.access_time_filled_rounded, color: Colors.indigo),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isEn ? 'Edit Attendance Shift & Slot' : 'حاضری کی شفٹ و سلاٹ منتخب کریں',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _selectedShiftSlot,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: isEn ? 'Select Shift / Slot' : 'شفٹ / مارننگ سلاٹ',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(value: 'morning', child: Text(isEn ? 'Morning Shift (صبح کی شفٹ)' : 'صبح کی شفٹ (Morning)')),
                    DropdownMenuItem(value: 'morning_slot_1', child: Text(isEn ? 'Morning Slot 1 (7:00 AM - 9:00 AM)' : 'مارننگ سلاٹ 1 (7:00 تا 9:00 AM)')),
                    DropdownMenuItem(value: 'morning_slot_2', child: Text(isEn ? 'Morning Slot 2 (9:00 AM - 11:00 AM)' : 'مارننگ سلاٹ 2 (9:00 تا 11:00 AM)')),
                    DropdownMenuItem(value: 'evening', child: Text(isEn ? 'Evening Shift (شام کی شفٹ)' : 'شام کی شفٹ (Evening)')),
                    DropdownMenuItem(value: 'night', child: Text(isEn ? 'Night Shift (رات کی شفٹ)' : 'رات کی شفٹ (Night)')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() {
                        _selectedShiftSlot = val;
                      });
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isEn ? 'Cancel' : 'منسوخ')),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Colors.indigo),
                onPressed: () {
                  setState(() {
                    for (var s in _students) {
                      s['shift'] = _selectedShiftSlot;
                    }
                  });
                  _saveData();
                  Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isEn ? 'Attendance shift slot updated successfully!' : 'حاضری کی شفٹ سلاٹ کامیابی سے تبدیل ہو گئی!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                child: Text(isEn ? 'Apply Slot' : 'لاگو کریں'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _students = widget.students.map((s) {
      final copy = Map<String, dynamic>.from(s);
      copy['attendance'] ??= 'present';
      copy['hasCap'] ??= true;
      copy['hasUniform'] ??= true;
      copy['hasBooks'] ??= true;
      copy['language'] ??= 'ur'; 
      return copy;
    }).toList();
    _loadSavedBatches();
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

  void _saveData() {
    if (widget.onSave != null) {
      widget.onSave!(_students);
    }
  }

  bool get _isTeacher =>
      widget.currentRole == null ||
      widget.currentRole == AppRole.teacher ||
      widget.currentRole == AppRole.admin ||
      widget.currentRole == AppRole.manager;

  List<Map<String, dynamic>> get _filteredStudents {
    if (_selectedClassFilter == 'All') {
      return _students;
    }
    return _students.where((s) => s['className'] == _selectedClassFilter).toList();
  }

  Future<void> _selectPeriod() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
      initialDateRange: _selectedDateRange ?? DateTimeRange(
        start: _selectedDate.subtract(const Duration(days: 3)),
        end: _selectedDate,
      ),
    );
    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
        _selectedDate = picked.start;
      });
    }
  }

  void _toggleSelection(int index, bool? selected) {
    if (!_isTeacher) return;
    setState(() {
      if (selected == true) {
        _selectedIndices.add(index);
      } else {
        _selectedIndices.remove(index);
      }
    });
  }

  void _markAttendance(int index, String status) {
    if (!_isTeacher) return;
    setState(() {
      _students[index]['attendance'] = status;
    });
    _saveData();
  }



  Future<void> _launchUrl(String urlString) async {
    final url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch app'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ignore: unused_element
  void _makePhoneCall(String phone) {
    if (phone.isEmpty) return;
    _launchUrl('tel:$phone');
  }

  // ignore: unused_element
  void _showBulkMessageDialog({Set<int>? indices}) {
    final targetIndices = indices ?? _selectedIndices;
    if (targetIndices.isEmpty) return;

    String selectedReason = 'absent';
    final customMsgController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 20, right: 20, top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Send Message to ${targetIndices.length} Student(s)', 
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Messages will automatically be sent using each parent\'s preferred language and channel (SMS/WhatsApp).',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 16),
              const Text('Reason:', style: TextStyle(fontWeight: FontWeight.bold)),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Absent (غیر حاضر)'),
                    selected: selectedReason == 'absent',
                    onSelected: (v) => setSheetState(() => selectedReason = 'absent'),
                  ),
                  ChoiceChip(
                    label: const Text('Late (دیر سے)'),
                    selected: selectedReason == 'late',
                    onSelected: (v) => setSheetState(() => selectedReason = 'late'),
                  ),
                  ChoiceChip(
                    label: const Text('Cap Issue (ٹوپی کی کمی)'),
                    selected: selectedReason == 'cap',
                    onSelected: (v) => setSheetState(() => selectedReason = 'cap'),
                  ),
                  ChoiceChip(
                    label: const Text('Uniform Issue (یونیفارم کی کمی)'),
                    selected: selectedReason == 'uniform',
                    onSelected: (v) => setSheetState(() => selectedReason = 'uniform'),
                  ),
                  ChoiceChip(
                    label: const Text('Books Issue (کتابوں کی کمی)'),
                    selected: selectedReason == 'books',
                    onSelected: (v) => setSheetState(() => selectedReason = 'books'),
                  ),
                  ChoiceChip(
                    label: const Text('Custom'),
                    selected: selectedReason == 'custom',
                    onSelected: (v) => setSheetState(() => selectedReason = 'custom'),
                  ),
                ],
              ),
              if (selectedReason == 'custom') ...[
                const SizedBox(height: 12),
                TextField(
                  controller: customMsgController,
                  decoration: const InputDecoration(
                    labelText: 'Custom Message',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _executeBulkMessage(targetIndices, selectedReason, customMsgController.text);
                  },
                  icon: const Icon(Icons.send_rounded),
                  label: const Text('Send Automatically'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _executeBulkMessage(Set<int> indices, String reason, String customMsg) async {
    for (int idx in indices) {
      final student = _students[idx];
      final phone = student['fatherPhone']?.toString() ?? '';
      if (phone.isEmpty) continue;

      // Determine language and generate personalized message
      final lang = student['language']?.toString() ?? 'ur';
      String message = '';
      final studentName = student['name'] ?? 'Student';

      if (reason == 'absent') {
        if (lang == 'ur') {
          message = 'السلام علیکم، مکتب کی اطلاع: $studentName آج مدرسے سے غیر حاضر ہے۔';
        } else if (lang == 'en') {
          message = 'Assalamu Alaikum. $studentName is absent from Madrasa today.';
        } else if (lang == 'te') {
          message = 'అస్సలాము అలైకుమ్. ఈరోజు $studentName మదర్సాకు హాజరు కాలేదు.';
        } else {
          message = 'Assalamu Alaikum. $studentName is absent from Madrasa today.';
        }
      } else if (reason == 'late') {
        if (lang == 'ur') {
          message = 'السلام علیکم، مکتب کی اطلاع: $studentName آج مدرسے دیر سے پہنچا ہے۔';
        } else if (lang == 'en') {
          message = 'Assalamu Alaikum. $studentName arrived late to Madrasa today.';
        } else if (lang == 'te') {
          message = 'అస్సలాము అలైకుమ్. $studentName ఈరోజు మదర్సాకు ఆలస్యంగా వచ్చారు.';
        } else {
          message = 'Assalamu Alaikum. $studentName arrived late to Madrasa today.';
        }
      } else if (reason == 'cap') {
        if (lang == 'ur') {
          message = 'السلام علیکم، مکتب کی اطلاع: براہ کرم $studentName کی ٹوپی کا خیال رکھیں۔';
        } else if (lang == 'en') {
          message = 'Assalamu Alaikum. Please ensure $studentName comes with a proper cap.';
        } else if (lang == 'te') {
          message = 'అస్సలాము అలైకుమ్. దయచేసి $studentName సరైన టోపీతో వస్తున్నారని నిర్ధారించుకోండి.';
        } else {
          message = 'Assalamu Alaikum. Please ensure $studentName comes with a proper cap.';
        }
      } else if (reason == 'uniform') {
        if (lang == 'ur') {
          message = 'السلام علیکم، مکتب کی اطلاع: براہ کرم $studentName کے لباس/یونیفارم کا خیال رکھیں۔';
        } else if (lang == 'en') {
          message = 'Assalamu Alaikum. Please ensure $studentName comes in proper uniform.';
        } else if (lang == 'te') {
          message = 'అస్సలాము అలైకుమ్. దయచేసి $studentName సరైన యూనిఫామ్‌తో వస్తున్నారని నిర్ధారించుకోండి.';
        } else {
          message = 'Assalamu Alaikum. Please ensure $studentName comes in proper uniform.';
        }
      } else if (reason == 'books') {
        if (lang == 'ur') {
          message = 'السلام علیکم، مکتب کی اطلاع: براہ کرم $studentName کی کتابوں کا خیال رکھیں۔';
        } else if (lang == 'en') {
          message = 'Assalamu Alaikum. Please ensure $studentName brings their books.';
        } else if (lang == 'te') {
          message = 'అస్సలాము అలైకుమ్. దయచేసి $studentName సరైన పుస్తకాలతో వస్తున్నారని నిర్ధారించుకోండి.';
        } else {
          message = 'Assalamu Alaikum. Please ensure $studentName brings their books.';
        }
      } else {
        message = customMsg;
      }

      final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
      final preferredMode = student['messageMethod']?.toString().toLowerCase() ?? 'whatsapp';
      
      if (preferredMode == 'whatsapp') {
        await _launchUrl('whatsapp://send?phone=$cleanPhone&text=${Uri.encodeComponent(message)}');
        await Future.delayed(const Duration(seconds: 1));
      } else if (preferredMode == 'sms') {
        await _launchUrl('sms:$cleanPhone?body=${Uri.encodeComponent(message)}');
        await Future.delayed(const Duration(seconds: 1));
      } else {
        // App Notification stub
        debugPrint('App Notification to $cleanPhone: $message');
      }
    }

    setState(() {
      _selectedIndices.clear();
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Messages sent successfully!'), backgroundColor: Colors.green),
      );
    }
  }

  void _sendReportToAdmin(int present, int absent, int lateCount, List<String> absentNames, List<String> lateNames) async {
    final prefs = await SharedPreferences.getInstance();
    final String teacherName = prefs.getString('cred_teacher_name') ?? 'Teacher (استاد)';
    
    final String dateStr = '${_selectedDate.day}-${_selectedDate.month}-${_selectedDate.year}';
    
    final StringBuffer report = StringBuffer();
    report.writeln('*مدرسہ خیر العلوم اشرفیہ - حاضری رپورٹ*');
    report.writeln('📅 تاریخ: $dateStr');
    report.writeln('👨‍🏫 استاد: $teacherName');
    report.writeln('');
    report.writeln('📊 *تفصیلات:*');
    report.writeln('کل طلبہ: ${present + absent + lateCount}');
    report.writeln('✅ حاضر: $present');
    report.writeln('❌ غیر حاضر: $absent ${absent > 0 ? "\\n( ${absentNames.join(', ')} )" : ""}');
    report.writeln('⏰ دیر سے آئے: $lateCount ${lateCount > 0 ? "\\n( ${lateNames.join(', ')} )" : ""}');
    report.writeln('');
    report.writeln('(Generated via Maktab App)');
    
    // Save locally for Results screen to see
    _saveTeacherReportLocally(
      teacherName: teacherName,
      group: 'All Groups',
      dateStr: dateStr,
      present: present,
      absent: absent,
      lateCount: lateCount,
      absentNames: absentNames,
      lateNames: lateNames,
    );

    // Inject directly into Community Chat
    final msgStr = prefs.getString('community_chat_messages_v1');
    List<dynamic> communityMessages = [];
    if (msgStr != null && msgStr.isNotEmpty) {
      communityMessages = jsonDecode(msgStr);
    }
    
    final now = DateTime.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}';
    
    final chatMsg = {
      'id': 'm_${DateTime.now().millisecondsSinceEpoch}',
      'senderId': 'teacher_${DateTime.now().millisecondsSinceEpoch}',
      'senderName': teacherName,
      'senderRole': 'teacher',
      'text': report.toString(),
      'timestamp': timeStr,
      'isMe': true,
      'isRead': true,
      'attachmentType': 'none'
    };
    
    communityMessages.add(chatMsg);
    await prefs.setString('community_chat_messages_v1', jsonEncode(communityMessages));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report successfully sent to Community Chat!'), backgroundColor: Colors.green),
      );
    }
  }

  Future<void> _saveTeacherReportLocally({
    required String teacherName,
    required String group,
    required String dateStr,
    required int present,
    required int absent,
    required int lateCount,
    required List<String> absentNames,
    required List<String> lateNames,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? existingStr = prefs.getString('teacher_reports');
      List<dynamic> existingReports = [];
      if (existingStr != null) {
        existingReports = jsonDecode(existingStr) as List<dynamic>;
      }

      final reportData = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'date': dateStr,
        'dateTime': DateTime.now().toIso8601String(),
        'senderName': teacherName,
        'group': group,
        'type': 'attendance',
        'details': {
          'present': present,
          'absent': absent,
          'late': lateCount,
          'absentNames': absentNames,
          'lateNames': lateNames,
        }
      };

      existingReports.add(reportData);
      await prefs.setString('teacher_reports', jsonEncode(existingReports));
    } catch (e) {
      debugPrint('Failed to save teacher report locally: $e');
    }
  }

  void _showNotificationsDialog() {
    final loc = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(loc.translate('notifications_center'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: Text(loc.translate('prev_attendance_saved'), style: const TextStyle()),
            ),
            ListTile(
              leading: const Icon(Icons.message, color: Colors.blue),
              title: Text(loc.translate('new_admin_msg'), style: const TextStyle()),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    int presentCount = 0;
    int absentCount = 0;
    int lateCount = 0;
    final List<String> absentNames = [];
    final List<String> lateNames = [];
    for (var s in _students) {
      final name = s['name']?.toString() ?? 'Unknown';
      if (s['attendance'] == 'present') {
        presentCount++;
      } else if (s['attendance'] == 'absent') {
        absentCount++;
        absentNames.add(name);
      } else if (s['attendance'] == 'late') {
        lateCount++;
        lateNames.add(name);
      }
    }

    // ignore: unused_local_variable
    final String selectedCountText = _selectedIndices.isEmpty ? '' : 'منتخب طلبہ\n${_selectedIndices.length}';

    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
            title: const SizedBox.shrink(),
            centerTitle: true,
            backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
            foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              if (_isTeacher)
                IconButton(
                  icon: const Icon(Icons.share, color: Colors.greenAccent, size: 20),
                  tooltip: 'Send Report to Admin',
                  onPressed: () => _sendReportToAdmin(presentCount, absentCount, lateCount, absentNames, lateNames),
                ),
              Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(icon: const Icon(Icons.notifications_none, size: 20), onPressed: _showNotificationsDialog),
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      child: const Text('5', style: TextStyle(fontSize: 10, color: Colors.white)),
                    ),
                  ),
                ],
              )
            ],
          ),
        body: Column(
          children: [
            Container(
              color: Theme.of(context).appBarTheme.backgroundColor ?? (isDark ? const Color(0xFF0F172A) : const Color(0xFF074E32)),
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.calendar_month_rounded, size: 14, color: Colors.indigo),
                    label: Text(
                      _selectedDateRange == null
                          ? '${_selectedDate.day}-${_selectedDate.month}-${_selectedDate.year}'
                          : '${_selectedDateRange!.start.day}/${_selectedDateRange!.start.month} - ${_selectedDateRange!.end.day}/${_selectedDateRange!.end.month}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    onPressed: _selectPeriod,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: DropdownButton<String>(
                      value: _batchesList.contains(_selectedClassFilter) ? _selectedClassFilter : 'All',
                      underline: const SizedBox(),
                      icon: const Icon(Icons.arrow_drop_down, size: 16),
                      style: TextStyle(fontSize: 11, color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
                      onChanged: (val) {
                        if (val == '__add_new__') {
                          _showAddBatchDialog();
                        } else if (val != null) {
                          setState(() {
                            _selectedClassFilter = val;
                          });
                        }
                      },
                      items: [
                        ..._batchesList.map((c) => DropdownMenuItem(value: c, child: Text(c))),
                        DropdownMenuItem(
                          value: '__add_new__',
                          child: Row(
                            children: [
                              const Icon(Icons.add, size: 14, color: Colors.indigo),
                              const SizedBox(width: 4),
                              Text(loc.locale.languageCode == 'en' ? '+ Add Batch' : '+ نیا بیچ بنائیں', style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.access_time_filled, size: 14, color: Colors.indigo),
                    label: Text(
                      _selectedShiftSlot == 'morning_slot_1'
                          ? (loc.locale.languageCode == 'en' ? 'Morning Slot 1' : 'مارننگ سلاٹ 1')
                          : (_selectedShiftSlot == 'morning_slot_2'
                              ? (loc.locale.languageCode == 'en' ? 'Morning Slot 2' : 'مارننگ سلاٹ 2')
                              : (_selectedShiftSlot == 'evening'
                                  ? (loc.locale.languageCode == 'en' ? 'Evening' : 'شام')
                                  : (_selectedShiftSlot == 'night'
                                      ? (loc.locale.languageCode == 'en' ? 'Night' : 'رات')
                                      : (loc.locale.languageCode == 'en' ? 'Morning' : 'صبح')))),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    onPressed: _editShiftSlotDialog,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.green.shade700,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${loc.translate('present')}: $presentCount',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 11),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.red.shade700,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${loc.translate('absent')}: $absentCount',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 11),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade800,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${loc.translate('late')}: $lateCount',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 11),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.indigo,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${loc.translate('total_students')}: ${_filteredStudents.length}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFF074E32),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(loc.translate('student_attendance_list'), style: TextStyle(color: isDark ? Colors.white70 : Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  const Icon(Icons.people, color: Colors.white, size: 18),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: 580,
                  child: Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
                        child: Row(
                          children: [
                            SizedBox(
                              width: 40,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (_isTeacher)
                                    Checkbox(
                                      value: _selectedIndices.length == _students.length && _students.isNotEmpty,
                                      onChanged: (v) {
                                        setState(() {
                                          if (v == true) {
                                            for (int i = 0; i < _students.length; i++) {
                                              _selectedIndices.add(i);
                                            }
                                          } else {
                                            _selectedIndices.clear();
                                          }
                                        });
                                      },
                                      visualDensity: VisualDensity.compact,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                    ),
                                  Text(loc.translate('select'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 3, 
                              child: Text(
                                loc.translate('cap_uniform_books'), 
                                textAlign: TextAlign.center, 
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Expanded(
                              flex: 2, 
                              child: Text(
                                loc.translate('late_arrival'), 
                                textAlign: TextAlign.center, 
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Expanded(
                              flex: 2, 
                              child: Text(
                                loc.translate('attendance_tap'), 
                                textAlign: TextAlign.center, 
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Expanded(
                              flex: 3, 
                              child: Text(
                                loc.translate('student_father_header'), 
                                textAlign: TextAlign.start, 
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _filteredStudents.length,
                          itemBuilder: (ctx, index) {
                            final student = _filteredStudents[index];
                            final originalIndex = _students.indexOf(student);
                            final status = student['attendance'] as String? ?? 'present';
                            final isSelected = _selectedIndices.contains(originalIndex);
                            final isEn = widget.languageController.locale.languageCode == 'en';
                            
                            final hasCap = student['hasCap'] as bool? ?? true;
                            final hasUniform = student['hasUniform'] as bool? ?? true;
                            final hasBooks = student['hasBooks'] as bool? ?? true;

                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? (index.isEven ? Theme.of(context).cardTheme.color : Theme.of(context).cardTheme.color?.withValues(alpha: 0.8))
                                    : (index.isEven ? Colors.white : Colors.grey.shade50),
                                border: Border(bottom: BorderSide(color: isDark ? const Color(0xFF334155) : Colors.grey.shade300)),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 0),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 40,
                                    child: _isTeacher ? Checkbox(
                                      value: isSelected,
                                      onChanged: (v) => _toggleSelection(originalIndex, v),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                    ) : const SizedBox(),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        GestureDetector(
                                          onTap: _isTeacher ? () {
                                            setState(() {
                                              _students[originalIndex]['hasBooks'] = !hasBooks;
                                            });
                                            _saveData();
                                          } : null,
                                          child: _buildItemIcon(Icons.menu_book_rounded, hasBooks, isEn ? 'Books' : 'کتابیں'),
                                        ),
                                        GestureDetector(
                                          onTap: _isTeacher ? () {
                                            setState(() {
                                              _students[originalIndex]['hasUniform'] = !hasUniform;
                                            });
                                            _saveData();
                                          } : null,
                                          child: _buildItemIcon(Icons.checkroom, hasUniform, isEn ? 'Uniform' : 'جبہ شریف'),
                                        ),
                                        GestureDetector(
                                          onTap: _isTeacher ? () {
                                            setState(() {
                                              _students[originalIndex]['hasCap'] = !hasCap;
                                            });
                                            _saveData();
                                          } : null,
                                          child: _buildItemIcon(Icons.school, hasCap, isEn ? 'Cap' : 'ٹوپی'),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Present Button
                                  Expanded(
                                    flex: 2,
                                    child: InkWell(
                                      onTap: _isTeacher ? () => _markAttendance(originalIndex, 'present') : null,
                                      child: Container(
                                        height: 32,
                                        margin: const EdgeInsets.symmetric(horizontal: 2),
                                        decoration: BoxDecoration(
                                          color: status == 'present' ? Colors.green.shade600 : (isDark ? const Color(0xFF1E293B) : Colors.grey.shade100),
                                          border: Border.all(color: status == 'present' ? Colors.green.shade700 : (isDark ? const Color(0xFF334155) : Colors.grey.shade300)),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.check_circle_rounded, size: 13, color: status == 'present' ? Colors.white : Colors.green),
                                            const SizedBox(width: 2),
                                            Flexible(
                                              child: Text(
                                                loc.translate('present'),
                                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: status == 'present' ? Colors.white : (isDark ? Colors.white70 : Colors.black87)),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Late Button
                                  Expanded(
                                    flex: 2,
                                    child: InkWell(
                                      onTap: _isTeacher ? () => _markAttendance(originalIndex, 'late') : null,
                                      child: Container(
                                        height: 32,
                                        margin: const EdgeInsets.symmetric(horizontal: 2),
                                        decoration: BoxDecoration(
                                          color: status == 'late' ? Colors.amber.shade700 : (isDark ? const Color(0xFF1E293B) : Colors.grey.shade100),
                                          border: Border.all(color: status == 'late' ? Colors.amber.shade800 : (isDark ? const Color(0xFF334155) : Colors.grey.shade300)),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.access_time_filled_rounded, size: 13, color: status == 'late' ? Colors.white : Colors.amber.shade800),
                                            const SizedBox(width: 2),
                                            Flexible(
                                              child: Text(
                                                loc.translate('late'),
                                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: status == 'late' ? Colors.white : (isDark ? Colors.white70 : Colors.black87)),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Absent Button
                                  Expanded(
                                    flex: 2,
                                    child: InkWell(
                                      onTap: _isTeacher ? () => _markAttendance(originalIndex, 'absent') : null,
                                      child: Container(
                                        height: 32,
                                        margin: const EdgeInsets.symmetric(horizontal: 2),
                                        decoration: BoxDecoration(
                                          color: status == 'absent' ? Colors.red.shade600 : (isDark ? const Color(0xFF1E293B) : Colors.grey.shade100),
                                          border: Border.all(color: status == 'absent' ? Colors.red.shade700 : (isDark ? const Color(0xFF334155) : Colors.grey.shade300)),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.cancel_rounded, size: 13, color: status == 'absent' ? Colors.white : Colors.red),
                                            const SizedBox(width: 2),
                                            Flexible(
                                              child: Text(
                                                loc.translate('absent'),
                                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: status == 'absent' ? Colors.white : (isDark ? Colors.white70 : Colors.black87)),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 4.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: TranslatedText(student['name'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isDark ? Colors.white : Colors.black87)),
                                              ),
                                              Text(' (${student['rollNo'] ?? student['roll_no'] ?? ''})', style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.grey)),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              TranslatedText('والد: ', style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.grey)),
                                              Expanded(
                                                child: TranslatedText(student['fatherName'] ?? '', style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.grey)),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 40,
                                    child: IconButton(
                                      icon: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(color: Colors.green.shade700, borderRadius: BorderRadius.circular(4)),
                                        child: const Icon(Icons.call, color: Colors.white, size: 16),
                                      ),
                                      onPressed: () {},
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
              ),
            ),
          ],
        ),
        bottomNavigationBar: _selectedIndices.isNotEmpty
            ? Container(
                color: const Color(0xFF0F766E),
                child: SafeArea(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.send, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      const Text(
                        'منتخب طلبہ کو پیغام بھیجیں',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '(ان کے والدین کو خودکار پیغام جائے گا)',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              )
            : const SizedBox(),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildTopBlock(String title, String subtitle, IconData icon, bool hasEdit) {
    final isDk = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isDk ? const Color(0xFF1E293B) : Colors.white,
          border: Border.all(color: isDk ? const Color(0xFF334155) : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 14, color: Colors.indigo),
                const SizedBox(width: 4),
                Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 4),
            Text(subtitle, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: isDk ? Colors.white70 : Colors.black87)),
            if (hasEdit) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(border: Border.all(color: isDk ? const Color(0xFF334155) : Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.edit, size: 10, color: Colors.indigo),
                    SizedBox(width: 2),
                    Text('تبدیل کریں', style: TextStyle(fontSize: 8)),
                  ],
                ),
              )
            ]
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildCounterBlock(String title, String count, MaterialColor color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.shade50,
          border: Border.all(color: color.shade200),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: TextStyle(fontSize: 12, color: color.shade700, fontWeight: FontWeight.bold)),
                const SizedBox(width: 4),
                Icon(icon, size: 14, color: color.shade700),
              ],
            ),
            const SizedBox(height: 4),
            Text(count, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildItemIcon(IconData icon, bool isOk, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Tooltip(
      message: label,
      child: Container(
        padding: const EdgeInsets.all(3.5),
        decoration: BoxDecoration(
          color: isOk
              ? Colors.green.withValues(alpha: isDark ? 0.18 : 0.08)
              : Colors.red.withValues(alpha: isDark ? 0.18 : 0.08),
          shape: BoxShape.circle,
          border: Border.all(
            color: isOk
                ? Colors.green.withValues(alpha: 0.3)
                : Colors.red.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          size: 13.5,
          color: isOk ? Colors.green : Colors.red,
        ),
      ),
    );
  }
}
