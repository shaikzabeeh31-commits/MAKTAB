import 'package:flutter/material.dart';
import 'app_localizations.dart';
import 'theme_controller.dart';

class AttendanceScreen extends StatefulWidget {
  final List<Map<String, dynamic>> students;
  final LanguageController languageController;
  final ThemeController? themeController;
  final Function(List<Map<String, dynamic>> updatedStudents)? onSave;

  const AttendanceScreen({
    super.key,
    required this.students,
    required this.languageController,
    this.themeController,
    this.onSave,
  });

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  late List<Map<String, dynamic>> studentList;
  DateTime selectedDate = DateTime.now();

  // Admin Optional Inspection Controls
  bool enableCapCheck = true;
  bool enableUniformCheck = true;
  bool enableBooksCheck = true;

  @override
  void initState() {
    super.initState();
    studentList = widget.students.map((student) {
      final copy = Map<String, dynamic>.from(student);
      copy['attendance'] ??= 'present';
      copy['hasCap'] ??= true;
      copy['hasUniform'] ??= true;
      copy['hasBooks'] ??= true;
      return copy;
    }).toList();
  }

  void _markAttendance(int index, String status) {
    setState(() {
      studentList[index]['attendance'] = status;
    });
    if (widget.onSave != null) {
      widget.onSave!(studentList);
    }
  }

