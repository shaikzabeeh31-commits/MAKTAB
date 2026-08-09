import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'app_localizations.dart';
import 'role_selection_screen.dart';

class ManageStaffLoginsScreen extends StatefulWidget {
  final LanguageController languageController;
  final AppRole currentUserRole;

  const ManageStaffLoginsScreen({
    super.key,
    required this.languageController,
    this.currentUserRole = AppRole.admin,
  });

  @override
  State<ManageStaffLoginsScreen> createState() => _ManageStaffLoginsScreenState();
}

class _ManageStaffLoginsScreenState extends State<ManageStaffLoginsScreen> {
  bool _isLoading = true;

  final Map<AppRole, TextEditingController> _phoneControllers = {
    AppRole.admin: TextEditingController(text: '1234567890'),
    AppRole.manager: TextEditingController(text: '9876543210'),
    AppRole.teacher: TextEditingController(text: '8888888888'),
    AppRole.mutawalli: TextEditingController(text: '7777777777'),
  };

  final Map<AppRole, TextEditingController> _pinControllers = {
    AppRole.admin: TextEditingController(text: '1234'),
    AppRole.manager: TextEditingController(text: '1234'),
    AppRole.teacher: TextEditingController(text: '1234'),
    AppRole.mutawalli: TextEditingController(text: '1234'),
  };

  final Map<AppRole, bool> _obscurePinMap = {
    AppRole.admin: true,
    AppRole.manager: true,
    AppRole.teacher: true,
    AppRole.mutawalli: true,
  };

