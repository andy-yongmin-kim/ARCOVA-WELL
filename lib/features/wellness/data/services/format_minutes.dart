/// Minutes → "6h 18m" (data-layer helper, independent of the UI formatter).
String fmtMinutes(int minutes) {
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (h <= 0) return '${m}m';
  return '${h}h ${m}m';
}
