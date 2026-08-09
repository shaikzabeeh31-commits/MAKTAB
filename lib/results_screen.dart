import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
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

  String getGradeLabel(bool isEn) {
    final p = percentage;
    if (p >= 90) return isEn ? 'Mumtaz (A+)' : 'ممتاز (A+)';
    if (p >= 75) return isEn ? 'Jayyid Jiddan (A)' : 'جید جداً (A)';
    if (p >= 60) return isEn ? 'Jayyid (B)' : 'جید (B)';
    if (p >= 40) return isEn ? 'Maqbool (C)' : 'مقبول (C)';
    return isEn ? 'Rasib (Fail)' : 'راسب (Fail)';
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

  List<Map<String, dynamic>> _teacherReports = [];
  bool _loadingReports = true;

  @override
  void initState() {
    super.initState();
    _loadTeacherReports();
  }

  Future<void> _loadTeacherReports() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reportsStr = prefs.getString('teacher_reports');
      if (reportsStr != null && reportsStr.isNotEmpty) {
        final decoded = jsonDecode(reportsStr) as List<dynamic>;
        setState(() {
          _teacherReports = decoded.map((item) => Map<String, dynamic>.from(item as Map)).toList().reversed.toList(); // Newest first
        });
      }
    } catch (_) {}
    setState(() {
      _loadingReports = false;
    });
  }

  Future<void> _clearReports() async {
    final isEn = widget.languageController.locale.languageCode == 'en';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEn ? 'Clear Reports History?' : 'رپورٹ ہسٹری صاف کریں؟'),
        content: Text(isEn ? 'Are you sure you want to delete all received teacher reports?' : 'کیا آپ واقعی اساتذہ کی تمام موصولہ رپورٹیں حذف کرنا چاہتے ہیں؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(isEn ? 'Cancel' : 'منسوخ')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(isEn ? 'Clear All' : 'صاف کریں')),
        ],
      ),
    );
    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('teacher_reports');
      setState(() {
        _teacherReports.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.languageController,
      builder: (context, _) {
        final loc = AppLocalizations.of(context);
        final isEn = loc.locale.languageCode == 'en';
        final filtered = _results.where((r) {
          if (_selectedClass != 'All' && r.className != _selectedClass) return false;
          return true;
        }).toList();

        final double avgPercentage = filtered.isEmpty
            ? 0
            : filtered.map((r) => r.percentage).reduce((a, b) => a + b) / filtered.length;
        final int passCount = filtered.where((r) => r.percentage >= 40).length;

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            appBar: AppBar(
              title: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'assets/images/app_logo.jpg',
                      width: 32,
                      height: 32,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(isEn ? 'Results & Reports' : 'نتائج و کارکردگی',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      Text('Manager & Admin Results Portal',
                          style: TextStyle(fontSize: 10.5, color: Colors.white70)),
                    ],
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: Colors.white,
              actions: [
                if (_teacherReports.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
                    tooltip: isEn ? 'Clear All Reports' : 'رپورٹیں صاف کریں',
                    onPressed: _clearReports,
                  ),
                LanguageButton(controller: widget.languageController),
              ],
              bottom: TabBar(
                tabs: [
                  Tab(icon: const Icon(Icons.school_rounded), text: isEn ? 'Academic Results' : 'تعلیمی نتائج'),
                  Tab(icon: const Icon(Icons.description_rounded), text: isEn ? 'Teacher Reports' : 'اساتذہ کی رپورٹیں'),
                ],
                labelColor: Colors.amberAccent,
                unselectedLabelColor: Colors.white70,
                indicatorColor: Colors.amberAccent,
                indicatorWeight: 3,
              ),
            ),
            body: TabBarView(
              children: [
                _buildAcademicResultsTab(filtered, passCount, avgPercentage, loc),
                _buildTeacherReportsTab(loc),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAcademicResultsTab(List<StudentResult> filtered, int passCount, double avgPercentage, AppLocalizations loc) {
    final isEn = loc.locale.languageCode == 'en';
    return Column(
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
                      decoration: InputDecoration(
                        labelText: isEn ? 'Exam Term' : 'امتحانی سیشن',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      items: [
                        DropdownMenuItem(
                            value: 'Annual Exam (سالانہ امتحان)',
                            child: Text(isEn ? 'Annual Exam' : 'سالانہ امتحان', style: const TextStyle(fontSize: 12))),
                        DropdownMenuItem(
                            value: 'Mid-Term Exam (ششماہی)',
                            child: Text(isEn ? 'Mid-Term Exam' : 'ششماہی', style: const TextStyle(fontSize: 12))),
                        DropdownMenuItem(
                            value: 'Quarterly Test (سہ ماہی)',
                            child: Text(isEn ? 'Quarterly Test' : 'سہ ماہی', style: const TextStyle(fontSize: 12))),
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
                      decoration: InputDecoration(
                        labelText: isEn ? 'Class' : 'کلاس',
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
              // Bottom Position Holders Banner (Top 3)
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
                    Row(
                      children: [
                        const Icon(Icons.emoji_events_rounded, color: Colors.amberAccent, size: 20),
                        const SizedBox(width: 8),
                        Text(isEn ? 'Top 3 Position Holders 🏆' : 'پوزیشن ہولڈر طلبہ 🏆',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
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
                                    r.getGradeLabel(isEn),
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
    );
  }

  Widget _buildTeacherReportsTab(AppLocalizations loc) {
    final isEn = loc.locale.languageCode == 'en';
    if (_loadingReports) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_teacherReports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_late_rounded, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              isEn ? 'No reports sent by teachers yet' : 'اساتذہ کی طرف سے کوئی رپورٹ موصول نہیں ہوئی',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _teacherReports.length,
      itemBuilder: (ctx, i) {
        final r = _teacherReports[i];
        final type = r['type'] ?? 'attendance';
        final isAttendance = type == 'attendance';
        final details = r['details'] as Map<String, dynamic>? ?? {};
        final sender = r['senderName'] ?? (isEn ? 'Teacher' : 'استاد');
        final timestampStr = r['dateTime']?.toString().split('.')[0] ?? '';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: isAttendance ? Colors.blue.shade100 : Colors.green.shade100,
              child: Icon(
                isAttendance ? Icons.fact_check_rounded : Icons.payments_rounded,
                color: isAttendance ? Colors.blue.shade900 : Colors.green.shade900,
              ),
            ),
            title: Text(
              isEn ? (isAttendance ? 'Attendance Report' : 'Fee Report') : (isAttendance ? 'حاضری رپورٹ' : 'فیس کلیکشن رپورٹ'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: Text(
              'منجانب: $sender | $timestampStr',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            childrenPadding: const EdgeInsets.all(14),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isAttendance ? Colors.blue.shade50 : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: isAttendance
                      ? [
                          _reportStat(isEn ? 'Date' : 'تاریخ', '${details['date'] ?? '-'}'),
                          _reportStat(isEn ? 'Total' : 'کل طلبہ', '${details['total'] ?? 0}'),
                          _reportStat(isEn ? 'Present' : 'حاضر', '${details['present'] ?? 0}', Colors.green),
                          _reportStat(isEn ? 'Absent' : 'غیر حاضر', '${details['absent'] ?? 0}', Colors.red),
                          _reportStat(isEn ? 'Leave' : 'رخصت', '${details['leave'] ?? 0}', Colors.orange),
                        ]
                      : [
                          _reportStat(isEn ? 'Month' : 'مہینہ', '${details['month'] ?? '-'}'),
                          _reportStat(isEn ? 'Total' : 'کل طلبہ', '${details['total'] ?? 0}'),
                          _reportStat(isEn ? 'Paid' : 'ادا شدہ', '${details['paid'] ?? 0}', Colors.green),
                          _reportStat(isEn ? 'Due' : 'واجب الادا', '${details['due'] ?? 0}', Colors.red),
                        ],
                ),
              ),
              const SizedBox(height: 12),
              if (isAttendance) ...[
                Text(isEn ? 'Absent Students:' : 'غیر حاضر طلبہ کی فہرست:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blueGrey)),
                const SizedBox(height: 6),
                if ((details['absentees'] as List? ?? []).isEmpty)
                  Text(isEn ? 'All present' : 'کوئی غیر حاضر نہیں ہے', style: TextStyle(fontSize: 11, color: Colors.green))
                else
                  Wrap(
                    spacing: 6,
                    children: (details['absentees'] as List? ?? []).map<Widget>((name) {
                      return Chip(
                        label: Text(name.toString(), style: const TextStyle(fontSize: 10.5)),
                        backgroundColor: Colors.red.shade50,
                        side: BorderSide(color: Colors.red.shade100),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      );
                    }).toList(),
                  ),
              ] else ...[
                Text(isEn ? 'Fee Due Students:' : 'بقایا فیس والے طلبہ:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blueGrey)),
                const SizedBox(height: 6),
                if ((details['dueStudentsList'] as List? ?? []).isEmpty)
                  Text(isEn ? 'All paid' : 'تمام طلبہ کی فیس جمع ہے', style: TextStyle(fontSize: 11, color: Colors.green))
                else
                  Wrap(
                    spacing: 6,
                    children: (details['dueStudentsList'] as List? ?? []).map<Widget>((name) {
                      return Chip(
                        label: Text(name.toString(), style: const TextStyle(fontSize: 10.5)),
                        backgroundColor: Colors.orange.shade50,
                        side: BorderSide(color: Colors.orange.shade100),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      );
                    }).toList(),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _reportStat(String label, String val, [Color color = Colors.black87]) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 9.5, color: Colors.grey)),
        const SizedBox(height: 3),
        Text(
          val,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
        ),
      ],
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