  List<AppRole> get _manageableRoles {
    if (widget.currentUserRole == AppRole.manager) {
      // Manager can ONLY create/manage Teacher & Mutawalli accounts
      return [AppRole.teacher, AppRole.mutawalli];
    }
    // Admin can manage Admin, Manager, Teacher, Mutawalli
    return [AppRole.admin, AppRole.manager, AppRole.teacher, AppRole.mutawalli];
  }

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      for (final role in _manageableRoles) {
        final savedPhone = prefs.getString('cred_${role.name}_phone');
        final savedPin = prefs.getString('cred_${role.name}_pin');

        if (savedPhone != null && savedPhone.isNotEmpty) {
          _phoneControllers[role]!.text = savedPhone;
        }
        if (savedPin != null && savedPin.isNotEmpty) {
          _pinControllers[role]!.text = savedPin;
        }
      }
      _isLoading = false;
    });
  }

  Future<void> _saveCredentials(AppRole role) async {
    final phone = _phoneControllers[role]!.text.trim();
    final pin = _pinControllers[role]!.text.trim();
    final isEn = widget.languageController.locale.languageCode == 'en';

    if (phone.isEmpty || pin.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEn ? 'Please enter a valid phone number and a 4-digit PIN.' : 'براہ کرم صحیح فون نمبر اور کم از کم 4 ہندسوں کا پن (PIN) درج کریں۔'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cred_${role.name}_phone', phone);
    await prefs.setString('cred_${role.name}_pin', pin);

    if (mounted) {
      _showShareCredentialsDialog(role, phone, pin);
    }
  }

  void _generateRandomPin(AppRole role) {
    final randomPin = (1000 + (9000 * (DateTime.now().microsecondsSinceEpoch % 1000) / 1000)).toInt().toString();
    setState(() {
      _pinControllers[role]!.text = randomPin;
    });
  }

  Future<void> _sendWhatsApp(String phone, String roleTitle, String pin) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    final fullPhone = cleanPhone.startsWith('91') ? cleanPhone : '91$cleanPhone';
    final isEn = widget.languageController.locale.languageCode == 'en';
    final message = isEn
        ? "Assalamu Alaikum! Your Maktab App ($roleTitle) login details are ready.\n\n📱 Mobile: $phone\n🔑 4-Digit PIN: $pin\n\nPlease log in to the app."
        : "السلام علیکم! آپ کا مکتب ایپ ($roleTitle) لاگ ان اور PIN تیار ہو گیا ہے۔\n\n📱 موبائل نمبر: $phone\n🔑 4-Digit PIN: $pin\n\nبرائے مہربانی ایپ میں لاگ ان کریں۔";
    final url = Uri.parse("https://wa.me/$fullPhone?text=${Uri.encodeComponent(message)}");
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  Future<void> _sendSms(String phone, String roleTitle, String pin) async {
    final isEn = widget.languageController.locale.languageCode == 'en';
    final message = isEn
        ? "Maktab App ($roleTitle) Login Details:\nPhone: $phone\nPIN: $pin"
        : "مکتب ایپ ($roleTitle) لاگ ان تفاصیل:\nموبائل: $phone\nPIN: $pin";
    final url = Uri.parse("sms:$phone?body=${Uri.encodeComponent(message)}");
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  void _showShareCredentialsDialog(AppRole role, String phone, String pin) {
    final isEn = widget.languageController.locale.languageCode == 'en';
    final roleTitle = role.name.toUpperCase();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.green),
            const SizedBox(width: 8),
            Text(isEn ? '$roleTitle Credentials Saved' : '$roleTitle کا لاگ ان محفوظ ہو گیا', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isEn ? 'Phone: $phone' : 'موبائل: $phone'),
            Text('PIN: $pin'),
            const SizedBox(height: 14),
            Text(isEn ? 'Do you want to send these details via WhatsApp or SMS?' : 'کیا آپ یہ تفصیلات متعلقہ فرد کو WhatsApp یا SMS کے ذریعے بھیجنا چاہتے ہیں؟', style: const TextStyle(fontSize: 12.5)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.send_rounded, color: Colors.blue),
            tooltip: isEn ? 'Send via SMS' : 'SMS کے ذریعے بھیجیں',
            onPressed: () {
              Navigator.pop(ctx);
              _sendSms(phone, roleTitle, pin);
            },
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            icon: const Icon(Icons.chat_rounded, size: 18),
            label: Text(isEn ? 'WhatsApp' : 'WhatsApp پر بھیجیں'),
            onPressed: () {
              Navigator.pop(ctx);
              _sendWhatsApp(phone, roleTitle, pin);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = widget.languageController.locale.languageCode != 'en';
    final isEn = !isRtl;

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        appBar: AppBar(
          title: Text(
            isEn
                ? (widget.currentUserRole == AppRole.manager
                    ? 'Manage Staff PINs'
                    : 'Manage Staff Logins')
                : (widget.currentUserRole == AppRole.manager
                    ? 'اسٹاف (استاد و متولی) PINs انتظام'
                    : 'اسٹاف PINs و لاگ ان انتظام'),
          ),
          backgroundColor: const Color(0xFF0F172A),
          foregroundColor: Colors.white,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.security_rounded, color: Color(0xFF0F172A), size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isEn
                                      ? (widget.currentUserRole == AppRole.manager
                                          ? 'Manager Portal: Only allowed to manage Teacher & Mutawalli PINs'
                                          : 'Admin Portal: Manage PINs and phone numbers for all staff members')
                                      : (widget.currentUserRole == AppRole.manager
                                          ? 'مینجر پورٹل: صرف استاد اور متولی کے اکاؤنٹس بنانے/سیٹ کرنے کی اجازت ہے'
                                          : 'ایڈمن پورٹل: تمام اسٹاف ممبران کے PINs اور موبائل نمبرز کا انتظام'),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isEn
                                      ? 'After setting or changing a PIN, send it directly via WhatsApp or SMS.'
                                      : 'نیا PIN سیٹ یا تبدیل کرنے کے بعد WhatsApp یا SMS پر ڈائریکٹ بھیجیں۔',
                                  style: const TextStyle(fontSize: 11.5, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._manageableRoles.map((role) => _buildRoleCard(role)),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildRoleCard(AppRole role) {
    String titleUrdu = '';
    Color cardColor = Colors.white;

    final isEn = widget.languageController.locale.languageCode == 'en';
    switch (role) {
      case AppRole.admin:
        titleUrdu = isEn ? 'Master Admin' : 'ایڈمن (Master Admin)';
        cardColor = const Color(0xFF0F172A);
        break;
      case AppRole.manager:
        titleUrdu = isEn ? 'Manager' : 'مینجر (Manager)';
        cardColor = Colors.purple.shade900;
        break;
      case AppRole.teacher:
        titleUrdu = isEn ? 'Teacher' : 'استاد (Teacher)';
        cardColor = Colors.green.shade900;
        break;
      case AppRole.mutawalli:
        titleUrdu = isEn ? 'Mutawalli' : 'متولی (Mutawalli)';
        cardColor = Colors.orange.shade900;
        break;
      default:
        titleUrdu = role.name;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: cardColor,
                  child: Icon(
                    role == AppRole.teacher
                        ? Icons.record_voice_over_rounded
                        : (role == AppRole.mutawalli ? Icons.mosque_rounded : Icons.person),
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  titleUrdu,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 20),
            TextFormField(
              controller: _phoneControllers[role],
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: isEn ? 'Phone Number' : 'موبائل نمبر',
                prefixIcon: const Icon(Icons.phone),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _pinControllers[role],
                    obscureText: _obscurePinMap[role] ?? true,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: InputDecoration(
                      labelText: '4-Digit PIN',
                      prefixIcon: const Icon(Icons.lock),
                      counterText: '',
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePinMap[role] == true ? Icons.visibility_off : Icons.visibility),
                        onPressed: () {
                          setState(() {
                            _obscurePinMap[role] = !(_obscurePinMap[role] ?? true);
                          });
                        },
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    textInputAction: TextInputAction.done,
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _generateRandomPin(role),
                  icon: const Icon(Icons.autorenew_rounded, size: 16),
                  label: Text(isEn ? 'Auto PIN' : 'آٹو PIN', style: const TextStyle(fontSize: 11)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: cardColor),
                    icon: const Icon(Icons.save_rounded, size: 18),
                    label: Text(isEn ? 'Save' : 'محفوظ کریں'),
                    onPressed: () => _saveCredentials(role),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  color: Colors.green.shade800,
                  tooltip: isEn ? 'Send via WhatsApp' : 'WhatsApp پر بھیجیں',
                  icon: const Icon(Icons.chat_rounded),
                  onPressed: () {
                    final phone = _phoneControllers[role]!.text.trim();
                    final pin = _pinControllers[role]!.text.trim();
                    _sendWhatsApp(phone, titleUrdu, pin);
                  },
                ),
                IconButton.filledTonal(
                  color: Colors.blue.shade800,
                  tooltip: isEn ? 'Send via SMS' : 'SMS کے ذریعے بھیجیں',
                  icon: const Icon(Icons.message_rounded),
                  onPressed: () {
                    final phone = _phoneControllers[role]!.text.trim();
                    final pin = _pinControllers[role]!.text.trim();
                    _sendSms(phone, titleUrdu, pin);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
