import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:vietlott_data/models/lottery_draw_model.dart';
import 'package:vietlott_data/repositories/lottery_repository.dart';
import 'package:vietlott_data/services/suggestion/suggestion_config.dart';
import 'package:vietlott_data/services/suggestion/suggestion_engine.dart';

@Timeout(Duration(minutes: 5))

class FileLotteryRepository implements LotteryRepository {
  FileLotteryRepository(this.draws);
  final List<LotteryDrawModel> draws;

  @override
  Future<List<LotteryDrawModel>> getDraws(
    String productName, {
    int? limit,
    int? offset,
  }) async {
    var list = draws;
    if (offset != null && offset < list.length) {
      list = list.sublist(offset);
    }
    if (limit != null) {
      list = list.take(limit).toList();
    }
    return list;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<List<LotteryDrawModel>> loadHistory(String product) async {
  final jsonlFile = File('data/$product.jsonl');
  if (!await jsonlFile.exists()) {
    print('Warning: data/$product.jsonl not found.');
    return [];
  }
  final lines = await jsonlFile.readAsLines();
  final list = <LotteryDrawModel>[];
  for (final line in lines) {
    if (line.trim().isEmpty) continue;
    try {
      final jsonMap = jsonDecode(line) as Map<String, dynamic>;
      list.add(
        LotteryDrawModel(
          id: jsonMap['id'] as String,
          date: jsonMap['date'] as String,
          regular: List<int>.from(jsonMap['regular'] as List),
          special: List<int>.from(jsonMap['special'] as List),
        ),
      );
    } catch (e) {
      // Ignore parse errors
    }
  }
  return list;
}

void main() {
  test('Optimize Suggestions Weights', () async {
    final products = ['mega645', 'power655', 'power535'];
    final optimizedWeights = <String, Map<String, double>>{};

    print('=============================================');
    print('    VIETLOTT SUGGESTION WEIGHTS OPTIMIZER    ');
    print('=============================================');

    for (final product in products) {
      print('\nOptimizing weights for: $product...');
      final draws = await loadHistory(product);
      if (draws.isEmpty) {
        print('Skipping $product (no data).');
        optimizedWeights[product] = SuggestionConfig.mlWeights[product] ?? {};
        continue;
      }

      final repo = FileLotteryRepository(draws);
      final engine = SuggestionEngine(repository: repo);
      final adapter = engine.getAdapter(product);
      if (adapter == null) {
        print('Error: Adapter for $product not found.');
        continue;
      }

      // Define all 18 parameter keys
      final weightKeys = <String>[];
      for (final criteria in [
        'cold_numbers',
        'odd_even',
        'frequency',
        'trend',
        'region_balance',
        'frequent_pairs',
      ]) {
        for (final interval in ['allTime', 'last30', 'last5']) {
          weightKeys.add('${criteria}_$interval');
        }
      }

      // Load initial weights
      final initialWeights = Map<String, double>.from(
        SuggestionConfig.mlWeights[product] ?? {},
      );
      // Fill in missing keys with default 0.0
      for (final key in weightKeys) {
        initialWeights.putIfAbsent(key, () => 0.0);
      }

      const backTestCount = 40; // Number of draws to back-test for fitness evaluation

      // Helper function to evaluate weights
      Future<double> evaluateFitness(Map<String, double> weights) async {
        var totalMatches = 0.0;
        var evaluatedCount = 0;

        for (var i = 0; i < backTestCount; i++) {
          if (i + 1 >= draws.length) break;
          final targetDraw = draws[i];
          final historyPrior = draws.sublist(i + 1);

          final suggestion = await engine.generateSuggestions(
            product: product,
            weights: weights,
            customHistory: historyPrior,
          );

          if (suggestion.isEmpty) continue;
          final matchResult = adapter.evaluateDraw(suggestion, targetDraw);
          totalMatches += matchResult.regularMatches;
          evaluatedCount++;
        }

        return evaluatedCount == 0 ? 0.0 : totalMatches / evaluatedCount;
      }

      print('Evaluating initial weights...');
      var bestFitness = await evaluateFitness(initialWeights);
      var bestWeights = Map<String, double>.from(initialWeights);
      print('Initial fitness (average matches): ${bestFitness.toStringAsFixed(4)}');

      // Run Optimization
      final rand = Random();
      const iterations = 100;
      var acceptedCount = 0;

      for (var iter = 1; iter <= iterations; iter++) {
        final candidateWeights = Map<String, double>.from(bestWeights);

        // Perturb weights
        final keyToPerturb = weightKeys[rand.nextInt(weightKeys.length)];
        final currentVal = candidateWeights[keyToPerturb] ?? 0.0;
        final change = (rand.nextDouble() * 0.2) - 0.1; // perturbation in [-0.1, 0.1]
        candidateWeights[keyToPerturb] = (currentVal + change).clamp(0.0, 1.0);

        // Re-normalize weights so they sum to 1.0
        var sum = candidateWeights.values.fold(0.0, (a, b) => a + b);
        if (sum > 0) {
          for (final k in candidateWeights.keys) {
            candidateWeights[k] = candidateWeights[k]! / sum;
          }
        } else {
          candidateWeights[weightKeys[0]] = 1.0;
        }

        final candidateFitness = await evaluateFitness(candidateWeights);

        if (candidateFitness > bestFitness) {
          bestFitness = candidateFitness;
          bestWeights = candidateWeights;
          acceptedCount++;
        }
      }

      print('Optimization finished.');
      print('Accepted mutations: $acceptedCount');
      print('Optimized fitness (average matches): ${bestFitness.toStringAsFixed(4)}');

      optimizedWeights[product] = bestWeights;
    }

    // Generate SuggestionConfig file
    print('\nGenerating lib/services/suggestion/suggestion_config.dart...');
    final buffer = StringBuffer();
    buffer.writeln('// Generated ML Suggestions Configuration. Do not edit manually.');
    buffer.writeln('');
    buffer.writeln('class SuggestionConfig {');
    buffer.writeln('  static const Map<String, Map<String, double>> mlWeights = {');

    for (final entry in optimizedWeights.entries) {
      buffer.writeln("    '${entry.key}': {");
      for (final weightEntry in entry.value.entries) {
        buffer.writeln(
          "      '${weightEntry.key}': ${weightEntry.value.toStringAsFixed(4)},",
        );
      }
      buffer.writeln('    },');
    }

    buffer.writeln('  };');
    buffer.writeln('}');

    final configFile = File('lib/services/suggestion/suggestion_config.dart');
    await configFile.writeAsString(buffer.toString());
    print('Successfully updated suggestion_config.dart.');
  }, timeout: const Timeout(Duration(minutes: 5)));
}
