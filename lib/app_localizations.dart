import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageController extends ChangeNotifier {
  static const String _prefKey = 'selected_language';
  Locale _locale = const Locale('ur');

  Locale get locale => _locale;

  LanguageController() {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final langCode = prefs.getString(_prefKey) ?? 'ur';
      _locale = Locale(langCode);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> setLanguage(String langCode) async {
    if (_locale.languageCode == langCode) return;
    _locale = Locale(langCode);
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, langCode);
    } catch (_) {}
  }
}

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('ur'));
  }

  static final Map<String, Map<String, String>> _localizedValues = {
    // ─────────────── URDU ───────────────
    'ur': {
      'app_title': 'مکتب مینیجر',
      'students_list': 'طلباء کی فہرست',
      'add_student': 'طالب علم شامل کریں',
      'edit_student': 'معلومات تبدیل کریں',
      'delete_student': 'حذف کریں',
      'search_hint': 'نام، رول نمبر، یا والد کے نام سے تلاش کریں...',
      'name': 'نام',
      'roll_no': 'رول نمبر',
      'father_name': 'والد کا نام',
      'phone_number': 'فون نمبر',
      'class_grade': 'کلاس / درجہ',
      'shift': 'شفٹ',
      'morning': 'صبح',
      'evening': 'شام',
      'gender': 'جنس',
      'male': 'لڑکا',
      'female': 'لڑکی',
      'teacher_name': 'استاد کا نام',
      'notice_channel': 'اطلاع کا ذریعہ',
      'message_language': 'میسج کی زبان',
      'save': 'محفوظ کریں',
      'cancel': 'کینسل',
      'delete': 'ڈیلیٹ',
      'fee_record': 'فیس ریکارڈ',
      'fee_amount': 'فیس کی رقم',
      'select_month': 'مہینہ منتخب کریں',
      'fee_status': 'فیس کا اسٹیٹس',
      'due': 'واجب الادا',
      'partially_paid': 'جزوی ادا',
      'paid': 'ادا شدہ',
      'attendance': 'حاضری',
      'present': 'حاضر',
      'absent': 'غائب',
      'leave': 'رخصت',
      'sabaq_lessons': 'اسباق کا ہدف',
      'total_students': 'کل طلباء',
      'actions': 'ایکشنز',
      'select_language': 'زبان منتخب کریں',
      'urdu': 'اردو',
      'english': 'English',
      'arabic': 'العربية',
      'hindi': 'हिंदी',
      'telugu': 'తెలుగు',
      'kannada': 'ಕನ್ನಡ',
      'tamil': 'தமிழ்',
      'malayalam': 'മലയാളം',
      'no_students_found': 'کوئی طالب علم نہیں ملا',
      'confirm_delete': 'کیا آپ واقعی اس طالب علم کو حذف کرنا چاہتے ہیں؟',
      'view_sabaq': 'سبق دیکھیں',
      'call': 'کال کریں',
      'whatsapp': 'واٹس ایپ',
      'all': 'تمام',
      'analytics': 'تجزیہ و رپورٹس',
      'theme_mode': 'تھیم تبدیل کریں',
      'print_pdf': 'پی ڈی ایف پرنٹ کریں',
      'fee_receipt': 'فیس کی رسید',
      'report_card': 'تعلیمی و حاضری رپورٹ',
      'consecutive_absent_alert': 'مسلسل غیر حاضری کا الرٹ',
      'consecutive_absent_desc': 'ان طلبہ کو مسلسل 3 دن سے زائد غیر حاضر پایا گیا ہے',
      'total_due_amount': 'کل واجب الادا رقم',
      'total_paid_amount': 'کل ادا شدہ رقم',
      'attendance_rate': 'حاضری کا تناسب',
    },

    // ─────────────── ENGLISH ───────────────
    'en': {
      'app_title': 'Maktab Manager',
      'students_list': 'Student List',
      'add_student': 'Add Student',
      'edit_student': 'Edit Student',
      'delete_student': 'Delete Student',
      'search_hint': 'Search by name, roll no, or father name...',
      'name': 'Name',
      'roll_no': 'Roll Number',
      'father_name': "Father's Name",
      'phone_number': 'Phone Number',
      'class_grade': 'Class / Grade',
      'shift': 'Shift',
      'morning': 'Morning',
      'evening': 'Evening',
      'gender': 'Gender',
      'male': 'Male',
      'female': 'Female',
      'teacher_name': "Teacher's Name",
      'notice_channel': 'Notification Method',
      'message_language': 'Message Language',
      'save': 'Save',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'fee_record': 'Fee Record',
      'fee_amount': 'Fee Amount',
      'select_month': 'Select Month',
      'fee_status': 'Fee Status',
      'due': 'Unpaid / Due',
      'partially_paid': 'Partially Paid',
      'paid': 'Paid',
      'attendance': 'Attendance',
      'present': 'Present',
      'absent': 'Absent',
      'leave': 'Leave',
      'sabaq_lessons': 'Lesson Target',
      'total_students': 'Total Students',
      'actions': 'Actions',
      'select_language': 'Select Language',
      'urdu': 'Urdu (اردو)',
      'english': 'English',
      'arabic': 'Arabic (العربية)',
      'hindi': 'Hindi (हिंदी)',
      'telugu': 'Telugu (తెలుగు)',
      'kannada': 'Kannada (ಕನ್ನಡ)',
      'tamil': 'Tamil (தமிழ்)',
      'malayalam': 'Malayalam (മലയാളം)',
      'no_students_found': 'No students found',
      'confirm_delete': 'Are you sure you want to delete this student?',
      'view_sabaq': 'View Lesson',
      'call': 'Call',
      'whatsapp': 'WhatsApp',
      'all': 'All',
      'analytics': 'Analytics & Reports',
      'theme_mode': 'Toggle Theme',
      'print_pdf': 'Print PDF',
      'fee_receipt': 'Fee Receipt',
      'report_card': 'Report Card',
      'consecutive_absent_alert': 'Consecutive Absence Alert',
      'consecutive_absent_desc': 'These students have been absent for 3+ consecutive days',
      'total_due_amount': 'Total Due Amount',
      'total_paid_amount': 'Total Paid Amount',
      'attendance_rate': 'Attendance Rate',
    },

    // ─────────────── ARABIC ───────────────
    'ar': {
      'app_title': 'مدير المكتب',
      'students_list': 'قائمة الطلاب',
      'add_student': 'إضافة طالب',
      'edit_student': 'تعديل بيانات الطالب',
      'delete_student': 'حذف',
      'search_hint': 'ابحث بالاسم أو رقم القيد أو اسم الأب...',
      'name': 'الاسم',
      'roll_no': 'رقم القيد',
      'father_name': 'اسم الأب',
      'phone_number': 'رقم الهاتف',
      'class_grade': 'الصف / المرحلة',
      'shift': 'الفترة',
      'morning': 'صباحاً',
      'evening': 'مساءً',
      'gender': 'الجنس',
      'male': 'ذكر',
      'female': 'أنثى',
      'teacher_name': 'اسم المعلم',
      'notice_channel': 'وسيلة الإشعارات',
      'message_language': 'لغة الرسالة',
      'save': 'حفظ',
      'cancel': 'إلغاء',
      'delete': 'حذف',
      'fee_record': 'سجل الرسوم',
      'fee_amount': 'مبلغ الرسوم',
      'select_month': 'اختر الشهر',
      'fee_status': 'حالة الرسوم',
      'due': 'مستحق',
      'partially_paid': 'مدفوع جزئياً',
      'paid': 'مدفوع',
      'attendance': 'التحضير',
      'present': 'حاضر',
      'absent': 'غائب',
      'leave': 'إجازة',
      'sabaq_lessons': 'متابعة الدروس',
      'total_students': 'إجمالي الطلاب',
      'actions': 'الإجراءات',
      'select_language': 'اختر اللغة',
      'urdu': 'أردو (اردو)',
      'english': 'الإنجليزية (English)',
      'arabic': 'العربية',
      'hindi': 'الهندية (हिंदी)',
      'telugu': 'التيلوغو (తెలుగు)',
      'kannada': 'الكانادية (ಕನ್ನಡ)',
      'tamil': 'التاميلية (தமிழ்)',
      'malayalam': 'المالايالامية (മലയാളം)',
      'no_students_found': 'لم يتم العثور على طلاب',
      'confirm_delete': 'هل أنت تأكد من حذف هذا الطالب؟',
      'view_sabaq': 'عرض الدرس',
      'call': 'اتصال',
      'whatsapp': 'واتساب',
      'all': 'الكل',
      'analytics': 'التحليلات والتقارير',
      'theme_mode': 'تغيير المظهر',
      'print_pdf': 'طباعة PDF',
      'fee_receipt': 'إيصال الرسوم',
      'report_card': 'التقرير الدراسي',
      'consecutive_absent_alert': 'تنبيه الغياب المتكرر',
      'consecutive_absent_desc': 'هؤلاء الطلاب غائبون لأكثر من 3 أيام متتالية',
      'total_due_amount': 'إجمالي المبلغ المستحق',
      'total_paid_amount': 'إجمالي المبلغ المدفوع',
      'attendance_rate': 'نسبة الحضور',
    },

    // ─────────────── HINDI ───────────────
    'hi': {
      'app_title': 'मकतब मैनेजर',
      'students_list': 'छात्र सूची',
      'add_student': 'छात्र जोड़ें',
      'edit_student': 'छात्र संपादित करें',
      'delete_student': 'हटाएं',
      'search_hint': 'नाम, रोल नं, या पिता के नाम से खोजें...',
      'name': 'नाम',
      'roll_no': 'रोल नंबर',
      'father_name': 'पिता का नाम',
      'phone_number': 'फ़ोन नंबर',
      'class_grade': 'कक्षा / दर्जा',
      'shift': 'शिफ्ट',
      'morning': 'सुबह',
      'evening': 'शाम',
      'gender': 'लिंग',
      'male': 'लड़का',
      'female': 'लड़की',
      'teacher_name': 'शिक्षक का नाम',
      'notice_channel': 'सूचना का तरीका',
      'message_language': 'संदेश की भाषा',
      'save': 'सहेजें',
      'cancel': 'रद्द करें',
      'delete': 'हटाएं',
      'fee_record': 'फीस रिकॉर्ड',
      'fee_amount': 'फीस राशि',
      'select_month': 'महीना चुनें',
      'fee_status': 'फीस की स्थिति',
      'due': 'बकाया',
      'partially_paid': 'आंशिक भुगतान',
      'paid': 'भुगतान हो गया',
      'attendance': 'उपस्थिति',
      'present': 'उपस्थित',
      'absent': 'अनुपस्थित',
      'leave': 'छुट्टी',
      'sabaq_lessons': 'पाठ लक्ष्य',
      'total_students': 'कुल छात्र',
      'actions': 'कार्रवाई',
      'select_language': 'भाषा चुनें',
      'urdu': 'उर्दू (اردو)',
      'english': 'अंग्रेज़ी (English)',
      'arabic': 'अरबी (العربية)',
      'hindi': 'हिंदी',
      'telugu': 'तेलुगु (తెలుగు)',
      'kannada': 'कन्नड़ (ಕನ್ನಡ)',
      'tamil': 'तमिल (தமிழ்)',
      'malayalam': 'मलयालम (മലയാളം)',
      'no_students_found': 'कोई छात्र नहीं मिला',
      'confirm_delete': 'क्या आप वाकई इस छात्र को हटाना चाहते हैं?',
      'view_sabaq': 'पाठ देखें',
      'call': 'कॉल करें',
      'whatsapp': 'WhatsApp',
      'all': 'सभी',
      'analytics': 'विश्लेषण और रिपोर्ट',
      'theme_mode': 'थीम बदलें',
      'print_pdf': 'PDF प्रिंट करें',
      'fee_receipt': 'फीस रसीद',
      'report_card': 'रिपोर्ट कार्ड',
      'consecutive_absent_alert': 'लगातार अनुपस्थिति अलर्ट',
      'consecutive_absent_desc': 'ये छात्र लगातार 3+ दिनों से अनुपस्थित हैं',
      'total_due_amount': 'कुल बकाया राशि',
      'total_paid_amount': 'कुल भुगतान राशि',
      'attendance_rate': 'उपस्थिति दर',
    },

    // ─────────────── TELUGU ───────────────
    'te': {
      'app_title': 'మక్తబ్ మేనేజర్',
      'students_list': 'విద్యార్థుల జాబితా',
      'add_student': 'విద్యార్థిని జోడించండి',
      'edit_student': 'విద్యార్థిని సవరించండి',
      'delete_student': 'తొలగించండి',
      'search_hint': 'పేరు, రోల్ నం, లేదా తండ్రి పేరు ద్వారా శోధించండి...',
      'name': 'పేరు',
      'roll_no': 'రోల్ నంబర్',
      'father_name': 'తండ్రి పేరు',
      'phone_number': 'ఫోన్ నంబర్',
      'class_grade': 'తరగతి / గ్రేడ్',
      'shift': 'షిఫ్ట్',
      'morning': 'ఉదయం',
      'evening': 'సాయంత్రం',
      'gender': 'లింగం',
      'male': 'మగ',
      'female': 'ఆడ',
      'teacher_name': 'ఉపాధ్యాయుని పేరు',
      'notice_channel': 'నోటీస్ పద్ధతి',
      'message_language': 'సందేశ భాష',
      'save': 'సేవ్ చేయండి',
      'cancel': 'రద్దు చేయండి',
      'delete': 'తొలగించు',
      'fee_record': 'ఫీజు రికార్డు',
      'fee_amount': 'ఫీజు మొత్తం',
      'select_month': 'నెలను ఎంచుకోండి',
      'fee_status': 'ఫీజు స్థితి',
      'due': 'బాకీ',
      'partially_paid': 'పాక్షికంగా చెల్లించారు',
      'paid': 'చెల్లించారు',
      'attendance': 'హాజరు',
      'present': 'హాజరు',
      'absent': 'గైర్హాజరు',
      'leave': 'సెలవు',
      'sabaq_lessons': 'పాఠం లక్ష్యం',
      'total_students': 'మొత్తం విద్యార్థులు',
      'actions': 'చర్యలు',
      'select_language': 'భాష ఎంచుకోండి',
      'urdu': 'ఉర్దూ (اردو)',
      'english': 'ఇంగ్లీషు (English)',
      'arabic': 'అరబిక్ (العربية)',
      'hindi': 'హిందీ (हिंदी)',
      'telugu': 'తెలుగు',
      'kannada': 'కన్నడ (ಕನ್ನಡ)',
      'tamil': 'తమిళం (தமிழ்)',
      'malayalam': 'మలయాళం (മലയാളം)',
      'no_students_found': 'విద్యార్థులు కనుగొనబడలేదు',
      'confirm_delete': 'మీరు నిజంగా ఈ విద్యార్థిని తొలగించాలనుకుంటున్నారా?',
      'view_sabaq': 'పాఠం చూడండి',
      'call': 'కాల్ చేయండి',
      'whatsapp': 'WhatsApp',
      'all': 'అన్నీ',
      'analytics': 'విశ్లేషణలు & నివేదికలు',
      'theme_mode': 'థీమ్ మార్చండి',
      'print_pdf': 'PDF ప్రింట్ చేయండి',
      'fee_receipt': 'ఫీజు రసీదు',
      'report_card': 'రిపోర్ట్ కార్డ్',
      'consecutive_absent_alert': 'వరుస గైర్హాజరు హెచ్చరిక',
      'consecutive_absent_desc': 'ఈ విద్యార్థులు వరుసగా 3+ రోజులు గైర్హాజరు అయ్యారు',
      'total_due_amount': 'మొత్తం బాకీ మొత్తం',
      'total_paid_amount': 'మొత్తం చెల్లించిన మొత్తం',
      'attendance_rate': 'హాజరు రేటు',
    },

    // ─────────────── KANNADA ───────────────
    'kn': {
      'app_title': 'ಮಕ್ತಬ್ ಮ್ಯಾನೇಜರ್',
      'students_list': 'ವಿದ್ಯಾರ್ಥಿ ಪಟ್ಟಿ',
      'add_student': 'ವಿದ್ಯಾರ್ಥಿ ಸೇರಿಸಿ',
      'edit_student': 'ವಿದ್ಯಾರ್ಥಿ ಸಂಪಾದಿಸಿ',
      'delete_student': 'ಅಳಿಸಿ',
      'search_hint': 'ಹೆಸರು, ರೋಲ್ ನಂ, ಅಥವಾ ತಂದೆ ಹೆಸರಿನಿಂದ ಹುಡುಕಿ...',
      'name': 'ಹೆಸರು',
      'roll_no': 'ರೋಲ್ ಸಂಖ್ಯೆ',
      'father_name': 'ತಂದೆಯ ಹೆಸರು',
      'phone_number': 'ಫೋನ್ ಸಂಖ್ಯೆ',
      'class_grade': 'ತರಗತಿ / ಗ್ರೇಡ್',
      'shift': 'ಶಿಫ್ಟ್',
      'morning': 'ಬೆಳಗ್ಗೆ',
      'evening': 'ಸಂಜೆ',
      'gender': 'ಲಿಂಗ',
      'male': 'ಗಂಡು',
      'female': 'ಹೆಣ್ಣು',
      'teacher_name': 'ಶಿಕ್ಷಕರ ಹೆಸರು',
      'notice_channel': 'ಸೂಚನೆ ವಿಧಾನ',
      'message_language': 'ಸಂದೇಶ ಭಾಷೆ',
      'save': 'ಉಳಿಸಿ',
      'cancel': 'ರದ್ದುಮಾಡಿ',
      'delete': 'ಅಳಿಸಿ',
      'fee_record': 'ಶುಲ್ಕ ದಾಖಲೆ',
      'fee_amount': 'ಶುಲ್ಕ ಮೊತ್ತ',
      'select_month': 'ತಿಂಗಳು ಆಯ್ಕೆಮಾಡಿ',
      'fee_status': 'ಶುಲ್ಕ ಸ್ಥಿತಿ',
      'due': 'ಬಾಕಿ',
      'partially_paid': 'ಭಾಗಶಃ ಪಾವತಿ',
      'paid': 'ಪಾವತಿ ಆಗಿದೆ',
      'attendance': 'ಹಾಜರಾತಿ',
      'present': 'ಹಾಜರು',
      'absent': 'ಗೈರುಹಾಜರು',
      'leave': 'ರಜೆ',
      'sabaq_lessons': 'ಪಾಠ ಗುರಿ',
      'total_students': 'ಒಟ್ಟು ವಿದ್ಯಾರ್ಥಿಗಳು',
      'actions': 'ಕ್ರಿಯೆಗಳು',
      'select_language': 'ಭಾಷೆ ಆಯ್ಕೆಮಾಡಿ',
      'urdu': 'ಉರ್ದು (اردو)',
      'english': 'ಇಂಗ್ಲಿಷ್ (English)',
      'arabic': 'ಅರಬಿಕ್ (العربية)',
      'hindi': 'ಹಿಂದಿ (हिंदी)',
      'telugu': 'ತೆಲುಗು (తెలుగు)',
      'kannada': 'ಕನ್ನಡ',
      'tamil': 'ತಮಿಳು (தமிழ்)',
      'malayalam': 'ಮಲಯಾಳಂ (മലയാളം)',
      'no_students_found': 'ವಿದ್ಯಾರ್ಥಿಗಳು ಕಂಡುಬಂದಿಲ್ಲ',
      'confirm_delete': 'ನೀವು ನಿಜವಾಗಿಯೂ ಈ ವಿದ್ಯಾರ್ಥಿಯನ್ನು ಅಳಿಸಲು ಬಯಸುತ್ತೀರಾ?',
      'view_sabaq': 'ಪಾಠ ನೋಡಿ',
      'call': 'ಕರೆ ಮಾಡಿ',
      'whatsapp': 'WhatsApp',
      'all': 'ಎಲ್ಲಾ',
      'analytics': 'ವಿಶ್ಲೇಷಣೆ & ವರದಿಗಳು',
      'theme_mode': 'ಥೀಮ್ ಬದಲಾಯಿಸಿ',
      'print_pdf': 'PDF ಮುದ್ರಿಸಿ',
      'fee_receipt': 'ಶುಲ್ಕ ರಸೀದಿ',
      'report_card': 'ವರದಿ ಕಾರ್ಡ್',
      'consecutive_absent_alert': 'ಸತತ ಗೈರುಹಾಜರು ಎಚ್ಚರಿಕೆ',
      'consecutive_absent_desc': 'ಈ ವಿದ್ಯಾರ್ಥಿಗಳು ಸತತ 3+ ದಿನಗಳಿಂದ ಗೈರುಹಾಜರಾಗಿದ್ದಾರೆ',
      'total_due_amount': 'ಒಟ್ಟು ಬಾಕಿ ಮೊತ್ತ',
      'total_paid_amount': 'ಒಟ್ಟು ಪಾವತಿ ಮೊತ್ತ',
      'attendance_rate': 'ಹಾಜರಾತಿ ದರ',
    },

    // ─────────────── TAMIL ───────────────
    'ta': {
      'app_title': 'மக்தப் மேலாளர்',
      'students_list': 'மாணவர் பட்டியல்',
      'add_student': 'மாணவரை சேர்க்கவும்',
      'edit_student': 'மாணவரை திருத்தவும்',
      'delete_student': 'நீக்கு',
      'search_hint': 'பெயர், சுருட்டு எண், அல்லது தந்தை பெயரால் தேடுங்கள்...',
      'name': 'பெயர்',
      'roll_no': 'சுருட்டு எண்',
      'father_name': 'தந்தையின் பெயர்',
      'phone_number': 'தொலைபேசி எண்',
      'class_grade': 'வகுப்பு / தரம்',
      'shift': 'ஷிஃப்ட்',
      'morning': 'காலை',
      'evening': 'மாலை',
      'gender': 'பாலினம்',
      'male': 'ஆண்',
      'female': 'பெண்',
      'teacher_name': 'ஆசிரியர் பெயர்',
      'notice_channel': 'அறிவிப்பு முறை',
      'message_language': 'செய்தி மொழி',
      'save': 'சேமிக்கவும்',
      'cancel': 'ரத்து செய்',
      'delete': 'நீக்கு',
      'fee_record': 'கட்டண பதிவு',
      'fee_amount': 'கட்டண தொகை',
      'select_month': 'மாதத்தை தேர்ந்தெடுக்கவும்',
      'fee_status': 'கட்டண நிலை',
      'due': 'நிலுவை',
      'partially_paid': 'பகுதியாக செலுத்தப்பட்டது',
      'paid': 'செலுத்தப்பட்டது',
      'attendance': 'வருகை',
      'present': 'வருகை',
      'absent': 'வருகையில்லை',
      'leave': 'விடுப்பு',
      'sabaq_lessons': 'பாட இலக்கு',
      'total_students': 'மொத்த மாணவர்கள்',
      'actions': 'செயல்கள்',
      'select_language': 'மொழியை தேர்ந்தெடுக்கவும்',
      'urdu': 'உருது (اردو)',
      'english': 'ஆங்கிலம் (English)',
      'arabic': 'அரபிக் (العربية)',
      'hindi': 'இந்தி (हिंदी)',
      'telugu': 'தெலுங்கு (తెలుగు)',
      'kannada': 'கன்னடம் (ಕನ್ನಡ)',
      'tamil': 'தமிழ்',
      'malayalam': 'மலையாளம் (മലയാളം)',
      'no_students_found': 'மாணவர்கள் எவரும் கண்டுபிடிக்கப்படவில்லை',
      'confirm_delete': 'இந்த மாணவரை நீக்க விரும்புகிறீர்களா?',
      'view_sabaq': 'பாடத்தை பாருங்கள்',
      'call': 'அழையுங்கள்',
      'whatsapp': 'WhatsApp',
      'all': 'அனைத்தும்',
      'analytics': 'பகுப்பாய்வு & அறிக்கைகள்',
      'theme_mode': 'தீம் மாற்று',
      'print_pdf': 'PDF அச்சிடு',
      'fee_receipt': 'கட்டண ரசீது',
      'report_card': 'அறிக்கை அட்டை',
      'consecutive_absent_alert': 'தொடர் வருகையில்லா எச்சரிக்கை',
      'consecutive_absent_desc': 'இந்த மாணவர்கள் தொடர்ச்சியாக 3+ நாட்கள் வருகையில்லாமல் உள்ளனர்',
      'total_due_amount': 'மொத்த நிலுவை தொகை',
      'total_paid_amount': 'மொத்த செலுத்திய தொகை',
      'attendance_rate': 'வருகை விகிதம்',
    },

    // ─────────────── MALAYALAM ───────────────
    'ml': {
      'app_title': 'മക്തബ് മാനേജർ',
      'students_list': 'വിദ്യാർത്ഥി പട്ടിക',
      'add_student': 'വിദ്യാർത്ഥിയെ ചേർക്കുക',
      'edit_student': 'വിദ്യാർത്ഥിയെ തിരുത്തുക',
      'delete_student': 'ഇല്ലാതാക്കുക',
      'search_hint': 'പേര്, റോൾ നം, അല്ലെങ്കിൽ പിതാവിന്റെ പേര് ഉപയോഗിച്ച് തിരയുക...',
      'name': 'പേര്',
      'roll_no': 'റോൾ നമ്പർ',
      'father_name': 'പിതാവിന്റെ പേര്',
      'phone_number': 'ഫോൺ നമ്പർ',
      'class_grade': 'ക്ലാസ് / ഗ്രേഡ്',
      'shift': 'ഷിഫ്റ്റ്',
      'morning': 'രാവിലെ',
      'evening': 'വൈകുന്നേരം',
      'gender': 'ലിംഗം',
      'male': 'ആൺ',
      'female': 'പെൺ',
      'teacher_name': 'അദ്ധ്യാപകന്റെ പേര്',
      'notice_channel': 'അറിയിപ്പ് രീതി',
      'message_language': 'സന്ദേശ ഭാഷ',
      'save': 'സംരക്ഷിക്കുക',
      'cancel': 'റദ്ദാക്കുക',
      'delete': 'ഇല്ലാതാക്കുക',
      'fee_record': 'ഫീസ് രേഖ',
      'fee_amount': 'ഫീസ് തുക',
      'select_month': 'മാസം തിരഞ്ഞെടുക്കുക',
      'fee_status': 'ഫീസ് നിലവാരം',
      'due': 'കുടിശ്ശിക',
      'partially_paid': 'ഭാഗികമായി അടച്ചു',
      'paid': 'അടച്ചു',
      'attendance': 'ഹാജർ',
      'present': 'ഹാജർ',
      'absent': 'ഗൈർഹാജർ',
      'leave': 'അവധി',
      'sabaq_lessons': 'പാഠ ലക്ഷ്യം',
      'total_students': 'ആകെ വിദ്യാർത്ഥികൾ',
      'actions': 'നടപടികൾ',
      'select_language': 'ഭാഷ തിരഞ്ഞെടുക്കുക',
      'urdu': 'ഉർദു (اردو)',
      'english': 'ഇംഗ്ലീഷ് (English)',
      'arabic': 'അറബിക് (العربية)',
      'hindi': 'ഹിന്ദി (हिंदी)',
      'telugu': 'തെലുഗു (తెలుగు)',
      'kannada': 'കന്നഡ (ಕನ್ನಡ)',
      'tamil': 'തമിഴ് (தமிழ்)',
      'malayalam': 'മലയാളം',
      'no_students_found': 'വിദ്യാർത്ഥികളെ കണ്ടെത്തിയില്ല',
      'confirm_delete': 'നിങ്ങൾക്ക് ഈ വിദ്യാർത്ഥിയെ ഇല്ലാതാക്കണോ?',
      'view_sabaq': 'പാഠം കാണുക',
      'call': 'വിളിക്കുക',
      'whatsapp': 'WhatsApp',
      'all': 'എല്ലാം',
      'analytics': 'വിശകലനങ്ങൾ & റിപ്പോർട്ടുകൾ',
      'theme_mode': 'തീം മാറ്റുക',
      'print_pdf': 'PDF പ്രിന്റ് ചെയ്യുക',
      'fee_receipt': 'ഫീസ് രസീത്',
      'report_card': 'റിപ്പോർട്ട് കാർഡ്',
      'consecutive_absent_alert': 'തുടർ ഗൈർഹാജർ മുന്നറിയിപ്പ്',
      'consecutive_absent_desc': 'ഈ വിദ്യാർത്ഥികൾ തുടർച്ചയായി 3+ ദിവസം ഗൈർഹാജരായി',
      'total_due_amount': 'ആകെ കുടിശ്ശിക തുക',
      'total_paid_amount': 'ആകെ അടച്ച തുക',
      'attendance_rate': 'ഹാജർ നിരക്ക്',
    },
  };

  String translate(String key) {
    final langCode = locale.languageCode;
    return _localizedValues[langCode]?[key] ??
        _localizedValues['ur']?[key] ??
        key;
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['ur', 'en', 'ar', 'hi', 'te', 'kn', 'ta', 'ml']
        .contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}

