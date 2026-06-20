import 'dart:math';
import 'package:vietlott_data/repositories/lottery_repository.dart';
import 'package:vietlott_data/services/suggestion/adapters/base_adapters.dart';
import 'package:vietlott_data/services/suggestion/adapters/mega645_suggestion_adapter.dart';
import 'package:vietlott_data/services/suggestion/adapters/power535_suggestion_adapter.dart';
import 'package:vietlott_data/services/suggestion/adapters/power655_suggestion_adapter.dart';
import 'package:vietlott_data/services/suggestion/suggestion_config.dart';

enum FrequencyInterval { allTime, last30, last5 }

class SuggestionEngine {
  SuggestionEngine({LotteryRepository? repository})
    : _repository = repository ?? LotteryRepository();

  final LotteryRepository _repository;

  final Map<String, BaseProductSuggestionAdapter> _adapters = {
    'mega645': Mega645SuggestionAdapter(),
    'power655': Power655SuggestionAdapter(),
    'power535': Power535SuggestionAdapter(),
  };

  /// Retrieves a suggestion adapter by its product name.
  BaseProductSuggestionAdapter? getAdapter(String productName) {
    return _adapters[productName];
  }

  /// Generates lottery number suggestions using machine learning weights from config.
  Future<List<int>> generateSuggestions({
    required String product,
    Map<String, double>? weights,
    List<LotteryDrawModel>? customHistory,
  }) async {
    final adapter = getAdapter(product);
    if (adapter == null) return [];

    final activeWeights = weights ?? SuggestionConfig.mlWeights[product] ?? {};

    final historyAll = customHistory ?? await _repository.getDraws(product);
    if (historyAll.isEmpty) {
      return [];
    }

    final history30 = historyAll.take(30).toList();
    final history5 = historyAll.take(5).toList();

    final historyMap = {
      'allTime': historyAll,
      'last30': history30,
      'last5': history5,
    };

    // Gather scores from product-specific calculations
    final combinedRegularScores = <int, double>{};
    for (var num = adapter.minNumber; num <= adapter.maxNumber; num++) {
      combinedRegularScores[num] = 0.0;
    }

    final combinedSpecialScores = <int, double>{};
    if (adapter.hasSpecialNumber) {
      for (
        var num = adapter.specialMinNumber;
        num <= adapter.specialMaxNumber;
        num++
      ) {
        combinedSpecialScores[num] = 0.0;
      }
    }

    final criteriaMethods =
        <
          String,
          Map<int, double> Function(List<LotteryDrawModel>, {bool isSpecial})
        >{
          'cold_numbers': adapter.calculateColdNumbers,
          'odd_even': adapter.calculateOddEven,
          'frequency': adapter.calculateFrequency,
          'trend': adapter.calculateTrend,
          'region_balance': adapter.calculateRegionBalance,
          'frequent_pairs': adapter.calculateFrequentPairs,
        };

    var totalWeight = 0.0;
    for (final criteriaEntry in criteriaMethods.entries) {
      final criteriaKey = criteriaEntry.key;
      final method = criteriaEntry.value;

      for (final intervalKey in ['allTime', 'last30', 'last5']) {
        final weightKey = '${criteriaKey}_$intervalKey';
        final weight = activeWeights[weightKey] ?? 0.0;

        if (weight <= 0) continue;

        totalWeight += weight;
        final historySlice = historyMap[intervalKey]!;

        final regularScores = method(historySlice);
        for (var num = adapter.minNumber; num <= adapter.maxNumber; num++) {
          final score = regularScores[num] ?? 0.0;
          combinedRegularScores[num] =
              combinedRegularScores[num]! + (score * weight);
        }

        if (adapter.hasSpecialNumber) {
          final specialScores = method(historySlice, isSpecial: true);
          for (
            var num = adapter.specialMinNumber;
            num <= adapter.specialMaxNumber;
            num++
          ) {
            final score = specialScores[num] ?? 0.0;
            combinedSpecialScores[num] =
                combinedSpecialScores[num]! + (score * weight);
          }
        }
      }
    }

    // Default if no weights are active
    if (totalWeight == 0.0) {
      final regularScores = adapter.calculateFrequency(historyAll);
      for (var num = adapter.minNumber; num <= adapter.maxNumber; num++) {
        final score = regularScores[num] ?? 0.0;
        combinedRegularScores[num] = score;
      }

      if (adapter.hasSpecialNumber) {
        final specialScores = adapter.calculateFrequency(
          historyAll,
          isSpecial: true,
        );
        for (
          var num = adapter.specialMinNumber;
          num <= adapter.specialMaxNumber;
          num++
        ) {
          final score = specialScores[num] ?? 0.0;
          combinedSpecialScores[num] = score;
        }
      }
    }

    // Selection process: Weighted random sampling
    final numPool = List<int>.generate(
      adapter.maxNumber - adapter.minNumber + 1,
      (i) => adapter.minNumber + i,
    );

    final selected = <int>[];
    final random = Random();
    final pool = List<int>.from(numPool);

    while (selected.length < adapter.numbersToSelect && pool.isNotEmpty) {
      var sumOfScores = 0.0;
      final currentScores = <double>[];

      for (final num in pool) {
        final score = max(0.01, combinedRegularScores[num] ?? 0.0);
        sumOfScores += score;
        currentScores.add(sumOfScores);
      }

      final r = random.nextDouble() * sumOfScores;
      var chosenIndex = 0;
      for (var i = 0; i < currentScores.length; i++) {
        if (r <= currentScores[i]) {
          chosenIndex = i;
          break;
        }
      }

      selected.add(pool[chosenIndex]);
      pool.removeAt(chosenIndex);
    }

    selected.sort();

    if (adapter.hasSpecialNumber) {
      final specialPool = <int>[];
      for (
        var num = adapter.specialMinNumber;
        num <= adapter.specialMaxNumber;
        num++
      ) {
        if (adapter.specialMaxNumber == adapter.maxNumber &&
            selected.contains(num)) {
          continue;
        }
        specialPool.add(num);
      }

      if (specialPool.isNotEmpty) {
        var sumOfScores = 0.0;
        final currentScores = <double>[];

        for (final num in specialPool) {
          final score = max(0.01, combinedSpecialScores[num] ?? 0.0);
          sumOfScores += score;
          currentScores.add(sumOfScores);
        }

        final r = random.nextDouble() * sumOfScores;
        var chosenIndex = 0;
        for (var i = 0; i < currentScores.length; i++) {
          if (r <= currentScores[i]) {
            chosenIndex = i;
            break;
          }
        }

        selected.add(specialPool[chosenIndex]);
      }
    }

    return selected;
  }

