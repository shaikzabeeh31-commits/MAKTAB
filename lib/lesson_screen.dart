import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'app_localizations.dart';
import 'theme_controller.dart';

class LessonScreen extends StatefulWidget {
  final List<Map<String, dynamic>>? students;
  final LanguageController? languageController;
  final ThemeController? themeController;

  const LessonScreen({
    super.key,
    this.students,
    this.languageController,
    this.themeController,
  });

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  DateTime selectedDate = DateTime.now();
  String selectedGroup = 'all';
  String teacherName = 'محمد عمران';
  String currentShift = 'صبح';
  String currentBook = 'قرآن کریم';
  String currentChapter = 'سورۃ الفاتحہ — تلاوت اور معنی';
  
  final TextEditingController globalSubjectController = TextEditingController(text: 'قرآن کریم - سورۃ الفاتحہ');

  List<Map<String, dynamic>> studentDarsList = [];
  List<String> _availableGroups = ['all'];
  
  final List<TextEditingController> studentLessonControllers = [];
  final List<String?> studentImagePaths = [];

  late stt.SpeechToText speech;
  bool isListening = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    speech = stt.SpeechToText();
    _loadTeacherInfo();

    if (widget.students != null && widget.students!.isNotEmpty) {
      final groups = <String>{};
      studentDarsList = widget.students!.map((s) {
        if (s['group'] != null && s['group'].toString().isNotEmpty) {
          groups.add(s['group'].toString());
        }
        return {
          'name': s['name'] ?? 'Unknown',
          'fatherName': s['fatherName'] ?? '-',
          'group': s['group'] ?? '',
        };
      }).toList();
      _availableGroups = ['all', ...groups.toList()..sort()];
    } else {
      studentDarsList = [
        {'name': 'محمد احمد', 'fatherName': 'عبد الرحمٰن', 'group': 'حفظ گروپ A'},
        {'name': 'علی رضا', 'fatherName': 'فاروق احمد', 'group': 'حفظ گروپ A'},
        {'name': 'حسن حیدر', 'fatherName': 'حیدر علی', 'group': 'حفظ گروپ A'},
        {'name': 'عبداللہ', 'fatherName': 'سلیم خان', 'group': 'حفظ گروپ A'},
        {'name': 'محمد اسامہ', 'fatherName': 'اکرم خان', 'group': 'حفظ گروپ A'},
        {'name': 'زید خان', 'fatherName': 'یوسف خان', 'group': 'ناظرہ گروپ B'},
        {'name': 'عمران', 'fatherName': 'ندیم احمد', 'group': 'ناظرہ گروپ B'},
        {'name': 'سعید احمد', 'fatherName': 'رشید احمد', 'group': 'ناظرہ گروپ B'},
        {'name': 'فیضان علی', 'fatherName': 'شکیل احمد', 'group': 'ناظرہ گروپ B'},
      ];
      _availableGroups = ['all', 'حفظ گروپ A', 'ناظرہ گروپ B'];
    }

