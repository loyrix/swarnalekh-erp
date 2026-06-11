import 'package:flutter/material.dart';

final localeNotifier = ValueNotifier<Locale?>(null);

void setAppLocale(Locale? locale) {
  localeNotifier.value = locale;
}
