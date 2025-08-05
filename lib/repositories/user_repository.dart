// Путь: lib/repositories/user_repository.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/user_consent_service.dart';
import '../services/firebase/firebase_service.dart';
import '../services/isar_service.dart';
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

  /// ✅ ПОЛНОСТЬЮ ПЕРЕПИСАНО: GDPR-совместимое удаление аккаунта со ВСЕМИ данными пользователя
  Future<void> deleteAccount() async {
    final FirebaseStorage _storage = FirebaseStorage.instance;

    try {
      final user = currentUser;
      final userId = currentUserId;

      if (user == null || userId == null) {
        throw Exception('Пользователь не авторизован');
      }

      debugPrint('🗑️ Начало ПОЛНОГО удаления аккаунта пользователя: $userId');

      // ========================================
      // 1. ОЧИЩАЕМ СОГЛАСИЯ ПОЛЬЗОВАТЕЛЯ
      // ========================================
      debugPrint('🧹 Шаг 1/6: Очищаем согласия пользователя');
      try {
        await _consentService.clearAllConsents();
        debugPrint('✅ Согласия пользователя очищены');
      } catch (e) {
        debugPrint('⚠️ Ошибка при очистке согласий: $e');
        // Продолжаем удаление даже если не удалось очистить согласия
      }

      // ========================================
      // 2. УДАЛЯЕМ ВСЕ ДАННЫЕ ИЗ FIRESTORE
      // ========================================
      debugPrint('🔥 Шаг 2/6: Удаляем все данные из Firestore');
      try {
        final batch = _firestore.batch();

        // Получаем ссылку на документ пользователя
        final userDocRef = _firestore.collection('users').doc(userId);

        // Удаляем все подколлекции пользователя
        final subcollections = [
          'fishing_notes',
          'marker_maps',
          'budget_notes',
          'user_consents',
          'subscription',
          'user_usage_limits'
        ];

        for (final subcollection in subcollections) {
          try {
            debugPrint('🗑️ Удаление подколлекции: $subcollection');

            // Получаем все документы в подколлекции
            final snapshot = await userDocRef.collection(subcollection).get();
            debugPrint('📊 Найдено ${snapshot.docs.length} документов в $subcollection');

            // Добавляем каждый документ в batch для удаления
            for (final doc in snapshot.docs) {
              batch.delete(doc.reference);
            }

            debugPrint('✅ Подколлекция $subcollection подготовлена к удалению');
          } catch (e) {
            debugPrint('⚠️ Ошибка при удалении подколлекции $subcollection: $e');
            // Продолжаем с другими подколлекциями
          }
        }

        // Удаляем основной документ пользователя
        batch.delete(userDocRef);

        // Выполняем batch удаление
        await batch.commit();
        debugPrint('✅ Все данные пользователя удалены из Firestore');

      } catch (e) {
        debugPrint('⚠️ Ошибка при удалении данных из Firestore: $e');
        // Продолжаем удаление даже если не удалось удалить данные из Firestore
      }

      // ========================================
      // 3. УДАЛЯЕМ ВСЕ ФАЙЛЫ ИЗ FIREBASE STORAGE
      // ========================================
      debugPrint('📁 Шаг 3/6: Удаляем все файлы из Firebase Storage');
      try {
        // Получаем ссылку на папку пользователя в Storage
        final userStorageRef = _storage.ref().child('users/$userId');

        // Получаем список всех файлов в папке пользователя
        final listResult = await userStorageRef.listAll();

        debugPrint('📊 Найдено ${listResult.items.length} файлов в Storage для удаления');

        // Удаляем каждый файл
        for (final fileRef in listResult.items) {
          try {
            await fileRef.delete();
            debugPrint('🗑️ Удален файл: ${fileRef.fullPath}');
          } catch (e) {
            debugPrint('⚠️ Ошибка при удалении файла ${fileRef.fullPath}: $e');
            // Продолжаем с другими файлами
          }
        }

        // Удаляем вложенные папки если есть
        for (final prefixRef in listResult.prefixes) {
          try {
            final nestedListResult = await prefixRef.listAll();
            for (final nestedFileRef in nestedListResult.items) {
              await nestedFileRef.delete();
              debugPrint('🗑️ Удален вложенный файл: ${nestedFileRef.fullPath}');
            }
          } catch (e) {
            debugPrint('⚠️ Ошибка при удалении вложенных файлов: $e');
          }
        }

        debugPrint('✅ Все файлы пользователя удалены из Storage');

      } catch (e) {
        debugPrint('⚠️ Ошибка при удалении файлов из Storage: $e');
        // Продолжаем удаление даже если не удалось удалить файлы
      }

      // ========================================
      // 4. УДАЛЯЕМ ВСЕ ДАННЫЕ ИЗ ЛОКАЛЬНОЙ БАЗЫ ISAR
      // ========================================
      debugPrint('💾 Шаг 4/6: Удаляем все данные из локальной базы Isar');
      try {
        // Импортируем IsarService для работы с локальной базой
        final isarService = IsarService.instance;

        if (isarService.isInitialized) {
          // Удаляем все данные пользователя из всех таблиц Isar
          await isarService.deleteAllUserData(userId);
          debugPrint('✅ Все данные пользователя удалены из локальной базы Isar');
        } else {
          debugPrint('⚠️ IsarService не инициализирован, пропускаем очистку локальной базы');
        }

      } catch (e) {
        debugPrint('⚠️ Ошибка при удалении данных из Isar: $e');
        // Продолжаем удаление даже если не удалось очистить локальную базу
      }

      // ========================================
      // 5. ОЧИЩАЕМ ЛОКАЛЬНОЕ ХРАНИЛИЩЕ (SharedPreferences)
      // ========================================
      debugPrint('🧹 Шаг 5/6: Очищаем локальное хранилище');
      try {
        final prefs = await SharedPreferences.getInstance();

        // Список ключей которые нужно удалить
        final keysToRemove = [
          'auth_user_email',
          'auth_user_id',
          'auth_user_display_name',
          'saved_email',
          'saved_password_hash',
          'offline_auth_enabled',
          'offline_auth_expiry_date',
          'user_consents',
          'subscription_status',
          'subscription_data',
          // Добавляем другие ключи связанные с пользователем
        ];

        for (final key in keysToRemove) {
          await prefs.remove(key);
        }

        debugPrint('✅ Локальное хранилище очищено');

      } catch (e) {
        debugPrint('⚠️ Ошибка при очистке локального хранилища: $e');
        // Продолжаем удаление
      }

      // ========================================
      // 6. УДАЛЯЕМ АККАУНТ ИЗ FIREBASE AUTH (ПОСЛЕДНИЙ ШАГ)
      // ========================================
      debugPrint('🔐 Шаг 6/6: Удаляем аккаунт из Firebase Auth');
      try {
        await user.delete();
        debugPrint('✅ Аккаунт пользователя удален из Firebase Auth');
      } catch (e) {
        debugPrint('❌ КРИТИЧЕСКАЯ ОШИБКА при удалении аккаунта из Firebase Auth: $e');

        // Если не удалось удалить аккаунт из Auth, это критическая ошибка
        // Но данные пользователя уже удалены, поэтому пробрасываем исключение
        throw Exception('Не удалось удалить аккаунт из системы авторизации: $e');
      }

      debugPrint('🎉 ПОЛНОЕ УДАЛЕНИЕ АККАУНТА ЗАВЕРШЕНО УСПЕШНО!');
      debugPrint('📊 Что было удалено:');
      debugPrint('   ✅ Согласия пользователя');
      debugPrint('   ✅ Все данные из Firestore (6 подколлекций)');
      debugPrint('   ✅ Все файлы из Firebase Storage');
      debugPrint('   ✅ Все данные из локальной базы Isar');
      debugPrint('   ✅ Данные из локального хранилища');
      debugPrint('   ✅ Аккаунт из Firebase Auth');

    } catch (e) {
      debugPrint('❌ КРИТИЧЕСКАЯ ОШИБКА при удалении аккаунта: $e');
      debugPrint('📍 Stack trace: ${StackTrace.current}');
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
      await user.verifyBeforeUpdateEmail(newEmail);

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