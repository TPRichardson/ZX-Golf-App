import 'package:flutter/material.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';

// Centralised formatting utilities to eliminate duplicated date, duration,
// and score helpers across feature screens.

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// Format date as "15 Mar 2026". With [includeTime]: "15 Mar 2026, 14:30".
/// With [includeWeekday]: "Mon, Mar 15".
String formatDate(DateTime? dt, {
  bool includeTime = false,
  bool includeWeekday = false,
}) {
  if (dt == null) return 'Unknown';
  if (includeWeekday) {
    return '${_weekdays[dt.weekday - 1]}, ${_months[dt.month - 1]} ${dt.day}';
  }
  final date = '${dt.day} ${_months[dt.month - 1]} ${dt.year}';
  if (!includeTime) return date;
  return '$date, '
      '${dt.hour.toString().padLeft(2, '0')}:'
      '${dt.minute.toString().padLeft(2, '0')}';
}

/// Format date as compact numeric "3/15/2026".
String formatDateNumeric(DateTime dt) {
  return '${dt.month}/${dt.day}/${dt.year}';
}

/// Format seconds as "1h 30m" or "5:08". Technique mode: "05:08".
String formatDuration(int seconds, {bool padMinutes = false}) {
  final hours = seconds ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;
  final secs = seconds % 60;
  if (hours > 0) {
    return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
  }
  final m = padMinutes
      ? minutes.toString().padLeft(2, '0')
      : minutes.toString();
  return '$m:${secs.toString().padLeft(2, '0')}';
}

/// Map a 0–5 score to a RAG colour token.
Color scoreColor(double score) {
  if (score >= 3.5) return ColorTokens.successDefault;
  if (score >= 2.0) return ColorTokens.primaryDefault;
  return ColorTokens.warningIntegrity;
}

/// Map 0–5 raw score to 0–5 stars, rounded to nearest 0.5.
double scoreToStars(double score) {
  return (score.clamp(0.0, 5.0) * 2).roundToDouble() / 2;
}
