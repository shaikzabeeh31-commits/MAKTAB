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
          'makharij': false,
          'ghunna': false,
          'sabqi': s['sabqi'] ?? 'پارہ 30',
          'manzil': s['manzil'] ?? 'پارہ 1',
          'rating': s['rating'] ?? 'Yaad Hai',
        };
      }).toList();
      _availableGroups = ['all', ...groups.toList()..sort()];
    } else {
      studentDarsList = [
        {'name': 'محمد احمد', 'fatherName': 'عبد الرحمٰن', 'group': 'حفظ گروپ A', 'makharij': false, 'ghunna': false, 'sabqi': 'پارہ 30', 'manzil': 'پارہ 1', 'rating': 'Yaad Hai'},
        {'name': 'علی رضا', 'fatherName': 'فاروق احمد', 'group': 'حفظ گروپ A', 'makharij': false, 'ghunna': false, 'sabqi': 'پارہ 30', 'manzil': 'پارہ 1', 'rating': 'Yaad Hai'},
        {'name': 'حسن حیدر', 'fatherName': 'حیدر علی', 'group': 'حفظ گروپ A', 'makharij': false, 'ghunna': false, 'sabqi': 'پارہ 30', 'manzil': 'پارہ 1', 'rating': 'Yaad Hai'},
        {'name': 'عبداللہ', 'fatherName': 'سلیم خان', 'group': 'حفظ گروپ A', 'makharij': false, 'ghunna': false, 'sabqi': 'پارہ 30', 'manzil': 'پارہ 1', 'rating': 'Yaad Hai'},
        {'name': 'محمد اسامہ', 'fatherName': 'اکرم خان', 'group': 'حفظ گروپ A', 'makharij': false, 'ghunna': false, 'sabqi': 'پارہ 30', 'manzil': 'پارہ 1', 'rating': 'Yaad Hai'},
        {'name': 'زید خان', 'fatherName': 'یوسف خان', 'group': 'ناظرہ گروپ B', 'makharij': false, 'ghunna': false, 'sabqi': 'پارہ 30', 'manzil': 'پارہ 1', 'rating': 'Yaad Hai'},
        {'name': 'عمران', 'fatherName': 'ندیم احمد', 'group': 'ناظرہ گروپ B', 'makharij': false, 'ghunna': false, 'sabqi': 'پارہ 30', 'manzil': 'پارہ 1', 'rating': 'Yaad Hai'},
        {'name': 'سعید احمد', 'fatherName': 'رشید احمد', 'group': 'ناظرہ گروپ B', 'makharij': false, 'ghunna': false, 'sabqi': 'پارہ 30', 'manzil': 'پارہ 1', 'rating': 'Yaad Hai'},
        {'name': 'فیضان علی', 'fatherName': 'شکیل احمد', 'group': 'ناظرہ گروپ B', 'makharij': false, 'ghunna': false, 'sabqi': 'پارہ 30', 'manzil': 'پارہ 1', 'rating': 'Yaad Hai'},
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
    final loc = AppLocalizations.of(context);
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
      SnackBar(
        content: Text(loc.locale.languageCode == 'en' ? 'Subject applied to all students!' : 'سبجیکٹ تمام طلبہ پر لاگو کر دیا گیا!', style: const TextStyle()),
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

  void _selectSubjectDialog() {
    final loc = AppLocalizations.of(context);
    final isEn = loc.locale.languageCode == 'en';
    final List<String> subjects = [
      isEn ? 'Quran' : 'قرآن مجید',
      isEn ? 'Tajweed' : 'تجوید و مخارج',
      isEn ? 'Diniyat' : 'دینیات و عقائد',
      isEn ? 'Hadith' : 'حدیث شریف',
      isEn ? 'Dua' : 'مسنون دعائیں',
      isEn ? 'Arabic' : 'عربی زبان',
    ];
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(loc.translate('select_subject'), style: const TextStyle()),
          content: SingleChildScrollView(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: subjects.map((sub) {
                return ActionChip(
                  label: Text(sub, style: const TextStyle()),
                  onPressed: () {
                    setState(() {
                      globalSubjectController.text = sub;
                    });
                    Navigator.pop(ctx);
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(loc.translate('cancel')),
            ),
          ],
        );
      },
    );
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
            Text(loc.locale.languageCode == 'en' ? 'Notifications' : 'نوٹیفکیشنز', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Divider(),
            ListTile(leading: const Icon(Icons.check_circle, color: Colors.green), title: const Text('پچھلی حاضری کامیابی سے محفوظ ہو گئی۔', style: TextStyle())),
            ListTile(leading: const Icon(Icons.message, color: Colors.blue), title: const Text('ایڈمن کی جانب سے نیا پیغام موصول ہوا۔', style: TextStyle())),
          ],
        ),
      ),
    );
  }

  void _editShiftDialog() {
    final loc = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) {
        String tempShift = currentShift;
        return StatefulBuilder(
          builder: (context, setStateSB) {
            return AlertDialog(
              title: Text(loc.locale.languageCode == 'en' ? 'Change Shift' : 'شفٹ تبدیل کریں', style: const TextStyle()),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: ['صبح', 'دوپہر', 'شام', 'رات'].map((shift) => RadioListTile(
                  title: Text(shift, style: const TextStyle()),
                  value: shift,
                  // ignore: deprecated_member_use
                  groupValue: tempShift,
                  // ignore: deprecated_member_use
                  onChanged: (val) => setStateSB(() => tempShift = val.toString()),
                )).toList(),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: Text(loc.translate('cancel'))),
                ElevatedButton(onPressed: () {
                  setState(() => currentShift = tempShift);
                  Navigator.pop(ctx);
                }, child: Text(loc.translate('save'))),
              ],
            );
          }
        );
      },
    );
  }

  void _editTeacherDialog() {
    final loc = AppLocalizations.of(context);
    final ctrl = TextEditingController(text: teacherName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.translate('change_teacher'), style: const TextStyle()),
        content: TextField(controller: ctrl, style: const TextStyle()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(loc.translate('cancel'))),
          ElevatedButton(onPressed: () async {
            setState(() => teacherName = ctrl.text);
            final prefs = await SharedPreferences.getInstance();
            prefs.setString('cred_teacher_name', ctrl.text);
            if (ctx.mounted) Navigator.pop(ctx);
          }, child: Text(loc.translate('save'))),
        ],
      ),
    );
  }

  void _editTopicDialog() {
    final loc = AppLocalizations.of(context);
    final bookCtrl = TextEditingController(text: currentBook);
    final chapterCtrl = TextEditingController(text: currentChapter);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.translate('change_topic'), style: const TextStyle()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: bookCtrl, decoration: InputDecoration(labelText: loc.translate('book_name')), style: const TextStyle()),
            const SizedBox(height: 8),
            TextField(controller: chapterCtrl, decoration: InputDecoration(labelText: loc.translate('lesson_surah')), style: const TextStyle()),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(loc.translate('cancel'))),
          ElevatedButton(onPressed: () {
            setState(() {
              currentBook = bookCtrl.text;
              currentChapter = chapterCtrl.text;
            });
            Navigator.pop(ctx);
          }, child: Text(loc.translate('save'))),
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
    final loc = AppLocalizations.of(context);
    
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
          title: Column(
            children: [
              Text(loc.translate('madrasa_title'), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              Text(loc.translate('lesson_plan'), style: const TextStyle(color: Colors.amberAccent, fontSize: 14)),
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
                      label: Text(currentShift, style: const TextStyle(fontSize: 14)),
                    ),
                  ),
                  _buildTopInfoBox(
                    title: 'دن / تاریخ',
                    icon: Icons.calendar_today,
                    child: Column(
                      children: [
                        Text(loc.locale.languageCode == 'en' ? 'Saturday' : 'ہفتہ', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        Text(DateFormat('dd-MM-yyyy').format(selectedDate), style: const TextStyle(fontSize: 10)),
                        Text(_getIslamicDate(), style: const TextStyle(fontSize: 12)),
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
                          child: Text(teacherName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
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
                      isExpanded: true,
                      underline: const SizedBox(),
                      style: const TextStyle(color: Colors.black, fontSize: 14),
                      items: _availableGroups.map((g) {
                        return DropdownMenuItem(value: g, child: Text(g == 'all' ? (loc.locale.languageCode == 'en' ? 'All Groups' : 'تمام گروپس') : g));
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
                    Align(
                      alignment: Alignment.topRight,
                      child: Text(
                        loc.translate('lesson_entry_title'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF074E32)),
                      ),
                    ),
                    const SizedBox(height: 8),
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
                          Align(
                            alignment: Alignment.topRight,
                            child: Text(loc.translate('overview'), style: const TextStyle(color: Colors.green, fontSize: 16)),
                          ),
                          const Icon(Icons.menu_book_rounded, size: 40, color: Colors.green),
                          const SizedBox(height: 8),
                          Text(currentBook, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                          Text(currentChapter, style: const TextStyle(fontSize: 16, color: Colors.grey)),
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
                          Text(loc.translate('select_subject'), style: const TextStyle(color: Colors.blue, fontSize: 16)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: _selectSubjectDialog),
                              Expanded(
                                child: TextFormField(
                                  controller: globalSubjectController,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 18, height: 1.6),
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
                              label: Text(loc.translate('apply_to_all'), style: const TextStyle(fontSize: 18)),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: Text(loc.locale.languageCode == 'en' ? 'Click here to copy the subject above to all students' : 'اوپر والے سبجیکٹ کو تمام طلبہ کے سبجیکٹ باکس میں کاپی کرنے کے لئے یہاں کلک کریں',
                                style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Section 3 Header and Quick Actions
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(
                          loc.translate('dars_entry_title'),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF074E32)),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  for (var s in studentDarsList) {
                                    s['rating'] = 'Yaad Hai';
                                  }
                                });
                              },
                              icon: const Icon(Icons.check_circle_outline, size: 14, color: Colors.green),
                              label: Text(
                                loc.translate('mark_all_yaad_hai'),
                                style: const TextStyle(fontSize: 10, color: Colors.green),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  for (var s in studentDarsList) {
                                    s['rating'] = 'Iaadah';
                                  }
                                });
                              },
                              icon: const Icon(Icons.repeat, size: 14, color: Colors.orange),
                              label: Text(
                                loc.translate('mark_all_iaadah'),
                                style: const TextStyle(fontSize: 10, color: Colors.orange),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

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
                              style: TextStyle(fontSize: 14),
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
        bottomNavigationBar: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: const Color(0x0D000000),
                blurRadius: 4,
                offset: const Offset(0, -2),
              )
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(loc.translate('save'))),
                    );
                  },
                  icon: const Icon(Icons.save),
                  label: Text(loc.translate('save_all_entries')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF074E32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('PDF Generated!')),
                    );
                  },
                  icon: const Icon(Icons.picture_as_pdf),
                  label: Text(loc.translate('save_as_pdf')),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF074E32),
                    side: const BorderSide(color: Color(0xFF074E32)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
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
                Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
    final loc = AppLocalizations.of(context);
    final grouped = _getGroupedStudents();
    List<Widget> tables = [];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    grouped.forEach((groupName, indices) {
      tables.add(
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.grey.shade200, blurRadius: 4, spreadRadius: 1)],
          ),
          child: Column(
            children: [
              // Group Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.blue.withValues(alpha: 0.15) : Colors.blue.shade50,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.people, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(groupName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
                      ],
                    ),
                    Text('${loc.locale.languageCode == 'en' ? "Students" : "طلبہ"}: ${indices.length}', style: const TextStyle(fontSize: 16, color: Colors.blue)),
                  ],
                ),
              ),
              // Table Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Row(
                  children: [
                    SizedBox(width: 24, child: Text('#', style: TextStyle(fontSize: 10, color: Colors.grey), textAlign: TextAlign.center)),
                    Expanded(flex: 2, child: Text(loc.translate('student_name'), style: const TextStyle(fontSize: 12, color: Colors.grey), textAlign: TextAlign.center)),
                    Expanded(flex: 3, child: Text(loc.locale.languageCode == 'en' ? 'Subject (Editable)' : 'سبجیکٹ (ایڈٹ کیا جا سکتا ہے)', style: const TextStyle(fontSize: 12, color: Colors.grey), textAlign: TextAlign.center)),
                    SizedBox(width: 60, child: Text(loc.locale.languageCode == 'en' ? 'Recording / Photo' : 'ریکارڈنگ / تصویر', style: const TextStyle(fontSize: 10, color: Colors.grey), textAlign: TextAlign.center)),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.white60 : Colors.grey;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: isDark ? const Color(0xFF334155) : Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          SizedBox(width: 24, child: Text(displayIndex.toString(), style: TextStyle(fontSize: 12, color: textColor), textAlign: TextAlign.center)),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                TranslatedText(student['name'], style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, height: 1.5, color: textColor)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    TranslatedText('والد/سرپرست: ', style: TextStyle(fontSize: 10, color: subColor, height: 1.2)),
                    Expanded(
                      child: TranslatedText(student['fatherName'], style: TextStyle(fontSize: 10, color: subColor, height: 1.2)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Tajweed Markers
                Row(
                  children: [
                    _buildTajweedChip('مخارج', globalIndex, 'makharij'),
                    const SizedBox(width: 4),
                    _buildTajweedChip('غنہ', globalIndex, 'ghunna'),
                  ],
                ),
                const SizedBox(height: 4),
                // Sabqi & Manzil Trackers
                Row(
                  children: [
                    TranslatedText('سبقی: ', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isDark ? Colors.tealAccent : Colors.blueGrey)),
                    Expanded(
                      child: TranslatedText(student['sabqi']?.toString() ?? 'پارہ 30', style: TextStyle(fontSize: 9, color: textColor), overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 4),
                    TranslatedText('منزل: ', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isDark ? Colors.tealAccent : Colors.blueGrey)),
                    Expanded(
                      child: TranslatedText(student['manzil']?.toString() ?? 'پارہ 1', style: TextStyle(fontSize: 9, color: textColor), overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Rating Dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: DropdownButton<String>(
                    value: student['rating']?.toString() ?? 'Yaad Hai',
                    isDense: true,
                    dropdownColor: Theme.of(context).cardTheme.color,
                    underline: const SizedBox(),
                    style: TextStyle(fontSize: 9, color: textColor),
                    items: ['Yaad Hai', 'Kam Yaad', 'Yaad Nahi', 'Iaadah'].map((r) {
                      return DropdownMenuItem(value: r, child: TranslatedText(r, style: TextStyle(fontSize: 9, color: textColor)));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          student['rating'] = val;
                        });
                      }
                    },
                  ),
                ),
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
                style: const TextStyle(fontSize: 14, height: 1.6),
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

  Widget _buildTajweedChip(String label, int index, String key) {
    final s = studentDarsList[index];
    final bool isChecked = s[key] as bool? ?? false;
    return InkWell(
      onTap: () {
        setState(() {
          s[key] = !isChecked;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: isChecked ? Colors.green.shade50 : Colors.grey.shade50,
          border: Border.all(color: isChecked ? Colors.green : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isChecked) const Icon(Icons.check, size: 8, color: Colors.green),
            Text(label, style: TextStyle(fontSize: 8, color: isChecked ? Colors.green.shade900 : Colors.black87)),
          ],
        ),
      ),
    );
  }
}
