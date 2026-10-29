import 'util.dart';

/// Cermin node RTDB `devices/{id}/status` yang ditulis alat tiap beberapa detik.
class StatusAlat {
  final String? firmware;
  final int? rssi; // dBm
  final DateTime? lastSeen;

  const StatusAlat({this.firmware, this.rssi, this.lastSeen});

  static StatusAlat? dari(Object? raw) {
    if (raw is! Map) return null;
    final m = Map<String, dynamic>.from(raw);
    final ls = m['last_seen'];
    final rssi = m['rssi'];
    final fw = m['firmware'];
    return StatusAlat(
      firmware: (fw is String && fw.trim().isNotEmpty) ? fw : null,
      rssi: (rssi is num && rssi != 0) ? rssi.toInt() : null,
      lastSeen: (ls is num && ls > 0)
          ? DateTime.fromMillisecondsSinceEpoch(ls.toInt())
          : toDate(ls),
    );
  }
}
