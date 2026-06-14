import 'dart:convert';

import 'package:html/parser.dart' show parse;
import 'package:http/http.dart' as http;
import 'package:vietlott_data/models/lottery_draw_model.dart';
import 'package:vietlott_data/services/crawler/adapters/base_adapters.dart';

/// Crawler adapter for Vietlott Product 655 (Power 6/55).
class Power655Adapter implements BaseCrawlerAdapter {
  @override
  String get productName => 'power655';

  @override
  Future<List<LotteryDrawModel>> fetchPage(int pageIndex) async {
    final url = Uri.parse(
      'https://vietlott.vn/ajaxpro/Vietlott.PlugIn.WebParts.Game655CompareWebPart,Vietlott.PlugIn.WebParts.ashx',
    );

    final headers = {
      'Content-Type': 'text/plain; charset=utf-8',
      'X-AjaxPro-Method': 'ServerSideDrawResult',
      'User-Agent':
          'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:128.0) Gecko/20100101 Firefox/128.0',
    };

    final body = {
      'ORenderInfo': {
        'SiteId': 'main.frontend.vi',
        'SiteAlias': 'main.vi',
        'UserSessionId': '',
        'SiteLang': 'vi',
        'IsPageDesign': false,
        'ExtraParam1': '',
        'ExtraParam2': '',
        'ExtraParam3': '',
        'SiteURL': '',
        'WebPage': null,
        'SiteName': 'Vietlott',
        'OrgPageAlias': null,
        'PageAlias': null,
        'RefKey': null,
        'FullPageAlias': null,
      },
      'Key': 'd0ea794f',
      'GameDrawId': '',
      'ArrayNumbers': List.generate(5, (_) => List.generate(55, (_) => '')),
      'CheckMulti': false,
      'PageIndex': pageIndex,
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

      final resJson = jsonDecode(response.body) as Map<String, dynamic>;
      final htmlContent =
          (resJson['value'] as Map<String, dynamic>?)?['HtmlContent']
              as String?;
      if (htmlContent == null || htmlContent.isEmpty) {
        return [];
      }

      return _parseHtml(htmlContent);
    } catch (e) {
      print('Error fetching page $pageIndex for product 655: $e');
      return [];
    }
  }

  List<LotteryDrawModel> _parseHtml(String htmlContent) {
    final document = parse(htmlContent);
    final results = <LotteryDrawModel>[];

    final rows = document.querySelectorAll('table tr');
    for (var i = 1; i < rows.length; i++) {
      final tds = rows[i].querySelectorAll('td');
      if (tds.length < 3) continue;

      final dateRaw = tds[0].text.trim();
      final drawId = tds[1].text.trim();

      // Parse date format DD/MM/YYYY to YYYY-MM-DD
      String dateFormatted;
      try {
        final parts = dateRaw.split('/');
        if (parts.length == 3) {
          dateFormatted =
              '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}';
        } else {
          continue;
        }
      } catch (e) {
        continue;
      }

      final spans = tds[2].querySelectorAll('span');
      final spanTexts = spans
          .map((s) => s.text.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      final regularNumbers = <int>[];
      final specialNumbers = <int>[];

      final pipeIndex = spanTexts.indexOf('|');
      if (pipeIndex != -1) {
        // Numbers before '|' are regular
        for (var j = 0; j < pipeIndex; j++) {
          final val = int.tryParse(spanTexts[j]);
          if (val != null) {
            regularNumbers.add(val);
          }
        }
        // Numbers after '|' are special
        for (var j = pipeIndex + 1; j < spanTexts.length; j++) {
          final val = int.tryParse(spanTexts[j]);
          if (val != null) {
            specialNumbers.add(val);
          }
        }
      } else {
        // Fallback: assume first 6 are regular and the rest are special
        final allNums = spanTexts
            .map(int.tryParse)
            .where((n) => n != null)
            .cast<int>()
            .toList();

        if (allNums.length >= 7) {
          regularNumbers.addAll(allNums.sublist(0, 6));
          specialNumbers.addAll(allNums.sublist(6));
        } else {
          regularNumbers.addAll(allNums);
        }
      }

      results.add(
        LotteryDrawModel(
          id: drawId,
          date: dateFormatted,
          regular: regularNumbers,
          special: specialNumbers,
        ),
      );
    }

    return results;
  }
}
