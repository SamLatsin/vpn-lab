import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:vpn_lab/constants.dart';

Flushbar getFlushError(String text) {
  return Flushbar(
    blockBackgroundInteraction: true,
    flushbarPosition: FlushbarPosition.TOP,
    backgroundColor: bgSecondaryDark.withOpacity(0.5),
    titleColor: primaryLight,
    messageColor: primaryLight,
    titleSize: 18,
    messageSize: 16,
    borderWidth: 1,
    borderColor: bgSecondaryGradStart,
    boxShadows: const [
      BoxShadow(
        color: bgSecondaryDark,
        spreadRadius: 5,
        blurRadius: 40,
      ),
    ],
    margin: const EdgeInsets.all(10),
    borderRadius: BorderRadius.circular(8),
    icon: const Icon(
      Icons.info_outline,
      size: 28.0,
      color: red,
    ),
    title: 'Error',
    message: text,
    duration: const Duration(seconds: 3),
  );
}

Flushbar getFlushSuccess(String text) {
  return Flushbar(
    blockBackgroundInteraction: true,
    flushbarPosition: FlushbarPosition.TOP,
    backgroundColor: bgSecondaryDark.withOpacity(0.5),
    titleColor: primaryLight,
    messageColor: primaryLight,
    titleSize: 18,
    messageSize: 16,
    borderWidth: 1,
    borderColor: bgSecondaryGradStart,
    boxShadows: const [
      BoxShadow(
        color: bgSecondaryDark,
        spreadRadius: 5,
        blurRadius: 40,
      ),
    ],
    margin: const EdgeInsets.all(10),
    borderRadius: BorderRadius.circular(8),
    icon: const Icon(
      Icons.info_outline,
      size: 28.0,
      color: green,
    ),
    title: 'Success',
    message: text,
    duration: const Duration(seconds: 3),
  );
}
