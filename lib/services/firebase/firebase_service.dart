// Путь: lib/services/firebase/firebase_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../offline/offline_storage_service.dart';
import '../../utils/network_utils.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final OfflineStorageService _offlineStorage = OfflineStorageService();

  // Ключи для хранения пользовательских данных
  static const String _authUserEmailKey = 'auth_user_email';
  static const String _authUserIdKey = 'auth_user_id';
  static const String _authUserDisplayNameKey = 'auth_user_display_name';

  // Кэшированные данные для быстрого доступа
  static String? _cachedUserId;

  // Получение текущего пользователя
  User? get currentUser => _auth.currentUser;

  // Проверка авторизации пользователя
  bool get isUserLoggedIn => _auth.currentUser != null;

  // Получение ID текущего пользователя
  String? get currentUserId {
    if (_auth.currentUser != null) {
      return _auth.currentUser!.uid;
    } else {
      // Если пользователь не авторизован, пытаемся получить ID из кэша
      return _getCachedUserId();
    }
  }

  // Получение ID пользователя из кэша
  String? _getCachedUserId() {
    // Используем статическую переменную для кэширования userId
    if (_cachedUserId != null) {
      return _cachedUserId;
    }

    // Если у нас нет закэшированного ID, возвращаем null
    // А затем асинхронно пытаемся загрузить его из SharedPreferences
    _loadCachedUserIdAsync();
    return null;
  }

  // Асинхронная загрузка userId из SharedPreferences
  Future<void> _loadCachedUserIdAsync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedUserId = prefs.getString(_authUserIdKey);
      debugPrint('Загружен кэшированный ID пользователя: $_cachedUserId');
    } catch (e) {
      debugPrint('Ошибка при загрузке ID пользователя из кэша: $e');
    }
  }

  Future<SharedPreferences> getSharedPreferences() async {
    return await SharedPreferences.getInstance();
  }

  // Регистрация нового пользователя с email и паролем
  Future<UserCredential> registerWithEmailAndPassword(
      String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Сохраняем данные пользователя в кэш
      await _cacheUserData(userCredential.user);

      return userCredential;
    } catch (e) {
      // Обработка ошибок Firebase и преобразование их в понятные пользователю сообщения
      throw _handleAuthException(e);
    }
  }

  // Вход пользователя с email и паролем
  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Сохраняем данные пользователя в кэш
      await _cacheUserData(userCredential.user);

      return userCredential;
    } catch (e) {
      // Обработка ошибок Firebase и преобразование их в понятные пользователю сообщения
      throw _handleAuthException(e);
    }
  }

  // Сохранение данных пользователя в кэш
  Future<void> _cacheUserData(User? user) async {
    if (user == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_authUserEmailKey, user.email ?? '');
      await prefs.setString(_authUserIdKey, user.uid);
      await prefs.setString(_authUserDisplayNameKey, user.displayName ?? '');

      // Обновляем статический кэш
      _cachedUserId = user.uid;

      // Также сохраняем в сервисе офлайн хранилища
      await _offlineStorage.saveUserData({
        'uid': user.uid,
        'email': user.email ?? '',
        'displayName': user.displayName ?? '',
      });

      debugPrint('Данные пользователя сохранены в кэш');
    } catch (e) {
      debugPrint('Ошибка при сохранении данных пользователя в кэш: $e');
    }
  }

  // Обработка ошибок аутентификации Firebase
  String _handleAuthException(dynamic e) {
    String errorMessage = 'Произошла неизвестная ошибка';

    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'Пользователь с таким email не найден';
          break;
        case 'wrong-password':
          errorMessage = 'Неверный пароль';
          break;
        case 'invalid-email':
          errorMessage = 'Неверный формат email';
          break;
        case 'user-disabled':
          errorMessage = 'Учетная запись отключена';
          break;
        case 'email-already-in-use':
          errorMessage = 'Email уже используется другим аккаунтом';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Операция не разрешена';
          break;
        case 'weak-password':
          errorMessage = 'Слишком простой пароль';
          break;
        case 'network-request-failed':
          errorMessage = 'Проверьте подключение к интернету';
          break;
        case 'too-many-requests':
          errorMessage = 'Слишком много попыток входа. Попробуйте позже';
          break;
        default:
          errorMessage = 'Ошибка: ${e.code}';
      }
    }

    debugPrint('Firebase Auth Error: $e');
    return errorMessage;
  }

  // Выход пользователя
  Future<void> signOut() async {
    // Удаляем кэшированные данные пользователя
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_authUserEmailKey);
      await prefs.remove(_authUserIdKey);
      await prefs.remove(_authUserDisplayNameKey);

      // Очищаем статический кэш
      _cachedUserId = null;
    } catch (e) {
      debugPrint('Ошибка при удалении кэшированных данных пользователя: $e');
    }

    await _auth.signOut();
  }

  // Отправка письма для сброса пароля
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Обновление данных пользователя в Firestore
  Future<void> updateUserData(String userId, Map<String, dynamic> data) async {
    try {
      // Проверяем подключение к интернету
      final isOnline = await NetworkUtils.isNetworkAvailable();

      if (isOnline) {
        // Если есть интернет, обновляем данные в Firestore
        await _firestore.collection('users').doc(userId).set(data, SetOptions(merge: true));
      }

      // В любом случае, сохраняем данные локально
      await _offlineStorage.saveUserData(data);
    } catch (e) {
      debugPrint('Ошибка при обновлении данных пользователя: $e');

      // В случае ошибки, сохраняем данные локально
      try {
        await _offlineStorage.saveUserData(data);
      } catch (_) {
        rethrow;
      }
    }
  }

  // Получение данных пользователя из Firestore
  Future<DocumentSnapshot> getUserData(String userId) async {
    try {
      // Проверяем подключение к интернету
      final isOnline = await NetworkUtils.isNetworkAvailable();

      if (isOnline) {
        // Если есть интернет, получаем данные из Firestore
        return await _firestore.collection('users').doc(userId).get();
      } else {
        // Если нет интернета, возвращаем исключение
        throw Exception('Нет подключения к интернету');
      }
    } catch (e) {
      debugPrint('Ошибка при получении данных пользователя: $e');
      rethrow;
    }
  }

  // Добавление заметки о рыбалке
  Future<DocumentReference> addFishingNote(Map<String, dynamic> noteData) async {
    try {
      return await _firestore.collection('fishing_notes').add(noteData);
    } catch (e) {
      debugPrint('Ошибка при добавлении заметки: $e');
      rethrow;
    }
  }

  // Обновление заметки о рыбалке
  Future<void> updateFishingNote(String noteId, Map<String, dynamic> noteData) async {
    try {
      await _firestore.collection('fishing_notes').doc(noteId).update(noteData);
    } catch (e) {
      debugPrint('Ошибка при обновлении заметки: $e');
      rethrow;
    }
  }

  // Получение заметок пользователя
  Future<QuerySnapshot> getUserFishingNotes(String userId) async {
    try {
      return await _firestore
          .collection('fishing_notes')
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .get();
    } catch (e) {
      // Если ошибка связана с индексом, пытаемся выполнить запрос без сортировки
      if (e.toString().contains('index')) {
        debugPrint('Ошибка индекса в Firestore, выполняем запрос без сортировки');
        return await _firestore
            .collection('fishing_notes')
            .where('userId', isEqualTo: userId)
            .get();
      }
      debugPrint('Ошибка при получении заметок пользователя: $e');
      rethrow;
    }
  }

  // Загрузка изображения в Firebase Storage
  Future<String> uploadImage(String path, List<int> imageBytes) async {
    try {
      final ref = _storage.ref().child(path);
      // Преобразуем List<int> в Uint8List
      final Uint8List uint8List = Uint8List.fromList(imageBytes);
      final uploadTask = ref.putData(uint8List);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Ошибка при загрузке изображения: $e');
      rethrow;
    }
  }
}