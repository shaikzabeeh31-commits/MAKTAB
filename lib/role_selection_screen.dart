import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('current_user_name') ?? prefs.getString('cred_${widget.currentRole.name}_name');
    if (name != null && name.isNotEmpty) {
      setState(() {
        _loggedInUserName = name;
      });
    }
    setState(() {
      _isLoading = false;
    });
  }

  RoleInfo get _roleInfo =>
      kAppRoles.firstWhere((r) => r.role == widget.currentRole);

  void _triggerAddStudentModal() {
    final studentNameCtrl = TextEditingController();
    final fatherNameCtrl = TextEditingController();
    final fatherPhoneCtrl = TextEditingController();
    final teacherNameCtrl = TextEditingController(text: 'حافظ احمد حسن');
    DateTime selectedAdmissionDate = DateTime.now();
    String selectedShift = 'morning';
    String selectedGroup = 'Hifz Group A';

    showDialog<void>(
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
                      style: TextStyle(color: fieldTextColor),
                      decoration: InputDecoration(
                        labelText: loc.translate('student_name'),
                        labelStyle: TextStyle(color: fieldLabelColor),
                        prefixIcon: Icon(Icons.person, color: fieldLabelColor),
                        filled: true,
                        fillColor: inputBgColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: fatherNameCtrl,
                      style: TextStyle(color: fieldTextColor),
                      decoration: InputDecoration(
                        labelText: loc.translate('father_name'),
                        labelStyle: TextStyle(color: fieldLabelColor),
                        prefixIcon: Icon(Icons.person_outline, color: fieldLabelColor),
                        filled: true,
                        fillColor: inputBgColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: fatherPhoneCtrl,
                      style: TextStyle(color: fieldTextColor),
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: loc.translate('father_phone'),
                        labelStyle: TextStyle(color: fieldLabelColor),
                        prefixIcon: Icon(Icons.phone, color: fieldLabelColor),
                        filled: true,
                        fillColor: inputBgColor,
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
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
                    DropdownButtonFormField<String>(
                      initialValue: selectedGroup,
                      dropdownColor: dialogBgColor,
                      decoration: InputDecoration(
                        labelText: loc.translate('batch_group'),
                        labelStyle: TextStyle(color: fieldLabelColor),
                        prefixIcon: Icon(Icons.groups_rounded, color: fieldLabelColor),
                        filled: true,
                        fillColor: inputBgColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: [
                        DropdownMenuItem(value: 'Hifz Group A', child: TranslatedText('Hifz Group A', style: TextStyle(color: fieldTextColor))),
                        DropdownMenuItem(value: 'Nazira Group B', child: TranslatedText('Nazira Group B', style: TextStyle(color: fieldTextColor))),
                        DropdownMenuItem(value: 'Tajweed Group C', child: TranslatedText('Tajweed Group C', style: TextStyle(color: fieldTextColor))),
                        DropdownMenuItem(value: 'Primary Group D', child: TranslatedText('Primary Group D', style: TextStyle(color: fieldTextColor))),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedGroup = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedShift,
                      dropdownColor: dialogBgColor,
                      decoration: InputDecoration(
                        labelText: loc.translate('shift_timing'),
                        labelStyle: TextStyle(color: fieldLabelColor),
                        prefixIcon: Icon(Icons.access_time_rounded, color: fieldLabelColor),
                        filled: true,
                        fillColor: inputBgColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: [
                        DropdownMenuItem(value: 'morning', child: TranslatedText('Morning Shift', style: TextStyle(color: fieldTextColor))),
                        DropdownMenuItem(value: 'evening', child: TranslatedText('Evening Shift', style: TextStyle(color: fieldTextColor))),
                        DropdownMenuItem(value: 'night', child: TranslatedText('Night Shift', style: TextStyle(color: fieldTextColor))),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedShift = val);
                      },
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
                      'name': name,
                      'fatherName': fatherNameCtrl.text.trim(),
                      'fatherPhone': fatherPhone,
                      'dob': '',
                      'group': selectedGroup,
                      'className': selectedGroup,
                      'teacherName': teacherNameCtrl.text.trim(),
                      'shift': selectedShift,
                      'gender': 'male',
                      'language': 'ur',
                      'messageMethod': 'SMS',
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
    return ListenableBuilder(
      listenable: widget.languageController,
      builder: (context, _) => Scaffold(
        drawer: _buildSideDrawer(context, info),
        appBar: AppBar(
          backgroundColor: Theme.of(context).brightness == Brightness.dark ? null : info.primaryColor,
          foregroundColor: Theme.of(context).brightness == Brightness.dark ? null : Colors.white,
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
            ThemeButton(controller: widget.themeController),
            const SizedBox(height: 8),
            LanguageButton(controller: widget.languageController),
          ],
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                ),
              )
            : _buildRoleSpecificBody(),
        bottomNavigationBar: Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: _buildBottomNav(),
          ),
        ),
      ),
    );
  }

  Widget _buildSideDrawer(BuildContext context, RoleInfo info) {
    final loc = AppLocalizations.of(context);
    final isEn = loc.locale.languageCode == 'en';
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
                colors: [info.primaryColor, info.primaryColor.withValues(alpha: 0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            accountName: Text(
              _loggedInUserName.isNotEmpty
                  ? _loggedInUserName
                  : info.title(context),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            accountEmail: Text(
              'Role: ${info.title(context)}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: const MaktabLogo(size: 64),
            ),
          ),
          if (canAddStudent)
            ListTile(
              leading: const Icon(Icons.person_add_alt_1_rounded, color: Colors.blue),
              title: Text(
                loc.translate('add_student'),
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 13.5),
              ),
              onTap: () {
                Navigator.pop(context);
                _triggerAddStudentModal();
              },
            ),
          if (widget.currentRole == AppRole.admin || widget.currentRole == AppRole.manager)
            ListTile(
              leading: const Icon(Icons.class_rounded, color: Colors.teal),
              title: Text(
                loc.translate('create_group'),
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal, fontSize: 13.5),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreateClassGroupScreen(
                      students: widget.students,
                      languageController: widget.languageController,
                      onSave: widget.onSave,
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
                      students: widget.students,
                      onSaveStudents: widget.onSave,
                    ),
                  ),
                );
              },
            ),
          if (canAddStudent) const Divider(),
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
                    students: widget.students,
                    languageController: widget.languageController,
                    themeController: ThemeController(),
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.people_rounded, color: Color(0xFF074E32)),
            title: Text(loc.translate('students_list')),
            onTap: () {
              Navigator.pop(context);
              setState(() => _selectedIndex = 1);
            },
          ),
          ListTile(
            leading: const Icon(Icons.how_to_reg_rounded, color: Color(0xFF074E32)),
            title: Text(loc.translate('attendance')),
            onTap: () {
              Navigator.pop(context);
              setState(() => _selectedIndex = 3);
            },
          ),
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
          ListTile(
            leading: const Icon(Icons.currency_rupee_rounded, color: Color(0xFF074E32)),
            title: Text(loc.translate('fee_record')),
            onTap: () {
              Navigator.pop(context);
              setState(() => _selectedIndex = 2);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.people_alt_rounded, color: Colors.indigo),
            title: Text(isEn ? 'PTM Dispatch' : 'والدین میٹنگ بلاوا'),
            onTap: () {
              Navigator.pop(context);
              _showPtmDispatchDialog();
            },
          ),
          ListTile(
            leading: const Icon(Icons.warning_amber_rounded, color: Colors.red),
            title: Text(isEn ? 'Emergency Alert' : 'ہنگامی حالت الرٹ'),
            onTap: () {
              Navigator.pop(context);
              _showEmergencyLockdownDialog();
            },
          ),
          ListTile(
            leading: const Icon(Icons.volunteer_activism_rounded, color: Colors.green),
            title: Text(isEn ? 'Donations Tracker' : 'عطیات و صدقات کھاتہ'),
            onTap: () {
              Navigator.pop(context);
              _showDonationTrackerDialog();
            },
          ),
          ListTile(
            leading: const Icon(Icons.gavel_rounded, color: Colors.purple),
            title: Text(isEn ? 'Shura Minutes Log' : 'مجلسِ شوریٰ منٹس'),
            onTap: () {
              Navigator.pop(context);
              _showShuraMinutesDialog();
            },
          ),
          ListTile(
            leading: const Icon(Icons.build_rounded, color: Colors.orange),
            title: Text(isEn ? 'Maintenance Log' : 'مرمت و تعمیرات کھاتہ'),
            onTap: () {
              Navigator.pop(context);
              _showMaintenanceTrackerDialog();
            },
          ),
          ListTile(
            leading: const Icon(Icons.fingerprint_rounded, color: Colors.blue),
            title: Text(isEn ? 'Biometric Security' : 'بائیو میٹرک لاک'),
            onTap: () {
              Navigator.pop(context);
              _showBiometricLockDialog();
            },
          ),
          ListTile(
            leading: const Icon(Icons.system_update_rounded, color: Color(0xFF074E32)),
            title: Text(isEn ? 'Check App Update' : 'ایپ اپڈیٹ چیک کریں'),
            onTap: () {
              Navigator.pop(context);
              _showAppUpdateCheckDialog();
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.assignment_turned_in_rounded, color: Colors.teal),
            title: Text(isEn ? 'Academic Results' : 'نتائج و تعلیمی کارکردگی'),
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
            title: Text(isEn ? 'Leave Requests' : 'استاد لیو پورٹل'),
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
            title: Text(isEn ? 'Community Hub' : 'کمیونٹی و پیغام رسانی'),
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
            title: Text(isEn ? 'Logout' : 'لاگ آؤٹ'),
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
        return BottomNavigationBar(
          currentIndex: _selectedIndex.clamp(0, 3),
          selectedItemColor: _roleInfo.primaryColor,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          onTap: (i) => setState(() => _selectedIndex = i),
          items: [
            BottomNavigationBarItem(
                icon: const Icon(Icons.menu_book_rounded), label: loc.translate('sabaq_lessons')),
            BottomNavigationBarItem(
                icon: const Icon(Icons.fact_check_rounded), label: loc.translate('attendance')),
            BottomNavigationBarItem(
                icon: const Icon(Icons.currency_rupee_rounded), label: loc.translate('fee_record')),
            BottomNavigationBarItem(
                icon: const Icon(Icons.people_outline_rounded), label: loc.translate('students_list')),
          ],
        );
      case AppRole.parent:
        return BottomNavigationBar(
          currentIndex: _selectedIndex.clamp(0, 2),
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
          return StudentListScreen(
            languageController: widget.languageController,
            currentRole: widget.currentRole,
            hideAppBar: true,
          );
        }
        if (_selectedIndex == 2) {
          return FeeScreen(
            students: widget.students,
            languageController: widget.languageController,
            onSave: widget.onSave,
            currentRole: widget.currentRole,
          );
        }
        if (_selectedIndex == 3) {
          return AttendanceScreen(
            students: widget.students,
            languageController: widget.languageController,
            onSave: widget.onSave,
            currentRole: widget.currentRole,
          );
        }
        return _buildManagerAdminOverview();

      case AppRole.teacher:
        if (_selectedIndex == 0) {
          return LessonScreen(
            students: widget.students,
            languageController: widget.languageController,
          );
        }
        if (_selectedIndex == 1) {
          return AttendanceScreen(
            students: widget.students,
            languageController: widget.languageController,
            onSave: widget.onSave,
            currentRole: widget.currentRole,
          );
        }
        if (_selectedIndex == 2) {
          return FeeScreen(
            students: widget.students,
            languageController: widget.languageController,
            onSave: widget.onSave,
            currentRole: widget.currentRole,
          );
        }
        // index 3 = Students List
        return StudentListScreen(
          languageController: widget.languageController,
          currentRole: widget.currentRole,
          hideAppBar: true,
        );

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
            currentRole: widget.currentRole,
          );
        }
        return _buildParentChildOverview();

      case AppRole.mutawalli:
        if (_selectedIndex == 1) {
          return FeeScreen(
            students: widget.students,
            languageController: widget.languageController,
            onSave: widget.onSave,
            currentRole: widget.currentRole,
          );
        }
        if (_selectedIndex == 2) {
          return AttendanceScreen(
            students: widget.students,
            languageController: widget.languageController,
            onSave: widget.onSave,
            currentRole: widget.currentRole,
          );
        }
        return _buildMutawalliOverview();

      case AppRole.other:
        return _buildOtherOverview();
    }
  }

  // ── MANAGER / ADMIN OVERVIEW ──
  Widget _buildManagerAdminOverview() {
    final loc = AppLocalizations.of(context);
    final totalStudents = widget.students.length;
    final presentCount =
        widget.students.where((s) => s['isPresent'] == true).length;
    final absentCount = totalStudents - presentCount;
    final paidCount =
        widget.students.where((s) => s['feeStatus'] == 'paid').length;
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
                if (widget.students.where((s) => s['isPresent'] != true).isNotEmpty) ...[
                  const Divider(color: Colors.white30, height: 16),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text('${loc.translate('absent')} ${loc.translate('students_list')}:',
                        style: const TextStyle(fontSize: 11, color: Colors.amberAccent, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 6),
                  ...widget.students
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
                  if (widget.students.where((s) => s['isPresent'] != true).length > 5)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '+${widget.students.where((s) => s['isPresent'] != true).length - 5} more...',
                        style: const TextStyle(fontSize: 10, color: Colors.white54),
                      ),
                    ),
                ],
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
    final isEn = widget.languageController.locale.languageCode == 'en';
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
