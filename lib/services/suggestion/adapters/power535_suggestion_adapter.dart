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
}
