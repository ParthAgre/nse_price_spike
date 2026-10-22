import 'package:flutter/material.dart';
import 'package:nse_price_spike/constants/strings.dart';
import 'package:nse_price_spike/theme/app_theme.dart';
import 'package:nse_price_spike/utils/investments_summary.dart';
import 'package:nse_price_spike/utils/money.dart';
import 'package:nse_price_spike/widgets/labels.dart';

/// One horizontal stacked bar of current value by asset class, with a
/// legend giving each class's share.
class AllocationBar extends StatelessWidget {
  /// Class → share of current value (0–1), in display order.
  final Map<AssetClass, double> shares;

  const AllocationBar({super.key, required this.shares});

  @override
  Widget build(BuildContext context) {
    final colors = allocationColors(Theme.of(context).colorScheme);
    final entries = shares.entries.toList();
    Color colorOf(AssetClass c) => colors[c.index % colors.length];
    final legend = [
      for (final e in entries)
        '${assetClassLabel(e.key)} ${formatShare(e.value)}',
    ];
    return Semantics(
      label: '${S.allocationLabel}: ${legend.join(', ')}',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 10,
            width: double.infinity,
            child: CustomPaint(
              key: const Key('allocationBar'),
              painter: _BarPainter([
                for (final e in entries) (e.value, colorOf(e.key)),
              ]),
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 12,
            runSpacing: 2,
            children: [
              for (var i = 0; i < entries.length; i++)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: colorOf(entries[i].key),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      legend[i],
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BarPainter extends CustomPainter {
  final List<(double, Color)> segments;

  _BarPainter(this.segments);

  @override
  void paint(Canvas canvas, Size size) {
    final radius = Radius.circular(size.height / 2);
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(Offset.zero & size, radius));
    var x = 0.0;
    for (final (share, color) in segments) {
      final w = size.width * share;
      canvas.drawRect(
        Rect.fromLTWH(x, 0, w, size.height),
        Paint()..color = color,
      );
      x += w;
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BarPainter old) =>
      old.segments.length != segments.length ||
      [for (var i = 0; i < segments.length; i++) old.segments[i] != segments[i]]
          .any((changed) => changed);
}
