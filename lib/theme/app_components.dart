import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart' hide PermissionStatus;
import 'app_colors.dart';
import 'app_spacing.dart';

class StatCardWidget extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const StatCardWidget({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: AppSpacing.radiusSm,
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Colors.black87),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class StatusChipWidget extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const StatusChipWidget({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class EmptyStateWidget extends StatelessWidget {
  final String message;
  final IconData icon;
  final VoidCallback? onAction;
  final String? actionLabel;

  const EmptyStateWidget({
    super.key,
    required this.message,
    this.icon = Icons.inbox_rounded,
    this.onAction,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.paddingLg,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add, size: 18),
                label: Text(actionLabel!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ContactPickerHelper {
  /// Import actual contact linked by phone number or select from student contacts
  static Future<Map<String, String>?> pickContact(BuildContext context, [List<Map<String, dynamic>>? studentsList]) async {
    try {
      final perm = await FlutterContacts.permissions.request(PermissionType.readWrite);
      if (perm == PermissionStatus.granted || perm == PermissionStatus.limited) {
        final contact = await FlutterContacts.native.showPicker(
          properties: {ContactProperty.phone, ContactProperty.name},
        );
        if (contact != null) {
          final cName = (contact.displayName ?? '${contact.name?.first ?? ''} ${contact.name?.last ?? ''}').trim();
          if (contact.phones.isNotEmpty) {
            return {
              'name': cName.isNotEmpty ? cName : 'Contact',
              'phone': contact.phones.first.number,
            };
          }
        }
      }
    } catch (_) {}

    final Map<String, Map<String, String>> actualContactsMap = {};

    if (studentsList != null && studentsList.isNotEmpty) {
      for (final st in studentsList) {
        final fName = st['fatherName']?.toString().trim() ?? '';
        final fPhone = st['fatherPhone']?.toString().trim() ?? '';
        final sName = st['name']?.toString().trim() ?? '';
        if (fPhone.isNotEmpty) {
          final displayName = fName.isNotEmpty ? '$fName (والد $sName)' : 'والد $sName';
          actualContactsMap[fPhone] = {'name': displayName, 'phone': fPhone};
        }
      }
    }

    final List<Map<String, String>> actualContacts = actualContactsMap.values.toList();
    final searchCtrl = TextEditingController();
    final customNameCtrl = TextEditingController();
    final customPhoneCtrl = TextEditingController();
    List<Map<String, String>> filtered = List.from(actualContacts);

    return showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.contacts_rounded, color: AppColors.primary),
                SizedBox(width: 8),
                Text('کانٹیکٹس کا انتخاب کریں (Select Contact)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (actualContacts.isNotEmpty) ...[
                      TextField(
                        controller: searchCtrl,
                        decoration: InputDecoration(
                          hintText: 'نام یا نمبر سے تلاش کریں...',
                          prefixIcon: const Icon(Icons.search_rounded, size: 20),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onChanged: (query) {
                          setDlgState(() {
                            filtered = actualContacts.where((c) =>
                              c['name']!.toLowerCase().contains(query.toLowerCase()) ||
                              c['phone']!.contains(query)
                            ).toList();
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 180),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: filtered.length,
                          itemBuilder: (context, idx) {
                            final c = filtered[idx];
                            return ListTile(
                              dense: true,
                              leading: const CircleAvatar(radius: 14, child: Icon(Icons.person, size: 14)),
                              title: Text(c['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                              subtitle: Text(c['phone']!, style: const TextStyle(fontSize: 11)),
                              trailing: const Icon(Icons.check_circle_outline_rounded, size: 16, color: Colors.green),
                              onTap: () => Navigator.pop(ctx, c),
                            );
                          },
                        ),
                      ),
                      const Divider(height: 20),
                    ],
                    const Text('یا نیا حقیقی نمبر اور نام درج کریں:', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: customNameCtrl,
                      decoration: InputDecoration(
                        labelText: 'نام (Contact Name)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: customPhoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'موبائل نمبر (Phone Number)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('منسوخ')),
              FilledButton(
                onPressed: () {
                  final p = customPhoneCtrl.text.trim();
                  final n = customNameCtrl.text.trim();
                  if (p.isNotEmpty) {
                    Navigator.pop(ctx, {'name': n.isNotEmpty ? n : 'والد / سرپرست', 'phone': p});
                  }
                },
                child: const Text('انتخاب کریں'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class MaktabLogo extends StatelessWidget {
  final double size;
  const MaktabLogo({super.key, this.size = 120});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(size * 0.2),
        gradient: const LinearGradient(
          colors: [Color(0xFF042E1B), Color(0xFF0A4F30)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0xFFD4AF37), width: size * 0.04),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Center(
        child: CustomPaint(
          size: Size(size * 0.8, size * 0.8),
          painter: _LogoPainter(),
        ),
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Golden Paint
    final goldPaint = Paint()
      ..color = const Color(0xFFD4AF37)
      ..style = PaintingStyle.fill;

    final goldStroke = Paint()
      ..color = const Color(0xFFD4AF37)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.03;

    // 1. Crescent & Star at top
    final crescentPath = Path()
      ..addOval(Rect.fromCircle(center: Offset(w * 0.5, h * 0.22), radius: w * 0.08));
    final crescentCut = Path()
      ..addOval(Rect.fromCircle(center: Offset(w * 0.54, h * 0.2), radius: w * 0.08));
    final crescentFinal = Path.combine(PathOperation.difference, crescentPath, crescentCut);
    canvas.drawPath(crescentFinal, goldPaint);

    // Star
    final starPath = Path();
    final centerX = w * 0.5;
    final centerY = h * 0.11;
    final starSize = w * 0.025;
    for (int i = 0; i < 5; i++) {
      final double angle = (i * 4 * 3.14159) / 5 - 3.14159 / 2;
      final x = centerX + starSize * 0.5 * math.cos(angle);
      final y = centerY + starSize * 0.5 * math.sin(angle);
      if (i == 0) {
        starPath.moveTo(x, y);
      } else {
        starPath.lineTo(x, y);
      }
    }
    starPath.close();
    canvas.drawPath(starPath, goldPaint);

    // 2. Dome
    final domePath = Path()
      ..moveTo(w * 0.3, h * 0.6)
      ..quadraticBezierTo(w * 0.3, h * 0.35, w * 0.5, h * 0.25)
      ..quadraticBezierTo(w * 0.7, h * 0.35, w * 0.7, h * 0.6)
      ..lineTo(w * 0.3, h * 0.6);
    canvas.drawPath(domePath, goldPaint);

    // Dome base
    canvas.drawRect(Rect.fromLTRB(w * 0.28, h * 0.6, w * 0.72, h * 0.63), goldPaint);

    // Dome tip
    canvas.drawRect(Rect.fromLTRB(w * 0.485, h * 0.2, w * 0.515, h * 0.25), goldPaint);

    // 3. Minarets (left & right)
    // Left Minaret
    canvas.drawRect(Rect.fromLTRB(w * 0.22, h * 0.45, w * 0.26, h * 0.63), goldPaint);
    final leftCap = Path()
      ..moveTo(w * 0.22, h * 0.45)
      ..lineTo(w * 0.24, h * 0.41)
      ..lineTo(w * 0.26, h * 0.45)
      ..close();
    canvas.drawPath(leftCap, goldPaint);

    // Right Minaret
    canvas.drawRect(Rect.fromLTRB(w * 0.74, h * 0.45, w * 0.78, h * 0.63), goldPaint);
    final rightCap = Path()
      ..moveTo(w * 0.74, h * 0.45)
      ..lineTo(w * 0.76, h * 0.41)
      ..lineTo(w * 0.78, h * 0.45)
      ..close();
    canvas.drawPath(rightCap, goldPaint);

    // 4. Open Book (at bottom)
    final bookPath = Path()
      ..moveTo(w * 0.1, h * 0.8)
      ..quadraticBezierTo(w * 0.3, h * 0.68, w * 0.5, h * 0.8)
      ..quadraticBezierTo(w * 0.7, h * 0.68, w * 0.9, h * 0.8)
      ..lineTo(w * 0.9, h * 0.84)
      ..quadraticBezierTo(w * 0.7, h * 0.72, w * 0.5, h * 0.84)
      ..quadraticBezierTo(w * 0.3, h * 0.72, w * 0.1, h * 0.84)
      ..close();
    canvas.drawPath(bookPath, goldPaint);

    // Book center line
    canvas.drawLine(Offset(w * 0.5, h * 0.8), Offset(w * 0.5, h * 0.84), goldStroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