    for (var i = 0; i < studentDarsList.length; i++) {
      studentLessonControllers.add(TextEditingController(text: 'قرآن کریم - سورۃ الفاتحہ'));
      studentImagePaths.add(null);
    }
  }

  Future<void> _loadTeacherInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      teacherName = prefs.getString('cred_teacher_name') ?? 'محمد عمران';
    });
  }

  @override
  void dispose() {
    globalSubjectController.dispose();
    for (var c in studentLessonControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _applySubjectToAll() {
    final text = globalSubjectController.text;
    if (text.isEmpty) return;
    setState(() {
      for (int i = 0; i < studentDarsList.length; i++) {
        if (selectedGroup == 'all' || studentDarsList[i]['group'] == selectedGroup) {
          studentLessonControllers[i].text = text;
        }
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('سبجیکٹ تمام طلبہ پر لاگو کر دیا گیا!', style: TextStyle(fontFamily: 'Jameel Noori Nastaleeq')),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _listenForStudent(int index) async {
    if (!isListening) {
      bool available = await speech.initialize();
      if (available) {
        setState(() => isListening = true);
        speech.listen(
          onResult: (val) => setState(() {
            studentLessonControllers[index].text = val.recognizedWords;
          }),
          listenOptions: stt.SpeechListenOptions(localeId: 'ur_PK'),
        );
      }
    } else {
      setState(() => isListening = false);
      speech.stop();
    }
  }

  Future<void> _capturePhotoForStudent(int index) async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 50);
      if (photo != null) {
        setState(() {
          studentImagePaths[index] = photo.path;
        });
      }
    } catch (e) {
      debugPrint('Error capturing photo: $e');
    }
  }

  void _showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('یہ فیچر جلد آ رہا ہے (Coming Soon)', style: TextStyle(fontFamily: 'Jameel Noori Nastaleeq')),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 1),
      ),
    );
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
            ListTile(leading: const Icon(Icons.message, color: Colors.blue), title: const Text('ایڈمن کی جانب سے نیا پیغام موصول ہوا۔', style: TextStyle(fontFamily: 'Jameel Noori Nastaleeq'))),
          ],
        ),
      ),
    );
  }

  void _editShiftDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        String tempShift = currentShift;
        return StatefulBuilder(
          builder: (context, setStateSB) {
            return AlertDialog(
              title: const Text('شفٹ تبدیل کریں', style: TextStyle(fontFamily: 'Jameel Noori Nastaleeq')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: ['صبح', 'دوپہر', 'شام', 'رات'].map((shift) => RadioListTile(
                  title: Text(shift, style: const TextStyle(fontFamily: 'Jameel Noori Nastaleeq')),
                  value: shift,
                  groupValue: tempShift,
                  onChanged: (val) => setStateSB(() => tempShift = val.toString()),
                )).toList(),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('کینسل')),
                ElevatedButton(onPressed: () {
                  setState(() => currentShift = tempShift);
                  Navigator.pop(ctx);
                }, child: const Text('محفوظ کریں')),
              ],
            );
          }
        );
      },
    );
  }

  void _editTeacherDialog() {
    final ctrl = TextEditingController(text: teacherName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('استاد کا نام تبدیل کریں', style: TextStyle(fontFamily: 'Jameel Noori Nastaleeq')),
        content: TextField(controller: ctrl, style: const TextStyle(fontFamily: 'Jameel Noori Nastaleeq')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('کینسل')),
          ElevatedButton(onPressed: () async {
            setState(() => teacherName = ctrl.text);
            final prefs = await SharedPreferences.getInstance();
            prefs.setString('cred_teacher_name', ctrl.text);
            if (ctx.mounted) Navigator.pop(ctx);
          }, child: const Text('محفوظ کریں')),
        ],
      ),
    );
  }

  void _editTopicDialog() {
    final bookCtrl = TextEditingController(text: currentBook);
    final chapterCtrl = TextEditingController(text: currentChapter);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('آج کا موضوع تبدیل کریں', style: TextStyle(fontFamily: 'Jameel Noori Nastaleeq')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: bookCtrl, decoration: const InputDecoration(labelText: 'کتاب کا نام'), style: const TextStyle(fontFamily: 'Jameel Noori Nastaleeq')),
            const SizedBox(height: 8),
            TextField(controller: chapterCtrl, decoration: const InputDecoration(labelText: 'سبق/سورت'), style: const TextStyle(fontFamily: 'Jameel Noori Nastaleeq')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('کینسل')),
          ElevatedButton(onPressed: () {
            setState(() {
              currentBook = bookCtrl.text;
              currentChapter = chapterCtrl.text;
            });
            Navigator.pop(ctx);
          }, child: const Text('محفوظ کریں')),
        ],
      ),
    );
  }

  String _getIslamicDate() {
    return '07 ذو القعدہ 1445';
  }

  Map<String, List<int>> _getGroupedStudents() {
    Map<String, List<int>> grouped = {};
    for (int i = 0; i < studentDarsList.length; i++) {
      if (selectedGroup == 'all' || studentDarsList[i]['group'] == selectedGroup) {
        String group = studentDarsList[i]['group'] as String;
        if (!grouped.containsKey(group)) {
          grouped[group] = [];
        }
        grouped[group]!.add(i);
      }
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F9),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0F172A),
          foregroundColor: Colors.white,
          title: const Column(
            children: [
              Text('مدرسہ خیر العلوم اشرفیہ', style: TextStyle(fontFamily: 'Jameel Noori Nastaleeq', fontSize: 24, fontWeight: FontWeight.bold)),
              Text('(Lessons) سبق', style: TextStyle(color: Colors.amberAccent, fontSize: 14)),
            ],
          ),
          centerTitle: true,
          actions: [
            Stack(
              alignment: Alignment.center,
              children: [
                IconButton(icon: const Icon(Icons.notifications_none_rounded), onPressed: _showNotificationsDialog),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    child: const Text('5', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            )
          ],
        ),
        body: Column(
          children: [
            // TOP INFO BAR
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildTopInfoBox(
                    title: 'شفٹ',
                    icon: Icons.people,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8), side: const BorderSide(color: Colors.blue)),
                      onPressed: _editShiftDialog,
                      icon: const Icon(Icons.edit, size: 12),
                      label: Text(currentShift, style: const TextStyle(fontFamily: 'Jameel Noori Nastaleeq', fontSize: 14)),
                    ),
                  ),
                  _buildTopInfoBox(
                    title: 'دن / تاریخ',
                    icon: Icons.calendar_today,
                    child: Column(
                      children: [
                        const Text('ہفتہ Saturday', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        Text(DateFormat('dd-MM-yyyy').format(selectedDate), style: const TextStyle(fontSize: 10)),
                        Text(_getIslamicDate(), style: const TextStyle(fontFamily: 'Jameel Noori Nastaleeq', fontSize: 12)),
                      ],
                    ),
                  ),
                  _buildTopInfoBox(
                    title: 'استاد',
                    icon: Icons.person,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.edit, size: 12, color: Colors.blue),
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: _editTeacherDialog,
                          child: Text(teacherName, style: const TextStyle(fontFamily: 'Jameel Noori Nastaleeq', fontSize: 14, decoration: TextDecoration.underline)),
                        ),
                      ],
                    ),
                  ),
                  _buildTopInfoBox(
                    title: 'گروپ سلیکشن',
                    icon: Icons.groups,
                    child: DropdownButton<String>(
                      value: selectedGroup,
                      isDense: true,
                      underline: const SizedBox(),
                      style: const TextStyle(fontFamily: 'Jameel Noori Nastaleeq', color: Colors.black, fontSize: 14),
                      items: _availableGroups.map((g) {
                        return DropdownMenuItem(value: g, child: Text(g == 'all' ? 'تمام گروپس' : g));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => selectedGroup = val);
                      },
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    // TODAY'S TOPIC
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Column(
                        children: [
                          const Align(
                            alignment: Alignment.topRight,
                            child: Text('آج کا موضوع', style: TextStyle(fontFamily: 'Jameel Noori Nastaleeq', color: Colors.green, fontSize: 16)),
                          ),
                          const Icon(Icons.menu_book_rounded, size: 40, color: Colors.green),
                          const SizedBox(height: 8),
                          Text(currentBook, style: const TextStyle(fontFamily: 'Jameel Noori Nastaleeq', fontSize: 28, fontWeight: FontWeight.bold)),
                          Text(currentChapter, style: const TextStyle(fontFamily: 'Jameel Noori Nastaleeq', fontSize: 16, color: Colors.grey)),
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: IconButton(icon: const Icon(Icons.edit, color: Colors.green), onPressed: _editTopicDialog),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // GLOBAL SUBJECT SELECTION
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('سبجیکٹ سلیکشن', style: TextStyle(fontFamily: 'Jameel Noori Nastaleeq', color: Colors.blue, fontSize: 16)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: _showComingSoon),
                              Expanded(
                                child: TextFormField(
                                  controller: globalSubjectController,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontFamily: 'Jameel Noori Nastaleeq', fontSize: 18, height: 1.6),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF0F3A8C),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: _applySubjectToAll,
                              icon: const Icon(Icons.sync),
                              label: const Text('کیا سب پر لاگو کریں', style: TextStyle(fontFamily: 'Jameel Noori Nastaleeq', fontSize: 18)),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Center(
                            child: Text('اوپر والے سبجیکٹ کو تمام طلبہ کے سبجیکٹ باکس میں کاپی کرنے کے لئے یہاں کلک کریں',
                                style: TextStyle(fontFamily: 'Jameel Noori Nastaleeq', fontSize: 12, color: Colors.grey)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // GROUPED TABLES
                    ..._buildGroupedTables(),

                    const SizedBox(height: 12),
                    // NOTE BOX
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        border: Border.all(color: Colors.orange.shade200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'نوٹ: اگر آپ کسی خاص طالب علم کے لئے سبجیکٹ تبدیل کریں گے (جیسے سبق نمبر 6) تو صرف اسی طالب علم کے باقی طلبہ پر اوپر والا سبجیکٹ لاگو رہے گا۔',
                              style: TextStyle(fontFamily: 'Jameel Noori Nastaleeq', fontSize: 14),
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildTopInfoBox({required String title, required IconData icon, required Widget child}) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 14, color: Colors.blue),
                const SizedBox(width: 4),
                Text(title, style: const TextStyle(fontFamily: 'Jameel Noori Nastaleeq', fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 8),
            child,
          ],
        ),
      ),
    );
  }

  List<Widget> _buildGroupedTables() {
    final grouped = _getGroupedStudents();
    List<Widget> tables = [];

    grouped.forEach((groupName, indices) {
      tables.add(
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 4, spreadRadius: 1)],
          ),
          child: Column(
            children: [
              // Group Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.people, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(groupName, style: const TextStyle(fontFamily: 'Jameel Noori Nastaleeq', fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
                      ],
                    ),
                    Text('طلبہ: ${indices.length}', style: const TextStyle(fontFamily: 'Jameel Noori Nastaleeq', fontSize: 16, color: Colors.blue)),
                  ],
                ),
              ),
              // Table Header
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Row(
                  children: [
                    SizedBox(width: 24, child: Text('#', style: TextStyle(fontSize: 10, color: Colors.grey), textAlign: TextAlign.center)),
                    Expanded(flex: 2, child: Text('طالب علم کا نام', style: TextStyle(fontFamily: 'Jameel Noori Nastaleeq', fontSize: 12, color: Colors.grey), textAlign: TextAlign.center)),
                    Expanded(flex: 3, child: Text('سبجیکٹ (ایڈٹ کیا جا سکتا ہے)', style: TextStyle(fontFamily: 'Jameel Noori Nastaleeq', fontSize: 12, color: Colors.grey), textAlign: TextAlign.center)),
                    SizedBox(width: 60, child: Text('ریکارڈنگ / تصویر', style: TextStyle(fontFamily: 'Jameel Noori Nastaleeq', fontSize: 10, color: Colors.grey), textAlign: TextAlign.center)),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Table Rows
              ...indices.asMap().entries.map((entry) {
                int rowIdx = entry.key + 1;
                int globalIdx = entry.value;
                return _buildStudentRow(rowIdx, globalIdx);
              }),
            ],
          ),
        ),
      );
    });

    return tables;
  }

  Widget _buildStudentRow(int displayIndex, int globalIndex) {
    final student = studentDarsList[globalIndex];
    final bool hasPhoto = studentImagePaths[globalIndex] != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          SizedBox(width: 24, child: Text(displayIndex.toString(), style: const TextStyle(fontSize: 12), textAlign: TextAlign.center)),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(student['name'], style: const TextStyle(fontFamily: 'Jameel Noori Nastaleeq', fontSize: 15, fontWeight: FontWeight.bold, height: 1.5)),
                const SizedBox(height: 4),
                Text('والد/سرپرست: ${student['fatherName']}', style: const TextStyle(fontFamily: 'Jameel Noori Nastaleeq', fontSize: 11, color: Colors.grey, height: 1.5)),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: TextFormField(
                controller: studentLessonControllers[globalIndex],
                textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: 'Jameel Noori Nastaleeq', fontSize: 14, height: 1.6),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.grey.shade300)),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                InkWell(
                  onTap: () => _capturePhotoForStudent(globalIndex),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: hasPhoto ? Colors.green.shade50 : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: hasPhoto ? Colors.green : Colors.blue.shade200),
                    ),
                    child: Icon(hasPhoto ? Icons.image : Icons.camera_alt, size: 14, color: hasPhoto ? Colors.green : Colors.blue),
                  ),
                ),
                InkWell(
                  onTap: () => _listenForStudent(globalIndex),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Icon(isListening ? Icons.mic : Icons.mic_none, size: 14, color: isListening ? Colors.red : Colors.blue),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
