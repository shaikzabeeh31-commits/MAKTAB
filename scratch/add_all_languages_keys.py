import re

filepath = r"c:\project\MAKTAB\lib\app_localizations.dart"

with open(filepath, "r", encoding="utf-8") as f:
    content = f.read()

new_keys = {
    'ur': {
        'present': 'حاضر',
        'absent': 'غیر حاضر',
        'late': 'تاخیر',
        'total_students': 'کل طلبہ',
        'select': 'منتخب',
        'cap_uniform_books': 'ٹوپی / یونیفارم / کتابیں',
        'late_arrival': 'دیر سے آیا',
        'attendance_tap': 'حاضری\\n(کلک کریں)',
        'student_father_header': 'طالب علم کا نام\\nوالد کا نام',
        'notifications_center': 'نوٹیفکیشنز سینٹر',
        'prev_attendance_saved': 'پچھلی حاضری کامیابی سے محفوظ ہو گئی۔',
        'new_admin_msg': 'ایڈمن کی جانب سے نیا پیغام موصول ہواے۔',
        'student_attendance_list': 'طلبہ کی حاضری لسٹ',
        'hardware_test_tool': 'مائیک و کیمرہ فنکشنلٹی ٹیسٹ ٹول',
        'mic_test_title': 'مائیک و وائس ریکگنیشن ٹیسٹ',
        'camera_test_title': 'کیمرہ فوٹو ٹیسٹ',
        'test_mic_btn': 'مائیک ٹیسٹ کریں',
        'test_camera_btn': 'کیمرہ ٹیسٹ کریں',
        'close': 'بند کریں',
    },
    'en': {
        'present': 'Present',
        'absent': 'Absent',
        'late': 'Late',
        'total_students': 'Total Students',
        'select': 'Select',
        'cap_uniform_books': 'Cap / Uniform / Books',
        'late_arrival': 'Late Arrival',
        'attendance_tap': 'Attendance\\n(Tap)',
        'student_father_header': 'Student Name\\nFather Name',
        'notifications_center': 'Notifications Center',
        'prev_attendance_saved': 'Previous attendance saved successfully.',
        'new_admin_msg': 'New message received from admin.',
        'student_attendance_list': 'Student Attendance List',
        'hardware_test_tool': 'Hardware Diagnostic Tools (Mic & Camera)',
        'mic_test_title': 'Microphone Speech-to-Text Test',
        'camera_test_title': 'Camera Capture Test',
        'test_mic_btn': 'Test Mic',
        'test_camera_btn': 'Test Camera',
        'close': 'Close',
    },
    'ar': {
        'present': 'حاضر',
        'absent': 'غائب',
        'late': 'متأخر',
        'total_students': 'إجمالي الطلاب',
        'select': 'تحديد',
        'cap_uniform_books': 'القبعة / الزي / الكتب',
        'late_arrival': 'وصول متأخر',
        'attendance_tap': 'الحضور\\n(انقر)',
        'student_father_header': 'اسم الطالب\\nاسم الأب',
        'notifications_center': 'مركز الإشعارات',
        'prev_attendance_saved': 'تم حفظ الحضور السابق بنجاح.',
        'new_admin_msg': 'تم استلام رسالة جديدة من المشرف.',
        'student_attendance_list': 'قائمة حضور الطلاب',
        'hardware_test_tool': 'أدوات فحص الأجهزة (الميكروفون والكاميرا)',
        'mic_test_title': 'اختبار التعرف على الصوت للميكروفون',
        'camera_test_title': 'اختبار التقاط الكاميرا',
        'test_mic_btn': 'اختبار الميكروفون',
        'test_camera_btn': 'اختبار الكاميرا',
        'close': 'إغلاق',
    },
    'hi': {
        'present': 'उपस्थित',
        'absent': 'अनुपस्थित',
        'late': 'विलंब',
        'total_students': 'कुल छात्र',
        'select': 'चुनें',
        'cap_uniform_books': 'टोपी / यूनिफॉर्म / पुस्तकें',
        'late_arrival': 'देर से आया',
        'attendance_tap': 'उपस्थिति\\n(टैप करें)',
        'student_father_header': 'छात्र का नाम\\nपिता का नाम',
        'notifications_center': 'सूचना केंद्र',
        'prev_attendance_saved': 'पिछली उपस्थिति सफलतापूर्वक सहेजी गई।',
        'new_admin_msg': 'एडमिन से नया संदेश प्राप्त हुआ।',
        'student_attendance_list': 'छात्र उपस्थिति सूची',
        'hardware_test_tool': 'हार्डवेयर डायग्नोस्टिक टूल्स (माइक और कैमरा)',
        'mic_test_title': 'माइक और वॉयस रिकग्निशन टेस्ट',
        'camera_test_title': 'कैमरा फोटो कैप्चर टेस्ट',
        'test_mic_btn': 'माइक टेस्ट करें',
        'test_camera_btn': 'कैमरा टेस्ट करें',
        'close': 'बंद करें',
    },
    'te': {
        'present': 'హాజరు',
        'absent': 'గైరుహాజరు',
        'late': 'ఆలస్యం',
        'total_students': 'మొత్తం విద్యార్థులు',
        'select': 'ఎంచుకోండి',
        'cap_uniform_books': 'టోపీ / యూనిఫాం / పుస్తకాలు',
        'late_arrival': 'ఆలస్యంగా వచ్చారు',
        'attendance_tap': 'హాజరు\\n(నొక్కండి)',
        'student_father_header': 'విద్యార్థి పేరు\\nతండ్రి పేరు',
        'notifications_center': 'నోటిఫికేషన్ కేంద్రం',
        'prev_attendance_saved': 'మునుపటి హాజరు విజయవంతంగా సేవ్ చేయబడింది.',
        'new_admin_msg': 'అడ్మిన్ నుండి కొత్త సందేశం వచ్చింది.',
        'student_attendance_list': 'విద్యార్థి హాజరు జాబితా',
        'hardware_test_tool': 'హార్డ్‌వేర్ డయాగ్నోస్టిక్ టూల్స్ (మైక్ & కెమెరా)',
        'mic_test_title': 'మైక్రోఫోన్ స్పీచ్-టు-టెక్స్ట్ టెస్ట్',
        'camera_test_title': 'కెమెరా క్యాప్చర్ టెస్ట్',
        'test_mic_btn': 'మైక్ టెస్ట్ చేయండి',
        'test_camera_btn': 'కెమెరా టెస్ట్ చేయండి',
        'close': 'మూసివేయి',
    },
    'kn': {
        'present': 'ಹಾಜರಿದ್ದಾರೆ',
        'absent': 'ಗೈರುಹಾಜರು',
        'late': 'ವಿಳಂಬ',
        'total_students': 'ಒಟ್ಟು ವಿದ್ಯಾರ್ಥಿಗಳು',
        'select': 'ಆರಿಸಿ',
        'cap_uniform_books': 'ಟೋಪಿ / ಯುನಿಫಾರ್ಮ್ / ಪುಸ್ತಕಗಳು',
        'late_arrival': 'ತಡವಾಗಿ ಬಂದರು',
        'attendance_tap': 'ಹಾಜರಾತಿ\\n(ಟ್ಯಾಪ್ ಮಾಡಿ)',
        'student_father_header': 'ವಿದ್ಯಾರ್ಥಿ ಹೆಸರು\\nತಂದೆಯ ಹೆಸರು',
        'notifications_center': 'ಸೂಚನಾ ಕೇಂದ್ರ',
        'prev_attendance_saved': 'ಹಿಂದಿನ ಹಾಜರಾತಿಯನ್ನು ಯಶಸ್ವಿಯಾಗಿ ಉಳಿಸಲಾಗಿದೆ.',
        'new_admin_msg': 'ಅಡ್ಮಿನ್‌ನಿಂದ പുതിയ ಸಂದೇಶ ಸ್ವೀಕರಿಸಲಾಗಿದೆ.',
        'student_attendance_list': 'ವಿದ್ಯಾರ್ಥಿಗಳ ಹಾಜರಾತಿ ಪಟ್ಟಿ',
        'hardware_test_tool': 'ಹಾರ್ಡ್‌ವೇರ್ ಡೈಾಗ್ನೋಸ್ಟಿಕ್ ಉಪಕರಣಗಳು (ಮೈಕ್ ಮತ್ತು ಕ್ಯಾಮೆರಾ)',
        'mic_test_title': 'ಮೈಕ್ರೋಫೋನ್ ಸ್ಪೀಚ್-ಟು-ಟೆಕ್ಸ್ಟ್ ಪರೀಕ್ಷೆ',
        'camera_test_title': 'ಕ್ಯಾಮೆರಾ ಕ್ಯಾಪ್ಚರ್ ಪರೀಕ್ಷೆ',
        'test_mic_btn': 'ಮೈಕ್ ಪರೀಕ್ಷಿಸಿ',
        'test_camera_btn': 'ಕ್ಯಾಮೆರಾ ಪರೀಕ್ಷಿಸಿ',
        'close': 'ಮುಚ್ಚಿ',
    },
    'ta': {
        'present': 'வந்துள்ளார்',
        'absent': 'வரவில்லை',
        'late': 'தாமதம்',
        'total_students': 'மொத்த மாணவர்கள்',
        'select': 'தேர்ந்தெடு',
        'cap_uniform_books': 'தொப்பி / சீருடை / புத்தகங்கள்',
        'late_arrival': 'தாமதமாக வந்தார்',
        'attendance_tap': 'வருகை\\n(தட்டவும்)',
        'student_father_header': 'மாணவர் பெயர்\\nதந்தையின் பெயர்',
        'notifications_center': 'அறிவிப்பு மையம்',
        'prev_attendance_saved': 'முந்தைய வருகை வெற்றிகரமாக சேமிக்கப்பட்டது.',
        'new_admin_msg': 'நிர்வாகியிடமிருந்து புதிய செய்தி வந்தது.',
        'student_attendance_list': 'மாணவர் வருகைப் பட்டியல்',
        'hardware_test_tool': 'வன்பொருள் கண்டறிதல் கருவிகள் (மைக் & கேமரா)',
        'mic_test_title': 'மைக்ரோஃபோன் பேச்சிலிருந்து உரை சோதனை',
        'camera_test_title': 'கேமரா பிடிப்பு சோதனை',
        'test_mic_btn': 'மைக்கை சோதிக்கவும்',
        'test_camera_btn': 'கேமராவை சோதிக்கவும்',
        'close': 'மூடு',
    },
    'ml': {
        'present': 'ഹാജർ',
        'absent': 'ഗൈർഹാജർ',
        'late': 'വൈകി',
        'total_students': 'ആകെ വിദ്യാർത്ഥികൾ',
        'select': 'തിരഞ്ഞെടുക്കുക',
        'cap_uniform_books': 'തൊപ്പി / യൂണിഫോം / പുസ്തകങ്ങൾ',
        'late_arrival': 'വൈകി വന്നു',
        'attendance_tap': 'ഹാജർ\\n(ടാപ്പ് ചെയ്യുക)',
        'student_father_header': 'വിദ്യാർത്ഥിയുടെ പേര്\\nപിതാവിന്റെ പേര്',
        'notifications_center': 'അറിയിപ്പ് കേന്ദ്രം',
        'prev_attendance_saved': 'മുൻ ഹാജർ വിജയകരമായി സേവ് ചെയ്തു.',
        'new_admin_msg': 'അഡ്മിനിൽ നിന്ന് പുതിയ സന്ദേശം ലഭിച്ചു.',
        'student_attendance_list': 'വിദ്യാർത്ഥി ഹാജർ പട്ടിക',
        'hardware_test_tool': 'ഹാർഡ്‌വെയർ ഡയഗ്നോസ്റ്റിക് ടൂളുകൾ (മൈക്കും ക്യാമറയും)',
        'mic_test_title': 'മൈക്രോഫോൺ സ്പീച്ച്-ടു-ടെക്സ്റ്റ് ടെസ്റ്റ്',
        'camera_test_title': 'ക്യാമറ ക്യാപ്ചർ ടെസ്റ്റ്',
        'test_mic_btn': 'മൈക്ക് ടെസ്റ്റ് ചെയ്യുക',
        'test_camera_btn': 'ക്യാമറ ടെസ്റ്റ് ചെയ്യുക',
        'close': 'അടയ്ക്കുക',
    }
}

languages = ['ur', 'en', 'ar', 'hi', 'te', 'kn', 'ta', 'ml']

for lang in languages:
    dict_map = new_keys[lang]
    # Find start of lang section
    target_str = f"'{lang}': {{"
    pos = content.find(target_str)
    if pos != -1:
        # Find 'app_title' line in this section
        app_title_pos = content.find("'app_title':", pos)
        if app_title_pos != -1:
            line_end = content.find("\n", app_title_pos)
            lines_to_add = []
            for k, v in dict_map.items():
                if f"'{k}':" not in content[pos:pos+5000]:
                    lines_to_add.append(f"      '{k}': '{v}',")
            if lines_to_add:
                add_block = "\n" + "\n".join(lines_to_add)
                content = content[:line_end] + add_block + content[line_end:]
                print(f"Added {len(lines_to_add)} keys to {lang}")

with open(filepath, "w", encoding="utf-8") as f:
    f.write(content)

print("Done updating app_localizations.dart")
