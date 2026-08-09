import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'app_localizations.dart';

class ManageParentLoginsScreen extends StatefulWidget {
  final LanguageController languageController;
  final List<Map<String, dynamic>> students;
  final Function(List<Map<String, dynamic>> updatedStudents)? onSaveStudents;

  const ManageParentLoginsScreen({
    super.key,
    required this.languageController,
    required this.students,
    this.onSaveStudents,
  });

  @override
  State<ManageParentLoginsScreen> createState() => _ManageParentLoginsScreenState();
}

class _ManageParentLoginsScreenState extends State<ManageParentLoginsScreen> {
  bool _isLoading = true;

  final TextEditingController _globalPhoneCtrl = TextEditingController(text: '9999999999');
  final TextEditingController _globalPinCtrl = TextEditingController(text: '1234');
  bool _obscureGlobalPin = true;

  final Map<int, TextEditingController> _studentPinCtrls = {};
  final Map<int, bool> _obscureStudentPinMap = {};

  List<Map<String, dynamic>> _studentsList = [];

  @override
  void initState() {
    super.initState();
    _studentsList = List<Map<String, dynamic>>.from(widget.students);
    _loadParentCredentials();
  }

  Future<void> _loadParentCredentials() async {
    final prefs = await SharedPreferences.getInstance();

    final savedGlobalPhone = prefs.getString('cred_parent_phone');
    final savedGlobalPin = prefs.getString('cred_parent_pin');

    if (savedGlobalPhone != null && savedGlobalPhone.isNotEmpty) {
      _globalPhoneCtrl.text = savedGlobalPhone;
    }
    if (savedGlobalPin != null && savedGlobalPin.isNotEmpty) {
      _globalPinCtrl.text = savedGlobalPin;
    }

    for (int i = 0; i < _studentsList.length; i++) {
      final student = _studentsList[i];
      final fatherPhone = student['fatherPhone']?.toString() ?? '';
      String pin = student['parentPin']?.toString() ?? '';

      if (pin.isEmpty && fatherPhone.isNotEmpty) {
        pin = prefs.getString('cred_parent_${fatherPhone}_pin') ?? '1234';
      } else if (pin.isEmpty) {
        pin = '1234';
      }

      _studentPinCtrls[i] = TextEditingController(text: pin);
      _obscureStudentPinMap[i] = true;
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveGlobalCredentials() async {
    final phone = _globalPhoneCtrl.text.trim();
    final pin = _globalPinCtrl.text.trim();
    final isEn = widget.languageController.locale.languageCode == 'en';

    if (phone.isEmpty || pin.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEn ? 'Please enter a valid phone number and a 4-digit PIN.' : 'براہ کرم صحیح فون نمبر اور کم از کم 4 ہندسوں کا PIN درج کریں۔'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cred_parent_phone', phone);
    await prefs.setString('cred_parent_pin', pin);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEn ? 'Global Parent PIN and credentials saved!' : 'والدین کا عمومی PIN اور لاگ ان محفوظ ہو گیا!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _saveStudentParentPin(int index) async {
    final student = _studentsList[index];
    final fatherPhone = student['fatherPhone']?.toString().trim() ?? '';
    final pin = _studentPinCtrls[index]!.text.trim();
    final isEn = widget.languageController.locale.languageCode == 'en';

    if (pin.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEn ? 'PIN must be at least 4 digits.' : 'PIN میں کم از کم 4 ہندسے ہونے چاہئیں۔'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    _studentsList[index]['parentPin'] = pin;

    final prefs = await SharedPreferences.getInstance();
    if (fatherPhone.isNotEmpty) {
      await prefs.setString('cred_parent_${fatherPhone}_pin', pin);
    }

    if (widget.onSaveStudents != null) {
      widget.onSaveStudents!(_studentsList);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEn ? 'Parent PIN ($pin) for ${student['name']} saved!' : '${student['name']} کے والد کا PIN ($pin) محفوظ ہو گیا!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _generateRandomGlobalPin() {
    final randomPin = (1000 + (9000 * (DateTime.now().microsecondsSinceEpoch % 1000) / 1000)).toInt().toString();
    setState(() {
      _globalPinCtrl.text = randomPin;
    });
  }

  void _generateRandomStudentPin(int index) {
    final randomPin = (1000 + (9000 * (DateTime.now().microsecondsSinceEpoch % 1000) / 1000)).toInt().toString();
    setState(() {
      _studentPinCtrls[index]!.text = randomPin;
    });
  }

  Future<void> _sendWhatsAppParent(String phone, String studentName, String pin) async {
    if (phone.isEmpty) return;
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    final fullPhone = cleanPhone.startsWith('91') ? cleanPhone : '91$cleanPhone';
    final isEn = widget.languageController.locale.languageCode == 'en';
    final message = isEn
        ? "Assalamu Alaikum! Parent of $studentName, your parent portal login is ready.\n\n📱 Registered Phone: $phone\n🔑 4-Digit Parent PIN: $pin\n\nPlease select Parent Login in the Maktab App."
        : "السلام علیکم! $studentName کے والد گرامی، مکتب ایپ میں آپ کا پیرنٹ پورٹل لاگ ان اور PIN محفوظ ہو گیا ہے۔\n\n📱 رجسٹرڈ موبائل: $phone\n🔑 4-Digit Parent PIN: $pin\n\nبراہ کرم مکتب ایپ میں والدین لاگ ان منتخب کر کے لاگ ان کریں۔";
    final url = Uri.parse("https://wa.me/$fullPhone?text=${Uri.encodeComponent(message)}");
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  Future<void> _sendSmsParent(String phone, String studentName, String pin) async {
    if (phone.isEmpty) return;
    final isEn = widget.languageController.locale.languageCode == 'en';
    final message = isEn
        ? "Parent login for $studentName:\nPhone: $phone\nPIN: $pin"
        : "$studentName پیرنٹ لاگ ان تفاصیل:\nموبائل: $phone\nPIN: $pin";
    final url = Uri.parse("sms:$phone?body=${Uri.encodeComponent(message)}");
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _globalPhoneCtrl.dispose();
    _globalPinCtrl.dispose();
    for (var ctrl in _studentPinCtrls.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = widget.languageController.locale.languageCode != 'en';
    final isEn = !isRtl;

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: const Color(0xFFB45309),
            foregroundColor: Colors.white,
            title: const SizedBox.shrink(),
            bottom: TabBar(
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: [
                Tab(icon: const Icon(Icons.public_rounded), text: isEn ? 'Global Login' : 'عمومی لاگ ان'),
                Tab(icon: const Icon(Icons.people_alt_rounded), text: isEn ? 'By Student PIN' : 'طالب علم کے لحاظ سے PIN'),
              ],
            ),
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  children: [
                    // Tab 1: Global Parent Credentials
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.family_restroom_rounded, color: Color(0xFFB45309), size: 28),
                                      const SizedBox(width: 12),
                                      Text(
                                        isEn ? 'Global Parent Credentials' : 'عمومی والد/مدر لاگ ان credential',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    isEn ? 'Set a global phone number and 4-digit PIN for all parents.' : 'تمام والدین کے لیے ایک عمومی فون نمبر اور 4 ہندسوں کا PIN مقرر کریں۔',
                                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
                                  const Divider(height: 24),
                                  TextFormField(
                                    controller: _globalPhoneCtrl,
                                    keyboardType: TextInputType.phone,
                                    decoration: InputDecoration(
                                      labelText: isEn ? 'Global Phone' : 'عمومی فون نمبر',
                                      prefixIcon: const Icon(Icons.phone),
                                      filled: true,
                                      fillColor: Colors.orange.shade50,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    textInputAction: TextInputAction.next,
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller: _globalPinCtrl,
                                          keyboardType: TextInputType.number,
                                          maxLength: 6,
                                          obscureText: _obscureGlobalPin,
                                          decoration: InputDecoration(
                                            labelText: isEn ? 'Global PIN' : 'عمومی PIN',
                                            counterText: '',
                                            prefixIcon: const Icon(Icons.lock),
                                            filled: true,
                                            fillColor: Colors.orange.shade50,
                                            suffixIcon: IconButton(
                                              icon: Icon(_obscureGlobalPin ? Icons.visibility : Icons.visibility_off),
                                              onPressed: () {
                                                setState(() {
                                                  _obscureGlobalPin = !_obscureGlobalPin;
                                                });
                                              },
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                          ),
                                          textInputAction: TextInputAction.done,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      OutlinedButton.icon(
                                        onPressed: _generateRandomGlobalPin,
                                        icon: const Icon(Icons.refresh, size: 18),
                                        label: Text(isEn ? 'New PIN' : 'نیا PIN'),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  SizedBox(
                                    width: double.infinity,
                                    child: FilledButton.icon(
                                      onPressed: _saveGlobalCredentials,
                                      style: FilledButton.styleFrom(
                                        backgroundColor: const Color(0xFFB45309),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                      icon: const Icon(Icons.save_rounded),
                                      label: Text(isEn ? 'Save Global PIN' : 'عمومی PIN محفوظ کریں'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Tab 2: Per-Student Parent PIN
                    _studentsList.isEmpty
                        ? Center(
                            child: Text(isEn ? 'No students found.' : 'کوئی طالب علم موجود نہیں ہے۔'),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _studentsList.length,
                            itemBuilder: (context, index) {
                              final student = _studentsList[index];
                              final fatherPhone = student['fatherPhone']?.toString() ?? '-';

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        leading: CircleAvatar(
                                          backgroundColor: const Color(0xFFFEF3C7),
                                          child: Text(
                                            '${index + 1}',
                                            style: const TextStyle(
                                              color: Color(0xFFB45309),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        title: Text(
                                          student['name'] ?? 'Student',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        subtitle: Text(
                                          isEn ? 'Father: ${student['fatherName'] ?? '-'} | Phone: $fatherPhone' : 'والد: ${student['fatherName'] ?? '-'} | فون: $fatherPhone',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextFormField(
                                              controller: _studentPinCtrls[index],
                                              keyboardType: TextInputType.number,
                                              maxLength: 6,
                                              obscureText: _obscureStudentPinMap[index] ?? true,
                                              decoration: InputDecoration(
                                                labelText: isEn ? 'Father\'s PIN' : 'والد کا PIN',
                                                counterText: '',
                                                prefixIcon: const Icon(Icons.key, size: 18),
                                                filled: true,
                                                fillColor: Colors.grey.shade100,
                                                suffixIcon: IconButton(
                                                  icon: Icon(
                                                    _obscureStudentPinMap[index]!
                                                        ? Icons.visibility
                                                        : Icons.visibility_off,
                                                    size: 18,
                                                  ),
                                                  onPressed: () {
                                                    setState(() {
                                                      _obscureStudentPinMap[index] =
                                                          !_obscureStudentPinMap[index]!;
                                                    });
                                                  },
                                                ),
                                                border: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                              ),
                                              textInputAction: TextInputAction.done,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton.filledTonal(
                                            onPressed: () => _generateRandomStudentPin(index),
                                            icon: const Icon(Icons.refresh, size: 18),
                                            tooltip: isEn ? 'Generate New PIN' : 'نیا PIN بنائیں',
                                          ),
                                          const SizedBox(width: 6),
                                          IconButton.filled(
                                            style: IconButton.styleFrom(backgroundColor: const Color(0xFF074E32)),
                                            onPressed: () => _saveStudentParentPin(index),
                                            icon: const Icon(Icons.save, size: 18),
                                            tooltip: isEn ? 'Save' : 'محفوظ کریں',
                                          ),
                                          const SizedBox(width: 6),
                                          IconButton.filledTonal(
                                            color: Colors.green.shade800,
                                            onPressed: () {
                                              final sName = student['name'] ?? '';
                                              final fPhone = student['fatherPhone']?.toString() ?? '';
                                              final pin = _studentPinCtrls[index]!.text.trim();
                                              _sendWhatsAppParent(fPhone, sName, pin);
                                            },
                                            icon: const Icon(Icons.chat_rounded, size: 18),
                                            tooltip: isEn ? 'Send via WhatsApp' : 'WhatsApp پر بھیجیں',
                                          ),
                                          IconButton.filledTonal(
                                            color: Colors.blue.shade800,
                                            onPressed: () {
                                              final sName = student['name'] ?? '';
                                              final fPhone = student['fatherPhone']?.toString() ?? '';
                                              final pin = _studentPinCtrls[index]!.text.trim();
                                              _sendSmsParent(fPhone, sName, pin);
                                            },
                                            icon: const Icon(Icons.message_rounded, size: 18),
                                            tooltip: isEn ? 'Send via SMS' : 'SMS کے ذریعے भीजें',
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ],
                ),
        ),
      ),
    );
  }
}
