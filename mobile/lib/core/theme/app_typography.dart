import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class PaceUpTypography {
  static TextStyle display(Color color) {
    return GoogleFonts.barlowCondensed(
      color: color,
      fontWeight: FontWeight.w700,
      fontSize: 48,
      height: 0.95,
      letterSpacing: -1.0,
    );
  }

  static TextStyle heroMetric(Color color) {
    return GoogleFonts.barlowCondensed(
      color: color,
      fontWeight: FontWeight.w600,
      fontSize: 72,
      height: 0.95,
      letterSpacing: -1.0,
      fontFeatures: const [
        FontFeature.tabularFigures(),
      ],
    );
  }

  static TextStyle largeMetric(Color color) {
    return GoogleFonts.barlowCondensed(
      color: color,
      fontWeight: FontWeight.w600,
      fontSize: 44,
      height: 1,
      letterSpacing: -0.8,
      fontFeatures: const [
        FontFeature.tabularFigures(),
      ],
    );
  }

  static TextStyle heading(Color color) {
    return GoogleFonts.barlowCondensed(
      color: color,
      fontWeight: FontWeight.w700,
      fontSize: 28,
      height: 1.05,
      letterSpacing: -0.5,
    );
  }

  static TextStyle sectionTitle(Color color) {
    return GoogleFonts.manrope(
      color: color,
      fontWeight: FontWeight.w800,
      fontSize: 11,
      height: 1.2,
      letterSpacing: 1.3,
    );
  }

  static TextStyle body(Color color) {
    return GoogleFonts.manrope(
      color: color,
      fontWeight: FontWeight.w400,
      fontSize: 13,
      height: 1.6,
    );
  }

  static TextStyle bodyMedium(Color color) {
    return GoogleFonts.manrope(
      color: color,
      fontWeight: FontWeight.w600,
      fontSize: 13,
      height: 1.5,
    );
  }

  static TextStyle label(Color color) {
    return GoogleFonts.manrope(
      color: color,
      fontWeight: FontWeight.w700,
      fontSize: 10,
      height: 1.2,
      letterSpacing: 1.4,
    );
  }
}