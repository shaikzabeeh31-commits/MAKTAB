import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_localizations.dart';
import 'role_selection_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DATA MODELS
// ─────────────────────────────────────────────────────────────────────────────

enum LeaveType { sick, family, personal, other }

enum LeaveStatus {
  pendingManager,
  pendingAdmin,
  forwardedToAdmin,
  adminReviewed,
  approved,
  rejected,
}

class ReplacementTeacher {
  final String name;
  final String maktab;
  final String phone;
  final String qualification;
  final String experience;
  final String fromDate;
  final String toDate;
  final String notes;
  final bool isArranged;

  ReplacementTeacher({
    required this.name,
    required this.maktab,
    required this.phone,
    required this.qualification,
    required this.experience,
    required this.fromDate,
    required this.toDate,
    required this.notes,
    this.isArranged = true,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'maktab': maktab,
        'phone': phone,
        'qualification': qualification,
        'experience': experience,
        'fromDate': fromDate,
        'toDate': toDate,
        'notes': notes,
        'isArranged': isArranged,
      };

  factory ReplacementTeacher.fromJson(Map<String, dynamic> json) =>
      ReplacementTeacher(
        name: json['name']?.toString() ?? '',
        maktab: json['maktab']?.toString() ?? '',
        phone: json['phone']?.toString() ?? '',
        qualification: json['qualification']?.toString() ?? '',
        experience: json['experience']?.toString() ?? '',
        fromDate: json['fromDate']?.toString() ?? '',
        toDate: json['toDate']?.toString() ?? '',
        notes: json['notes']?.toString() ?? '',
        isArranged: json['isArranged'] == true,
      );
}

class LeaveRequest {
  final String id; // e.g. LRQ-2024-00056
  final String teacherName;
  final String teacherPhone;
  final String maktabName;
  final String leaveType;
  final String fromDate;
  final String toDate;
  final int totalDays;
  final String reason;
  final String attachmentName;
  final String appliedDate;
  final String teacherMessage;
  LeaveStatus status;
  String managerNote;
  String adminNote;
  bool isDirectToAdmin; // True if teacher sent directly/CC to Admin as well
  ReplacementTeacher? replacement;
  List<Map<String, String>> logs;

  LeaveRequest({
    required this.id,
    required this.teacherName,
    required this.teacherPhone,
    required this.maktabName,
    required this.leaveType,
    required this.fromDate,
    required this.toDate,
    required this.totalDays,
    required this.reason,
    required this.attachmentName,
    required this.appliedDate,
    this.teacherMessage = '',
    this.status = LeaveStatus.pendingManager,
    this.managerNote = '',
    this.adminNote = '',
    this.isDirectToAdmin = true,
    this.replacement,
    List<Map<String, String>>? logs,
  }) : logs = logs ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'teacherName': teacherName,
        'teacherPhone': teacherPhone,
        'maktabName': maktabName,
        'leaveType': leaveType,
        'fromDate': fromDate,
        'toDate': toDate,
        'totalDays': totalDays,
        'reason': reason,
        'attachmentName': attachmentName,
        'appliedDate': appliedDate,
        'teacherMessage': teacherMessage,
        'status': status.name,
        'managerNote': managerNote,
        'adminNote': adminNote,
        'isDirectToAdmin': isDirectToAdmin,
        'replacement': replacement?.toJson(),
        'logs': logs,
      };

