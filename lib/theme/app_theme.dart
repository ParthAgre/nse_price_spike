import 'package:flutter/material.dart';

/// Gain/loss colours as theme tokens, so a design team can restyle them in
/// one place. Gains and losses always carry a sign as well (never colour
/// alone).
@immutable
class GainLossColors extends ThemeExtension<GainLossColors> {
  final Color gain;
  final Color loss;
  final Color neutral;

  const GainLossColors({
    required this.gain,
    required this.loss,
    required this.neutral,
  });

  static GainLossColors of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<GainLossColors>() ??
        GainLossColors(
          gain: const Color(0xFF1B7F3B),
          loss: theme.colorScheme.error,
          neutral: theme.colorScheme.onSurfaceVariant,
        );
  }

  /// Colour for a signed amount; neutral for zero or unknown.
  Color forSign(num? value) {
    if (value == null || value == 0) return neutral;
    return value > 0 ? gain : loss;
  }

  @override
  GainLossColors copyWith({Color? gain, Color? loss, Color? neutral}) =>
      GainLossColors(
        gain: gain ?? this.gain,
        loss: loss ?? this.loss,
        neutral: neutral ?? this.neutral,
      );

  @override
  GainLossColors lerp(GainLossColors? other, double t) {
    if (other == null) return this;
    return GainLossColors(
      gain: Color.lerp(gain, other.gain, t)!,
      loss: Color.lerp(loss, other.loss, t)!,
      neutral: Color.lerp(neutral, other.neutral, t)!,
    );
  }
}

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: Colors.indigo);
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    extensions: [
      GainLossColors(
        gain: const Color(0xFF1B7F3B),
        loss: scheme.error,
        neutral: scheme.onSurfaceVariant,
      ),
    ],
  );
}

/// Allocation colours per asset class, in display order.
List<Color> allocationColors(ColorScheme scheme) => [
  scheme.primary,
  scheme.tertiary,
  scheme.secondary,
];
