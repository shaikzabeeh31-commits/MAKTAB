import 'package:flutter/material.dart';
import 'app_localizations.dart';

class StudentResult {
  final String rollNo;
  final String name;
  final String fatherName;
  final String className;
  final int quranScore; // out of 100
  final int tajweedScore; // out of 100
  final int diniyatScore; // out of 100
  final int arabicScore; // out of 100

  StudentResult({
    required this.rollNo,
    required this.name,
    required this.fatherName,
    required this.className,
    required this.quranScore,
    required this.tajweedScore,
    required this.diniyatScore,
    required this.arabicScore,
  });

  int get totalMarks => quranScore + tajweedScore + diniyatScore + arabicScore;
  double get percentage => (totalMarks / 400) * 100;

  String get grade {
    final p = percentage;
    if (p >= 90) return 'Mumtaz (ممتاز / A+)';
    if (p >= 75) return 'Jayyid Jiddan (جید جداً / A)';
    if (p >= 60) return 'Jayyid (جید / B)';
    if (p >= 40) return 'Maqbool (مقبول / C)';
    return 'Rasib (راسب / Fail)';
  }

  Color get gradeColor {
    final p = percentage;
    if (p >= 90) return const Color(0xFF047857);
    if (p >= 75) return Colors.blue.shade800;
    if (p >= 60) return Colors.amber.shade900;
    if (p >= 40) return Colors.orange.shade800;
    return Colors.red.shade800;
  }
}

List<StudentResult> _getSampleResults() {
  return [
    StudentResult(
      rollNo: '101',
      name: 'Muhammad Abdullah',
      fatherName: 'Tariq Mahmood',
      className: 'Class 7 (A)',
      quranScore: 95,
      tajweedScore: 92,
      diniyatScore: 90,
      arabicScore: 88,
    ),
    StudentResult(
      rollNo: '102',
      name: 'Zaid Ibn Ali',
      fatherName: 'Ali Hassan',
      className: 'Class 7 (A)',
      quranScore: 88,
      tajweedScore: 85,
      diniyatScore: 82,
      arabicScore: 80,
    ),
    StudentResult(
      rollNo: '103',
      name: 'Fatima Az-Zahra',
      fatherName: 'Usman Ghani',
      className: 'Class 6 (B)',
      quranScore: 98,
      tajweedScore: 96,
      diniyatScore: 95,
      arabicScore: 94,
    ),
    StudentResult(
      rollNo: '104',
      name: 'Umar Farooq',
      fatherName: 'Khalid Masood',
      className: 'Class 6 (B)',
      quranScore: 72,
      tajweedScore: 68,
      diniyatScore: 70,
      arabicScore: 65,
    ),
    StudentResult(
      rollNo: '105',
      name: 'Aisha Siddiqua',
      fatherName: 'Abu Bakr',
      className: 'Class 5 (A)',
      quranScore: 91,
      tajweedScore: 89,
      diniyatScore: 93,
      arabicScore: 87,
    ),
  ];
}

class ResultsScreen extends StatefulWidget {
  final LanguageController languageController;

