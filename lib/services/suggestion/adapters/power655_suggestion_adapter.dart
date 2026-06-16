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
}
