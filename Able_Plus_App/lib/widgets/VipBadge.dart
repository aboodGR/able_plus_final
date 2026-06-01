import 'package:flutter/material.dart';

const _vipGold = Color(0xFFFFC83D);
const _vipDarkGold = Color(0xFFB27600);

class VipBadge extends StatelessWidget {
  const VipBadge({super.key, this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 9,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFE690), _vipGold, Color(0xFFFFF2B6)],
        ),
        borderRadius: BorderRadius.circular(99),
        boxShadow: [
          BoxShadow(
            color: _vipGold.withOpacity(0.28),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.workspace_premium_rounded,
              size: compact ? 12 : 14, color: _vipDarkGold),
          const SizedBox(width: 3),
          Text(
            'VIP',
            style: TextStyle(
              color: _vipDarkGold,
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class VipGoldFrame extends StatelessWidget {
  const VipGoldFrame({
    super.key,
    required this.isVip,
    required this.child,
    this.radius = 24,
    this.padding = const EdgeInsets.all(1.4),
  });

  final bool isVip;
  final Widget child;
  final double radius;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    if (!isVip) return child;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFE9A6), _vipGold, Color(0xFFD99A16)],
        ),
        boxShadow: [
          BoxShadow(
            color: _vipGold.withOpacity(0.24),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
