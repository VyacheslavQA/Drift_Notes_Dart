// Путь: lib/repositories/user_repository.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/user_consent_service.dart'; // НОВЫЙ ИМПОРТ!

class UserRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserConsentService _consentService = UserConsentService(); // НОВОЕ!

  // Получение текущего пользователя
  User? get currentUser => _auth.currentUser;

  // Получение ID текущего пользователя
  String? get currentUserId => _auth.currentUser?.uid;

  // Проверка авторизации пользователя
  bool get isUserLoggedIn => _auth.currentUser != null;

  // Получение данных пользователя по ID
  Future<UserModel?> getUserData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();

      if (!doc.exists) {
        return null;
      }

      return UserModel.fromJson(doc.data() as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Ошибка при получении данных пользователя: $e');
      return null;
    }
  }

  // Получение данных текущего пользователя
  Future<UserModel?> getCurrentUserData() async {
    final userId = currentUserId;
    if (userId == null) return null;

    return getUserData(userId);
  }

  // Стрим для получения данных пользователя в реальном времени
  Stream<UserModel?> getUserStream() {
    final userId = currentUserId;
    if (userId == null) {
      return Stream.value(null);
    }

    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) {
        return null;
      }

      return UserModel.fromJson(snapshot.data() as Map<String, dynamic>);
    });
  }

  // Обновление данных пользователя
  Future<void> updateUserData(Map<String, dynamic> userData) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('Пользователь не авторизован');
    }

    await _firestore.collection('users').doc(userId).set(
      userData,
      SetOptions(merge: true),
    );
  }

  // Обновление аватара пользователя
  Future<void> updateUserAvatar(String avatarUrl) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('Пользователь не авторизован');
    }

    await _firestore.collection('users').doc(userId).update({
      'avatarUrl': avatarUrl,
    });
  }

  // Выход из аккаунта (ИСПРАВЛЕНО!)
  Future<void> signOut() async {
    try {
      // ВАЖНО: Очищаем согласия ПЕРЕД выходом
      debugPrint('🧹 Очищаем согласия пользователя перед выходом');
      await _consentService.clearAllConsents();

      // Выходим из Firebase Auth
      await _auth.signOut();

      debugPrint('✅ Успешный выход из аккаунта (с очисткой согласий)');
    } catch (e) {
      debugPrint('❌ Ошибка при выходе из аккаунта: $e');

      // В случае ошибки все равно пытаемся выйти из Firebase
      try {
        await _auth.signOut();
      } catch (signOutError) {
        debugPrint('❌ Критическая ошибка при выходе из Firebase: $signOutError');
      }
    }
  }
}