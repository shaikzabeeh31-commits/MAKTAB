import 'package:flutter/material.dart';
import 'app_localizations.dart';
import 'theme_controller.dart';

class AnalyticsScreen extends StatelessWidget {
  final List<Map<String, dynamic>> students;
  final LanguageController languageController;
  final ThemeController themeController;
  final Function(Map<String, dynamic> student, String type)? onSendMessage;

  const AnalyticsScreen({
    super.key,
    required this.students,
    required this.languageController,
    required this.themeController,
    this.onSendMessage,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isRtl = languageController.locale.languageCode != 'en';

    final totalStudents = students.length;
    final presentStudents =
        students.where((s) => s['isPresent'] == true).length;
    final absentStudentsList =
        students.where((s) => s['isPresent'] == false).toList();
    final absentStudentsCount = absentStudentsList.length;

    final attendanceRate = totalStudents == 0
        ? 0.0
        : ((presentStudents / totalStudents) * 100);

    // Calculate Fees
    double totalPaid = 0;
    double totalDue = 0;

    for (final s in students) {
      final amount = double.tryParse(s['feeAmount']?.toString() ?? '0') ?? 0;
      final status = s['feeStatus']?.toString() ?? 'due';
      if (status == 'paid') {
        totalPaid += amount;
      } else {
        totalDue += amount;
      }
    }

    // Detect students absent for 3+ consecutive days or flagged absent
    final consecutiveAbsentees = absentStudentsList;

    final morningShiftCount = students
        .where((s) => (s['shift']?.toString() ?? '').toLowerCase().contains('morn') || s['shift'] == 'صبح')
        .length;
    final eveningShiftCount = totalStudents - morningShiftCount;

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(loc.translate('analytics')),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          actions: [
            ThemeButton(controller: themeController),
            LanguageButton(controller: languageController),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Attendance Summary Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: Colors.green.shade700,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Text(
                        loc.translate('attendance_rate'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${attendanceRate.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatColumn(
                            loc.translate('total_students'),
                            '$totalStudents',
                            Colors.white,
                          ),
                          _buildStatColumn(
                            loc.translate('present'),
                            '$presentStudents',
                            Colors.lightGreenAccent,
                          ),
                          _buildStatColumn(
                            loc.translate('absent'),
                            '$absentStudentsCount',
                            Colors.orangeAccent,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Consecutive Absence Warning Card
              if (consecutiveAbsentees.isNotEmpty) ...[
                Card(
                  color: Colors.red.shade50,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.red.shade300),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 28),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                loc.translate('consecutive_absent_alert'),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          loc.translate('consecutive_absent_desc'),
                          style: TextStyle(color: Colors.red.shade800),
                        ),
                        const SizedBox(height: 12),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: consecutiveAbsentees.length,
                          itemBuilder: (context, index) {
                            final student = consecutiveAbsentees[index];
                            return ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                student['name'] ?? '',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                'Lang: ${student['language'] ?? 'urdu'} | Method: ${student['messageMethod'] ?? 'SMS'}',
                              ),
                              trailing: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red.shade800,
                                ),
                                onPressed: () {
                                  if (onSendMessage != null) {
                                    onSendMessage!(student, 'absent');
                                  }
                                },
                                icon: const Icon(Icons.send, size: 16),
                                label: Text(loc.translate('actions')),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Fee Collection Card
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.translate('fee_record'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(loc.translate('total_paid_amount')),
                          Text(
                            '₹${totalPaid.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(loc.translate('total_due_amount')),
                          Text(
                            '₹${totalDue.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Shift Breakdown Card
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.translate('shift'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Chip(
                            avatar: const Icon(Icons.wb_sunny_outlined),
                            label: Text('${loc.translate('morning')}: $morningShiftCount'),
                          ),
                          Chip(
                            avatar: const Icon(Icons.nights_stay_outlined),
                            label: Text('${loc.translate('evening')}: $eveningShiftCount'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color textColor) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: textColor,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: textColor.withValues(alpha: 0.9),
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
