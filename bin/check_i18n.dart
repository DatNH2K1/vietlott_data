import 'dart:convert';
import 'dart:io';

void main() {
  final viFile = File('assets/lang/vi.json');
  final enFile = File('assets/lang/en.json');

  if (!viFile.existsSync()) {
    print('❌ Error: assets/lang/vi.json not found.');
    exit(1);
  }
  if (!enFile.existsSync()) {
    print('❌ Error: assets/lang/en.json not found.');
    exit(1);
  }

  try {
    final viMap = jsonDecode(viFile.readAsStringSync()) as Map<String, dynamic>;
    final enMap = jsonDecode(enFile.readAsStringSync()) as Map<String, dynamic>;

    final viKeys = viMap.keys.toSet();
    final enKeys = enMap.keys.toSet();

    final missingInEn = viKeys.difference(enKeys);
    final missingInVi = enKeys.difference(viKeys);

    var hasError = false;

    if (missingInEn.isNotEmpty) {
      print('❌ Keys present in vi.json but missing in en.json:');
      for (final key in missingInEn) {
        print('  - $key');
      }
      hasError = true;
    }

    if (missingInVi.isNotEmpty) {
      print('❌ Keys present in en.json but missing in vi.json:');
      for (final key in missingInVi) {
        print('  - $key');
      }
      hasError = true;
    }

    if (hasError) {
      print('\n⚠️ Validation failed: Locale files do not match.');
      exit(1);
    } else {
      print(
        '✅ Success: Locale files are perfectly synced! (${viKeys.length} keys verified)',
      );
      exit(0);
    }
  } catch (e) {
    print('❌ Error parsing JSON: $e');
    exit(1);
  }
}
