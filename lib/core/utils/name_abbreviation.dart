import '../models/student_model.dart';

/// Builds a short label for map markers (e.g. "John Doe" → "JD").
String nameAbbreviation(
  String firstName,
  String lastName, {
  String? fallback,
}) {
  final first = firstName.trim();
  final last = lastName.trim();

  if (first.isNotEmpty && last.isNotEmpty) {
    return '${first[0]}${last[0]}'.toUpperCase();
  }
  if (first.length >= 2) return first.substring(0, 2).toUpperCase();
  if (first.isNotEmpty) return first.toUpperCase();
  if (last.length >= 2) return last.substring(0, 2).toUpperCase();
  if (last.isNotEmpty) return last.toUpperCase();

  final fb = (fallback ?? '').trim();
  if (fb.length >= 2) return fb.substring(0, 2).toUpperCase();
  if (fb.isNotEmpty) return fb.toUpperCase();
  return '?';
}

String studentAbbreviation(Student student) {
  return nameAbbreviation(
    student.firstName,
    student.lastName,
    fallback: student.studentId,
  );
}

/// Joins multiple student abbreviations for a shared pickup stop.
String combinedStudentAbbreviations(Iterable<String> abbreviations) {
  final labels = abbreviations
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
  if (labels.isEmpty) return '?';
  if (labels.length == 1) return labels.first;

  final joined = labels.join('/');
  if (joined.length <= 5) return joined;
  return '${joined.substring(0, 4)}…';
}
