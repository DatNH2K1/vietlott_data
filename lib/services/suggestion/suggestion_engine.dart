import 'dart:math';
import 'package:vietlott_data/models/lottery_draw_model.dart';
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
  }) async {
    final adapter = getAdapter(product);
    if (adapter == null) return [];

    final activeWeights = weights ?? SuggestionConfig.mlWeights[product] ?? {};

    final historyAll = await _repository.getDraws(product);
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
}
