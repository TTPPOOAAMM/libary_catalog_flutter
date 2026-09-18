import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/config.dart';
import '../core/permissions.dart';
import '../models/auth_tokens.dart';
import '../models/user.dart';
import '../repositories/auth_repository.dart';

class AuthNotifier extends ChangeNotifier {
  final AuthRepository _authRepository;
  final SharedPreferences _prefs;

  AuthNotifier(this._authRepository, this._prefs) {
    _initSession();
  }

  static const _kAccessToken = 'auth_access_token';
  static const _kRefreshToken = 'auth_refresh_token';
  static const _kUser = 'auth_user_profile';
  static const _kSessionStart = 'auth_session_start_time';
  static const _kLastActivity = 'auth_last_activity_time';

  User? _currentUser;
  AuthTokens? _tokens;
  bool _isInitialized = false;

  Timer? _inactivityTimer;
  Timer? _warningTicker;
  Timer? _absoluteSessionTimer;

  bool _isWarningActive = false;
  int _secondsUntilLogout = 30;
  String? _sessionExpiredMessage;

  User? get currentUser => _currentUser;
  UserRole get currentRole => _currentUser?.role ?? UserRole.reader;
  bool get isAuthenticated => _tokens != null && _currentUser != null;
  bool get isInitialized => _isInitialized;
  String? get accessToken => _tokens?.accessToken;
  bool get isWarningActive => _isWarningActive;
  int get secondsUntilLogout => _secondsUntilLogout;
  String? get sessionExpiredMessage => _sessionExpiredMessage;

  void clearSessionMessage() {
    _sessionExpiredMessage = null;
    notifyListeners();
  }

  Future<void> _initSession() async {
    final access = _prefs.getString(_kAccessToken);
    final refresh = _prefs.getString(_kRefreshToken);
    final userRaw = _prefs.getString(_kUser);
    final startRaw = _prefs.getInt(_kSessionStart);
    final lastActRaw = _prefs.getInt(_kLastActivity);

    if (access != null &&
        refresh != null &&
        userRaw != null &&
        startRaw != null &&
        lastActRaw != null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final sessionStart = startRaw;
      final lastAct = lastActRaw;

      if (now - sessionStart >
          SessionConfig.absoluteSessionTimeout.inMilliseconds) {
        await logout(
            reason: 'Время вашей сессии истекло (30 мин). Войдите снова.');
        _isInitialized = true;
        notifyListeners();
        return;
      }

      if (now - lastAct > SessionConfig.inactivityTimeout.inMilliseconds) {
        await logout(reason: 'Вы были отключены из-за неактивности (3 мин).');
        _isInitialized = true;
        notifyListeners();
        return;
      }

      try {
        _tokens = AuthTokens(accessToken: access, refreshToken: refresh);
        _currentUser =
            User.fromJson(jsonDecode(userRaw) as Map<String, dynamic>);
        _startTimers(
            resumeRemainingInactivityMs:
                SessionConfig.inactivityTimeout.inMilliseconds -
                    (now - lastAct));
      } catch (_) {
        await logout();
      }
    }

    _isInitialized = true;
    notifyListeners();
  }

  void recordActivity() {
    if (!isAuthenticated) return;

    if (_isWarningActive) {
      _isWarningActive = false;
      _warningTicker?.cancel();
      notifyListeners();
    }

    _prefs.setInt(_kLastActivity, DateTime.now().millisecondsSinceEpoch);
    _resetInactivityTimer();
  }

  void _startTimers({int? resumeRemainingInactivityMs}) {
    _inactivityTimer?.cancel();
    _warningTicker?.cancel();
    _absoluteSessionTimer?.cancel();

    final startRaw =
        _prefs.getInt(_kSessionStart) ?? DateTime.now().millisecondsSinceEpoch;
    final elapsed = DateTime.now().millisecondsSinceEpoch - startRaw;
    final remainingAbs =
        SessionConfig.absoluteSessionTimeout.inMilliseconds - elapsed;

    if (remainingAbs <= 0) {
      logout(reason: 'Превышена максимальная длительность сессии.');
      return;
    }

    _absoluteSessionTimer = Timer(Duration(milliseconds: remainingAbs), () {
      logout(reason: 'Сессия завершена по истечении 30 минут.');
    });

    final timeoutDuration = resumeRemainingInactivityMs != null
        ? Duration(milliseconds: resumeRemainingInactivityMs)
        : SessionConfig.inactivityTimeout;

    _scheduleInactivity(timeoutDuration);
  }

