import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_localizations.dart';
import 'leave_management_screen.dart';
import 'role_selection_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DATA MODELS
// ─────────────────────────────────────────────────────────────────────────────

enum AttachmentType { none, pdf, images, voice, feeHandover }

class FeeHandoverRecord {
  final String id;
  final String teacherName;
  final String studentName;
  final String amount;
  final String paymentMode;
  final String date;
  bool isAcknowledged;
  String? managerNote;

  FeeHandoverRecord({
    required this.id,
    required this.teacherName,
    required this.studentName,
    required this.amount,
    required this.paymentMode,
    required this.date,
    this.isAcknowledged = false,
    this.managerNote,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'teacherName': teacherName,
        'studentName': studentName,
        'amount': amount,
        'paymentMode': paymentMode,
        'date': date,
        'isAcknowledged': isAcknowledged,
        'managerNote': managerNote,
      };

  factory FeeHandoverRecord.fromJson(Map<String, dynamic> json) =>
      FeeHandoverRecord(
        id: json['id']?.toString() ?? '',
        teacherName: json['teacherName']?.toString() ?? '',
        studentName: json['studentName']?.toString() ?? '',
        amount: json['amount']?.toString() ?? '0',
        paymentMode: json['paymentMode']?.toString() ?? 'Cash',
        date: json['date']?.toString() ?? '',
        isAcknowledged: json['isAcknowledged'] == true,
        managerNote: json['managerNote']?.toString(),
      );
}

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String senderRole;
  final String text;
  final String timestamp;
  final bool isMe;
  bool isRead;
  final AttachmentType attachmentType;
  final String? attachmentName;
  final String? attachmentSize;
  final List<String>? imageUrls;
  final String? voiceDuration;
  String? reactionEmoji;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.text,
    required this.timestamp,
    this.isMe = false,
    this.isRead = true,
    this.attachmentType = AttachmentType.none,
    this.attachmentName,
    this.attachmentSize,
    this.imageUrls,
    this.voiceDuration,
    this.reactionEmoji,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'senderId': senderId,
        'senderName': senderName,
        'senderRole': senderRole,
        'text': text,
        'timestamp': timestamp,
        'isMe': isMe,
        'isRead': isRead,
        'attachmentType': attachmentType.name,
        'attachmentName': attachmentName,
        'attachmentSize': attachmentSize,
        'imageUrls': imageUrls,
        'voiceDuration': voiceDuration,
        'reactionEmoji': reactionEmoji,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id']?.toString() ?? '',
        senderId: json['senderId']?.toString() ?? '',
        senderName: json['senderName']?.toString() ?? '',
        senderRole: json['senderRole']?.toString() ?? '',
        text: json['text']?.toString() ?? '',
        timestamp: json['timestamp']?.toString() ?? '',
        isMe: json['isMe'] == true,
        isRead: json['isRead'] == true,
        attachmentType: AttachmentType.values.firstWhere(
          (e) => e.name == json['attachmentType'],
          orElse: () => AttachmentType.none,
        ),
        attachmentName: json['attachmentName']?.toString(),
        attachmentSize: json['attachmentSize']?.toString(),
        imageUrls: (json['imageUrls'] as List?)?.map((e) => e.toString()).toList(),
        voiceDuration: json['voiceDuration']?.toString(),
        reactionEmoji: json['reactionEmoji']?.toString(),
      );
}

class ChatConversation {
  final String id;
  final String name;
  final String roleName;
  final String avatarInitials;
  final Color avatarColor;
  final String lastMessage;
  final String lastTime;
  final int unreadCount;
  final bool isGroup;

  ChatConversation({
    required this.id,
    required this.name,
    required this.roleName,
    required this.avatarInitials,
    required this.avatarColor,
    required this.lastMessage,
    required this.lastTime,
    this.unreadCount = 0,
    this.isGroup = false,
  });
}

class PublicAnnouncement {
  final String id;
  final String title;
  final String body;
  final String authorName;
  final String authorRole;
  final String timestamp;
  final String targetAudience; // All Members, Teachers Only, Parents Only

