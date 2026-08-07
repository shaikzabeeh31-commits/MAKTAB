import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'app_localizations.dart';
import 'attendance_screen.dart';
import 'fee_screen.dart';
import 'role_selection_screen.dart';
import 'theme/app_components.dart';
import 'theme/app_theme.dart';

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

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _languageController,
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
          theme: AppTheme.lightTheme(),
          darkTheme: AppTheme.darkTheme(),
          home: MainRoleAppScreen(languageController: _languageController),
        );
      },
    );
  }
}

class MainRoleAppScreen extends StatefulWidget {
  final LanguageController languageController;

  const MainRoleAppScreen({super.key, required this.languageController});

  @override
  State<MainRoleAppScreen> createState() => _MainRoleAppScreenState();
}

class _MainRoleAppScreenState extends State<MainRoleAppScreen> {
  static const String _storageKey = 'students_data';
  static const String _roleKey = 'user_selected_role';

  List<Map<String, dynamic>> studentsList = [];
  bool isLoading = true;
  AppRole? activeRole;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? studentsData = prefs.getString(_storageKey);
      final String? savedRole = prefs.getString(_roleKey);

      if (studentsData != null && studentsData.isNotEmpty) {
        final decodedData = jsonDecode(studentsData) as List<dynamic>;
        studentsList = decodedData
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
      }

      if (savedRole != null) {
        final match = AppRole.values.firstWhere(
          (r) => r.name == savedRole,
          orElse: () => AppRole.manager,
        );
        activeRole = match;
      }
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
      return RoleSelectionScreen(
        languageController: widget.languageController,
        students: studentsList,
        onSave: saveStudentsData,
        onRoleSelected: (role) => setRole(role),
      );
    }

    return RoleDashboardScreen(
      currentRole: activeRole!,
      languageController: widget.languageController,
      students: studentsList,
      onSave: saveStudentsData,
      onChangeRole: clearRole,
    );
  }
}

class StudentListScreen extends StatefulWidget {
  final LanguageController languageController;

  const StudentListScreen({super.key, required this.languageController});

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static const String _storageKey = 'students_data';

  List<Map<String, dynamic>> studentsList = [];
  bool isLoading = true;

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

