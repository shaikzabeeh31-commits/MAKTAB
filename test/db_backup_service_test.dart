import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:maktab_management_system/db_backup_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'students_data': '[{"name": "Ali"}]',
      'subjects': ['Math', 'Science'],
    });
  });

  test('DbBackupService exports json string successfully', () async {
    final jsonStr = await DbBackupService.exportDatabaseJson();
    expect(jsonStr, isNotEmpty);
    
    final decoded = jsonDecode(jsonStr);
    expect(decoded['database_name'], 'maktab_management_system.db');
    
    final tables = decoded['tables'];
    expect(tables['students'].length, 1);
    expect(tables['subjects'].length, 2);
  });

  test('DbBackupService imports json string successfully', () async {
    final mockJson = '''
    {
      "tables": {
        "maktabs": ["Maktab 1"]
      }
    }
    ''';
    
    final result = await DbBackupService.importDatabaseJson(mockJson);
    expect(result, true);
    
    final prefs = await SharedPreferences.getInstance();
    final maktabs = prefs.getStringList('maktabs');
    expect(maktabs, ['Maktab 1']);
  });
}
