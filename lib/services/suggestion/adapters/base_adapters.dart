import 'dart:math';
import 'package:vietlott_data/models/lottery_draw_model.dart';

abstract class BaseProductSuggestionAdapter {
  String get productName;
  int get minNumber;
  int get maxNumber;
  int get numbersToSelect;
  bool get hasSpecialNumber;
  int get specialMinNumber => minNumber;
  int get specialMaxNumber => maxNumber;

  Map<int, double> calculateColdNumbers(
    List<LotteryDrawModel> history, {
    bool isSpecial = false,
  }) {
    final scores = <int, double>{};
    if (history.isEmpty) return scores;

    final startNum = isSpecial ? specialMinNumber : minNumber;
    final endNum = isSpecial ? specialMaxNumber : maxNumber;

    final lastSeenIndex = <int, int>{};
    for (var num = startNum; num <= endNum; num++) {
      lastSeenIndex[num] = history.length;
    }

    for (var i = 0; i < history.length; i++) {
      final draw = history[i];
      final numbersInDraw = isSpecial ? draw.special : draw.regular;
      for (final num in numbersInDraw) {
        if (lastSeenIndex.containsKey(num) &&
            lastSeenIndex[num] == history.length) {
          lastSeenIndex[num] = i;
        }
      }
    }

    var maxDistance = 0;
    var minDistance = history.length;
    for (final val in lastSeenIndex.values) {
      maxDistance = max(maxDistance, val);
      minDistance = min(minDistance, val);
    }

    final range = (maxDistance - minDistance).toDouble();

    for (var num = startNum; num <= endNum; num++) {
      final distance = lastSeenIndex[num]!;
      if (range == 0) {
        scores[num] = 1.0;
      } else {
        scores[num] = (distance - minDistance) / range;
      }
    }

    return scores;
  }

  Map<int, double> calculateOddEven(
    List<LotteryDrawModel> history, {
    bool isSpecial = false,
  }) {
    final scores = <int, double>{};
    if (history.isEmpty) return scores;

    final startNum = isSpecial ? specialMinNumber : minNumber;
    final endNum = isSpecial ? specialMaxNumber : maxNumber;

    var totalNumbers = 0;
    var totalOdds = 0;

    for (final draw in history) {
      final numbers = isSpecial ? draw.special : draw.regular;
      for (final num in numbers) {
        totalNumbers++;
        if (num % 2 != 0) {
          totalOdds++;
        }
      }
    }

    if (totalNumbers == 0) {
      for (var num = startNum; num <= endNum; num++) {
        scores[num] = 0.5;
      }
      return scores;
    }

    final oddRatio = totalOdds / totalNumbers;
    final oddScore = 1.0 - oddRatio;
    final evenScore = oddRatio;

    for (var num = startNum; num <= endNum; num++) {
      if (num % 2 != 0) {
        scores[num] = oddScore;
      } else {
        scores[num] = evenScore;
      }
    }

    return scores;
  }

  Map<int, double> calculateFrequency(
    List<LotteryDrawModel> history, {
    bool isSpecial = false,
  }) {
    final scores = <int, double>{};
    if (history.isEmpty) return scores;

    final startNum = isSpecial ? specialMinNumber : minNumber;
    final endNum = isSpecial ? specialMaxNumber : maxNumber;

    final counts = <int, int>{};
    for (var num = startNum; num <= endNum; num++) {
      counts[num] = 0;
    }

    for (final draw in history) {
      final numbers = isSpecial ? draw.special : draw.regular;
      for (final num in numbers) {
        if (counts.containsKey(num)) {
          counts[num] = counts[num]! + 1;
        }
      }
    }

    var maxCount = 0;
    var minCount = history.length;
    for (final val in counts.values) {
      maxCount = max(maxCount, val);
      minCount = min(minCount, val);
    }

    final range = (maxCount - minCount).toDouble();

    for (var num = startNum; num <= endNum; num++) {
      final count = counts[num]!;
      if (range == 0) {
        scores[num] = 1.0;
      } else {
        scores[num] = (count - minCount) / range;
      }
    }

    return scores;
  }

