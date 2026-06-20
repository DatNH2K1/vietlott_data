import 'package:vietlott_data/services/suggestion/adapters/base_adapters.dart';

class Mega645SuggestionAdapter extends BaseProductSuggestionAdapter {
  @override
  String get productName => 'mega645';

  @override
  int get minNumber => 1;

  @override
  int get maxNumber => 45;

  @override
  int get numbersToSelect => 6;

  @override
  bool get hasSpecialNumber => false;

  @override
  Map<String, int> get prizeValues => const {
        'jackpot': 12000000000,
        'first': 10000000,
        'second': 300000,
        'third': 30000,
      };

  @override
  Map<String, double> calculateWinningProbabilities() {
    final totalComb = combinations(45, 6);
    return {
      'jackpot': combinations(6, 6) * combinations(39, 0) / totalComb,
      'first': combinations(6, 5) * combinations(39, 1) / totalComb,
      'second': combinations(6, 4) * combinations(39, 2) / totalComb,
      'third': combinations(6, 3) * combinations(39, 3) / totalComb,
    };
  }

  @override
  MatchResult evaluateDraw(List<int> suggestion, LotteryDrawModel draw) {
    final targetRegular = draw.regular.toSet();
    final regularMatches = suggestion.where(targetRegular.contains).length;
    String? prizeCategory;
    if (regularMatches == 6) {
      prizeCategory = 'jackpot';
    } else if (regularMatches == 5) {
      prizeCategory = 'first';
    } else if (regularMatches == 4) {
      prizeCategory = 'second';
    } else if (regularMatches == 3) {
      prizeCategory = 'third';
    }
    return MatchResult(
      regularMatches: regularMatches,
      hasSpecialMatch: false,
      prizeCategory: prizeCategory,
      isWin: regularMatches >= 3,
    );
  }
}
