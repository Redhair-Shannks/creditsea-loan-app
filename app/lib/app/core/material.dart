/// The single place the app imports Flutter's Material library.
///
/// Flutter 3.47 deprecated `package:flutter/material.dart` in favour of the separate
/// `material_ui` package. GetX 4.x (GetMaterialApp, Get.snackbar, Get.dialog, ...) is still
/// built on the framework's Material classes, and `material_ui` ships its own copies of those
/// types, so mixing the two would break theming and navigation. Until GetX moves over, the app
/// uses the framework's Material library, and switching later is a one-line change here.
library;

// ignore: deprecated_member_use
export 'package:flutter/material.dart';
