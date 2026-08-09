import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_localizations.dart';
import 'role_selection_screen.dart';

class LoginScreen extends StatefulWidget {
  final AppRole role;
  final LanguageController languageController;
  final VoidCallback onLoginSuccess;
  final VoidCallback onBack;

  const LoginScreen({
    super.key,
    required this.role,
    required this.languageController,
    required this.onLoginSuccess,
    required this.onBack,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isNewUserMode = false; // Toggle between Login and New User Creation
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  final _confirmPinCtrl = TextEditingController();

  bool _obscurePin = true;
  bool _rememberMe = true;
  String _errorMsg = '';
  String _lastLoginTimeStr = '';
  
  // Advanced PIN Pad state
  String _pinDigits = '';
  String _confirmPinDigits = '';
  bool _isConfirmPinMode = false;
  // ignore: unused_field
  final GlobalKey<_PinDotsRowState> _pinDotsKey = GlobalKey<_PinDotsRowState>();
  // ignore: unused_field
  final GlobalKey<_PinDotsRowState> _confirmPinDotsKey = GlobalKey<_PinDotsRowState>();

  // Failed Attempt Lockout State
  int _failedAttempts = 0;
  bool _isLockedOut = false;
  int _lockoutSeconds = 0;

  late AppRole _selectedRoleForRegistration;

  List<AppRole> get _allowedRegistrationRoles {
    if (widget.role == AppRole.manager) {
      // Manager can ONLY create accounts for Mutawalli and Teacher
      return [AppRole.teacher, AppRole.mutawalli];
    } else if (widget.role == AppRole.teacher) {
      // Teacher can ONLY create accounts for Parents
      return [AppRole.parent];
    }
    // Admin / Default can create Admin, Manager, Teacher, Parent, Mutawalli
    return [AppRole.admin, AppRole.manager, AppRole.teacher, AppRole.parent, AppRole.mutawalli];
  }

  @override
  void initState() {
    super.initState();
    _selectedRoleForRegistration = _allowedRegistrationRoles.contains(widget.role)
        ? widget.role
        : _allowedRegistrationRoles.first;
    _loadSavedState();
  }

  Future<void> _loadSavedState() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load Remembered Credentials
    _rememberMe = prefs.getBool('remember_me_${widget.role.name}') ?? true;
    final savedName = prefs.getString('cred_${widget.role.name}_name');
    final savedPhone = prefs.getString('cred_${widget.role.name}_phone');
    final lastLogin = prefs.getString('last_login_timestamp_${widget.role.name}');

    if (lastLogin != null && lastLogin.isNotEmpty) {
      setState(() {
        _lastLoginTimeStr = lastLogin;
      });
    }

    if (_rememberMe) {
      if (savedName != null && savedName.isNotEmpty) {
        _nameCtrl.text = savedName;
      }
      if (savedPhone != null && savedPhone.isNotEmpty) {
        _phoneCtrl.text = savedPhone;
      }
    }

    if (_nameCtrl.text.isEmpty) {
      _setDefaultNameAndPhone();
    }
  }

  void _setDefaultNameAndPhone() {
    switch (widget.role) {
      case AppRole.admin:
        _nameCtrl.text = 'قاری محمد طارق (ایڈمن)';
        _phoneCtrl.text = '1234567890';
        break;
      case AppRole.manager:
        _nameCtrl.text = 'مولانا عبداللہ علی (مینجر)';
        _phoneCtrl.text = '9876543210';
        break;
      case AppRole.teacher:
        _nameCtrl.text = 'حافظ احمد حسن (استاد)';
        _phoneCtrl.text = '8888888888';
        break;
      case AppRole.parent:
        _nameCtrl.text = 'محمد ابراہیم (والد)';
        _phoneCtrl.text = '9999999999';
        break;
      case AppRole.mutawalli:
        _nameCtrl.text = 'الحاج رشید احمد (متولی)';
        _phoneCtrl.text = '7777777777';
        break;
      case AppRole.other:
        _nameCtrl.text = 'صارف';
        _phoneCtrl.text = 'other';
        break;
    }
  }

  void _triggerLockoutTimer() {
    final loc = AppLocalizations(widget.languageController.locale);
    setState(() {
      _isLockedOut = true;
      _lockoutSeconds = 30;
      _errorMsg = '${loc.translate('too_many_attempts')} ${loc.translate('security_lock')}: 30 ${loc.translate('seconds_remaining')}';
    });

    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      if (_lockoutSeconds > 1) {
        setState(() {
          _lockoutSeconds--;
          _errorMsg = '${loc.translate('security_lock')}: $_lockoutSeconds ${loc.translate('seconds_remaining')}...';
        });
        return true;
      } else {
        setState(() {
          _isLockedOut = false;
          _failedAttempts = 0;
          _errorMsg = '';
        });
        return false;
      }
    });
  }

  Future<void> _handleLogin() async {
    final loc = AppLocalizations(widget.languageController.locale);
    if (_isLockedOut) return;

    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final pin = _pinCtrl.text.trim();

    if (phone.isEmpty || pin.isEmpty) {
      setState(() => _errorMsg = loc.translate('error_phone_pin'));
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final savedPhone = prefs.getString('cred_${widget.role.name}_phone');
    final savedPin = prefs.getString('cred_${widget.role.name}_pin');

    bool isAuthenticated = false;

    // 1. Direct Saved Credentials check
    if (savedPhone != null && savedPin != null && savedPhone == phone && savedPin == pin) {
      isAuthenticated = true;
    }

    // 2. Role-specific saved PIN or per-student parent PIN check
    if (!isAuthenticated && widget.role == AppRole.parent) {
      final perStudentPin = prefs.getString('cred_parent_${phone}_pin');
      if (perStudentPin != null && perStudentPin == pin) {
        isAuthenticated = true;
      }
    }

    // 3. Default PIN Fallback
    if (!isAuthenticated) {
      if (pin == '1234' || (savedPin != null && savedPin == pin)) {
        if (phone == widget.role.name ||
            (widget.role == AppRole.admin && (phone == '1234567890' || phone == 'admin')) ||
            (widget.role == AppRole.manager && (phone == '9876543210' || phone == 'manager')) ||
            (widget.role == AppRole.teacher && (phone == '8888888888' || phone == 'teacher')) ||
            (widget.role == AppRole.parent && (phone == '9999999999' || phone == 'parent')) ||
            (widget.role == AppRole.mutawalli && (phone == '7777777777' || phone == 'mutawalli')) ||
            (widget.role == AppRole.other && phone == 'other')) {
          isAuthenticated = true;
        }
      }
    }

    if (isAuthenticated) {
      final displayName = name.isNotEmpty ? name : '${widget.role.name.toUpperCase()} User';
      final now = DateTime.now();
      final timeStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

      await prefs.setBool('remember_me_${widget.role.name}', _rememberMe);
      if (_rememberMe) {
        await prefs.setString('cred_${widget.role.name}_name', displayName);
        await prefs.setString('cred_${widget.role.name}_phone', phone);
      }
      await prefs.setString('cred_${widget.role.name}_pin', pin);
      await prefs.setString('current_user_name', displayName);
      await prefs.setString('last_login_timestamp_${widget.role.name}', timeStr);

      widget.onLoginSuccess();
    } else {
      _failedAttempts++;
      if (_failedAttempts >= 5) {
        _triggerLockoutTimer();
      } else {
        setState(() {
          _errorMsg = '${loc.translate('error_wrong_pin')}. ${loc.translate('attempts_remaining')}: ${5 - _failedAttempts}';
        });
      }
    }
  }

  Future<void> _handleNewUserRegistration() async {
    final loc = AppLocalizations(widget.languageController.locale);
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final pin = _pinCtrl.text.trim();
    final confirmPin = _confirmPinCtrl.text.trim();

    if (name.isEmpty) {
      setState(() => _errorMsg = loc.translate('error_name_required'));
      return;
    }
    if (phone.isEmpty || phone.length < 8) {
      setState(() => _errorMsg = loc.translate('error_phone_invalid'));
      return;
    }
    if (pin.length < 4) {
      setState(() => _errorMsg = loc.translate('error_pin_short'));
      return;
    }
    if (pin != confirmPin) {
      setState(() => _errorMsg = loc.translate('error_pin_mismatch'));
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final targetRole = _selectedRoleForRegistration;

    await prefs.setString('cred_${targetRole.name}_name', name);
    await prefs.setString('cred_${targetRole.name}_phone', phone);
    await prefs.setString('cred_${targetRole.name}_pin', pin);
    await prefs.setString('current_user_name', name);

    if (targetRole == AppRole.parent) {
      await prefs.setString('cred_parent_${phone}_pin', pin);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${loc.translate('account_created')} ($name)'),
          backgroundColor: Colors.green,
        ),
      );
      widget.onLoginSuccess();
    }
  }

  Future<void> _handleBiometricLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPhone = prefs.getString('cred_${widget.role.name}_phone') ?? '';
    final savedPin = prefs.getString('cred_${widget.role.name}_pin') ?? '';
    
    if (savedPhone.isEmpty || savedPin.isEmpty) {
      if (mounted) {
        final loc = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.locale.languageCode == 'en' 
                ? 'Please log in manually once to set up biometric access.' 
                : 'بائیو میٹرک کے لیے پہلے ایک بار مینوئل لاگ ان کریں۔'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }
    
    _phoneCtrl.text = savedPhone;
    _pinCtrl.text = savedPin;
    await _handleLogin();
  }

  void _showForgotPinDialog() {
    final loc = AppLocalizations(widget.languageController.locale);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.help_outline_rounded, color: Colors.indigo),
            const SizedBox(width: 8),
            Text(loc.translate('pin_recovery'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          '${loc.translate('pin_recovery_msg')}\n\nDefault PIN: 1234',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(loc.translate('ok')),
          ),
        ],
      ),
    );
  }

  Color get _roleColor {
    switch (widget.role) {
      case AppRole.admin:
        return const Color(0xFF0F172A);
      case AppRole.manager:
        return const Color(0xFF5B21B6);
      case AppRole.teacher:
        return const Color(0xFF074E32);
      case AppRole.parent:
        return const Color(0xFF991B1B);
      case AppRole.mutawalli:
        return const Color(0xFFC2410C);
      case AppRole.other:
        return const Color(0xFF334155);
    }
  }

  String get _roleTitleUrdu {
    final loc = AppLocalizations(widget.languageController.locale);
    switch (widget.role) {
      case AppRole.admin:
        return loc.translate('admin_login');
      case AppRole.manager:
        return loc.translate('manager_login');
      case AppRole.teacher:
        return loc.translate('teacher_login');
      case AppRole.parent:
        return loc.translate('parent_login');
      case AppRole.mutawalli:
        return loc.translate('mutawalli_login');
      case AppRole.other:
        return loc.translate('user_login');
    }
  }

  IconData get _roleIcon {
    switch (widget.role) {
      case AppRole.admin:
        return Icons.admin_panel_settings_rounded;
      case AppRole.manager:
        return Icons.business_center_rounded;
      case AppRole.teacher:
        return Icons.record_voice_over_rounded;
      case AppRole.parent:
        return Icons.family_restroom_rounded;
      case AppRole.mutawalli:
        return Icons.mosque_rounded;
      case AppRole.other:
        return Icons.person_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = widget.languageController.locale.languageCode != 'en';
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inputBgColor = isDark ? const Color(0xFF1C2541) : const Color(0xFFF8FAFC);
    final textColor = isDark ? Colors.white : Colors.black87;
    final fieldLabelColor = isDark ? Colors.tealAccent : const Color(0xFF074E32);

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        appBar: AppBar(
          backgroundColor: _roleColor,
          foregroundColor: Colors.white,
          title: const SizedBox.shrink(),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: widget.onBack,
          ),
          actions: [
            LanguageButton(controller: widget.languageController),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            children: [
              // Dynamic Role Banner Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_roleColor, _roleColor.withValues(alpha: 0.85)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: _roleColor.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: Colors.white24,
                      child: Icon(_roleIcon, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _roleTitleUrdu,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Role: ${widget.role.name.toUpperCase()} Tier',
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Segmented Toggle: Already Have Account vs Create New Account
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _isNewUserMode = false;
                          _errorMsg = '';
                          _pinDigits = '';
                          _confirmPinDigits = '';
                          _isConfirmPinMode = false;
                          _pinCtrl.clear();
                          _confirmPinCtrl.clear();
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !_isNewUserMode ? _roleColor : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            loc.translate('login'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: !_isNewUserMode ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _isNewUserMode = true;
                          _errorMsg = '';
                          _pinDigits = '';
                          _confirmPinDigits = '';
                          _isConfirmPinMode = false;
                          _pinCtrl.clear();
                          _confirmPinCtrl.clear();
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _isNewUserMode ? _roleColor : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            loc.locale.languageCode == 'ur' ? 'نیا اکاؤنٹ بنائیں' : 'Create Account',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: _isNewUserMode ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Main Glassmorphic Form Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_errorMsg.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            border: Border.all(color: Colors.red.shade300),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline_rounded, color: Colors.red.shade700, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMsg,
                                  style: TextStyle(color: Colors.red.shade800, fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Form Input 1: Full Name
                      TextFormField(
                        controller: _nameCtrl,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          labelText: loc.translate('full_name'),
                          labelStyle: TextStyle(color: fieldLabelColor),
                          prefixIcon: Icon(Icons.person, color: fieldLabelColor),
                          filled: true,
                          fillColor: inputBgColor,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),

                      // Form Input 2: Mobile Phone Number
                      TextFormField(
                        controller: _phoneCtrl,
                        style: TextStyle(color: textColor),
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: loc.translate('phone_number'),
                          labelStyle: TextStyle(color: fieldLabelColor),
                          prefixIcon: Icon(Icons.phone, color: fieldLabelColor),
                          filled: true,
                          fillColor: inputBgColor,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),

                      if (_isNewUserMode) ...[
                        // Role Selection for Registration
                        DropdownButtonFormField<AppRole>(
                          initialValue: _selectedRoleForRegistration,
                          dropdownColor: isDark ? const Color(0xFF0B1329) : null,
                          style: TextStyle(color: textColor),
                          decoration: InputDecoration(
                            labelText: loc.translate('select_role'),
                            labelStyle: TextStyle(color: fieldLabelColor),
                            prefixIcon: Icon(Icons.badge_rounded, color: fieldLabelColor),
                            filled: true,
                            fillColor: inputBgColor,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: _allowedRegistrationRoles.map((r) {
                            String rTitle = r.name.toUpperCase();
                            final isUr = loc.locale.languageCode == 'ur';
                            if (r == AppRole.admin) rTitle = isUr ? 'ایڈمن' : 'Admin';
                            if (r == AppRole.manager) rTitle = isUr ? 'مینجر' : 'Manager';
                            if (r == AppRole.teacher) rTitle = isUr ? 'استاد' : 'Teacher';
                            if (r == AppRole.parent) rTitle = isUr ? 'والدین/سرپرست' : 'Parent/Guardian';
                            if (r == AppRole.mutawalli) rTitle = isUr ? 'متولی' : 'Mutawalli';
                            return DropdownMenuItem(value: r, child: Text(rTitle, style: TextStyle(color: textColor)));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedRoleForRegistration = val);
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                      ],

                      // PIN Input Section
                      SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1C2541) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark ? const Color(0xFF334155) : Colors.grey.shade300,
                          ),
                        ),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _pinCtrl,
                              obscureText: _obscurePin,
                              keyboardType: TextInputType.number,
                              style: TextStyle(color: textColor),
                              decoration: InputDecoration(
                                labelText: loc.translate('pin'),
                                labelStyle: TextStyle(color: fieldLabelColor),
                                prefixIcon: Icon(Icons.lock_rounded, color: fieldLabelColor),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePin ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                    size: 16,
                                    color: isDark ? Colors.white54 : Colors.grey,
                                  ),
                                  onPressed: () => setState(() => _obscurePin = !_obscurePin),
                                ),
                                filled: true,
                                fillColor: inputBgColor,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              textInputAction: TextInputAction.done,
                            ),
                            if (_isNewUserMode) ...[
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _confirmPinCtrl,
                                obscureText: _obscurePin,
                                keyboardType: TextInputType.number,
                                style: TextStyle(color: textColor),
                                decoration: InputDecoration(
                                  labelText: loc.translate('confirm_pin'),
                                  labelStyle: TextStyle(color: fieldLabelColor),
                                  prefixIcon: Icon(Icons.lock_rounded, color: fieldLabelColor),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePin ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                      size: 16,
                                      color: isDark ? Colors.white54 : Colors.grey,
                                    ),
                                    onPressed: () => setState(() => _obscurePin = !_obscurePin),
                                  ),
                                  filled: true,
                                  fillColor: inputBgColor,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                textInputAction: TextInputAction.done,
                              ),
                            ],
                          ],
                        ),
                      ),

                      if (!_isNewUserMode) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Checkbox(
                              value: _rememberMe,
                              activeColor: _roleColor,
                              onChanged: (val) {
                                if (val != null) setState(() => _rememberMe = val);
                              },
                            ),
                            Text(loc.translate('remember_me'), style: const TextStyle(fontSize: 12.5)),
                            const Spacer(),
                            TextButton(
                              onPressed: _showForgotPinDialog,
                              child: Text(loc.translate('forgot_pin'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 20),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: _roleColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: Icon(_isNewUserMode ? Icons.person_add_rounded : Icons.login_rounded),
                          label: Text(
                            _isNewUserMode ? loc.translate('create_account_btn') : loc.translate('login_btn'),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          onPressed: _isLockedOut
                              ? null
                              : (_isNewUserMode ? _handleNewUserRegistration : _handleLogin),
                        ),
                      ),

                      if (!_isNewUserMode) ...[
                        const SizedBox(height: 14),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                            side: BorderSide(color: _roleColor),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: const Icon(Icons.fingerprint_rounded, size: 22),
                          label: Text(
                            loc.translate('biometric_login'),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          onPressed: _handleBiometricLogin,
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              if (_lastLoginTimeStr.isNotEmpty) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.history_rounded, size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      '${loc.translate('last_login')}: $_lastLoginTimeStr',
                      style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ─── PIN Pad Grid ───────────────────────────────────────────
  // ignore: unused_element
  Widget _buildPinGrid(bool isDark, Color textColor) {
    final buttonColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : Colors.grey.shade200;

    Widget pinBtn(String label, {IconData? icon, Color? bgColor, VoidCallback? onTap}) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Material(
            color: bgColor ?? buttonColor,
            borderRadius: BorderRadius.circular(14),
            elevation: isDark ? 0 : 1,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: onTap,
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor, width: 0.5),
                ),
                alignment: Alignment.center,
                child: icon != null
                    ? Icon(icon, color: textColor, size: 24)
                    : Text(
                        label,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        Row(children: [
          pinBtn('1', onTap: () => _onPinDigitTap('1')),
          pinBtn('2', onTap: () => _onPinDigitTap('2')),
          pinBtn('3', onTap: () => _onPinDigitTap('3')),
        ]),
        Row(children: [
          pinBtn('4', onTap: () => _onPinDigitTap('4')),
          pinBtn('5', onTap: () => _onPinDigitTap('5')),
          pinBtn('6', onTap: () => _onPinDigitTap('6')),
        ]),
        Row(children: [
          pinBtn('7', onTap: () => _onPinDigitTap('7')),
          pinBtn('8', onTap: () => _onPinDigitTap('8')),
          pinBtn('9', onTap: () => _onPinDigitTap('9')),
        ]),
        Row(children: [
          pinBtn('', icon: Icons.fingerprint_rounded,
            bgColor: _roleColor.withValues(alpha: 0.15),
            onTap: _handleBiometricLogin,
          ),
          pinBtn('0', onTap: () => _onPinDigitTap('0')),
          pinBtn('', icon: Icons.backspace_rounded,
            bgColor: isDark ? const Color(0xFF2D1B1B) : Colors.red.shade50,
            onTap: _onPinBackspace,
          ),
        ]),
      ],
    );
  }

  void _onPinDigitTap(String digit) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_isNewUserMode && _isConfirmPinMode) {
        if (_confirmPinDigits.length < 4) {
          _confirmPinDigits += digit;
          _confirmPinCtrl.text = _confirmPinDigits;
        }
      } else {
        if (_pinDigits.length < 4) {
          _pinDigits += digit;
          _pinCtrl.text = _pinDigits;
        }
        // In registration mode, auto-switch to confirm PIN after 4 digits
        if (_isNewUserMode && _pinDigits.length == 4 && !_isConfirmPinMode) {
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              setState(() => _isConfirmPinMode = true);
            }
          });
        }
      }
    });
  }

  void _onPinBackspace() {
    HapticFeedback.mediumImpact();
    setState(() {
      if (_isNewUserMode && _isConfirmPinMode) {
        if (_confirmPinDigits.isNotEmpty) {
          _confirmPinDigits = _confirmPinDigits.substring(0, _confirmPinDigits.length - 1);
          _confirmPinCtrl.text = _confirmPinDigits;
        } else {
          // Go back to PIN entry mode
          _isConfirmPinMode = false;
        }
      } else {
        if (_pinDigits.isNotEmpty) {
          _pinDigits = _pinDigits.substring(0, _pinDigits.length - 1);
          _pinCtrl.text = _pinDigits;
        }
      }
    });
  }
}