  const ResultsScreen({super.key, required this.languageController});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  String _selectedClass = 'All';
  String _selectedTerm = 'Annual Exam (سالانہ امتحان)';
  final List<StudentResult> _results = _getSampleResults();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.languageController,
      builder: (context, _) {
        final loc = AppLocalizations.of(context);
        final filtered = _results.where((r) {
          if (_selectedClass != 'All' && r.className != _selectedClass) return false;
          return true;
        }).toList();

        final double avgPercentage = filtered.isEmpty
            ? 0
            : filtered.map((r) => r.percentage).reduce((a, b) => a + b) / filtered.length;
        final int passCount = filtered.where((r) => r.percentage >= 40).length;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            title: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('نتائج و تعلیمی کارکردگی (Academic Results)',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                Text('Manager & Admin Results Portal',
                    style: TextStyle(fontSize: 10.5, color: Colors.white70)),
              ],
            ),
            backgroundColor: const Color(0xFF0F172A),
            foregroundColor: Colors.white,
            actions: [
              LanguageButton(controller: widget.languageController),
            ],
          ),
          body: Column(
        children: [
          // Filter Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedTerm,
                        decoration: const InputDecoration(
                          labelText: 'Exam Term (امتحانی سیشن)',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'Annual Exam (سالانہ امتحان)',
                              child: Text('Annual Exam (سالانہ امتحان)', style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(
                              value: 'Mid-Term Exam (ششماہی)',
                              child: Text('Mid-Term Exam (ششماہی)', style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(
                              value: 'Quarterly Test (سہ ماہی)',
                              child: Text('Quarterly Test (سہ ماہی)', style: TextStyle(fontSize: 12))),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _selectedTerm = v);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedClass,
                        decoration: const InputDecoration(
                          labelText: 'Class (کلاس)',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'All', child: Text('All Classes', style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: 'Class 7 (A)', child: Text('Class 7 (A)', style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: 'Class 6 (B)', child: Text('Class 6 (B)', style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: 'Class 5 (A)', child: Text('Class 5 (A)', style: TextStyle(fontSize: 12))),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _selectedClass = v);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Stats Summary Banner
                Row(
                  children: [
                    _statBanner('کُل طلبہ', '${filtered.length}', Colors.blue),
                    const SizedBox(width: 6),
                    _statBanner('کامیاب طلبہ', '$passCount / ${filtered.length}', Colors.green),
                    const SizedBox(width: 6),
                    _statBanner('اوسط فیصد', '${avgPercentage.toStringAsFixed(1)}%', Colors.amber.shade900),
                  ],
                ),
                // Top 3 Position Holders Banner
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(top: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF074E32), Color(0xFF047857)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.emoji_events_rounded, color: Colors.amberAccent, size: 20),
                          SizedBox(width: 8),
                          Text('پوزیشن ہولڈر طلبہ (Top 3 Rank Position Holders 🏆)',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _positionBadge('🥇 1st', 'Fatima Az-Zahra (95.7%)'),
                            const SizedBox(width: 6),
                            _positionBadge('🥈 2nd', 'Muhammad Abdullah (91.2%)'),
                            const SizedBox(width: 6),
                            _positionBadge('🥉 3rd', 'Aisha Siddiqua (90.0%)'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Student Results List
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('کوئی رزلٹ نہیں ملا'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final r = filtered[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: const Color(0xFF0F172A),
                                    child: Text(r.rollNo,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(r.name,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold, fontSize: 14)),
                                      Text('والد: ${r.fatherName} | ${r.className}',
                                          style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                    ],
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: r.gradeColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: r.gradeColor),
                                    ),
                                    child: Text(
                                      r.grade,
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: r.gradeColor),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 16),
                              // Marks Grid
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _subjectScore('قرآن و حفظ', r.quranScore),
                                  _subjectScore('تجوید', r.tajweedScore),
                                  _subjectScore('دینیات', r.diniyatScore),
                                  _subjectScore('عربی', r.arabicScore),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('مجموعی نمبر: ${r.totalMarks} / 400',
                                      style: const TextStyle(
                                          fontSize: 11.5, fontWeight: FontWeight.bold)),
                                  Text('فیصد: ${r.percentage.toStringAsFixed(1)}%',
                                      style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.bold,
                                          color: r.gradeColor)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
      },
    );
  }

  Widget _positionBadge(String rank, String studentInfo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Text(rank, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.amberAccent)),
          Text(studentInfo, style: const TextStyle(fontSize: 10, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _statBanner(String label, String val, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(val,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: const TextStyle(fontSize: 9.5, color: Colors.black87)),
          ],
        ),
      ),
    );
  }

  Widget _subjectScore(String title, int score) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        const SizedBox(height: 2),
        Text('$score',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
      ],
    );
  }
}
