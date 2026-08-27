import 'package:flutter_test/flutter_test.dart';
import 'package:physio_app/firebase/firebase_auth_service.dart';

void main() {
  test('normalizeInviteCode canonicalizes anything a patient might type', () {
    expect(normalizeInviteCode('LK7-3FQ9'), 'LK7-3FQ9');
    expect(normalizeInviteCode('lk73fq9'), 'LK7-3FQ9');
    expect(normalizeInviteCode(' lk7 3fq9 '), 'LK7-3FQ9');
    expect(normalizeInviteCode('lk7-3fq9'), 'LK7-3FQ9');
    // Wrong length passes through (still trimmed/uppercased) — the lookup
    // simply misses and reports an invalid code.
    expect(normalizeInviteCode(' abc '), 'ABC');
    expect(normalizeInviteCode(''), '');
  });
}
