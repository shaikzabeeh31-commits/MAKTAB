import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'app_localizations.dart';
import 'attendance_screen.dart';
import 'fee_screen.dart';
import 'role_selection_screen.dart';
import 'login_screen.dart';

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

  Future<void> showLocalAppNotification({
    required String title,
    required String body,
  }) async {
    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'maktab_channel_id',
        'Maktab Notifications',
        channelDescription: 'Notifications for Maktab management app',
        importance: Importance.high,
        priority: Priority.high,
      );
      const NotificationDetails details = NotificationDetails(android: androidDetails);
      await notificationsPlugin.show(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: title,
        body: body,
        notificationDetails: details,
      );
    } catch (_) {}
  }

  Future<void> showNotificationsCenterDialog() async {
    final now = DateTime.now();
    final timeStr = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    final isEn = AppLocalizations.of(context).locale.languageCode == 'en';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        title: Row(
          children: [
            const Icon(Icons.notifications_active, color: Colors.amber),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isEn ? 'Notification Center' : 'اطلاعات و نوٹیفیکیشنز',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.check, color: Colors.white, size: 16)),
                title: Text(isEn ? 'Attendance Marked' : 'حاضری درج کی گئی', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('$timeStr - All student attendance records saved.'),
              ),
              const Divider(height: 1),
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.currency_rupee, color: Colors.white, size: 16)),
                title: Text(isEn ? 'Fee Notification' : 'فیس کی اطلاع', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('$timeStr - Defaulter notices prepared for parents.'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isEn ? 'Close' : 'بند کریں')),
        ],
      ),
    );
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
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${student['name']} کے والد کا PIN ($newPin) محفوظ ہو گیا!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('محفوظ کریں'),
          ),
        ],
      ),
    );
  }

  Future<void> showEditStudentClassAndBatchDialog(int index) async {
    final student = studentsList[index];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    String currentClass = student['className']?.toString() ?? student['group']?.toString() ?? 'Hifz Group A';
    String currentShift = student['shift']?.toString() ?? 'morning';
    final isEn = AppLocalizations.of(context).locale.languageCode == 'en';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            title: Row(
              children: [
                const Icon(Icons.edit_note_rounded, color: Colors.indigo),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isEn ? 'Edit Class & Morning Slot' : 'کلاس و شفٹ/بیچ میں تبدیلی',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${isEn ? "Student" : "طالب علم"}: ${student['name']}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: ['Hifz Group A', 'Nazira Group B', 'Tajweed Group C', 'Primary Group D', 'Class 1', 'Class 2', 'Class 3'].contains(currentClass)
                        ? currentClass
                        : 'Hifz Group A',
                    dropdownColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                    decoration: InputDecoration(
                      labelText: isEn ? 'Class / Group' : 'کلاس / گروپ',
                      prefixIcon: const Icon(Icons.groups_rounded, color: Colors.indigo),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: [
                      'Hifz Group A',
                      'Nazira Group B',
                      'Tajweed Group C',
                      'Primary Group D',
                      'Class 1',
                      'Class 2',
                      'Class 3',
                    ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          currentClass = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: ['morning', 'morning_slot_1', 'morning_slot_2', 'evening', 'night'].contains(currentShift)
                        ? currentShift
                        : 'morning',
                    dropdownColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                    decoration: InputDecoration(
                      labelText: isEn ? 'Shift / Morning Slot' : 'شفٹ / مارننگ سلاٹ',
                      prefixIcon: const Icon(Icons.access_time_filled_rounded, color: Colors.amber),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: [
                      DropdownMenuItem(value: 'morning', child: Text(isEn ? 'Morning Shift' : 'صبح کی شفٹ')),
                      DropdownMenuItem(value: 'morning_slot_1', child: Text(isEn ? 'Morning Slot 1 (7:00 - 9:00 AM)' : 'مارننگ سلاٹ 1 (7:00 تا 9:00 AM)')),
                      DropdownMenuItem(value: 'morning_slot_2', child: Text(isEn ? 'Morning Slot 2 (9:00 - 11:00 AM)' : 'مارننگ سلاٹ 2 (9:00 تا 11:00 AM)')),
                      DropdownMenuItem(value: 'evening', child: Text(isEn ? 'Evening Shift' : 'شام کی شفٹ')),
                      DropdownMenuItem(value: 'night', child: Text(isEn ? 'Night Shift' : 'رات کی شفٹ')),
                    ].toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          currentShift = val;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(isEn ? 'Cancel' : 'منسوخ'),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: Colors.indigo),
                icon: const Icon(Icons.check, size: 16),
                label: Text(isEn ? 'Save Changes' : 'محفوظ کریں'),
                onPressed: () async {
                  setState(() {
                    studentsList[index]['className'] = currentClass;
                    studentsList[index]['group'] = currentClass;
                    studentsList[index]['shift'] = currentShift;
                  });
                  await saveStudentsToStorage();
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isEn ? 'Class and Morning Slot updated successfully!' : 'کلاس اور مارننگ سلاٹ میں کامیابی سے تبدیلی کی گئی!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
              ),
            ],
          );
        },
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
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.9) {
        if (_displayCount < studentsList.length) {
          setState(() {
            _displayCount += 20;
          });
        }
      }
    });
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

  Future<void> showAddStudentDialog() async {
    final loc = AppLocalizations.of(context);
    final prefs = await SharedPreferences.getInstance();

    final studentNameController = TextEditingController(text: prefs.getString('draft_student_name') ?? '');
    final fatherNameController = TextEditingController(text: prefs.getString('draft_father_name') ?? '');
    final fatherPhoneController = TextEditingController(text: prefs.getString('draft_father_phone') ?? '');
    final dobController = TextEditingController(text: prefs.getString('draft_dob') ?? '');
    final teacherNameController = TextEditingController(text: prefs.getString('draft_teacher_name') ?? '');
    
    void saveDrafts() {
      prefs.setString('draft_student_name', studentNameController.text);
      prefs.setString('draft_father_name', fatherNameController.text);
      prefs.setString('draft_father_phone', fatherPhoneController.text);
      prefs.setString('draft_dob', dobController.text);
      prefs.setString('draft_teacher_name', teacherNameController.text);
    }

    studentNameController.addListener(saveDrafts);
    fatherNameController.addListener(saveDrafts);
    fatherPhoneController.addListener(saveDrafts);
    dobController.addListener(saveDrafts);
    teacherNameController.addListener(saveDrafts);

    void clearDrafts() {
      prefs.remove('draft_student_name');
      prefs.remove('draft_father_name');
      prefs.remove('draft_father_phone');
      prefs.remove('draft_dob');
      prefs.remove('draft_teacher_name');
    }

    String selectedGroup = 'Hifz Group A';
    String selectedShift = 'morning';
    String selectedGender = 'male';
    String selectedLanguage = 'ur';
    String selectedMessageMethod = 'SMS';

    final guardianNameController = TextEditingController(text: 'سرپرست (ولی)');
    final guardianRelationController = TextEditingController(text: 'والد / چچا');

    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isRtl = widget.languageController.locale.languageCode != 'en';
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final inputBgColor = isDark ? const Color(0xFF1C2541) : Colors.grey.shade100;
            final textColor = isDark ? Colors.white : Colors.black87;
            final fieldLabelColor = isDark ? Colors.tealAccent : const Color(0xFF074E32);

            return Directionality(
              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
              child: Dialog.fullscreen(
                backgroundColor: isDark ? const Color(0xFF0B1329) : Colors.white,
                child: Scaffold(
                  backgroundColor: isDark ? const Color(0xFF0B1329) : Colors.white,
                  appBar: AppBar(
                    backgroundColor: const Color(0xFF074E32),
                    foregroundColor: Colors.white,
                    title: const SizedBox.shrink(),
                    leading: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(dialogContext),
                    ),
                  ),
                  body: SafeArea(
                    child: Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // SECTION 1: Student Details
                                Card(
                                  elevation: 0,
                                  color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade50,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isRtl ? 'طالب علم کی معلومات' : 'Student Information',
                                          style: TextStyle(fontWeight: FontWeight.bold, color: fieldLabelColor),
                                        ),
                                        const SizedBox(height: 12),
                                        TextFormField(
                                          controller: studentNameController,
                                          style: TextStyle(color: textColor),
                                          decoration: InputDecoration(
                                            labelText: loc.translate('name'),
                                            labelStyle: TextStyle(color: fieldLabelColor),
                                            prefixIcon: Icon(Icons.person_rounded, color: fieldLabelColor),
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                            filled: true,
                                            fillColor: inputBgColor,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        TextFormField(
                                          controller: dobController,
                                          style: TextStyle(color: textColor),
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
                                            labelText: isRtl ? 'تاریخِ پیدائش' : 'Date of Birth (YYYY-MM-DD)',
                                            labelStyle: TextStyle(color: fieldLabelColor),
                                            prefixIcon: Icon(Icons.calendar_today_rounded, color: fieldLabelColor),
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                            filled: true,
                                            fillColor: inputBgColor,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        DropdownButtonFormField<String>(
                                          initialValue: selectedGender,
                                          dropdownColor: isDark ? const Color(0xFF0B1329) : Colors.white,
                                          style: TextStyle(color: textColor),
                                          decoration: InputDecoration(
                                            labelText: loc.translate('gender'),
                                            labelStyle: TextStyle(color: fieldLabelColor),
                                            prefixIcon: Icon(Icons.wc_rounded, color: fieldLabelColor),
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                            filled: true,
                                            fillColor: inputBgColor,
                                          ),
                                          items: [
                                            DropdownMenuItem(value: 'male', child: TranslatedText('male', style: TextStyle(color: textColor))),
                                            DropdownMenuItem(value: 'female', child: TranslatedText('female', style: TextStyle(color: textColor))),
                                          ],
                                          onChanged: (newValue) {
                                            if (newValue != null) {
                                              setDialogState(() => selectedGender = newValue);
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // SECTION 2: Guardian & Contacts
                                Card(
                                  elevation: 0,
                                  color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade50,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              isRtl ? 'سرپرست اور رابطہ' : 'Guardian & Contact Info',
                                              style: TextStyle(fontWeight: FontWeight.bold, color: fieldLabelColor),
                                            ),
                                            // Modern "Import from Contacts" button!
                                            TextButton.icon(
                                              onPressed: () async {
                                                try {
                                                  final perm = await FlutterContacts.permissions.request(PermissionType.readWrite);
                                                  if (perm == PermissionStatus.granted || perm == PermissionStatus.limited) {
                                                    final contact = await FlutterContacts.native.showPicker(
                                                      properties: {ContactProperty.phone, ContactProperty.name},
                                                    );
                                                    if (contact != null) {
                                                      setDialogState(() {
                                                        if (contact.name != null) {
                                                          fatherNameController.text = '${contact.name!.first ?? ''} ${contact.name!.last ?? ''}'.trim();
                                                        }
                                                        if (contact.phones.isNotEmpty) {
                                                          fatherPhoneController.text = contact.phones.first.number;
                                                        }
                                                      });
                                                    }
                                                  } else {
                                                    if (context.mounted) {
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        const SnackBar(content: Text('Phone contacts permission denied'), backgroundColor: Colors.red),
                                                      );
                                                    }
                                                  }
                                                } catch (e) {
                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(content: Text('Error loading phone contacts: $e'), backgroundColor: Colors.red),
                                                    );
                                                  }
                                                }
                                              },
                                              icon: const Icon(Icons.contacts_rounded, size: 16),
                                              label: Text(isRtl ? 'فون سے لائیں' : 'Import from Phone', style: const TextStyle(fontSize: 11)),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        TextFormField(
                                          controller: fatherNameController,
                                          style: TextStyle(color: textColor),
                                          decoration: InputDecoration(
                                            labelText: loc.translate('father_name'),
                                            labelStyle: TextStyle(color: fieldLabelColor),
                                            prefixIcon: Icon(Icons.escalator_warning_rounded, color: fieldLabelColor),
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                            filled: true,
                                            fillColor: inputBgColor,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        TextFormField(
                                          controller: fatherPhoneController,
                                          style: TextStyle(color: textColor),
                                          decoration: InputDecoration(
                                            labelText: loc.translate('phone_number'),
                                            labelStyle: TextStyle(color: fieldLabelColor),
                                            prefixIcon: Icon(Icons.phone_rounded, color: fieldLabelColor),
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                            filled: true,
                                            fillColor: inputBgColor,
                                          ),
                                          keyboardType: TextInputType.phone,
                                        ),
                                        const SizedBox(height: 12),
                                        TextFormField(
                                          controller: guardianNameController,
                                          style: TextStyle(color: textColor),
                                          decoration: InputDecoration(
                                            labelText: isRtl ? 'سرپرست کا نام' : 'Guardian Name',
                                            labelStyle: TextStyle(color: fieldLabelColor),
                                            prefixIcon: Icon(Icons.shield_rounded, color: fieldLabelColor),
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                            filled: true,
                                            fillColor: inputBgColor,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        TextFormField(
                                          controller: guardianRelationController,
                                          style: TextStyle(color: textColor),
                                          decoration: InputDecoration(
                                            labelText: isRtl ? 'سرپرست سے رشتہ' : 'Guardian Relation',
                                            labelStyle: TextStyle(color: fieldLabelColor),
                                            prefixIcon: Icon(Icons.family_restroom_rounded, color: fieldLabelColor),
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                            filled: true,
                                            fillColor: inputBgColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // SECTION 3: Maktab details
                                Card(
                                  elevation: 0,
                                  color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade50,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isRtl ? 'مکتب کی تفصیلات' : 'Maktab Details',
                                          style: TextStyle(fontWeight: FontWeight.bold, color: fieldLabelColor),
                                        ),
                                        const SizedBox(height: 12),
                                        DropdownButtonFormField<String>(
                                          initialValue: selectedGroup,
                                          dropdownColor: isDark ? const Color(0xFF0B1329) : Colors.white,
                                          style: TextStyle(color: textColor),
                                          decoration: InputDecoration(
                                            labelText: loc.translate('batch_group'),
                                            labelStyle: TextStyle(color: fieldLabelColor),
                                            prefixIcon: Icon(Icons.groups_rounded, color: fieldLabelColor),
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                            filled: true,
                                            fillColor: inputBgColor,
                                          ),
                                          items: [
                                            DropdownMenuItem(value: 'Hifz Group A', child: TranslatedText('Hifz Group A', style: TextStyle(color: textColor))),
                                            DropdownMenuItem(value: 'Nazira Group B', child: TranslatedText('Nazira Group B', style: TextStyle(color: textColor))),
                                            DropdownMenuItem(value: 'Tajweed Group C', child: TranslatedText('Tajweed Group C', style: TextStyle(color: textColor))),
                                            DropdownMenuItem(value: 'Primary Group D', child: TranslatedText('Primary Group D', style: TextStyle(color: textColor))),
                                          ],
                                          onChanged: (newValue) {
                                            if (newValue != null) {
                                              setDialogState(() => selectedGroup = newValue);
                                            }
                                          },
                                        ),
                                        const SizedBox(height: 12),
                                        TextFormField(
                                          controller: teacherNameController,
                                          style: TextStyle(color: textColor),
                                          decoration: InputDecoration(
                                            labelText: loc.translate('teacher_name'),
                                            labelStyle: TextStyle(color: fieldLabelColor),
                                            prefixIcon: Icon(Icons.school, color: fieldLabelColor),
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                            filled: true,
                                            fillColor: inputBgColor,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        DropdownButtonFormField<String>(
                                          initialValue: selectedShift,
                                          dropdownColor: isDark ? const Color(0xFF0B1329) : Colors.white,
                                          style: TextStyle(color: textColor),
                                          decoration: InputDecoration(
                                            labelText: loc.translate('shift'),
                                            labelStyle: TextStyle(color: fieldLabelColor),
                                            prefixIcon: Icon(Icons.access_time_rounded, color: fieldLabelColor),
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                            filled: true,
                                            fillColor: inputBgColor,
                                          ),
                                          items: [
                                            DropdownMenuItem(value: 'morning', child: TranslatedText('Morning Shift', style: TextStyle(color: textColor))),
                                            DropdownMenuItem(value: 'evening', child: TranslatedText('Evening Shift', style: TextStyle(color: textColor))),
                                          ],
                                          onChanged: (newValue) {
                                            if (newValue != null) {
                                              setDialogState(() => selectedShift = newValue);
                                            }
                                          },
                                        ),
                                        const SizedBox(height: 12),
                                        DropdownButtonFormField<String>(
                                          initialValue: selectedMessageMethod,
                                          dropdownColor: isDark ? const Color(0xFF0B1329) : Colors.white,
                                          style: TextStyle(color: textColor),
                                          decoration: InputDecoration(
                                            labelText: loc.translate('notice_channel'),
                                            labelStyle: TextStyle(color: fieldLabelColor),
                                            prefixIcon: Icon(Icons.message_rounded, color: fieldLabelColor),
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                            filled: true,
                                            fillColor: inputBgColor,
                                          ),
                                          items: [
                                            DropdownMenuItem(value: 'SMS', child: Text('SMS', style: TextStyle(color: textColor))),
                                            DropdownMenuItem(value: 'WhatsApp', child: Text('WhatsApp', style: TextStyle(color: textColor))),
                                            DropdownMenuItem(value: 'Notification', child: TranslatedText('App Notification', style: TextStyle(color: textColor))),
                                          ],
                                          onChanged: (newValue) {
                                            if (newValue != null) {
                                              setDialogState(() => selectedMessageMethod = newValue);
                                            }
                                          },
                                        ),
                                        const SizedBox(height: 12),
                                        DropdownButtonFormField<String>(
                                          initialValue: selectedLanguage,
                                          dropdownColor: isDark ? const Color(0xFF0B1329) : Colors.white,
                                          style: TextStyle(color: textColor),
                                          decoration: InputDecoration(
                                            labelText: loc.translate('message_language'),
                                            labelStyle: TextStyle(color: fieldLabelColor),
                                            prefixIcon: Icon(Icons.language_rounded, color: fieldLabelColor),
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                            filled: true,
                                            fillColor: inputBgColor,
                                          ),
                                          items: [
                                            DropdownMenuItem(value: 'ur', child: Text('🇵🇰 Urdu (اردو)', style: TextStyle(color: textColor))),
                                            DropdownMenuItem(value: 'en', child: Text('🇬🇧 English', style: TextStyle(color: textColor))),
                                            DropdownMenuItem(value: 'ar', child: Text('🇸🇦 Arabic (العربية)', style: TextStyle(color: textColor))),
                                            DropdownMenuItem(value: 'hi', child: Text('🇮🇳 Hindi (हिंदी)', style: TextStyle(color: textColor))),
                                            DropdownMenuItem(value: 'te', child: Text('🇮🇳 Telugu (తెలుగు)', style: TextStyle(color: textColor))),
                                            DropdownMenuItem(value: 'kn', child: Text('🇮🇳 Kannada (ಕನ್ನಡ)', style: TextStyle(color: textColor))),
                                            DropdownMenuItem(value: 'ta', child: Text('🇮🇳 Tamil (தமிழ்)', style: TextStyle(color: textColor))),
                                            DropdownMenuItem(value: 'ml', child: Text('🇮🇳 Malayalam (മലയാളം)', style: TextStyle(color: textColor))),
                                          ],
                                          onChanged: (newValue) {
                                            if (newValue != null) {
                                              setDialogState(() => selectedLanguage = newValue);
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Persisted Bottom actions
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0B1329) : Colors.white,
                            border: Border(top: BorderSide(color: isDark ? const Color(0xFF334155) : Colors.grey.shade200)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.pop(dialogContext),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: Text(loc.translate('cancel')),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFF074E32),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  icon: const Icon(Icons.save_rounded),
                                  label: Text(loc.translate('save')),
                                  onPressed: () async {
                                    final studentName = studentNameController.text.trim();

                                    if (studentName.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('${loc.translate('name')} required')),
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

                                    clearDrafts();
                                    await saveStudentsToStorage();

                                    if (dialogContext.mounted) {
                                      Navigator.pop(dialogContext);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('✓ $studentName added!'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
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
  String _selectedClassFilter = 'All';
  DateTimeRange? _selectedDateRange;
  DateTime _selectedDate = DateTime.now();
  String _searchQuery = '';
  bool _isSearching = false;
  String _feeFilter = 'all'; // 'all', 'paid', 'due'

  // Pagination & scrolling
  int _displayCount = 20;
  final ScrollController _scrollController = ScrollController();

  // Bulk Selection
  final Set<int> _bulkSelectedIndices = {};

  // Metrics card selection filter
  String _metricFilter = 'all'; // 'all', 'present', 'absent'



  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Feature 14: Localize date output
  String _localizeDate(String dateStr) {
    if (dateStr.trim().isEmpty) return '-';
    try {
      final parts = dateStr.split('-');
      if (parts.length != 3) return dateStr;
      final year = parts[0];
      final month = int.parse(parts[1]);
      final day = parts[2];
      
      final isUr = widget.languageController.locale.languageCode == 'ur';
      if (!isUr) return dateStr;
      
      const urMonths = [
        'جنوری', 'فروری', 'مارچ', 'اپریل', 'مئی', 'جون',
        'جولائی', 'اگست', 'ستمبر', 'اکتوبر', 'نومبر', 'دسمبر'
      ];
      if (month >= 1 && month <= 12) {
        return '$day ${urMonths[month - 1]} $year';
      }
      return dateStr;
    } catch (_) {
      return dateStr;
    }
  }

  // Feature 10: Gender-specific avatars
  Widget _buildGenderAvatar(String? gender) {
    final isBoy = (gender ?? 'male') == 'male';
    return CircleAvatar(
      radius: 16,
      backgroundColor: isBoy ? Colors.blue.shade100 : Colors.pink.shade100,
      child: Icon(
        isBoy ? Icons.face_rounded : Icons.face_3_rounded,
        size: 20,
        color: isBoy ? Colors.blue.shade800 : Colors.pink.shade800,
      ),
    );
  }

  // Feature 7: Attendance indicator badge
  Widget _buildAttendanceBadge(bool isPresent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isPresent ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: isPresent ? Colors.green : Colors.red),
      ),
      child: Text(
        isPresent ? 'P' : 'A',
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isPresent ? Colors.green.shade700 : Colors.red.shade700),
      ),
    );
  }

  // Feature 7: Fee status badge
  Widget _buildFeeStatusBadge(String status) {
    final isPaid = status == 'paid';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isPaid ? Colors.teal.shade50 : Colors.amber.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: isPaid ? Colors.teal : Colors.amber.shade700),
      ),
      child: Text(
        isPaid ? 'Paid' : 'Due',
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isPaid ? Colors.teal.shade700 : Colors.amber.shade800),
      ),
    );
  }

  // Feature 15: Today's Attendance Overview Metric Cards
  // ignore: unused_element
  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String filterValue,
  }) {
    final isSelected = _metricFilter == filterValue;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _metricFilter = filterValue;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: isDark ? 0.3 : 0.15)
                : (isDark ? const Color(0xFF1E293B) : Colors.white),
            border: Border.all(
              color: isSelected ? color : (isDark ? const Color(0xFF334155) : Colors.grey.shade300),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      value,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Feature 4: Comprehensive Profile Detail Views
  void _showStudentProfile(Map<String, dynamic> student) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isRtl = widget.languageController.locale.languageCode != 'en';
    final fieldLabelColor = isDark ? Colors.tealAccent : const Color(0xFF074E32);

    showDialog(
      context: context,
      builder: (ctx) => Dialog.fullscreen(
        backgroundColor: isDark ? const Color(0xFF0B1329) : Colors.white,
        child: Scaffold(
          backgroundColor: isDark ? const Color(0xFF0B1329) : Colors.white,
          appBar: AppBar(
            backgroundColor: const Color(0xFF074E32),
            foregroundColor: Colors.white,
            title: const SizedBox.shrink(),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(ctx),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 45,
                        backgroundColor: (student['gender'] ?? 'male') == 'male' ? Colors.blue.shade100 : Colors.pink.shade100,
                        child: Icon(
                          (student['gender'] ?? 'male') == 'male' ? Icons.face_rounded : Icons.face_3_rounded,
                          size: 55,
                          color: (student['gender'] ?? 'male') == 'male' ? Colors.blue.shade800 : Colors.pink.shade800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        student['name'] ?? '',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Roll No: ${student['rollNo'] ?? student['roll_no'] ?? '-'}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isRtl ? 'بنیادی معلومات' : 'Basic Info',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: fieldLabelColor),
                        ),
                        const Divider(),
                        _buildProfileRow('والد کا نام (Father\'s Name)', student['fatherName'] ?? '-'),
                        _buildProfileRow('رابطہ نمبر (Phone Number)', student['fatherPhone'] ?? '-'),
                        _buildProfileRow('گروپ (Group)', student['group'] ?? '-'),
                        _buildProfileRow('شفٹ (Shift)', student['shift'] ?? '-'),
                        _buildProfileRow('داخلہ تاریخ (Admission Date)', _localizeDate(student['admissionDate'] ?? '')),
                        _buildProfileRow('جنس (Gender)', student['gender'] ?? '-'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isRtl ? 'حاضری اور فیس کا خلاصہ' : 'Attendance & Fee Summary',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: fieldLabelColor),
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                const Text('حاضری شرح', style: TextStyle(color: Colors.grey)),
                                Text(
                                  student['isPresent'] == false ? '90%' : '100%',
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                const Text('فیس کی حالت', style: TextStyle(color: Colors.grey)),
                                Text(
                                  (student['feeStatus'] ?? 'due').toString().toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: (student['feeStatus'] ?? 'due') == 'paid' ? Colors.green : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  // Feature 3: Bulk Batch Actions helper methods
  void _bulkChangeGroup() {
    final loc = AppLocalizations.of(context);
    String targetGroup = 'Hifz Group A';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.translate('batch_group')),
        content: DropdownButtonFormField<String>(
          initialValue: targetGroup,
          items: const [
            DropdownMenuItem(value: 'Hifz Group A', child: Text('Hifz Group A')),
            DropdownMenuItem(value: 'Nazira Group B', child: Text('Nazira Group B')),
            DropdownMenuItem(value: 'Tajweed Group C', child: Text('Tajweed Group C')),
            DropdownMenuItem(value: 'Primary Group D', child: Text('Primary Group D')),
          ],
          onChanged: (v) {
            if (v != null) targetGroup = v;
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              setState(() {
                final disp = _getDisplayedStudentsList();
                for (final idx in _bulkSelectedIndices) {
                  if (idx < disp.length) {
                    final s = disp[idx];
                    final realIdx = studentsList.indexOf(s);
                    if (realIdx != -1) {
                      studentsList[realIdx]['group'] = targetGroup;
                      studentsList[realIdx]['className'] = targetGroup;
                    }
                  }
                }
                _bulkSelectedIndices.clear();
              });
              await saveStudentsToStorage();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _bulkChangeShift() {
    String targetShift = 'morning';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Shift'),
        content: DropdownButtonFormField<String>(
          initialValue: targetShift,
          items: const [
            DropdownMenuItem(value: 'morning', child: Text('Morning')),
            DropdownMenuItem(value: 'evening', child: Text('Evening')),
          ],
          onChanged: (v) {
            if (v != null) targetShift = v;
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              setState(() {
                final disp = _getDisplayedStudentsList();
                for (final idx in _bulkSelectedIndices) {
                  if (idx < disp.length) {
                    final s = disp[idx];
                    final realIdx = studentsList.indexOf(s);
                    if (realIdx != -1) {
                      studentsList[realIdx]['shift'] = targetShift;
                    }
                  }
                }
                _bulkSelectedIndices.clear();
              });
              await saveStudentsToStorage();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _bulkDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Students'),
        content: Text('Are you sure you want to delete ${_bulkSelectedIndices.length} students?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              setState(() {
                final disp = _getDisplayedStudentsList();
                final toRemove = _bulkSelectedIndices.map((idx) => disp[idx]).toList();
                studentsList.removeWhere((s) => toRemove.contains(s));
                _bulkSelectedIndices.clear();
              });
              await saveStudentsToStorage();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // Feature 11: Academic Session Archiving
  void _triggerSessionArchive() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Archive Current Session?'),
        content: const Text('This will save all current student records to the offline archives and clear/reset their fee statuses for the new year. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
              await prefs.setString('archived_session_$timestamp', jsonEncode(studentsList));
              
              setState(() {
                for (var s in studentsList) {
                  s['feeStatus'] = 'due';
                  s['isNewAdmission'] = false; 
                }
              });
              await saveStudentsToStorage();
              if (ctx.mounted) Navigator.pop(ctx);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✓ Session archived successfully! All students reset for new year.'), backgroundColor: Colors.green),
              );
            },
            child: const Text('Archive & Reset'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectPeriod() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
      initialDateRange: _selectedDateRange ?? DateTimeRange(
        start: _selectedDate.subtract(const Duration(days: 3)),
        end: _selectedDate,
      ),
    );
    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
        _selectedDate = picked.start;
      });
    }
  }

  List<Map<String, dynamic>> _getDisplayedStudentsList() {
    return studentsList.where((student) {
      if (_selectedClassFilter != 'All') {
        if (student['className'] != _selectedClassFilter) return false;
      }
      if (_selectedClassFilter != 'All') {
        if (student['className'] != _selectedClassFilter) return false;
      }
      final isNew = student['isNewAdmission'] == true;
      if (_admissionFilter == 'new' && !isNew) return false;
      if (_admissionFilter == 'old' && isNew) return false;

      // Feature 6: Smart Search Tagging
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase().trim();
        if (q.startsWith('#')) {
          final tag = q.substring(1);
          if (tag == 'due') {
            if (student['feeStatus'] == 'paid') return false;
          } else if (tag == 'paid') {
            if (student['feeStatus'] != 'paid') return false;
          } else if (tag == 'morning') {
            if ((student['shift'] ?? 'morning') != 'morning') return false;
          } else if (tag == 'evening') {
            if ((student['shift'] ?? 'morning') != 'evening') return false;
          } else if (tag == 'male') {
            if ((student['gender'] ?? 'male') != 'male') return false;
          } else if (tag == 'female') {
            if ((student['gender'] ?? 'male') != 'female') return false;
          } else if (tag == 'new') {
            if (student['isNewAdmission'] != true) return false;
          } else {
            final name = (student['name'] ?? '').toString().toLowerCase();
            if (!name.contains(q)) return false;
          }
        } else {
          final name = (student['name'] ?? '').toString().toLowerCase();
          if (!name.contains(q)) return false;
        }
      }

      if (_feeFilter == 'paid') {
        if (student['feeStatus'] != 'paid') return false;
      } else if (_feeFilter == 'due') {
        if (student['feeStatus'] == 'paid') return false;
      }

      // Feature 15 filtering
      if (_metricFilter == 'present') {
        if (student['isPresent'] == false) return false;
      } else if (_metricFilter == 'absent') {
        if (student['isPresent'] != false) return false;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isRtl = widget.languageController.locale.languageCode != 'en';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final int newCount = studentsList.where((s) => s['isNewAdmission'] == true).length;
    final int oldCount = studentsList.length - newCount;

    final displayedStudents = _getDisplayedStudentsList();

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: widget.hideAppBar
            ? null
            : AppBar(
          title: _isSearching
              ? TextField(
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: '${loc.translate('search_hint')} (Use #due, #paid, #new)',
                    hintStyle: const TextStyle(color: Colors.white70),
                    border: InputBorder.none,
                    prefixIcon: const Icon(Icons.search, color: Colors.white),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      loc.translate('students_list'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      'استاد: $_loggedInTeacherName',
                      style: const TextStyle(fontSize: 10, color: Colors.white70),
                    ),
                  ],
                ),
          centerTitle: !_isSearching,
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          actions: [
            if (_isSearching)
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () {
                  setState(() {
                    _isSearching = false;
                    _searchQuery = '';
                  });
                },
              )
            else ...[
              IconButton(
                icon: const Icon(Icons.notifications_active_rounded, color: Colors.amberAccent),
                tooltip: 'Notifications / اطلاعات',
                onPressed: showNotificationsCenterDialog,
              ),
              IconButton(
                icon: const Icon(Icons.search_rounded),
                tooltip: loc.translate('search'),
                onPressed: () => setState(() => _isSearching = true),
              ),
            ],
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
                } else if (value == 'archive_session') {
                  _triggerSessionArchive();
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
                PopupMenuItem(
                  value: 'archive_session',
                  child: Row(
                    children: [
                      const Icon(Icons.archive_rounded, color: Colors.green),
                      const SizedBox(width: 8),
                      const Text('سابقہ سال محفوظ کریں (Archive Year)'),
                    ],
                  ),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.person_add_rounded),
              tooltip: loc.translate('add_student'),
              onPressed: showAddStudentDialog,
            ),
            LanguageButton(controller: widget.languageController),
          ],
        ),
        floatingActionButton: null,
        bottomNavigationBar: _bulkSelectedIndices.isNotEmpty
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: isDark ? const Color(0xFF1E293B) : Colors.green.shade50,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isRtl
                          ? '${_bulkSelectedIndices.length} طلبہ منتخب ہیں'
                          : '${_bulkSelectedIndices.length} selected',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.group_work_rounded, color: Colors.blue),
                          tooltip: 'گروپ تبدیل کریں (Change Group)',
                          onPressed: _bulkChangeGroup,
                        ),
                        IconButton(
                          icon: const Icon(Icons.schedule_rounded, color: Colors.orange),
                          tooltip: 'شفٹ تبدیل کریں (Change Shift)',
                          onPressed: _bulkChangeShift,
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_sweep_rounded, color: Colors.red),
                          tooltip: 'حذف کریں (Delete selected)',
                          onPressed: _bulkDelete,
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () => setState(() => _bulkSelectedIndices.clear()),
                          child: Text(isRtl ? 'منسوخ' : 'Clear'),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            : SafeArea(
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
                  // Compact Top Controls Bar
                  Container(
                    color: isDark ? const Color(0xFF0F172A) : Colors.green.shade50,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Period Selector
                        ActionChip(
                          avatar: const Icon(Icons.calendar_month_rounded, size: 14, color: Colors.green),
                          label: Text(
                            _selectedDateRange == null
                                ? '${_selectedDate.day}-${_selectedDate.month}-${_selectedDate.year}'
                                : '${_selectedDateRange!.start.day}/${_selectedDateRange!.start.month} - ${_selectedDateRange!.end.day}/${_selectedDateRange!.end.month}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          onPressed: _selectPeriod,
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                        // Batch Dropdown Selector
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(16),
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          ),
                          child: DropdownButton<String>(
                            value: _selectedClassFilter,
                            underline: const SizedBox(),
                            icon: const Icon(Icons.arrow_drop_down, size: 16),
                            style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : Colors.black87, fontWeight: FontWeight.bold),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedClassFilter = val;
                                });
                              }
                            },
                            items: ['All', 'Class 7 (A)', 'Class 6 (B)']
                                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                                .toList(),
                          ),
                        ),
                        // Admission Filter
                        DropdownButton<String>(
                          value: _admissionFilter,
                          underline: const SizedBox(),
                          icon: const Icon(Icons.filter_alt_rounded, size: 14, color: Colors.green),
                          style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : Colors.black87, fontWeight: FontWeight.bold),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _admissionFilter = val;
                              });
                            }
                          },
                          items: [
                            DropdownMenuItem(value: 'all', child: Text('${loc.translate('all')} (${studentsList.length})')),
                            DropdownMenuItem(value: 'new', child: Text('${loc.translate('new_admission')} ($newCount)')),
                            DropdownMenuItem(value: 'old', child: Text('${loc.translate('old_admission')} ($oldCount)')),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Compact metrics summary
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('${loc.translate('total')}: ${displayedStudents.length}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 12),
                        Text('${loc.translate('present')}: ${displayedStudents.where((s) => s['isPresent'] != false).length}', style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 12),
                        Text('${loc.translate('absent')}: ${displayedStudents.where((s) => s['isPresent'] == false).length}', style: const TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),

                  // Feature 12: Pull-to-Refresh Integration
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async {
                        await Future.delayed(const Duration(milliseconds: 800));
                        await loadStudentsFromStorage();
                      },
                      child: displayedStudents.isEmpty
                          // Feature 9: Interactive Empty States
                          ? Center(
                              child: SingleChildScrollView(
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
                                    const SizedBox(height: 16),
                                    OutlinedButton(
                                      onPressed: () {
                                        setState(() {
                                          _searchQuery = '';
                                          _admissionFilter = 'all';
                                          _feeFilter = 'all';
                                          _metricFilter = 'all';
                                          _isSearching = false;
                                        });
                                      },
                                      child: const Text('Reset All Filters / فلٹرز ختم کریں'),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : _isTableView
                              ? SingleChildScrollView(
                                  padding: const EdgeInsets.all(12),
                                  scrollDirection: Axis.horizontal,
                                  child: SingleChildScrollView(
                                    controller: _scrollController,
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
                                      rows: List.generate(
                                        displayedStudents.length < _displayCount ? displayedStudents.length : _displayCount,
                                        (index) {
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
                                                IconButton(
                                                  icon: const Icon(Icons.delete, color: Colors.red, size: 16),
                                                  onPressed: () => deleteStudent(index),
                                                ),
                                              ],
                                            )),
                                          ]);
                                        },
                                      ),
                                    ),
                                  ),
                                )
                              : Row(
                                  children: [
                                    Expanded(
                                      child: ListView.builder(
                                        controller: _scrollController,
                                        padding: const EdgeInsets.all(12),
                                        itemCount: displayedStudents.length < _displayCount ? displayedStudents.length : _displayCount,
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
                                                leading: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Checkbox(
                                                      value: _bulkSelectedIndices.contains(index),
                                                      onChanged: (v) {
                                                        setState(() {
                                                          if (v == true) {
                                                            _bulkSelectedIndices.add(index);
                                                          } else {
                                                            _bulkSelectedIndices.remove(index);
                                                          }
                                                        });
                                                      },
                                                    ),
                                                    const SizedBox(width: 4),
                                                    _buildGenderAvatar(student['gender']),
                                                  ],
                                                ),
                                                title: Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Expanded(
                                                      child: InkWell(
                                                        onTap: () => _showStudentProfile(student),
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
                                                            const SizedBox(width: 8),
                                                            _buildAttendanceBadge(student['isPresent'] as bool? ?? true),
                                                            const SizedBox(width: 4),
                                                            _buildFeeStatusBadge(student['feeStatus']?.toString() ?? 'due'),
                                                          ],
                                                        ),
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
                                                        } else if (value == 'edit_batch_class') {
                                                          showEditStudentClassAndBatchDialog(index);
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
                                                        PopupMenuItem(
                                                          value: 'edit_batch_class',
                                                          child: Row(
                                                            children: [
                                                              const Icon(Icons.edit_note_rounded, size: 20, color: Colors.indigo),
                                                              const SizedBox(width: 8),
                                                              Text(loc.locale.languageCode == 'en' ? 'Edit Class & Slot' : 'کلاس و شفٹ کی تبدیلی'),
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
                                    if (displayedStudents.length > 10 && _searchQuery.isEmpty)
                                      Container(
                                        width: 24,
                                        color: Colors.transparent,
                                        child: SingleChildScrollView(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('').map((letter) {
                                              return GestureDetector(
                                                onTap: () {
                                                  final idx = displayedStudents.indexWhere((s) => (s['name'] ?? '').toString().toUpperCase().startsWith(letter));
                                                  if (idx != -1) {
                                                    _scrollController.animateTo(
                                                      idx * 115.0,
                                                      duration: const Duration(milliseconds: 350),
                                                      curve: Curves.easeInOut,
                                                    );
                                                  }
                                                },
                                                child: Padding(
                                                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                                                  child: Text(
                                                    letter,
                                                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.green),
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                  ),
                ),
              ],
              ),
      ),
    );
  }
}
