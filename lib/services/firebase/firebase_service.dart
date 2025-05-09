// Путь: lib/services/firebase/firebase_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Получение текущего пользователя
  User? get currentUser => _auth.currentUser;

  // Проверка авторизации пользователя
  bool get isUserLoggedIn => _auth.currentUser != null;

  // Получение ID текущего пользователя
  String? get currentUserId => _auth.currentUser?.uid;

  // Регистрация нового пользователя с email и паролем
  Future<UserCredential> registerWithEmailAndPassword(
      String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      // Обработка ошибок Firebase и преобразование их в понятные пользователю сообщения
      throw _handleAuthException(e);
    }
  }

  Future<SharedPreferences> getSharedPreferences() async {
    return await SharedPreferences.getInstance();
  }

  // Вход пользователя с email и паролем
  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      // Обработка ошибок Firebase и преобразование их в понятные пользователю сообщения
      throw _handleAuthException(e);
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
    await _firestore.collection('users').doc(userId).set(data, SetOptions(merge: true));
  }

  // Получение данных пользователя из Firestore
  Future<DocumentSnapshot> getUserData(String userId) async {
    return await _firestore.collection('users').doc(userId).get();
  }

  // Добавление заметки о рыбалке
  Future<DocumentReference> addFishingNote(Map<String, dynamic> noteData) async {
    return await _firestore.collection('fishing_notes').add(noteData);
  }

  // Обновление заметки о рыбалке
  Future<void> updateFishingNote(String noteId, Map<String, dynamic> noteData) async {
    await _firestore.collection('fishing_notes').doc(noteId).update(noteData);
  }

  // Получение заметок пользователя
  Future<QuerySnapshot> getUserFishingNotes(String userId) async {
    return await _firestore
        .collection('fishing_notes')
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .get();
  }

  // Загрузка изображения в Firebase Storage
  Future<String> uploadImage(String path, List<int> imageBytes) async {
    final ref = _storage.ref().child(path);
    // Преобразуем List<int> в Uint8List
    final Uint8List uint8List = Uint8List.fromList(imageBytes);
    final uploadTask = ref.putData(uint8List);
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }
}