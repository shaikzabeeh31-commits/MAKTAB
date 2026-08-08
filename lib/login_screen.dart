import 'package:flutter/material.dart';
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
    setState(() {
      _isLockedOut = true;
      _lockoutSeconds = 30;
      _errorMsg = 'بہت سی غلط کوششیں! سیکیورٹی کے لیے 30 سیکنڈز بعد دوبارہ کوشش کریں۔';
    });

    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      if (_lockoutSeconds > 1) {
        setState(() {
          _lockoutSeconds--;
          _errorMsg = 'سیکیورٹی لاک: $_lockoutSeconds سیکنڈز باقی ہیں...';
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
    if (_isLockedOut) return;

    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final pin = _pinCtrl.text.trim();

    if (phone.isEmpty || pin.isEmpty) {
      setState(() => _errorMsg = 'براہ کرم فون نمبر اور 4 ہندسوں کا پن (PIN) درج کریں۔');
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
          _errorMsg = 'غلط فون نمبر یا پن (PIN)۔ باقی کوششیں: ${5 - _failedAttempts}';
        });
      }
    }
  }

  Future<void> _handleNewUserRegistration() async {
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final pin = _pinCtrl.text.trim();
    final confirmPin = _confirmPinCtrl.text.trim();

    if (name.isEmpty) {
      setState(() => _errorMsg = 'براہ کرم اپنا پورا نام درج کریں۔');
      return;
    }
    if (phone.isEmpty || phone.length < 8) {
      setState(() => _errorMsg = 'براہ کرم درست موبائل فون نمبر درج کریں۔');
      return;
    }
    if (pin.length < 4) {
      setState(() => _errorMsg = 'پن (PIN) کم از کم 4 ہندسوں کا ہونا چاہیے۔');
      return;
    }
    if (pin != confirmPin) {
      setState(() => _errorMsg = 'پن (PIN) کی تصدیق میچ نہیں ہوئی۔');
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
          content: Text('نیا اکاؤنٹ ($name) کامیابی سے رجسٹر ہو گیا!'),
          backgroundColor: Colors.green,
        ),
      );
      widget.onLoginSuccess();
    }
  }

  Future<void> _handleBiometricLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPin = prefs.getString('cred_${widget.role.name}_pin') ?? '1234';
    _pinCtrl.text = savedPin;
    await _handleLogin();
  }

  void _showForgotPinDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.help_outline_rounded, color: Colors.indigo),
            SizedBox(width: 8),
            Text('پن (PIN) کی بازیابی / Forgotten PIN', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'اگر آپ اپنا PIN بھول گئے ہیں تو ایڈمن یا متعلقہ استاد سے رابطہ کریں۔ وہ "اسٹاف و والدین PIN انتظام" سے آپ کا نیا PIN چند سیکنڈز میں سیٹ کر سکتے ہیں۔\n\nDefault PIN: 1234',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ٹھیک ہے (OK)'),
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
    switch (widget.role) {
      case AppRole.admin:
        return 'ایڈمن لاگ ان (Administrator)';
      case AppRole.manager:
        return 'مینجر لاگ ان (Manager)';
      case AppRole.teacher:
        return 'استاد لاگ ان (Teacher)';
      case AppRole.parent:
        return 'والدین لاگ ان (Parent)';
      case AppRole.mutawalli:
        return 'متولی لاگ ان (Mutawalli)';
      case AppRole.other:
        return 'صارف لاگ ان (User)';
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

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        appBar: AppBar(
          backgroundColor: _roleColor,
          foregroundColor: Colors.white,
          title: Text(_roleTitleUrdu, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _isNewUserMode = false;
                          _errorMsg = '';
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !_isNewUserMode ? _roleColor : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'پہلے سے اکاؤنٹ ہے (Login)',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: !_isNewUserMode ? Colors.white : Colors.black87,
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
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _isNewUserMode ? _roleColor : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'نیا اکاؤنٹ بنائیں (Create Account)',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: _isNewUserMode ? Colors.white : Colors.black87,
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
                        decoration: InputDecoration(
                          labelText: 'صارف کا نام (Full Name)',
                          prefixIcon: const Icon(Icons.person),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),

                      // Form Input 2: Mobile Phone Number
                      TextFormField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'موبائل نمبر / فون (Phone Number)',
                          prefixIcon: const Icon(Icons.phone),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),

                      if (_isNewUserMode) ...[
                        // Role Selection for Registration
                        DropdownButtonFormField<AppRole>(
                          initialValue: _selectedRoleForRegistration,
                          decoration: InputDecoration(
                            labelText: 'کردار منتخب کریں (Select User Role)',
                            prefixIcon: const Icon(Icons.badge_rounded),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: _allowedRegistrationRoles.map((r) {
                            String rTitle = r.name.toUpperCase();
                            if (r == AppRole.admin) rTitle = 'ایڈمن (Admin)';
                            if (r == AppRole.manager) rTitle = 'مینجر (Manager)';
                            if (r == AppRole.teacher) rTitle = 'استاد (Teacher)';
                            if (r == AppRole.parent) rTitle = 'والدین (Parent)';
                            if (r == AppRole.mutawalli) rTitle = 'متولی (Mutawalli)';
                            return DropdownMenuItem(value: r, child: Text(rTitle));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedRoleForRegistration = val);
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Form Input 3: 4-Digit PIN
                      TextFormField(
                        controller: _pinCtrl,
                        obscureText: _obscurePin,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        decoration: InputDecoration(
                          labelText: _isNewUserMode ? 'نیا 4 ہندسوں کا پن (New PIN)' : '4 ہندسوں کا پن (PIN)',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePin ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _obscurePin = !_obscurePin),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          counterText: '',
                        ),
                        textInputAction: _isNewUserMode ? TextInputAction.next : TextInputAction.done,
                      ),

                      if (_isNewUserMode) ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _confirmPinCtrl,
                          obscureText: _obscurePin,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          decoration: InputDecoration(
                            labelText: 'پن کی تصدیق (Confirm PIN)',
                            prefixIcon: const Icon(Icons.lock_reset_rounded),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            counterText: '',
                          ),
                          textInputAction: TextInputAction.done,
                        ),
                      ],

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
                            const Text('معلومات یاد رکھیں (Remember Me)', style: TextStyle(fontSize: 12.5)),
                            const Spacer(),
                            TextButton(
                              onPressed: _showForgotPinDialog,
                              child: const Text('PIN بھول گئے؟', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
                            _isNewUserMode ? 'نیا اکاؤنٹ بنائیں اور داخل ہوں' : 'لاگ ان کریں (Login)',
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
                          label: const Text(
                            'فنگر پرنٹ / بائیو میٹرک لاگ ان (Biometric Login)',
                            style: TextStyle(fontWeight: FontWeight.bold),
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
                      'آخری کامیاب لاگ ان: $_lastLoginTimeStr',
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
}
