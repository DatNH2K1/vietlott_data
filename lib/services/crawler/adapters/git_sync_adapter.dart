import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:vietlott_data/config.dart';
import 'package:vietlott_data/models/lottery_draw_model.dart';
import 'package:vietlott_data/services/crawler/adapters/base_adapters.dart';

/// Sync adapter that fetches data from the public GitHub repository using raw URL in streamed chunks.
class GitSyncAdapter implements BaseSyncAdapter {
  GitSyncAdapter(this.productName);
  @override
  final String productName;

  @override
  Future<List<LotteryDrawModel>> fetchDraws() async {
    final urlString = AppConfig.getProductDataUrl(productName);
    final url = Uri.parse(urlString);

    final client = http.Client();
    try {
      final request = http.Request('GET', url);
      final response = await client.send(request);

      if (response.statusCode != 200) {
        throw Exception(
          'HTTP Request failed with status code ${response.statusCode} for $urlString',
        );
      }

      final draws = <LotteryDrawModel>[];

      // Decode streamed chunks to UTF-8 and split them by line (chunk-by-chunk processing)
      await response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .forEach((line) {
            if (line.trim().isEmpty) return;
            try {
              final jsonMap = jsonDecode(line) as Map<String, dynamic>;
              final draw = LotteryDrawModel(
                id: jsonMap['id'] as String,
                date: jsonMap['date'] as String,
                regular: List<int>.from(jsonMap['regular'] as List),
                special: List<int>.from(jsonMap['special'] as List),
              );
              draws.add(draw);
            } catch (e) {
              print('Error parsing JSONL line: $line. Error: $e');
            }
          });

      return draws;
    } catch (e) {
      print('Failed to sync $productName from Git: $e');
      rethrow;
    } finally {
      client.close();
    }
  }
}
