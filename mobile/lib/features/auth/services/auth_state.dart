import '../models/auth_models.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

enum AuthStatus { loading, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;

  const AuthState({required this.status, this.user, this.errorMessage});

  const AuthState.loading()
    : status = AuthStatus.loading,
      user = null,
      errorMessage = null;

  const AuthState.authenticated(this.user)
    : status = AuthStatus.authenticated,
      errorMessage = null;

  const AuthState.unauthenticated([this.errorMessage])
    : status = AuthStatus.unauthenticated,
      user = null;
}

class AuthController {
  final AuthService _authService;

  AuthState _state = const AuthState.loading();

  AuthState get state => _state;

  AuthController({AuthService? authService})
    : _authService = authService ?? AuthService();

  Future<void> restoreSession() async {
    _state = const AuthState.loading();

    try {
      final accessToken = await _authService.getAccessToken();

      if (accessToken == null || accessToken.isEmpty) {
        _state = const AuthState.unauthenticated();
        return;
      }

      final user = await _authService.getCurrentUser();

      _state = AuthState.authenticated(user);
    } catch (e) {
      _state = AuthState.unauthenticated(e.toString());
    }
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      await _authService.login(LoginRequest(email: email, password: password));

      final user = await _authService.getCurrentUser();

      _state = AuthState.authenticated(user);

      return user;
    } catch (e) {
      _state = AuthState.unauthenticated(e.toString());

      rethrow;
    }
  }

  Future<UserModel> register({
    required String username,
    required String email,
    required String displayName,
    required String password,
  }) async {
    try {
      await _authService.register(
        RegisterRequest(
          username: username,
          email: email,
          displayName: displayName,
          password: password,
        ),
      );

      final user = await _authService.getCurrentUser();

      _state = AuthState.authenticated(user);

      return user;
    } catch (e) {
      _state = AuthState.unauthenticated(e.toString());

      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _authService.logout();
    } finally {
      _state = const AuthState.unauthenticated();
    }
  }

  void dispose() {
    _authService.dispose();
  }
}
