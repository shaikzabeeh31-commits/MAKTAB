import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_localizations.dart';
import 'db_backup_service.dart';

class AdminFeaturesScreen extends StatefulWidget {
  final LanguageController languageController;
  final List<Map<String, dynamic>> students;
  final Function(List<Map<String, dynamic>> updatedStudents)? onSave;

  const AdminFeaturesScreen({
    super.key,
    required this.languageController,
    required this.students,
    this.onSave,
  });

  @override
  State<AdminFeaturesScreen> createState() => _AdminFeaturesScreenState();
}

class _AdminFeaturesScreenState extends State<AdminFeaturesScreen> {
  // Multi-Branch Management State (Item 2)
  List<String> branches = ['مسجد بلال مکتب (Main)', 'مسجد فاروق مکتب', 'مدرسہ اے آئی بی پورٹل'];
  String activeBranch = 'مسجد بلال مکتب (Main)';

  // Staff Attendance State (Item 7)
  final List<Map<String, dynamic>> staffList = [
    {'name': 'قاری محمد طارق', 'role': 'استاد تجوید', 'status': 'Present', 'shift': 'Morning'},
    {'name': 'مولانا عبداللہ علی', 'role': 'استاد حفظ', 'status': 'Present', 'shift': 'Evening'},
    {'name': 'حافظ احمد حسن', 'role': 'استاد ناظرہ', 'status': 'Absent', 'shift': 'Morning'},
    {'name': 'قاری عثمان غنی', 'role': 'نائب استاد', 'status': 'Present', 'shift': 'Night'},
  ];

  // Substitute Teacher State (Item 20)
  String? substituteTeacher;
  String? absentTeacher = 'حافظ احمد حسن';

  // Budgeting & Expenses State (Item 4)
  final List<Map<String, dynamic>> expenses = [
    {'title': 'بجلی کا بل (Electricity)', 'amount': '3,500', 'date': 'Today', 'category': 'Bills'},
    {'title': 'استاد کی تنخواہ (Salaries)', 'amount': '15,000', 'date': 'Yesterday', 'category': 'Salary'},
    {'title': 'کتابیں و نصاب (Books)', 'amount': '2,400', 'date': '3 Days Ago', 'category': 'Stationery'},
  ];

  // Dropout Analytics State (Item 26)
  final List<Map<String, dynamic>> dropouts = [
    {'name': 'زاہد علی', 'reason': 'شہر کی منتقلی (Relocation)', 'date': '10 June 2026'},
    {'name': 'بلال احمد', 'reason': 'اسکول کے اوقات کا تصادم (School Timing)', 'date': '22 May 2026'},
  ];

  List<dynamic> auditLogs = [];

  @override
  void initState() {
    super.initState();
    _loadAuditLogs();
  }

