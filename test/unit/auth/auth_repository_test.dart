import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:expence_flow_pro/features/auth/repository/auth_repository.dart';

import '../../helpers/mocks.mocks.dart';
import '../../helpers/test_helpers.dart';

// Local mocks for Firebase internals not covered by the shared mocks file
@GenerateMocks([
  FirebaseAuth,
  FirebaseFirestore,
  UserCredential,
  CollectionReference,
  DocumentReference,
  DocumentSnapshot,
])
import 'auth_repository_test.mocks.dart';

void main() {
  late AuthRepository repository;
  late MockFirebaseAuth mockAuth;
  late MockFirebaseFirestore mockFirestore;
  late MockUserCredential mockCredential;
  late MockUser mockUser;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    mockFirestore = MockFirebaseFirestore();
    mockCredential = MockUserCredential();
    mockUser = MockUser();

    repository = AuthRepository(auth: mockAuth, firestore: mockFirestore);

    when(mockCredential.user).thenReturn(mockUser);
    when(mockUser.uid).thenReturn(kTestUserId);
    when(mockUser.email).thenReturn(kTestEmail);
    when(mockUser.displayName).thenReturn(kTestName);
  });

  // ─── signIn ────────────────────────────────────────────────────────────────

  group('signIn', () {
    test('returns user on success', () async {
      when(mockAuth.signInWithEmailAndPassword(
        email: kTestEmail,
        password: kTestPassword,
      )).thenAnswer((_) async => mockCredential);

      final user = await repository.signIn(
        email: kTestEmail,
        password: kTestPassword,
      );

      expect(user, equals(mockUser));
    });

    test('propagates FirebaseAuthException from Firebase', () async {
      when(mockAuth.signInWithEmailAndPassword(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenThrow(FirebaseAuthException(code: 'user-not-found'));

      expect(
        () => repository.signIn(email: kTestEmail, password: 'wrong'),
        throwsA(isA<FirebaseAuthException>()),
      );
    });

    test('propagates wrong-password exception', () async {
      when(mockAuth.signInWithEmailAndPassword(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenThrow(FirebaseAuthException(code: 'wrong-password'));

      expect(
        () => repository.signIn(email: kTestEmail, password: 'badpass'),
        throwsA(isA<FirebaseAuthException>()),
      );
    });
  });

  // ─── signUp ────────────────────────────────────────────────────────────────

  group('signUp', () {
    late MockCollectionReference<Map<String, dynamic>> mockCollection;
    late MockDocumentReference<Map<String, dynamic>> mockDoc;
    late MockDocumentSnapshot<Map<String, dynamic>> mockSnapshot;

    setUp(() {
      mockCollection = MockCollectionReference();
      mockDoc = MockDocumentReference();
      mockSnapshot = MockDocumentSnapshot();

      when(mockFirestore.collection('users')).thenReturn(mockCollection);
      when(mockCollection.doc(kTestUserId)).thenReturn(mockDoc);
      when(mockDoc.get()).thenAnswer((_) async => mockSnapshot);
      when(mockSnapshot.exists).thenReturn(false);
      when(mockDoc.set(any)).thenAnswer((_) async {});
      when(mockUser.updateDisplayName(any)).thenAnswer((_) async {});
    });

    test('returns user and creates Firestore document on first sign up', () async {
      when(mockAuth.createUserWithEmailAndPassword(
        email: kTestEmail,
        password: kTestPassword,
      )).thenAnswer((_) async => mockCredential);

      final user = await repository.signUp(
        name: kTestName,
        email: kTestEmail,
        password: kTestPassword,
      );

      expect(user, equals(mockUser));
      verify(mockDoc.set(argThat(containsPair('uid', kTestUserId)))).called(1);
    });

    test('does NOT overwrite existing Firestore document', () async {
      when(mockSnapshot.exists).thenReturn(true);
      when(mockAuth.createUserWithEmailAndPassword(
        email: kTestEmail,
        password: kTestPassword,
      )).thenAnswer((_) async => mockCredential);

      await repository.signUp(
        name: kTestName,
        email: kTestEmail,
        password: kTestPassword,
      );

      verifyNever(mockDoc.set(any));
    });

    test('propagates email-already-in-use exception', () async {
      when(mockAuth.createUserWithEmailAndPassword(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenThrow(FirebaseAuthException(code: 'email-already-in-use'));

      expect(
        () => repository.signUp(
          name: kTestName,
          email: kTestEmail,
          password: kTestPassword,
        ),
        throwsA(isA<FirebaseAuthException>()),
      );
    });
  });

  // ─── signOut ───────────────────────────────────────────────────────────────

  group('signOut', () {
    test('calls FirebaseAuth.signOut()', () async {
      when(mockAuth.signOut()).thenAnswer((_) async {});
      await repository.signOut();
      verify(mockAuth.signOut()).called(1);
    });
  });

  // ─── sendPasswordResetEmail ────────────────────────────────────────────────

  group('sendPasswordResetEmail', () {
    test('delegates to FirebaseAuth', () async {
      when(mockAuth.sendPasswordResetEmail(email: kTestEmail))
          .thenAnswer((_) async {});

      await repository.sendPasswordResetEmail(kTestEmail);

      verify(mockAuth.sendPasswordResetEmail(email: kTestEmail)).called(1);
    });

    test('propagates invalid-email exception', () async {
      when(mockAuth.sendPasswordResetEmail(email: anyNamed('email')))
          .thenThrow(FirebaseAuthException(code: 'invalid-email'));

      expect(
        () => repository.sendPasswordResetEmail('not-an-email'),
        throwsA(isA<FirebaseAuthException>()),
      );
    });
  });
}
