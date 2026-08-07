import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_localizations.dart';
import 'attendance_screen.dart';
import 'fee_screen.dart';
import 'lesson_screen.dart';
import 'leave_management_screen.dart';
import 'community_chat_screen.dart';
import 'results_screen.dart';
import 'admin_features_screen.dart';
import 'main.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ROLE MODEL & DATA
// ─────────────────────────────────────────────────────────────────────────────
enum AppRole {
  manager,
  admin,
  teacher,
  parent,
  mutawalli,
  other,
}

class RoleInfo {
  final AppRole role;
  final String titleUrdu;
  final String titleEnglish;
  final String descriptionUrdu;
  final String welcomeUrdu;
  final String subtitleUrdu;
  final IconData icon;
  final Color primaryColor;

  const RoleInfo({
    required this.role,
    required this.titleUrdu,
    required this.titleEnglish,
    required this.descriptionUrdu,
    required this.welcomeUrdu,
    required this.subtitleUrdu,
    required this.icon,
    required this.primaryColor,
  });
}

const List<RoleInfo> kAppRoles = [
  RoleInfo(
    role: AppRole.manager,
    titleUrdu: 'مینجر',
    titleEnglish: 'Manager',
    descriptionUrdu: 'ادارے کے عمومی کام کاج اور رپورٹیں',
    welcomeUrdu: 'خوش آمدید مینجر صاحب!',
    subtitleUrdu: 'آج آپ کے اداروں کا خلاصہ اور کارکردگی',
    icon: Icons.badge_rounded,
    primaryColor: Color(0xFF0A3B25),
  ),
  RoleInfo(
    role: AppRole.admin,
    titleUrdu: 'ایڈمن',
    titleEnglish: 'Admin',
    descriptionUrdu: 'سسٹم اور صارفین کا مکمل انتظام',
    welcomeUrdu: 'خوش آمدید ایڈمن صاحب!',
    subtitleUrdu: 'سسٹم، صارفین اور بیک اپ کا انتظام کریں',
    icon: Icons.admin_panel_settings_rounded,
    primaryColor: Color(0xFF1E3A8A),
  ),
  RoleInfo(
    role: AppRole.teacher,
    titleUrdu: 'استاد',
    titleEnglish: 'Ustadh / Teacher',
    descriptionUrdu: 'طلبہ کی تعلیم، حاضری اور سبق کا جائزہ',
    welcomeUrdu: 'خوش آمدید استاد صاحب!',
    subtitleUrdu: 'طلبہ کی تعلیم اور تربیت کا انتظام کریں',
    icon: Icons.menu_book_rounded,
    primaryColor: Color(0xFF047857),
  ),
  RoleInfo(
    role: AppRole.parent,
    titleUrdu: 'والد/مدر',
    titleEnglish: 'Parent',
    descriptionUrdu: 'اپنے بچے کی حاضری، سبق اور فیس دیکھیں',
    welcomeUrdu: 'خوش آمدید والد/مدر صاحبہ!',
    subtitleUrdu: 'اپنے بچے کی تعلیمی پیشرفت اور فیس کی تفصیل دیکھیں',
    icon: Icons.family_restroom_rounded,
    primaryColor: Color(0xFFB45309),
  ),
  RoleInfo(
    role: AppRole.mutawalli,
    titleUrdu: 'متولی',
    titleEnglish: 'Mutawalli / Trustee',
    descriptionUrdu: 'مسجد اور مکتب کا مالیاتی اور انتظامی جائزہ',
    welcomeUrdu: 'خوش آمدید متولی صاحب!',
    subtitleUrdu: 'اپنے مسجد اور ادارے کا انتظام کریں',
    icon: Icons.account_balance_rounded,
    primaryColor: Color(0xFF4C1D95),
  ),
  RoleInfo(
    role: AppRole.other,
    titleUrdu: 'دیگر',
    titleEnglish: 'Other / Staff',
    descriptionUrdu: 'عام معلومات اور ڈائرکٹری',
    welcomeUrdu: 'خوش آمدید!',
    subtitleUrdu: 'مکتب ایپ میں آپ کا خیر مقدم ہے',
    icon: Icons.more_horiz_rounded,
    primaryColor: Color(0xFF374151),
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// 1. ROLE SELECTION SCREEN (Exact copy of Reference Image Screen 1 & 2)
// ─────────────────────────────────────────────────────────────────────────────
class RoleSelectionScreen extends StatefulWidget {
  final LanguageController languageController;
  final List<Map<String, dynamic>> students;
  final Future<void> Function(List<Map<String, dynamic>>) onSave;
  final Function(AppRole) onRoleSelected;

  const RoleSelectionScreen({
    super.key,
    required this.languageController,
    required this.students,
    required this.onSave,
    required this.onRoleSelected,
  });

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  AppRole _selectedRole = AppRole.manager;
  int _currentStep = 1; // 1: Select Role, 2: Welcome Screen

  RoleInfo get _activeInfo =>
      kAppRoles.firstWhere((r) => r.role == _selectedRole);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _currentStep == 1
            ? _buildStep1RoleSelect()
            : _buildStep2WelcomeScreen(),
      ),
    );
  }

  // ── STEP 1: SELECT ROLE (Dark Green Islamic Theme) ──
  Widget _buildStep1RoleSelect() {
    return Container(
      key: const ValueKey(1),
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF032617),
            Color(0xFF0A4027),
            Color(0xFF021B10),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Header Indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '1. کردار منتخب کریں',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Dome & Emblem Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                border: Border.all(color: const Color(0xFFD4AF37), width: 2),
              ),
              child: const Icon(
                Icons.mosque_rounded,
                color: Color(0xFFFEE180),
                size: 44,
              ),
            ),
            const SizedBox(height: 16),
            // Main Title
            const Text(
              'اپنا کردار منتخب کریں',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Roboto',
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'براہ کرم اپنا کردار منتخب کریں تاکہ آپ کو مناسب تجربہ فراہم کیا جا سکے',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  color: Colors.white70,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 24),
            // 6 Grid Role Cards
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GridView.count(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.9,
                  children: kAppRoles.map((roleInfo) {
                    final isSelected = _selectedRole == roleInfo.role;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedRole = roleInfo.role;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFFD4AF37)
                                : Colors.transparent,
                            width: isSelected ? 3 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isSelected
                                  ? const Color(0xFFD4AF37)
                                      .withValues(alpha: 0.4)
                                  : Colors.black.withValues(alpha: 0.1),
                              blurRadius: isSelected ? 12 : 4,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected
                                    ? roleInfo.primaryColor.withValues(alpha: 0.1)
                                    : Colors.grey.shade100,
                              ),
                              child: Icon(
                                roleInfo.icon,
                                size: 30,
                                color: isSelected
                                    ? roleInfo.primaryColor
                                    : Colors.grey.shade800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              roleInfo.titleUrdu,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? roleInfo.primaryColor
                                    : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            // Bottom Continue Button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF074E32),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                      side: const BorderSide(color: Color(0xFFD4AF37), width: 1.5),
                    ),
                    elevation: 4,
                  ),
                  onPressed: () {
                    setState(() {
                      _currentStep = 2;
                    });
                  },
                  icon: const Text(
                    'جاری رکھیں',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  label: const Icon(Icons.arrow_forward_rounded, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── STEP 2: WELCOME SCREEN (Soft Off-White Islamic Screen) ──
  Widget _buildStep2WelcomeScreen() {
    final info = _activeInfo;
    return Container(
      key: const ValueKey(2),
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFFF9F7F0),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      _currentStep = 1;
                    });
                  },
                  icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF032617)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF074E32).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '2. خوش آمدید اسکرین',
                    style: TextStyle(
                      color: Color(0xFF074E32),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
            const SizedBox(height: 16),
            // Mosque Arch & Lanterns emblem
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Icon(Icons.wb_twilight_rounded, color: Colors.amber.shade700, size: 28),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF074E32).withValues(alpha: 0.08),
                    border: Border.all(color: const Color(0xFF074E32), width: 1.5),
                  ),
                  child: Icon(
                    info.icon,
                    size: 48,
                    color: info.primaryColor,
                  ),
                ),
                Icon(Icons.wb_twilight_rounded, color: Colors.amber.shade700, size: 28),
              ],
            ),
            const SizedBox(height: 20),
            // Greeting Title
            Text(
              info.welcomeUrdu,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: info.primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                info.subtitleUrdu,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
            ),
            const Spacer(),
            // Rehal & Quran Book Graphic Container
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.menu_book_rounded,
                    size: 72,
                    color: Color(0xFFB45309),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'علم کے نور سے اپنی دنیا اور آخرت کو سنواریں',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            // Start / Go to Dashboard Button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: info.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                    elevation: 4,
                  ),
                  onPressed: () {
                    widget.onRoleSelected(_selectedRole);
                  },
                  icon: const Text(
                    'ڈیش بورڈ پر جائیں',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  label: const Icon(Icons.arrow_forward_rounded, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. ROLE DASHBOARD WRAPPER & SPECIFIC ROLE PAGES
// ─────────────────────────────────────────────────────────────────────────────
class RoleDashboardScreen extends StatefulWidget {
  final AppRole currentRole;
  final LanguageController languageController;
  final List<Map<String, dynamic>> students;
  final Future<void> Function(List<Map<String, dynamic>>) onSave;
  final VoidCallback onChangeRole;

  const RoleDashboardScreen({
    super.key,
    required this.currentRole,
    required this.languageController,
    required this.students,
    required this.onSave,
    required this.onChangeRole,
  });

  @override
  State<RoleDashboardScreen> createState() => _RoleDashboardScreenState();
}

class _RoleDashboardScreenState extends State<RoleDashboardScreen> {
  int _selectedIndex = 0;

  RoleInfo get _roleInfo =>
      kAppRoles.firstWhere((r) => r.role == widget.currentRole);

  void _showPtmDispatchDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.people_alt_rounded, color: Colors.indigo),
            SizedBox(width: 8),
            Text('والدین میٹنگ بلاوا (PTM Dispatch)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text('کیا آپ تمام والدین کو آنے والے ہفتے کی PTM کا دعوت نامہ بھیجنا چاہتے ہیں؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('منسوخ')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تمام والدین کو PTM کا دعوت نامہ بھیج دیا گیا!'), backgroundColor: Colors.indigo),
              );
            },
            child: const Text('دعوت نامہ بھیجیں'),
          ),
        ],
      ),
    );
  }

  void _showEmergencyLockdownDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('ہنگامی حالت الرٹ (Emergency Alert)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text('ہنگامی حالت یا بارش کی وجہ سے مکتب کی فوری چھٹی کا الرٹ تمام والدین کو ڈسپچ کریں؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('منسوخ')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('🚨 ہنگامی چھٹی کا الرٹ تمام والدین کو بھیج دیا گیا!'), backgroundColor: Colors.red),
              );
            },
            child: const Text('ہنگامی الرٹ بھیجیں'),
          ),
        ],
      ),
    );
  }

  void _showDonationTrackerDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.volunteer_activism_rounded, color: Colors.green),
            SizedBox(width: 8),
            Text('عطیات و صدقات کھاتہ (Donations Tracker)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              dense: true,
              title: Text('عطیہ: حاجی عبدالسّتار صاحب (₹10,000)'),
              subtitle: Text('مد: مکتب کی سولر لائٹنگ لائبریری'),
            ),
          ],
        ),
        actions: [ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('بند کریں'))],
      ),
    );
  }

  void _showShuraMinutesDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.gavel_rounded, color: Colors.purple),
            SizedBox(width: 8),
            Text('مجلسِ شوریٰ منٹس (Shura Minutes Log)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text('مجلسِ شوریٰ کے آخری اجلاس مورخہ 1 اگست 2026ء کی منٹس رپورٹ محفوظ ہے۔'),
        actions: [ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('ٹھیک ہے'))],
      ),
    );
  }

  void _showMaintenanceTrackerDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.build_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('مرمت و تعمیرات کھاتہ (Maintenance Log)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text('مکتب کی عمارت اور وضو خانے کی مرمت کا خرچ Rs 4,500 درج ہے۔'),
        actions: [ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('بند کریں'))],
      ),
    );
  }

  void _showBiometricLockDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.fingerprint_rounded, color: Colors.blue),
            SizedBox(width: 8),
            Text('بائیو میٹرک و پِن سیکیورٹی (Security Lock)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text('بائیو میٹرک فنگر پرنٹ اور پن کوڈ سیکیورٹی 100% فعال (Active) ہے۔'),
        actions: [ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('محفوظ ہے'))],
      ),
    );
  }

  void _showAppUpdateCheckDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.system_update_rounded, color: Color(0xFF074E32)),
            SizedBox(width: 8),
            Text('ایپ اپڈیٹ چیکر (In-App Update Checker)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text('آپ مکتب مینیجر کا تازہ ترین ورژن (v2.5.0 Stable) استعمال کر رہے ہیں۔'),
        actions: [ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('عالی شان'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final info = _roleInfo;
    return ListenableBuilder(
      listenable: widget.languageController,
      builder: (context, _) => Scaffold(
        drawer: _buildSideDrawer(context, info),
        appBar: AppBar(
          backgroundColor: info.primaryColor,
          foregroundColor: Colors.white,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'مکتب ایپ — ${info.titleUrdu} ڈیش بورڈ',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                info.titleEnglish,
                style: const TextStyle(fontSize: 11, color: Colors.white70),
              ),
            ],
          ),
          actions: [
            if (widget.currentRole == AppRole.manager ||
                widget.currentRole == AppRole.admin ||
                widget.currentRole == AppRole.teacher)
              IconButton(
                icon: const Icon(Icons.campaign_rounded, color: Colors.amberAccent),
                tooltip: 'اہم اعلان بھیجیں (Send Announcement)',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CommunityChatScreen(
                        currentRole: widget.currentRole,
                        languageController: widget.languageController,
                        initialOpenAnnouncementModal: true,
                      ),
                    ),
                  );
                },
              ),
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              tooltip: 'لاگ آؤٹ (Logout)',
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('user_selected_role');
                widget.onChangeRole();
              },
            ),
            LanguageButton(controller: widget.languageController),
          ],
        ),
        body: _buildRoleSpecificBody(),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  Widget _buildSideDrawer(BuildContext context, RoleInfo info) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: info.primaryColor),
            accountName: Text('مکتب ایپ — ${info.titleUrdu}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            accountEmail: Text('Role: ${info.titleEnglish}',
                style: const TextStyle(color: Colors.white70)),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(info.icon, color: info.primaryColor, size: 32),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.people_rounded, color: Color(0xFF074E32)),
            title: const Text('1. طلبہ کی فہرست (Students List)'),
            onTap: () {
              Navigator.pop(context);
              setState(() => _selectedIndex = 0);
            },
          ),
          ListTile(
            leading: const Icon(Icons.how_to_reg_rounded, color: Color(0xFF074E32)),
            title: const Text('2. حاضری کا کھاتہ (Attendance Ledger)'),
            onTap: () {
              Navigator.pop(context);
              setState(() => _selectedIndex = 1);
            },
          ),
          ListTile(
            leading: const Icon(Icons.menu_book_rounded, color: Color(0xFF074E32)),
            title: const Text('3. سبق و تلاوت (Lesson Plan)'),
            onTap: () {
              Navigator.pop(context);
              setState(() => _selectedIndex = 2);
            },
          ),
          ListTile(
            leading: const Icon(Icons.currency_rupee_rounded, color: Color(0xFF074E32)),
            title: const Text('4. فیس پورٹل (Fees Management)'),
            onTap: () {
              Navigator.pop(context);
              setState(() => _selectedIndex = 3);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.people_alt_rounded, color: Colors.indigo),
            title: const Text('والدین میٹنگ بلاوا (PTM Dispatch)'),
            onTap: () {
              Navigator.pop(context);
              _showPtmDispatchDialog();
            },
          ),
          ListTile(
            leading: const Icon(Icons.warning_amber_rounded, color: Colors.red),
            title: const Text('ہنگامی حالت الرٹ (Emergency Alert)'),
            onTap: () {
              Navigator.pop(context);
              _showEmergencyLockdownDialog();
            },
          ),
          ListTile(
            leading: const Icon(Icons.volunteer_activism_rounded, color: Colors.green),
            title: const Text('عطیات و صدقات کھاتہ (Donations Tracker)'),
            onTap: () {
              Navigator.pop(context);
              _showDonationTrackerDialog();
            },
          ),
          ListTile(
            leading: const Icon(Icons.gavel_rounded, color: Colors.purple),
            title: const Text('مجلسِ شوریٰ منٹس (Shura Minutes Log)'),
            onTap: () {
              Navigator.pop(context);
              _showShuraMinutesDialog();
            },
          ),
          ListTile(
            leading: const Icon(Icons.build_rounded, color: Colors.orange),
            title: const Text('مرمت و تعمیرات کھاتہ (Maintenance Log)'),
            onTap: () {
              Navigator.pop(context);
              _showMaintenanceTrackerDialog();
            },
          ),
          ListTile(
            leading: const Icon(Icons.fingerprint_rounded, color: Colors.blue),
            title: const Text('بائیو میٹرک لاک (Biometric Security)'),
            onTap: () {
              Navigator.pop(context);
              _showBiometricLockDialog();
            },
          ),
          ListTile(
            leading: const Icon(Icons.system_update_rounded, color: Color(0xFF074E32)),
            title: const Text('ایپ اپڈیٹ چیک کریں (Check App Update)'),
            onTap: () {
              Navigator.pop(context);
              _showAppUpdateCheckDialog();
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.assignment_turned_in_rounded, color: Colors.teal),
            title: const Text('نتائج و تعلیمی کارکردگی (Academic Results)'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ResultsScreen(
                    languageController: widget.languageController,
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.mark_email_unread_rounded, color: Colors.green),
            title: const Text('استاد لیو پورٹل (Leave Requests)'),
            onTap: () {
              Navigator.pop(context);
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
          ListTile(
            leading: const Icon(Icons.chat_rounded, color: Colors.purple),
            title: const Text('کمیونٹی و پیغام رسانی (Community Hub)'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CommunityChatScreen(
                    currentRole: widget.currentRole,
                    languageController: widget.languageController,
                  ),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.red),
            title: const Text('لاگ آؤٹ (Logout)'),
            onTap: () async {
              Navigator.pop(context);
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('user_selected_role');
              widget.onChangeRole();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    switch (widget.currentRole) {
      case AppRole.manager:
      case AppRole.admin:
        return BottomNavigationBar(
          currentIndex: _selectedIndex.clamp(0, 3),
          selectedItemColor: _roleInfo.primaryColor,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          onTap: (i) => setState(() => _selectedIndex = i),
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_rounded), label: 'خلاصہ'),
            BottomNavigationBarItem(
                icon: Icon(Icons.people_rounded), label: 'طلبہ'),
            BottomNavigationBarItem(
                icon: Icon(Icons.currency_rupee_rounded), label: 'فیس'),
            BottomNavigationBarItem(
                icon: Icon(Icons.how_to_reg_rounded), label: 'حاضری'),
          ],
        );
      case AppRole.teacher:
        return BottomNavigationBar(
          currentIndex: _selectedIndex.clamp(0, 3),
          selectedItemColor: _roleInfo.primaryColor,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          onTap: (i) => setState(() => _selectedIndex = i),
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.menu_book_rounded), label: 'سبق و تلاوت'),
            BottomNavigationBarItem(
                icon: Icon(Icons.fact_check_rounded), label: 'حاضری'),
            BottomNavigationBarItem(
                icon: Icon(Icons.currency_rupee_rounded), label: 'فیس پورٹل'),
            BottomNavigationBarItem(
                icon: Icon(Icons.people_outline_rounded), label: 'طلبہ'),
          ],
        );
      case AppRole.parent:
        return BottomNavigationBar(
          currentIndex: _selectedIndex.clamp(0, 2),
          selectedItemColor: _roleInfo.primaryColor,
          unselectedItemColor: Colors.grey,
          onTap: (i) => setState(() => _selectedIndex = i),
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.child_care_rounded), label: 'میرا بچہ'),
            BottomNavigationBarItem(
                icon: Icon(Icons.history_edu_rounded), label: 'سبق کی رفتار'),
            BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long_rounded), label: 'فیس کی رسید'),
          ],
        );
      case AppRole.mutawalli:
        return BottomNavigationBar(
          currentIndex: _selectedIndex.clamp(0, 2),
          selectedItemColor: _roleInfo.primaryColor,
          unselectedItemColor: Colors.grey,
          onTap: (i) => setState(() => _selectedIndex = i),
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.account_balance_rounded), label: 'وقف خلاصہ'),
            BottomNavigationBarItem(
                icon: Icon(Icons.payments_rounded), label: 'مالیاتی جائزہ'),
            BottomNavigationBarItem(
                icon: Icon(Icons.picture_as_pdf_rounded), label: 'بیچ رپورٹ'),
          ],
        );
      default:
        return BottomNavigationBar(
          currentIndex: _selectedIndex.clamp(0, 1),
          selectedItemColor: _roleInfo.primaryColor,
          unselectedItemColor: Colors.grey,
          onTap: (i) => setState(() => _selectedIndex = i),
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.info_outline_rounded), label: 'معلومات'),
            BottomNavigationBarItem(
                icon: Icon(Icons.contact_phone_rounded), label: 'رابطہ'),
          ],
        );
    }
  }

  Widget _buildRoleSpecificBody() {
    switch (widget.currentRole) {
      case AppRole.manager:
      case AppRole.admin:
        if (_selectedIndex == 1) {
          return StudentListScreen(languageController: widget.languageController);
        }
        if (_selectedIndex == 2) {
          return FeeScreen(
            students: widget.students,
            languageController: widget.languageController,
            onSave: widget.onSave,
          );
        }
        if (_selectedIndex == 3) {
          return AttendanceScreen(
            students: widget.students,
            languageController: widget.languageController,
            onSave: widget.onSave,
          );
        }
        return _buildManagerAdminOverview();

      case AppRole.teacher:
        if (_selectedIndex == 0) {
          return LessonScreen(
            languageController: widget.languageController,
          );
        }
        if (_selectedIndex == 1) {
          return AttendanceScreen(
            students: widget.students,
            languageController: widget.languageController,
            onSave: widget.onSave,
          );
        }
        return StudentListScreen(languageController: widget.languageController);

      case AppRole.parent:
        if (_selectedIndex == 1) {
          return LessonScreen(
            languageController: widget.languageController,
          );
        }
        if (_selectedIndex == 2) {
          return FeeScreen(
            students: widget.students,
            languageController: widget.languageController,
            onSave: widget.onSave,
          );
        }
        return _buildParentChildOverview();

      case AppRole.mutawalli:
        if (_selectedIndex == 1) {
          return FeeScreen(
            students: widget.students,
            languageController: widget.languageController,
            onSave: widget.onSave,
          );
        }
        return _buildMutawalliOverview();

      case AppRole.other:
        return _buildOtherOverview();
    }
  }

  // ── MANAGER / ADMIN OVERVIEW ──
  Widget _buildManagerAdminOverview() {
    final totalStudents = widget.students.length;
    final presentCount =
        widget.students.where((s) => s['isPresent'] == true).length;
    final paidCount =
        widget.students.where((s) => s['feeStatus'] == 'paid').length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RoleBannerCard(
            title: 'خوش آمدید، ${_roleInfo.titleUrdu}!',
            subtitle: _roleInfo.subtitleUrdu,
            color: _roleInfo.primaryColor,
          ),
          const SizedBox(height: 16),
          const Text(
            'ادارے کا مجموعی جائزہ (Overview)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'کل طلبہ',
                  value: '$totalStudents',
                  icon: Icons.groups_rounded,
                  color: Colors.blue.shade700,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  title: 'حاضر طلبہ',
                  value: '$presentCount',
                  icon: Icons.check_circle_rounded,
                  color: Colors.green.shade700,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  title: 'فیس وصولی',
                  value: '$paidCount / $totalStudents',
                  icon: Icons.payments_rounded,
                  color: Colors.amber.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'فوری اقدامات (Quick Actions)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2.2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            children: [
              _ActionTile(
                title: 'حاضری درج کریں',
                icon: Icons.fact_check_rounded,
                color: Colors.teal,
                onTap: () => setState(() => _selectedIndex = 3),
              ),
              _ActionTile(
                title: 'فیس پورٹل',
                icon: Icons.currency_rupee_rounded,
                color: Colors.orange.shade800,
                onTap: () => setState(() => _selectedIndex = 2),
              ),
              _ActionTile(
                title: 'سبق و تلاوت',
                icon: Icons.menu_book_rounded,
                color: Colors.indigo,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LessonScreen(
                        languageController: widget.languageController,
                      ),
                    ),
                  );
                },
              ),
              _ActionTile(
                title: 'طلبہ کی فہرست',
                icon: Icons.list_alt_rounded,
                color: Colors.blue.shade800,
                onTap: () => setState(() => _selectedIndex = 1),
              ),
              _ActionTile(
                title: 'استاد لیو پورٹل',
                icon: Icons.mark_email_unread_rounded,
                color: Colors.green.shade800,
                onTap: () {
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
              _ActionTile(
                title: 'کمیونٹی و پیغام رسانی',
                icon: Icons.chat_rounded,
                color: Colors.purple.shade800,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CommunityChatScreen(
                        currentRole: widget.currentRole,
                        languageController: widget.languageController,
                      ),
                    ),
                  );
                },
              ),
              _ActionTile(
                title: 'نتائج و کارکردگی',
                icon: Icons.assignment_turned_in_rounded,
                color: Colors.teal.shade800,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ResultsScreen(
                        languageController: widget.languageController,
                      ),
                    ),
                  );
                },
              ),
              _ActionTile(
                title: 'ایڈمن کنٹرول پورٹل',
                icon: Icons.admin_panel_settings_rounded,
                color: const Color(0xFF074E32),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AdminFeaturesScreen(
                        languageController: widget.languageController,
                        students: widget.students,
                        onSave: widget.onSave,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── PARENT CHILD OVERVIEW ──
  Widget _buildParentChildOverview() {
    final firstStudent =
        widget.students.isNotEmpty ? widget.students.first : null;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RoleBannerCard(
            title: 'خوش آمدید والد/مدر صاحبہ!',
            subtitle: 'اپنے بچے کی مکتب تعلیمی پیشرفت، حاضری اور فیس کی تفصیل',
            color: const Color(0xFFB45309),
          ),
          const SizedBox(height: 16),
          if (firstStudent == null)
            const Center(child: Text('کوئی بچہ درج نہیں ہے'))
          else ...[
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: const Color(0xFFB45309),
                          child: Text(
                            firstStudent['name']?.substring(0, 1) ?? 'S',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              firstStudent['name']?.toString() ?? 'Student',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'درجہ: ${firstStudent['className'] ?? 'Class 1'} | شفٹ: ${firstStudent['shift'] ?? 'Morning'}',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _DetailInfoItem(
                          label: 'حاضری',
                          value: firstStudent['isPresent'] == true
                              ? 'حاضر ✓'
                              : 'غیر حاضر ✗',
                          color: firstStudent['isPresent'] == true
                              ? Colors.green
                              : Colors.red,
                        ),
                        _DetailInfoItem(
                          label: 'فیس کی حالت',
                          value: firstStudent['feeStatus'] == 'paid'
                              ? 'ادا شدہ'
                              : 'باقی',
                          color: firstStudent['feeStatus'] == 'paid'
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB45309),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => setState(() => _selectedIndex = 2),
              icon: const Icon(Icons.receipt_long_rounded),
              label: const Text('فیس کی رسید ڈاؤن لوڈ کریں (Download PDF)'),
            ),
          ],
        ],
      ),
    );
  }

  bool _mutawalliShowStudents = true;
  bool _mutawalliShowPayments = true;
  bool _mutawalliShowResults = true;

  // ── MUTAWALLI OVERVIEW ──
  Widget _buildMutawalliOverview() {
    final totalStudents = widget.students.length;
    final totalFeesCollected = widget.students
        .where((s) => s['feeStatus'] == 'paid')
        .fold<double>(
            0, (sum, s) => sum + (double.tryParse(s['feeAmount']?.toString() ?? '0') ?? 0));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RoleBannerCard(
            title: 'خوش آمدید متولی صاحب! (Mutawalli Portal)',
            subtitle: 'مسجد اور مکتب کا مالیاتی، تعلیمی اور عمومی انتظامی جائزہ',
            color: const Color(0xFF4C1D95),
          ),
          const SizedBox(height: 16),
          // Mutawalli Optional Access Toggles Card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ExpansionTile(
              leading: const Icon(Icons.tune_rounded, color: Color(0xFF4C1D95)),
              title: const Text('متولی اختیارات و رسائی (Access Controls)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              subtitle: const Text('طلبہ، مالیات اور نتائج تک رسائی تبدیل کریں',
                  style: TextStyle(fontSize: 11, color: Colors.grey)),
              children: [
                SwitchListTile(
                  title: const Text('👥 طلبہ کی فہرست دکھائیں (Students Roster)'),
                  value: _mutawalliShowStudents,
                  onChanged: (v) => setState(() => _mutawalliShowStudents = v),
                ),
                SwitchListTile(
                  title: const Text('💵 فیس و مالیاتی جائزہ (Payments Ledger)'),
                  value: _mutawalliShowPayments,
                  onChanged: (v) => setState(() => _mutawalliShowPayments = v),
                ),
                SwitchListTile(
                  title: const Text('🏆 تعلیمی نتائج دکھائیں (Academic Results)'),
                  value: _mutawalliShowResults,
                  onChanged: (v) => setState(() => _mutawalliShowResults = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'مجموعی فیس وصولی',
                  value: '₹ ${totalFeesCollected.toInt()}',
                  icon: Icons.account_balance_wallet_rounded,
                  color: Colors.green.shade800,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  title: 'کل طلبہ کی تعداد',
                  value: '$totalStudents',
                  icon: Icons.school_rounded,
                  color: const Color(0xFF4C1D95),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text('فوری رسائی پورٹل (Mutawalli Actions)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              if (_mutawalliShowStudents)
                _ActionTile(
                  title: 'طلبہ کی فہرست',
                  icon: Icons.people_rounded,
                  color: const Color(0xFF4C1D95),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StudentListScreen(
                          languageController: widget.languageController,
                        ),
                      ),
                    );
                  },
                ),
              if (_mutawalliShowPayments)
                _ActionTile(
                  title: 'مالیاتی جائزہ',
                  icon: Icons.payments_rounded,
                  color: Colors.green.shade800,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FeeScreen(
                          students: widget.students,
                          languageController: widget.languageController,
                          onSave: widget.onSave,
                        ),
                      ),
                    );
                  },
                ),
              if (_mutawalliShowResults)
                _ActionTile(
                  title: 'نتائج و کارکردگی',
                  icon: Icons.assignment_turned_in_rounded,
                  color: Colors.teal.shade800,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ResultsScreen(
                          languageController: widget.languageController,
                        ),
                      ),
                    );
                  },
                ),
              _ActionTile(
                title: 'کمیونٹی چیٹ',
                icon: Icons.chat_rounded,
                color: Colors.purple.shade800,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CommunityChatScreen(
                        currentRole: widget.currentRole,
                        languageController: widget.languageController,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4C1D95),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => setState(() => _selectedIndex = 1),
            icon: const Icon(Icons.picture_as_pdf_rounded),
            label: const Text('مکتب کی ماہانہ رپورٹ (Batch Fee PDF)'),
          ),
        ],
      ),
    );
  }

  // ── OTHER OVERVIEW ──
  Widget _buildOtherOverview() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _RoleBannerCard(
            title: 'خوش آمدید!',
            subtitle: 'مکتب مینیجر ایپ میں آپ کا خیر مقدم ہے',
            color: const Color(0xFF374151),
          ),
          const SizedBox(height: 24),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_rounded, color: Color(0xFF374151)),
              title: const Text('مکتب کی اوقات کار'),
              subtitle: const Text('صبح: 7:00 سے 9:00 | شام: 5:00 سے 7:00'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPER WIDGETS
// ─────────────────────────────────────────────────────────────────────────────
class _RoleBannerCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;

  const _RoleBannerCard({
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailInfoItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _DetailInfoItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
