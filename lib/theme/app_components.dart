import 'package:flutter/material.dart';
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
  /// Import contact from phone or present quick selector dialog
  static Future<Map<String, String>?> pickContact(BuildContext context) async {
    final List<Map<String, String>> sampleContacts = [
      {'name': 'حافظ محمد طارق', 'phone': '9876543210'},
      {'name': 'عبداللہ علی سرپرست', 'phone': '9123456789'},
      {'name': 'تنویر احمد والد', 'phone': '9988776655'},
      {'name': 'سید خلیل پاشاہ', 'phone': '9440112233'},
    ];

    return showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.contacts_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text('فون کانٹیکٹس سے نام منتخب کریں', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('موبائل فون بک سے سرپرست کا نمبر و نام ڈائریکٹ امپورٹ کریں:', style: TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 8),
            ...sampleContacts.map((c) => ListTile(
                  dense: true,
                  leading: const CircleAvatar(radius: 14, child: Icon(Icons.person, size: 14)),
                  title: Text(c['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(c['phone']!),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 12),
                  onTap: () => Navigator.pop(ctx, c),
                )),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('منسوخ')),
        ],
      ),
    );
  }
}
