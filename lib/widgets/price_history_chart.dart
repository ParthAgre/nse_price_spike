import 'package:flutter/material.dart';
import 'package:nse_price_spike/constants/strings.dart';
import 'package:nse_price_spike/utils/money.dart';
import 'package:nse_price_spike/utils/trading_day.dart';

/// A small line of daily closes, oldest to newest. Renders nothing with
/// fewer than 2 points.
class PriceHistoryChart extends StatelessWidget {
  /// (trade date, close in paise), any order.
  final List<(DateTime, int)> points;

  const PriceHistoryChart({super.key, required this.points});

  @override
  Widget build(BuildContext context) {
    if (points.length < 2) return const SizedBox.shrink();
    final sorted = [...points]..sort((a, b) => a.$1.compareTo(b.$1));
    final theme = Theme.of(context);
    final closes = sorted.map((p) => p.$2);
    final low = closes.reduce((a, b) => a < b ? a : b);
    final high = closes.reduce((a, b) => a > b ? a : b);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Semantics(
      label:
          '${S.priceHistory}: ${formatRupees(sorted.first.$2)} on '
          '${formatDisplayDate(sorted.first.$1)} to '
          '${formatRupees(sorted.last.$2)} on '
          '${formatDisplayDate(sorted.last.$1)}',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(S.priceHistory, style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          SizedBox(
            height: 96,
            child: CustomPaint(
              key: const Key('priceChart'),
              painter: _LinePainter(
                [for (final p in sorted) p.$2],
                theme.colorScheme.primary,
                theme.colorScheme.outlineVariant,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(formatDisplayDate(sorted.first.$1), style: muted),
              ),
              Text(
                '${formatRupees(low)} – ${formatRupees(high)}',
                style: muted,
              ),
              Expanded(
                child: Text(
                  formatDisplayDate(sorted.last.$1),
                  style: muted,
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  final List<int> closes;
  final Color line;
  final Color grid;

  _LinePainter(this.closes, this.line, this.grid);

  @override
  void paint(Canvas canvas, Size size) {
    final low = closes.reduce((a, b) => a < b ? a : b);
    final high = closes.reduce((a, b) => a > b ? a : b);
    final span = high == low ? 1 : high - low;
    const pad = 4.0;
    final h = size.height - 2 * pad;
    Offset at(int i) => Offset(
      size.width * i / (closes.length - 1),
      pad + h - h * (closes[i] - low) / span,
    );

    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, pad), Offset(size.width, pad), gridPaint);
    canvas.drawLine(
      Offset(0, size.height - pad),
      Offset(size.width, size.height - pad),
      gridPaint,
    );

    final path = Path()..moveTo(at(0).dx, at(0).dy);
    for (var i = 1; i < closes.length; i++) {
      path.lineTo(at(i).dx, at(i).dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = line
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawCircle(at(closes.length - 1), 3, Paint()..color = line);
  }

  @override
  bool shouldRepaint(_LinePainter old) =>
      old.line != line || old.grid != grid || !_sameList(old.closes, closes);

  static bool _sameList(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
