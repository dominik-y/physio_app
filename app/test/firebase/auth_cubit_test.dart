import 'package:flutter_test/flutter_test.dart';
import 'package:physio_app/firebase/auth_cubit.dart';
import 'package:physio_app/firebase/auth_identity.dart';
import 'package:physio_app/firebase/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('IdentityCache', () {
    test('corrupt cache shape reads as no cache, never throws', () async {
      SharedPreferences.setMockInitialValues(
          {'auth_identity_v1': '{"uid": 42, "isPhysio": "yes"}'});
      final cache = IdentityCache(await SharedPreferences.getInstance());
      expect(cache.read('42'), isNull);
    });

    test('round-trips an identity and scopes it to the uid', () async {
      final cache = await freshCache();
      await cache.write(ana);
      expect(cache.read('uid-ana'), ana);
      expect(cache.read('uid-other'), isNull,
          reason: 'must not leak across accounts');
      await cache.clear();
      expect(cache.read('uid-ana'), isNull);
    });
  });

  group('AuthCubit', () {
    test('starts unknown, goes signedOut on null uid', () async {
      final service = FakeAuthService();
      final cubit = AuthCubit(service, await freshCache());
      expect(cubit.state, const AuthUnknown());
      service.emitUid(null);
      await pump();
      expect(cubit.state, const AuthSignedOut());
      await cubit.close();
    });

    test('no cache: resolving then ready, and writes the cache', () async {
      final service = FakeAuthService()..resolveResult = tomislav;
      final cache = await freshCache();
      final cubit = AuthCubit(service, cache);
      final states = <AuthState>[];
      final sub = cubit.stream.listen(states.add);
      service.emitUid('uid-physio');
      await pump();
      await pump();
      expect(states, const [AuthResolving(), AuthReady(tomislav)]);
      expect(cache.read('uid-physio'), tomislav);
      await sub.cancel();
      await cubit.close();
    });

    test('cached identity boots the app before resolution finishes', () async {
      final service = FakeAuthService()..resolveFailure = AuthFailure.network;
      final cache = await freshCache();
      await cache.write(ana);
      final cubit = AuthCubit(service, cache);
      service.emitUid('uid-ana');
      await pump();
      await pump();
      // Offline cold start: cache wins, network failure doesn't evict it.
      expect(cubit.state, const AuthReady(ana));
      expect(service.resolveCalls, 1);
      await cubit.close();
    });

    test('background refresh replaces a stale cached identity', () async {
      const renamed = AuthIdentity(
          uid: 'uid-ana',
          isPhysio: false,
          patientId: 'pat-ana',
          displayName: 'Ana Novak');
      final service = FakeAuthService()..resolveResult = renamed;
      final cache = await freshCache();
      await cache.write(ana);
      final cubit = AuthCubit(service, cache);
      service.emitUid('uid-ana');
      await pump();
      await pump();
      expect(cubit.state, const AuthReady(renamed));
      expect(cache.read('uid-ana'), renamed);
      await cubit.close();
    });

    test('notLinked evicts even a cached identity', () async {
      final service = FakeAuthService()..resolveFailure = AuthFailure.notLinked;
      final cache = await freshCache();
      await cache.write(ana);
      final cubit = AuthCubit(service, cache);
      service.emitUid('uid-ana');
      await pump();
      await pump();
      expect(cubit.state, const AuthResolveFailed(AuthFailure.notLinked));
      await cubit.close();
    });

    test('no cache + failure = resolveFailed; retry recovers', () async {
      final service = FakeAuthService()..resolveFailure = AuthFailure.network;
      final cubit = AuthCubit(service, await freshCache());
      service.emitUid('uid-physio');
      await pump();
      await pump();
      expect(cubit.state, const AuthResolveFailed(AuthFailure.network));
      service
        ..resolveFailure = null
        ..resolveResult = tomislav;
      await cubit.retryResolve();
      expect(cubit.state, const AuthReady(tomislav));
      await cubit.close();
    });

    test('redeemInvite never flashes notLinked mid-flow', () async {
      const luka = AuthIdentity(
          uid: 'uid-new',
          isPhysio: false,
          patientId: 'pat-luka',
          displayName: 'Luka Babić');
      final service = FakeAuthService()
        // Mid-flow resolution would yield notLinked — the suppressed stream
        // must never let that reach the UI.
        ..resolveResult = luka;
      final cubit = AuthCubit(service, await freshCache());
      service.emitUid(null);
      await pump();
      final states = <AuthState>[];
      final sub = cubit.stream.listen(states.add);
      final failure = await cubit.redeemInvite(
          code: 'LK7-3FQ9', email: 'luka@example.com', password: 'pw123456');
      await pump();
      expect(failure, isNull);
      expect(states.whereType<AuthResolveFailed>(), isEmpty);
      expect(cubit.state, const AuthReady(luka));
      await sub.cancel();
      await cubit.close();
    });

    test('redeemInvite invalid code: reports failure, stays signedOut',
        () async {
      final service = FakeAuthService()
        ..redeemResult = AuthFailure.invalidInvite;
      final cubit = AuthCubit(service, await freshCache());
      service.emitUid(null);
      await pump();
      final failure = await cubit.redeemInvite(
          code: 'XXX-XXXX', email: 'luka@example.com', password: 'pw123456');
      await pump();
      expect(failure, AuthFailure.invalidInvite);
      expect(cubit.state, const AuthSignedOut());
      await cubit.close();
    });

    test('notLinked recovery: redeemForCurrentUser lands Ready', () async {
      final service = FakeAuthService()..resolveFailure = AuthFailure.notLinked;
      final cubit = AuthCubit(service, await freshCache());
      service.emitUid('uid-new');
      await pump();
      await pump();
      expect(cubit.state, const AuthResolveFailed(AuthFailure.notLinked));
      const luka = AuthIdentity(
          uid: 'uid-new',
          isPhysio: false,
          patientId: 'pat-luka',
          displayName: 'Luka Babić');
      service
        ..resolveFailure = null
        ..resolveResult = luka;
      final failure = await cubit.redeemForCurrentUser('LK7-3FQ9');
      expect(failure, isNull);
      expect(cubit.state, const AuthReady(luka));
      await cubit.close();
    });

    test('stale resolution after sign-out is discarded, cache stays clean',
        () async {
      final service = FakeAuthService()
        ..resolveResult = ana
        ..resolveDelay = const Duration(milliseconds: 40);
      final cache = await freshCache();
      final cubit = AuthCubit(service, cache);
      service.emitUid('uid-ana');
      await pump();
      service.emitUid(null); // signed out while resolution is in flight
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(cubit.state, const AuthSignedOut());
      expect(cache.read('uid-ana'), isNull,
          reason: 'a stale resolve must not repoison the cleared cache');
      await cubit.close();
    });

    test('account switch mid-resolve: old identity never surfaces as new',
        () async {
      final service = FakeAuthService()
        ..resolveResult = ana
        ..resolveDelay = const Duration(milliseconds: 40);
      final cache = await freshCache();
      final cubit = AuthCubit(service, cache);
      service.emitUid('uid-ana'); // slow resolution for A starts
      await pump();
      service
        ..resolveResult = tomislav
        ..resolveDelay = Duration.zero;
      service.emitUid('uid-physio'); // B signs in, resolves instantly
      await pump();
      await pump();
      expect(cubit.state, const AuthReady(tomislav));
      await Future<void>.delayed(const Duration(milliseconds: 80));
      // A's late completion must not clobber B's session or cache.
      expect(cubit.state, const AuthReady(tomislav));
      expect(cache.read('uid-physio'), tomislav);
      expect(cache.read('uid-ana'), isNull);
      await cubit.close();
    });

    test('redeem network failure with live session resyncs to notLinked',
        () async {
      final service = FakeAuthService()
        ..redeemResult = AuthFailure.network // account kept, link batch died
        ..resolveFailure = AuthFailure.notLinked;
      final cubit = AuthCubit(service, await freshCache());
      service.emitUid(null);
      await pump();
      final failure = await cubit.redeemInvite(
          code: 'LK7-3FQ9', email: 'luka@example.com', password: 'pw123456');
      expect(failure, AuthFailure.network);
      await pump();
      await pump();
      // The suppressed signed-in event was replayed: the user lands on the
      // notLinked recovery screen, not a dead login form.
      expect(cubit.state, const AuthResolveFailed(AuthFailure.notLinked));
      await cubit.close();
    });

    test('externally-driven sign-out clears the cached identity', () async {
      final service = FakeAuthService()..resolveResult = ana;
      final cache = await freshCache();
      final cubit = AuthCubit(service, cache);
      service.emitUid('uid-ana');
      await pump();
      await pump();
      expect(cache.read('uid-ana'), ana);
      service.emitUid(null); // token revoked server-side, not cubit.signOut()
      await pump();
      await pump();
      expect(cubit.state, const AuthSignedOut());
      expect(cache.read('uid-ana'), isNull);
      await cubit.close();
    });

    test('signOut clears the cache and lands signedOut', () async {
      final service = FakeAuthService()..resolveResult = ana;
      final cache = await freshCache();
      final cubit = AuthCubit(service, cache);
      service.emitUid('uid-ana');
      await pump();
      await pump();
      await cubit.signOut();
      await pump();
      expect(cubit.state, const AuthSignedOut());
      expect(cache.read('uid-ana'), isNull);
      await cubit.close();
    });
  });
}
