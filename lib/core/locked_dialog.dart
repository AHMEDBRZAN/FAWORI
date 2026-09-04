import 'package:flutter/material.dart';
import 'app_settings.dart';
import 'theme.dart';

void showLockedDialog(BuildContext context, AppSettings s) => showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 70, height: 70,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x33E8A33D),
              ),
              child: const Icon(Icons.lock_rounded, color: AppColors.orange, size: 34),
            ),
            const SizedBox(height: 16),
            Text(s.tr('lockedTitle'),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(s.tr('lockedMsg'),
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade400)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                onPressed: () => Navigator.pop(context),
                child: Text(s.tr('ok')),
              ),
            ),
          ]),
        ),
      ),
    );
