// Путь: lib/services/admin_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/subscription_constants.dart';
import 'firebase/firebase_service.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseService _firebaseService = FirebaseService();

  // Админские email адреса
  static const List<String> adminEmails = [
    'vyacheslav-kuzin@bk.ru',
    'world8770@gmail.com',
    'raider777@mail.ru',
  ];

  /// Проверка является ли пользователь админом
  bool isAdmin(String? email) {
    if (email == null) return false;
    return adminEmails.contains(email.toLowerCase());
  }

  /// Поиск пользователя по email или userId
  Future<Map<String, dynamic>?> findUserByEmailOrId(String input) async {
    try {
      // Если это userId (не содержит @)
      if (!input.contains('@')) {
        return await findUserById(input);
      }

      // Если это email - ищем через Firestore query
      return await findUserByEmail(input);
    } catch (e) {
      throw Exception('Ошибка поиска: $e');
    }
  }

  /// Поиск пользователя по email
  Future<Map<String, dynamic>?> findUserByEmail(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.toLowerCase().trim())
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        return {
          'userId': doc.id,
          'userData': doc.data(),
        };
      }

      return null;
    } catch (e) {
      throw Exception('Ошибка поиска пользователя по email: $e');
    }
  }

  /// Поиск пользователя по userId
  Future<Map<String, dynamic>?> findUserById(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();

      if (doc.exists) {
        return {
          'userId': doc.id,
          'userData': doc.data()!,
        };
      }

      return null;
    } catch (e) {
      throw Exception('Ошибка поиска пользователя по ID: $e');
    }
  }

  /// Создание подписки для пользователя (поддержка email и userId)
  Future<void> grantSubscription({
    required String userEmailOrId,
    required SubscriptionType subscriptionType,
    required Duration duration,
  }) async {
    try {
      // Ищем пользователя по email или userId
      final userInfo = await findUserByEmailOrId(userEmailOrId);
      if (userInfo == null) {
        throw Exception('Пользователь с $userEmailOrId не найден');
      }

      final userId = userInfo['userId'] as String;
      final now = DateTime.now();
      final expirationDate = now.add(duration);

      // Определяем productId
      final productId = subscriptionType == SubscriptionType.yearly
          ? SubscriptionConstants.yearlyPremiumId
          : SubscriptionConstants.monthlyPremiumId;

      // Создаем документ подписки
      final subscriptionData = {
        'createdAt': Timestamp.fromDate(now),
        'expirationDate': Timestamp.fromDate(expirationDate),
        'isActive': true,
        'originalTransactionId': 'ADMIN_GRANT_${DateTime.now().millisecondsSinceEpoch}',
        'platform': 'manual',
        'productId': productId,
        'purchaseToken': 'ADMIN_GRANT_${DateTime.now().millisecondsSinceEpoch}',
        'status': 'active',
        'type': subscriptionType == SubscriptionType.yearly ? 'yearly' : 'monthly',
        'updatedAt': Timestamp.fromDate(now),
        'userId': userId,
        'grantedBy': 'admin',
        'grantedAt': Timestamp.fromDate(now),
      };

      // Сохраняем подписку
      await _firestore
          .collection('users')
          .doc(userId)
          .collection(SubscriptionConstants.subscriptionSubcollection)
          .doc('current')
          .set(subscriptionData);

    } catch (e) {
      throw Exception('Ошибка выдачи подписки: $e');
    }
  }

  /// Отзыв подписки у пользователя (поддержка email и userId)
  Future<void> revokeSubscription(String userEmailOrId) async {
    try {
      // Ищем пользователя по email или userId
      final userInfo = await findUserByEmailOrId(userEmailOrId);
      if (userInfo == null) {
        throw Exception('Пользователь с $userEmailOrId не найден');
      }

      final userId = userInfo['userId'] as String;

      // Обновляем подписку
      await _firestore
          .collection('users')
          .doc(userId)
          .collection(SubscriptionConstants.subscriptionSubcollection)
          .doc('current')
          .update({
        'status': 'inactive',
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
        'revokedBy': 'admin',
        'revokedAt': FieldValue.serverTimestamp(),
      });

    } catch (e) {
      throw Exception('Ошибка отзыва подписки: $e');
    }
  }

  /// Получение информации о подписке пользователя (поддержка email и userId)
  Future<Map<String, dynamic>?> getUserSubscriptionInfo(String userEmailOrId) async {
    try {
      // Ищем пользователя по email или userId
      final userInfo = await findUserByEmailOrId(userEmailOrId);
      if (userInfo == null) {
        return null;
      }

      final userId = userInfo['userId'] as String;
      final userData = userInfo['userData'] as Map<String, dynamic>;
      final userEmail = userData['email'] as String? ?? 'Unknown';

      // Получаем подписку
      final subscriptionDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection(SubscriptionConstants.subscriptionSubcollection)
          .doc('current')
          .get();

      if (!subscriptionDoc.exists) {
        return {
          'hasSubscription': false,
          'userId': userId,
          'userEmail': userEmail,
        };
      }

      final subscriptionData = subscriptionDoc.data()!;
      final expirationDate = (subscriptionData['expirationDate'] as Timestamp?)?.toDate();
      final isActive = subscriptionData['isActive'] ?? false;
      final status = subscriptionData['status'] ?? 'none';

      return {
        'hasSubscription': true,
        'userId': userId,
        'userEmail': userEmail,
        'isActive': isActive,
        'status': status,
        'expirationDate': expirationDate,
        'productId': subscriptionData['productId'],
        'type': subscriptionData['type'],
        'platform': subscriptionData['platform'],
        'subscriptionData': subscriptionData,
      };

    } catch (e) {
      throw Exception('Ошибка получения информации о подписке: $e');
    }
  }

  /// Получение всех пользователей с подписками (для статистики)
  Future<List<Map<String, dynamic>>> getAllSubscribedUsers() async {
    try {
      final List<Map<String, dynamic>> result = [];

      // Получаем всех пользователей
      final usersSnapshot = await _firestore.collection('users').get();

      for (final userDoc in usersSnapshot.docs) {
        final userId = userDoc.id;
        final userData = userDoc.data();

        // Проверяем подписку
        final subscriptionDoc = await _firestore
            .collection('users')
            .doc(userId)
            .collection(SubscriptionConstants.subscriptionSubcollection)
            .doc('current')
            .get();

        if (subscriptionDoc.exists) {
          final subscriptionData = subscriptionDoc.data()!;
          result.add({
            'userId': userId,
            'userEmail': userData['email'] ?? 'Unknown',
            'subscriptionData': subscriptionData,
          });
        }
      }

      return result;
    } catch (e) {
      throw Exception('Ошибка получения списка подписчиков: $e');
    }
  }

  /// Быстрые методы для стандартных сроков
  Future<void> grantYearlySubscription(String userEmailOrId) async {
    await grantSubscription(
      userEmailOrId: userEmailOrId,
      subscriptionType: SubscriptionType.yearly,
      duration: const Duration(days: 365),
    );
  }

  Future<void> grantMonthlySubscription(String userEmailOrId) async {
    await grantSubscription(
      userEmailOrId: userEmailOrId,
      subscriptionType: SubscriptionType.monthly,
      duration: const Duration(days: 30),
    );
  }

  /// Предустановленные периоды для удобства
  static const Map<String, Duration> predefinedDurations = {
    '1 неделя': Duration(days: 7),
    '1 месяц': Duration(days: 30),
    '3 месяца': Duration(days: 90),
    '6 месяцев': Duration(days: 180),
    '1 год': Duration(days: 365),
  };

  /// Получение периода по названию
  static Duration? getDurationByName(String durationName) {
    return predefinedDurations[durationName];
  }
}