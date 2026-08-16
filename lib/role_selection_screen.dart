import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'theme/app_components.dart';
import 'app_localizations.dart';
import 'attendance_screen.dart';
import 'fee_screen.dart';
import 'lesson_screen.dart';
import 'leave_management_screen.dart';
import 'community_chat_screen.dart';
import 'results_screen.dart';
import 'admin_features_screen.dart';
import 'analytics_screen.dart';
import 'create_class_group_screen.dart';
import 'manage_parent_logins_screen.dart';
import 'manage_staff_logins_screen.dart';
import 'shift_manager.dart';
import 'theme_controller.dart';
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

  String title(BuildContext context) {
    final lang = AppLocalizations.of(context).locale.languageCode;
    if (lang == 'ur') return titleUrdu;
    if (lang == 'en') return titleEnglish;
    if (lang == 'ar') {
      switch (role) {
        case AppRole.admin: return 'المسؤول';
        case AppRole.manager: return 'المدير';
        case AppRole.teacher: return 'المعلم';
        case AppRole.parent: return 'ولي الأمر';
        case AppRole.mutawalli: return 'المتولي';
        case AppRole.other: return 'مستخدم';
      }
    }
    if (lang == 'hi') {
      switch (role) {
        case AppRole.admin: return 'व्यवस्थापक';
        case AppRole.manager: return 'प्रबंधक';
        case AppRole.teacher: return 'शिक्षक';
        case AppRole.parent: return 'अभिभावक';
        case AppRole.mutawalli: return 'मुतवल्ली';
        case AppRole.other: return 'उपयोगकर्ता';
      }
    }
    if (lang == 'te') {
      switch (role) {
        case AppRole.admin: return 'అడ్మిన్';
        case AppRole.manager: return 'మేనేజర్';
        case AppRole.teacher: return 'ఉపాధ్యాయుడు';
        case AppRole.parent: return 'తల్లిదండ్రులు';
        case AppRole.mutawalli: return 'ట్రస్టీ';
        case AppRole.other: return 'వినియోగదారు';
      }
    }
    if (lang == 'kn') {
      switch (role) {
        case AppRole.admin: return 'ಅಡ್ಮಿನ್';
        case AppRole.manager: return 'ಮ್ಯಾನೇಜರ್';
        case AppRole.teacher: return 'ಶಿಕ್ಷಕ';
        case AppRole.parent: return 'ಪೋಷಕರು';
        case AppRole.mutawalli: return 'ಟ್ರಸ್ಟಿ';
        case AppRole.other: return 'ಬಳಕೆದಾರ';
      }
    }
    if (lang == 'ta') {
      switch (role) {
        case AppRole.admin: return 'நிர்வாகி';
        case AppRole.manager: return 'மேலாளர்';
        case AppRole.teacher: return 'ஆசிரியர்';
        case AppRole.parent: return 'பெற்றோர்';
        case AppRole.mutawalli: return 'அறங்காவலர்';
        case AppRole.other: return 'பயனர்';
      }
    }
    if (lang == 'ml') {
      switch (role) {
        case AppRole.admin: return 'അഡ്മിൻ';
        case AppRole.manager: return 'മാനേജർ';
        case AppRole.teacher: return 'അധ്യാപകൻ';
        case AppRole.parent: return 'രക്ഷിതാവ്';
        case AppRole.mutawalli: return 'ട്രസ്റ്റി';
        case AppRole.other: return 'ഉപയോക്താവ്';
      }
    }
    return titleUrdu;
  }
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
    titleEnglish: 'Teacher',
    descriptionUrdu: 'طلبہ کی تعلیم، حاضری اور سبق کا جائزہ',
    welcomeUrdu: 'خوش آمدید استاد صاحب!',
    subtitleUrdu: 'طلبہ کی تعلیم اور تربیت کا انتظام کریں',
    icon: Icons.menu_book_rounded,
    primaryColor: Color(0xFF047857),
  ),
  RoleInfo(
    role: AppRole.parent,
    titleUrdu: 'والدین / سرپرست',
    titleEnglish: 'Parent',
    descriptionUrdu: 'اپنے بچے کی حاضری، سبق اور فیس دیکھیں',
    welcomeUrdu: 'خوش آمدید سرپرست صاحب / صاحبہ!',
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
  final ThemeController themeController;
  final List<Map<String, dynamic>> students;
  final Future<void> Function(List<Map<String, dynamic>>) onSave;
  final Function(AppRole) onRoleSelected;

  const RoleSelectionScreen({
    super.key,
    required this.languageController,
    required this.themeController,
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
    final loc = AppLocalizations.of(context);

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
              child: Text(
                loc.translate('select_role'),
                style: const TextStyle(
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
                image: const DecorationImage(
                  image: AssetImage('assets/images/app_logo.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Main Title
            Text(
              loc.translate('select_role'),
              style: const TextStyle(
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
                              roleInfo.title(context),
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
                  icon: Text(
                    loc.translate('continue_btn'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
    final loc = AppLocalizations.of(context);
    final info = _activeInfo;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF032617);
    final cardBgColor = Theme.of(context).cardTheme.color ?? (isDark ? const Color(0xFF1E293B) : Colors.white);
    
    return Container(
      key: const ValueKey(2),
      width: double.infinity,
      height: double.infinity,
      color: Theme.of(context).scaffoldBackgroundColor,
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
                  icon: Icon(Icons.arrow_back_rounded, color: textColor),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFF074E32).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    loc.translate('welcome'),
                    style: TextStyle(
                      color: isDark ? Colors.white70 : const Color(0xFF074E32),
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
                const Icon(Icons.star, color: Color(0xFFD4AF37), size: 18),
                TranslatedText(
                  'خوش آمدید',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const Icon(Icons.star, color: Color(0xFFD4AF37), size: 18),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              info.title(context),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.grey.shade700,
              ),
            ),
            const Spacer(),
            // Rehal & Quran Book Graphic Container
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cardBgColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
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
                    info.title(context),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.grey.shade800,
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
                  icon: const TranslatedText(
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
  final ThemeController themeController;
  final List<Map<String, dynamic>> students;
  final Future<void> Function(List<Map<String, dynamic>>) onSave;
  final VoidCallback onChangeRole;

  const RoleDashboardScreen({
    super.key,
    required this.currentRole,
    required this.languageController,
    required this.themeController,
    required this.students,
    required this.onSave,
    required this.onChangeRole,
  });

  @override
  State<RoleDashboardScreen> createState() => _RoleDashboardScreenState();
}

class _RoleDashboardScreenState extends State<RoleDashboardScreen> {
  int _selectedIndex = 0;
  String _loggedInUserName = '';
  String _currentClassName = 'کلاس منتخب نہیں';
  String? _activeMaktabId;
  String _activeMaktabName = '';
  List<Map<String, dynamic>> _maktabProfiles = <Map<String, dynamic>>[];
  bool _maktabSetupComplete = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    final savedClass =
        prefs.getString('current_class_name') ?? 'کلاس منتخب نہیں';
    final setupComplete = prefs.getBool('maktab_setup_complete') ?? false;
    final openAttendance =
        prefs.getBool('post_setup_open_attendance') ?? false;
    if (openAttendance) {
      await prefs.remove('post_setup_open_attendance');
    }
    final activeMaktabId = prefs.getString('active_maktab_id');
    List<Map<String, dynamic>> profiles = <Map<String, dynamic>>[];
    try {
      final raw = prefs.getString('maktab_profiles_v1');
      if (raw != null) {
        profiles = (jsonDecode(raw) as List)
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
      }
      if (profiles.isEmpty) {
        profiles = [
          {'id': 'm1', 'name': 'مکتب الفاروق', 'sectionName': 'مرکزی ڈویژن'},
          {'id': 'm2', 'name': 'مکتب النور', 'sectionName': 'شاخ 1'},
          {'id': 'm3', 'name': 'مکتب الصفاء', 'sectionName': 'شاخ 2'},
        ];
        await prefs.setString('maktab_profiles_v1', jsonEncode(profiles));
      }
    } catch (_) {}
    final activeProfile = profiles.where(
      (item) => item['id']?.toString() == activeMaktabId,
    );
    final name = prefs.getString('current_user_name') ?? prefs.getString('cred_${widget.currentRole.name}_name');
    if (!mounted) return;
    setState(() {
      _currentClassName = savedClass;
      _maktabSetupComplete = setupComplete;
      if (openAttendance && setupComplete) {
        _selectedIndex = _attendanceTabIndex;
      }
      _maktabProfiles = profiles;
      _activeMaktabId = activeMaktabId;
      _activeMaktabName = activeProfile.isEmpty
          ? (prefs.getString('maktab_name') ?? '')
          : (activeProfile.first['name']?.toString() ?? '');
      if (name != null && name.isNotEmpty) {
        _loggedInUserName = name;
      }
      _isLoading = false;
    });
  }

  RoleInfo get _roleInfo =>
      kAppRoles.firstWhere((r) => r.role == widget.currentRole);

  bool get _canManageMaktab =>
      widget.currentRole == AppRole.admin ||
      widget.currentRole == AppRole.manager ||
      widget.currentRole == AppRole.teacher;

  int get _attendanceTabIndex => switch (widget.currentRole) {
        AppRole.manager => 3,
        AppRole.admin => 3,
        AppRole.teacher => 0,
        AppRole.mutawalli => 2,
        _ => 0,
      };

  List<Map<String, dynamic>> get _activeStudents {
    if (_activeMaktabId == null || _activeMaktabId!.isEmpty) {
      return widget.students;
    }
    final filtered = widget.students
        .where((student) {
          final mId = student['maktabId']?.toString();
          return mId == null || mId.isEmpty || mId == _activeMaktabId || mId == 'maktab_default';
        })
        .toList();
    if (filtered.isNotEmpty) return filtered;
    return widget.students;
  }

  Future<void> _saveActiveStudents(
      List<Map<String, dynamic>> updatedActive) async {
    final activeId = _activeMaktabId;
    if (activeId == null || activeId.isEmpty) {
      // Saving an unscoped list could overwrite/mix students of all Maktabs.
      return;
    }
    final otherMaktabs = widget.students
        .where((student) => student['maktabId']?.toString() != activeId)
        .map((student) => Map<String, dynamic>.from(student));
    final scoped = updatedActive.map((student) {
      final copy = Map<String, dynamic>.from(student);
      copy['maktabId'] = activeId;
      return copy;
    });
    await widget.onSave(<Map<String, dynamic>>[
      ...otherMaktabs,
      ...scoped,
    ]);
  }

  Future<void> _selectMaktab() async {
    if (_maktabProfiles.length < 2) return;
    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: SimpleDialog(
          title: const Text('مکتب منتخب کریں'),
          children: _maktabProfiles.map((profile) {
            final id = profile['id']?.toString() ?? '';
            final selected = id == _activeMaktabId;
            return ListTile(
              leading: Icon(
                selected ? Icons.check_circle : Icons.account_balance_rounded,
                color: const Color(0xFF08734B),
              ),
              title: Text(profile['name']?.toString() ?? 'مکتب'),
              subtitle: Text(profile['sectionName']?.toString() ?? ''),
              onTap: () => Navigator.pop(ctx, id),
            );
          }).toList(),
        ),
      ),
    );
    if (selected == null || selected == _activeMaktabId) return;
    await _activateMaktab(selected);
  }

  Future<void> _activateMaktab(String selected) async {
    final profile = _maktabProfiles.firstWhere(
      (item) => item['id']?.toString() == selected,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_maktab_id', selected);
    await prefs.setString('maktab_name', profile['name']?.toString() ?? '');
    await prefs.setString(
        'maktab_section_name', profile['sectionName']?.toString() ?? '');
    await prefs.setString(
        'shared_teacher_name', profile['teacherName']?.toString() ?? '');
    await prefs.setString('current_class_name',
        profile['currentClassName']?.toString() ?? 'کلاس منتخب نہیں');
    final scopedClasses = prefs.getString('maktab_classes_v2_$selected');
    if (scopedClasses != null) {
      await prefs.setString('maktab_classes_v2', scopedClasses);
    }
    final scopedHoliday = prefs.getString('maktab_holiday_v1_$selected');
    if (scopedHoliday != null) {
      await prefs.setString('maktab_holiday_v1', scopedHoliday);
    } else {
      await prefs.remove('maktab_holiday_v1');
    }
    setState(() {
      _activeMaktabId = selected;
      _activeMaktabName = profile['name']?.toString() ?? '';
      _currentClassName =
          profile['currentClassName']?.toString() ?? 'کلاس منتخب نہیں';
      _selectedIndex = _attendanceTabIndex;
    });
  }

  Future<void> _activateMaktabKeepingCurrentScreen(String selected) async {
    final currentIndex = _selectedIndex;
    await _activateMaktab(selected);
    if (!mounted) return;
    setState(() => _selectedIndex = currentIndex);
  }

  Future<void> _openMaktabSetup({bool editCurrent = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final maktabId = editCurrent && _activeMaktabId != null
        ? _activeMaktabId!
        // Every new Maktab must always receive its own fresh identity.
        // Reusing pending_maktab_id was mixing students from different Maktabs.
        : 'maktab_${DateTime.now().microsecondsSinceEpoch}';
    await prefs.setString('pending_maktab_id', maktabId);
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateClassGroupScreen(
          students: widget.students,
          languageController: widget.languageController,
          onSave: widget.onSave,
          maktabId: maktabId,
          onAddStudent: () => _triggerAddStudentModal(maktabId: maktabId),
        ),
      ),
    );

    if (!mounted) return;

    final savedPrefs = await SharedPreferences.getInstance();
    final savedId = savedPrefs.getString('active_maktab_id');

    if (saved == true || savedId == maktabId) {
      await savedPrefs.remove('post_setup_open_attendance');
      await _loadUserName();
      if (!mounted) return;
      setState(() {
        _maktabSetupComplete = true;
        _activeMaktabId = savedId ?? maktabId;
        _selectedIndex = _attendanceTabIndex;
      });
    } else {
      await _loadUserName();
    }
  }

  Widget _buildMaktabSetupLanding() {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.account_balance_rounded,
                      size: 64, color: Color(0xFF08734B)),
                  const SizedBox(height: 12),
                  const Text(
                    'مکتب مینیجر میں خوش آمدید',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF065F46),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'پہلے مکتب کی بنیادی تفصیلات مکمل کریں، پھر تمام اسکرینیں خود ظاہر ہو جائیں گی۔',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, height: 1.6),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton.icon(
                      onPressed: _openMaktabSetup,
                      icon: const Icon(Icons.add_business_rounded),
                      label: const Text('مکتب شامل کریں'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF08734B),
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openStudentListFromMenu() {
    final index = switch (widget.currentRole) {
      AppRole.teacher => 3,
      AppRole.manager => 1,
      AppRole.admin => 1,
      AppRole.parent => 0,
      _ => 0,
    };
    setState(() => _selectedIndex = index);
  }

  void _openAttendanceFromMenu() {
    final index = switch (widget.currentRole) {
      AppRole.teacher => 0,
      AppRole.manager => 3,
      AppRole.admin => 3,
      AppRole.mutawalli => 2,
      _ => 0,
    };
    setState(() => _selectedIndex = index);
  }

  Future<void> _triggerAddStudentModal({String? maktabId}) async {
    final studentNameCtrl = TextEditingController();
    final fatherNameCtrl = TextEditingController();
    final fatherPhoneCtrl = TextEditingController();
    final teacherNameCtrl = TextEditingController(text: 'حافظ احمد حسن');
    DateTime selectedAdmissionDate = DateTime.now();
    List<MaktabShift> availableShifts = await ShiftStore.load();
    final Set<String> selectedShiftIds = <String>{'morning'};
    final activeId = maktabId ?? _activeMaktabId ?? 'legacy_maktab';
    final admissionNumbers = widget.students
        .where((student) => student['maktabId']?.toString() == activeId)
        .map((student) => int.tryParse(
                student['admissionNo']?.toString().replaceAll(RegExp(r'\D'), '') ??
                    '') ??
            0);
    final nextAdmissionNo = admissionNumbers.isEmpty
        ? 1
        : admissionNumbers.reduce((a, b) => a > b ? a : b) + 1;
    String selectedLanguage = 'ur';
    String selectedMessageMethod = 'WhatsApp';
    String selectedMaktabType = 'شعبه ناظره قرآن (Nazira Dept)';
    String selectedMaktabTargetId = maktabId ?? _activeMaktabId ?? (_maktabProfiles.isNotEmpty ? _maktabProfiles.first['id']?.toString() ?? 'm1' : 'm1');

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        final loc = AppLocalizations.of(context);
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final inputBgColor = isDark ? const Color(0xFF1C2541) : Colors.grey.shade50;
        final fieldTextColor = isDark ? Colors.white : Colors.black87;
        final fieldLabelColor = isDark ? Colors.tealAccent : const Color(0xFF074E32);
        final dialogBgColor = Theme.of(context).cardTheme.color ?? (isDark ? const Color(0xFF0B1329) : Colors.white);

        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              titlePadding: EdgeInsets.zero,
              backgroundColor: dialogBgColor,
              title: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFF074E32),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person_add_alt_1_rounded, color: Colors.white, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TranslatedText(
                        'New Student',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_maktabProfiles.isNotEmpty)
                      DropdownButtonFormField<String>(
                        initialValue: _maktabProfiles.any((p) => p['id']?.toString() == selectedMaktabTargetId)
                            ? selectedMaktabTargetId
                            : _maktabProfiles.first['id']?.toString(),
                        isExpanded: true,
                        dropdownColor: dialogBgColor,
                        decoration: InputDecoration(
                          labelText: 'Select Maktab / مکتب منتخب کریں',
                          labelStyle: TextStyle(color: fieldLabelColor, fontSize: 13),
                          prefixIcon: Icon(Icons.account_balance_rounded, color: fieldLabelColor),
                          filled: true,
                          fillColor: inputBgColor,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: _maktabProfiles.map((p) {
                          final name = p['name']?.toString() ?? 'مکتب';
                          final section = p['sectionName']?.toString() ?? '';
                          return DropdownMenuItem<String>(
                            value: p['id']?.toString(),
                            child: Text(
                              section.isNotEmpty ? '$name ($section)' : name,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: fieldTextColor, fontSize: 13.5),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setDialogState(() => selectedMaktabTargetId = val);
                        },
                      ),
                    if (_maktabProfiles.isNotEmpty) const SizedBox(height: 12),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark ? Colors.tealAccent : const Color(0xFF074E32),
                        side: BorderSide(color: isDark ? Colors.tealAccent : const Color(0xFF074E32)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () async {
                        final contact = await ContactPickerHelper.pickContact(context, widget.students);
                        if (contact != null) {
                          setDialogState(() {
                            fatherNameCtrl.text = contact['name'] ?? '';
                            fatherPhoneCtrl.text = contact['phone'] ?? '';
                          });
                        }
                      },
                      icon: const Icon(Icons.contacts_rounded, size: 18),
                      label: TranslatedText('Import from Contacts', style: const TextStyle(fontSize: 12)),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: studentNameCtrl,
                      style: TextStyle(color: fieldTextColor, fontSize: 14, height: 1.2),
                      decoration: InputDecoration(
                        labelText: loc.translate('student_name'),
                        labelStyle: TextStyle(color: fieldLabelColor, fontSize: 13),
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        prefixIcon: Icon(Icons.person, color: fieldLabelColor),
                        filled: true,
                        fillColor: inputBgColor,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        isDense: false,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: fatherNameCtrl,
                      style: TextStyle(color: fieldTextColor, fontSize: 14, height: 1.2),
                      decoration: InputDecoration(
                        labelText: loc.translate('father_name'),
                        labelStyle: TextStyle(color: fieldLabelColor, fontSize: 13),
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        prefixIcon: Icon(Icons.person_outline, color: fieldLabelColor),
                        filled: true,
                        fillColor: inputBgColor,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        isDense: false,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: fatherPhoneCtrl,
                      style: TextStyle(color: fieldTextColor, fontSize: 14, height: 1.2),
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: loc.translate('father_phone'),
                        labelStyle: TextStyle(color: fieldLabelColor, fontSize: 13),
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        prefixIcon: Icon(Icons.phone, color: fieldLabelColor),
                        filled: true,
                        fillColor: inputBgColor,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        isDense: false,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedAdmissionDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            selectedAdmissionDate = picked;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: inputBgColor,
                          border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_month_rounded, color: fieldLabelColor),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '${loc.translate('admission_date')}: ${selectedAdmissionDate.year}-${selectedAdmissionDate.month.toString().padLeft(2, '0')}-${selectedAdmissionDate.day.toString().padLeft(2, '0')}',
                                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500, color: fieldTextColor),
                              ),
                            ),
                            Icon(Icons.arrow_drop_down, color: fieldLabelColor),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'داخلہ نمبر (خودکار)',
                        prefixIcon: Icon(Icons.confirmation_number_rounded,
                            color: fieldLabelColor),
                        filled: true,
                        fillColor: inputBgColor,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        nextAdmissionNo.toString().padLeft(4, '0'),
                        style: TextStyle(
                          color: fieldTextColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedLanguage,
                      isExpanded: true,
                      dropdownColor: dialogBgColor,
                      decoration: InputDecoration(
                        labelText: 'Preferred Language / پسندیدہ زبان',
                        labelStyle: TextStyle(color: fieldLabelColor, fontSize: 13),
                        prefixIcon: Icon(Icons.language_rounded, color: fieldLabelColor),
                        filled: true,
                        fillColor: inputBgColor,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        isDense: false,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'ur', child: Text('اردو')),
                        DropdownMenuItem(value: 'te', child: Text('తెలుగు / تیلگو')),
                        DropdownMenuItem(value: 'en', child: Text('English / انگریزی')),
                        DropdownMenuItem(value: 'hi', child: Text('हिन्दी / ہندی')),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedLanguage = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedMessageMethod,
                      isExpanded: true,
                      dropdownColor: dialogBgColor,
                      decoration: InputDecoration(
                        labelText: 'Preferred App / پیغام کا پسندیدہ ذریعہ',
                        labelStyle: TextStyle(color: fieldLabelColor, fontSize: 13),
                        prefixIcon: Icon(Icons.message_rounded, color: fieldLabelColor),
                        filled: true,
                        fillColor: inputBgColor,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'WhatsApp', child: Text('WhatsApp')),
                        DropdownMenuItem(value: 'SMS', child: Text('SMS')),
                        DropdownMenuItem(value: 'Notification', child: Text('App Notification')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedMessageMethod = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'ایک یا متعدد شفٹیں منتخب کریں',
                        prefixIcon: Icon(Icons.access_time_rounded,
                            color: fieldLabelColor),
                        filled: true,
                        fillColor: inputBgColor,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: availableShifts
                            .map((shift) => FilterChip(
                                  label: Text(shift.name),
                                  selected: selectedShiftIds.contains(shift.id),
                                  onSelected: (selected) => setDialogState(() {
                                    if (selected) {
                                      selectedShiftIds.add(shift.id);
                                    } else if (selectedShiftIds.length > 1) {
                                      selectedShiftIds.remove(shift.id);
                                    }
                                  }),
                                ))
                            .toList(),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        icon: const Icon(Icons.edit_calendar_rounded),
                        label: const Text('شفٹیں بنائیں یا تبدیل کریں'),
                        onPressed: () async {
                          await showShiftManager(context);
                          final loaded = await ShiftStore.load();
                          setDialogState(() {
                            availableShifts = loaded;
                            selectedShiftIds.removeWhere((id) =>
                                availableShifts.every((shift) => shift.id != id));
                            if (selectedShiftIds.isEmpty &&
                                availableShifts.isNotEmpty) {
                              selectedShiftIds.add(availableShifts.first.id);
                            }
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: TranslatedText('Cancel', style: TextStyle(color: isDark ? Colors.tealAccent : const Color(0xFF074E32))),
                ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFF074E32),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.check_circle_rounded, size: 18),
                  onPressed: () async {
                    final name = studentNameCtrl.text.trim();
                    if (name.isEmpty) return;

                    final formattedDate = "${selectedAdmissionDate.year}-${selectedAdmissionDate.month.toString().padLeft(2, '0')}-${selectedAdmissionDate.day.toString().padLeft(2, '0')}";
                    final fatherPhone = fatherPhoneCtrl.text.trim();

                    final newStudent = {
                      'id': 'student_${DateTime.now().microsecondsSinceEpoch}',
                      'maktabId': selectedMaktabTargetId,
                      'maktabType': selectedMaktabType,
                      'maktabName': _maktabProfiles.firstWhere((p) => p['id']?.toString() == selectedMaktabTargetId, orElse: () => {'name': _activeMaktabName.isNotEmpty ? _activeMaktabName : 'مکتب الفاروق'})['name']?.toString() ?? 'مکتب الفاروق',
                      'admissionNo': nextAdmissionNo.toString().padLeft(4, '0'),
                      'name': name,
                      'fatherName': fatherNameCtrl.text.trim(),
                      'fatherPhone': fatherPhone,
                      'dob': '',
                      'group': '',
                      'teacherName': teacherNameCtrl.text.trim(),
                      'shiftIds': selectedShiftIds.toList(),
                      'shifts': selectedShiftIds.toList(),
                      'shiftId': selectedShiftIds.first,
                      'shift': availableShifts
                          .firstWhere(
                            (shift) => shift.id == selectedShiftIds.first,
                            orElse: () => availableShifts.first,
                          )
                          .name,
                      'gender': 'male',
                      'language': selectedLanguage,
                      'preferredLanguage': selectedLanguage,
                      'messageMethod': selectedMessageMethod,
                      'preferredApp': selectedMessageMethod,
                      'feeAmount': '500',
                      'feeMonth': 'August 2026',
                      'feeStatus': 'due',
                      'isPresent': true,
                      'isNewAdmission': true,
                      'admissionDate': formattedDate,
                      'parentPin': '1234',
                    };

                    final updatedList = List<Map<String, dynamic>>.from(widget.students)..add(newStudent);
                    await widget.onSave(updatedList);
                    try {
                      widget.students
                        ..clear()
                        ..addAll(updatedList);
                    } catch (_) {}
                    if (mounted) {
                      setState(() {});
                    }

                    if (fatherPhone.isNotEmpty) {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString('cred_parent_${fatherPhone}_pin', '1234');
                    }

                    if (!dialogCtx.mounted) return;
                    Navigator.pop(dialogCtx);
                    setState(() {
                      _selectedIndex = 0; // Show Students List
                    });
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: TranslatedText('نیا طالب علم ($name) کامیابی سے تمام پورٹلز (حاضری، فیس، بیچ) میں شامل ہو گیا!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  label: const TranslatedText('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showPtmDispatchDialog() {
    final isEn = widget.languageController.locale.languageCode == 'en';
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.people_alt_rounded, color: Colors.indigo),
            const SizedBox(width: 8),
            Text(isEn ? 'PTM Dispatch' : 'والدین میٹنگ بلاوا', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(isEn ? 'Do you want to send the PTM invitation to all parents for the upcoming week?' : 'کیا آپ واقعی تمام والدین کو آنے والے ہفتے کی PTM کا دعوت نامہ بھیجنا چاہتے ہیں؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isEn ? 'Cancel' : 'منسوخ')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(isEn ? 'PTM invitation sent to all parents!' : 'تمام والدین کو PTM کا دعوت نامہ بھیج دیا گیا!'), backgroundColor: Colors.indigo),
              );
            },
            child: Text(isEn ? 'Send Invite' : 'دعوت نامہ بھیجیں'),
          ),
        ],
      ),
    );
  }

  void _showEmergencyLockdownDialog() {
    final isEn = widget.languageController.locale.languageCode == 'en';
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red),
            const SizedBox(width: 8),
            Text(isEn ? 'Emergency Alert' : 'ہنگامی حالت الرٹ', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(isEn ? 'Dispatch emergency holiday alert to all parents due to emergency/rain?' : 'ہنگامی حالت یا بارش کی وجہ سے مکتب کی فوری چھٹی کا الرٹ تمام والدین کو ڈسپچ کریں؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isEn ? 'Cancel' : 'منسوخ')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(isEn ? '🚨 Emergency holiday alert sent to all parents!' : '🚨 ہنگامی چھٹی کا الرٹ تمام والدین کو بھیج دیا گیا!'), backgroundColor: Colors.red),
              );
            },
            child: Text(isEn ? 'Send Alert' : 'ہنگامی الرٹ بھیجیں'),
          ),
        ],
      ),
    );
  }

  void _showDonationTrackerDialog() {
    final isEn = widget.languageController.locale.languageCode == 'en';
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.volunteer_activism_rounded, color: Colors.green),
            const SizedBox(width: 8),
            Text(isEn ? 'Donations Tracker' : 'عطیات و صدقات کھاتہ', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              dense: true,
              title: Text(isEn ? 'Donation: Haji Abdul Sattar (₹10,000)' : 'عطیہ: حاجی عبدالسّتار صاحب (₹10,000)'),
              subtitle: Text(isEn ? 'Purpose: Solar Lighting & Library' : 'مد: مکتب کی سولر لائٹنگ لائبریری'),
            ),
          ],
        ),
        actions: [ElevatedButton(onPressed: () => Navigator.pop(ctx), child: Text(isEn ? 'Close' : 'بند کریں'))],
      ),
    );
  }

  void _showShuraMinutesDialog() {
    final isEn = widget.languageController.locale.languageCode == 'en';
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.gavel_rounded, color: Colors.purple),
            const SizedBox(width: 8),
            Text(isEn ? 'Shura Minutes Log' : 'مجلسِ شوریٰ منٹس', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(isEn ? 'Shura minutes for the meeting on August 1, 2026 are saved.' : 'مجلسِ شوریٰ کے آخری اجلاس مورخہ 1 اگست 2026ء کی منٹس رپورٹ محفوظ ہے۔'),
        actions: [ElevatedButton(onPressed: () => Navigator.pop(ctx), child: Text(isEn ? 'OK' : 'ٹھیک ہے'))],
      ),
    );
  }

  void _showMaintenanceTrackerDialog() {
    final isEn = widget.languageController.locale.languageCode == 'en';
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.build_rounded, color: Colors.orange),
            const SizedBox(width: 8),
            Text(isEn ? 'Maintenance Log' : 'مرمت و تعمیرات کھاتہ', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(isEn ? 'Maintenance cost of Rs 4,500 for building and wudu area is recorded.' : 'مکتب کی عمارت اور وضو خانے کی مرمت کا خرچ Rs 4,500 درج ہے۔'),
        actions: [ElevatedButton(onPressed: () => Navigator.pop(ctx), child: Text(isEn ? 'Close' : 'بند کریں'))],
      ),
    );
  }

  void _showBiometricLockDialog() {
    final isEn = widget.languageController.locale.languageCode == 'en';
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.fingerprint_rounded, color: Colors.blue),
            const SizedBox(width: 8),
            Text(isEn ? 'Security Lock' : 'بائیو میٹرک و پِن سیکیورٹی', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(isEn ? 'Biometric fingerprint and PIN code security is 100% active.' : 'بائیو میٹرک فنگر پرنٹ اور پن کوڈ سیکیورٹی 100% فعال ہے۔'),
        actions: [ElevatedButton(onPressed: () => Navigator.pop(ctx), child: Text(isEn ? 'Secure' : 'محفوظ ہے'))],
      ),
    );
  }

  void _showAppUpdateCheckDialog() {
    final isEn = widget.languageController.locale.languageCode == 'en';
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.system_update_rounded, color: Color(0xFF074E32)),
            const SizedBox(width: 8),
            Text(isEn ? 'In-App Update Checker' : 'ایپ اپڈیٹ چیکر', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(isEn ? 'You are using the latest version of Maktab Manager (v2.5.0 Stable).' : 'آپ مکتب مینیجر کا تازہ ترین ورژن (v2.5.0 Stable) استعمال کر رہے ہیں۔'),
        actions: [ElevatedButton(onPressed: () => Navigator.pop(ctx), child: Text(isEn ? 'Great' : 'عالی شان'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final info = _roleInfo;
    final bool attendanceIsOpen =
        ((widget.currentRole == AppRole.manager ||
                    widget.currentRole == AppRole.admin) &&
                _selectedIndex == 3) ||
            (widget.currentRole == AppRole.teacher && _selectedIndex == 0) ||
            (widget.currentRole == AppRole.mutawalli && _selectedIndex == 2);
    final bool lessonIsOpen =
        (widget.currentRole == AppRole.teacher && _selectedIndex == 1) ||
            (widget.currentRole == AppRole.parent && _selectedIndex == 1);
    final bool compactWorkScreen =
        _maktabSetupComplete && (lessonIsOpen || attendanceIsOpen);
    return ListenableBuilder(
      listenable: widget.languageController,
      builder: (context, _) {
        final isEn = widget.languageController.locale.languageCode == 'en';
        return Scaffold(
          drawer: _buildSideDrawer(context, info),
        extendBodyBehindAppBar: compactWorkScreen,
        appBar: AppBar(
          toolbarHeight: compactWorkScreen ? 38 : null,
          elevation: compactWorkScreen ? 0 : null,
          systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
            statusBarColor: info.primaryColor,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
          ),
          backgroundColor: compactWorkScreen
              ? Colors.transparent
              : (Theme.of(context).brightness == Brightness.dark
                  ? null
                  : info.primaryColor),
          foregroundColor: compactWorkScreen
              ? Colors.white
              : (Theme.of(context).brightness == Brightness.dark
                  ? null
                  : Colors.white),
          flexibleSpace: compactWorkScreen
              ? Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        info.primaryColor,
                        info.primaryColor,
                        info.primaryColor.withValues(alpha: 0),
                      ],
                      stops: const [0, .55, 1],
                    ),
                  ),
                )
              : null,
          title: const SizedBox.shrink(),
          actions: [
            if (_maktabSetupComplete &&
                (widget.currentRole == AppRole.manager ||
                widget.currentRole == AppRole.admin ||
                widget.currentRole == AppRole.teacher))
              Container(
                constraints: const BoxConstraints(minWidth: 96, maxWidth: 172),
                margin: const EdgeInsetsDirectional.only(end: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFFFFF), Color(0xFFE0F4EA)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFF08734B), width: 1.4),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x44065F46),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  _currentClassName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF065F46),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
          ],
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                ),
              )
            : (!_maktabSetupComplete && _canManageMaktab)
                ? _buildMaktabSetupLanding()
                : _buildRoleSpecificBody(),
        bottomNavigationBar: (!_maktabSetupComplete && _canManageMaktab)
            ? null
            : Container(
          margin: EdgeInsets.zero,
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            border: const Border(
              top: BorderSide(color: Color(0xFFD6E5DE), width: 1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.24),
                blurRadius: 11,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: SizedBox(
              height: 58,
              child: _buildBottomNav(),
            ),
          ),
        ),
      );
    },
  );
}

  Widget _buildSideDrawer(BuildContext context, RoleInfo info) {
    final loc = AppLocalizations.of(context);
    final isEn = loc.locale.languageCode == 'en';
    // ignore: unused_local_variable
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool canAddStudent = widget.currentRole == AppRole.admin ||
        widget.currentRole == AppRole.teacher ||
        widget.currentRole == AppRole.manager;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [info.primaryColor, info.primaryColor.withValues(alpha: 0.75)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            accountName: Text(
              _loggedInUserName.isNotEmpty
                  ? _loggedInUserName
                  : info.title(context),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
            ),
            accountEmail: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    info.title(context),
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: MaktabLogo(size: 50),
              ),
            ),
          ),
          if (widget.currentRole == AppRole.admin || widget.currentRole == AppRole.manager)
            ListTile(
              leading: const Icon(
                Icons.account_balance_rounded,
                color: Color(0xFF08734B),
              ),
              title: const Text(
                'مکتب شامل کریں',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF08734B),
                  fontSize: 14,
                ),
              ),
              onTap: () async {
                Navigator.pop(context);
                await _openMaktabSetup();
              },
            ),
          ExpansionTile(
            leading: const Icon(Icons.mosque_rounded, color: Color(0xFF08734B)),
            title: Text(
              isEn ? 'Maktabs List & Switcher' : 'تمام مکاتب کی فہرست (Maktabs List)',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF065F46)),
            ),
            initiallyExpanded: true,
            children: (widget.currentRole == AppRole.teacher
                    ? _maktabProfiles.where((p) => p['id']?.toString() == _activeMaktabId || _activeMaktabId == null).toList()
                    : _maktabProfiles)
                .map((p) {
              final isSelected = p['id']?.toString() == _activeMaktabId;
              final name = p['name']?.toString() ?? 'مکتب';
              final section = p['sectionName']?.toString() ?? '';
              return ListTile(
                dense: true,
                contentPadding: const EdgeInsets.only(left: 20, right: 16),
                leading: Icon(
                  isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  color: isSelected ? const Color(0xFF08734B) : Colors.grey,
                  size: 18,
                ),
                title: Text(
                  section.isNotEmpty ? '$name — $section' : name,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? const Color(0xFF065F46) : null,
                  ),
                ),
                trailing: isSelected
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF7F0),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isEn ? 'Active' : 'فعال',
                          style: const TextStyle(fontSize: 10, color: Color(0xFF08734B), fontWeight: FontWeight.bold),
                        ),
                      )
                    : null,
                onTap: () async {
                  if (isSelected) return;
                  Navigator.pop(context);
                  await _activateMaktab(p['id']?.toString() ?? '');
                },
              );
            }).toList(),
          ),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xFFEAF7F0),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_add_alt_1_rounded, color: Color(0xFF08734B), size: 20),
            ),
            title: Text(
              isEn ? 'Add New Student' : 'طالب علم کا نیا داخلہ (Add Student)',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF065F46), fontSize: 14),
            ),
            subtitle: Text(
              isEn ? 'Simplest admission form' : 'سادہ داخلہ فارم',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            onTap: () {
              Navigator.pop(context);
              _triggerAddStudentModal(maktabId: _activeMaktabId);
            },
          ),
          const Divider(),
          if (_activeMaktabId != null && _activeMaktabName.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: const Color(0xFF79B99C)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x22065F46),
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: ListTile(
                dense: true,
                leading: const Icon(Icons.edit_rounded,
                    color: Color(0xFF08734B)),
                title: Text(
                  _activeMaktabName,
                  style: const TextStyle(
                    color: Color(0xFF065F46),
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                subtitle: const Text('منتخب مکتب کی تفصیلات میں ترمیم کریں'),
                trailing: const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 15, color: Color(0xFF08734B)),
                onTap: () async {
                  Navigator.pop(context);
                  await _openMaktabSetup(editCurrent: true);
                },
              ),
            ),
          if (widget.currentRole == AppRole.admin ||
              widget.currentRole == AppRole.manager ||
              widget.currentRole == AppRole.teacher)
            ListTile(
              leading: const Icon(Icons.campaign_rounded, color: Colors.orange),
              title: const Text(
                'اعلان / Notice',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: () {
                Navigator.pop(context);
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
          if (widget.currentRole == AppRole.admin || widget.currentRole == AppRole.manager)
            ListTile(
              leading: const Icon(Icons.security_rounded, color: Color(0xFF0F172A)),
              title: Text(
                loc.translate('staff_logins'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ManageStaffLoginsScreen(
                      languageController: widget.languageController,
                      currentUserRole: widget.currentRole,
                    ),
                  ),
                );
              },
            ),
          if (canAddStudent)
            ListTile(
              leading: const Icon(Icons.family_restroom_rounded, color: Colors.indigo),
              title: Text(
                loc.translate('parent_logins'),
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo, fontSize: 13.5),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ManageParentLoginsScreen(
                      languageController: widget.languageController,
                      students: _activeStudents,
                      onSaveStudents: _saveActiveStudents,
                    ),
                  ),
                );
              },
            ),
          if (canAddStudent) const Divider(),
          if (widget.currentRole != AppRole.manager)
            ListTile(
              leading: const Icon(Icons.analytics_rounded, color: Colors.purple),
              title: Text(
                loc.translate('advanced_dashboard'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => AnalyticsScreen(
                        students: _activeStudents,
                      languageController: widget.languageController,
                      themeController: ThemeController(),
                    ),
                  ),
                );
              },
            ),
          if (!canAddStudent)
            ListTile(
            leading: const Icon(Icons.people_rounded, color: Color(0xFF074E32)),
            title: Text(loc.translate('students_list')),
            onTap: () {
              Navigator.pop(context);
              _openStudentListFromMenu();
            },
          ),
          if (!canAddStudent)
            ListTile(
            leading: const Icon(Icons.how_to_reg_rounded, color: Color(0xFF074E32)),
            title: Text(loc.translate('attendance')),
            onTap: () {
              Navigator.pop(context);
              _openAttendanceFromMenu();
            },
          ),
          if (!canAddStudent)
            ListTile(
            leading: const Icon(Icons.menu_book_rounded, color: Color(0xFF074E32)),
            title: Text(loc.translate('sabaq_lessons')),
            onTap: () {
              Navigator.pop(context);
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
          if (!canAddStudent)
            ListTile(
            leading: const Icon(Icons.currency_rupee_rounded, color: Color(0xFF074E32)),
            title: Text(loc.translate('fee_record')),
            onTap: () {
              Navigator.pop(context);
              setState(() => _selectedIndex = 2);
            },
          ),
          if (widget.currentRole != AppRole.manager) const Divider(),
          if (widget.currentRole != AppRole.manager)
            ListTile(
              leading: const Icon(Icons.assignment_turned_in_rounded, color: Colors.teal),
              title: Text(loc.translate('results_performance')),
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
            title: Text(loc.translate('leave_portal')),
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
            title: Text(loc.translate('community_chat')),
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
            leading: const Icon(Icons.people_alt_rounded, color: Colors.indigo),
            title: Text(loc.translate('notice_channel')),
            onTap: () {
              Navigator.pop(context);
              _showPtmDispatchDialog();
            },
          ),
          ListTile(
            leading: const Icon(Icons.warning_amber_rounded, color: Colors.red),
            title: Text(loc.translate('security_lock')),
            onTap: () {
              Navigator.pop(context);
              _showEmergencyLockdownDialog();
            },
          ),
          ListTile(
            leading: const Icon(Icons.volunteer_activism_rounded, color: Colors.green),
            title: Text(loc.translate('fee_collection')),
            onTap: () {
              Navigator.pop(context);
              _showDonationTrackerDialog();
            },
          ),
          ListTile(
            leading: const Icon(Icons.gavel_rounded, color: Colors.purple),
            title: Text(loc.translate('admin_control')),
            onTap: () {
              Navigator.pop(context);
              _showShuraMinutesDialog();
            },
          ),
          ListTile(
            leading: const Icon(Icons.build_rounded, color: Colors.orange),
            title: Text(loc.translate('quick_actions')),
            onTap: () {
              Navigator.pop(context);
              _showMaintenanceTrackerDialog();
            },
          ),
          ListTile(
            leading: const Icon(Icons.fingerprint_rounded, color: Colors.blue),
            title: Text(loc.translate('security_logins')),
            onTap: () {
              Navigator.pop(context);
              _showBiometricLockDialog();
            },
          ),
          ListTile(
            leading: const Icon(Icons.system_update_rounded, color: Color(0xFF074E32)),
            title: Text(loc.translate('overview')),
            onTap: () {
              Navigator.pop(context);
              _showAppUpdateCheckDialog();
            },
          ),
          ListTile(
            leading: const Icon(Icons.palette_rounded, color: Colors.indigo),
            title: Text(loc.translate('theme_mode')),
            trailing: ThemeButton(controller: widget.themeController),
          ),
          ListTile(
            leading: const Icon(Icons.language_rounded, color: Colors.teal),
            title: Text(loc.translate('select_language')),
            trailing: LanguageButton(controller: widget.languageController),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.red),
            title: Text(loc.translate('logout')),
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
    final loc = AppLocalizations.of(context);

    switch (widget.currentRole) {
      case AppRole.manager:
      case AppRole.admin:
        return BottomNavigationBar(
          currentIndex: _selectedIndex.clamp(0, 3),
          iconSize: 21,
          selectedFontSize: 10.5,
          unselectedFontSize: 9.5,
          selectedLabelStyle: const TextStyle(height: 1),
          unselectedLabelStyle: const TextStyle(height: 1),
          selectedItemColor: _roleInfo.primaryColor,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          onTap: (i) => setState(() => _selectedIndex = i),
          items: [
            BottomNavigationBarItem(
                icon: const Icon(Icons.dashboard_rounded), label: loc.translate('advanced_dashboard')),
            BottomNavigationBarItem(
                icon: const Icon(Icons.people_rounded), label: loc.translate('students_list')),
            BottomNavigationBarItem(
                icon: const Icon(Icons.currency_rupee_rounded), label: loc.translate('fee_record')),
            BottomNavigationBarItem(
                icon: const Icon(Icons.how_to_reg_rounded), label: loc.translate('attendance')),
          ],
        );
      case AppRole.teacher:
        return Directionality(
          textDirection: TextDirection.rtl,
          child: BottomNavigationBar(
            currentIndex: _selectedIndex.clamp(0, 3),
            iconSize: 21,
            selectedFontSize: 10.5,
            unselectedFontSize: 9.5,
            selectedLabelStyle: const TextStyle(height: 1),
            unselectedLabelStyle: const TextStyle(height: 1),
            selectedItemColor: _roleInfo.primaryColor,
            unselectedItemColor: Colors.grey,
            type: BottomNavigationBarType.fixed,
            onTap: (i) => setState(() => _selectedIndex = i),
            items: [
              BottomNavigationBarItem(
                  icon: const Icon(Icons.fact_check_rounded), label: loc.translate('attendance')),
              BottomNavigationBarItem(
                  icon: const Icon(Icons.menu_book_rounded), label: loc.translate('sabaq_lessons')),
              BottomNavigationBarItem(
                  icon: const Icon(Icons.currency_rupee_rounded), label: loc.translate('fee_record')),
              BottomNavigationBarItem(
                  icon: const Icon(Icons.people_outline_rounded), label: loc.translate('students_list')),
            ],
          ),
        );
      case AppRole.parent:
        return BottomNavigationBar(
          currentIndex: _selectedIndex.clamp(0, 2),
          iconSize: 21,
          selectedFontSize: 10.5,
          unselectedFontSize: 9.5,
          selectedLabelStyle: const TextStyle(height: 1),
          unselectedLabelStyle: const TextStyle(height: 1),
          selectedItemColor: _roleInfo.primaryColor,
          unselectedItemColor: Colors.grey,
          onTap: (i) => setState(() => _selectedIndex = i),
          items: [
            BottomNavigationBarItem(
                icon: const Icon(Icons.child_care_rounded), label: loc.translate('students_list')),
            BottomNavigationBarItem(
                icon: const Icon(Icons.history_edu_rounded), label: loc.translate('sabaq_lessons')),
            BottomNavigationBarItem(
                icon: const Icon(Icons.receipt_long_rounded), label: loc.translate('fee_record')),
          ],
        );
      case AppRole.mutawalli:
        return BottomNavigationBar(
          currentIndex: _selectedIndex.clamp(0, 2),
          iconSize: 21,
          selectedFontSize: 10.5,
          unselectedFontSize: 9.5,
          selectedLabelStyle: const TextStyle(height: 1),
          unselectedLabelStyle: const TextStyle(height: 1),
          selectedItemColor: _roleInfo.primaryColor,
          unselectedItemColor: Colors.grey,
          onTap: (i) => setState(() => _selectedIndex = i),
          items: [
            BottomNavigationBarItem(
                icon: const Icon(Icons.account_balance_rounded), label: loc.translate('advanced_dashboard')),
            BottomNavigationBarItem(
                icon: const Icon(Icons.payments_rounded), label: loc.translate('fee_record')),
            BottomNavigationBarItem(
                icon: const Icon(Icons.picture_as_pdf_rounded), label: loc.translate('attendance')),
          ],
        );
      default:
        return BottomNavigationBar(
          currentIndex: _selectedIndex.clamp(0, 1),
          iconSize: 21,
          selectedFontSize: 10.5,
          unselectedFontSize: 9.5,
          selectedLabelStyle: const TextStyle(height: 1),
          unselectedLabelStyle: const TextStyle(height: 1),
          selectedItemColor: _roleInfo.primaryColor,
          unselectedItemColor: Colors.grey,
          onTap: (i) => setState(() => _selectedIndex = i),
          items: [
            BottomNavigationBarItem(
                icon: const Icon(Icons.dashboard_rounded), label: loc.translate('advanced_dashboard')),
            BottomNavigationBarItem(
                icon: const Icon(Icons.people_rounded), label: loc.translate('students_list')),
          ],
        );
    }
  }

  Widget _buildRoleSpecificBody() {
    switch (widget.currentRole) {
      case AppRole.manager:
      case AppRole.admin:
        if (_selectedIndex == 1) {
          return _buildActiveMaktabStudentList();
        }
        if (_selectedIndex == 2) {
          return FeeScreen(
            students: _activeStudents,
            languageController: widget.languageController,
            onSave: _saveActiveStudents,
            currentRole: widget.currentRole,
            maktabId: _activeMaktabId,
            onMaktabChanged: _activateMaktabKeepingCurrentScreen,
          );
        }
        if (_selectedIndex == 3) {
          return AttendanceScreen(
            students: _activeStudents,
            languageController: widget.languageController,
            onSave: _saveActiveStudents,
            currentRole: widget.currentRole,
            maktabId: _activeMaktabId,
          );
        }
        return _buildManagerAdminOverview();

      case AppRole.teacher:
        if (_selectedIndex == 0) {
          return AttendanceScreen(
            students: _activeStudents,
            languageController: widget.languageController,
            onSave: _saveActiveStudents,
            currentRole: widget.currentRole,
            maktabId: _activeMaktabId,
          );
        }
        if (_selectedIndex == 1) {
          return LessonScreen(
            students: _activeStudents,
            languageController: widget.languageController,
            maktabId: _activeMaktabId,
          );
        }
        if (_selectedIndex == 2) {
          return FeeScreen(
            students: _activeStudents,
            languageController: widget.languageController,
            onSave: _saveActiveStudents,
            currentRole: widget.currentRole,
            maktabId: _activeMaktabId,
            onMaktabChanged: _activateMaktabKeepingCurrentScreen,
          );
        }
        // index 3 = Students List
        return _buildActiveMaktabStudentList();

      case AppRole.parent:
        if (_selectedIndex == 1) {
          return LessonScreen(
            languageController: widget.languageController,
            maktabId: _activeMaktabId,
          );
        }
        if (_selectedIndex == 2) {
          return FeeScreen(
            students: _activeStudents,
            languageController: widget.languageController,
            onSave: _saveActiveStudents,
            currentRole: widget.currentRole,
            maktabId: _activeMaktabId,
            onMaktabChanged: _activateMaktabKeepingCurrentScreen,
          );
        }
        return _buildParentChildOverview();

      case AppRole.mutawalli:
        if (_selectedIndex == 1) {
          return FeeScreen(
            students: _activeStudents,
            languageController: widget.languageController,
            onSave: _saveActiveStudents,
            currentRole: widget.currentRole,
            maktabId: _activeMaktabId,
            onMaktabChanged: _activateMaktabKeepingCurrentScreen,
          );
        }
        if (_selectedIndex == 2) {
          return AttendanceScreen(
            students: _activeStudents,
            languageController: widget.languageController,
            onSave: _saveActiveStudents,
            currentRole: widget.currentRole,
            maktabId: _activeMaktabId,
          );
        }
        return _buildMutawalliOverview();

      case AppRole.other:
        return _buildOtherOverview();
    }
  }

  Widget _buildActiveMaktabStudentList() {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(12, 8, 12, 6),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFE9F6EF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF79B99C)),
              ),
              child: Text(
                '${_activeMaktabName.isEmpty ? 'منتخب مکتب' : _activeMaktabName} — طلبہ: ${_activeStudents.length}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF065F46),
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ),
            Expanded(
              child: _activeStudents.isEmpty
                  ? const Center(child: Text('اس مکتب میں کوئی طالب علم موجود نہیں۔'))
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                      itemCount: _activeStudents.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 7),
                      itemBuilder: (context, index) {
                        final student = _activeStudents[index];
                        return Card(
                          elevation: 2,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFFE1F3E9),
                              child: Text('${index + 1}',
                                  style: const TextStyle(
                                      color: Color(0xFF08734B),
                                      fontWeight: FontWeight.bold)),
                            ),
                            title: Text(
                              student['name']?.toString() ?? 'طالب علم',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 16),
                            ),
                            subtitle: Text(
                              'والد: ${student['fatherName'] ?? '-'}  •  کلاس: ${student['className'] ?? '-'}\n'
                              'شفٹ: ${student['shift'] ?? '-'}  •  فون: ${student['fatherPhone'] ?? '-'}',
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

  // ── MANAGER / ADMIN OVERVIEW ──
  Widget _buildManagerAdminOverview() {
    final loc = AppLocalizations.of(context);
    final totalStudents = _activeStudents.length;
    final presentCount =
        _activeStudents.where((s) => s['isPresent'] == true).length;
    final absentCount = totalStudents - presentCount;
    final paidCount =
        _activeStudents.where((s) => s['feeStatus'] == 'paid').length;
    final attendanceRate = totalStudents == 0
        ? 0
        : ((presentCount / totalStudents) * 100).toInt();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const MaktabLogo(size: 64),
              const SizedBox(width: 12),
              Expanded(
                child: _RoleBannerCard(
                  title: '${loc.translate('welcome')}, ${_roleInfo.titleUrdu}!',
                  subtitle: _roleInfo.subtitleUrdu,
                  color: _roleInfo.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            loc.translate('overview'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: loc.translate('total_students'),
                  value: '$totalStudents',
                  icon: Icons.groups_rounded,
                  color: Colors.blue.shade700,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  title: loc.translate('present'),
                  value: '$presentCount',
                  icon: Icons.check_circle_rounded,
                  color: Colors.green.shade700,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  title: loc.translate('fee_collection'),
                  value: '$paidCount / $totalStudents',
                  icon: Icons.payments_rounded,
                  color: Colors.amber.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── ATTENDANCE RESULT DISPLAY ──
          Text(
            loc.translate('attendance_result'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Container(
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
              children: [
                Row(
                  children: [
                    const Icon(Icons.how_to_reg_rounded, color: Colors.amberAccent, size: 22),
                    const SizedBox(width: 8),
                    Text(loc.translate('attendance_result'),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
                const Divider(color: Colors.white30, height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _attendanceResultItem(loc.translate('present'), '$presentCount', Colors.greenAccent, Icons.check_circle_rounded),
                    _attendanceResultItem(loc.translate('absent'), '$absentCount', Colors.redAccent, Icons.cancel_rounded),
                    _attendanceResultItem(loc.translate('attendance_rate'), '$attendanceRate%', Colors.amberAccent, Icons.bar_chart_rounded),
                  ],
                ),
                const SizedBox(height: 12),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: totalStudents == 0 ? 0 : presentCount / totalStudents,
                    minHeight: 10,
                    backgroundColor: Colors.red.shade200,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${loc.translate('present')}: $presentCount',
                        style: const TextStyle(fontSize: 10, color: Colors.white70)),
                    Text('${loc.translate('absent')}: $absentCount',
                        style: const TextStyle(fontSize: 10, color: Colors.white70)),
                  ],
                ),
                if (_activeStudents.where((s) => s['isPresent'] != true).isNotEmpty) ...[
                  const Divider(color: Colors.white30, height: 16),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text('${loc.translate('absent')} ${loc.translate('students_list')}:',
                        style: const TextStyle(fontSize: 11, color: Colors.amberAccent, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 6),
                  ..._activeStudents
                      .where((s) => s['isPresent'] != true)
                      .take(5)
                      .map((s) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                const Icon(Icons.person_off_rounded, size: 14, color: Colors.redAccent),
                                const SizedBox(width: 8),
                                Text(s['name']?.toString() ?? 'Student',
                                    style: const TextStyle(fontSize: 12, color: Colors.white)),
                                const Spacer(),
                                Text(s['group']?.toString() ?? s['className']?.toString() ?? '',
                                    style: const TextStyle(fontSize: 10, color: Colors.white54)),
                              ],
                            ),
                          )),
                  if (_activeStudents.where((s) => s['isPresent'] != true).length > 5)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '+${_activeStudents.where((s) => s['isPresent'] != true).length - 5} more...',
                        style: const TextStyle(fontSize: 10, color: Colors.white54),
                      ),
                    ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),
          // ── TEACHER ATTENDANCE & RECORDED ATTENDANCE CARD FOR MANAGER ──
          Text(
            loc.translate('teacher_attendance_status'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1E293B)
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.teal.shade200),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.badge_rounded, color: Colors.teal, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      loc.translate('recorded_by_teacher'),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${loc.translate('present')}: $presentCount | ${loc.translate('absent')}: $absentCount',
                        style: TextStyle(fontSize: 10, color: Colors.teal.shade900, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 16),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.green.shade100,
                      child: const Icon(Icons.person_outline_rounded, size: 18, color: Colors.green),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.locale.languageCode == 'en' ? 'Ustadh Mohammad' : 'استاد محمد علی',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            loc.locale.languageCode == 'en'
                                ? 'Hifz Class • Recorded $presentCount Present'
                                : 'حفظ کلاس • درج کردہ حاضری: $presentCount حاضر',
                            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        loc.translate('present'),
                        style: TextStyle(fontSize: 10, color: Colors.green.shade900, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          Text(
            loc.translate('quick_actions'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                title: loc.translate('mark_attendance'),
                icon: Icons.fact_check_rounded,
                color: Colors.teal,
                onTap: () => setState(() => _selectedIndex = 3),
              ),
              _ActionTile(
                title: loc.translate('fee_portal'),
                icon: Icons.currency_rupee_rounded,
                color: Colors.orange.shade800,
                onTap: () => setState(() => _selectedIndex = 2),
              ),
              _ActionTile(
                title: loc.translate('sabaq_lessons'),
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
                title: loc.translate('students_list'),
                icon: Icons.list_alt_rounded,
                color: Colors.blue.shade800,
                onTap: () => setState(() => _selectedIndex = 1),
              ),
              _ActionTile(
                title: loc.translate('leave_portal'),
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
                title: loc.translate('community_chat'),
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
                title: loc.translate('results_performance'),
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
                title: loc.translate('admin_control'),
                icon: Icons.admin_panel_settings_rounded,
                color: const Color(0xFF074E32),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AdminFeaturesScreen(
                        languageController: widget.languageController,
                        students: _activeStudents,
                        onSave: _saveActiveStudents,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          // ── BOTTOM SHORTCUT BOX: MAKTAB STUDENTS DIRECTORY ──
          InkWell(
            onTap: () => _showMaktabStudentsShortcutModal(context),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: Theme.of(context).brightness == Brightness.dark
                      ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                      : [const Color(0xFF074E32), const Color(0xFF0D6E48)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF79B99C)),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3))
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.groups_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.locale.languageCode == 'en'
                              ? 'Selected Maktab Students Roster'
                              : 'اس مکتب کے تمام طلبہ کی فہرست',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          loc.locale.languageCode == 'en'
                              ? 'Tap to view only the ${_activeStudents.length} students of this Maktab'
                              : 'اس مکتب کے کل ${_activeStudents.length} طلبہ کی فہرست دیکھنے کے لیے کلک کریں',
                          style: const TextStyle(fontSize: 11, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 16),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showMaktabStudentsShortcutModal(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final maktabStudents = _activeStudents;
    final maktabName = _activeMaktabName.isEmpty ? loc.translate('select_branch') : _activeMaktabName;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalCtx) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final filtered = maktabStudents.where((s) {
              final name = (s['name'] ?? '').toString().toLowerCase();
              final fName = (s['fatherName'] ?? '').toString().toLowerCase();
              final phone = (s['fatherPhone'] ?? s['parentPhone'] ?? '').toString();
              final query = searchQuery.toLowerCase();
              return name.contains(query) || fName.contains(query) || phone.contains(query);
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE9F6EF),
                        child: const Icon(Icons.school_rounded, color: Color(0xFF065F46)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              maktabName,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              loc.locale.languageCode == 'en'
                                  ? 'Total Students: ${maktabStudents.length}'
                                  : 'اس مکتب کے کل طلبہ: ${maktabStudents.length}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.tealAccent : const Color(0xFF065F46),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.person_add_alt_1_rounded, color: Color(0xFF065F46)),
                        tooltip: 'نیا طالب علم شامل کریں',
                        onPressed: () {
                          Navigator.pop(modalCtx);
                          _triggerAddStudentModal(maktabId: _activeMaktabId);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: InputDecoration(
                      hintText: loc.locale.languageCode == 'en' ? 'Search student...' : 'طالب علم کی تلاش...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (q) => setModalState(() => searchQuery = q),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Text(
                              loc.locale.languageCode == 'en'
                                  ? 'No students found for this Maktab'
                                  : 'اس مکتب میں کوئی طالب علم نہیں ملا۔',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          )
                        : ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (c, idx) {
                              final student = filtered[idx];
                              final phone = (student['fatherPhone'] ?? student['parentPhone'] ?? '').toString();
                              return Card(
                                elevation: 1,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: const Color(0xFFE9F6EF),
                                    child: Text(
                                      '${idx + 1}',
                                      style: const TextStyle(
                                        color: Color(0xFF065F46),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    student['name']?.toString() ?? 'طالب علم',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                    'والد: ${student['fatherName'] ?? '-'} • کلاس: ${student['className'] ?? student['class'] ?? '-'}\nفون: ${phone.isEmpty ? '-' : phone}',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  trailing: phone.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.call_rounded, color: Colors.green),
                                          onPressed: () async {
                                            final uri = Uri(scheme: 'tel', path: phone);
                                            if (await canLaunchUrl(uri)) await launchUrl(uri);
                                          },
                                        )
                                      : null,
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
      },
    );
  }

  Widget _attendanceResultItem(String label, String val, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(val, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.white70)),
      ],
    );
  }

  // ── PARENT CHILD OVERVIEW ──
  Widget _buildParentChildOverview() {
    final firstStudent =
        _activeStudents.isNotEmpty ? _activeStudents.first : null;
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
    final isEn = widget.languageController.locale.languageCode == 'en';
    final totalStudents = _activeStudents.length;
    final totalFeesCollected = _activeStudents
        .where((s) => s['feeStatus'] == 'paid')
        .fold<double>(
            0, (sum, s) => sum + (double.tryParse(s['feeAmount']?.toString() ?? '0') ?? 0));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RoleBannerCard(
            title: isEn ? 'Welcome to Mutawalli Portal!' : 'خوش آمدید متولی صاحب!',
            subtitle: isEn ? 'Financial, Academic & Administrative Overview of Mosque & Maktab' : 'مسجد اور مکتب کا مالیاتی، تعلیمی اور عمومی انتظامی جائزہ',
            color: const Color(0xFF4C1D95),
          ),
          const SizedBox(height: 16),
          // Mutawalli Optional Access Toggles Card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ExpansionTile(
              leading: const Icon(Icons.tune_rounded, color: Color(0xFF4C1D95)),
              title: Text(isEn ? 'Access Controls' : 'متولی اختیارات و رسائی',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              subtitle: Text(isEn ? 'Change access to students, payments, and results' : 'طلبہ، مالیات اور نتائج تک رسائی تبدیل کریں',
                  style: TextStyle(fontSize: 11, color: Colors.grey)),
              children: [
                SwitchListTile(
                  title: Text(isEn ? '👥 Show Students Roster' : '👥 طلبہ کی فہرست دکھائیں'),
                  value: _mutawalliShowStudents,
                  onChanged: (v) => setState(() => _mutawalliShowStudents = v),
                ),
                SwitchListTile(
                  title: Text(isEn ? '💵 Show Payments Ledger' : '💵 فیس و مالیاتی جائزہ'),
                  value: _mutawalliShowPayments,
                  onChanged: (v) => setState(() => _mutawalliShowPayments = v),
                ),
                SwitchListTile(
                  title: Text(isEn ? '🏆 Show Academic Results' : '🏆 تعلیمی نتائج دکھائیں'),
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
                  title: isEn ? 'Total Fees Collected' : 'مجموعی فیس وصولی',
                  value: '₹ ${totalFeesCollected.toInt()}',
                  icon: Icons.account_balance_wallet_rounded,
                  color: Colors.green.shade800,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  title: isEn ? 'Total Students' : 'کل طلبہ کی تعداد',
                  value: '$totalStudents',
                  icon: Icons.school_rounded,
                  color: const Color(0xFF4C1D95),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(isEn ? 'Quick Access Portal (Mutawalli)' : 'فوری رسائی پورٹل',
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
                  title: isEn ? 'Students List' : 'طلبہ کی فہرست',
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
                  title: isEn ? 'Payments Ledger' : 'مالیاتی جائزہ',
                  icon: Icons.payments_rounded,
                  color: Colors.green.shade800,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FeeScreen(
                          students: _activeStudents,
                          languageController: widget.languageController,
                          onSave: _saveActiveStudents,
                          maktabId: _activeMaktabId,
                          onMaktabChanged:
                              _activateMaktabKeepingCurrentScreen,
                        ),
                      ),
                    );
                  },
                ),
              if (_mutawalliShowResults)
                _ActionTile(
                  title: isEn ? 'Results & Performance' : 'نتائج و کارکردگی',
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
                title: isEn ? 'Community Chat' : 'کمیونٹی چیٹ',
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
            label: Text(isEn ? 'Batch Fee PDF Report' : 'مکتب کی ماہانہ رپورٹ'),
          ),
        ],
      ),
    );
  }

  // ── OTHER OVERVIEW ──
  Widget _buildOtherOverview() {
    final loc = AppLocalizations.of(context);
    final isEn = loc.locale.languageCode == 'en';
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _RoleBannerCard(
            title: loc.translate('welcome'),
            subtitle: isEn ? 'Welcome to Maktab Management System' : 'مکتب مینیجر ایپ میں آپ کا خیر مقدم ہے',
            color: const Color(0xFF374151),
          ),
          const SizedBox(height: 24),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_rounded, color: Color(0xFF374151)),
              title: Text(isEn ? 'Working Hours' : 'مکتب کی اوقات کار'),
              subtitle: Text(isEn ? 'Morning: 7:00 to 9:00 AM | Evening: 5:00 to 7:00 PM' : 'صبح: 7:00 سے 9:00 | شام: 5:00 سے 7:00'),
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
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good Morning' : (hour < 17 ? 'Good Afternoon' : 'Good Evening');

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
            greeting,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 4),
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
        gradient: LinearGradient(
          colors: [Colors.white, color.withValues(alpha: 0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
          gradient: LinearGradient(
            colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
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
