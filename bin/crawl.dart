import 'dart:convert';
import 'dart:io';
import 'package:vietlott_data/models/lottery_draw_model.dart';
import 'package:vietlott_data/services/crawler/crawler_service.dart';

void main(List<String> args) async {
  if (args.isEmpty || (args[0] != 'all' && args[0] != 'missing')) {
    print('Usage: dart run bin/crawl.dart <all|missing>');
    exit(1);
  }

  final mode = args[0];
  final products = LotteryCrawler.supportedProducts;

  if (products.isEmpty) {
    print('Error: No crawler adapters registered in LotteryCrawler.');
    exit(1);
  }

  print(
    'Starting crawl process in "$mode" mode for products: ${products.join(", ")}',
  );

  for (final targetProduct in products) {
    final adapter = LotteryCrawler.getAdapter(targetProduct);
    if (adapter == null) {
      print(
        'Error: Crawler adapter not found for product: $targetProduct. Skipping.',
      );
      continue;
    }

    print('\n======================================');
    print('Initializing crawler for product: ${adapter.productName}...');
    print('======================================');

    final jsonlFile = File('data/${adapter.productName}.jsonl');
    final existingIds = <String>{};
    final existingDraws = <LotteryDrawModel>[];

    // Read existing draws if in missing mode and file exists
    if (mode == 'missing' && await jsonlFile.exists()) {
      print('Reading existing draws from ${jsonlFile.path}...');
      final lines = await jsonlFile.readAsLines();
      for (final line in lines) {
        if (line.trim().isEmpty) continue;
        try {
          final jsonMap = jsonDecode(line) as Map<String, dynamic>;
          final draw = LotteryDrawModel(
            id: jsonMap['id'] as String,
            date: jsonMap['date'] as String,
            regular: List<int>.from(jsonMap['regular'] as List),
            special: List<int>.from(jsonMap['special'] as List),
          );
          existingDraws.add(draw);
          existingIds.add(draw.id);
        } catch (e) {
          print('Error parsing line: $line. Error: $e');
        }
      }
      print('Found ${existingDraws.length} existing draws.');
    }

    print('Crawling in "$mode" mode...');
    final newDraws = <LotteryDrawModel>[];
    var pageIndex = 0;
    var caughtUp = false;

    while (true) {
      print('[$targetProduct] Fetching page $pageIndex...');
      final draws = await adapter.fetchPage(pageIndex);
      if (draws.isEmpty) {
        print(
          '[$targetProduct] No more draws returned on page $pageIndex. Stopping.',
        );
        break;
      }

      print(
        '[$targetProduct] Fetched ${draws.length} draws from page $pageIndex.',
      );

      for (final draw in draws) {
        if (mode == 'missing' && existingIds.contains(draw.id)) {
          print(
            '[$targetProduct] Found existing draw ID ${draw.id}. Caught up with history.',
          );
          caughtUp = true;
          break;
        }
        newDraws.add(draw);
      }

      if (caughtUp) {
        break;
      }

      pageIndex++;
      // Tiny delay between requests to be polite to the server
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }

    final finalDraws = <LotteryDrawModel>[];
    if (mode == 'all') {
      finalDraws.addAll(newDraws);
    } else {
      // Merge new draws with existing draws
      finalDraws.addAll(newDraws);
      finalDraws.addAll(existingDraws);
    }

    if (finalDraws.isEmpty) {
      print(
        '[$targetProduct] No data fetched. Please check connection/endpoint.',
      );
      continue;
    }

    print(
      '[$targetProduct] Total draws compiled: ${finalDraws.length} (New: ${newDraws.length}, Existing: ${existingDraws.length}).',
    );

    // Ensure data directory exists
    final dataDir = Directory('data');
    if (!await dataDir.exists()) {
      await dataDir.create(recursive: true);
    }

    print('[$targetProduct] Writing to ${jsonlFile.path}...');
    final sink = jsonlFile.openWrite();
    for (final draw in finalDraws) {
      sink.write('${draw.toJsonLString()}\n');
    }
    await sink.close();

    print('\n--- SAMPLE OUTPUT (${adapter.productName} - First 3 draws) ---');
    final previewCount = finalDraws.length < 3 ? finalDraws.length : 3;
    for (var i = 0; i < previewCount; i++) {
      print(finalDraws[i].toJsonLString());
    }
    print('--------------------------------------');
    print('All ${finalDraws.length} records written to ${jsonlFile.path}.');
  }
}
