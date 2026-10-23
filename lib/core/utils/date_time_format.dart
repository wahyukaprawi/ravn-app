import 'package:intl/intl.dart';

String formatDateTime(String? value) {
  if (value == null || value.isEmpty) return '';
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return value;
  return DateFormat('d MMM yyyy • HH:mm').format(parsed.toLocal());
}

String formatDate(String? value) {
  if (value == null || value.isEmpty) return '';
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return value;
  return DateFormat('d MMM yyyy').format(parsed.toLocal());
}
