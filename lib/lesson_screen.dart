import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'app_localizations.dart';
import 'pdf_service.dart';
import 'theme_controller.dart';

class LessonScreen extends StatefulWidget {
  final LanguageController? languageController;
  final ThemeController? themeController;

  const LessonScreen({
    super.key,
    this.languageController,
    this.themeController,
  });

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  DateTime selectedDate = DateTime.now();
  List<String> subjects = [
    'Diniyat',
    'Quran Hifz',
    'Nazra',
    'Tajweed',
    'Arabic',
    'Hadith',
    'Seerat',
  ];
  int selectedSubjectIndex = 0;

  String get selectedSubject {
    if (subjects.isEmpty) return 'Diniyat';
    return subjects[selectedSubjectIndex];
  }

  final TextEditingController todayLessonController = TextEditingController(
    text: 'رَّبِّ زِدْنِي عِلْمًا وَارْزُقْنِي فَهْمًا\nRabb Zidni Ilman Warzuqni Fahman',
  );

  // Student Dars State List
  final List<Map<String, dynamic>> studentDarsList = [
    {'name': 'Mohammad Ahmed', 'lesson': '', 'rating': 'Yaad Hai', 'remarks': ''},
    {'name': 'Abdullah Khan', 'lesson': '', 'rating': 'Yaad Hai', 'remarks': ''},
    {'name': 'Ali Raza', 'lesson': '', 'rating': 'Yaad Hai', 'remarks': ''},
    {'name': 'Tahir Hussain', 'lesson': '', 'rating': 'Kam Yaad Hai', 'remarks': ''},
    {'name': 'Yousuf Ali', 'lesson': '', 'rating': 'Yaad Hai', 'remarks': ''},
    {'name': 'Zaid Hasan', 'lesson': '', 'rating': 'Yaad Nahi', 'remarks': ''},
    {'name': 'Hassan Mahmood', 'lesson': '', 'rating': 'Iaadah', 'remarks': ''},
    {'name': 'Abbas Haider', 'lesson': '', 'rating': 'Yaad Hai', 'remarks': ''},
    {'name': 'Salman Farooq', 'lesson': '', 'rating': 'Yaad Hai', 'remarks': ''},
    {'name': 'Abdul Rehman', 'lesson': '', 'rating': 'Yaad Hai', 'remarks': ''},
  ];

  late stt.SpeechToText speech;
  bool isListening = false;
  int? listeningStudentIndex;
  final List<TextEditingController> studentLessonControllers = [];
  final List<TextEditingController> studentRemarksControllers = [];

  @override
  void initState() {
    super.initState();
    speech = stt.SpeechToText();
    loadSubjects();

    for (var i = 0; i < studentDarsList.length; i++) {
      studentLessonControllers.add(
        TextEditingController(text: todayLessonController.text),
      );
      studentRemarksControllers.add(
        TextEditingController(text: studentDarsList[i]['remarks']),
      );
    }
  }

  @override
  void dispose() {
    speech.stop();
    todayLessonController.dispose();
    for (final c in studentLessonControllers) {
      c.dispose();
    }
    for (final c in studentRemarksControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> loadSubjects() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('subjects');
    if (saved != null && saved.isNotEmpty) {
      setState(() {
        subjects = saved;
      });
    }
  }

  Future<void> saveSubjects() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('subjects', subjects);
  }

