import 'base_crawler_adapter.dart';
import 'power535_adapter.dart';

export 'base_crawler_adapter.dart';
export 'power535_adapter.dart';

/// Centralized manager for all lottery product crawler adapters.
class LotteryCrawler {
  static final Map<String, BaseCrawlerAdapter> _registry = {
    'power535': Power535Adapter(),
    // Add new product crawler adapters here as they are implemented
  };

  /// Retrieves a crawler adapter by its product name.
  static BaseCrawlerAdapter? getAdapter(String productName) {
    return _registry[productName];
  }

  /// Lists all registered product names.
  static List<String> get supportedProducts => _registry.keys.toList();
}
