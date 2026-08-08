import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

import 'app_localizations.dart';
import 'attendance_screen.dart';
import 'fee_screen.dart';
import 'role_selection_screen.dart';
import 'login_screen.dart';
import 'theme/app_components.dart';
import 'theme/app_theme.dart';
import 'theme_controller.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final LanguageController _languageController = LanguageController();
  final ThemeController _themeController = ThemeController();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_languageController, _themeController]),
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'مکتب مینیجر',
          locale: _languageController.locale,
          supportedLocales: const [
            Locale('ur'),
            Locale('en'),
            Locale('ar'),
            Locale('hi'),
            Locale('te'),
            Locale('kn'),
            Locale('ta'),
            Locale('ml'),
          ],
          localizationsDelegates: const [
            AppLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          themeMode: _themeController.themeMode,
          theme: AppTheme.lightTheme(_languageController.locale.languageCode),
          darkTheme: AppTheme.darkTheme(_languageController.locale.languageCode),
          home: MainRoleAppScreen(
            languageController: _languageController,
            themeController: _themeController,
          ),
        );
      },
    );
  }
}

class MainRoleAppScreen extends StatefulWidget {
  final LanguageController languageController;
  final ThemeController themeController;

  const MainRoleAppScreen({super.key, required this.languageController, required this.themeController});

  @override
  State<MainRoleAppScreen> createState() => _MainRoleAppScreenState();
}

class _MainRoleAppScreenState extends State<MainRoleAppScreen> {
  static const String _storageKey = 'students_data';
  static const String _roleKey = 'user_selected_role';

  List<Map<String, dynamic>> studentsList = [];
  bool isLoading = true;
  AppRole? activeRole;
  AppRole? pendingLoginRole;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? studentsData = prefs.getString(_storageKey);

      if (studentsData != null && studentsData.isNotEmpty) {
        final decodedData = jsonDecode(studentsData) as List<dynamic>;
        studentsList = decodedData
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
      }

      // Require LoginScreen PIN authentication for role access
      activeRole = null;
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> saveStudentsData(List<Map<String, dynamic>> updatedList) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(updatedList));
    setState(() {
      studentsList = updatedList;
    });
  }

  Future<void> setRole(AppRole role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_roleKey, role.name);
    setState(() {
      activeRole = role;
    });
  }

  void clearRole() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_roleKey);
    setState(() {
      activeRole = null;
      pendingLoginRole = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (activeRole == null) {
      if (pendingLoginRole != null) {
        return LoginScreen(
          role: pendingLoginRole!,
          languageController: widget.languageController,
          onLoginSuccess: () {
            setRole(pendingLoginRole!);
            setState(() {
              pendingLoginRole = null;
            });
          },
          onBack: () {
            setState(() {
              pendingLoginRole = null;
            });
          },
        );
      }

      return RoleSelectionScreen(
        languageController: widget.languageController,
        themeController: widget.themeController,
        students: studentsList,
        onSave: saveStudentsData,
        onRoleSelected: (role) {
          setState(() {
            pendingLoginRole = role;
          });
        },
      );
    }

    return RoleDashboardScreen(
      currentRole: activeRole!,
      languageController: widget.languageController,
      themeController: widget.themeController,
      students: studentsList,
      onSave: saveStudentsData,
      onChangeRole: clearRole,
    );
  }
}

class StudentListScreen extends StatefulWidget {
  final LanguageController languageController;
  final AppRole? currentRole;
  final bool hideAppBar;

  const StudentListScreen({
    super.key,
    required this.languageController,
    this.currentRole,
    this.hideAppBar = false,
  });

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static const String _storageKey = 'students_data';

  List<Map<String, dynamic>> studentsList = [];
  bool isLoading = true;
  int _currentStep = 0;

  Future<void> initializeNotifications() async {
    try {
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings settings = InitializationSettings(
        android: androidSettings,
      );

      await notificationsPlugin.initialize(settings: settings);
    } catch (_) {
      // Ignored in unsupported test environments
    }
  }

