import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class DbBackupService {
  static const String _studentsKey = 'students_data';
  static const String _subjectsKey = 'subjects';
  static const String _maktabsKey = 'maktabs';
  static const String _classesKey = 'classes';
  static const String _teachersKey = 'teachers';
  static const String _auditLogsKey = 'audit_logs';

  /// Export entire Maktab SQLite/SharedPreferences Database to a structured JSON string (.db.json format)
  static Future<String> exportDatabaseJson() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> dbDump = {
      'database_name': 'maktab_management_system.db',
      'export_timestamp': DateTime.now().toIso8601String(),
      'version': '2.5.0',
      'tables': {
        'students': jsonDecode(prefs.getString(_studentsKey) ?? '[]'),
        'subjects': prefs.getStringList(_subjectsKey) ?? [],
        'maktabs': prefs.getStringList(_maktabsKey) ?? [],
        'classes': prefs.getStringList(_classesKey) ?? [],
        'teachers': prefs.getStringList(_teachersKey) ?? [],
        'audit_logs': jsonDecode(prefs.getString(_auditLogsKey) ?? '[]'),
      }
    };
    return const JsonEncoder.withIndent('  ').convert(dbDump);
  }

  /// Import database JSON string (.db.json format) into storage
  static Future<bool> importDatabaseJson(String jsonString) async {
    try {
      final Map<String, dynamic> dbDump = jsonDecode(jsonString);
      final tables = dbDump['tables'] as Map<String, dynamic>?;
      if (tables == null) return false;

      final prefs = await SharedPreferences.getInstance();

      if (tables.containsKey('students')) {
        await prefs.setString(_studentsKey, jsonEncode(tables['students']));
      }
      if (tables.containsKey('subjects')) {
        await prefs.setStringList(_subjectsKey, List<String>.from(tables['subjects']));
      }
      if (tables.containsKey('maktabs')) {
        await prefs.setStringList(_maktabsKey, List<String>.from(tables['maktabs']));
      }
      if (tables.containsKey('classes')) {
        await prefs.setStringList(_classesKey, List<String>.from(tables['classes']));
      }
      if (tables.containsKey('teachers')) {
        await prefs.setStringList(_teachersKey, List<String>.from(tables['teachers']));
      }
      if (tables.containsKey('audit_logs')) {
        await prefs.setString(_auditLogsKey, jsonEncode(tables['audit_logs']));
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Add audit log entry
  static Future<void> addAuditLog(String action, String details) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<dynamic> logs = jsonDecode(prefs.getString(_auditLogsKey) ?? '[]');
      logs.insert(0, {
        'timestamp': DateTime.now().toIso8601String(),
        'action': action,
        'details': details,
      });
      await prefs.setString(_auditLogsKey, jsonEncode(logs.take(100).toList()));
    } catch (_) {}
  }
}
