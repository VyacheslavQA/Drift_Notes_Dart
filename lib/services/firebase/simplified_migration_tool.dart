// lib/services/firebase/simplified_migration_tool.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class SimplifiedMigrationTool {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  // Коллекции для миграции (без usage_limits)
  static const List<String> collectionsToMigrate = [
    'fishing_notes',
    'fishing_trips',
    'marker_maps',
    'user_consents'
  ];

  // === ПОЛНАЯ МИГРАЦИЯ В SUBCOLLECTIONS ===
  Future<Map<String, dynamic>> runCompleteMigration() async {
    try {
      if (kDebugMode) {
        debugPrint('🚀 === ЗАПУСК УПРОЩЕННОЙ МИГРАЦИИ ===');
      }

      final userId = currentUserId;
      if (userId == null) {
        throw Exception('Пользователь не авторизован');
      }

      // Создаем профиль пользователя, если его нет
      await _ensureUserProfile(userId);

      // Удаляем usage_limits сразу (не критично)
      await _deleteUsageLimits();

      // Мигрируем основные коллекции
      for (String collection in collectionsToMigrate) {
        await _migrateCollection(collection);
      }

      // Проверяем результат
      final verification = await verifyMigration();

      if (kDebugMode) {
        debugPrint('🎉 === УПРОЩЕННАЯ МИГРАЦИЯ ЗАВЕРШЕНА ===');
      }

      return verification;

    } catch (e) {
      if (kDebugMode) {
        debugPrint('💥 === ОШИБКА МИГРАЦИИ ===');
        debugPrint('❌ $e');
      }
      rethrow;
    }
  }

  // Обеспечиваем наличие профиля пользователя
  Future<void> _ensureUserProfile(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        if (kDebugMode) {
          debugPrint('👤 Создаем профиль пользователя: $userId');
        }
        await createTestProfile();
      } else {
        if (kDebugMode) {
          debugPrint('✅ Профиль пользователя уже существует: $userId');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Ошибка при проверке профиля: $e');
      }
      // Пытаемся создать профиль в любом случае
      await createTestProfile();
    }
  }

  // Удаление usage_limits (не критично)
  Future<void> _deleteUsageLimits() async {
    try {
      if (kDebugMode) {
        debugPrint('🗑️ Удаляем usage_limits (не критично)...');
      }

      await _deleteCollectionInBatches('usage_limits');

      if (kDebugMode) {
        debugPrint('✅ usage_limits удалены');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Ошибка удаления usage_limits (не критично): $e');
      }
      // Не останавливаем миграцию из-за этого
    }
  }

  // Миграция конкретной коллекции
  Future<void> _migrateCollection(String collectionName) async {
    try {
      if (kDebugMode) {
        debugPrint('  🔄 Мигрируем $collectionName...');
      }

      final snapshot = await _firestore.collection(collectionName).get();

      if (snapshot.docs.isEmpty) {
        if (kDebugMode) {
          debugPrint('  ⚪ $collectionName пуста');
        }
        return;
      }

      int migrated = 0;
      int errors = 0;
      int skipped = 0;

      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();
          final userId = data['userId'];

          if (userId == null) {
            skipped++;
            if (kDebugMode) {
              debugPrint('  ⚠️ Пропущен ${doc.id} - нет userId');
            }
            continue;
          }

          // Проверяем, не существует ли уже документ в новой структуре
          final existingDoc = await _firestore
              .collection('users')
              .doc(userId)
              .collection(collectionName)
              .doc(doc.id)
              .get();

          if (existingDoc.exists) {
            skipped++;
            if (kDebugMode) {
              debugPrint('  ⚠️ Пропущен ${doc.id} - уже существует в новой структуре');
            }
            continue;
          }

          // Убираем userId из данных (он теперь в пути)
          final cleanData = Map<String, dynamic>.from(data);
          cleanData.remove('userId');

          // Добавляем метки времени если их нет
          if (!cleanData.containsKey('createdAt')) {
            cleanData['createdAt'] = FieldValue.serverTimestamp();
          }
          if (!cleanData.containsKey('updatedAt')) {
            cleanData['updatedAt'] = FieldValue.serverTimestamp();
          }

          // Копируем в новую структуру
          await _firestore
              .collection('users')
              .doc(userId)
              .collection(collectionName)
              .doc(doc.id)
              .set(cleanData);

          migrated++;

        } catch (e) {
          errors++;
          if (kDebugMode) {
            debugPrint('  ❌ Ошибка миграции ${doc.id}: $e');
          }
        }
      }

      if (kDebugMode) {
        debugPrint('  ✅ $collectionName: $migrated мигрировано, $skipped пропущено, $errors ошибок');
      }

    } catch (e) {
      if (kDebugMode) {
        debugPrint('  ❌ Ошибка миграции $collectionName: $e');
      }
    }
  }

  // === ПРОВЕРКА РЕЗУЛЬТАТА ===
  Future<Map<String, dynamic>> verifyMigration() async {
    try {
      if (kDebugMode) {
        debugPrint('=== ПРОВЕРКА РЕЗУЛЬТАТА ===');
      }

      final result = <String, dynamic>{};

      // Получаем всех пользователей
      final usersSnapshot = await _firestore.collection('users').get();
      final users = usersSnapshot.docs;

      result['totalUsers'] = users.length;
      result['userDetails'] = <Map<String, dynamic>>[];

      int totalNewNotes = 0;
      int totalNewTrips = 0;
      int totalNewMaps = 0;
      int totalNewConsents = 0;

      for (var userDoc in users) {
        // Правильно получаем userId - это ID документа
        final userId = userDoc.id;
        final userData = userDoc.data();

        final notesCount = await _getSubcollectionCount(userId, 'fishing_notes');
        final tripsCount = await _getSubcollectionCount(userId, 'fishing_trips');
        final mapsCount = await _getSubcollectionCount(userId, 'marker_maps');
        final consentsCount = await _getSubcollectionCount(userId, 'user_consents');

        result['userDetails'].add({
          'userId': userId,
          'email': userData['email'] ?? 'Нет email',
          'displayName': userData['displayName'] ?? 'Нет имени',
          'notesCount': notesCount,
          'tripsCount': tripsCount,
          'mapsCount': mapsCount,
          'consentsCount': consentsCount,
        });

        totalNewNotes += notesCount;
        totalNewTrips += tripsCount;
        totalNewMaps += mapsCount;
        totalNewConsents += consentsCount;
      }

      result['newStructure'] = {
        'notes': totalNewNotes,
        'trips': totalNewTrips,
        'maps': totalNewMaps,
        'consents': totalNewConsents,
      };

      // Проверяем старые коллекции
      result['oldStructure'] = {
        'notes': await _getCollectionCount('fishing_notes'),
        'trips': await _getCollectionCount('fishing_trips'),
        'maps': await _getCollectionCount('marker_maps'),
        'consents': await _getCollectionCount('user_consents'),
      };

      if (kDebugMode) {
        debugPrint('✅ Проверка выполнена');
        debugPrint('Пользователей: ${result['totalUsers']}');
        debugPrint('Новая структура: ${result['newStructure']}');
        debugPrint('Старая структура: ${result['oldStructure']}');
      }

      return result;

    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка проверки: $e');
      }
      rethrow;
    }
  }

  // === УДАЛЕНИЕ СТАРЫХ ДАННЫХ ===
  Future<void> cleanupOldData() async {
    try {
      if (kDebugMode) {
        debugPrint('=== УДАЛЕНИЕ СТАРЫХ ДАННЫХ ===');
      }

      for (String collection in collectionsToMigrate) {
        await _deleteCollectionInBatches(collection);
      }

      if (kDebugMode) {
        debugPrint('✅ Старые данные удалены');
      }

    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка удаления: $e');
      }
      rethrow;
    }
  }

  // Вспомогательные методы
  Future<int> _getSubcollectionCount(String userId, String subcollection) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection(subcollection)
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      // Если count() не работает, делаем обычный запрос
      try {
        final snapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection(subcollection)
            .get();
        return snapshot.docs.length;
      } catch (e) {
        return 0;
      }
    }
  }

  Future<int> _getCollectionCount(String collection) async {
    try {
      final snapshot = await _firestore.collection(collection).count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      // Если count() не работает, делаем обычный запрос
      try {
        final snapshot = await _firestore.collection(collection).get();
        return snapshot.docs.length;
      } catch (e) {
        return 0;
      }
    }
  }

  Future<void> _deleteCollectionInBatches(String collectionName) async {
    const batchSize = 100;

    if (kDebugMode) {
      debugPrint('  🗑️ Удаляем $collectionName...');
    }

    int totalDeleted = 0;

    while (true) {
      final snapshot = await _firestore
          .collection(collectionName)
          .limit(batchSize)
          .get();

      if (snapshot.docs.isEmpty) {
        break;
      }

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      totalDeleted += snapshot.docs.length;

      if (kDebugMode) {
        debugPrint('  📊 Удалено $totalDeleted документов из $collectionName');
      }
    }

    if (kDebugMode) {
      debugPrint('  ✅ $collectionName: удалено $totalDeleted документов');
    }
  }

  // === СОЗДАНИЕ ТЕСТОВОГО ПРОФИЛЯ ===
  Future<void> createTestProfile() async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('Пользователь не авторизован');
    }

    try {
      final user = _auth.currentUser!;

      await _firestore.collection('users').doc(userId).set({
        'uid': userId,
        'email': user.email ?? '',
        'displayName': user.displayName ?? 'Пользователь',
        'city': 'Ваш город',
        'country': 'Ваша страна',
        'experience': 'beginner',
        'fishingTypes': ['Обычная рыбалка'],
        'photoUrl': user.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (kDebugMode) {
        debugPrint('✅ Профиль создан/обновлен для: $userId');
      }

    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка создания профиля: $e');
      }
      rethrow;
    }
  }

  // === БЫСТРАЯ ПРОВЕРКА СОСТОЯНИЯ ===
  Future<String> getQuickStatus() async {
    try {
      if (kDebugMode) {
        debugPrint('🔍 Начинаем проверку состояния...');
      }

      // Проверяем, авторизован ли пользователь
      final userId = currentUserId;
      if (userId == null) {
        return '❌ ОШИБКА: Пользователь не авторизован';
      }

      if (kDebugMode) {
        debugPrint('✅ Пользователь авторизован: $userId');
      }

      // Проверяем наличие профиля текущего пользователя
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        return '👤 НУЖЕН ПРОФИЛЬ: создайте профиль пользователя\n\nПользователь: $userId';
      }

      // Проверяем наличие данных в новой структуре для текущего пользователя
      final newNotesCount = await _getSubcollectionCount(userId, 'fishing_notes');
      final newTripsCount = await _getSubcollectionCount(userId, 'fishing_trips');
      final newMapsCount = await _getSubcollectionCount(userId, 'marker_maps');
      final newConsentsCount = await _getSubcollectionCount(userId, 'user_consents');

      if (kDebugMode) {
        debugPrint('📊 Данные в новой структуре - Записи: $newNotesCount, Поездки: $newTripsCount, Карты: $newMapsCount, Согласия: $newConsentsCount');
      }

      // Проверяем старые коллекции
      final oldNotesCount = await _getCollectionCount('fishing_notes');
      final oldTripsCount = await _getCollectionCount('fishing_trips');
      final oldMapsCount = await _getCollectionCount('marker_maps');
      final oldConsentsCount = await _getCollectionCount('user_consents');

      if (kDebugMode) {
        debugPrint('📊 Старые данные - Записи: $oldNotesCount, Поездки: $oldTripsCount, Карты: $oldMapsCount, Согласия: $oldConsentsCount');
      }

      final totalNewData = newNotesCount + newTripsCount + newMapsCount + newConsentsCount;
      final totalOldData = oldNotesCount + oldTripsCount + oldMapsCount + oldConsentsCount;

      if (totalNewData > 0) {
        if (totalOldData > 0) {
          return '⚠️ МИГРАЦИЯ ВЫПОЛНЕНА: можно удалить старые данные\n\nВаши данные в новой структуре:\n📝 $newNotesCount записей\n🎣 $newTripsCount поездок\n🗺️ $newMapsCount карт\n✅ $newConsentsCount согласий\n\nСтарые данные: $totalOldData документов';
        } else {
          return '✅ ВСЕ ГОТОВО: данные в новой структуре, старые данные удалены\n\nВаши данные:\n📝 $newNotesCount записей\n🎣 $newTripsCount поездок\n🗺️ $newMapsCount карт\n✅ $newConsentsCount согласий';
        }
      }

      if (totalOldData > 0) {
        return '🔄 ГОТОВО К МИГРАЦИИ: есть данные для переноса\n\nВ старой структуре найдено:\n📝 $oldNotesCount записей\n🎣 $oldTripsCount поездок\n🗺️ $oldMapsCount карт\n✅ $oldConsentsCount согласий';
      }

      return '📭 НЕТ ДАННЫХ: создайте записи или они уже мигрированы\n\nПользователь: ${userDoc.data()?['email'] ?? userId}';

    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Ошибка проверки состояния: $e');
      }
      return '❌ Ошибка проверки: $e\n\nПроверьте подключение к Firebase';
    }
  }
}