  Map<int, double> calculateTrend(
    List<LotteryDrawModel> history, {
    bool isSpecial = false,
  }) {
    final scores = <int, double>{};
    if (history.isEmpty) return scores;

    final startNum = isSpecial ? specialMinNumber : minNumber;
    final endNum = isSpecial ? specialMaxNumber : maxNumber;

    final totalDraws = history.length;
    if (totalDraws < 2) {
      for (var num = startNum; num <= endNum; num++) {
        scores[num] = 0.5;
      }
      return scores;
    }

    final splitPoint = (totalDraws / 2).floor();
    final recentDraws = history.sublist(0, splitPoint);
    final olderDraws = history.sublist(splitPoint);

    final recentCounts = <int, int>{};
    final olderCounts = <int, int>{};

    for (var num = startNum; num <= endNum; num++) {
      recentCounts[num] = 0;
      olderCounts[num] = 0;
    }

    for (final draw in recentDraws) {
      final numbers = isSpecial ? draw.special : draw.regular;
      for (final num in numbers) {
        if (recentCounts.containsKey(num)) {
          recentCounts[num] = recentCounts[num]! + 1;
        }
      }
    }

    for (final draw in olderDraws) {
      final numbers = isSpecial ? draw.special : draw.regular;
      for (final num in numbers) {
        if (olderCounts.containsKey(num)) {
          olderCounts[num] = olderCounts[num]! + 1;
        }
      }
    }

    final trends = <int, double>{};
    for (var num = startNum; num <= endNum; num++) {
      final recentFreq = recentCounts[num]! / recentDraws.length;
      final olderFreq = olderCounts[num]! / olderDraws.length;
      trends[num] = recentFreq - olderFreq;
    }

    var maxTrend = -double.maxFinite;
    var minTrend = double.maxFinite;
    for (final val in trends.values) {
      maxTrend = max(maxTrend, val);
      minTrend = min(minTrend, val);
    }

    final range = maxTrend - minTrend;

    for (var num = startNum; num <= endNum; num++) {
      final trend = trends[num]!;
      if (range == 0) {
        scores[num] = 1.0;
      } else {
        scores[num] = (trend - minTrend) / range;
      }
    }

    return scores;
  }

  Map<int, double> calculateRegionBalance(
    List<LotteryDrawModel> history, {
    bool isSpecial = false,
  }) {
    final scores = <int, double>{};
    if (history.isEmpty) return scores;

    final startNum = isSpecial ? specialMinNumber : minNumber;
    final endNum = isSpecial ? specialMaxNumber : maxNumber;

    final totalNumbers = endNum - startNum + 1;
    final regionSize = (totalNumbers / 3).floor();

    final r1Start = startNum;
    final r1End = r1Start + regionSize - 1;
    final r2Start = r1End + 1;
    final r2End = r2Start + regionSize - 1;
    final r3Start = r2End + 1;
    final r3End = endNum;

    final regionSizes = [
      r1End - r1Start + 1,
      r2End - r2Start + 1,
      r3End - r3Start + 1,
    ];

    var totalDrawnCount = 0;
    final regionDrawnCounts = [0, 0, 0];

    for (final draw in history) {
      final numbers = isSpecial ? draw.special : draw.regular;
      for (final num in numbers) {
        totalDrawnCount++;
        if (num >= r1Start && num <= r1End) {
          regionDrawnCounts[0]++;
        } else if (num >= r2Start && num <= r2End) {
          regionDrawnCounts[1]++;
        } else if (num >= r3Start && num <= r3End) {
          regionDrawnCounts[2]++;
        }
      }
    }

    if (totalDrawnCount == 0) {
      for (var num = startNum; num <= endNum; num++) {
        scores[num] = 0.5;
      }
      return scores;
    }

    final expectedRatios = [
      regionSizes[0] / totalNumbers,
      regionSizes[1] / totalNumbers,
      regionSizes[2] / totalNumbers,
    ];

    final actualRatios = [
      regionDrawnCounts[0] / totalDrawnCount,
      regionDrawnCounts[1] / totalDrawnCount,
      regionDrawnCounts[2] / totalDrawnCount,
    ];

    final deficiencies = [
      expectedRatios[0] - actualRatios[0],
      expectedRatios[1] - actualRatios[1],
      expectedRatios[2] - actualRatios[2],
    ];

    final maxDef = deficiencies.reduce(max);
    final minDef = deficiencies.reduce(min);
    final range = maxDef - minDef;

    final regionScores = <int, double>{};
    for (var i = 0; i < 3; i++) {
      if (range == 0) {
        regionScores[i] = 0.5;
      } else {
        regionScores[i] = (deficiencies[i] - minDef) / range;
      }
    }

    for (var num = startNum; num <= endNum; num++) {
      if (num >= r1Start && num <= r1End) {
        scores[num] = regionScores[0]!;
      } else if (num >= r2Start && num <= r2End) {
        scores[num] = regionScores[1]!;
      } else if (num >= r3Start && num <= r3End) {
        scores[num] = regionScores[2]!;
      } else {
        scores[num] = 0.5;
      }
    }

    return scores;
  }

