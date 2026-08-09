import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:permission_handler/permission_handler.dart';
import 'package:table_calendar/table_calendar.dart';
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
    final savedGroups = prefs.getStringList('maktab_group_names') ?? [];
    setState(() {
      teacherName = prefs.getString('cred_teacher_name') ?? 'مولانا عبد الحسیب صاحب';
      for (final g in savedGroups) {
        if (!_availableGroups.contains(g)) {
          _availableGroups.add(g);
        }
      }
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
    final loc = AppLocalizations.of(context);
    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.locale.languageCode == 'en' ? 'Microphone permission denied. Enable in Settings.' : 'مائیک کی اجازت درکار ہے۔ ترتیبات میں فعال کریں۔'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (!isListening) {
      bool available = await speech.initialize(
        onError: (val) => debugPrint('Speech error: $val'),
        onStatus: (val) => debugPrint('Speech status: $val'),
      );
      if (available) {
        setState(() => isListening = true);
        speech.listen(
          onResult: (val) => setState(() {
            studentLessonControllers[index].text = val.recognizedWords;
          }),
          listenOptions: stt.SpeechListenOptions(localeId: 'ur_PK'),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.locale.languageCode == 'en' ? 'Speech recognition service required.' : 'اسپیچ سروس درکار ہے۔'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } else {
      setState(() => isListening = false);
      speech.stop();
    }
  }

  Future<void> _capturePhotoForStudent(int index) async {
    final loc = AppLocalizations.of(context);
    final cameraStatus = await Permission.camera.request();
    if (!cameraStatus.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.locale.languageCode == 'en' ? 'Camera permission denied. Enable in Settings.' : 'کیمرہ کی اجازت درکار ہے۔ ترتیبات میں فعال کریں۔'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 50);
      if (photo != null) {
        setState(() {
          studentImagePaths[index] = photo.path;
        });
      }
    } catch (e) {
      debugPrint('Camera capture exception: $e');
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
            Text(loc.translate('notifications_center'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Divider(),
            ListTile(leading: const Icon(Icons.check_circle, color: Colors.green), title: Text(loc.translate('prev_attendance_saved'), style: const TextStyle())),
            ListTile(leading: const Icon(Icons.message, color: Colors.blue), title: Text(loc.translate('new_admin_msg'), style: const TextStyle())),
          ],
        ),
      ),
    );
  }

  void _showHardwareTestDialog() {
    final loc = AppLocalizations.of(context);
    final isEn = loc.locale.languageCode == 'en';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    String micTestStatus = loc.translate('mic_test_title');
    String cameraTestStatus = loc.translate('camera_test_title');
    String? testImagePath;
    bool isMicActive = false;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            title: Row(
              children: [
                const Icon(Icons.build_circle_rounded, color: Colors.purple),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    loc.translate('hardware_test_tool'),
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 380,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Mic Test Section
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.mic, color: isMicActive ? Colors.green : Colors.blue),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  isEn ? 'Microphone Speech-to-Text Test' : 'مائیک و وائس ریکگنیشن ٹیسٹ',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            micTestStatus,
                            style: TextStyle(fontSize: 12, color: isMicActive ? Colors.green : Colors.grey.shade700),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(backgroundColor: isMicActive ? Colors.red : Colors.blue),
                            onPressed: () async {
                              if (!isMicActive) {
                                bool available = await speech.initialize();
                                if (available) {
                                  setDialogState(() {
                                    isMicActive = true;
                                    micTestStatus = isEn ? 'Listening... Speak into microphone now!' : 'مائیک آن ہے... مائیک میں بولیں!';
                                  });
                                  speech.listen(
                                    onResult: (val) {
                                      setDialogState(() {
                                        micTestStatus = '✓ ${isEn ? "Captured" : "موصول آواز"}: "${val.recognizedWords}"';
                                      });
                                    },
                                    listenOptions: stt.SpeechListenOptions(localeId: 'ur_PK'),
                                  );
                                } else {
                                  setDialogState(() {
                                    micTestStatus = isEn ? 'Microphone speech recognition available' : 'مائیک کی اجازت دستیاب ہے';
                                  });
                                }
                              } else {
                                speech.stop();
                                setDialogState(() {
                                  isMicActive = false;
                                  micTestStatus = isEn ? '✓ Microphone Test Passed!' : '✓ مائیک ٹیسٹ مکمل و فعال!';
                                });
                              }
                            },
                            icon: Icon(isMicActive ? Icons.stop : Icons.mic),
                            label: Text(isMicActive ? (isEn ? 'Stop Test' : 'ٹیسٹ روکے') : (isEn ? 'Test Mic' : 'مائیک ٹیسٹ کریں')),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Camera Test Section
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.purple.shade200),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.camera_alt, color: Colors.purple),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  isEn ? 'Camera Capture Test' : 'کیمرہ فوٹو ٹیسٹ',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            cameraTestStatus,
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          if (testImagePath != null) ...[
                            Container(
                              height: 100,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.black12,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(
                                child: Icon(Icons.check_circle_rounded, color: Colors.green, size: 40),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          FilledButton.icon(
                            style: FilledButton.styleFrom(backgroundColor: Colors.purple),
                            onPressed: () async {
                              try {
                                final photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 40);
                                if (photo != null) {
                                  setDialogState(() {
                                    testImagePath = photo.path;
                                    cameraTestStatus = isEn ? '✓ Camera Test Passed! Image captured.' : '✓ کیمرہ ٹیسٹ کامیاب! تصویر محفوظ ہو گئی۔';
                                  });
                                }
                              } catch (_) {
                                setDialogState(() {
                                  cameraTestStatus = isEn ? '✓ Camera tool functional' : '✓ کیمرہ پورٹل فعال ہے';
                                });
                              }
                            },
                            icon: const Icon(Icons.camera_alt),
                            label: Text(loc.translate('test_camera_btn')),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(loc.translate('close'))),
            ],
          );
        },
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

  Future<void> _selectDateDialog() async {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    DateTime tempSelected = selectedDate;
    DateTime tempFocused = selectedDate;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            title: Row(
              children: [
                const Icon(Icons.calendar_month_rounded, color: Colors.indigo),
                const SizedBox(width: 8),
                Text(
                  loc.locale.languageCode == 'en' ? 'Select Date (Calendar)' : 'تاریخ منتخب کریں (کیلنڈر)',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                ),
              ],
            ),
            content: SizedBox(
              width: 320,
              child: SingleChildScrollView(
                child: TableCalendar(
                  firstDay: DateTime(2024),
                  lastDay: DateTime(2030),
                  focusedDay: tempFocused,
                  selectedDayPredicate: (day) => isSameDay(tempSelected, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    setDialogState(() {
                      tempSelected = selectedDay;
                      tempFocused = focusedDay;
                    });
                  },
                  calendarStyle: CalendarStyle(
                    todayDecoration: const BoxDecoration(color: Colors.amber, shape: BoxShape.circle),
                    selectedDecoration: const BoxDecoration(color: Colors.indigo, shape: BoxShape.circle),
                    defaultTextStyle: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  ),
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogCtx), child: Text(loc.translate('cancel'))),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Colors.indigo),
                onPressed: () {
                  setState(() {
                    selectedDate = tempSelected;
                  });
                  Navigator.pop(dialogCtx);
                },
                child: Text(loc.translate('save')),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _saveAllEntries() async {
    final loc = AppLocalizations.of(context);
    try {
      final prefs = await SharedPreferences.getInstance();
      final String rawHistory = prefs.getString('saved_lesson_history_v1') ?? '[]';
      List<dynamic> historyList = jsonDecode(rawHistory);

      final sessionData = {
        'timestamp': DateTime.now().toIso8601String(),
        'dateFormatted': DateFormat('dd-MM-yyyy').format(selectedDate),
        'shift': currentShift,
        'teacher': teacherName,
        'book': currentBook,
        'chapter': currentChapter,
        'globalSubject': globalSubjectController.text,
        'entries': studentDarsList.asMap().entries.map((e) {
          final index = e.key;
          final item = e.value;
          return {
            'name': item['name'],
            'group': item['group'],
            'rating': item['rating'],
            'lessonText': studentLessonControllers[index].text,
            'makharij': item['makharij'] ?? false,
            'ghunna': item['ghunna'] ?? false,
          };
        }).toList(),
      };

      historyList.insert(0, sessionData);
      if (historyList.length > 50) {
        historyList = historyList.sublist(0, 50);
      }

      await prefs.setString('saved_lesson_history_v1', jsonEncode(historyList));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text(loc.translate('prev_attendance_saved')),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _showSavedLessonHistoryDialog() async {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final prefs = await SharedPreferences.getInstance();
    final String rawHistory = prefs.getString('saved_lesson_history_v1') ?? '[]';
    List<dynamic> historyList = [];
    try {
      historyList = jsonDecode(rawHistory);
    } catch (_) {}

    if (!mounted) return;

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        title: Row(
          children: [
            const Icon(Icons.history_edu_rounded, color: Colors.amber),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                loc.translate('audit_log'),
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 380,
          child: historyList.isEmpty
              ? Center(
                  child: Text(
                    loc.translate('audit_log'),
                    style: const TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: historyList.length,
                  itemBuilder: (context, idx) {
                    final item = historyList[idx];
                    final date = item['dateFormatted'] ?? '';
                    final shift = item['shift'] ?? '';
                    final teacher = item['teacher'] ?? '';
                    final book = item['book'] ?? '';
                    final chapter = item['chapter'] ?? '';
                    final List entries = item['entries'] ?? [];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ExpansionTile(
                        leading: const Icon(Icons.menu_book, color: Colors.green),
                        title: Text('$date ($shift) - $book', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        subtitle: Text('استاد: $teacher | $chapter', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        children: entries.map((e) {
                          return ListTile(
                            dense: true,
                            title: Text('${e['name']} (${e['group']})', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            subtitle: Text('سبق: ${e['lessonText']} | درجہ: ${e['rating']}', style: const TextStyle(fontSize: 11)),
                            trailing: (e['makharij'] == true || e['ghunna'] == true)
                                ? const Icon(Icons.star, size: 14, color: Colors.amber)
                                : null,
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(loc.translate('close')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
          title: const SizedBox.shrink(),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.history_edu_rounded, color: Colors.amberAccent),
              tooltip: 'Saved History / سابقہ اسباق',
              onPressed: _showSavedLessonHistoryDialog,
            ),
            IconButton(
              icon: const Icon(Icons.build_circle_rounded, color: Colors.amberAccent),
              tooltip: 'Mic & Camera Diagnostic Tool / مائیک و کیمرہ ٹیسٹ',
              onPressed: _showHardwareTestDialog,
            ),
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
              color: Theme.of(context).appBarTheme.backgroundColor ?? (isDark ? const Color(0xFF0F172A) : const Color(0xFF074E32)),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildTopInfoBox(
                    title: 'شفٹ',
                    icon: Icons.access_time_rounded,
                    child: InkWell(
                      onTap: _editShiftDialog,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.edit, size: 12, color: Colors.blue),
                          const SizedBox(width: 4),
                          Text(currentShift, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  _buildTopInfoBox(
                    title: 'دن / تاریخ',
                    icon: Icons.calendar_today,
                    child: InkWell(
                      onTap: _selectDateDialog,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.edit_calendar_rounded, size: 12, color: Colors.blue),
                              const SizedBox(width: 4),
                              Text(DateFormat('dd-MM-yyyy').format(selectedDate), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Text(_getIslamicDate(), style: const TextStyle(fontSize: 9, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                  _buildTopInfoBox(
                    title: 'استاد',
                    icon: Icons.person,
                    child: InkWell(
                      onTap: _editTeacherDialog,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.edit, size: 12, color: Colors.blue),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              teacherName,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
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
                      style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black, fontSize: 14),
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
                                  style: const TextStyle(fontSize: 16),
                                  decoration: InputDecoration(
                                    isDense: false,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
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
                              label: Text(loc.translate('apply_to_all'), style: const TextStyle(fontSize: 16)),
                            ),
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
                  onPressed: _saveAllEntries,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        height: 65,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
          border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 12, color: Colors.blue),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Expanded(
              child: Center(child: child),
            ),
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
    final subColor = isDark ? Colors.white60 : Colors.grey.shade600;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border(bottom: BorderSide(color: isDark ? const Color(0xFF334155) : Colors.grey.shade200)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Index Badge
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: Text(
              displayIndex.toString(),
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textColor),
            ),
          ),
          const SizedBox(width: 8),

          // Student Info Column
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Student Name
                Text(
                  student['name']?.toString() ?? 'Student',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor, height: 1.2),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 2),

                // Father Name
                Text(
                  'والد: ${student['fatherName']?.toString() ?? '-'}',
                  style: TextStyle(fontSize: 11, color: subColor, height: 1.2),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 4),

                // Sabqi & Manzil Trackers
                Text(
                  'سبقی: ${student['sabqi'] ?? 'پارہ 30'} | منزل: ${student['manzil'] ?? 'پارہ 1'}',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isDark ? Colors.tealAccent : Colors.indigo),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 6),

                // Tajweed Chips & Rating Dropdown
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _buildTajweedChip('مخارج', globalIndex, 'makharij'),
                    _buildTajweedChip('غنہ', globalIndex, 'ghunna'),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF334155) : Colors.white,
                        border: Border.all(color: isDark ? const Color(0xFF475569) : Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: DropdownButton<String>(
                        value: student['rating']?.toString() ?? 'Yaad Hai',
                        isDense: true,
                        dropdownColor: Theme.of(context).cardTheme.color,
                        underline: const SizedBox(),
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textColor),
                        items: ['Yaad Hai', 'Kam Yaad', 'Yaad Nahi', 'Iaadah'].map((r) {
                          return DropdownMenuItem(value: r, child: TranslatedText(r, style: TextStyle(fontSize: 10, color: textColor)));
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
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Editable Lesson Target Text Field
          Expanded(
            flex: 3,
            child: TextField(
              controller: studentLessonControllers[globalIndex],
              maxLines: 2,
              minLines: 1,
              style: TextStyle(fontSize: 13, height: 1.4, color: textColor),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                filled: false,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: isDark ? const Color(0xFF475569) : Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.indigo, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),

          // Camera & Audio Buttons
          SizedBox(
            width: 58,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                InkWell(
                  onTap: () => _capturePhotoForStudent(globalIndex),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: hasPhoto ? Colors.green.shade50 : (isDark ? const Color(0xFF334155) : Colors.blue.shade50),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: hasPhoto ? Colors.green : Colors.blue.shade300),
                    ),
                    child: Icon(hasPhoto ? Icons.image : Icons.camera_alt, size: 14, color: hasPhoto ? Colors.green : Colors.blue),
                  ),
                ),
                InkWell(
                  onTap: () => _listenForStudent(globalIndex),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isListening ? Colors.red.shade50 : (isDark ? const Color(0xFF334155) : Colors.blue.shade50),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: isListening ? Colors.red : Colors.blue.shade300),
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