  PublicAnnouncement({
    required this.id,
    required this.title,
    required this.body,
    required this.authorName,
    required this.authorRole,
    required this.timestamp,
    required this.targetAudience,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'authorName': authorName,
        'authorRole': authorRole,
        'timestamp': timestamp,
        'targetAudience': targetAudience,
      };

  factory PublicAnnouncement.fromJson(Map<String, dynamic> json) =>
      PublicAnnouncement(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        body: json['body']?.toString() ?? '',
        authorName: json['authorName']?.toString() ?? '',
        authorRole: json['authorRole']?.toString() ?? '',
        timestamp: json['timestamp']?.toString() ?? '',
        targetAudience: json['targetAudience']?.toString() ?? 'All Members',
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// SAMPLE PRE-SEEDED CONVERSATIONS & ANNOUNCEMENTS
// ─────────────────────────────────────────────────────────────────────────────
List<ChatConversation> _getSampleConversations() {
  return [
    ChatConversation(
      id: 'c_staff',
      name: 'اساتذہ و انتظامیہ گروپ (All Staff Group)',
      roleName: 'عملہ چینل (Staff Channel)',
      avatarInitials: 'SG',
      avatarColor: const Color(0xFF047857),
      lastMessage: 'کوئی پیغام نہیں (No messages yet)',
      lastTime: '',
      isGroup: true,
    ),
    ChatConversation(
      id: 'c_admin',
      name: 'ایڈمن (Master Admin)',
      roleName: 'اعلیٰ انتظامیہ (Top Admin)',
      avatarInitials: 'AD',
      avatarColor: const Color(0xFF0F172A),
      lastMessage: 'براہ راست رابطہ',
      lastTime: '',
    ),
    ChatConversation(
      id: 'c_manager',
      name: 'مینجر (Manager)',
      roleName: 'انتظامیہ (Executive)',
      avatarInitials: 'MG',
      avatarColor: const Color(0xFF6B21A8),
      lastMessage: 'براہ راست رابطہ',
      lastTime: '',
    ),
    ChatConversation(
      id: 'c_mutawalli',
      name: 'متولی (Mutawalli)',
      roleName: 'مجلسِ انتظامی (Trustee)',
      avatarInitials: 'MT',
      avatarColor: const Color(0xFFD97706),
      lastMessage: 'براہ راست رابطہ',
      lastTime: '',
    ),
    ChatConversation(
      id: 'c_teacher',
      name: 'استاد (Qari Mohammad Tariq)',
      roleName: 'معلم مکتب (Teacher)',
      avatarInitials: 'QT',
      avatarColor: const Color(0xFF0284C7),
      lastMessage: 'براہ راست رابطہ',
      lastTime: '',
    ),
  ];
}

List<ChatMessage> _getSampleMessages() {
  return [];
}

List<PublicAnnouncement> _getSampleAnnouncements() {
  return [];
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN COMMUNITY CHAT & ANNOUNCEMENT SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class CommunityChatScreen extends StatefulWidget {
  final AppRole currentRole;
  final LanguageController languageController;
  final bool initialOpenAnnouncementModal;

  const CommunityChatScreen({
    super.key,
    required this.currentRole,
    required this.languageController,
    this.initialOpenAnnouncementModal = false,
  });

  @override
  State<CommunityChatScreen> createState() => _CommunityChatScreenState();
}

class _CommunityChatScreenState extends State<CommunityChatScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<ChatMessage> _messages = [];
  List<PublicAnnouncement> _announcements = [];
  bool _enableReadReceipts = true;
  final TextEditingController _textCtrl = TextEditingController();
  final String _storageKeyMsg = 'community_chat_messages_v1';
  final String _storageKeyAnn = 'community_announcements_v1';
  String _activeChatName = 'Main Owner';
  void _showToolsBottomSheet() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Text(
                  'کمیونٹی ٹولز اور ایکشنز (Chat Tools & Actions)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  children: [
                    _buildToolItem(
                      icon: Icons.campaign_rounded,
                      color: Colors.amber,
                      label: 'Notice\n(اعلان)',
                      onTap: () {
                        Navigator.pop(ctx);
                        _showSendAnnouncementDialog();
                      },
                    ),
                    _buildToolItem(
                      icon: Icons.payments_rounded,
                      color: Colors.green,
                      label: 'Fee Handover\n(فیس تصفیہ)',
                      onTap: () {
                        Navigator.pop(ctx);
                        _showTeacherFeeHandoverDialog();
                      },
                    ),
                    _buildToolItem(
                      icon: Icons.event_busy_rounded,
                      color: Colors.indigo,
                      label: 'Leave Req\n(رخصت درخواست)',
                      onTap: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LeaveManagementScreen(
                              currentRole: widget.currentRole,
                              languageController: widget.languageController,
                            ),
                          ),
                        );
                      },
                    ),
                    _buildToolItem(
                      icon: Icons.mic_rounded,
                      color: Colors.purple,
                      label: 'Voice Note\n(آڈیو پیغام)',
                      onTap: () {
                        Navigator.pop(ctx);
                        _sendMessage(
                            text: 'Voice message',
                            attachmentType: AttachmentType.voice,
                            voiceDuration: '0:15');
                      },
                    ),
                    _buildToolItem(
                      icon: Icons.image_rounded,
                      color: Colors.teal,
                      label: 'Photos\n(تصاویر)',
                      onTap: () {
                        Navigator.pop(ctx);
                        _sendMessage(
                            text: 'Attaching photo gallery',
                            attachmentType: AttachmentType.images,
                            imageUrls: ['img1.jpg']);
                      },
                    ),
                    _buildToolItem(
                      icon: Icons.attach_file_rounded,
                      color: Colors.deepOrange,
                      label: 'PDF Doc\n(دستاویز)',
                      onTap: () {
                        Navigator.pop(ctx);
                        _sendMessage(
                            text: 'Attached Document',
                            attachmentType: AttachmentType.pdf,
                            attachmentSize: '180 KB • PDF');
                      },
                    ),
                    _buildToolItem(
                      icon: _enableReadReceipts ? Icons.done_all_rounded : Icons.visibility_off_rounded,
                      color: _enableReadReceipts ? Colors.blue : Colors.grey,
                      label: _enableReadReceipts ? 'Receipts\n(ON)' : 'Receipts\n(OFF)',
                      onTap: () {
                        setState(() {
                          _enableReadReceipts = !_enableReadReceipts;
                        });
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(_enableReadReceipts 
                                ? 'Read receipts enabled (ریڈ رسیدیں آن ہیں)'
                                : 'Read receipts disabled (ریڈ رسیدیں آف ہیں)'),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildToolItem({required IconData icon, required Color color, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: color.withValues(alpha: 0.15),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
    if (widget.initialOpenAnnouncementModal) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSendAnnouncementDialog();
      });
    }
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final msgStr = prefs.getString(_storageKeyMsg);
    final annStr = prefs.getString(_storageKeyAnn);

    if (msgStr != null && msgStr.isNotEmpty) {
      final List decoded = jsonDecode(msgStr);
      _messages = decoded.map((e) => ChatMessage.fromJson(e)).toList();
    } else {
      _messages = _getSampleMessages();
    }

    if (annStr != null && annStr.isNotEmpty) {
      final List decoded = jsonDecode(annStr);
      _announcements = decoded.map((e) => PublicAnnouncement.fromJson(e)).toList();
    } else {
      _announcements = _getSampleAnnouncements();
    }

    if (mounted) setState(() {});
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _storageKeyMsg, jsonEncode(_messages.map((m) => m.toJson()).toList()));
    await prefs.setString(
        _storageKeyAnn, jsonEncode(_announcements.map((a) => a.toJson()).toList()));
  }

