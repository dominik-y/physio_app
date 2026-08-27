import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The resolved answer to "who is this signed-in user inside the app":
/// a physio (custom claim) or a linked patient (patients doc with their uid).
class AuthIdentity extends Equatable {
  final String uid;
  final bool isPhysio;

  /// The patients/{id} doc ID this account is linked to; null for physios.
  final String? patientId;
  final String displayName;

  const AuthIdentity({
    required this.uid,
    required this.isPhysio,
    this.patientId,
    required this.displayName,
  });

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'isPhysio': isPhysio,
        'patientId': patientId,
        'displayName': displayName,
      };

  factory AuthIdentity.fromJson(Map<String, dynamic> json) => AuthIdentity(
        uid: json['uid'] as String,
        isPhysio: json['isPhysio'] as bool,
        patientId: json['patientId'] as String?,
        displayName: json['displayName'] as String? ?? '',
      );

  @override
  List<Object?> get props => [uid, isPhysio, patientId, displayName];
}

/// Offline cold start (plan correction #3): ID tokens expire after 1 h and
/// claim resolution needs the network, so the last resolved identity is
/// persisted and trusted immediately on boot; a background refresh corrects
/// it when the network returns.
class IdentityCache {
  static const _key = 'auth_identity_v1';
  final SharedPreferences _prefs;

  IdentityCache(this._prefs);

  /// Returns the cached identity only if it belongs to [uid] — a stale entry
  /// from a previously signed-in account must never leak across users.
  AuthIdentity? read(String uid) {
    final raw = _prefs.getString(_key);
    if (raw == null) return null;
    try {
      final identity =
          AuthIdentity.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      return identity.uid == uid ? identity : null;
    } catch (_) {
      // Any corrupt shape (not just bad JSON — wrong field types too) must
      // read as "no cache", never crash the boot path.
      return null;
    }
  }

  Future<void> write(AuthIdentity identity) =>
      _prefs.setString(_key, jsonEncode(identity.toJson()));

  Future<void> clear() => _prefs.remove(_key);
}