  factory LeaveRequest.fromJson(Map<String, dynamic> json) {
    return LeaveRequest(
      id: json['id']?.toString() ?? 'LRQ-${DateTime.now().millisecondsSinceEpoch}',
      teacherName: json['teacherName']?.toString() ?? 'Sr. Sana Fatima',
      teacherPhone: json['teacherPhone']?.toString() ?? '0300-1234567',
      maktabName: json['maktabName']?.toString() ?? 'Al-Noor Maktab',
      leaveType: json['leaveType']?.toString() ?? 'Sick Leave',
      fromDate: json['fromDate']?.toString() ?? '22 Jul 2024 (Mon)',
      toDate: json['toDate']?.toString() ?? '24 Jul 2024 (Wed)',
      totalDays: int.tryParse(json['totalDays']?.toString() ?? '3') ?? 3,
      reason: json['reason']?.toString() ?? 'Fever and headache, need rest and doctor advice.',
      attachmentName: json['attachmentName']?.toString() ?? 'Prescription.jpg',
      appliedDate: json['appliedDate']?.toString() ?? '21 Jul 2024, 09:15 AM',
      teacherMessage: json['teacherMessage']?.toString() ?? 'Assalamu Alaikum Sir, I am not well, please approve my leave request.',
      status: LeaveStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => LeaveStatus.pendingManager,
      ),
      managerNote: json['managerNote']?.toString() ?? '',
      adminNote: json['adminNote']?.toString() ?? '',
      isDirectToAdmin: json['isDirectToAdmin'] == true,
      replacement: json['replacement'] != null
          ? ReplacementTeacher.fromJson(
              Map<String, dynamic>.from(json['replacement'] as Map))
          : null,
      logs: json['logs'] is List
          ? (json['logs'] as List)
              .map((e) => Map<String, String>.from(e as Map))
              .toList()
          : [],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PRE-SEEDED SAMPLE DATA
// ─────────────────────────────────────────────────────────────────────────────
List<LeaveRequest> _getSampleLeaveRequests() {
  return [
    LeaveRequest(
      id: 'LRQ-2024-00056',
      teacherName: 'Sr. Sana Fatima',
      teacherPhone: '0300-9876543',
      maktabName: 'Al-Noor Maktab',
      leaveType: 'Sick Leave',
      fromDate: '22 Jul 2024 (Mon)',
      toDate: '24 Jul 2024 (Wed)',
      totalDays: 3,
      reason: 'Fever and headache, need rest and doctor advice.',
      attachmentName: 'Prescription.jpg',
      appliedDate: '21 Jul 2024, 09:15 AM',
      teacherMessage: 'Assalamu Alaikum Sir, I am not well, so please approve my leave request. JazakAllah.',
      status: LeaveStatus.forwardedToAdmin,
      isDirectToAdmin: true,
      managerNote: 'Kindly review and approve/reject the leave request.',
      replacement: ReplacementTeacher(
        name: 'Sr. Maleeha Ahmed',
        maktab: 'Al-Noor Maktab',
        phone: '0300-1234567',
        qualification: 'Hafiz, Dars-e-Nizami (Final)',
        experience: '3 Years',
        fromDate: '22 Jul 2024',
        toDate: '24 Jul 2024',
        notes: 'She will handle Class 3 & 4 during my absence.',
      ),
      logs: [
        {'time': '21 Jul 2024, 09:15 AM', 'text': 'Teacher applied for Sick Leave (Direct copy sent to Main Admin)'},
        {'time': '21 Jul 2024, 09:25 AM', 'text': 'Manager reviewed & forwarded request to Main Admin'},
      ],
    ),
    LeaveRequest(
      id: 'LRQ-2024-00057',
      teacherName: 'Sr. Ibraheem',
      teacherPhone: '0300-8877665',
      maktabName: 'Dar-ul-Huda Maktab',
      leaveType: 'Family Leave',
      fromDate: '28 Jul 2024 (Sun)',
      toDate: '30 Jul 2024 (Tue)',
      totalDays: 3,
      reason: 'Family event out of station.',
      attachmentName: 'Travel_Ticket.pdf',
      appliedDate: '21 Jul 2024, 08:50 AM',
      status: LeaveStatus.pendingManager,
      isDirectToAdmin: true,
    ),
    LeaveRequest(
      id: 'LRQ-2024-00058',
      teacherName: 'Sr. Ayesha Parveen',
      teacherPhone: '0300-5544332',
      maktabName: 'Madina Maktab',
      leaveType: 'Personal Leave',
      fromDate: '25 Jul 2024 (Thu)',
      toDate: '26 Jul 2024 (Fri)',
      totalDays: 2,
      reason: 'Urgent personal work at home.',
      attachmentName: 'Document.pdf',
      appliedDate: '20 Jul 2024, 08:40 AM',
      status: LeaveStatus.approved,
      isDirectToAdmin: false,
    ),
  ];
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN LEAVE PORTAL SCREEN (Role-Aware Router)
// ─────────────────────────────────────────────────────────────────────────────
class LeaveManagementScreen extends StatefulWidget {
  final AppRole currentRole;
  final LanguageController languageController;

  const LeaveManagementScreen({
    super.key,
    required this.currentRole,
    required this.languageController,
  });

  @override
  State<LeaveManagementScreen> createState() => _LeaveManagementScreenState();
}

class _LeaveManagementScreenState extends State<LeaveManagementScreen> {
  static const String _storageKey = 'leave_requests_v1';
  List<LeaveRequest> _requests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonStr = prefs.getString(_storageKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final decoded = jsonDecode(jsonStr) as List<dynamic>;
        _requests = decoded
            .map((item) => LeaveRequest.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      } else {
        _requests = _getSampleLeaveRequests();
        await _saveRequests();
      }
    } catch (_) {
      _requests = _getSampleLeaveRequests();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveRequests() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(_requests.map((r) => r.toJson()).toList());
    await prefs.setString(_storageKey, jsonStr);
  }

  void _addLeaveRequest(LeaveRequest req) {
    setState(() {
      _requests.insert(0, req);
    });
    _saveRequests();
  }

  void _updateRequest(LeaveRequest updated) {
    final idx = _requests.indexWhere((r) => r.id == updated.id);
    if (idx != -1) {
      setState(() {
        _requests[idx] = updated;
      });
      _saveRequests();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    switch (widget.currentRole) {
      case AppRole.teacher:
        return _TeacherLeavePortal(
          requests: _requests
              .where((r) => r.teacherName.contains('Sana') || r.teacherName.contains('Teacher'))
              .toList(),
          allRequests: _requests,
          onApply: _addLeaveRequest,
          languageController: widget.languageController,
        );
      case AppRole.manager:
        return _ManagerLeavePortal(
          requests: _requests,
          onUpdate: _updateRequest,
          languageController: widget.languageController,
        );
      case AppRole.admin:
        return _AdminLeavePortal(
          requests: _requests,
          onUpdate: _updateRequest,
          languageController: widget.languageController,
        );
      default:
        return _TeacherLeavePortal(
          requests: _requests,
          allRequests: _requests,
          onApply: _addLeaveRequest,
          languageController: widget.languageController,
        );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. TEACHER LEAVE PORTAL & APPLY FORM (Screen 1 & 4 from Reference)
// ─────────────────────────────────────────────────────────────────────────────
class _TeacherLeavePortal extends StatefulWidget {
  final List<LeaveRequest> requests;
  final List<LeaveRequest> allRequests;
  final Function(LeaveRequest) onApply;
  final LanguageController languageController;

  const _TeacherLeavePortal({
    required this.requests,
    required this.allRequests,
    required this.onApply,
    required this.languageController,
  });

  @override
  State<_TeacherLeavePortal> createState() => _TeacherLeavePortalState();
}

class _TeacherLeavePortalState extends State<_TeacherLeavePortal>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const SizedBox.shrink(),
        backgroundColor: const Color(0xFF047857),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: Colors.amber,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.history_rounded), text: 'لیو ہسٹری (History)'),
            Tab(icon: Icon(Icons.add_circle_outline_rounded), text: 'نئی درخواست (Apply)'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildTeacherHistoryList(),
          _buildApplyLeaveForm(),
        ],
      ),
    );
  }

  Widget _buildTeacherHistoryList() {
    final list = widget.requests.isNotEmpty ? widget.requests : widget.allRequests;
    if (list.isEmpty) {
      return const Center(child: Text('کوئی لیو درخواست نہیں ملی'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: list.length,
      itemBuilder: (ctx, i) {
        final r = list[i];
        final isApproved = r.status == LeaveStatus.approved;
        final isRejected = r.status == LeaveStatus.rejected;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isApproved
                            ? Colors.green.shade100
                            : isRejected
                                ? Colors.red.shade100
                                : Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isApproved
                            ? 'Approved (منظور)'
                            : isRejected
                                ? 'Rejected (مسترد)'
                                : 'Pending with Manager/Admin',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isApproved
                              ? Colors.green.shade900
                              : isRejected
                                  ? Colors.red.shade900
                                  : Colors.orange.shade900,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(r.id,
                        style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${r.leaveType} (${r.totalDays} Days)',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text('تاریخ: ${r.fromDate} ➔ ${r.toDate}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                Text('سبب: ${r.reason}',
                    style: const TextStyle(fontSize: 12, color: Colors.black87)),
                if (r.isDirectToAdmin)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('Direct copy sent to Main Admin (مین ایڈمن کو بھی کی کاپی دی گئی)',
                        style: TextStyle(fontSize: 10, color: Colors.blue)),
                  ),
                // Replacement Teacher Details Card if assigned
                if (r.replacement != null) ...[
                  const Divider(height: 16),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.teal.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.person_pin_rounded,
                                size: 16, color: Color(0xFF047857)),
                            const SizedBox(width: 4),
                            Text('Replacement Teacher: ${r.replacement!.name}',
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF047857))),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text('Phone: ${r.replacement!.phone} | Qual: ${r.replacement!.qualification}',
                            style: const TextStyle(fontSize: 11, color: Colors.black87)),
                        Text('Notes: ${r.replacement!.notes}',
                            style: const TextStyle(fontSize: 10.5, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildApplyLeaveForm() {
    final typeCtrl = TextEditingController(text: 'Sick Leave');
    final reasonCtrl = TextEditingController();
    final messageCtrl = TextEditingController();
    String fromDateStr = '22 Jul 2024';
    String toDateStr = '24 Jul 2024';
    int daysCount = 3;
    bool sendDirectToAdmin = true; // Send to Manager AND CC Main Admin directly

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'نئی لیو درخواست بھیجیں (Apply for Leave)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: 'Sick Leave',
            decoration: const InputDecoration(
              labelText: 'Leave Type (لیو قسم)',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'Sick Leave', child: Text('Sick Leave (بیماری)')),
              DropdownMenuItem(value: 'Family Leave', child: Text('Family Leave (خاندانی)')),
              DropdownMenuItem(value: 'Personal Leave', child: Text('Personal Leave (ذاتی)')),
            ],
            onChanged: (v) {
              if (v != null) typeCtrl.text = v;
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  readOnly: true,
                  controller: TextEditingController(text: fromDateStr),
                  decoration: const InputDecoration(
                    labelText: 'From Date (شروع)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today_rounded),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  readOnly: true,
                  controller: TextEditingController(text: toDateStr),
                  decoration: const InputDecoration(
                    labelText: 'To Date (ختم)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today_rounded),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: reasonCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Reason for Leave (سبب)',
              hintText: 'e.g. Fever and headache, need rest and doctor advice.',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: messageCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Message to Manager & Admin (پیغام)',
              hintText: 'Assalamu Alaikum Sir, please approve my leave request.',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          StatefulBuilder(
            builder: (ctx, setSt) => SwitchListTile(
              activeThumbColor: const Color(0xFF047857),
              title: const Text('Send copy to Main Admin directly as well'),
              subtitle: const Text('مینجر کے ساتھ ساتھ مین ایڈمن کو بھی کی کاپی جائے گی'),
              value: sendDirectToAdmin,
              onChanged: (v) => setSt(() => sendDirectToAdmin = v),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF047857),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                final req = LeaveRequest(
                  id: 'LRQ-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}',
                  teacherName: 'Sr. Sana Fatima',
                  teacherPhone: '0300-9876543',
                  maktabName: 'Al-Noor Maktab',
                  leaveType: typeCtrl.text,
                  fromDate: fromDateStr,
                  toDate: toDateStr,
                  totalDays: daysCount,
                  reason: reasonCtrl.text.isEmpty
                      ? 'Fever and headache, doctor advice.'
                      : reasonCtrl.text,
                  attachmentName: 'Prescription.jpg',
                  appliedDate: 'Just Now',
                  teacherMessage: messageCtrl.text.isEmpty
                      ? 'Assalamu Alaikum, please approve my leave request.'
                      : messageCtrl.text,
                  status: LeaveStatus.pendingManager,
                  isDirectToAdmin: sendDirectToAdmin,
                  logs: [
                    {
                      'time': 'Just Now',
                      'text': sendDirectToAdmin
                          ? 'Teacher applied for Leave (Copy sent to Manager & Main Admin)'
                          : 'Teacher applied for Leave'
                    }
                  ],
                );
                widget.onApply(req);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('لیو درخواست کامیابی سے بھیج دی گئی!'),
                  backgroundColor: Color(0xFF047857),
                ));
                _tabCtrl.animateTo(0);
              },
              icon: const Icon(Icons.send_rounded),
              label: const Text('درخواست بھیجیں (Submit Leave Application)',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. MANAGER LEAVE PORTAL & FORWARD WORKFLOW (Section 1 & 3 from Reference)
// ─────────────────────────────────────────────────────────────────────────────
class _ManagerLeavePortal extends StatefulWidget {
  final List<LeaveRequest> requests;
  final Function(LeaveRequest) onUpdate;
  final LanguageController languageController;

  const _ManagerLeavePortal({
    required this.requests,
    required this.onUpdate,
    required this.languageController,
  });

  @override
  State<_ManagerLeavePortal> createState() => _ManagerLeavePortalState();
}

class _ManagerLeavePortalState extends State<_ManagerLeavePortal> {
  String _selectedTab = 'All';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.requests.where((r) {
      if (_selectedTab == 'Pending') return r.status == LeaveStatus.pendingManager || r.status == LeaveStatus.forwardedToAdmin;
      if (_selectedTab == 'Approved') return r.status == LeaveStatus.approved;
      if (_selectedTab == 'Rejected') return r.status == LeaveStatus.rejected;
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('مینجر ان باکس (Manager Inbox & Requests)',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0A3B25),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Tabs Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ['All', 'Pending', 'Approved', 'Rejected'].map((tab) {
                final isSel = _selectedTab == tab;
                return ChoiceChip(
                  label: Text(tab),
                  selected: isSel,
                  selectedColor: const Color(0xFF0A3B25),
                  labelStyle: TextStyle(
                      color: isSel ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 12),
                  onSelected: (_) => setState(() => _selectedTab = tab),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('کوئی درخواست نہیں ہے'))
                : ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final r = filtered[i];
                      return _buildManagerRequestCard(r);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildManagerRequestCard(LeaveRequest r) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF0A3B25),
          child: Text(r.teacherName.substring(0, 1),
              style: const TextStyle(color: Colors.white)),
        ),
        title: Text(
          '${r.teacherName} — ${r.leaveType}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${r.fromDate} to ${r.toDate} (${r.totalDays} Days)',
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
            Text('Status: ${r.status.name}',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0A3B25),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 10),
          ),
          onPressed: () => _showManagerDetailDialog(r),
          child: const Text('تفصیلات (View)', style: TextStyle(fontSize: 11)),
        ),
      ),
    );
  }

  void _showManagerDetailDialog(LeaveRequest r) {
    final noteCtrl = TextEditingController(text: r.managerNote);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSt) => Padding(
            padding: EdgeInsets.fromLTRB(
                16, 16, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('درخواست تفصیلات: ${r.teacherName}',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close)),
                    ],
                  ),
                  const Divider(),
                  _detailRow('Leave Type:', r.leaveType),
                  _detailRow('From / To:', '${r.fromDate} ➔ ${r.toDate}'),
                  _detailRow('Total Days:', '${r.totalDays} Days'),
                  _detailRow('Reason:', r.reason),
                  _detailRow('Attachment:', r.attachmentName),
                  _detailRow('Teacher Msg:', r.teacherMessage),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Message to Main Admin (مین ایڈمن کیلئے نوٹ)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0A3B25),
                              foregroundColor: Colors.white),
                          onPressed: () {
                            r.status = LeaveStatus.forwardedToAdmin;
                            r.managerNote = noteCtrl.text;
                            r.logs.add({
                              'time': 'Just Now',
                              'text': 'Manager forwarded request to Main Admin: ${noteCtrl.text}'
                            });
                            widget.onUpdate(r);
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('درخواست مین ایڈمن کو فارورڈ کر دی گئی!')),
                            );
                          },
                          icon: const Icon(Icons.send_rounded, size: 16),
                          label: const Text('Forward to Admin',
                              style: TextStyle(fontSize: 11)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade700,
                              foregroundColor: Colors.white),
                          onPressed: () {
                            r.status = LeaveStatus.approved;
                            r.logs.add({
                              'time': 'Just Now',
                              'text': 'Manager directly approved leave request'
                            });
                            widget.onUpdate(r);
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('لیو منظور کر دی گئی!')),
                            );
                          },
                          icon: const Icon(Icons.check_circle_rounded, size: 16),
                          label: const Text('Approve Leave',
                              style: TextStyle(fontSize: 11)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
              width: 100,
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey))),
          Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. MAIN ADMIN LEAVE PORTAL & REPLACEMENT ASSIGNMENT (Section 2 from Reference)