  void _sendMessage({
    required String text,
    AttachmentType attachmentType = AttachmentType.none,
    String? attachmentName,
    String? attachmentSize,
    List<String>? imageUrls,
    String? voiceDuration,
  }) {
    if (text.trim().isEmpty && attachmentType == AttachmentType.none) return;

    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}';

    final msg = ChatMessage(
      id: 'm_${DateTime.now().millisecondsSinceEpoch}',
      senderId: 'me',
      senderName: 'You (${widget.currentRole.name.toUpperCase()})',
      senderRole: widget.currentRole.name,
      text: text,
      timestamp: timeStr,
      isMe: true,
      attachmentType: attachmentType,
      attachmentName: attachmentName,
      attachmentSize: attachmentSize,
      imageUrls: imageUrls,
      voiceDuration: voiceDuration,
    );

    setState(() {
      _messages.add(msg);
      _textCtrl.clear();
    });
    _saveData();
  }

  void _addAnnouncement(PublicAnnouncement ann) {
    setState(() {
      _announcements.insert(0, ann);
    });
    _saveData();
  }

  bool _isSearching = false;
  String _searchQuery = '';

  Future<void> _callPhone() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: '+923001234567');
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('نہیں کال کر سکتے', style: TextStyle())));
      }
    }
  }

  void _showEmojiPicker() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: ['😊', '😂', '👍', '🙏', '❤️', '🔥', '🎉', '🌟', '✅', '❌'].map((emoji) {
            return InkWell(
              onTap: () {
                _textCtrl.text += emoji;
                Navigator.pop(ctx);
              },
              child: Text(emoji, style: const TextStyle(fontSize: 32)),
            );
          }).toList(),
        ),
      ),
    );
  }