// ═══════════════════════════════════════════════════════════════
// PIN Dots Row Widget - Animated dots showing PIN entry progress
// ═══════════════════════════════════════════════════════════════
class _PinDotsRow extends StatefulWidget {
  final String pinText;
  final int maxLength;
  final bool obscure;
  final Color activeColor;
  final Color inactiveColor;

  const _PinDotsRow({
    // ignore: unused_element_parameter
    super.key,
    required this.pinText,
    required this.maxLength,
    required this.obscure,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  State<_PinDotsRow> createState() => _PinDotsRowState();
}

class _PinDotsRowState extends State<_PinDotsRow> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(_PinDotsRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pinText.length != oldWidget.pinText.length && widget.pinText.length > oldWidget.pinText.length) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.maxLength, (i) {
        final isFilled = i < widget.pinText.length;
        final isLatest = i == widget.pinText.length - 1 && widget.pinText.isNotEmpty;

        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final scale = isLatest ? 1.0 + (_controller.value * 0.3) : 1.0;
            return Transform.scale(
              scale: scale,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                width: isFilled ? (widget.obscure ? 18 : 24) : 16,
                height: isFilled ? (widget.obscure ? 18 : 24) : 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isFilled ? widget.activeColor : Colors.transparent,
                  border: Border.all(
                    color: isFilled ? widget.activeColor : widget.inactiveColor,
                    width: 2.5,
                  ),
                  boxShadow: isFilled
                      ? [
                          BoxShadow(
                            color: widget.activeColor.withValues(alpha: 0.4),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: isFilled && !widget.obscure
                    ? Center(
                        child: Text(
                          widget.pinText[i],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.black87 : Colors.white,
                          ),
                        ),
                      )
                    : null,
              ),
            );
          },
        );
      }),
    );
  }
}