  Map<int, double> calculateFrequentPairs(
    List<LotteryDrawModel> history, {
    bool isSpecial = false,
  }) {
    final scores = <int, double>{};
    if (history.isEmpty) return scores;

    final startNum = isSpecial ? specialMinNumber : minNumber;
    final endNum = isSpecial ? specialMaxNumber : maxNumber;

    for (var num = startNum; num <= endNum; num++) {
      scores[num] = 0.0;
    }

    if (history.length < 2) {
      for (var num = startNum; num <= endNum; num++) {
        scores[num] = 0.5;
      }
      return scores;
    }

    final latestDraw = history.first;
    final latestNumbers = isSpecial
        ? <int>{...latestDraw.special}
        : <int>{...latestDraw.regular};

    final coOccurrence = <int, Map<int, int>>{};
    for (var num = startNum; num <= endNum; num++) {
      coOccurrence[num] = <int, int>{};
      for (var num2 = startNum; num2 <= endNum; num2++) {
        coOccurrence[num]![num2] = 0;
      }
    }

    final historicalDraws = history.sublist(1);
    for (final draw in historicalDraws) {
      final drawNums = isSpecial ? draw.special : draw.regular;
      for (var i = 0; i < drawNums.length; i++) {
        for (var j = i + 1; j < drawNums.length; j++) {
          final n1 = drawNums[i];
          final n2 = drawNums[j];
          if (coOccurrence.containsKey(n1) &&
              coOccurrence[n1]!.containsKey(n2)) {
            coOccurrence[n1]![n2] = coOccurrence[n1]![n2]! + 1;
            coOccurrence[n2]![n1] = coOccurrence[n2]![n1]! + 1;
          }
        }
      }
    }

    final rawScores = <int, int>{};
    for (var num = startNum; num <= endNum; num++) {
      var totalCoOccurrence = 0;
      for (final latestNum in latestNumbers) {
        if (latestNum != num && coOccurrence.containsKey(num)) {
          totalCoOccurrence += coOccurrence[num]![latestNum] ?? 0;
        }
      }
      rawScores[num] = totalCoOccurrence;
    }

    var maxRaw = 0;
    var minRaw = historicalDraws.length;
    for (final val in rawScores.values) {
      maxRaw = max(maxRaw, val);
      minRaw = min(minRaw, val);
    }

    final range = (maxRaw - minRaw).toDouble();

    for (var num = startNum; num <= endNum; num++) {
      final rawVal = rawScores[num]!;
      if (range == 0) {
        scores[num] = 0.5;
      } else {
        scores[num] = (rawVal - minRaw) / range;
      }
    }

    return scores;
  }
}
