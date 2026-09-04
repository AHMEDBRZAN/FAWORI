import 'package:flutter/material.dart';
import '../core/theme.dart';

class BottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  const BottomNav({super.key, required this.index, required this.onTap});

  static const _icons = [
    Icons.home_rounded, Icons.grid_view_rounded,
    Icons.account_balance_wallet_rounded, Icons.favorite_rounded, Icons.person_rounded,
  ];
  static const _labels = ['الرئيسية', 'المنتجات', 'المحفظة', 'المفضلة', 'الإعدادات'];

  @override
  Widget build(BuildContext context) {
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
              final color = active ? AppColors.orange : Colors.grey;
              return Expanded(
                child: InkWell(
                  onTap: () => onTap(i),
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
                      Icon(_icons[i], color: color, size: 24),
                      const SizedBox(height: 4),
                      Text(_labels[i],
                          style: TextStyle(color: color, fontSize: 12,
                              fontWeight: active ? FontWeight.w700 : FontWeight.w400)),
                    ],
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
