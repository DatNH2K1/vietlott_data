import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLocalizations {
  AppLocalizations(this.locale);
  final Locale locale;
  Map<String, String> _localizedStrings = {};

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('vi'));
  }

  Future<bool> load() async {
    // Load the language JSON file from the "assets/lang" folder
    final jsonString = await rootBundle.loadString(
      'assets/lang/${locale.languageCode}.json',
    );
    final jsonMap = json.decode(jsonString) as Map<String, dynamic>;

    _localizedStrings = jsonMap.map((key, value) {
      return MapEntry(key, value.toString());
    });

    return true;
  }

  String translate(String key) {
    return _localizedStrings[key] ?? key;
  }

  // Getters for convenience
  String get appTitle => translate('appTitle');
  String get reSync => translate('reSync');
  String get syncing => translate('syncing');
  String get errorOccurred => translate('errorOccurred');
  String get retry => translate('retry');
  String get noResults => translate('noResults');
  String get threeRecentDraws => translate('threeRecentDraws');
  String get drawNumber => translate('drawNumber');
  String get winningNumbers => translate('winningNumbers');
  String get settings => translate('settings');
  String get theme => translate('theme');
  String get language => translate('language');
  String get themeLightRed => translate('themeLightRed');
  String get themeDarkSlate => translate('themeDarkSlate');
  String get themeGoldLuxury => translate('themeGoldLuxury');
  String get themeCyberMidnight => translate('themeCyberMidnight');
  String get themeNordicMint => translate('themeNordicMint');
  String get langVi => translate('langVi');
  String get langEn => translate('langEn');
  String get close => translate('close');
  String get latestResults => translate('latestResults');
  String get lotteryProducts => translate('lotteryProducts');
  String get mega645Desc => translate('mega645Desc');
  String get power655Desc => translate('power655Desc');
  String get power535Desc => translate('power535Desc');
  String get appInfo => translate('appInfo');
  String get version => translate('version');
  String get appDisclaimer => translate('appDisclaimer');
  String get suggestions => translate('suggestions');
  String get suggestionTitle => translate('suggestionTitle');
  String get selectProduct => translate('selectProduct');
  String get selectInterval => translate('selectInterval');
  String get allTime => translate('allTime');
  String get last30Draws => translate('last30Draws');
  String get last5Draws => translate('last5Draws');
  String get criteriaWeights => translate('criteriaWeights');
  String get coldNumbers => translate('coldNumbers');
  String get oddEven => translate('oddEven');
  String get frequency => translate('frequency');
  String get trend => translate('trend');
  String get regionBalance => translate('regionBalance');
  String get frequentPairs => translate('frequentPairs');
  String get generate => translate('generate');
  String get suggestedNumbers => translate('suggestedNumbers');
  String get noDataToAnalyze => translate('noDataToAnalyze');
  String get mlModelTitle => translate('mlModelTitle');
  String get mlModelDesc => translate('mlModelDesc');
  String get analyzingMl => translate('analyzingMl');
  String get regenerate => translate('regenerate');
  String get lastUpdated => translate('lastUpdated');
  String get theoreticalProbabilities => translate('theoreticalProbabilities');
  String get aiPerformance => translate('aiPerformance');
  String get loadingAiPerformance => translate('loadingAiPerformance');
  String get prizeColumn => translate('prizeColumn');
  String get theoreticalColumn => translate('theoreticalColumn');
  String get aiActualColumn => translate('aiActualColumn');
  String get breakEvenRate => translate('breakEvenRate');
  String get roiRate => translate('roiRate');

  String get updateAvailable => translate('updateAvailable');
  String get updateBtn => translate('updateBtn');
  String get updateLater => translate('updateLater');
  String get checkingUpdate => translate('checkingUpdate');
  String get appUpToDate => translate('appUpToDate');
  String get checkUpdateError => translate('checkUpdateError');
  String get checkUpdate => translate('checkUpdate');
  String get batteryOptTitle => translate('batteryOptTitle');
  String get batteryOptMessage => translate('batteryOptMessage');
  String get batteryOptDisableBtn => translate('batteryOptDisableBtn');
  String get batteryOptLaterBtn => translate('batteryOptLaterBtn');

  String translateWithParam(String key, String paramKey, String paramValue) {
    final raw = translate(key);
    return raw.replaceAll('{$paramKey}', paramValue);
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['vi', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
