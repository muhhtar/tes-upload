import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppTextStyles {
  static TextTheme get textTheme {
    final base = GoogleFonts.nunitoTextTheme();

    return base.copyWith(
      bodyLarge: GoogleFonts.nunito(fontSize: 16, height: 1.5),
      bodyMedium: GoogleFonts.nunito(fontSize: 16, height: 1.5),
      headlineLarge: GoogleFonts.lora(fontSize: 32, height: 1.3),
      headlineMedium: GoogleFonts.lora(fontSize: 28, height: 1.3),
      titleLarge: GoogleFonts.lora(fontSize: 24, height: 1.3),
    );
  }
}
