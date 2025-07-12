// Путь: lib/repositories/user_repository.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/user_consent_service.dart';
import '../services/firebase/firebase_service.dart';
import '../utils/network_utils.dart';

class UserRepository {
  // 🔥 ИСПРАВЛЕНО: Правильные имена переменных
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserConsentService _consentService = UserConsentService();
  final FirebaseService _firebaseService = FirebaseService();

  // Получение текущего пользователя
  User? get currentUser => _auth.currentUser;

  // Получение ID текущего пользователя
  String? get currentUserId => _firebaseService.currentUserId; // Используем FirebaseService для поддержки офлайн

  // Проверка авторизации пользователя
  bool get isUserLoggedIn => _firebaseService.isUserLoggedIn; // Используем FirebaseService для поддержки офлайн

  // 🔥 ИСПРАВЛЕНО: Получение данных пользователя с поддержкой офлайн режима
  Future<UserModel?> getUserData(String userId) async {
    try {
      debugPrint('👤 Получение данных пользователя: $userId');

      // Проверяем подключение к интернету
      final isOnline = await NetworkUtils.isNetworkAvailable();

      if (isOnline) {
        // Если есть интернет, получаем данные из Firestore
        final doc = await _firestore.collection('users').doc(userId).get();

        if (!doc.exists) {
          debugPrint('⚠️ Пользователь не найден в Firestore: $userId');
          return null;
        }

        final userData = UserModel.fromJson(doc.data() as Map<String, dynamic>);
        debugPrint('✅ Данные пользователя получены из Firestore');

        return userData;
      } else {
        // Если нет интернета, пытаемся получить данные из кэша
        debugPrint('📱 Офлайн режим: получение данных из кэша');

        try {
          final doc = await _firestore
              .collection('users')
              .doc(userId)
              .get(const GetOptions(source: Source.cache));

          if (doc.exists) {
            debugPrint('✅ Данные пользователя получены из кэша');
            return UserModel.fromJson(doc.data() as Map<String, dynamic>);
          }
        } catch (e) {
          debugPrint('⚠️ Ошибка получения из кэша: $e');
        }

        debugPrint('❌ Данные пользователя недоступны в офлайн режиме');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Ошибка при получении данных пользователя: $e');
      return null;
    }
  }

  // Получение данных текущего пользователя
  Future<UserModel?> getCurrentUserData() async {
    final userId = currentUserId;
    if (userId == null) {
      debugPrint('⚠️ getCurrentUserData: Пользователь не авторизован');
      return null;
    }

    return getUserData(userId);
  }

  // 🔥 ИСПРАВЛЕНО: Стрим для получения данных пользователя с обработкой ошибок
  Stream<UserModel?> getUserStream() {
    final userId = currentUserId;
    if (userId == null) {
      debugPrint('⚠️ getUserStream: Пользователь не авторизован');
      return Stream.value(null);
    }

    debugPrint('📡 Создание стрима для пользователя: $userId');

    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      try {
        if (!snapshot.exists) {
          debugPrint('⚠️ Документ пользователя не существует: $userId');
          return null;
        }

        final data = snapshot.data();
        if (data == null) {
          debugPrint('⚠️ Данные пользователя null: $userId');
          return null;
        }

        debugPrint('✅ Получены обновленные данные пользователя через стрим');
        return UserModel.fromJson(data);
      } catch (e) {
        debugPrint('❌ Ошибка парсинга данных пользователя в стриме: $e');
        return null;
      }
    }).handleError((error) {
      debugPrint('❌ Ошибка в стриме пользователя: $error');
      return null;
    });
  }

  // 🔥 ИСПРАВЛЕНО: Обновление данных пользователя с офлайн поддержкой
  Future<void> updateUserData(Map<String, dynamic> userData) async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        throw Exception('Пользователь не авторизован');
      }

      debugPrint('👤 Обновление данных пользователя: $userId');
      debugPrint('📝 Данные для обновления: $userData');

      // Добавляем timestamp обновления
      final dataToUpdate = {
        ...userData,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Проверяем подключение к интернету
      final isOnline = await NetworkUtils.isNetworkAvailable();

      if (isOnline) {
        // Если есть интернет, обновляем данные в Firestore
        await _firestore
            .collection('users')
            .doc(userId)
            .set(dataToUpdate, SetOptions(merge: true));

        debugPrint('✅ Данные пользователя обновлены в Firestore');
      } else {
        // Если нет интернета, сохраняем обновление для последующей синхронизации
        debugPrint('📱 Офлайн режим: данные будут синхронизированы позже');

        // Firestore автоматически сохранит изменения для офлайн синхронизации
        await _firestore
            .collection('users')
            .doc(userId)
            .set(dataToUpdate, SetOptions(merge: true));

        debugPrint('✅ Данные пользователя сохранены для офлайн синхронизации');
      }
    } catch (e) {
      debugPrint('❌ Ошибка при обновлении данных пользователя: $e');
      rethrow;
    }
  }

  // 🔥 ИСПРАВЛЕНО: Обновление аватара пользователя с офлайн поддержкой
  Future<void> updateUserAvatar(String avatarUrl) async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        throw Exception('Пользователь не авторизован');
      }

      debugPrint('👤 Обновление аватара пользователя: $userId');
      debugPrint('🖼️ URL аватара: $avatarUrl');

      final updateData = {
        'avatarUrl': avatarUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Проверяем подключение к интернету
      final isOnline = await NetworkUtils.isNetworkAvailable();

      if (isOnline) {
        await _firestore.collection('users').doc(userId).update(updateData);
        debugPrint('✅ Аватар пользователя обновлен в Firestore');
      } else {
        // В офлайн режиме используем set с merge для создания документа если его нет
        await _firestore
            .collection('users')
            .doc(userId)
            .set(updateData, SetOptions(merge: true));
        debugPrint('✅ Аватар пользователя сохранен для офлайн синхронизации');
      }
    } catch (e) {
      debugPrint('❌ Ошибка при обновлении аватара пользователя: $e');
      rethrow;
    }
  }

  // 🔥 ИСПРАВЛЕНО: Создание или обновление профиля пользователя
  Future<void> createUserProfile(Map<String, dynamic> profileData) async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        throw Exception('Пользователь не авторизован');
      }

      debugPrint('👤 Создание/обновление профиля пользователя: $userId');

      // Используем FirebaseService для работы с профилем
      await _firebaseService.createUserProfile(profileData);

      debugPrint('✅ Профиль пользователя создан/обновлен');
    } catch (e) {
      debugPrint('❌ Ошибка при создании/обновлении профиля: $e');
      rethrow;
    }
  }

  // 🔥 ИСПРАВЛЕНО: Получение профиля пользователя
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        debugPrint('⚠️ getUserProfile: Пользователь не авторизован');
        return null;
      }

      debugPrint('👤 Получение профиля пользователя: $userId');

      // Используем FirebaseService для работы с профилем
      final doc = await _firebaseService.getUserProfile();

      if (!doc.exists) {
        debugPrint('⚠️ Профиль пользователя не найден');
        return null;
      }

      final profileData = doc.data() as Map<String, dynamic>?;
      debugPrint('✅ Профиль пользователя получен');

      return profileData;
    } catch (e) {
      debugPrint('❌ Ошибка при получении профиля пользователя: $e');
      return null;
    }
  }

  // 🔥 ИСПРАВЛЕНО: Выход из аккаунта с правильной очисткой
  Future<void> signOut() async {
    try {
      // 🔥 ДОБАВЛЯЕМ ОТЛАДКУ ДЛЯ ПОИСКА МЕСТА ВЫЗОВА
      if (kDebugMode) {
        debugPrint('🚨 UserRepository.signOut() ВЫЗВАН!');
        debugPrint('📍 Stack trace вызова:');
        debugPrint(StackTrace.current.toString());
      }

      final userId = currentUserId;
      debugPrint('🚪 Начало выхода из аккаунта для пользователя: $userId');

      // ВАЖНО: Очищаем согласия ПЕРЕД выходом
      debugPrint('🧹 Очищаем согласия пользователя перед выходом');
      await _consentService.clearAllConsents();

      // Используем FirebaseService для корректного выхода
      debugPrint('🚪 Выполнение выхода через FirebaseService');
      await _firebaseService.signOut();

      debugPrint('✅ Успешный выход из аккаунта (с очисткой согласий)');
    } catch (e) {
      debugPrint('❌ Ошибка при выходе из аккаунта: $e');

      // В случае ошибки все равно пытаемся выйти из Firebase
      try {
        await _auth.signOut();
        debugPrint('✅ Аварийный выход из Firebase Auth выполнен');
      } catch (signOutError) {
        debugPrint(
          '❌ Критическая ошибка при выходе из Firebase: $signOutError',
        );
      }
    }
  }

  // 🔥 НОВОЕ: Удаление аккаунта пользователя
  Future<void> deleteAccount() async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        throw Exception('Пользователь не авторизован');
      }

      debugPrint('🗑️ Начало удаления аккаунта пользователя: $userId');

      // Очищаем согласия перед удалением
      await _consentService.clearAllConsents();

      // Используем FirebaseService для удаления аккаунта
      await _firebaseService.deleteAccount();

      debugPrint('✅ Аккаунт пользователя успешно удален');
    } catch (e) {
      debugPrint('❌ Ошибка при удалении аккаунта: $e');
      rethrow;
    }
  }

  // 🔥 НОВОЕ: Проверка состояния подключения
  Future<bool> isOnline() async {
    return await NetworkUtils.isNetworkAvailable();
  }

  // 🔥 НОВОЕ: Принудительная синхронизация данных пользователя
  Future<void> syncUserData() async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        debugPrint('⚠️ syncUserData: Пользователь не авторизован');
        return;
      }

      final isOnline = await this.isOnline();
      if (!isOnline) {
        debugPrint('📱 syncUserData: Нет подключения к интернету');
        return;
      }

      debugPrint('🔄 Принудительная синхронизация данных пользователя: $userId');

      // Получаем актуальные данные пользователя
      await getUserData(userId);

      debugPrint('✅ Синхронизация данных пользователя завершена');
    } catch (e) {
      debugPrint('❌ Ошибка при синхронизации данных пользователя: $e');
    }
  }

  // 🔥 НОВОЕ: Получение статуса авторизации
  Map<String, dynamic> getAuthStatus() {
    return {
      'isLoggedIn': isUserLoggedIn,
      'userId': currentUserId,
      'isOfflineMode': _firebaseService.isOfflineMode,
      'userEmail': currentUser?.email,
      'isEmailVerified': currentUser?.emailVerified ?? false,
    };
  }

  // 🔥 НОВОЕ: Подписка на изменения состояния авторизации
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // 🔥 НОВОЕ: Обновление email пользователя
  Future<void> updateUserEmail(String newEmail) async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('Пользователь не авторизован');
      }

      debugPrint('📧 Обновление email пользователя: ${user.uid}');
      debugPrint('📧 Новый email: $newEmail');

      // Обновляем email в Firebase Auth
      await user.updateEmail(newEmail);

      // Обновляем email в профиле пользователя
      await updateUserData({'email': newEmail});

      debugPrint('✅ Email пользователя успешно обновлен');
    } catch (e) {
      debugPrint('❌ Ошибка при обновлении email: $e');
      rethrow;
    }
  }

  // 🔥 НОВОЕ: Обновление пароля пользователя
  Future<void> updateUserPassword(String newPassword) async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('Пользователь не авторизован');
      }

      debugPrint('🔑 Обновление пароля пользователя: ${user.uid}');

      // Обновляем пароль в Firebase Auth
      await user.updatePassword(newPassword);

      debugPrint('✅ Пароль пользователя успешно обновлен');
    } catch (e) {
      debugPrint('❌ Ошибка при обновлении пароля: $e');
      rethrow;
    }
  }

  // 🔥 НОВОЕ: Отправка письма для подтверждения email
  Future<void> sendEmailVerification() async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('Пользователь не авторизован');
      }

      if (user.emailVerified) {
        debugPrint('ℹ️ Email уже подтвержден');
        return;
      }

      debugPrint('📧 Отправка письма для подтверждения email: ${user.email}');

      await user.sendEmailVerification();

      debugPrint('✅ Письмо для подтверждения email отправлено');
    } catch (e) {
      debugPrint('❌ Ошибка при отправке письма для подтверждения: $e');
      rethrow;
    }
  }

  // 🔥 НОВОЕ: Перезагрузка данных пользователя
  Future<void> reloadUser() async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('Пользователь не авторизован');
      }

      debugPrint('🔄 Перезагрузка данных пользователя: ${user.uid}');

      await user.reload();

      debugPrint('✅ Данные пользователя перезагружены');
    } catch (e) {
      debugPrint('❌ Ошибка при перезагрузке данных пользователя: $e');
      rethrow;
    }
  }
}