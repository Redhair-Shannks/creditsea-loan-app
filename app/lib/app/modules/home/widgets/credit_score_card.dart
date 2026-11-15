import 'dart:math' as math;

import '../../../core/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/loan_status_style.dart';
import '../../../data/models/user.dart';

/// Credit score gauge (bonus feature): repayments move the score up.
class CreditScoreCard extends StatelessWidget {
  const CreditScoreCard({super.key, required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final color = creditScoreColor(user.creditScore);
    final latest = user.creditHistory.firstOrNull;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 18, offset: Offset(0, 6))],
      ),
      child: Row(
        children: [
          SizedBox.square(
            dimension: 86,
            child: CustomPaint(
              painter: _GaugePainter(score: user.creditScore, color: color),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${user.creditScore}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                    const Text('of 900', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('CreditSea score', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(user.creditBand, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
                const SizedBox(height: 6),
                Text(
                  latest == null
                      ? 'Repay on time to grow your score and unlock higher limits.'
                      : '${latest.delta >= 0 ? '+' : ''}${latest.delta} · ${latest.reason}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  const _GaugePainter({required this.score, required this.color});

  final int score;
  final Color color;

  static const _start = math.pi * 0.75;
  static const _sweep = math.pi * 1.5;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final arc = rect.deflate(6);
    final track = Paint()
      ..color = AppColors.divider
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    final progress = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    final fraction = ((score - 300) / 600).clamp(0.0, 1.0);
    canvas
      ..drawArc(arc, _start, _sweep, false, track)
      ..drawArc(arc, _start, _sweep * fraction, false, progress);
  }

  @override
  bool shouldRepaint(_GaugePainter oldDelegate) => oldDelegate.score != score || oldDelegate.color != color;
}