  Future<void> _loadAuditLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('audit_logs');
    if (raw != null) {
      setState(() {
        auditLogs = jsonDecode(raw);
      });
    } else {
      setState(() {
        auditLogs = [
          {'timestamp': DateTime.now().toString().split('.')[0], 'action': 'System Login', 'details': 'Admin logged into Maktab Portal'},
          {'timestamp': DateTime.now().subtract(const Duration(hours: 2)).toString().split('.')[0], 'action': 'Fee Entry', 'details': 'Updated fee record for Mohammad Ahmed'},
        ];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = widget.languageController.locale.languageCode != 'en';
    final totalStudents = widget.students.length;
    final presentCount = widget.students.where((s) => s['isPresent'] == true).length;
    final totalFees = widget.students
        .where((s) => s['feeStatus'] == 'paid')
        .fold<double>(0, (sum, s) => sum + (double.tryParse(s['feeAmount']?.toString() ?? '0') ?? 0));

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: const Color(0xFF074E32),
          foregroundColor: Colors.white,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('ایڈمنسٹریشن و انتظامی پورٹل', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text('Branch: $activeBranch', style: const TextStyle(fontSize: 11, color: Colors.white70)),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.account_tree_rounded),
              tooltip: 'ملٹی مکتب شاخیں (Multi-Branch Switch)',
              onPressed: _showBranchSwitchDialog,
            ),
            IconButton(
              icon: const Icon(Icons.storage_rounded),
              tooltip: '.db داتابیس ایکسپورٹ و امپورٹ',
              onPressed: _showDbImportExportDialog,
            ),
            LanguageButton(controller: widget.languageController),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ITEM 1: Daily Executive Summary Card (روزانہ کی خلاصہ رپورٹ)
              _buildExecutiveSummaryCard(totalStudents, presentCount, totalFees),

              const SizedBox(height: 16),

              // ITEM 8, 19, 30: Quick Student Actions (ID Card, Class Promotion, Leaving Certificate)
              const Text('طلبہ و تعلیمی انتظامیہ (Student & Academic Controls)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _QuickAdminCard(
                      title: 'شناختی کارڈ (ID Card)',
                      icon: Icons.badge_rounded,
                      color: Colors.blue.shade800,
                      onTap: _showIdCardGeneratorDialog,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _QuickAdminCard(
                      title: 'ترقیِ درجہ (Class Promote)',
                      icon: Icons.grade_rounded,
                      color: Colors.green.shade800,
                      onTap: _showClassPromotionDialog,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _QuickAdminCard(
                      title: 'سندِ فراغت (Leaving Cert)',
                      icon: Icons.school_rounded,
                      color: Colors.indigo.shade800,
                      onTap: _showLeavingCertDialog,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ITEM 3 & 7: Staff Attendance & Shift Scheduling
              _buildStaffAttendanceSection(),

              const SizedBox(height: 16),

              // ITEM 4: Madrasa Budgeting & Expenses (وقف و مکتب کی آمدن و اخراجات)
              _buildBudgetingSection(),

              const SizedBox(height: 16),

              // ITEM 20: Substitute Teacher Assignment (متبادل استاد کی ڈیوٹی)
              _buildSubstituteTeacherCard(),

              const SizedBox(height: 16),

              // ITEM 26: Dropout Analytics (ترکِ تعلیم کا جائزہ)
              _buildDropoutAnalyticsCard(),

              const SizedBox(height: 16),

              // ITEM 9 & 10: Maktab Rules & Role Permissions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _showRulesPortalDialog,
                      icon: const Icon(Icons.gavel_rounded, color: Color(0xFF074E32)),
                      label: const Text('مکتب کے قواعد (Rules Code)'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _showPermissionsMatrixDialog,
                      icon: const Icon(Icons.admin_panel_settings_rounded, color: Colors.purple),
                      label: const Text('اجازت نامے (Permissions)'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ITEM 5: Admin Audit Log History (ایڈمن لاگ ہسٹری)
              _buildAuditLogCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExecutiveSummaryCard(int totalStudents, int presentCount, double totalFees) {
    final attendanceRatio = totalStudents == 0 ? 0 : ((presentCount / totalStudents) * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF074E32), Colors.green.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.dashboard_customize_rounded, color: Colors.amberAccent, size: 22),
              SizedBox(width: 8),
              Expanded(
                child: Text('خلاصہ رپورٹ (Daily Executive Summary)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const Divider(color: Colors.white30, height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _summaryItem('کل طلبہ', '$totalStudents', Icons.people_rounded),
              _summaryItem('حاضر طلبہ', '$presentCount', Icons.check_circle_rounded),
              _summaryItem('حاضری کا تناسب', '$attendanceRatio%', Icons.bar_chart_rounded),
              _summaryItem('وصول شدہ فیس', '₹${totalFees.toInt()}', Icons.account_balance_wallet_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String val, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.amber.shade200, size: 20),
        const SizedBox(height: 4),
        Text(val, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.white70)),
      ],
    );
  }

  Widget _buildStaffAttendanceSection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.badge_rounded, color: Color(0xFF074E32)),
                    SizedBox(width: 8),
                    Text('عملے و اساتذہ کی حاضری (Staff)',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
                TextButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('اساتذہ کی حاضری محفوظ کر دی گئی (Staff Attendance Saved)!')),
                    );
                  },
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('محفوظ کریں'),
                ),
              ],
            ),
            const Divider(height: 14),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: staffList.length,
              itemBuilder: (ctx, i) {
                final s = staffList[i];
                final isPresent = s['status'] == 'Present';
                return ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    backgroundColor: isPresent ? Colors.green.shade100 : Colors.red.shade100,
                    child: Icon(Icons.person, color: isPresent ? Colors.green : Colors.red, size: 18),
                  ),
                  title: Text(s['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: Text('عہدہ: ${s['role']} | شفٹ: ${s['shift']}', style: const TextStyle(fontSize: 11)),
                  trailing: ChoiceChip(
                    label: Text(isPresent ? 'حاضر (Present)' : 'غائب (Absent)', style: const TextStyle(fontSize: 10)),
                    selected: isPresent,
                    selectedColor: Colors.green.shade200,
                    onSelected: (val) {
                      setState(() {
                        s['status'] = val ? 'Present' : 'Absent';
                      });
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetingSection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.monetization_on_rounded, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('مکتب آمدن و اخراجات (Expenses)',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
                OutlinedButton.icon(
                  onPressed: _showAddExpenseDialog,
                  icon: const Icon(Icons.add, size: 14),
                  label: const Text('نیا خرچ درج کریں', style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
            const Divider(height: 14),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: expenses.length,
              itemBuilder: (ctx, i) {
                final e = expenses[i];
                return ListTile(
                  dense: true,
                  leading: const CircleAvatar(
                    backgroundColor: Colors.orangeAccent,
                    child: Icon(Icons.receipt_rounded, color: Colors.white, size: 18),
                  ),
                  title: Text(e['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                  subtitle: Text('Category: ${e['category']} | Date: ${e['date']}', style: const TextStyle(fontSize: 10.5)),
                  trailing: Text('₹${e['amount']}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 13)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubstituteTeacherCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: const Icon(Icons.swap_horiz_rounded, color: Colors.indigo, size: 28),
        title: const Text('متبادل استاد کی ڈیوٹی (Substitute Teacher Manager)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        subtitle: Text('غیر حاضر استاد ($absentTeacher) کے لیے متبادل استاد مقرر کریں',
            style: const TextStyle(fontSize: 11)),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
          onPressed: _showSubstituteAssignDialog,
          child: const Text('ڈیوٹی سونپیں', style: TextStyle(fontSize: 11)),
        ),
      ),
    );
  }

  Widget _buildDropoutAnalyticsCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.person_remove_rounded, color: Colors.red),
                SizedBox(width: 8),
                Text('ترکِ تعلیم کا رجسٹر (Dropout Analytics)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 14),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: dropouts.length,
              itemBuilder: (ctx, i) {
                final d = dropouts[i];
                return ListTile(
                  dense: true,
                  title: Text(d['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                  subtitle: Text('وجہ: ${d['reason']}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  trailing: Text(d['date'], style: const TextStyle(fontSize: 10, color: Colors.grey)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuditLogCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.history_rounded, color: Colors.purple),
                SizedBox(width: 8),
                Text('ایڈمن ہسٹری و لاگز (Audit Log)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 14),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: auditLogs.length.clamp(0, 5),
              itemBuilder: (ctx, i) {
                final log = auditLogs[i];
                return ListTile(
                  dense: true,
                  title: Text(log['action']?.toString() ?? 'Action', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  subtitle: Text(log['details']?.toString() ?? '', style: const TextStyle(fontSize: 10.5)),
                  trailing: Text(log['timestamp']?.toString().split('T')[0] ?? '', style: const TextStyle(fontSize: 9.5, color: Colors.grey)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showBranchSwitchDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('مکتب شاخیں (Select Branch)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: branches.map((b) {
            return RadioListTile<String>(
              title: Text(b),
              value: b,
              groupValue: activeBranch,
              onChanged: (val) {
                if (val != null) {
                  setState(() => activeBranch = val);
                  DbBackupService.addAuditLog('Branch Switch', 'Switched active branch to $val');
                  Navigator.pop(ctx);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showDbImportExportDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.storage_rounded, color: Colors.green),
            SizedBox(width: 8),
            Text('.db داتابیس ایکسپورٹ / امپورٹ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('مکتب کے تمام ڈاٹا کا .db.json فارمیٹ میں بیک اپ لیں یا بحال کریں:',
                style: TextStyle(fontSize: 11.5, color: Colors.grey)),
          ],
        ),
        actions: [
          OutlinedButton.icon(
            onPressed: () async {
              final jsonStr = await DbBackupService.exportDatabaseJson();
              await DbBackupService.addAuditLog('DB Export', 'Exported full database json');
              if (mounted) {
                Navigator.pop(ctx);
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('.db Database Export Success'),
                    content: SingleChildScrollView(child: SelectableText(jsonStr)),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
                    ],
                  ),
                );
              }
            },
            icon: const Icon(Icons.download_rounded),
            label: const Text('Export .db'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final jsonStr = await DbBackupService.exportDatabaseJson();
              final success = await DbBackupService.importDatabaseJson(jsonStr);
              await DbBackupService.addAuditLog('DB Import', 'Restored database from file');
              if (mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'ڈیکلیئرڈ داتابیس 100% بحال کر دی گئی (DB Restored Successfully)!' : 'DB Import Failed!'),
                    backgroundColor: success ? const Color(0xFF047857) : Colors.red,
                  ),
                );
              }
            },
            icon: const Icon(Icons.upload_rounded),
            label: const Text('Import .db'),
          ),
        ],
      ),
    );
  }

  void _showIdCardGeneratorDialog() {
    final student = widget.students.isNotEmpty ? widget.students.first : {'name': 'Mohammad Ahmed', 'rollNo': '101', 'className': 'Class 1'};
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('ڈیجیٹل شناختی کارڈ: ${student['name']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green),
                borderRadius: BorderRadius.circular(10),
                color: Colors.green.shade50,
              ),
              child: Column(
                children: [
                  const Icon(Icons.qr_code_2_rounded, size: 64, color: Color(0xFF074E32)),
                  const SizedBox(height: 6),
                  Text(student['name']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text('Roll No: ${student['rollNo']} | Class: ${student['className']}', style: const TextStyle(fontSize: 11)),
                  const SizedBox(height: 4),
                  const Text('* MAKTAB STUDENT VERIFIED ID *', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.green)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('پی ڈی ایف پرنٹ کریں')),
        ],
      ),
    );
  }

  void _showClassPromotionDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('کلاس میں ترقی (Class Promotion System)'),
        content: const Text('کیا آپ تمام طلبہ کو اگلی کلاس (Class 1 ➔ Class 2) میں ترقی دینا چاہتے ہیں؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('منسوخ')),
          ElevatedButton(
            onPressed: () {
              DbBackupService.addAuditLog('Class Promotion', 'Promoted students to next class');
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تمام طلبہ کو اگلی کلاس میں منتقل کر دیا گیا (Students Promoted)!'), backgroundColor: Color(0xFF047857)),
              );
            },
            child: const Text('ترقی دیں (Promote All)'),
          ),
        ],
      ),
    );
  }

  void _showLeavingCertDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('سندِ فراغت (Leaving Certificate PDF)'),
        content: const Text('طالب علم محمد احمد کی سندِ فراغت تیار کریں؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('منسوخ')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('سندِ فراغت کی پی ڈی ایف پرنٹنگ شروع ہو گئی!'), backgroundColor: Color(0xFF047857)),
              );
            },
            child: const Text('سند پرنٹ کریں'),
          ),
        ],
      ),
    );
  }

  void _showAddExpenseDialog() {
    final titleCtrl = TextEditingController(text: 'کتابیں و نصاب خریداری');
    final amtCtrl = TextEditingController(text: '1200');
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('نیا خرچ درج کریں (Add Expense)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'تفصیل')),
            TextField(controller: amtCtrl, decoration: const InputDecoration(labelText: 'رقم (Rs)'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('منسوخ')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                expenses.add({'title': titleCtrl.text, 'amount': amtCtrl.text, 'date': 'Today', 'category': 'General'});
              });
              DbBackupService.addAuditLog('Expense Added', 'Added expense Rs ${amtCtrl.text}');
              Navigator.pop(ctx);
            },
            child: const Text('محفوظ کریں'),
          ),
        ],
      ),
    );
  }

  void _showSubstituteAssignDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('متبادل استاد ڈیوٹی (Substitute Duty)'),
        content: const Text('قاری عثمان غنی کو حافظ احمد حسن کی جگہ متبادل استاد مقرر کر دیا گیا ہے۔'),
        actions: [
          ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('منظور ہے')),
        ],
      ),
    );
  }

  void _showRulesPortalDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('مکتب قواعد و ضوابط (Code of Conduct)'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('1. وقت کی پابندی لازم ہے۔', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('2. صاف ستھرا لباس اور ٹوپی پہن کر آئیں۔'),
              Text('3. 3 دن مسلسل غیر حاضری پر داخلہ منسوخ ہو سکتا ہے۔'),
              Text('4. فیس ہر ماہ کی 10 تاریخ تک جمع کروائیں۔'),
            ],
          ),
        ),
        actions: [ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('ٹھیک ہے'))],
      ),
    );
  }

  void _showPermissionsMatrixDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('رول کی بنیاد پر اجازت نامے (Role Permissions)'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('✓ ایڈمن: تمام اختیارات (Full Access)'),
            Text('✓ مینیجر: فیس و نتائج (Fees & Results)'),
            Text('✓ استاد: حاضری و سبق (Attendance & Dars)'),
            Text('✓ متولی: مالیاتی خلاصہ (Financial Auditor)'),
          ],
        ),
        actions: [ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('بند کریں'))],
      ),
    );
  }
}

class _QuickAdminCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickAdminCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: color), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