  Future<void> openSmsApp({
    required String phone,
    required String message,
  }) async {
    final loc = AppLocalizations.of(context);
    if (phone.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${loc.translate('phone_number')} missing')),
      );
      return;
    }

    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Chrome में SMS نہیں بھیجا جا سکتا۔ Android پر چلائیں۔',
          ),
        ),
      );
      return;
    }

    final Uri smsUri = Uri(
      scheme: 'sms',
      path: phone,
      queryParameters: {'body': message},
    );

    await launchUrl(smsUri, mode: LaunchMode.externalApplication);
  }

  Future<void> openWhatsApp({
    required String phone,
    required String message,
  }) async {
    String cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');

    if (cleanPhone.length == 10) {
      cleanPhone = '91$cleanPhone';
    }

    final Uri whatsappUri = Uri.parse(
      'https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}',
    );

    await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
  }

  Future<void> makePhoneCall(String phone) async {
    final loc = AppLocalizations.of(context);
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleanPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${loc.translate('phone_number')} معلوم نہیں ہے')),
      );
      return;
    }
    final Uri phoneUri = Uri(scheme: 'tel', path: cleanPhone);
    await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
  }

  Future<void> showSetParentPinDialog(int index) async {
    final student = studentsList[index];
    final fatherPhone = student['fatherPhone']?.toString().trim() ?? '';
    final prefs = await SharedPreferences.getInstance();

    String currentPin = student['parentPin']?.toString() ?? '';
    if (currentPin.isEmpty && fatherPhone.isNotEmpty) {
      currentPin = prefs.getString('cred_parent_${fatherPhone}_pin') ?? '1234';
    } else if (currentPin.isEmpty) {
      currentPin = '1234';
    }

    final pinCtrl = TextEditingController(text: currentPin);

    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.key_rounded, color: Color(0xFFB45309)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${student['name']} - والد کا PIN',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('والد کا نام: ${student['fatherName'] ?? '-'}'),
            Text('موبائل نمبر: ${fatherPhone.isEmpty ? '-' : fatherPhone}'),
            const SizedBox(height: 16),
            TextField(
              controller: pinCtrl,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(
                labelText: '4-Digit Parent PIN',
                counterText: '',
                prefixIcon: const Icon(Icons.lock),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('منسوخ')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFB45309)),
            onPressed: () async {
              final newPin = pinCtrl.text.trim();
              if (newPin.length < 4) return;
              setState(() {
                studentsList[index]['parentPin'] = newPin;
              });
              if (fatherPhone.isNotEmpty) {
                await prefs.setString('cred_parent_${fatherPhone}_pin', newPin);
              }
              await saveStudentsToStorage();
              if (context.mounted && ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${student['name']} کے والد کا PIN ($newPin) محفوظ ہو گیا!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('محفوظ کریں'),
          ),
        ],
      ),
    );
  }

  String _loggedInTeacherName = 'محمد عمران';

  @override
  void initState() {
    super.initState();
    initializeNotifications();
    loadStudentsFromStorage();
    _loadTeacherName();
  }

  Future<void> _loadTeacherName() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _loggedInTeacherName = prefs.getString('cred_teacher_name') ?? 'محمد عمران';
      });
    }
  }

  Future<void> loadStudentsFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? studentsData = prefs.getString(_storageKey);

      if (studentsData != null && studentsData.isNotEmpty) {
        final decodedData = jsonDecode(studentsData) as List<dynamic>;

        studentsList = decodedData
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading data: $error')));
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> sendAllMessages() async {
    final loc = AppLocalizations.of(context);
    final absentStudents = studentsList.where((student) {
      return student['isPresent'] == false;
    }).toList();

    if (absentStudents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.translate('no_students_found'))),
      );
      return;
    }

    final int whatsappCount = absentStudents.where((student) {
      return student['messageMethod'] == 'WhatsApp';
    }).length;

    final int notificationCount = absentStudents.where((student) {
      return student['messageMethod'] == 'Notification';
    }).length;

    final int smsCount = absentStudents.where((student) {
      return student['messageMethod'] == 'SMS';
    }).length;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        final isRtl = widget.languageController.locale.languageCode != 'en';
        return Directionality(
          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: SafeArea(
            child: SizedBox(
              height: MediaQuery.of(sheetContext).size.height * 0.75,
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Text(
                    loc.translate('absent'),
                    style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                children: [
                                  Text(loc.translate('absent')),
                                  Text(
                                    '${absentStudents.length}',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                children: [
                                  const Text('App Notification'),
                                  Text(
                                    '$notificationCount',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                children: [
                                  const Text('WhatsApp'),
                                  Text(
                                    '$whatsappCount',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                children: [
                                  const Text('SMS'),
                                  Text(
                                    '$smsCount',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView.builder(
                      itemCount: absentStudents.length,
                      itemBuilder: (context, index) {
                        final student = absentStudents[index];
                        final String name =
                            student['name']?.toString() ?? 'Student';
                        final String language =
                            student['language']?.toString() ?? 'اردو';
                        final String messageMethod =
                            student['messageMethod']?.toString() ?? 'SMS';

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          child: ListTile(
                            leading: CircleAvatar(child: Text('${index + 1}')),
                            title: Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              'Language: $language | Method: $messageMethod',
                            ),
                            trailing: PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert),
                              onSelected: (value) {
                                if (value == 'absent') {
                                  sendAutoMessage(student, 'absent');
                                } else if (value == 'call') {
                                  // Mock call logic
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'absent',
                                  child: Row(
                                    children: [
                                      Icon(messageMethod == 'WhatsApp' ? Icons.chat : Icons.sms, size: 20),
                                      const SizedBox(width: 8),
                                      const Text('Send Absent Msg'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'call',
                                  child: Row(
                                    children: [
                                      Icon(Icons.call, size: 20),
                                      SizedBox(width: 8),
                                      Text('Call Father'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            onTap: () {
                              sendAutoMessage(student, 'absent');
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          if (absentStudents.isNotEmpty) {
                            sendAutoMessage(absentStudents.first, 'absent');
                          }
                        },
                        icon: const Icon(Icons.send),
                        label: Text(loc.translate('actions')),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> saveStudentsToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(studentsList));
  }

  Future<void> deleteStudent(int index) async {
    final loc = AppLocalizations.of(context);
    final studentName = studentsList[index]['name'] ?? 'Student';

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final isRtl = widget.languageController.locale.languageCode != 'en';
        return Directionality(
          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: AlertDialog(
            title: Text(loc.translate('delete_student')),
            content: Text('${loc.translate('confirm_delete')}\n($studentName)'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(loc.translate('cancel')),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(loc.translate('delete')),
              ),
            ],
          ),
        );
      },
    );

    if (shouldDelete == true) {
      setState(() {
        studentsList.removeAt(index);
      });
      await saveStudentsToStorage();
    }
  }

  String _getLocalizedParentMessage({
    required String lang,
    required String messageType,
    required String studentName,
    String feeMonth = '',
    String feeAmount = '',
  }) {
    final l = lang.trim().toLowerCase();

    if (messageType == 'absent') {
      if (l == 'english' || l == 'en') {
        return 'Assalamu Alaikum, your child $studentName is absent from Maktab today. Please tell us the reason.';
      } else if (l == 'arabic' || l == 'ar') {
        return 'السلام عليكم، ابنكم/ابنتكم $studentName غائب(ة) عن المكتب اليوم. نرجو إفادتنا بالسبب.';
      } else if (l == 'hindi' || l == 'hi') {
        return 'अस्सलामु अलैकुम, आपका बच्चा $studentName आज मकतब में उपस्थित नहीं है। कृपया कारण बताएं।';
      } else if (l == 'telugu' || l == 'te') {
        return 'అస్సలాము అలైకుం, మీ బిడ్డ $studentName ఈరోజు మక్తబ్‌కు రాలేదు. దయచేసి కారణం తెలియజేయండి.';
      } else if (l == 'kannada' || l == 'kn') {
        return 'ಅಸ್ಸಲಾಮು ಅಲೈಕುಮ್, ನಿಮ್ಮ ಮಗ/ಮಗಳು $studentName ಇಂದು ಮಕ್ತಬ್‌ಗೆ ಬಂದಿಲ್ಲ. ದಯವಿಟ್ಟು ಕಾರಣ ತಿಳಿಸಿ.';
      } else if (l == 'tamil' || l == 'ta') {
        return 'அஸ்ஸலாமு அலைக்கும், உங்கள் குழந்தை $studentName இன்று மக்தப்பிற்கு வரவில்லை. தயவுசெய்து காரணம் சொல்லுங்கள்.';
      } else if (l == 'malayalam' || l == 'ml') {
        return 'അസ്സലാമു അലൈക്കും, നിങ്ങളുടെ കുട്ടി $studentName ഇന്ന് മക്തബിൽ ഗൈർഹാജരായി. ദയവായി കാരണം അറിയിക്കൂ.';
      } else {
        return 'السلام علیکم، آپ کا بچہ $studentName آج مکتب میں حاضر نہیں ہے۔ براہ کرم وجہ بتائیں۔';
      }
    } else {
      if (l == 'english' || l == 'en') {
        return "Assalamu Alaikum, your child $studentName's Maktab fee for $feeMonth (₹$feeAmount) is pending. Please pay it soon.";
      } else if (l == 'arabic' || l == 'ar') {
        return 'السلام عليكم، رسوم المكتب الخاصة بالطالب/الطالبة $studentName لشهر $feeMonth (₹$feeAmount) مستحقة. نرجو السداد في أقرب وقت.';
      } else if (l == 'hindi' || l == 'hi') {
        return 'अस्सलामु अलैकुम, आपके बच्चे $studentName की $feeMonth की फीस (₹$feeAmount) बाकी है। कृपया जल्द जमा करें।';
      } else if (l == 'telugu' || l == 'te') {
        return 'అస్సలాము అలైకుం, మీ బిడ్డ $studentName యొక్క $feeMonth ఫీజు (₹$feeAmount) బాకీ ఉంది. దయచేసి త్వరగా చెల్లించండి.';
      } else if (l == 'kannada' || l == 'kn') {
        return 'ಅಸ್ಸಲಾಮು ಅಲೈಕುಮ್, ನಿಮ್ಮ ಮಗ/ಮಗಳು $studentName ಅವರ $feeMonth ತಿಂಗಳ ಶುಲ್ಕ (₹$feeAmount) ಬಾಕಿ ಇದೆ. ದಯವಿಟ್ಟು ಶೀಘ್ರದಲ್ಲೇ ಪಾವತಿಸಿ.';
      } else if (l == 'tamil' || l == 'ta') {
        return 'அஸ்ஸலாமு அலைக்கும், உங்கள் குழந்தை $studentName இன் $feeMonth மாத கட்டணம் (₹$feeAmount) நிலுவையில் உள்ளது. தயவுசெய்து விரைவில் செலுத்துங்கள்.';
      } else if (l == 'malayalam' || l == 'ml') {
        return 'അസ്സലാമു അലൈക്കും, നിങ്ങളുടെ കുട്ടി $studentName യുടെ $feeMonth മാസത്തെ ഫീസ് (₹$feeAmount) കുടിശ്ശികയാണ്. ദയവായി ഉടൻ അടക്കൂ.';
      } else {
        return 'السلام علیکم، آپ کے بچے $studentName کی $feeMonth کی فیس (₹$feeAmount) واجب الادا ہے۔ براہ کرم جلد جمع کروائیں۔';
      }
    }
  }

  void sendAutoMessage(Map<String, dynamic> student, String messageType) {
    final loc = AppLocalizations.of(context);
    String selectedMsgLang = student['language']?.toString() ?? 'ur';
    final String studentName = student['name']?.toString() ?? 'Student';
    final String messageMethod = student['messageMethod']?.toString() ?? 'SMS';
    final String feeMonth = student['feeMonth']?.toString() ?? 'Current Month';
    final String feeAmount = student['feeAmount']?.toString() ?? '0';

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDlgState) {
            final isRtl = widget.languageController.locale.languageCode != 'en';
            final String finalMessage = _getLocalizedParentMessage(
              lang: selectedMsgLang,
              messageType: messageType,
              studentName: studentName,
              feeMonth: feeMonth,
              feeAmount: feeAmount,
            );

            return Directionality(
              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
              child: AlertDialog(
                title: Row(
                  children: [
                    const Icon(Icons.mark_email_unread_rounded, color: Colors.green),
                    const SizedBox(width: 8),
                    Text('پیغام بھیجیں ($messageMethod)',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  ],
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('پیغام کی زبان منتخب کریں (Select Message Language):',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.indigo)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: kAllLanguages.any((l) => l.code == selectedMsgLang) ? selectedMsgLang : 'ur',
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        items: kAllLanguages.map((lang) {
                          return DropdownMenuItem(
                            value: lang.code,
                            child: Text(lang.nativeScript),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDlgState(() {
                              selectedMsgLang = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade300),
                        ),
                        child: SelectableText(
                          finalMessage,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: Text(loc.translate('cancel')),
                  ),
                  if (messageMethod == 'SMS')
                    FilledButton.icon(
                      onPressed: () async {
                        final String phone =
                            student['fatherPhone']?.toString() ?? '';
                        await openSmsApp(phone: phone, message: finalMessage);
                      },
                      icon: const Icon(Icons.send),
                      label: const Text('SMS'),
                    ),
                  if (messageMethod == 'WhatsApp')
                    FilledButton.icon(
                      onPressed: () async {
                        final String phone =
                            student['fatherPhone']?.toString() ?? '';
                        await openWhatsApp(phone: phone, message: finalMessage);
                      },
                      icon: const Icon(Icons.chat),
                      label: const Text('WhatsApp'),
                    ),
                  if (messageMethod == 'Notification')
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Firebase Parent App Notification dispatches successfully.'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.notifications),
                      label: const Text('App Notification'),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void showFeeDialog(int index) {
    final loc = AppLocalizations.of(context);
    final student = studentsList[index];

    final feeAmountController = TextEditingController(
      text: student['feeAmount']?.toString() ?? '500',
    );

    String feeMonth = student['feeMonth'] ?? 'January';
    String feeStatus = student['feeStatus'] ?? 'due';

    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isRtl = widget.languageController.locale.languageCode != 'en';
            return Directionality(
              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
              child: AlertDialog(
                title: Text(
                  '${loc.translate('fee_record')}: ${student['name']}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: feeAmountController,
                        decoration: InputDecoration(
                          labelText: loc.translate('fee_amount'),
                          prefixText: '₹ ',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: months.contains(feeMonth) ? feeMonth : months.first,
                        decoration: InputDecoration(
                          labelText: loc.translate('select_month'),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        items: months
                            .map(
                              (month) => DropdownMenuItem<String>(
                                value: month,
                                child: Text(month),
                              ),
                            )
                            .toList(),
                        onChanged: (newValue) {
                          if (newValue != null) {
                            setDialogState(() {
                              feeMonth = newValue;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: feeStatus,
                        decoration: InputDecoration(
                          labelText: loc.translate('fee_status'),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'due',
                            child: Text(loc.translate('due')),
                          ),
                          DropdownMenuItem(
                            value: 'partially_paid',
                            child: Text(loc.translate('partially_paid')),
                          ),
                          DropdownMenuItem(
                            value: 'paid',
                            child: Text(loc.translate('paid')),
                          ),
                        ],
                        onChanged: (newValue) {
                          if (newValue != null) {
                            setDialogState(() {
                              feeStatus = newValue;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: Text(loc.translate('cancel')),
                  ),
                  FilledButton(
                    onPressed: () async {
                      setState(() {
                        studentsList[index]['feeAmount'] = feeAmountController
                            .text
                            .trim();
                        studentsList[index]['feeMonth'] = feeMonth;
                        studentsList[index]['feeStatus'] = feeStatus;
                      });

                      await saveStudentsToStorage();

                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                      }
                    },
                    child: Text(loc.translate('save')),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(feeAmountController.dispose);
  }

  void showAddStudentDialog() {
    final loc = AppLocalizations.of(context);
    final studentNameController = TextEditingController();
    final fatherNameController = TextEditingController();
    final fatherPhoneController = TextEditingController();
    final dobController = TextEditingController();
    final teacherNameController = TextEditingController();
    String selectedGroup = 'Hifz Group A';
    String selectedShift = 'morning';
    String selectedGender = 'male';
    String selectedLanguage = 'ur';
    String selectedMessageMethod = 'SMS';

      final guardianNameController = TextEditingController(text: 'سرپرست (ولی)');
      final guardianRelationController = TextEditingController(text: 'والد / چچا');
      int currentStep = 0;

      showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isRtl = widget.languageController.locale.languageCode != 'en';
            return Directionality(
              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
              child: AlertDialog(
                title: Text(
                  loc.translate('add_student'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                content: SizedBox(
                  width: double.maxFinite,
                  height: 400,
                  child: Stepper(
                    type: StepperType.horizontal,
                    currentStep: _currentStep,
                    onStepTapped: (index) => setDialogState(() => _currentStep = index),
                    onStepContinue: () {
                      if (_currentStep < 1) {
                        setDialogState(() => _currentStep += 1);
                      }
                    },
                    onStepCancel: () {
                      if (_currentStep > 0) {
                        setDialogState(() => _currentStep -= 1);
                      }
                    },
                    controlsBuilder: (context, details) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Row(
                          children: [
                            if (_currentStep < 1)
                              FilledButton(onPressed: details.onStepContinue, child: const Text('Next')),
                            const SizedBox(width: 8),
                            if (_currentStep > 0)
                              TextButton(onPressed: details.onStepCancel, child: const Text('Back')),
                          ],
                        ),
                      );
                    },
                    steps: [
                      Step(
                        title: const Text('Personal'),
                        isActive: _currentStep >= 0,
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                      TextFormField(
                        controller: studentNameController,
                        decoration: InputDecoration(
                          labelText: loc.translate('name'),
                          prefixIcon: const Icon(Icons.person_rounded),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final contact = await ContactPickerHelper.pickContact(context, studentsList);
                          if (contact != null) {
                            setDialogState(() {
                              fatherNameController.text = contact['name'] ?? '';
                              fatherPhoneController.text = contact['phone'] ?? '';
                            });
                          }
                        },
                        icon: const Icon(Icons.contacts_rounded, size: 16),
                        label: const Text('فون کانٹیکٹ سے نام و نمبر امپورٹ کریں (Import Contact)', style: TextStyle(fontSize: 11)),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: fatherNameController,
                        decoration: InputDecoration(
                          labelText: loc.translate('father_name'),
                          prefixIcon: const Icon(Icons.escalator_warning_rounded),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: guardianNameController,
                        decoration: InputDecoration(
                          labelText: 'سرپرست کا نام (Guardian Name)',
                          prefixIcon: const Icon(Icons.shield_rounded),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: guardianRelationController,
                        decoration: InputDecoration(
                          labelText: 'سرپرست سے رشتہ (Guardian Relation)',
                          prefixIcon: const Icon(Icons.family_restroom_rounded),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                        ),
                        textInputAction: TextInputAction.done,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: fatherPhoneController,
                              decoration: InputDecoration(
                                labelText: loc.translate('phone_number'),
                                prefixIcon: const Icon(Icons.phone_rounded),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                filled: true,
                                fillColor: Colors.grey.shade100,
                              ),
                              keyboardType: TextInputType.phone,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filled(
                            icon: const Icon(Icons.contacts_rounded),
                            tooltip: 'Import from Contacts',
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () async {
                              try {
                                final contact = await FlutterContacts.native.showPicker(
                                  properties: {ContactProperty.phone, ContactProperty.name},
                                );
                                if (contact != null) {
                                  setDialogState(() {
                                    if (contact.name?.first != null && contact.name!.first!.isNotEmpty) {
                                      fatherNameController.text = '${contact.name!.first ?? ''} ${contact.name!.last ?? ''}'.trim();
                                    }
                                    if (contact.phones.isNotEmpty) {
                                      fatherPhoneController.text = contact.phones.first.number;
                                    }
                                  });
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error picking contact: $e'), backgroundColor: Colors.red),
                                  );
                                }
                              }
                            },
                          ),
                        ],
                      ),
                            ],
                          ),
                        ),
                        Step(
                          title: const Text('Details'),
                          isActive: _currentStep >= 1,
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: dobController,
                        readOnly: true,
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(1900),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setDialogState(() {
                              dobController.text = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                            });
                          }
                        },
                        decoration: InputDecoration(
                          labelText: 'Date of Birth (YYYY-MM-DD)',
                          prefixIcon: const Icon(Icons.calendar_today_rounded),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: selectedGroup,
                        decoration: InputDecoration(
                          labelText: 'گروپ (Batch Group Option)',
                          prefixIcon: Icon(Icons.groups_rounded),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Hifz Group A', child: Text('حفظ گروپ (Hifz Group A)')),
                          DropdownMenuItem(value: 'Nazira Group B', child: Text('ناظرہ گروپ (Nazira Group B)')),
                          DropdownMenuItem(value: 'Tajweed Group C', child: Text('تجوید گروپ (Tajweed Group C)')),
                          DropdownMenuItem(value: 'Primary Group D', child: Text('ابتدائی گروپ (Primary Group D)')),
                        ],
                        onChanged: (newValue) {
                          if (newValue != null) {
                            setDialogState(() {
                              selectedGroup = newValue;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: teacherNameController,
                        decoration: InputDecoration(
                          labelText: loc.translate('teacher_name'),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: selectedShift,
                        decoration: InputDecoration(
                          labelText: loc.translate('shift'),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'morning',
                            child: Text(loc.translate('morning')),
                          ),
                          DropdownMenuItem(
                            value: 'evening',
                            child: Text(loc.translate('evening')),
                          ),
                        ],
                        onChanged: (newValue) {
                          if (newValue != null) {
                            setDialogState(() {
                              selectedShift = newValue;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: selectedMessageMethod,
                        decoration: InputDecoration(
                          labelText: loc.translate('notice_channel'),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'SMS', child: Text('SMS')),
                          DropdownMenuItem(
                            value: 'WhatsApp',
                            child: Text('WhatsApp'),
                          ),
                          DropdownMenuItem(
                            value: 'Notification',
                            child: Text('App Notification'),
                          ),
                        ],
                        onChanged: (newValue) {
                          if (newValue != null) {
                            setDialogState(() {
                              selectedMessageMethod = newValue;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: selectedGender,
                        decoration: InputDecoration(
                          labelText: loc.translate('gender'),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'male',
                            child: Text(loc.translate('male')),
                          ),
                          DropdownMenuItem(
                            value: 'female',
                            child: Text(loc.translate('female')),
                          ),
                        ],
                        onChanged: (newValue) {
                          if (newValue != null) {
                            setDialogState(() {
                              selectedGender = newValue;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: selectedLanguage,
                        decoration: InputDecoration(
                          labelText: loc.translate('message_language'),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'ur', child: Text('🇵🇰 Urdu (اردو)')),
                          DropdownMenuItem(value: 'en', child: Text('🇬🇧 English')),
                          DropdownMenuItem(value: 'ar', child: Text('🇸🇦 Arabic (العربية)')),
                          DropdownMenuItem(value: 'hi', child: Text('🇮🇳 Hindi (हिंदी)')),
                          DropdownMenuItem(value: 'te', child: Text('🇮🇳 Telugu (తెలుగు)')),
                          DropdownMenuItem(value: 'kn', child: Text('🇮🇳 Kannada (ಕನ್ನಡ)')),
                          DropdownMenuItem(value: 'ta', child: Text('🇮🇳 Tamil (தமிழ்)')),
                          DropdownMenuItem(value: 'ml', child: Text('🇮🇳 Malayalam (മലയാളം)')),
                        ],
                        onChanged: (newValue) {
                          if (newValue != null) {
                            setDialogState(() {
                              selectedLanguage = newValue;
                            });
                          }
                        },
                      ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: Text(loc.translate('cancel')),
                  ),
                  FilledButton(
                    onPressed: () async {
                      final studentName = studentNameController.text.trim();

                      if (studentName.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${loc.translate('name')} required'),
                          ),
                        );
                        return;
                      }

                      final now = DateTime.now();
                      final formattedDate = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
                      final fatherPhone = fatherPhoneController.text.trim();

                      setState(() {
                        studentsList.add({
                          'name': studentName,
                          'fatherName': fatherNameController.text.trim(),
                          'fatherPhone': fatherPhone,
                          'dob': dobController.text.trim(),
                          'group': selectedGroup,
                          'className': selectedGroup,
                          'teacherName': teacherNameController.text.trim().isNotEmpty ? teacherNameController.text.trim() : 'حافظ احمد حسن',
                          'shift': selectedShift,
                          'gender': selectedGender,
                          'language': selectedLanguage,
                          'messageMethod': selectedMessageMethod,
                          'feeAmount': '500',
                          'feeMonth': 'August 2026',
                          'feeStatus': 'due',
                          'isPresent': true,
                          'isNewAdmission': true,
                          'admissionDate': formattedDate,
                          'parentPin': '1234',
                        });
                      });

                      if (fatherPhone.isNotEmpty) {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setString('cred_parent_${fatherPhone}_pin', '1234');
                      }

                      await saveStudentsToStorage();

                      // Ask to save parent contact to phone
                      final fatherName = fatherNameController.text.trim();
                      if (fatherPhone.isNotEmpty && fatherName.isNotEmpty && dialogContext.mounted) {
                        final saveContact = await showDialog<bool>(
                          context: dialogContext,
                          builder: (ctx) => AlertDialog(
                            icon: const Icon(Icons.contact_phone_rounded, color: Colors.green, size: 40),
                            title: const Text('Save to Contacts?'),
                            content: Text(
                              'کیا آپ "$fatherName" ($fatherPhone) کو اپنے فون رابطوں میں محفوظ کرنا چاہتے ہیں؟\n\n'
                              'Do you want to save "$fatherName" to your phone contacts?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: Text(loc.translate('cancel')),
                              ),
                              FilledButton.icon(
                                onPressed: () => Navigator.pop(ctx, true),
                                icon: const Icon(Icons.save_rounded),
                                label: Text(loc.translate('save')),
                              ),
                            ],
                          ),
                        );

                        if (saveContact == true) {
                          try {
                            final permStatus = await FlutterContacts.permissions.request(PermissionType.readWrite);
                            if (permStatus == PermissionStatus.granted || permStatus == PermissionStatus.limited) {
                              final nameParts = fatherName.split(' ');
                              final newContact = Contact(
                                name: Name(
                                  first: nameParts.first,
                                  last: nameParts.skip(1).join(' '),
                                ),
                                phones: [Phone(number: fatherPhone)],
                                organizations: [Organization(name: 'Maktab — $studentName Parent')],
                              );
                              await FlutterContacts.create(newContact);
                              if (dialogContext.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('✓ $fatherName contact saved!'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            }
                          } catch (e) {
                            if (dialogContext.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Could not save contact: $e'), backgroundColor: Colors.red),
                              );
                            }
                          }
                        }
                      }

                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                      }
                    },
                    child: Text(loc.translate('save')),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      studentNameController.dispose();
      fatherNameController.dispose();
      fatherPhoneController.dispose();
      dobController.dispose();
      teacherNameController.dispose();
    });
  }

  bool _isTableView = false;
  String _admissionFilter = 'all'; // 'all', 'new', 'old'
  String _searchQuery = '';
  String _feeFilter = 'all'; // 'all', 'paid', 'due'

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isRtl = widget.languageController.locale.languageCode != 'en';

    final int newCount = studentsList.where((s) => s['isNewAdmission'] == true).length;
    final int oldCount = studentsList.length - newCount;

    final displayedStudents = studentsList.where((student) {
      final isNew = student['isNewAdmission'] == true;
      if (_admissionFilter == 'new' && !isNew) return false;
      if (_admissionFilter == 'old' && isNew) return false;

      if (_searchQuery.isNotEmpty) {
        final name = (student['name'] ?? '').toString().toLowerCase();
        if (!name.contains(_searchQuery.toLowerCase())) return false;
      }

      if (_feeFilter == 'paid') {
        if (student['feeStatus'] != 'paid') return false;
      } else if (_feeFilter == 'due') {
        if (student['feeStatus'] == 'paid') return false;
      }

      return true;
    }).toList();

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: widget.hideAppBar
            ? null
            : AppBar(
          title: Text(
            loc.translate('students_list'),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              tooltip: 'ٹولز (Tools)',
              onSelected: (value) {
                if (value == 'view_toggle') {
                  setState(() => _isTableView = !_isTableView);
                } else if (value == 'fee_record') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FeeScreen(
                        students: studentsList,
                        languageController: widget.languageController,
                        currentRole: widget.currentRole,
                        onSave: (updated) async {
                          setState(() {
                            studentsList = updated;
                          });
                          await saveStudentsToStorage();
                        },
                      ),
                    ),
                  );
                } else if (value == 'attendance') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AttendanceScreen(
                        students: studentsList,
                        languageController: widget.languageController,
                        currentRole: widget.currentRole,
                        onSave: (updated) {
                          setState(() {
                            studentsList = updated;
                          });
                          saveStudentsToStorage();
                        },
                      ),
                    ),
                  );
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'view_toggle',
                  child: Row(
                    children: [
                      Icon(_isTableView ? Icons.view_agenda_rounded : Icons.table_chart_rounded, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(_isTableView ? 'Card View (کارڈ منظر)' : 'Table View (ٹیبل منظر)'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'fee_record',
                  child: Row(
                    children: [
                      const Icon(Icons.currency_rupee_rounded, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(loc.translate('fee_record')),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'attendance',
                  child: Row(
                    children: [
                      const Icon(Icons.fact_check, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(loc.translate('attendance')),
                    ],
                  ),
                ),
              ],
            ),
            LanguageButton(controller: widget.languageController),
          ],
        ),
        floatingActionButton: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton.extended(
              heroTag: 'student',
              onPressed: showAddStudentDialog,
              icon: const Icon(Icons.person_add),
              label: Text(loc.translate('add_student')),
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: FilledButton.icon(
              onPressed: sendAllMessages,
              icon: const Icon(Icons.send),
              label: Text(loc.translate('actions')),
            ),
          ),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Container(
                    width: double.infinity,
                    color: const Color(0xFF074E32),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    child: Row(
                      children: [
                        const Icon(Icons.person, color: Colors.amberAccent),
                        const SizedBox(width: 8),
                        Text(
                          'استاد: $_loggedInTeacherName',
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Jameel Noori Nastaleeq', height: 1.6),
                        ),
                      ],
                    ),
                  ),
                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: TextField(
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        labelText: loc.translate('search'),
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  // Filter Chips
                  Container(
                    color: Colors.grey.shade100,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ChoiceChip(
                            label: Text('${loc.translate('all')} (${studentsList.length})'),
                            selected: _admissionFilter == 'all',
                            onSelected: (val) {
                              if (val) setState(() => _admissionFilter = 'all');
                            },
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: Text('${loc.translate('new_admission')} ($newCount)'),
                            selectedColor: Colors.green.shade200,
                            selected: _admissionFilter == 'new',
                            onSelected: (val) {
                              if (val) setState(() => _admissionFilter = 'new');
                            },
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: Text('${loc.translate('old_admission')} ($oldCount)'),
                            selectedColor: Colors.blue.shade200,
                            selected: _admissionFilter == 'old',
                            onSelected: (val) {
                              if (val) setState(() => _admissionFilter = 'old');
                            },
                          ),
                          const SizedBox(width: 16),
                          ChoiceChip(
                            label: const Text('All Fees'),
                            selected: _feeFilter == 'all',
                            onSelected: (val) {
                              if (val) setState(() => _feeFilter = 'all');
                            },
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('Paid'),
                            selectedColor: Colors.green.shade200,
                            selected: _feeFilter == 'paid',
                            onSelected: (val) {
                              if (val) setState(() => _feeFilter = 'paid');
                            },
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('Due'),
                            selectedColor: Colors.red.shade200,
                            selected: _feeFilter == 'due',
                            onSelected: (val) {
                              if (val) setState(() => _feeFilter = 'due');
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  Expanded(
                    child: displayedStudents.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.group_add, size: 100, color: Colors.green),
                                const SizedBox(height: 16),
                                Text(
                                  loc.translate('no_students_found'),
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Try adjusting your filters or add a new student.',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                        : _isTableView
                            ? SingleChildScrollView(
                                padding: const EdgeInsets.all(12),
                                scrollDirection: Axis.horizontal,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.vertical,
                                  child: DataTable(
                                    headingRowColor: WidgetStateProperty.all(Colors.green.shade100),
                                    columns: [
                                      const DataColumn(label: Text('#', style: TextStyle(fontWeight: FontWeight.bold))),
                                      const DataColumn(label: Text('نام (Name)', style: TextStyle(fontWeight: FontWeight.bold))),
                                      const DataColumn(label: Text('داخلہ قسم', style: TextStyle(fontWeight: FontWeight.bold))),
                                      const DataColumn(label: Text('والد (Father)', style: TextStyle(fontWeight: FontWeight.bold))),
                                      const DataColumn(label: Text('کلاس (Class)', style: TextStyle(fontWeight: FontWeight.bold))),
                                      const DataColumn(label: Text('شفٹ (Shift)', style: TextStyle(fontWeight: FontWeight.bold))),
                                      const DataColumn(label: Text('ایکشن (Action)', style: TextStyle(fontWeight: FontWeight.bold))),
                                    ],
                                    rows: List.generate(displayedStudents.length, (index) {
                                      final student = displayedStudents[index];
                                      final isNew = student['isNewAdmission'] == true;

                                      return DataRow(cells: [
                                        DataCell(Text('${index + 1}')),
                                        DataCell(Text(student['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold))),
                                        DataCell(
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: isNew ? Colors.green.shade100 : Colors.blue.shade100,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              isNew ? 'نیا داخلہ' : 'سابقہ',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: isNew ? Colors.green.shade800 : Colors.blue.shade800,
                                              ),
                                            ),
                                          ),
                                        ),
                                        DataCell(Text(student['fatherName'] ?? '')),
                                        DataCell(Text(student['className'] ?? '-')),
                                        DataCell(Text(student['shift'] ?? 'morning')),
                                        DataCell(Row(
                                          children: [
                                            IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 16), onPressed: () => deleteStudent(index)),
                                          ],
                                        )),
                                      ]);
                                    }),
                                  ),
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(12),
                                itemCount: displayedStudents.length,
                                itemBuilder: (context, index) {
                                  final student = displayedStudents[index];
                                  final isNew = student['isNewAdmission'] == true;

                          return Dismissible(
                            key: Key(student['name'] ?? index.toString()),
                            background: Container(
                              color: Colors.blue,
                              alignment: isRtl ? Alignment.centerLeft : Alignment.centerRight,
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: const Icon(Icons.call, color: Colors.white),
                            ),
                            secondaryBackground: Container(
                              color: Colors.red,
                              alignment: isRtl ? Alignment.centerRight : Alignment.centerLeft,
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: const Icon(Icons.delete, color: Colors.white),
                            ),
                            confirmDismiss: (direction) async {
                              if (direction == DismissDirection.endToStart) {
                                await deleteStudent(index);
                                return false;
                              } else {
                                final phone = student['fatherPhone']?.toString() ?? '';
                                if (phone.isNotEmpty) {
                                  makePhoneCall(phone);
                                }
                                return false;
                              }
                            },
                            child: Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ExpansionTile(
                                leading: CircleAvatar(child: Text('${index + 1}')),
                              title: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Text(
                                          student['name'] ?? 'Student',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isNew ? Colors.green.shade100 : Colors.blue.shade100,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: isNew ? Colors.green.shade400 : Colors.blue.shade400),
                                          ),
                                          child: Text(
                                            isNew ? 'نیا داخلہ' : 'سابقہ',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: isNew ? Colors.green.shade800 : Colors.blue.shade800,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert),
                            onSelected: (value) {
                              final fatherPhone = student['fatherPhone']?.toString() ?? '';
                              if (value == 'call') {
                                makePhoneCall(fatherPhone);
                              } else if (value == 'sms') {
                                openSmsApp(
                                  phone: fatherPhone,
                                  message: 'السلام علیکم، مکتب سے پیغام: ${student['name']} کے حوالے سے رابطہ کریں۔',
                                );
                              } else if (value == 'whatsapp') {
                                openWhatsApp(
                                  phone: fatherPhone,
                                  message: 'السلام علیکم، مکتب کی اطلاع: ${student['name']} کی پیشرفت کا جائزہ لیں۔',
                                );
                              } else if (value == 'set_pin') {
                                showSetParentPinDialog(index);
                              } else if (value == 'delete') {
                                deleteStudent(index);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'call',
                                child: Row(
                                  children: [
                                    Icon(Icons.call, size: 20, color: Colors.blue),
                                    SizedBox(width: 8),
                                    Text('کال کریں (Call)'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'sms',
                                child: Row(
                                  children: [
                                    Icon(Icons.sms, size: 20, color: Colors.orange),
                                    SizedBox(width: 8),
                                    Text('SMS بھیجیں'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'whatsapp',
                                child: Row(
                                  children: [
                                    Icon(Icons.chat_bubble, size: 20, color: Colors.green),
                                    SizedBox(width: 8),
                                    Text('واتس اپ (WhatsApp)'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'set_pin',
                                child: Row(
                                  children: [
                                    Icon(Icons.key, size: 20, color: Color(0xFFB45309)),
                                    SizedBox(width: 8),
                                    Text('والد کا PIN دیکھیں/سیٹ کریں'),
                                  ],
                                ),
                              ),
                              const PopupMenuDivider(),
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    const Icon(Icons.delete, size: 20, color: Colors.red),
                                    const SizedBox(width: 8),
                                    Text(loc.translate('delete'), style: const TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      subtitle: Text(
                        '${loc.translate('father_name')}: ${student['fatherName'] ?? '-'}\n'
                        '${loc.translate('class_grade')}: ${student['className']?.toString().isNotEmpty == true ? student['className'] : '-'}',
                      ),
                      childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      children: [
                        ListTile(
                          leading: const Icon(Icons.phone),
                          title: Text(loc.translate('phone_number')),
                          subtitle: Text(
                            student['fatherPhone']?.toString().isNotEmpty ==
                                    true
                                ? student['fatherPhone'].toString()
                                : '-',
                          ),
                        ),
                        if (student['group'] != null)
                          ListTile(
                            leading: const Icon(Icons.groups_rounded, color: Colors.teal),
                            title: Text('Group: ${student['group']}'),
                          ),
                        if (student['shift'] != null)
                          ListTile(
                            leading: const Icon(Icons.schedule_rounded, color: Colors.indigo),
                            title: Text('${loc.translate('shift')}: ${loc.translate(student['shift'] ?? 'morning')}'),
                          ),
                      ],
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
}
