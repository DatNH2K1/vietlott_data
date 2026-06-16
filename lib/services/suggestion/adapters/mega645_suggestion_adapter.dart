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
}
