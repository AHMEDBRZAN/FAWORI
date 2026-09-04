import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_settings.dart';
import '../core/theme.dart';

class BottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  const BottomNav({super.key, required this.index, required this.onTap});

  static const _icons = [
    Icons.home_rounded, Icons.grid_view_rounded,
    Icons.account_balance_wallet_rounded, Icons.favorite_rounded, Icons.person_rounded,
  ];
  static const _keys = ['home', 'products', 'wallet', 'favorites', 'settings'];

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppSettings>();
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: Colors.grey.shade800)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: List.generate(_icons.length, (i) {
              final active = i == index;
              final locked = s.isGuest && (i == 2 || i == 3);
              final color = active ? AppColors.orange : Colors.grey;
              return Expanded(
                child: InkWell(
                  onTap: () => onTap(i),
                  child: Opacity(
                    opacity: locked ? 0.45 : 1,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 24, height: 3,
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            color: active ? AppColors.orange : Colors.transparent,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(_icons[i], color: color, size: 24),
                            if (locked)
                              Positioned(
                                bottom: -2, right: -7,
                                child: Icon(Icons.lock_rounded,
                                    size: 12, color: Colors.grey.shade400),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(s.tr(_keys[i]),
                            style: TextStyle(color: color, fontSize: 12,
                                fontWeight: active ? FontWeight.w700 : FontWeight.w400)),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
