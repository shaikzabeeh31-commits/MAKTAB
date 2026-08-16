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

    // Calculate New vs Old Admissions
    final newAdmissionsCount = students.where((s) => s['isNewAdmission'] == true).length;
    final oldAdmissionsCount = totalStudents - newAdmissionsCount;

    // Group-wise breakdown
    final hifzCount = students.where((s) => (s['group'] ?? s['className'] ?? '').toString().contains('Hifz')).length;
    final naziraCount = students.where((s) => (s['group'] ?? s['className'] ?? '').toString().contains('Nazira')).length;
    final tajweedCount = students.where((s) => (s['group'] ?? s['className'] ?? '').toString().contains('Tajweed')).length;
    final primaryCount = totalStudents - (hifzCount + naziraCount + tajweedCount);

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

    final morningShiftCount = students
        .where((s) => (s['shift']?.toString() ?? '').toLowerCase().contains('morn') || s['shift'] == 'صبح')
        .length;
    final eveningShiftCount = students
        .where((s) => (s['shift']?.toString() ?? '').toLowerCase().contains('even') || s['shift'] == 'شام')
        .length;
    final nightShiftCount = totalStudents - (morningShiftCount + eveningShiftCount);

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const SizedBox.shrink(),
          backgroundColor: const Color(0xFF074E32),
          foregroundColor: Colors.white,
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
              // 1. Overall Performance Banner
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: const Color(0xFF074E32),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Text(
                        loc.translate('attendance_rate'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${attendanceRate.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          color: Colors.amberAccent,
                          fontSize: 38,
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

              // 2. New vs Old Admission Analytics
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.pie_chart_rounded, color: Colors.blue, size: 22),
                          SizedBox(width: 8),
                          Text(
                            'داخلہ تجزیہ (New vs Old Admission Breakdown)',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.green.shade200),
                              ),
                              child: Column(
                                children: [
                                  Text(loc.translate('new_admissions'), style: const TextStyle(fontSize: 12, color: Colors.green)),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$newAdmissionsCount',
                                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Column(
                                children: [
                                  Text(loc.translate('old_admissions'), style: const TextStyle(fontSize: 12, color: Colors.blue)),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$oldAdmissionsCount',
                                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 3. Batch Group Distribution
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.groups_rounded, color: Colors.purple, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            loc.translate('batch_group'),
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Chip(
                            avatar: const CircleAvatar(backgroundColor: Colors.purple, child: Text('A', style: TextStyle(color: Colors.white, fontSize: 10))),
                            label: Text('${loc.translate('hifz_group')}: $hifzCount'),
                          ),
                          Chip(
                            avatar: const CircleAvatar(backgroundColor: Colors.teal, child: Text('B', style: TextStyle(color: Colors.white, fontSize: 10))),
                            label: Text('${loc.translate('nazira_group')}: $naziraCount'),
                          ),
                          Chip(
                            avatar: const CircleAvatar(backgroundColor: Colors.indigo, child: Text('C', style: TextStyle(color: Colors.white, fontSize: 10))),
                            label: Text('${loc.translate('tajweed_group')}: $tajweedCount'),
                          ),
                          Chip(
                            avatar: const CircleAvatar(backgroundColor: Colors.orange, child: Text('D', style: TextStyle(color: Colors.white, fontSize: 10))),
                            label: Text('${loc.translate('primary_group')}: ${primaryCount > 0 ? primaryCount : 0}'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 4. Consecutive Absence Warning Card
              if (absentStudentsList.isNotEmpty) ...[
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
                                  fontSize: 16,
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
                          style: TextStyle(color: Colors.red.shade800, fontSize: 12),
                        ),
                        const SizedBox(height: 12),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: absentStudentsList.length,
                          itemBuilder: (context, index) {
                            final student = absentStudentsList[index];
                            return ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                student['name'] ?? '',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                'فون: ${student['fatherPhone'] ?? '-'} | گروپ: ${student['group'] ?? student['className'] ?? '-'}',
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

              // 5. Fee Collection Card
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
                      const Row(
                        children: [
                          Icon(Icons.account_balance_wallet_rounded, color: Colors.green, size: 22),
                          SizedBox(width: 8),
                          Text(
                            'فیس وصولی کا خلاصہ (Financial Recovery)',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
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

              // 6. Shift Breakdown Card
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
                      const Row(
                        children: [
                          Icon(Icons.schedule_rounded, color: Colors.orange, size: 22),
                          SizedBox(width: 8),
                          Text(
                            'شفٹ تقسیم (Shift Timings)',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Chip(
                            avatar: const Icon(Icons.wb_sunny_outlined, size: 18),
                            label: Text(AppLocalizations.of(context).locale.languageCode == 'en' ? 'Morning: $morningShiftCount' : 'صبح: $morningShiftCount'),
                          ),
                          Chip(
                            avatar: const Icon(Icons.wb_twilight_rounded, size: 18),
                            label: Text(AppLocalizations.of(context).locale.languageCode == 'en' ? 'Evening: $eveningShiftCount' : 'شام: $eveningShiftCount'),
                          ),
                          Chip(
                            avatar: const Icon(Icons.nights_stay_outlined, size: 18),
                            label: Text(AppLocalizations.of(context).locale.languageCode == 'en' ? 'Night: ${nightShiftCount > 0 ? nightShiftCount : 0}' : 'شبینہ: ${nightShiftCount > 0 ? nightShiftCount : 0}'),
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
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
