import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? _currentUser;
  bool _isLoading = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;

  // Khởi tạo và kiểm tra người dùng đã đăng nhập
  Future<void> initAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser != null) {
        // Lấy thông tin user từ Firestore
        final doc = await _firestore
            .collection('users')
            .doc(firebaseUser.uid)
            .get();

        if (doc.exists) {
          _currentUser = UserModel.fromJson({
            'id': firebaseUser.uid,
            ...doc.data()!,
          });
        }
      }
    } catch (e) {
      debugPrint('Init auth error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Đăng ký tài khoản mới với Firebase
  Future<String?> register(String email, String password, String name) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Tạo user trong Firebase Auth
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Lưu thông tin user vào Firestore
      final newUser = UserModel(
        id: credential.user!.uid,
        email: email,
        name: name,
      );

      await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .set(newUser.toJson());

      // Đăng xuất sau khi đăng ký (để user phải login lại)
      await _auth.signOut();

      _isLoading = false;
      notifyListeners();
      return null; // Success
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();

      switch (e.code) {
        case 'weak-password':
          return 'Mật khẩu quá yếu';
        case 'email-already-in-use':
          return 'Email đã được sử dụng';
        case 'invalid-email':
          return 'Email không hợp lệ';
        default:
          return 'Đăng ký thất bại: ${e.message}';
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return 'Có lỗi xảy ra: $e';
    }
  }

  // Đăng nhập với Firebase
  Future<String?> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Lấy thông tin user từ Firestore
      final doc = await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .get();

      if (doc.exists) {
        _currentUser = UserModel.fromJson({
          'id': credential.user!.uid,
          ...doc.data()!,
        });
      }

      _isLoading = false;
      notifyListeners();
      return null; // Success
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();

      switch (e.code) {
        case 'user-not-found':
          return 'Không tìm thấy tài khoản';
        case 'wrong-password':
          return 'Sai mật khẩu';
        case 'invalid-email':
          return 'Email không hợp lệ';
        case 'user-disabled':
          return 'Tài khoản đã bị vô hiệu hóa';
        case 'invalid-credential':
          return 'Email hoặc mật khẩu không đúng';
        default:
          return 'Đăng nhập thất bại: ${e.message}';
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return 'Có lỗi xảy ra: $e';
    }
  }

  // Đăng xuất
  Future<void> logout() async {
    try {
      await _auth.signOut();
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Logout error: $e');
    }
  }

  // Cập nhật thông tin user
  Future<String?> updateProfile(String name) async {
    if (_currentUser == null) return 'Chưa đăng nhập';

    try {
      await _firestore.collection('users').doc(_currentUser!.id).update({
        'name': name,
      });

      _currentUser = _currentUser!.copyWith(name: name);
      notifyListeners();
      return null; // Success
    } catch (e) {
      return 'Cập nhật thất bại: $e';
    }
  }

  // Đổi mật khẩu
  Future<String?> changePassword(String currentPassword, String newPassword) async {
    if (_currentUser == null) return 'Chưa đăng nhập';

    try {
      // Re-authenticate user
      final credential = EmailAuthProvider.credential(
        email: _currentUser!.email,
        password: currentPassword,
      );
      await _auth.currentUser!.reauthenticateWithCredential(credential);

      // Change password
      await _auth.currentUser!.updatePassword(newPassword);
      return null; // Success
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'wrong-password':
          return 'Mật khẩu hiện tại không đúng';
        case 'weak-password':
          return 'Mật khẩu mới quá yếu';
        default:
          return 'Đổi mật khẩu thất bại: ${e.message}';
      }
    } catch (e) {
      return 'Có lỗi xảy ra: $e';
    }
  }
}