  void _scheduleInactivity(Duration totalDuration) {
    _inactivityTimer?.cancel();
    _warningTicker?.cancel();

    final warnAfter = totalDuration - SessionConfig.inactivityWarningDuration;

    if (warnAfter.isNegative) {
      _triggerWarning(totalDuration.inSeconds);
      return;
    }

    _inactivityTimer = Timer(warnAfter, () {
      _triggerWarning(SessionConfig.inactivityWarningDuration.inSeconds);
    });
  }

  void _triggerWarning(int secondsLeft) {
    _isWarningActive = true;
    _secondsUntilLogout = secondsLeft;
    notifyListeners();

    _warningTicker?.cancel();
    _warningTicker = Timer.periodic(const Duration(seconds: 1), (timer) {
      _secondsUntilLogout--;
      if (_secondsUntilLogout <= 0) {
        timer.cancel();
        logout(reason: 'Вы были отключены из-за отсутствия активности.');
      } else {
        notifyListeners();
      }
    });
  }

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    _warningTicker?.cancel();
    _isWarningActive = false;

    _scheduleInactivity(SessionConfig.inactivityTimeout);
  }

  Future<void> login(String username, String password) async {
    final (user, tokens) = await _authRepository.login(username, password);
    await _persistSession(user, tokens);
  }

  Future<void> register({
    required String username,
    required String password,
    required String fullName,
    required String email,
    required String role,
  }) async {
    final (user, tokens) = await _authRepository.register(
      username: username,
      password: password,
      fullName: fullName,
      email: email,
      role: role,
    );
    await _persistSession(user, tokens);
  }

  Future<void> _persistSession(User user, AuthTokens tokens) async {
    _currentUser = user;
    _tokens = tokens;
    _sessionExpiredMessage = null;

    final now = DateTime.now().millisecondsSinceEpoch;
    await _prefs.setString(_kAccessToken, tokens.accessToken);
    await _prefs.setString(_kRefreshToken, tokens.refreshToken);
    await _prefs.setString(_kUser, jsonEncode(user.toJson()));
    await _prefs.setInt(_kSessionStart, now);
    await _prefs.setInt(_kLastActivity, now);

    _startTimers();
    notifyListeners();
  }

  Future<String?> refreshAccessToken() async {
    final curRefresh = _tokens?.refreshToken;
    if (curRefresh == null || curRefresh.isEmpty) return null;

    try {
      final newTokens = await _authRepository.refreshToken(curRefresh);
      _tokens = newTokens;
      await _prefs.setString(_kAccessToken, newTokens.accessToken);
      if (newTokens.refreshToken.isNotEmpty) {
        await _prefs.setString(_kRefreshToken, newTokens.refreshToken);
      }
      return newTokens.accessToken;
    } catch (_) {
      return null;
    }
  }

  Future<void> simulateDevToolsRoleChange(UserRole spoofedRole) async {
    if (_currentUser == null) return;
    _currentUser = _currentUser!.copyWith(role: spoofedRole);
    await _prefs.setString(_kUser, jsonEncode(_currentUser!.toJson()));
    notifyListeners();
  }

  Future<void> logout({String? reason}) async {
    _inactivityTimer?.cancel();
    _warningTicker?.cancel();
    _absoluteSessionTimer?.cancel();

    _currentUser = null;
    _tokens = null;
    _isWarningActive = false;
    _sessionExpiredMessage = reason;

    await _prefs.remove(_kAccessToken);
    await _prefs.remove(_kRefreshToken);
    await _prefs.remove(_kUser);
    await _prefs.remove(_kSessionStart);
    await _prefs.remove(_kLastActivity);

    notifyListeners();
  }
}
