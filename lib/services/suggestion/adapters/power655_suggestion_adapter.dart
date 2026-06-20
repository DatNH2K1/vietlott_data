import 'package:vietlott_data/services/suggestion/adapters/base_adapters.dart';

class Power655SuggestionAdapter extends BaseProductSuggestionAdapter {
  @override
  String get productName => 'power655';

  @override
  int get minNumber => 1;

  @override
  int get maxNumber => 55;

  @override
  int get numbersToSelect => 6;

  @override
  bool get hasSpecialNumber => true;

  @override
  Map<String, int> get prizeValues => const {
        'jackpot1': 30000000000,
        'jackpot2': 3000000000,
        'first': 40000000,
        'second': 500000,
        'third': 50000,
      };

  @override
  Map<String, double> calculateWinningProbabilities() {
    final totalComb = combinations(55, 6);
    return {
      'jackpot1': combinations(6, 6) / totalComb,
      'jackpot2': combinations(6, 5) * 1.0 / totalComb,
      'first': combinations(6, 5) * 48.0 / totalComb,
      'second': combinations(6, 4) * combinations(49, 2) / totalComb,
      'third': combinations(6, 3) * combinations(49, 3) / totalComb,
    };
  }

  @override
  MatchResult evaluateDraw(List<int> suggestion, LotteryDrawModel draw) {
    final targetRegular = draw.regular.toSet();
    final targetSpecial = draw.special.toSet();
    final suggestedRegular = suggestion.take(6).toSet();
    final suggestedSpecial = suggestion.last;

    final regularMatches = suggestedRegular.where(targetRegular.contains).length;
    final hasSpecialMatch = targetSpecial.contains(suggestedSpecial);

    String? prizeCategory;
    if (regularMatches == 6) {
      prizeCategory = 'jackpot1';
    } else if (regularMatches == 5 && hasSpecialMatch) {
      prizeCategory = 'jackpot2';
    } else if (regularMatches == 5) {
      prizeCategory = 'first';
    } else if (regularMatches == 4) {
      prizeCategory = 'second';
    } else if (regularMatches == 3) {
      prizeCategory = 'third';
    }

    return MatchResult(
      regularMatches: regularMatches,
      hasSpecialMatch: hasSpecialMatch,
      prizeCategory: prizeCategory,
      isWin: regularMatches >= 3,
    );
  }
}