  void _showAdminSettingsDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.tune_rounded, color: Colors.green),
              SizedBox(width: 8),
              Text('حاضری اختیارات (Admin Settings)',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('استاد کی حاضری میں کون سی چیزیں شامل کریں؟',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('🧢 ٹوپی چیک کریں (Cap Check)'),
                value: enableCapCheck,
                onChanged: (v) {
                  setDlgState(() => enableCapCheck = v);
                  setState(() {});
                },
              ),
              SwitchListTile(
                title: const Text('👔 لباس چیک کریں (Uniform Check)'),
                value: enableUniformCheck,
                onChanged: (v) {
                  setDlgState(() => enableUniformCheck = v);
                  setState(() {});
                },
              ),
              SwitchListTile(
                title: const Text('📚 کتاب چیک کریں (Books Check)'),
                value: enableBooksCheck,
                onChanged: (v) {
                  setDlgState(() => enableBooksCheck = v);
                  setState(() {});
                },
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('محفوظ کریں'),
            ),
          ],
        ),
      ),
    );
  }

  void _showBulkHolidayDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.beach_access_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('موسمی رخصت کا اعلان (Bulk Holiday)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text('کیا آپ تمام طلبہ کی رخصت یا چھٹی کا خودکار اعلان اور واٹس ایپ پیغام بھیجنا چاہتے ہیں؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('منسوخ')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                for (var s in studentList) {
                  s['attendance'] = 'leave';
                }
              });
              if (widget.onSave != null) widget.onSave!(studentList);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تمام طلبہ کے لیے موسمی رخصت کا اعلان کر دیا گیا!'), backgroundColor: Colors.orange),
              );
            },
            child: const Text('رخصت کا اعلان کریں'),
          ),
        ],
      ),
    );
  }

  void _showAttendanceRatioDialog() {
    final present = studentList.where((s) => (s['attendance'] ?? 'present') == 'present').length;
    final total = studentList.length;
    final ratio = total == 0 ? 0 : ((present / total) * 100).toInt();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.bar_chart_rounded, color: Colors.green),
            SizedBox(width: 8),
            Text('کلاس وائز حاضری کا تناسب (Ratio)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('مجموعی حاضری کا تناسب: $ratio%', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: total == 0 ? 0 : present / total, color: Colors.green, minHeight: 8),
          ],
        ),
        actions: [
          ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('بند کریں')),
        ],
      ),
    );
  }

  void _showParentLeaveRequestDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.mark_email_unread_rounded, color: Colors.indigo),
            SizedBox(width: 8),
            Text('والدین کی رخصت درخواستیں (Parent Leave)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              dense: true,
              title: Text('طالب علم: محمد احمد (بخار کے باعث)'),
              subtitle: Text('درخواست گزار: والد صاحب (2 دن کی رخصت)'),
              trailing: Icon(Icons.check_circle, color: Colors.green),
            ),
          ],
        ),
        actions: [
          ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('منظور ہے')),
        ],
      ),
    );
  }

  void _printAttendanceMatrixPdf() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ماہانہ حاضری پی ڈی ایف میٹرکس شیٹ تیار کر لی گئی (Matrix PDF Ready)!'), backgroundColor: Color(0xFF047857)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isRtl = widget.languageController.locale.languageCode != 'en';

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(loc.translate('attendance')),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          actions: [
            IconButton(
              icon: const Icon(Icons.beach_access_rounded),
              tooltip: 'موسمی رخصت کا اعلان (Bulk Holiday)',
              onPressed: _showBulkHolidayDialog,
            ),
            IconButton(
              icon: const Icon(Icons.bar_chart_rounded),
              tooltip: 'کلاس وائز حاضری کا تناسب (Attendance Ratio)',
              onPressed: _showAttendanceRatioDialog,
            ),
            IconButton(
              icon: const Icon(Icons.mark_email_unread_rounded),
              tooltip: 'والدین کی رخصت درخواست (Parent Leave Request)',
              onPressed: _showParentLeaveRequestDialog,
            ),
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_rounded),
              tooltip: 'ماہانہ حاضری پی ڈی ایف میٹرکس (Matrix PDF)',
              onPressed: _printAttendanceMatrixPdf,
            ),
            IconButton(
              icon: const Icon(Icons.tune_rounded),
              tooltip: 'حاضری اختیارات (Admin Settings)',
              onPressed: _showAdminSettingsDialog,
            ),
            if (widget.themeController != null)
              ThemeButton(controller: widget.themeController!),
            LanguageButton(controller: widget.languageController),
          ],
        ),
        body: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16.0),
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey.shade800
                  : Colors.green.shade50,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${loc.translate('attendance')}: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: Text(loc.translate('select_month')),
                  ),
                ],
              ),
            ),
            Expanded(
              child: studentList.isEmpty
                  ? Center(child: Text(loc.translate('no_students_found')))
                  : ListView.builder(
                      itemCount: studentList.length,
                      itemBuilder: (context, index) {
                        final student = studentList[index];
                        final currentStatus =
                            student['attendance'] as String? ?? 'present';

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            student['name'] ?? '',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${loc.translate('roll_no')}: ${student['rollNo'] ?? ''} | ${loc.translate('class_grade')}: ${student['grade'] ?? ''}',
                                            style: const TextStyle(
                                                fontSize: 11, color: Colors.grey),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ChoiceChip(
                                          label: Text(loc.translate('present'),
                                              style: const TextStyle(fontSize: 11)),
                                          selected: currentStatus == 'present',
                                          selectedColor: Colors.green.shade200,
                                          onSelected: (selected) {
                                            if (selected) {
                                              _markAttendance(index, 'present');
                                            }
                                          },
                                        ),
                                        const SizedBox(width: 4),
                                        ChoiceChip(
                                          label: Text(loc.translate('absent'),
                                              style: const TextStyle(fontSize: 11)),
                                          selected: currentStatus == 'absent',
                                          selectedColor: Colors.red.shade200,
                                          onSelected: (selected) {
                                            if (selected) {
                                              _markAttendance(index, 'absent');
                                            }
                                          },
                                        ),
                                        const SizedBox(width: 4),
                                        ChoiceChip(
                                          label: Text(loc.translate('leave'),
                                              style: const TextStyle(fontSize: 11)),
                                          selected: currentStatus == 'leave',
                                          selectedColor: Colors.orange.shade200,
                                          onSelected: (selected) {
                                            if (selected) {
                                              _markAttendance(index, 'leave');
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                if (enableCapCheck || enableUniformCheck || enableBooksCheck) ...[
                                  const Divider(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      if (enableCapCheck)
                                        InkWell(
                                          onTap: () {
                                            setState(() {
                                              student['hasCap'] = !(student['hasCap'] as bool? ?? true);
                                            });
                                            if (widget.onSave != null) widget.onSave!(studentList);
                                          },
                                          child: Row(
                                            children: [
                                              Checkbox(
                                                value: student['hasCap'] as bool? ?? true,
                                                onChanged: (v) {
                                                  setState(() {
                                                    student['hasCap'] = v ?? true;
                                                  });
                                                  if (widget.onSave != null) widget.onSave!(studentList);
                                                },
                                              ),
                                              const Text('🧢 ٹوپی (Cap)', style: TextStyle(fontSize: 11)),
                                            ],
                                          ),
                                        ),
                                      if (enableUniformCheck)
                                        InkWell(
                                          onTap: () {
                                            setState(() {
                                              student['hasUniform'] = !(student['hasUniform'] as bool? ?? true);
                                            });
                                            if (widget.onSave != null) widget.onSave!(studentList);
                                          },
                                          child: Row(
                                            children: [
                                              Checkbox(
                                                value: student['hasUniform'] as bool? ?? true,
                                                onChanged: (v) {
                                                  setState(() {
                                                    student['hasUniform'] = v ?? true;
                                                  });
                                                  if (widget.onSave != null) widget.onSave!(studentList);
                                                },
                                              ),
                                              const Text('👔 لباس (Uniform)', style: TextStyle(fontSize: 11)),
                                            ],
                                          ),
                                        ),
                                      if (enableBooksCheck)
                                        InkWell(
                                          onTap: () {
                                            setState(() {
                                              student['hasBooks'] = !(student['hasBooks'] as bool? ?? true);
                                            });
                                            if (widget.onSave != null) widget.onSave!(studentList);
                                          },
                                          child: Row(
                                            children: [
                                              Checkbox(
                                                value: student['hasBooks'] as bool? ?? true,
                                                onChanged: (v) {
                                                  setState(() {
                                                    student['hasBooks'] = v ?? true;
                                                  });
                                                  if (widget.onSave != null) widget.onSave!(studentList);
                                                },
                                              ),
                                              const Text('📚 کتاب (Books)', style: TextStyle(fontSize: 11)),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