// ─────────────────────────────────────────────────────────────────────────────
class _AdminLeavePortal extends StatefulWidget {
  final List<LeaveRequest> requests;
  final Function(LeaveRequest) onUpdate;
  final LanguageController languageController;

  const _AdminLeavePortal({
    required this.requests,
    required this.onUpdate,
    required this.languageController,
  });

  @override
  State<_AdminLeavePortal> createState() => _AdminLeavePortalState();
}

class _AdminLeavePortalState extends State<_AdminLeavePortal> {
  @override
  Widget build(BuildContext context) {
    final forwarded = widget.requests;

    return Scaffold(
      appBar: AppBar(
        title: const Text('مین ایڈمن ڈیش بورڈ — لیو اور ریپلیسمنٹ',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
      ),
      body: forwarded.isEmpty
          ? const Center(child: Text('کوئی درخواست نہیں ملی'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: forwarded.length,
              itemBuilder: (ctx, i) {
                final r = forwarded[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(r.teacherName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14)),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(r.status.name,
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade900)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('مکتب: ${r.maktabName} | قسم: ${r.leaveType}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        Text('تاریخ: ${r.fromDate} ➔ ${r.toDate} (${r.totalDays} Days)',
                            style: const TextStyle(fontSize: 11.5)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1E3A8A),
                                    foregroundColor: Colors.white),
                                onPressed: () => _showReplacementFormDialog(r),
                                icon: const Icon(Icons.person_add_rounded, size: 16),
                                label: const Text('ریپلیسمنٹ استاذ درج کریں',
                                    style: TextStyle(fontSize: 11)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showReplacementFormDialog(LeaveRequest r) {
    final repNameCtrl = TextEditingController(
        text: r.replacement?.name ?? 'Sr. Maleeha Ahmed');
    final repPhoneCtrl =
        TextEditingController(text: r.replacement?.phone ?? '0300-1234567');
    final repQualCtrl = TextEditingController(
        text: r.replacement?.qualification ?? 'Hafiz, Dars-e-Nizami');
    final notesCtrl = TextEditingController(
        text: r.replacement?.notes ?? 'Will cover classes during leave period.');
    String decision = 'Approve';

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: Text('ریپلیسمنٹ اور منظوری: ${r.teacherName}',
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: repNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Replacement Teacher Name (متبادل استاد)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: repPhoneCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number (فون)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: repQualCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Qualification (قابلیت)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: notesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Coverage Notes (ہدایات)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: decision,
                  decoration: const InputDecoration(
                    labelText: 'Admin Decision (فیصلہ)',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Approve', child: Text('Approve (منظور)')),
                    DropdownMenuItem(value: 'Reject', child: Text('Reject (مسترد)')),
                  ],
                  onChanged: (v) {
                    if (v != null) setSt(() => decision = v);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A)),
              onPressed: () {
                final rep = ReplacementTeacher(
                  name: repNameCtrl.text.trim(),
                  maktab: r.maktabName,
                  phone: repPhoneCtrl.text.trim(),
                  qualification: repQualCtrl.text.trim(),
                  experience: '3 Years',
                  fromDate: r.fromDate,
                  toDate: r.toDate,
                  notes: notesCtrl.text.trim(),
                );
                r.replacement = rep;
                r.status = decision == 'Approve'
                    ? LeaveStatus.approved
                    : LeaveStatus.rejected;
                r.adminNote = 'Admin decision: $decision';
                r.logs.add({
                  'time': 'Just Now',
                  'text': 'Main Admin $decision leave and assigned replacement: ${rep.name}'
                });
                widget.onUpdate(r);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Admin decision saved ($decision)!')),
                );
              },
              child: const Text('Save Decision & Send'),
            ),
          ],
        ),
      ),
    );
  }
}
