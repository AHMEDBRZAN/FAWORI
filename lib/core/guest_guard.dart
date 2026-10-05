import 'package:flutter/material.dart';
import 'theme.dart';

/// ✅ قيود الضيوف: حوار قفل موحّد + شارة قفل صغيرة
class GuestGuard {
  static Future<void> lock(
    BuildContext context, {
    required String title,
    required String message,
    VoidCallback? onLogin,
    String? loginLabel,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.orange.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_rounded,
                  color: AppColors.orange, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 16)),
            ),
          ],
        ),
        content: Text(message,
            style: const TextStyle(
                fontWeight: FontWeight.w700, height: 1.7, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('حسناً'),
          ),
          if (onLogin != null)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                onLogin();
              },
              icon: const Icon(Icons.login_rounded, size: 18),
              label: Text(loginLabel ?? 'تسجيل الدخول'),
            ),
        ],
      ),
    );
  }

  /// ✅ شارة قفل حمراء صغيرة تُوضع فوق الأيقونات المقفلة
  static Widget badge({double size = 14}) {
    return Container(
      padding: EdgeInsets.all(size * 0.28),
      decoration: BoxDecoration(
        color: Colors.red,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Icon(Icons.lock_rounded,
          color: Colors.white, size: size * 0.62),
    );
  }
}
