import 'base_crawler_adapter.dart';
import 'power535_adapter.dart';
import 'mega645_adapter.dart';
import 'power655_adapter.dart';

export 'base_crawler_adapter.dart';
export 'power535_adapter.dart';
export 'mega645_adapter.dart';
export 'power655_adapter.dart';

/// Centralized manager for all lottery product crawler adapters.
class LotteryCrawler {
  static final Map<String, BaseCrawlerAdapter> _registry = {
    'power535': Power535Adapter(),
    'mega645': Mega645Adapter(),
    'power655': Power655Adapter(),
  };

  /// Retrieves a crawler adapter by its product name.
  static BaseCrawlerAdapter? getAdapter(String productName) {
    return _registry[productName];
  }

  /// Lists all registered product names.
  static List<String> get supportedProducts => _registry.keys.toList();
}
