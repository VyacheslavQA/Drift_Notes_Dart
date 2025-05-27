// Путь: lib/services/tournament_service.dart

import '../models/tournament_model.dart';

class TournamentService {
  static final TournamentService _instance = TournamentService._internal();
  factory TournamentService() => _instance;
  TournamentService._internal();

  // Все турниры на 2025 год
  List<TournamentModel> getAllTournaments() {
    return [
      // АПРЕЛЬ
      TournamentModel(
        id: 'apr_1',
        name: 'Кастинг, Область Абай',
        startDate: DateTime(2025, 4, 1), // Примерная дата
        duration: 10,
        sector: '100 м',
        location: 'г.Семей',
        organizer: 'Карповый клуб Семей',
        month: 'АПРЕЛЬ',
        type: TournamentType.casting,
      ),
      TournamentModel(
        id: 'apr_2',
        name: 'Кастинг, г.Алматы',
        startDate: DateTime(2025, 4, 9),
        duration: 10,
        sector: '100 м',
        location: 'г.Алматы',
        organizer: 'FDLr.Алматы',
        month: 'АПРЕЛЬ',
        type: TournamentType.casting,
      ),
      TournamentModel(
        id: 'apr_3',
        name: 'Кастинг, Туркестанская область',
        startDate: DateTime(2025, 4, 26),
        duration: 10,
        sector: '200 м',
        location: 'вдх.Бадам, г.Шымкент',
        organizer: 'ФСР Туркестанской области',
        month: 'АПРЕЛЬ',
        type: TournamentType.casting,
      ),

      // МАЙ
      TournamentModel(
        id: 'may_1',
        name: 'Турнир в честь открытия озера "KazFish"',
        startDate: DateTime(2025, 5, 8),
        endDate: DateTime(2025, 5, 11),
        duration: 72,
        sector: '15',
        location: 'вдх.KazFish, г.Алматы',
        organizer: 'Jetysu Carp Club',
        month: 'МАЙ',
        type: TournamentType.tournament,
      ),
      TournamentModel(
        id: 'may_2',
        name: 'Открытый кубок "Jetysu Carp Club"',
        startDate: DateTime(2025, 5, 29),
        endDate: DateTime(2025, 6, 1),
        duration: 72,
        sector: '15',
        location: 'вдх.KazFish, г.Алматы',
        organizer: 'Jetysu Carp Club',
        month: 'МАЙ',
        type: TournamentType.cup,
      ),

      // ИЮНЬ
      TournamentModel(
        id: 'jun_1',
        name: 'Чемпионат Области Абай',
        startDate: DateTime(2025, 6, 5),
        endDate: DateTime(2025, 6, 8),
        duration: 72,
        sector: '15',
        location: 'оз.Тополек, Область Абай (г.Семей)',
        organizer: 'ФСР области Абай/Карповый клуб Семей',
        month: 'ИЮНЬ',
        type: TournamentType.championship,
      ),
      TournamentModel(
        id: 'jun_2',
        name: 'Кубок "Архи"',
        startDate: DateTime(2025, 6, 6), // Примерная дата
        duration: 100,
        sector: '15',
        location: 'вдх.KazFish, г.Алматы',
        organizer: 'Мечта Рыбака',
        month: 'ИЮНЬ',
        type: TournamentType.cup,
      ),
      TournamentModel(
        id: 'jun_3',
        name: 'Кубок Касына',
        startDate: DateTime(2025, 6, 5),
        endDate: DateTime(2025, 6, 8),
        duration: 72,
        sector: '20',
        location: 'оз.К-28, г.Алматы',
        organizer: 'FDLr.Алматы',
        month: 'ИЮНЬ',
        type: TournamentType.cup,
      ),
      TournamentModel(
        id: 'jun_4',
        name: 'KUKA PARTY',
        startDate: DateTime(2025, 6, 12),
        endDate: DateTime(2025, 6, 15),
        duration: 72,
        sector: '30',
        location: 'вдх.Шардара, Туркестанская область (г.Шардара)',
        organizer: 'CKK/Мечта Рыбака',
        month: 'ИЮНЬ',
        type: TournamentType.tournament,
      ),
      TournamentModel(
        id: 'jun_5',
        name: 'Турнир "Family"',
        startDate: DateTime(2025, 6, 12),
        endDate: DateTime(2025, 6, 15),
        duration: 72,
        sector: '15',
        location: 'вдх.KazFish, г.Алматы',
        organizer: 'Jetysu Carp Club',
        month: 'ИЮНЬ',
        type: TournamentType.tournament,
      ),
      TournamentModel(
        id: 'jun_6',
        name: 'Кубок "Профи"',
        startDate: DateTime(2025, 6, 12),
        endDate: DateTime(2025, 6, 16),
        duration: 100,
        sector: '15',
        location: 'вдх.KazFish, г.Алматы',
        organizer: 'Jetysu Carp Club',
        month: 'ИЮНЬ',
        type: TournamentType.cup,
      ),
      TournamentModel(
        id: 'jun_7',
        name: 'Кубок "Мечта рыбака"',
        startDate: DateTime(2025, 6, 25),
        endDate: DateTime(2025, 6, 29),
        duration: 72,
        sector: '30',
        location: 'вдх.Шардара, Туркестанская область (г.Шардара)',
        organizer: 'Мечта Рыбака',
        month: 'ИЮНЬ',
        type: TournamentType.cup,
      ),
      TournamentModel(
        id: 'jun_8',
        name: 'Чемпионат СКО, 1 этап',
        startDate: DateTime(2025, 6, 26),
        endDate: DateTime(2025, 6, 29),
        duration: 72,
        sector: '20',
        location: 'СКО, Джамбульский район, оз.Сичакм',
        organizer: 'Петропавловский карповый клуб',
        month: 'ИЮНЬ',
        type: TournamentType.championship,
      ),

      // ИЮЛЬ
      TournamentModel(
        id: 'jul_1',
        name: 'Лига Чемпионов 1 этап',
        startDate: DateTime(2025, 7, 3),
        endDate: DateTime(2025, 7, 6),
        duration: 72,
        sector: '15',
        location: 'вдх.KazFish, г.Алматы',
        organizer: 'Jetysu Carp Club',
        month: 'ИЮЛЬ',
        type: TournamentType.league,
      ),
      TournamentModel(
        id: 'jul_2',
        name: 'Чемпионат СКО, 2 этап',
        startDate: DateTime(2025, 7, 10),
        endDate: DateTime(2025, 7, 13),
        duration: 72,
        sector: '20',
        location: 'СКО, Джамбульский район, оз.Сичакм',
        organizer: 'Петропавловский карповый клуб',
        month: 'ИЮЛЬ',
        type: TournamentType.championship,
      ),
      TournamentModel(
        id: 'jul_3',
        name: 'Лига Чемпионов 2 этап',
        startDate: DateTime(2025, 7, 17),
        endDate: DateTime(2025, 7, 20),
        duration: 72,
        sector: '15',
        location: 'вдх.KazFish, г.Алматы',
        organizer: 'Jetysu Carp Club',
        month: 'ИЮЛЬ',
        type: TournamentType.league,
      ),
      TournamentModel(
        id: 'jul_4',
        name: 'Чемпионат Республики Казахстан 1 тур',
        startDate: DateTime(2025, 7, 19),
        endDate: DateTime(2025, 7, 22),
        duration: 72,
        sector: '30',
        location: 'вдх.Шардара, Туркестанская область (г.Шардара)',
        organizer: 'ФСР РК, ФСР Туркестанской области',
        month: 'ИЮЛЬ',
        type: TournamentType.championship,
      ),
      TournamentModel(
        id: 'jul_5',
        name: 'Чемпионат Республики Казахстан 2 тур',
        startDate: DateTime(2025, 7, 24),
        endDate: DateTime(2025, 7, 27),
        duration: 72,
        sector: '30',
        location: 'вдх.Шардара, Туркестанская область (г.Шардара)',
        organizer: 'ФСР РК, ФСР Туркестанской области',
        month: 'ИЮЛЬ',
        type: TournamentType.championship,
      ),
      TournamentModel(
        id: 'jul_6',
        name: 'Лига Чемпионов Финал',
        startDate: DateTime(2025, 7, 31),
        endDate: DateTime(2025, 8, 3),
        duration: 72,
        sector: '15',
        location: 'вдх.KazFish, г.Алматы',
        organizer: 'Jetysu Carp Club',
        month: 'ИЮЛЬ',
        type: TournamentType.league,
      ),

      // АВГУСТ
      TournamentModel(
        id: 'aug_1',
        name: 'Кубок ФСР Туркестанской области',
        startDate: DateTime(2025, 8, 7),
        endDate: DateTime(2025, 8, 10),
        duration: 72,
        sector: '30',
        location: 'вдх.Шардара, Туркестанская область (г.Шардара)',
        organizer: 'ФСР Туркестанской области',
        month: 'АВГУСТ',
        type: TournamentType.cup,
      ),
      TournamentModel(
        id: 'aug_2',
        name: 'Чемпионат Актюбинской области',
        startDate: DateTime(2025, 8, 7),
        endDate: DateTime(2025, 8, 10),
        duration: 72,
        sector: '15',
        location: 'вдх.KazFish, г.Алматы',
        organizer: 'ФСР Актюбинской области',
        month: 'АВГУСТ',
        type: TournamentType.championship,
      ),
      TournamentModel(
        id: 'aug_3',
        name: 'Чемпионат г.Алматы',
        startDate: DateTime(2025, 8, 12),
        endDate: DateTime(2025, 8, 15),
        duration: 72,
        sector: '20',
        location: 'вдх.KazFish, г.Алматы',
        organizer: 'ФСР г.Алматы',
        month: 'АВГУСТ',
        type: TournamentType.championship,
      ),
      TournamentModel(
        id: 'aug_4',
        name: 'Чемпионат г.Астана',
        startDate: DateTime(2025, 8, 21),
        endDate: DateTime(2025, 8, 24),
        duration: 72,
        sector: '20+',
        location: 'оз.Тойганколь, Акмолинская область, Ерейментауский район',
        organizer: 'ФСР г.Астана/Карповый клуб Астана',
        month: 'АВГУСТ',
        type: TournamentType.championship,
      ),
      TournamentModel(
        id: 'aug_5',
        name: '"Gold Carp" большая коммерция',
        startDate: DateTime(2025, 8, 21),
        endDate: DateTime(2025, 8, 24),
        duration: 72,
        sector: '15',
        location: 'вдх.KazFish, г.Алматы',
        organizer: 'Jetysu Carp Club',
        month: 'АВГУСТ',
        type: TournamentType.commercial,
      ),

      // СЕНТЯБРЬ
      TournamentModel(
        id: 'sep_1',
        name: 'Чемпионат КККК',
        startDate: DateTime(2025, 9, 3),
        endDate: DateTime(2025, 9, 7),
        duration: 100,
        sector: '30',
        location: 'вдх.Шардара, Туркестанская область',
        organizer: 'Клуб КККК',
        month: 'СЕНТЯБРЬ',
        type: TournamentType.championship,
      ),
      TournamentModel(
        id: 'sep_2',
        name: 'Коммерческий турнир "Осенний Карп"',
        startDate: DateTime(2025, 9, 4),
        endDate: DateTime(2025, 9, 7),
        duration: 72,
        sector: '15',
        location: 'оз.Тополек, Область Абай (г.Семей)',
        organizer: 'ФСР области Абай/Карповый клуб Семей',
        month: 'СЕНТЯБРЬ',
        type: TournamentType.commercial,
      ),
      TournamentModel(
        id: 'sep_3',
        name: 'Кубок Капитанов',
        startDate: DateTime(2025, 9, 11),
        endDate: DateTime(2025, 9, 14),
        duration: 72,
        sector: '15',
        location: 'вдх.KazFish, г.Алматы',
        organizer: 'Jetysu Carp Club',
        month: 'СЕНТЯБРЬ',
        type: TournamentType.cup,
      ),
      TournamentModel(
        id: 'sep_4',
        name: 'Чемпионат Мира',
        startDate: DateTime(2025, 9, 15),
        endDate: DateTime(2025, 9, 21),
        duration: 72,
        sector: '40+',
        location: 'Хорватия, оз.Коритник (с.Бучеторынско), оз.Яошана (г.Джакого)',
        organizer: 'FIPSED',
        month: 'СЕНТЯБРЬ',
        type: TournamentType.championship,
      ),
      TournamentModel(
        id: 'sep_5',
        name: 'Чемпионат Алаш-SKK',
        startDate: DateTime(2025, 9, 19),
        endDate: DateTime(2025, 9, 21),
        duration: 72,
        sector: '30',
        location: 'вдх.Шардара, Туркестанская область',
        organizer: 'Алаш-SKK',
        month: 'СЕНТЯБРЬ',
        type: TournamentType.championship,
      ),
      TournamentModel(
        id: 'sep_6',
        name: 'Чемпионат Туркестанской области',
        startDate: DateTime(2025, 9, 25),
        endDate: DateTime(2025, 9, 28),
        duration: 72,
        sector: '30',
        location: 'вдх.Шардара, Туркестанская область',
        organizer: 'ФСР Туркестанской области',
        month: 'СЕНТЯБРЬ',
        type: TournamentType.championship,
      ),

      // ОКТЯБРЬ
      TournamentModel(
        id: 'oct_1',
        name: 'Чемпионат "Жылы багыр"',
        startDate: DateTime(2025, 10, 9),
        endDate: DateTime(2025, 10, 12),
        duration: 72,
        sector: '30',
        location: 'вдх.Шардара, Туркестанская область',
        organizer: 'СКК',
        month: 'ОКТЯБРЬ',
        type: TournamentType.championship,
      ),
      TournamentModel(
        id: 'oct_2',
        name: 'Закрытие сезона',
        startDate: DateTime(2025, 10, 9),
        endDate: DateTime(2025, 10, 12),
        duration: 72,
        sector: '15',
        location: 'вдх.KazFish, г.Алматы',
        organizer: 'Jetysu Carp Club',
        month: 'ОКТЯБРЬ',
        type: TournamentType.tournament,
      ),
    ];
  }

  // Фильтры
  List<TournamentModel> getTournamentsByMonth(String month) {
    return getAllTournaments().where((t) => t.month == month).toList();
  }

  List<TournamentModel> getTournamentsByType(TournamentType type) {
    return getAllTournaments().where((t) => t.type == type).toList();
  }

  List<TournamentModel> getUpcomingTournaments() {
    return getAllTournaments().where((t) => t.isFuture).toList();
  }

  List<TournamentModel> getActiveTournaments() {
    return getAllTournaments().where((t) => t.isActive).toList();
  }

  List<TournamentModel> getPastTournaments() {
    return getAllTournaments().where((t) => t.isPast).toList();
  }

  // Поиск
  List<TournamentModel> searchTournaments(String query) {
    final lowercaseQuery = query.toLowerCase();
    return getAllTournaments().where((t) =>
    t.name.toLowerCase().contains(lowercaseQuery) ||
        t.location.toLowerCase().contains(lowercaseQuery) ||
        t.organizer.toLowerCase().contains(lowercaseQuery)
    ).toList();
  }
}