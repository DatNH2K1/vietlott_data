import 'package:vietlott_data/services/suggestion/adapters/base_adapters.dart';

class Power535SuggestionAdapter extends BaseProductSuggestionAdapter {
  @override
  String get productName => 'power535';

  @override
  int get minNumber => 1;

  @override
  int get maxNumber => 35;

  @override
  int get numbersToSelect => 5;

  @override
  bool get hasSpecialNumber => true;

  @override
  int get specialMinNumber => 1;

  @override
  int get specialMaxNumber => 12;

  @override
  Map<String, int> get prizeValues => const {
        'jackpot': 6000000000,
        'first': 10000000,
        'second': 5000000,
        'third': 500000,
        'fourth': 100000,
        'fifth': 30000,
        'consolation': 10000,
      };

  @override
  Map<String, double> calculateWinningProbabilities() {
    final regComb = combinations(35, 5);
    final totalComb = regComb * 12.0;
    // Consolation is: 2 regular + 1 special OR 1 regular + 1 special
    final consolationComb =
        (combinations(5, 2) * combinations(30, 3) * 1.0) +
        (combinations(5, 1) * combinations(30, 4) * 1.0);

    return {
      'jackpot': 1.0 / totalComb,
      'first': 11.0 / totalComb,
      'second': (combinations(5, 4) * combinations(30, 1) * 1.0) / totalComb,
      'third': (combinations(5, 4) * combinations(30, 1) * 11.0) / totalComb,
      'fourth': (combinations(5, 3) * combinations(30, 2) * 1.0) / totalComb,
      'fifth': (combinations(5, 3) * combinations(30, 2) * 11.0) / totalComb,
      'consolation': consolationComb / totalComb,
    };
  }

  @override
  MatchResult evaluateDraw(List<int> suggestion, LotteryDrawModel draw) {
    final targetRegular = draw.regular.toSet();
    final targetSpecial = draw.special.toSet();
    final suggestedRegular = suggestion.take(5).toSet();
    final suggestedSpecial = suggestion.last;

    final regularMatches = suggestedRegular.where(targetRegular.contains).length;
    final hasSpecialMatch = targetSpecial.contains(suggestedSpecial);

    String? prizeCategory;
    var isWin = false;

    if (regularMatches == 5 && hasSpecialMatch) {
      prizeCategory = 'jackpot';
      isWin = true;
    } else if (regularMatches == 5) {
      prizeCategory = 'first';
      isWin = true;
    } else if (regularMatches == 4 && hasSpecialMatch) {
      prizeCategory = 'second';
      isWin = true;
    } else if (regularMatches == 4) {
      prizeCategory = 'third';
      isWin = true;
    } else if (regularMatches == 3 && hasSpecialMatch) {
      prizeCategory = 'fourth';
      isWin = true;
    } else if (regularMatches == 3) {
      prizeCategory = 'fifth';
      isWin = true;
    } else if ((regularMatches == 1 || regularMatches == 2) && hasSpecialMatch) {
      prizeCategory = 'consolation';
      isWin = true;
    }

    return MatchResult(
      regularMatches: regularMatches,
      hasSpecialMatch: hasSpecialMatch,
      prizeCategory: prizeCategory,
      isWin: isWin,
    );
  }
}
