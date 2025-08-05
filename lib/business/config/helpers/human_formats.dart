import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:yo_te_pago/business/config/constants/formats.dart';


class HumanFormats {

  HumanFormats._();

  static String toAmount(double number, [String? symbol, int? decimals]) {

    return NumberFormat.currency(
        decimalDigits: decimals ?? AppFormats.maxDecimalDigits,
        symbol: symbol ?? '',
        locale: 'es_US'
    ).format(number);
  }

  static String toShortDate(DateTime date, {bool isShortFormat = true}) {
    String strFormat = AppFormats.date;
    if (!isShortFormat) {
      strFormat = AppFormats.odooDateTime;
    }
    final formatter = DateFormat(strFormat);

    return formatter.format(date);
  }

  static String toShortTime(DateTime date) {
    final formatter = DateFormat(AppFormats.time);

    return formatter.format(date);
  }

  static TimeOfDay? tryTimeOfDay(String formattedTime) {
    final parts = formattedTime.split(':');
    if (parts.length >= 2) {
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts[1]) ?? 0;

      return TimeOfDay(hour: hour, minute: minute);
    }

    return null;
  }

  static DateTime toDateTime(String dateTime) {
    final formatter = DateFormat(AppFormats.dateTime);

    return formatter.parse(dateTime);
  }

}