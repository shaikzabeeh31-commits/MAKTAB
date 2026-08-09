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
  final DateTime _selectedDate = DateTime.now();
  final Set<int> _selectedIndices = {};

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

  void _makePhoneCall(String phone) {
    if (phone.isEmpty) return;
    _launchUrl('tel:$phone');
  }

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
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('نوٹیفکیشنز (Notifications)', style: TextStyle(fontFamily: 'Jameel Noori Nastaleeq', fontSize: 20, fontWeight: FontWeight.bold)),
            const Divider(),
            ListTile(leading: const Icon(Icons.check_circle, color: Colors.green), title: const Text('پچھلی حاضری کامیابی سے محفوظ ہو گئی۔', style: TextStyle(fontFamily: 'Jameel Noori Nastaleeq'))),
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

    final String selectedCountText = _selectedIndices.isEmpty ? '' : 'منتخب طلبہ\n${_selectedIndices.length}';

    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Column(
            children: [
              Text(loc.translate('madrasa_title'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              Text(loc.translate('mark_attendance'), style: const TextStyle(color: Colors.amberAccent, fontSize: 14)),
            ],
          ),
          centerTitle: true,
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            if (_isTeacher)
              IconButton(
                icon: const Icon(Icons.share, color: Colors.greenAccent),
                tooltip: 'Send Report to Admin',
                onPressed: () => _sendReportToAdmin(presentCount, absentCount, lateCount, absentNames, lateNames),
              ),
            Stack(
              alignment: Alignment.center,
              children: [
                IconButton(icon: const Icon(Icons.notifications_none), onPressed: _showNotificationsDialog),
                Positioned(
                  right: 8, top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    child: const Text('5', style: TextStyle(fontSize: 10, color: Colors.white)),
                  ),
                )
              ],
            )
          ],
        ),
        body: Column(
          children: [
            // Top 4 blocks
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  _buildTopBlock('تاریخ', '${_selectedDate.day}-${_selectedDate.month}-${_selectedDate.year}', Icons.calendar_month, true),
                  const SizedBox(width: 4),
                  _buildTopBlock('وقت', '09:15 AM\nصبح', Icons.access_time, false),
                  const SizedBox(width: 4),
                  _buildTopBlock('دن', 'ہفتہ\n${_selectedDate.day}-${_selectedDate.month}-${_selectedDate.year}', Icons.calendar_today, false),
                  const SizedBox(width: 4),
                  _buildTopBlock('شفٹ\nصبح', 'تبدیل کریں', Icons.people_alt, true),
                ],
              ),
            ),
            // Counters
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  _buildCounterBlock('کل طلبہ', _students.length.toString(), Colors.blue, Icons.people),
                  const SizedBox(width: 4),
                  _buildCounterBlock('حاضر', presentCount.toString(), Colors.green, Icons.check_circle),
                  const SizedBox(width: 4),
                  _buildCounterBlock('غیر حاضر', absentCount.toString(), Colors.red, Icons.cancel),
                  const SizedBox(width: 4),
                  _buildCounterBlock('دیر سے آئے', lateCount.toString(), Colors.orange, Icons.access_time_filled),
                ],
              ),
            ),
            // Quick Actions Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.beach_access_rounded, size: 14, color: Colors.orange),
                      label: const Text('Bulk Holiday', style: TextStyle(fontSize: 10)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        elevation: 1,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        side: BorderSide(color: Colors.grey.shade200),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                    const SizedBox(width: 6),
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.bar_chart_rounded, size: 14, color: Colors.blue),
                      label: const Text('Ratio / Analytics', style: TextStyle(fontSize: 10)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        elevation: 1,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        side: BorderSide(color: Colors.grey.shade200),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                    const SizedBox(width: 6),
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.mark_email_unread_rounded, size: 14, color: Colors.purple),
                      label: const Text('Parent Leave', style: TextStyle(fontSize: 10)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        elevation: 1,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        side: BorderSide(color: Colors.grey.shade200),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                    const SizedBox(width: 6),
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.picture_as_pdf_rounded, size: 14, color: Colors.red),
                      label: const Text('Matrix PDF', style: TextStyle(fontSize: 10)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        elevation: 1,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        side: BorderSide(color: Colors.grey.shade200),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Header
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('طلبہ کی حاضری لسٹ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  SizedBox(width: 8),
                  Icon(Icons.people, color: Colors.white, size: 18),
                ],
              ),
            ),
            // Table Header
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
                        color: Colors.grey.shade100,
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
                                  const Text('منتخب', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            const Expanded(
                              flex: 3, 
                              child: TranslatedText(
                                'ٹوپی / یونیفارم / کتابیں', 
                                textAlign: TextAlign.center, 
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const Expanded(
                              flex: 2, 
                              child: TranslatedText(
                                'دیر سے آیا', 
                                textAlign: TextAlign.center, 
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const Expanded(
                              flex: 2, 
                              child: TranslatedText(
                                'حاضری\n(کلک کریں)', 
                                textAlign: TextAlign.center, 
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const Expanded(
                              flex: 3, 
                              child: TranslatedText(
                                'طالب علم کا نام\nوالد کا نام', 
                                textAlign: TextAlign.start, 
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 40),
                          ],
                        ),
                      ),
                      // Table List
                      Expanded(
                        child: ListView.builder(
                          itemCount: _students.length,
                          itemBuilder: (ctx, index) {
                            final student = _students[index];
                            final status = student['attendance'] as String? ?? 'present';
                            final isSelected = _selectedIndices.contains(index);
                            final isEn = widget.languageController.locale.languageCode == 'en';
                            
                            final hasCap = student['hasCap'] as bool? ?? true;
                            final hasUniform = student['hasUniform'] as bool? ?? true;
                            final hasBooks = student['hasBooks'] as bool? ?? true;

                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? (index.isEven ? Theme.of(context).cardTheme.color : Theme.of(context).cardTheme.color?.withValues(alpha: 0.8))
                                    : (index.isEven ? Colors.white : Colors.grey.shade50),
                                border: Border(bottom: BorderSide(color: isDark ? const Color(0xFF334155) : Colors.grey.shade300)),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 40,
                                    child: _isTeacher ? Checkbox(
                                      value: isSelected,
                                      onChanged: (v) => _toggleSelection(index, v),
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
                                              student['hasBooks'] = !hasBooks;
                                            });
                                            _saveData();
                                          } : null,
                                          child: _buildItemIcon(Icons.menu_book_rounded, hasBooks, isEn ? 'Books' : 'کتابیں'),
                                        ),
                                        GestureDetector(
                                          onTap: _isTeacher ? () {
                                            setState(() {
                                              student['hasUniform'] = !hasUniform;
                                            });
                                            _saveData();
                                          } : null,
                                          child: _buildItemIcon(Icons.checkroom, hasUniform, isEn ? 'Uniform' : 'جبہ شریف'),
                                        ),
                                        GestureDetector(
                                          onTap: _isTeacher ? () {
                                            setState(() {
                                              student['hasCap'] = !hasCap;
                                            });
                                            _saveData();
                                          } : null,
                                          child: _buildItemIcon(Icons.school, hasCap, isEn ? 'Cap' : 'ٹوپی'),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: InkWell(
                                      onTap: _isTeacher ? () => _markAttendance(index, status == 'late' ? 'present' : 'late') : null,
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(horizontal: 4),
                                        padding: const EdgeInsets.symmetric(vertical: 4),
                                        decoration: BoxDecoration(
                                          color: status == 'late' ? Colors.orange.shade50.withValues(alpha: isDark ? 0.15 : 1) : Colors.transparent,
                                          border: Border.all(color: status == 'late' ? Colors.orange : (isDark ? const Color(0xFF334155) : Colors.grey.shade300)),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Column(
                                          children: [
                                            Icon(Icons.access_time, size: 13.5, color: status == 'late' ? Colors.orange : Colors.grey),
                                            TranslatedText('دیر سے آیا', style: TextStyle(fontSize: 7.5, color: status == 'late' ? Colors.orange : Colors.grey)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: InkWell(
                                      onTap: _isTeacher ? () => _markAttendance(index, status == 'absent' ? 'present' : 'absent') : null,
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(horizontal: 4),
                                        padding: const EdgeInsets.symmetric(vertical: 4),
                                        decoration: BoxDecoration(
                                          color: status == 'present' ? Colors.green.shade50.withValues(alpha: isDark ? 0.15 : 1) : (status == 'absent' ? Colors.red.shade50.withValues(alpha: isDark ? 0.15 : 1) : (isDark ? const Color(0xFF1E293B) : Colors.grey.shade100)),
                                          border: Border.all(color: status == 'present' ? Colors.green : (status == 'absent' ? Colors.red : (isDark ? const Color(0xFF334155) : Colors.grey.shade300))),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            TranslatedText(status == 'absent' ? 'غیر حاضر' : 'حاضر', 
                                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: status == 'absent' ? Colors.red : Colors.green)),
                                            if (status == 'absent') const SizedBox(width: 1),
                                            if (status == 'absent') const Icon(Icons.close, size: 9.5, color: Colors.red),
                                            if (status == 'present') const SizedBox(width: 1),
                                            if (status == 'present') const Icon(Icons.check, size: 9.5, color: Colors.green),
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
                                              TranslatedText('والد: ', style: TextStyle(fontSize: 10, color: isDark ? Colors.white60 : Colors.grey)),
                                              Expanded(
                                                child: TranslatedText(student['fatherName'] ?? '', style: TextStyle(fontSize: 10, color: isDark ? Colors.white60 : Colors.grey)),
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
                                      onPressed: () async {
                                        final p = student['fatherPhone']?.toString() ?? '';
                                        if (p.isNotEmpty) {
                                          await _launchUrl('tel:$p');
                                        }
                                      },
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
        bottomNavigationBar: _selectedIndices.isNotEmpty ? InkWell(
          onTap: () => _showBulkMessageDialog(),
          child: Container(
            color: const Color(0xFF0F766E),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SafeArea(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: const Color(0xFF042F2E), borderRadius: BorderRadius.circular(8)),
                    child: Text(selectedCountText, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                  const Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.send, color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Text('منتخب طلبہ کو پیغام بھیجیں', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                        Text('(ان کے والدین کو خودکار پیغام جائے گا)', style: TextStyle(color: Colors.white70, fontSize: 10)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ) : const SizedBox(),
      ),
    );
  }

  Widget _buildTopBlock(String title, String subtitle, IconData icon, bool hasEdit) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300),
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
            Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: Colors.black87)),
            if (hasEdit) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
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
                Text(title, style: TextStyle(fontSize: 10, color: color.shade700, fontWeight: FontWeight.bold)),
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
