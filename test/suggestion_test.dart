import 'package:flutter_test/flutter_test.dart';
import 'package:vietlott_data/models/lottery_draw_model.dart';
import 'package:vietlott_data/repositories/lottery_repository.dart';
import 'package:vietlott_data/services/suggestion/adapters/mega645_suggestion_adapter.dart';
import 'package:vietlott_data/services/suggestion/adapters/power535_suggestion_adapter.dart';
import 'package:vietlott_data/services/suggestion/adapters/power655_suggestion_adapter.dart';
import 'package:vietlott_data/services/suggestion/suggestion_engine.dart';

class MockLotteryRepository implements LotteryRepository {
  MockLotteryRepository(this.mockHistory);
  final List<LotteryDrawModel> mockHistory;

  @override
  Future<List<LotteryDrawModel>> getDraws(
    String productName, {
    int? limit,
    int? offset,
  }) async {
    if (limit != null) {
      return mockHistory.take(limit).toList();
    }
    return mockHistory;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Product Suggestion Adapters Tests', () {
    late List<LotteryDrawModel> mockHistory;

    setUp(() {
      mockHistory = [
        LotteryDrawModel(id: '5', date: '2026-06-05', regular: [1, 2, 3], special: []),
        LotteryDrawModel(id: '4', date: '2026-06-04', regular: [1, 4, 5], special: []),
        LotteryDrawModel(id: '3', date: '2026-06-03', regular: [1, 2, 6], special: []),
        LotteryDrawModel(id: '2', date: '2026-06-02', regular: [7, 8, 9], special: []),
        LotteryDrawModel(id: '1', date: '2026-06-01', regular: [1, 2, 10], special: []),
      ];
    });

    test('Mega645SuggestionAdapter properties and calculations', () {
      final adapter = Mega645SuggestionAdapter();
      expect(adapter.productName, equals('mega645'));
      expect(adapter.minNumber, equals(1));
      expect(adapter.maxNumber, equals(45));
      expect(adapter.numbersToSelect, equals(6));
      expect(adapter.hasSpecialNumber, isFalse);

      final coldScores = adapter.calculateColdNumbers(mockHistory);
      expect(coldScores.length, equals(45));
      expect(coldScores[1], lessThan(coldScores[10]!));

      final oddEvenScores = adapter.calculateOddEven(mockHistory);
      expect(oddEvenScores.length, equals(45));

      final freqScores = adapter.calculateFrequency(mockHistory);
      expect(freqScores[1], equals(1.0));
    });

    test('Power655SuggestionAdapter properties', () {
      final adapter = Power655SuggestionAdapter();
      expect(adapter.productName, equals('power655'));
      expect(adapter.minNumber, equals(1));
      expect(adapter.maxNumber, equals(55));
      expect(adapter.numbersToSelect, equals(6));
      expect(adapter.hasSpecialNumber, isTrue);

      final regionScores = adapter.calculateRegionBalance(mockHistory);
      expect(regionScores.length, equals(55));
    });

    test('Power535SuggestionAdapter properties and special calculations', () {
      final adapter = Power535SuggestionAdapter();
      expect(adapter.productName, equals('power535'));
      expect(adapter.minNumber, equals(1));
      expect(adapter.maxNumber, equals(35));
      expect(adapter.numbersToSelect, equals(5));
      expect(adapter.hasSpecialNumber, isTrue);

      final pairScores = adapter.calculateFrequentPairs(mockHistory);
      expect(pairScores.length, equals(35));

      final testHistory = [
        LotteryDrawModel(id: '1', date: '2026-06-01', regular: [13, 14, 15], special: [5]),
      ];
      final regularFreq = adapter.calculateFrequency(testHistory);
      final specialFreq = adapter.calculateFrequency(testHistory, isSpecial: true);

      // Verify range isolation
      expect(regularFreq.length, equals(35));
      expect(specialFreq.length, equals(12));

      // Verify value isolation
      expect(regularFreq[13], equals(1.0));
      expect(regularFreq[5], equals(0.0)); // 5 is special, so regular frequency should be 0.0
      expect(specialFreq[5], equals(1.0));  // 5 is special, so special frequency should be 1.0
      expect(specialFreq[1], equals(0.0));
    });

    test('SuggestionEngine generates predictions using composite weights', () async {
      final mockRepo = MockLotteryRepository(mockHistory);
      final engine = SuggestionEngine(repository: mockRepo);

      final suggestions = await engine.generateSuggestions(
        product: 'mega645',
        weights: {
          'cold_numbers_allTime': 1.0,
          'frequency_last30': 0.5,
          'odd_even_last5': 0.8,
        },
      );

      expect(suggestions.length, equals(6));
      for (final num in suggestions) {
        expect(num, greaterThanOrEqualTo(1));
        expect(num, lessThanOrEqualTo(45));
      }

      final suggestionsPower655 = await engine.generateSuggestions(
        product: 'power655',
      );
      expect(suggestionsPower655.length, equals(7)); // 6 regular + 1 special
      for (final num in suggestionsPower655) {
        expect(num, greaterThanOrEqualTo(1));
        expect(num, lessThanOrEqualTo(55));
      }

      final suggestionsPower535 = await engine.generateSuggestions(
        product: 'power535',
      );
      expect(suggestionsPower535.length, equals(6)); // 5 regular + 1 special
      for (var i = 0; i < 5; i++) {
        expect(suggestionsPower535[i], greaterThanOrEqualTo(1));
        expect(suggestionsPower535[i], lessThanOrEqualTo(35));
      }
      expect(suggestionsPower535[5], greaterThanOrEqualTo(1));
      expect(suggestionsPower535[5], lessThanOrEqualTo(12));
    });
  });
}
