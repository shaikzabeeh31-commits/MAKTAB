import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_localizations.dart';

class CreateClassGroupScreen extends StatefulWidget {
  final List<Map<String, dynamic>> students;
  final LanguageController languageController;
  final Function(List<Map<String, dynamic>> updatedStudents) onSave;

  const CreateClassGroupScreen({
    super.key,
    required this.students,
    required this.languageController,
    required this.onSave,
  });

  @override
  State<CreateClassGroupScreen> createState() => _CreateClassGroupScreenState();
}

class _CreateClassGroupScreenState extends State<CreateClassGroupScreen> {
  final _groupNameController = TextEditingController();
  final _searchController = TextEditingController();

  final List<String> _availableTeachers = [
    'حافظ احمد حسن',
    'استاد محمد عمران',
    'مولانا محمود الحسن',
    'قاری عبدالرحمٰن',
    'مولانا ساجد علی',
  ];

  late String _selectedTeacher;
  Set<String> _selectedStudentPhones = {};
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedTeacher = _availableTeachers.first;
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = widget.languageController.locale.languageCode != 'en';
    final filteredStudents = widget.students.where((student) {
      final name = (student['name'] ?? '').toString().toLowerCase();
      final father = (student['fatherName'] ?? '').toString().toLowerCase();
      final phone = (student['fatherPhone'] ?? '').toString().toLowerCase();
      final q = _searchQuery.toLowerCase();
      return name.contains(q) || father.contains(q) || phone.contains(q);
    }).toList();

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text('کلاس و گروپ تشکیل دیں (Create Group)'),
          backgroundColor: const Color(0xFF074E32),
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner Step 1
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: Colors.white,
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: Color(0xFF074E32),
                            child: Text('1', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                          SizedBox(width: 10),
                          Text(
                            'گروپ کا نام اور استاد کا انتخاب (Group & Teacher)',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _groupNameController,
                        decoration: InputDecoration(
                          labelText: 'گروپ / کلاس کا نام (e.g. حفظ گروپ A)',
                          prefixIcon: const Icon(Icons.class_rounded, color: Color(0xFF074E32)),
                          filled: true,
                          fillColor: const Color(0xFFF1F5F9),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedTeacher,
                        decoration: InputDecoration(
                          labelText: 'استاد کا انتخاب کریں (Select Assigned Teacher)',
                          prefixIcon: const Icon(Icons.person_rounded, color: Color(0xFF074E32)),
                          filled: true,
                          fillColor: const Color(0xFFF1F5F9),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: _availableTeachers
                            .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedTeacher = val;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Banner Step 2: Select Students
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: Colors.white,
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: Color(0xFF074E32),
                                child: Text('2', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                              SizedBox(width: 10),
                              Text(
                                'طلبہ کا انتخاب کریں (Select Students)',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ],
                          ),
                          Chip(
                            backgroundColor: Colors.green.shade100,
                            label: Text(
                              'منتخب: ${_selectedStudentPhones.length}',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF074E32)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _searchController,
                        onChanged: (v) => setState(() => _searchQuery = v),
                        decoration: InputDecoration(
                          hintText: 'نام، والد کے نام سے تلاش کریں...',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: const Color(0xFFF1F5F9),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _selectedStudentPhones = filteredStudents
                                    .map((s) => (s['fatherPhone'] ?? s['name']).toString())
                                    .toSet();
                              });
                            },
                            icon: const Icon(Icons.select_all, size: 18),
                            label: const Text('تمام منتخب کریں (Select All)'),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _selectedStudentPhones.clear();
                              });
                            },
                            icon: const Icon(Icons.deselect, size: 18),
                            label: const Text('انتخاب ختم کریں (Clear)'),
                          ),
                        ],
                      ),
                      const Divider(),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredStudents.length,
                        itemBuilder: (context, index) {
                          final student = filteredStudents[index];
                          final phoneKey = (student['fatherPhone'] ?? student['name']).toString();
                          final isSelected = _selectedStudentPhones.contains(phoneKey);

                          return CheckboxListTile(
                            value: isSelected,
                            activeColor: const Color(0xFF074E32),
                            onChanged: (checked) {
                              setState(() {
                                if (checked == true) {
                                  _selectedStudentPhones.add(phoneKey);
                                } else {
                                  _selectedStudentPhones.remove(phoneKey);
                                }
                              });
                            },
                            title: Text(
                              student['name'] ?? '',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              'والد: ${student['fatherName'] ?? '-'} | موجودہ گروپ: ${student['group'] ?? student['className'] ?? '-'} | استاد: ${student['teacherName'] ?? '-'}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            secondary: CircleAvatar(
                              backgroundColor: isSelected ? Colors.green.shade700 : Colors.grey.shade300,
                              child: Text(
                                student['name'] != null && student['name'].toString().isNotEmpty
                                    ? student['name'].toString()[0]
                                    : 'S',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Create Group Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF074E32),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.check_circle_rounded, size: 22),
                  label: const Text(
                    'گروپ تشکیل دیں اور استاد کو Assign کریں (Create Group & Assign Teacher)',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () async {
                    final groupName = _groupNameController.text.trim();
                    if (groupName.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('براہ کرم گروپ یا کلاس کا نام لکھیں'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    if (_selectedStudentPhones.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('براہ کرم کم از کم ایک طالب علم منتخب کریں'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    // Update student list with assigned group and teacher
                    final updatedStudents = widget.students.map((st) {
                      final phoneKey = (st['fatherPhone'] ?? st['name']).toString();
                      if (_selectedStudentPhones.contains(phoneKey)) {
                        final copy = Map<String, dynamic>.from(st);
                        copy['group'] = groupName;
                        copy['className'] = groupName;
                        copy['teacherName'] = _selectedTeacher;
                        return copy;
                      }
                      return st;
                    }).toList();

                    // Save Group definition to SharedPreferences
                    final prefs = await SharedPreferences.getInstance();
                    final existingGroupsStr = prefs.getStringList('maktab_group_names') ?? [];
                    if (!existingGroupsStr.contains(groupName)) {
                      existingGroupsStr.add(groupName);
                      await prefs.setStringList('maktab_group_names', existingGroupsStr);
                    }

                    await widget.onSave(updatedStudents);

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('گروپ ($groupName) کامیابی سے تشکیل دے دیا گیا اور $_selectedTeacher کے ٹیچر پورٹل میں بھیج دیا گیا!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      Navigator.pop(context);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
