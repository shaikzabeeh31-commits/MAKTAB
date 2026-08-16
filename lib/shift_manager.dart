import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MaktabShift {
  final String id;
  final String name;
  final String startTime;
  final String endTime;
  final bool archived;

  const MaktabShift({
    required this.id,
    required this.name,
    this.startTime = '',
    this.endTime = '',
    this.archived = false,
  });

  factory MaktabShift.fromMap(Map<String, dynamic> map) => MaktabShift(
        id: map['id']?.toString() ?? '',
        name: map['name']?.toString() ?? '',
        startTime: map['startTime']?.toString() ?? '',
        endTime: map['endTime']?.toString() ?? '',
        archived: map['archived'] == true,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'startTime': startTime,
        'endTime': endTime,
        'archived': archived,
      };

  MaktabShift copyWith({
    String? name,
    String? startTime,
    String? endTime,
    bool? archived,
  }) =>
      MaktabShift(
        id: id,
        name: name ?? this.name,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        archived: archived ?? this.archived,
      );
}

class ShiftStore {
  static const String storageKey = 'maktab_custom_shifts_v1';

  static List<MaktabShift> get defaults => const [
        MaktabShift(id: 'morning', name: 'صبح'),
        MaktabShift(id: 'afternoon', name: 'دوپہر'),
        MaktabShift(id: 'evening', name: 'شام'),
        MaktabShift(id: 'night', name: 'رات'),
      ];

  static Future<List<MaktabShift>> load({bool includeArchived = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    List<MaktabShift> shifts;
    try {
      shifts = raw == null
          ? defaults
          : (jsonDecode(raw) as List)
              .map((item) => MaktabShift.fromMap(
                    Map<String, dynamic>.from(item as Map),
                  ))
              .where((shift) => shift.id.isNotEmpty && shift.name.isNotEmpty)
              .toList();
    } catch (_) {
      shifts = defaults;
    }
    if (shifts.isEmpty) shifts = defaults;
    return includeArchived
        ? shifts
        : shifts.where((shift) => !shift.archived).toList();
  }

  static Future<void> save(List<MaktabShift> shifts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      storageKey,
      jsonEncode(shifts.map((shift) => shift.toMap()).toList()),
    );
  }

  static String legacyId(String value) {
    final text = value.trim().toLowerCase();
    if (text == 'morning' || text == 'subah' || text == 'صبح') {
      return 'morning';
    }
    if (text == 'afternoon' || text == 'dopahar' || text == 'دوپہر') {
      return 'afternoon';
    }
    if (text == 'evening' || text == 'sham' || text == 'شام') {
      return 'evening';
    }
    if (text == 'night' || text == 'raat' || text == 'رات') return 'night';
    return value.trim();
  }

  static Set<String> studentShiftIds(Map<String, dynamic> student) {
    final values = student['shiftIds'] ?? student['shifts'];
    if (values is List) {
      return values
          .map((value) => legacyId(value.toString()))
          .where((value) => value.isNotEmpty)
          .toSet();
    }
    final legacy = (student['shiftId'] ?? student['shift'] ?? '').toString();
    final id = legacyId(legacy);
    return {if (id.isNotEmpty) id else 'morning'};
  }
}

Future<bool> showShiftManager(BuildContext context) async {
  List<MaktabShift> shifts = await ShiftStore.load(includeArchived: true);
  if (!context.mounted) return false;
  bool changed = false;

  Future<MaktabShift?> editShift(
    BuildContext dialogContext, {
    MaktabShift? existing,
  }) async {
    final name = TextEditingController(text: existing?.name ?? '');
    final start = TextEditingController(text: existing?.startTime ?? '');
    final end = TextEditingController(text: existing?.endTime ?? '');
    final result = await showDialog<MaktabShift>(
      context: dialogContext,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'نئی شفٹ بنائیں' : 'شفٹ تبدیل کریں'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              autofocus: true,
              textDirection: TextDirection.rtl,
              decoration: const InputDecoration(labelText: 'شفٹ کا نام'),
            ),
            TextField(
              controller: start,
              decoration: const InputDecoration(labelText: 'شروع کا وقت'),
            ),
            TextField(
              controller: end,
              decoration: const InputDecoration(labelText: 'اختتام کا وقت'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('منسوخ'),
          ),
          FilledButton(
            onPressed: () {
              if (name.text.trim().isEmpty) return;
              Navigator.pop(
                ctx,
                MaktabShift(
                  id: existing?.id ??
                      'shift_${DateTime.now().microsecondsSinceEpoch}',
                  name: name.text.trim(),
                  startTime: start.text.trim(),
                  endTime: end.text.trim(),
                  archived: existing?.archived ?? false,
                ),
              );
            },
            child: const Text('محفوظ کریں'),
          ),
        ],
      ),
    );
    name.dispose();
    start.dispose();
    end.dispose();
    return result;
  }

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (ctx, setLocalState) => AlertDialog(
        title: const Text('شفٹوں کا انتظام'),
        content: SizedBox(
          width: 430,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: shifts.length,
            itemBuilder: (_, index) {
              final shift = shifts[index];
              return ListTile(
                enabled: !shift.archived,
                leading: const Icon(Icons.schedule_rounded),
                title: Text(shift.name),
                subtitle: shift.startTime.isEmpty && shift.endTime.isEmpty
                    ? null
                    : Text('${shift.startTime} تا ${shift.endTime}'),
                trailing: Wrap(
                  children: [
                    IconButton(
                      tooltip: 'تبدیل کریں',
                      icon: const Icon(Icons.edit_rounded),
                      onPressed: shift.archived
                          ? null
                          : () async {
                              final updated = await editShift(
                                dialogContext,
                                existing: shift,
                              );
                              if (updated == null) return;
                              shifts[index] = updated;
                              await ShiftStore.save(shifts);
                              changed = true;
                              setLocalState(() {});
                            },
                    ),
                    IconButton(
                      tooltip: shift.archived ? 'بحال کریں' : 'Archive کریں',
                      icon: Icon(shift.archived
                          ? Icons.unarchive_rounded
                          : Icons.archive_rounded),
                      onPressed: () async {
                        shifts[index] =
                            shift.copyWith(archived: !shift.archived);
                        await ShiftStore.save(shifts);
                        changed = true;
                        setLocalState(() {});
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('نئی شفٹ'),
            onPressed: () async {
              final created = await editShift(dialogContext);
              if (created == null) return;
              shifts.add(created);
              await ShiftStore.save(shifts);
              changed = true;
              setLocalState(() {});
            },
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('مکمل'),
          ),
        ],
      ),
    ),
  );
  return changed;
}
