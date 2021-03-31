import 'package:flutter/material.dart';

class IntlString {
  final String en;
  final String tc;
  final String sc;

  IntlString({@required this.en, @required this.tc, @required this.sc});

  String localeString(Locale locale) {
    print(locale.toLanguageTag());
    switch (locale.toLanguageTag()) {
      case 'en':
        {
          return this.en;
        }
        break;
      case 'zh-Hant-HK':
        {
          return this.tc;
        }
        break;
      default:
        return this.en;
    }
  }
}
