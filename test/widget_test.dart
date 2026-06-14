import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vietlott_data/app/app.dart';
import 'package:vietlott_data/services/settings/app_settings.dart';

class TestAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    if (key.endsWith('vi.json') || key.endsWith('en.json')) {
      const jsonStr = '''
      {
        "appTitle": "Vietlott Analytics",
        "settings": "Cài đặt",
        "theme": "Giao diện",
        "language": "Ngôn ngữ",
        "themeLightRed": "Đỏ Vietlott",
        "themeDarkSlate": "Tối Hiện đại",
        "themeGoldLuxury": "Vàng Sang trọng",
        "langVi": "Tiếng Việt",
        "langEn": "English",
        "close": "Đóng",
        "reSync": "Đồng bộ lại",
        "syncing": "Đang đồng bộ dữ liệu từ Git..."
      }
      ''';
      return ByteData.view(Uint8List.fromList(utf8.encode(jsonStr)).buffer);
    }
    throw FlutterError('Asset not found: $key');
  }
}

void main() {
  testWidgets('Vietlott Analytics Page displays app bar title', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      DefaultAssetBundle(
        bundle: TestAssetBundle(),
        child: AppSettingsProvider(
          notifier: AppSettings(),
          child: const MyApp(),
        ),
      ),
    );

    // Wait for AppLocalizations to finish loading
    await tester.pumpAndSettle();

    expect(find.text('Vietlott Analytics'), findsOneWidget);
  });
}
