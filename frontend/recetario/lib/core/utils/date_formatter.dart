import 'package:intl/intl.dart';

class DateFormatter {
  static String formatShort(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  static String formatFull(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return 'Hace ${difference.inSeconds} segundos';
    } else if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes} minutos';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours} horas';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} días';
    } else {
      return formatShort(date);
    }
  }

  static String formatLongDate(DateTime date) {
    return DateFormat('EEEE, d MMMM yyyy', 'es_ES').format(date);
  }
}