  @override
  void initState() {
    super.initState();
    initializeNotifications();
    loadStudentsFromStorage();
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
                            trailing: Icon(
                              messageMethod == 'WhatsApp'
                                  ? Icons.chat
                                  : Icons.sms,
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
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
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
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: months.contains(feeMonth) ? feeMonth : months.first,
                        decoration: InputDecoration(
                          labelText: loc.translate('select_month'),
                          border: const OutlineInputBorder(),
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
                          border: const OutlineInputBorder(),
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
    final classNameController = TextEditingController();
    final teacherNameController = TextEditingController();
    String selectedShift = 'morning';
    String selectedGender = 'male';
    String selectedLanguage = 'ur';
    String selectedMessageMethod = 'SMS';

      final guardianNameController = TextEditingController(text: 'سرپرست (ولی)');
      final guardianRelationController = TextEditingController(text: 'والد / چچا');

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
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: studentNameController,
                        decoration: InputDecoration(
                          labelText: loc.translate('name'),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final contact = await ContactPickerHelper.pickContact(context);
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
                      TextField(
                        controller: fatherNameController,
                        decoration: InputDecoration(
                          labelText: loc.translate('father_name'),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: guardianNameController,
                        decoration: const InputDecoration(
                          labelText: 'سرپرست کا نام (Guardian Name)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: guardianRelationController,
                        decoration: const InputDecoration(
                          labelText: 'سرپرست سے رشتہ (Guardian Relation)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: fatherPhoneController,
                        decoration: InputDecoration(
                          labelText: loc.translate('phone_number'),
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: dobController,
                        decoration: const InputDecoration(
                          labelText: 'Date of Birth (YYYY-MM-DD)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.datetime,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: classNameController,
                        decoration: InputDecoration(
                          labelText: loc.translate('class_grade'),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: teacherNameController,
                        decoration: InputDecoration(
                          labelText: loc.translate('teacher_name'),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: selectedShift,
                        decoration: InputDecoration(
                          labelText: loc.translate('shift'),
                          border: const OutlineInputBorder(),
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
                          border: const OutlineInputBorder(),
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
                          border: const OutlineInputBorder(),
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
                          border: const OutlineInputBorder(),
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

                      setState(() {
                        studentsList.add({
                          'name': studentName,
                          'fatherName': fatherNameController.text.trim(),
                          'fatherPhone': fatherPhoneController.text.trim(),
                          'dob': dobController.text.trim(),
                          'className': classNameController.text.trim(),
                          'teacherName': teacherNameController.text.trim(),
                          'shift': selectedShift,
                          'gender': selectedGender,
                          'language': selectedLanguage,
                          'messageMethod': selectedMessageMethod,
                          'feeAmount': '500',
                          'feeMonth': 'January',
                          'feeStatus': 'due',
                          'isPresent': true,
                        });
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
    ).whenComplete(() {
      studentNameController.dispose();
      fatherNameController.dispose();
      fatherPhoneController.dispose();
      dobController.dispose();
      classNameController.dispose();
      teacherNameController.dispose();
    });
  }

  bool _isTableView = false;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isRtl = widget.languageController.locale.languageCode != 'en';

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            loc.translate('students_list'),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: Icon(_isTableView ? Icons.view_agenda_rounded : Icons.table_chart_rounded),
              tooltip: _isTableView ? 'Card View' : 'Table View (ڈیٹا ٹیبل)',
              onPressed: () => setState(() => _isTableView = !_isTableView),
            ),
            IconButton(
              icon: const Icon(Icons.currency_rupee_rounded),
              tooltip: loc.translate('fee_record'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FeeScreen(
                      students: studentsList,
                      languageController: widget.languageController,
                      onSave: (updated) async {
                        setState(() {
                          studentsList = updated;
                        });
                        await saveStudentsToStorage();
                      },
                    ),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.fact_check),
              tooltip: loc.translate('attendance'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AttendanceScreen(
                      students: studentsList,
                      languageController: widget.languageController,
                      onSave: (updated) {
                        setState(() {
                          studentsList = updated;
                        });
                        saveStudentsToStorage();
                      },
                    ),
                  ),
                );
              },
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
            : studentsList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.school_outlined, size: 72),
                        const SizedBox(height: 12),
                        Text(
                          loc.translate('no_students_found'),
                          style: const TextStyle(fontSize: 18),
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
                            columns: const [
                              DataColumn(label: Text('#', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('نام (Name)', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('والد (Father)', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('کلاس (Class)', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('شفٹ (Shift)', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('فیس (Fee)', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('حاضری (Attendance)', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('ایکشن (Action)', style: TextStyle(fontWeight: FontWeight.bold))),
                            ],
                            rows: List.generate(studentsList.length, (index) {
                              final student = studentsList[index];
                              final isPresent = student['isPresent'] as bool? ?? true;
                              final feeStatus = student['feeStatus'] ?? 'due';

                              return DataRow(cells: [
                                DataCell(Text('${index + 1}')),
                                DataCell(Text(student['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold))),
                                DataCell(Text(student['fatherName'] ?? '')),
                                DataCell(Text(student['className'] ?? '-')),
                                DataCell(Text(student['shift'] ?? 'morning')),
                                DataCell(Text(feeStatus.toUpperCase(), style: TextStyle(color: feeStatus == 'paid' ? Colors.green : Colors.red, fontWeight: FontWeight.bold))),
                                DataCell(Text(isPresent ? 'حاضر (Present)' : 'غائب (Absent)', style: TextStyle(color: isPresent ? Colors.green : Colors.red))),
                                DataCell(Row(
                                  children: [
                                    IconButton(icon: const Icon(Icons.currency_rupee_rounded, size: 16), onPressed: () => showFeeDialog(index)),
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
                        itemCount: studentsList.length,
                        itemBuilder: (context, index) {
                          final student = studentsList[index];
                          final bool isPresent = student['isPresent'] as bool? ?? true;
                          final String feeStatus = student['feeStatus'] ?? 'due';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ExpansionTile(
                      leading: CircleAvatar(child: Text('${index + 1}')),
                      title: Text(
                        student['name'] ?? 'Student',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${loc.translate('father_name')}: ${student['fatherName'] ?? '-'}\n'
                        '${loc.translate('class_grade')}: ${student['className']?.toString().isNotEmpty == true ? student['className'] : '-'}\n'
                        '${loc.translate('teacher_name')}: ${student['teacherName'] ?? '-'}',
                      ),
                      childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      children: [
                        SwitchListTile(
                          title: Text(
                            isPresent
                                ? loc.translate('present')
                                : loc.translate('absent'),
                          ),
                          secondary: Icon(
                            isPresent ? Icons.check_circle : Icons.cancel,
                            color: isPresent ? Colors.green : Colors.red,
                          ),
                          value: isPresent,
                          onChanged: (value) async {
                            setState(() {
                              studentsList[index]['isPresent'] = value;
                            });
                            await saveStudentsToStorage();
                          },
                        ),
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
                        ListTile(
                          leading: Icon(
                            feeStatus == 'paid'
                                ? Icons.verified
                                : Icons.payments_outlined,
                            color: feeStatus == 'paid'
                                ? Colors.green
                                : Colors.orange,
                          ),
                          title: Text(
                            '${loc.translate('fee_amount')}: ₹${student['feeAmount'] ?? '0'}',
                          ),
                          subtitle: Text(
                            '${student['feeMonth'] ?? '-'} — ${loc.translate(feeStatus)}',
                          ),
                          trailing: IconButton(
                            onPressed: () => showFeeDialog(index),
                            icon: const Icon(Icons.edit),
                          ),
                        ),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () =>
                                  sendAutoMessage(student, 'absent'),
                              icon: const Icon(Icons.person_off),
                              label: Text(loc.translate('absent')),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => sendAutoMessage(student, 'fee'),
                              icon: const Icon(Icons.message),
                              label: Text(loc.translate('fee_record')),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => showFeeDialog(index),
                              icon: const Icon(Icons.currency_rupee),
                              label: Text(loc.translate('fee_amount')),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => deleteStudent(index),
                              icon: const Icon(Icons.delete),
                              label: Text(loc.translate('delete')),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
