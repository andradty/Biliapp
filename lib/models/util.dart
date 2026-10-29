import 'package:cloud_firestore/cloud_firestore.dart';

/// Menerima Timestamp (disarankan) atau string ISO.
DateTime? toDate(dynamic v) {
  if (v is Timestamp) return v.toDate();
  if (v is String) return DateTime.tryParse(v);
  return null;
}
