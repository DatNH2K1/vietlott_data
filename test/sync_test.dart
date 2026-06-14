import 'package:flutter_test/flutter_test.dart';
import 'package:vietlott_data/services/crawler/adapters/git_sync_adapter.dart';

void main() {
  test(
    'GitSyncAdapter fetches and parses power535 data from raw GitHub',
    () async {
      final adapter = GitSyncAdapter('power535');

      // Fetch data
      final draws = await adapter.fetchDraws();

      // Print diagnostic info
      print('Fetched ${draws.length} draws from GitHub.');

      // Basic assertions
      expect(draws, isNotEmpty);

      final firstDraw = draws.first;
      expect(firstDraw.id, isNotEmpty);

      // Date format should match YYYY-MM-DD (e.g. 2024-06-12)
      final dateRegExp = RegExp(r'^\d{4}-\d{2}-\d{2}$');
      expect(dateRegExp.hasMatch(firstDraw.date), isTrue);

      expect(firstDraw.regular, isNotEmpty);
      print('Sample draw parsed successfully: $firstDraw');
    },
  );
}