  /// Runs a back-test on the last [backTestCount] draws to evaluate the AI suggestion performance.
  /// Returns a map containing the match statistics (e.g. number of matches per draw, winning categories achieved).
  Future<Map<String, dynamic>> evaluateAiPerformance({
    required String product,
    int backTestCount = 10,
  }) async {
    final allHistory = await _repository.getDraws(product);
    if (allHistory.length <= backTestCount) {
      return <String, dynamic>{
        'totalEvaluated': 0,
        'averageMatches': 0.0,
        'details': const <Map<String, dynamic>>[],
      };
    }

    final adapter = getAdapter(product);
    if (adapter == null) return <String, dynamic>{};

    final stats = <String, int>{};
    for (final prizeKey in adapter.calculateWinningProbabilities().keys) {
      stats[prizeKey] = 0;
    }

    var totalMatchesCount = 0;
    var winDrawsCount = 0;
    final resultsList = <Map<String, dynamic>>[];

    // We evaluate the last `backTestCount` draws
    for (var i = 0; i < backTestCount; i++) {
      // The draw we are trying to predict
      final targetDraw = allHistory[i];

      // The history available prior to this draw (excluding this draw and newer ones)
      final historyPrior = allHistory.sublist(i + 1);

      // Generate suggestion using the history prior to this draw
      final suggestion = await generateSuggestions(
        product: product,
        customHistory: historyPrior,
      );

      if (suggestion.isEmpty) continue;

      final matchResult = adapter.evaluateDraw(suggestion, targetDraw);

      if (matchResult.prizeCategory != null) {
        stats[matchResult.prizeCategory!] =
            (stats[matchResult.prizeCategory!] ?? 0) + 1;
      }

      if (matchResult.isWin) {
        winDrawsCount++;
      }

      totalMatchesCount += matchResult.regularMatches;
      resultsList.add({
        'drawId': targetDraw.id,
        'date': targetDraw.date,
        'regularMatches': matchResult.regularMatches,
        'specialMatch': matchResult.hasSpecialMatch,
      });
    }

    var totalPrizeMoney = 0.0;
    for (final entry in stats.entries) {
      final prizeValue = adapter.prizeValues[entry.key] ?? 0;
      totalPrizeMoney += entry.value * prizeValue;
    }
    final actualRoi = resultsList.isEmpty ? 0.0 : totalPrizeMoney / (resultsList.length * 10000.0);

    return {
      'totalEvaluated': resultsList.length,
      'averageMatches': resultsList.isEmpty ? 0.0 : totalMatchesCount / resultsList.length,
      'breakEvenRate': resultsList.isEmpty ? 0.0 : winDrawsCount / resultsList.length,
      'roi': actualRoi,
      'stats': stats,
      'details': resultsList,
    };
  }
}
