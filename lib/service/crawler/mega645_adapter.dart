import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:vietlott_data/models/lottery_draw_model.dart';
import 'package:vietlott_data/service/crawler/base_crawler_adapter.dart';

/// Crawler adapter for Vietlott Product 645 (Mega 6/45).
class Mega645Adapter implements BaseCrawlerAdapter {
  @override
  String get productName => 'mega645';

  @override
  Future<List<LotteryDrawModel>> fetchPage(int pageIndex) async {
    final url = Uri.parse('https://vietlott.vn/ajaxpro/Vietlott.PlugIn.WebParts.Game645CompareWebPart,Vietlott.PlugIn.WebParts.ashx');
    
    final headers = {
      'Content-Type': 'text/plain; charset=utf-8',
      'X-AjaxPro-Method': 'ServerSideDrawResult',
      'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:128.0) Gecko/20100101 Firefox/128.0'
    };

    final body = {
      "ORenderInfo": {
        "SiteId": "main.frontend.vi",
        "SiteAlias": "main.vi",
        "UserSessionId": "",
        "SiteLang": "vi",
        "IsPageDesign": false,
        "ExtraParam1": "",
        "ExtraParam2": "",
        "ExtraParam3": "",
        "SiteURL": "",
        "WebPage": null,
        "SiteName": "Vietlott",
        "OrgPageAlias": null,
        "PageAlias": null,
        "RefKey": null,
        "FullPageAlias": null
      },
      "Key": "d0ea794f",
      "GameDrawId": "",
      "ArrayNumbers": List.generate(5, (_) => List.generate(45, (_) => "")),
      "CheckMulti": false,
      "PageIndex": pageIndex
    };

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode != 200) {
        throw Exception('HTTP Error: ${response.statusCode}');
      }

      final dynamic resJson = jsonDecode(response.body);
      final String? htmlContent = resJson['value']?['HtmlContent'] as String?;
      if (htmlContent == null || htmlContent.isEmpty) {
        return [];
      }

      return _parseHtml(htmlContent);
    } catch (e) {
      print('Error fetching page $pageIndex for product 645: $e');
      return [];
    }
  }

  List<LotteryDrawModel> _parseHtml(String htmlContent) {
    final document = parse(htmlContent);
    final List<LotteryDrawModel> results = [];

    final rows = document.querySelectorAll('table tr');
    for (int i = 1; i < rows.length; i++) {
      final tds = rows[i].querySelectorAll('td');
      if (tds.length < 3) continue;

      final dateRaw = tds[0].text.trim();
      final drawId = tds[1].text.trim();

      // Parse date format DD/MM/YYYY to YYYY-MM-DD
      String dateFormatted;
      try {
        final parts = dateRaw.split('/');
        if (parts.length == 3) {
          dateFormatted = '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}';
        } else {
          continue;
        }
      } catch (e) {
        continue;
      }

      final spans = tds[2].querySelectorAll('span');
      final List<String> spanTexts = spans
          .map((s) => s.text.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      final List<int> regularNumbers = [];

      // Mega 6/45 has no special numbers. All numbers are regular.
      for (final text in spanTexts) {
        final int? val = int.tryParse(text);
        if (val != null) {
          regularNumbers.add(val);
        }
      }

      results.add(
        LotteryDrawModel(
          id: drawId,
          date: dateFormatted,
          regular: regularNumbers,
          special: [],
        ),
      );
    }

    return results;
  }
}
