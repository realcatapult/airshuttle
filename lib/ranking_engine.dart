import 'dart:math';

import 'models.dart';

class TeamRatingDelta {
  TeamRatingDelta({
    required this.sideADelta,
    required this.sideBDelta,
    required this.expectedSideAWin,
  });

  final double sideADelta;
  final double sideBDelta;
  final double expectedSideAWin;
}

class RankingEngine {
  static const double minRating = 1.0;
  static const double maxRating = 16.5;

  static double expectedOutcome(double ratingA, double ratingB) {
    final exponent = (ratingB - ratingA) / 2.2;
    return 1.0 / (1.0 + pow(10, exponent));
  }

  static TeamRatingDelta computeDelta({
    required double averageSideARating,
    required double averageSideBRating,
    required bool sideAWon,
    required List<MatchSet> sets,
    required MatchFormat format,
  }) {
    final expectedA = expectedOutcome(averageSideARating, averageSideBRating);
    final actualA = sideAWon ? 1.0 : 0.0;
    final marginBoost = _marginBoost(sets);
    final baseK = format == MatchFormat.singles ? 0.64 : 0.52;
    final kFactor = baseK * marginBoost;
    final sideADelta = kFactor * (actualA - expectedA);

    return TeamRatingDelta(
      sideADelta: sideADelta,
      sideBDelta: -sideADelta,
      expectedSideAWin: expectedA,
    );
  }

  static double clampRating(double value) {
    return value.clamp(minRating, maxRating).toDouble();
  }

  static int reliabilityFromMatches(int totalMatches) {
    final estimate = 35 + (totalMatches * 8);
    if (estimate < 35) {
      return 35;
    }
    if (estimate > 100) {
      return 100;
    }
    return estimate;
  }

  static double _marginBoost(List<MatchSet> sets) {
    if (sets.isEmpty) {
      return 1.0;
    }

    var sideAPoints = 0;
    var sideBPoints = 0;
    for (final set in sets) {
      sideAPoints += set.sideA;
      sideBPoints += set.sideB;
    }

    final totalPoints = max(1, sideAPoints + sideBPoints);
    final absoluteMargin = (sideAPoints - sideBPoints).abs();
    final dominance = absoluteMargin / totalPoints;
    final marginBoost = 1.0 + (dominance * 0.8);
    return marginBoost.clamp(0.9, 1.8).toDouble();
  }
}