/// Language metadata for display in picker
class LangOption {
  final String code;
  final String nativeScript; // shown in native script
  const LangOption(this.code, this.nativeScript);
}

const List<LangOption> kAllLanguages = [
  LangOption('ur', 'اردو'),
  LangOption('en', 'English'),
  LangOption('ar', 'العربية'),
  LangOption('hi', 'हिंदी'),
  LangOption('te', 'తెలుగు'),
  LangOption('kn', 'ಕನ್ನಡ'),
  LangOption('ta', 'தமிழ்'),
  LangOption('ml', 'മലയാളം'),
];

class LanguageButton extends StatelessWidget {
  final LanguageController controller;

  const LanguageButton({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final currentCode = controller.locale.languageCode;

    return PopupMenuButton<String>(
      icon: const Icon(Icons.language),
      tooltip: loc.translate('select_language'),
      onSelected: (String langCode) {
        controller.setLanguage(langCode);
      },
      itemBuilder: (BuildContext context) => kAllLanguages.map((lang) {
        final isSelected = currentCode == lang.code;
        return PopupMenuItem<String>(
          value: lang.code,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  lang.nativeScript,
                  style: TextStyle(
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              if (isSelected)
                const Icon(Icons.check, size: 18, color: Colors.green),
            ],
          ),
        );
      }).toList(),
    );
  }
}
