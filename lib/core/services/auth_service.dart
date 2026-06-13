import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Firebase 인증 서비스
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Google Sign-In for Android (serverClientId not needed for mobile)
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  /// 현재 유저
  User? get currentUser => _auth.currentUser;

  /// 로그인 상태
  bool get isLoggedIn => currentUser != null;

  /// 유저 ID
  String? get userId => currentUser?.uid;

  /// 인증 상태 스트림
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Google 로그인
  Future<User?> signInWithGoogle() async {
    try {
      // Google 로그인 다이얼로그
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // 사용자가 로그인 취소
        return null;
      }

      // 인증 정보 가져오기
      final GoogleSignInAuthentication googleAuth = 
          await googleUser.authentication;

      // Firebase 자격증명 생성
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Firebase 로그인
      final UserCredential userCredential = 
          await _auth.signInWithCredential(credential);

      return userCredential.user;
    } catch (e) {
      print('Google 로그인 에러: $e');
      rethrow;
    }
  }

  /// 로그아웃
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}

/// Auth 서비스 Provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// 현재 유저 상태 Provider
final currentUserProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

/// 로그인 상태 Provider
final isLoggedInProvider = Provider<bool>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.when(
    data: (user) => user != null,
    loading: () => false,
    error: (_, __) => false,
  );
});