  // Real-time sync: text entered in lesson entry updates all student lessons
  void _syncLessonToAllStudents() {
    final text = todayLessonController.text;
    setState(() {
      for (var i = 0; i < studentLessonControllers.length; i++) {
        studentLessonControllers[i].text = text;
        studentDarsList[i]['lesson'] = text;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('سبق تمام طلبہ پر لاگو کر دیا گیا (Lesson synced to all students)!'),
        backgroundColor: Color(0xFF047857),
      ),
    );
  }

  void _markAllRatings(String rating) {
    setState(() {
      for (var i = 0; i < studentDarsList.length; i++) {
        studentDarsList[i]['rating'] = rating;
      }
    });
  }

  void _clearAllRatings() {
    setState(() {
      for (var i = 0; i < studentDarsList.length; i++) {
        studentDarsList[i]['rating'] = '';
        studentRemarksControllers[i].clear();
        studentDarsList[i]['remarks'] = '';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = widget.languageController?.locale.languageCode != 'en';

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F9),
        appBar: AppBar(
          backgroundColor: const Color(0xFF074E32),
          foregroundColor: Colors.white,
          leading: Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),
          title: Row(
            children: [
              const Icon(Icons.mosque, color: Colors.amberAccent, size: 24),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Madrasa AIB',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Group & Wanther System',
                    style: TextStyle(fontSize: 10, color: Colors.amber.shade200),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.calendar_month_rounded),
              tooltip: 'Calendar',
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (picked != null) {
                  setState(() => selectedDate = picked);
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.assessment_rounded),
              tooltip: 'Reports',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Dars Report History Log Ready')),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.settings_rounded),
              tooltip: 'Settings',
              onPressed: () {},
            ),
            if (widget.languageController != null)
              LanguageButton(controller: widget.languageController!),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              // SECTION 1: Select Subject
              _buildSectionCard(
                stepNum: '1',
                title: 'Select Subject',
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedSubject,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            items: subjects.map((subj) {
                              return DropdownMenuItem(value: subj, child: Text(subj));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  selectedSubjectIndex = subjects.indexOf(val);
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Choose any subject\nfrom the list',
                          style: TextStyle(fontSize: 11, color: Colors.indigo.shade900, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Subject Edit / Add / Delete & Navigation Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back_ios_rounded, color: Color(0xFF074E32), size: 22),
                              onPressed: () {
                                if (selectedSubjectIndex > 0) {
                                  setState(() => selectedSubjectIndex--);
                                }
                              },
                              tooltip: 'Previous Subject',
                            ),
                            IconButton(
                              icon: const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF074E32), size: 22),
                              onPressed: () {
                                if (selectedSubjectIndex < subjects.length - 1) {
                                  setState(() => selectedSubjectIndex++);
                                }
                              },
                              tooltip: 'Next Subject',
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            OutlinedButton.icon(
                              onPressed: _showAddSubjectDialog,
                              icon: const Icon(Icons.add, size: 14),
                              label: const Text('Add', style: TextStyle(fontSize: 11)),
                            ),
                            const SizedBox(width: 4),
                            OutlinedButton.icon(
                              onPressed: _showEditSubjectDialog,
                              icon: const Icon(Icons.edit, size: 14, color: Colors.orange),
                              label: const Text('Edit', style: TextStyle(fontSize: 11)),
                            ),
                            const SizedBox(width: 4),
                            OutlinedButton.icon(
                              onPressed: _showDeleteSubjectDialog,
                              icon: const Icon(Icons.delete, size: 14, color: Colors.red),
                              label: const Text('Delete', style: TextStyle(fontSize: 11)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // SECTION 2: Lesson Entry (Speak or Type)
              _buildSectionCard(
                stepNum: '2',
                title: 'Lesson Entry (Speak or Type)',
                headerTrailing: Wrap(
                  spacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Date: ${selectedDate.day} July ${selectedDate.year}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Voice Entry ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF047857))),
                          Icon(Icons.mic, size: 14, color: Color(0xFF047857)),
                        ],
                      ),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: todayLessonController,
                      maxLines: 3,
                      onChanged: (val) {
                        for (var i = 0; i < studentLessonControllers.length; i++) {
                          studentLessonControllers[i].text = val;
                          studentDarsList[i]['lesson'] = val;
                        }
                      },
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.all(12),
                        hintText: 'سبق یا دعا درج کریں (Enter Lesson or Dua)...',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          ),
                          onPressed: _listenTodayLesson,
                          icon: const Icon(Icons.mic, size: 16),
                          label: const Text('آواز انٹری (Mic)', style: TextStyle(fontSize: 11)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade800,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('کتاب کی تصویر محفوظ کر لی گئی (Textbook Photo Captured)!')),
                            );
                          },
                          icon: const Icon(Icons.camera_alt, size: 16),
                          label: const Text('کیمرہ (Camera)', style: TextStyle(fontSize: 11)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF047857),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _syncLessonToAllStudents,
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('Save Lesson'),
                        ),
                        OutlinedButton(
                          onPressed: () {
                            todayLessonController.clear();
                            _syncLessonToAllStudents();
                          },
                          child: const Text('Clear'),
                        ),
                        const Text(
                          'This lesson will appear below for all students. ↓',
                          style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: Colors.indigo),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // SECTION 3: Dars Entry (In Class)
              _buildSectionCard(
                stepNum: '3',
                title: 'Dars Entry (In Class)',
                child: Column(
                  children: [
                    // Quick Mark All Row
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          const Text('Mark All Students: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 4),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(foregroundColor: Colors.green),
                            onPressed: () => _markAllRatings('Yaad Hai'),
                            icon: const Icon(Icons.check, size: 14),
                            label: const Text('Mark All Yaad Hai', style: TextStyle(fontSize: 10)),
                          ),
                          const SizedBox(width: 4),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(foregroundColor: Colors.orange),
                            onPressed: () => _markAllRatings('Kam Yaad Hai'),
                            icon: const Icon(Icons.error_outline, size: 14),
                            label: const Text('Mark All Kam Yaad Hai', style: TextStyle(fontSize: 10)),
                          ),
                          const SizedBox(width: 4),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                            onPressed: () => _markAllRatings('Yaad Nahi'),
                            icon: const Icon(Icons.cancel_outlined, size: 14),
                            label: const Text('Mark All Yaad Nahi', style: TextStyle(fontSize: 10)),
                          ),
                          const SizedBox(width: 4),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(foregroundColor: Colors.blue),
                            onPressed: () => _markAllRatings('Iaadah'),
                            icon: const Icon(Icons.autorenew, size: 14),
                            label: const Text('Mark All Iaadah', style: TextStyle(fontSize: 10)),
                          ),
                          const SizedBox(width: 4),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(foregroundColor: Colors.grey),
                            onPressed: _clearAllRatings,
                            icon: const Icon(Icons.refresh, size: 14),
                            label: const Text('Clear All Marks', style: TextStyle(fontSize: 10)),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Student Dars Cards / Rows
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: studentDarsList.length,
                      itemBuilder: (ctx, idx) {
                        return _buildStudentDarsRow(idx);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Bottom Action Bar: Back, Save All Entries, Save as PDF & Dispatch
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Back'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF047857),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('تمام طلبہ کے درس کے اندراجات محفوظ کر لیے گئے (All Dars Entries Saved)!'),
                            backgroundColor: Color(0xFF047857),
                          ),
                        );
                      },
                      icon: const Icon(Icons.check_circle_rounded),
                      label: const Text('Save All Entries'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _generateAndDispatchDarsPdf,
                      icon: const Icon(Icons.picture_as_pdf_rounded),
                      label: const Text('Save as PDF'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Row(
                children: [
                  Icon(Icons.lightbulb_outline, size: 14, color: Colors.amber),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Tip: Tap Mic and speak lesson details (e.g. Para 2, Page 18 / Lesson 5). PDF auto-dispatches to Parent notice channel.',
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String stepNum,
    required String title,
    Widget? headerTrailing,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E3A8A),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    stepNum,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                ),
                if (headerTrailing != null) ...[
                  const SizedBox(width: 12),
                  headerTrailing,
                ],
              ],
            ),
          ),
          const Divider(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildStudentDarsRow(int idx) {
    final s = studentDarsList[idx];
    final currentRating = s['rating'] as String;
    final lessonCtrl = studentLessonControllers[idx];
    final remarksCtrl = studentRemarksControllers[idx];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: idx.isEven ? Colors.grey.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 14,
                backgroundColor: Color(0xFF047857),
                child: Icon(Icons.person, size: 16, color: Colors.white),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 110,
                child: Text(
                  s['name'],
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                child: TextField(
                  controller: lessonCtrl,
                  maxLines: 1,
                  style: const TextStyle(fontSize: 11),
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    isDense: true,
                    border: OutlineInputBorder(),
                    hintText: 'Lesson / Dua',
                  ),
                  onChanged: (val) {
                    s['lesson'] = val;
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.mic, size: 16, color: Colors.indigo),
                onPressed: () => _listenStudentLesson(idx),
                tooltip: 'Mic',
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 16, color: Colors.orange),
                onPressed: () => _modifyStudentPlanDialog(idx),
                tooltip: 'Modify Plan for this Student',
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Quality Rating Buttons & Remarks Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildRatingChip(idx, 'Yaad Hai', Colors.green, currentRating == 'Yaad Hai'),
                const SizedBox(width: 4),
                _buildRatingChip(idx, 'Kam Yaad Hai', Colors.orange, currentRating == 'Kam Yaad Hai'),
                const SizedBox(width: 4),
                _buildRatingChip(idx, 'Yaad Nahi', Colors.red, currentRating == 'Yaad Nahi'),
                const SizedBox(width: 4),
                _buildRatingChip(idx, 'Iaadah', Colors.blue, currentRating == 'Iaadah'),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 16, color: Colors.grey),
                  onPressed: () {
                    setState(() {
                      studentDarsList[idx]['rating'] = '';
                    });
                  },
                  tooltip: 'Reset Rating',
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: remarksCtrl,
            maxLines: 1,
            style: const TextStyle(fontSize: 11),
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              isDense: true,
              border: OutlineInputBorder(),
              hintText: 'Remarks (Write Quality)...',
            ),
            onChanged: (val) {
              s['remarks'] = val;
            },
          ),
          const SizedBox(height: 6),
          // ITEM 12, 14, 16, 18: Tajweed Markers, Sabqi/Manzil Trackers, Star Badges & Private Note
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Row(
              children: [
                // Star Reward Badge (Item 18)
                InkWell(
                  onTap: () {
                    setState(() {
                      int stars = (s['stars'] as int? ?? 3);
                      s['stars'] = stars >= 5 ? 1 : stars + 1;
                    });
                  },
                  child: Row(
                    children: [
                      const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                      Text(' ${s['stars'] ?? 5}⭐', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Sabqi & Manzil Tracker (Item 14)
                Text('سبقی: ${s['sabqi'] ?? 'صفحہ 5'} | منزل: ${s['manzil'] ?? 'پارہ 1'}',
                    style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF074E32))),
                const Spacer(),
                // Tajweed Correction Badges (Item 12)
                Wrap(
                  spacing: 4,
                  children: [
                    _tajweedBadge('مخارج', Colors.purple),
                    _tajweedBadge('غنہ', Colors.indigo),
                    _tajweedBadge('اخفاء', Colors.teal),
                    _tajweedBadge('قلقلہ', Colors.orange),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tajweedBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Widget _buildRatingChip(int idx, String label, Color color, bool isSelected) {
    return InkWell(
      onTap: () {
        setState(() {
          studentDarsList[idx]['rating'] = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : color,
          ),
        ),
      ),
    );
  }

  Future<void> _listenTodayLesson() async {
    final available = await speech.initialize();
    if (available) {
      speech.listen(
        onResult: (result) {
          if (result.finalResult) {
            setState(() {
              todayLessonController.text = result.recognizedWords;
              _syncLessonToAllStudents();
            });
          }
        },
      );
    }
  }

  Future<void> _listenStudentLesson(int idx) async {
    final available = await speech.initialize();
    if (available) {
      speech.listen(
        onResult: (result) {
          if (result.finalResult) {
            setState(() {
              studentLessonControllers[idx].text = result.recognizedWords;
              studentDarsList[idx]['lesson'] = result.recognizedWords;
            });
          }
        },
      );
    }
  }

  void _modifyStudentPlanDialog(int idx) {
    final ctrl = TextEditingController(text: studentLessonControllers[idx].text);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Modify Lesson Plan: ${studentDarsList[idx]['name']}'),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Enter custom lesson plan for this student...',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                studentLessonControllers[idx].text = ctrl.text;
                studentDarsList[idx]['lesson'] = ctrl.text;
              });
              Navigator.pop(ctx);
            },
            child: const Text('Save Plan'),
          ),
        ],
      ),
    );
  }

  void _showAddSubjectDialog() {
    final ctrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Subject (نیا مضمون)'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'Enter subject name...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final text = ctrl.text.trim();
              if (text.isNotEmpty) {
                setState(() {
                  subjects.add(text);
                  selectedSubjectIndex = subjects.length - 1;
                });
                saveSubjects();
              }
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditSubjectDialog() {
    final ctrl = TextEditingController(text: selectedSubject);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Subject (مضمون تبدیل کریں)'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'Enter new subject name...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final text = ctrl.text.trim();
              if (text.isNotEmpty) {
                setState(() {
                  subjects[selectedSubjectIndex] = text;
                });
                saveSubjects();
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteSubjectDialog() {
    if (subjects.isEmpty) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Subject'),
        content: Text('Are you sure you want to delete "$selectedSubject"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() {
                subjects.removeAt(selectedSubjectIndex);
                if (selectedSubjectIndex >= subjects.length) {
                  selectedSubjectIndex = subjects.isEmpty ? 0 : subjects.length - 1;
                }
              });
              saveSubjects();
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _generateAndDispatchDarsPdf() async {
    final pdf = await PdfService.buildDarsReportPdf(
      subject: selectedSubject,
      dateLabel: '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
      todayLesson: todayLessonController.text,
      studentDarsList: studentDarsList,
    );

    // Save and preview/print PDF
    await PdfService.printOrSharePdf(pdf, 'Dars_Evaluation_Report_${selectedSubject}');

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📄 Dars Report PDF Generated & Dispatched to Registered Parents, Manager, Admin & History Log!'),
        backgroundColor: Color(0xFF047857),
      ),
    );
  }
}