@override
  Widget build(BuildContext context) {
    final bool isWide = MediaQuery.of(context).size.width > 700;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        title: const SizedBox.shrink(),
        actions: [
          IconButton(
            icon: const Icon(Icons.home_rounded, color: Colors.white),
            tooltip: 'ہوم ڈیش بورڈ (Return to Home)',
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.popUntil(context, (route) => route.isFirst);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.campaign_rounded, color: Colors.amberAccent),
            tooltip: 'اہم اعلان بھیجیں (Send Announcement)',
            onPressed: _showSendAnnouncementDialog,
          ),
          LanguageButton(controller: widget.languageController),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amber,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.chat_bubble_rounded), text: 'چَیٹ (Chats)'),
            Tab(icon: Icon(Icons.group_rounded), text: 'گروپس (Groups)'),
            Tab(icon: Icon(Icons.contacts_rounded), text: 'رابطے (Contacts)'),
            Tab(icon: Icon(Icons.campaign_rounded), text: 'اعلانات (Notices)'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Hierarchy Indicator Banner
          _buildRoleHierarchyBanner(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                isWide ? _buildSplitView() : _buildChatView(),
                _buildGroupsView(),
                _buildContactsView(),
                _buildAnnouncementsView(),
              ],
            ),
          ),
          // Bottom Communication Features Card
          _buildBottomFeatureGrid(),
        ],
      ),
    );
  }

  // ── Hierarchy Top Bar ──
  Widget _buildRoleHierarchyBanner() {
    return Container(
      color: const Color(0xFF0F172A),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _hierarchyNode('Teacher', 'Ustadh', Colors.blue, Icons.person_rounded),
            const Icon(Icons.swap_horiz_rounded, color: Colors.blue, size: 16),
            _hierarchyNode('Manager', 'Middle', Colors.green, Icons.person_2_rounded),
            const Icon(Icons.swap_horiz_rounded, color: Colors.purple, size: 16),
            _hierarchyNode('Main Owner', 'Top Level', Colors.purple, Icons.shield_rounded),
            const Icon(Icons.swap_horiz_rounded, color: Colors.amber, size: 16),
            _hierarchyNode('Mutawalli', 'Trustee', Colors.amber.shade900, Icons.account_balance_rounded),
          ],
        ),
      ),
    );
  }

  Widget _hierarchyNode(String title, String subtitle, Color color, IconData icon) {
    return Row(
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.bold, color: color)),
            Text(subtitle,
                style: const TextStyle(fontSize: 9, color: Colors.grey)),
          ],
        ),
      ],
    );
  }

  // ── Split View for Desktop/Tablet ──
  Widget _buildSplitView() {
    return Row(
      children: [
        SizedBox(width: 280, child: _buildConversationsSidebar()),
        const VerticalDivider(width: 1),
        Expanded(child: _buildChatWindow()),
      ],
    );
  }

  Widget _buildChatView() {
    return _buildChatWindow();
  }

  // ── Contacts Directory ──
  Widget _buildContactsView() {
    final contacts = _getFilteredContacts();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark ? const Color(0xFF0F172A) : Colors.white,
      child: ListView.builder(
        itemCount: contacts.length,
        itemBuilder: (ctx, i) {
          final c = contacts[i];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: c['color'] as Color,
              child: Text(c['initials'] as String, style: const TextStyle(color: Colors.white, fontSize: 12)),
            ),
            title: Text(c['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            subtitle: Text(c['role'] as String, style: const TextStyle(fontSize: 11)),
            trailing: IconButton(
              icon: const Icon(Icons.message_rounded, color: Colors.blue, size: 20),
              onPressed: () {
                setState(() {
                  _activeChatName = c['name'] as String;
                  _tabController.animateTo(0); // Go back to Chat tab
                });
              },
            ),
          );
        },
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredContacts() {
    final allContacts = [
      {'name': 'Admin (قاری محمد طارق)', 'role': 'Admin', 'initials': 'AD', 'color': Colors.purple},
      {'name': 'Manager (مولانا عبداللہ)', 'role': 'Manager', 'initials': 'MA', 'color': Colors.green},
      {'name': 'Teacher Ahmed', 'role': 'Teacher', 'initials': 'TA', 'color': Colors.blue},
      {'name': 'Mutawalli (حاجی یوسف)', 'role': 'Mutawalli', 'initials': 'MU', 'color': Colors.amber.shade900},
      {'name': 'Parent (علی والد محمد احمد)', 'role': 'Parent', 'initials': 'PA', 'color': Colors.orange},
    ];

    if (widget.currentRole == AppRole.teacher) {
      return allContacts.where((c) => c['role'] != 'Teacher').toList();
    } else if (widget.currentRole == AppRole.parent) {
      return allContacts.where((c) => c['role'] == 'Admin' || c['role'] == 'Manager' || c['role'] == 'Teacher').toList();
    }

    return allContacts;
  }

  // ── Left Sidebar Conversations ──
  Widget _buildConversationsSidebar() {
    var list = _getSampleConversations();
    if (widget.currentRole == AppRole.mutawalli) {
      list = list.where((c) => c.id == 'c_teacher' || c.id == 'c_manager' || c.id == 'c_admin').toList();
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: Column(
        children: [
          // Quick Action Tiles consolidated into a single premium button
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onPressed: _showToolsBottomSheet,
                icon: const Icon(Icons.build_rounded, size: 16, color: Colors.amberAccent),
                label: const Text('Chat Tools & Actions (ٹولز مینو)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              itemCount: list.length,
              itemBuilder: (ctx, i) {
                final c = list[i];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: c.avatarColor,
                    child: Text(c.avatarInitials,
                        style: const TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                  title: Text(c.name,
                      style: const TextStyle(
                          fontSize: 12.5, fontWeight: FontWeight.bold)),
                  subtitle: Text(c.lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11)),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(c.lastTime,
                          style: const TextStyle(fontSize: 9, color: Colors.grey)),
                      if (c.unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                              color: Colors.blue, shape: BoxShape.circle),
                          child: Text('${c.unreadCount}',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 9)),
                        ),
                    ],
                  ),
                  onTap: () {
                    setState(() {
                      _activeChatName = c.name;
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Main Chat Thread Window ──
  Widget _buildChatWindow() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    bool changed = false;
    for (var m in _messages) {
      if (!m.isMe && !m.isRead && (m.senderName.toLowerCase().contains(_activeChatName.toLowerCase()) || _activeChatName.toLowerCase().contains(m.senderName.toLowerCase()))) {
        m.isRead = true;
        changed = true;
      }
    }
    if (changed) {
      _saveData();
    }

    return Column(
      children: [
        // Active Chat Header
        Container(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFF6B21A8),
                child: Text(_activeChatName.substring(0, 1),
                    style: const TextStyle(color: Colors.white, fontSize: 12)),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_activeChatName,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold)),
                  const Text('Online • Connected',
                      style: TextStyle(fontSize: 10, color: Colors.green)),
                ],
              ),
              const Spacer(),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _enableReadReceipts ? Colors.blue.shade50 : Colors.grey.shade200,
                  foregroundColor: _enableReadReceipts ? Colors.blue.shade700 : Colors.grey.shade700,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  minimumSize: const Size(0, 32),
                ),
                onPressed: () {
                  setState(() {
                    _enableReadReceipts = !_enableReadReceipts;
                  });
                },
                icon: Icon(
                  _enableReadReceipts ? Icons.done_all_rounded : Icons.visibility_off_rounded,
                  size: 16,
                ),
                label: Text(
                  _enableReadReceipts ? 'Receipts ON' : 'Receipts OFF',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                  onPressed: _callPhone,
                  icon: const Icon(Icons.phone_rounded, color: Color(0xFF0F172A))),
              IconButton(
                  onPressed: () {
                    setState(() {
                      _isSearching = !_isSearching;
                      _searchQuery = '';
                    });
                  },
                  icon: Icon(_isSearching ? Icons.close : Icons.search_rounded, color: const Color(0xFF0F172A))),
            ],
          ),
        ),
        if (_isSearching)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'تلاش کریں...',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
        const Divider(height: 1),
        // Messages Thread
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _messages.where((m) => m.text.toLowerCase().contains(_searchQuery.toLowerCase())).length,
            itemBuilder: (ctx, i) {
              final filteredMessages = _messages.where((m) => m.text.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
              final m = filteredMessages[i];
              return _buildMessageBubble(m);
            },
          ),
        ),
        // Input Bar
        _buildChatInputBar(),
      ],
    );
  }

  // ── Chat Bubble ──
  Widget _buildMessageBubble(ChatMessage m) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final align = m.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bubbleColor = m.isMe ? (isDark ? const Color(0xFF056162) : const Color(0xFFDCF8C6)) : (isDark ? const Color(0xFF1E293B) : Colors.white);

    return Column(
      crossAxisAlignment: align,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(10),
          constraints: const BoxConstraints(maxWidth: 280),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!m.isMe)
                Text(m.senderName,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple.shade900)),
              Text(m.text, style: const TextStyle(fontSize: 13)),
              // Attachments
              if (m.attachmentType == AttachmentType.pdf) _buildPdfAttachment(m),
              if (m.attachmentType == AttachmentType.images) _buildImageGrid(m),
              if (m.attachmentType == AttachmentType.voice) _buildVoicePlayer(m),
              if (m.attachmentType == AttachmentType.feeHandover) _buildFeeHandoverCard(m),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (m.reactionEmoji != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade300)),
                      child: Text('${m.reactionEmoji} 1',
                          style: const TextStyle(fontSize: 10)),
                    ),
                  const Spacer(),
                  Text(m.timestamp,
                      style: const TextStyle(fontSize: 9, color: Colors.grey)),
                  if (m.isMe) ...[
                    const SizedBox(width: 4),
                    Icon(Icons.done_all_rounded,
                        size: 14, color: (_enableReadReceipts && m.isRead) ? Colors.blue : Colors.grey),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPdfAttachment(ChatMessage m) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.picture_as_pdf_rounded, color: Colors.red, size: 24),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m.attachmentName ?? 'Document.pdf',
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.bold)),
                Text(m.attachmentSize ?? '245 KB • PDF',
                    style: const TextStyle(fontSize: 9.5, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGrid(ChatMessage m) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      height: 70,
      child: Row(
        children: [
          Expanded(
              child: Container(
                  decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(6)),
                  child: const Center(
                      child: Icon(Icons.image, color: Colors.blue)))),
          const SizedBox(width: 4),
          Expanded(
              child: Container(
                  decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(6)),
                  child: const Center(
                      child: Icon(Icons.image, color: Colors.green)))),
          const SizedBox(width: 4),
          Expanded(
              child: Container(
                  decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(6)),
                  child: const Center(
                      child: Text('+2',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16))))),
        ],
      ),
    );
  }
  Widget _buildFeeHandoverCard(ChatMessage m) {
    final bool isManagerOrAdmin =
        widget.currentRole == AppRole.manager || widget.currentRole == AppRole.admin;
    final bool isAck = m.reactionEmoji == '✓✓ Acknowledged';

    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.monetization_on_rounded, color: Color(0xFF047857), size: 20),
              SizedBox(width: 6),
              Text('فیس رقم کا تصفیہ (Fee Handover)',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF047857))),
            ],
          ),
          const SizedBox(height: 4),
          Text('طالب علم: ${m.attachmentName ?? 'Student'}',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          Text('جمع شدہ رقم: ${m.attachmentSize ?? '₹0'}',
              style: const TextStyle(
                  fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.green)),
          const SizedBox(height: 6),
          if (isAck)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                  color: Colors.green.shade200, borderRadius: BorderRadius.circular(4)),
              child: const Text('✓✓ Manager Acknowledged & Saved (وصول پا لیا)',
                  style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF047857))),
            )
          else if (isManagerOrAdmin)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF047857),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
              onPressed: () {
                setState(() {
                  m.reactionEmoji = '✓✓ Acknowledged';
                });
                _saveData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('فیس وصولی کی تصدیق کر دی گئی (Fee Handover Acknowledged)!')),
                );
              },
              icon: const Icon(Icons.check_circle_rounded, size: 14),
              label: const Text('Approve & Acknowledge (وصول پا لیا)',
                  style: TextStyle(fontSize: 10)),
            ),
        ],
      ),
    );
  }

  void _showTeacherFeeHandoverDialog() {
    final studentCtrl = TextEditingController(text: 'Muhammad Abdullah');
    final amountCtrl = TextEditingController(text: '500');
    String mode = 'Cash';

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.payments_rounded, color: Colors.green),
              SizedBox(width: 8),
              Text('فیس رقم کا تصفیہ (Handover Collected Fee)',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: studentCtrl,
                decoration: const InputDecoration(
                  labelText: 'Student Name (طالب علم کا نام)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Collected Amount (جمع شدہ رقم ₹)',
                  prefixText: '₹ ',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: mode,
                decoration: const InputDecoration(
                  labelText: 'Payment Mode (طریقہ ادائی)',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Cash', child: Text('💵 Cash')),
                  DropdownMenuItem(value: 'UPI', child: Text('📱 UPI / GPay / PhonePe')),
                  DropdownMenuItem(value: 'Bank Transfer', child: Text('🏦 Bank Transfer')),
                ],
                onChanged: (v) {
                  if (v != null) setSt(() => mode = v);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF047857)),
              onPressed: () {
                _sendMessage(
                  text: 'فیس رقم کا تصفیہ (Teacher Fee Handover)',
                  attachmentType: AttachmentType.feeHandover,
                  attachmentName: studentCtrl.text.trim(),
                  attachmentSize: '₹${amountCtrl.text.trim()} • $mode',
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('فیس رقم کا تصفیہ مینجر کو بھیج دیا گیا!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('مینجر کو بھیجیں (Submit to Manager)'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoicePlayer(ChatMessage m) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 12,
            backgroundColor: Color(0xFF6B21A8),
            child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Icon(Icons.graphic_eq_rounded, color: Color(0xFF6B21A8)),
          ),
          const SizedBox(width: 8),
          Text(m.voiceDuration ?? '0:18',
              style: const TextStyle(fontSize: 10, color: Color(0xFF6B21A8))),
        ],
      ),
    );
  }

  // ── Input Bar ──
  Widget _buildChatInputBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          IconButton(
              icon: const Icon(Icons.emoji_emotions_outlined, color: Colors.grey),
              onPressed: _showEmojiPicker),
          IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF0F172A), size: 24),
              tooltip: 'ٹولز (Tools)',
              onPressed: _showToolsBottomSheet),
          Expanded(
            child: TextField(
              controller: _textCtrl,
              decoration: const InputDecoration(
                hintText: 'Type your message...',
                border: InputBorder.none,
              ),
            ),
          ),
          CircleAvatar(
            backgroundColor: const Color(0xFF0F172A),
            child: IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
              onPressed: () => _sendMessage(text: _textCtrl.text),
            ),
          ),
        ],
      ),
    );
  }

  // ── Groups View ──
  Widget _buildGroupsView() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Card(
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.amber,
              child: Icon(Icons.group, color: Colors.white),
            ),
            title: const Text('All Teachers Group (تمام اساتذہ کا گروپ)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            subtitle: const Text('42 Members • Active'),
            trailing: ElevatedButton(
              onPressed: () => _tabController.animateTo(0),
              child: const Text('میسج کریں'),
            ),
          ),
        ),
      ],
    );
  }

  // ── Public Announcements View ──
  Widget _buildAnnouncementsView() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _announcements.length,
      itemBuilder: (ctx, i) {
        final a = _announcements[i];
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
                    const Icon(Icons.campaign_rounded, color: Colors.amber, size: 20),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(a.title,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(4)),
                      child: Text(a.targetAudience,
                          style: TextStyle(
                              fontSize: 9.5,
                              color: Colors.blue.shade900,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(a.body, style: const TextStyle(fontSize: 12.5)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('بذریعہ: ${a.authorName}',
                        style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    const Spacer(),
                    Text(a.timestamp,
                        style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Send Public Announcement Dialog (For Manager, Teacher/Ustadh, Admin) ──
  void _showSendAnnouncementDialog() {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    String target = 'All Members';

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.campaign_rounded, color: Colors.amber),
              SizedBox(width: 8),
              Text('اہم اعلان بھیجیں (Public Notice)',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Announcement Title (عنوان)',
                    hintText: 'e.g. Maktab Holiday / Exam Schedule',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: bodyCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Announcement Body (تفصیلات)',
                    hintText: 'جو اعلان تمام ممبران یا والدین کو بھیجنا چاہتے ہیں وہ یہاں لکھیں...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: target,
                  decoration: const InputDecoration(
                    labelText: 'Target Audience (جن کو پیغام بھیجنا ہے)',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'All Members', child: Text('All Members & Parents (تمام ممبران)')),
                    DropdownMenuItem(value: 'Teachers Only', child: Text('Teachers Only (صرف اساتذہ)')),
                    DropdownMenuItem(value: 'Parents Only', child: Text('Parents Only (صرف والدین)')),
                  ],
                  onChanged: (v) {
                    if (v != null) setSt(() => target = v);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0F172A)),
              onPressed: () {
                if (titleCtrl.text.trim().isEmpty) return;

                final ann = PublicAnnouncement(
                  id: 'ann_${DateTime.now().millisecondsSinceEpoch}',
                  title: titleCtrl.text.trim(),
                  body: bodyCtrl.text.trim(),
                  authorName: 'You (${widget.currentRole.name.toUpperCase()})',
                  authorRole: widget.currentRole.name,
                  timestamp: 'Just Now',
                  targetAudience: target,
                );

                _addAnnouncement(ann);
                Navigator.pop(ctx);
                _tabController.animateTo(2);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('اہم اعلان تمام اراکین کو بھیج دیا گیا!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('بھیجیں (Publish Notice)'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Bottom Feature 3-Dots Action Bar ──
  Widget _buildBottomFeatureGrid() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.forum_rounded, color: Color(0xFF0F172A), size: 20),
              SizedBox(width: 8),
              Text('کمیونٹی ٹولز اور سروسز (Community Tools)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
            ],
          ),
          IconButton.filledTonal(
            style: IconButton.styleFrom(backgroundColor: const Color(0xFFF1F5F9)),
            icon: const Icon(Icons.more_horiz_rounded, size: 26, color: Color(0xFF0F172A)),
            tooltip: 'تمام ٹولز دکھائیں (Display All Tools)',
            onPressed: _showToolsBottomSheet,
          ),
        ],
      ),
    );
  }
}
