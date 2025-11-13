// lib/services/audit_logger.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Lightweight Firestore audit logger that does NOT depend on FirebaseAuth.
/// Make sure Firebase.initializeApp() is called before using this.
class AuditLogger {
  // Flat audit trail (existing)
  static final _logs = FirebaseFirestore.instance.collection('audit_logs');

  /// Generic audit event (append-only) -> collection: audit_logs
  static Future<void> log({
    required String action,                 // e.g., "login_success", "profile_update"
    String? operation,                      // "create" | "update" | "delete" | "read"
    String? collection,                     // affected collection
    String? docId,                          // affected doc id
    Map<String, dynamic>? before,           // snapshot BEFORE
    Map<String, dynamic>? after,            // snapshot AFTER
    Map<String, dynamic>? meta,             // extra info (screen, reason, device, etc.)
    String? uid,                            // optional user id
    String? email,                          // optional email
  }) async {
    final payload = <String, dynamic>{
      'uid': uid ?? '-',
      'email': email ?? '-',
      'action': action,
      'operation': operation,
      'collection': collection,
      'docId': docId,
      'before': before ?? const <String, dynamic>{},
      'after':  after  ?? const <String, dynamic>{},
      'meta':   meta   ?? const <String, dynamic>{},
      'ts': FieldValue.serverTimestamp(),
    };
    await _logs.add(payload);
  }

  /// Tiny diff for flat maps (string/num/bool)
  static Map<String, dynamic> diff(
      Map<String, dynamic> a,
      Map<String, dynamic> b,
      ) {
    final out = <String, dynamic>{};
    final keys = {...a.keys, ...b.keys};
    for (final k in keys) {
      final va = a[k];
      final vb = b[k];
      if (va != vb) out[k] = {'from': va, 'to': vb};
    }
    return out;
  }

  /// CREATE helper
  static Future<void> logCreate({
    required String collection,
    required String docId,
    required Map<String, dynamic> after,
    Map<String, dynamic>? meta,
    String? uid,
    String? email,
  }) {
    return log(
      action: 'create',
      operation: 'create',
      collection: collection,
      docId: docId,
      after: after,
      meta: meta,
      uid: uid,
      email: email,
    );
  }

  /// UPDATE helper (fixed meta merge)
  static Future<void> logUpdate({
    required String collection,
    required String docId,
    required Map<String, dynamic> before,
    required Map<String, dynamic> after,
    Map<String, dynamic>? meta,
    String? uid,
    String? email,
  }) {
    final mergedMeta = {...?meta, 'diff': diff(before, after)};
    return log(
      action: 'update',
      operation: 'update',
      collection: collection,
      docId: docId,
      before: before,
      after: after,
      meta: mergedMeta,
      uid: uid,
      email: email,
    );
  }

  /// DELETE helper
  static Future<void> logDelete({
    required String collection,
    required String docId,
    required Map<String, dynamic> before,
    Map<String, dynamic>? meta,
    String? uid,
    String? email,
  }) {
    return log(
      action: 'delete',
      operation: 'delete',
      collection: collection,
      docId: docId,
      before: before,
      meta: meta,
      uid: uid,
      email: email,
    );
  }

  // ---------------- Per-day structure using SERVER TIME + time as doc ID ----------------
  // Writes to: log/{yyyy-MM-dd}/time/{HHmmssSSS[ _xxxx ]}
  // Fields: { date, time, action, ts, uid?, email?, ...meta }
  //
  // We derive the day from the resolved serverTimestamp, not the device clock.
  // tzOffsetMinutes: set your local offset (e.g., 480 for UTC+8).
  static Future<void> logPerDay({
    required String action,
    Map<String, dynamic>? meta,
    String? uid,
    String? email,
    int tzOffsetMinutes = 480, // Malaysia/Singapore UTC+8 by default
  }) async {
    final fs = FirebaseFirestore.instance;

    // 1) Write to a temp inbox to get the resolved server timestamp
    final temp = await fs.collection('log_inbox').add({
      'action': action,
      'uid': uid ?? '-',
      'email': email ?? '-',
      ...?meta,
      'ts': FieldValue.serverTimestamp(),
    });

    // 2) Read back to obtain server time
    final snap = await temp.get();
    final data = snap.data() as Map<String, dynamic>?;
    final ts = (data?['ts'] as Timestamp?)?.toDate();

    // Clean up temp regardless
    await temp.delete();

    if (ts == null) return; // rare

    // 3) Convert server UTC to your local zone by offset
    final local = ts.add(Duration(minutes: tzOffsetMinutes));

    final dateStr = _fmtDate(local);         // yyyy-MM-dd
    final timeStr = _fmtTime(local);         // HH:mm:ss
    final timeId  = _fmtTimeIdMs(local);     // HHmmssSSS (for doc id)

    // 4) Prepare payload
    final payload = {
      'date': dateStr,
      'time': timeStr,
      'action': action,
      'uid': uid ?? '-',
      'email': email ?? '-',
      ...?meta,
      'ts': ts, // actual server time
    };

    // 5) Write under log/{date}/time/{timeId}, avoid collisions
    final col = fs.collection('log').doc(dateStr).collection('time');
    var id = timeId;
    if ((await col.doc(id).get()).exists) {
      id = '${timeId}_${_rand4()}'; // ultra-rare collision safeguard
    }
    await col.doc(id).set(payload); // create (append-only per your rules)
  }

  // ---- formatting helpers (no intl dependency)
  static String _pad2(int v) => v.toString().padLeft(2, '0');
  static String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${_pad2(d.month)}-${_pad2(d.day)}';
  static String _fmtTime(DateTime d) =>
      '${_pad2(d.hour)}:${_pad2(d.minute)}:${_pad2(d.second)}';
  static String _fmtTimeIdMs(DateTime d) =>
      '${_pad2(d.hour)}${_pad2(d.minute)}${_pad2(d.second)}${d.millisecond.toString().padLeft(3, '0')}';
  static String _rand4() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final n = DateTime.now().microsecondsSinceEpoch;
    return List.generate(4, (i) => chars[(n >> (i * 5)) % chars.length]).join();
  }
}
