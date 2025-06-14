// Путь: lib/services/tournament_service.dart

import 'package:flutter/foundation.dart';
import '../models/tournament_model.dart';

class TournamentService {
  static final TournamentService _instance = TournamentService._internal();
  factory TournamentService() => _instance;
  TournamentService._internal();

  // НОВЫЙ МЕТОД: Получить турнир по ID
  TournamentModel? getTournamentById(String id) {
    try {
      return getAllTournaments().firstWhere((tournament) => tournament.id == id);
    } catch (e) {
      debugPrint('❌ Турнир с ID $id не найден');
      return null;
    }
  }

  // Все турниры на 2025 год (данные из Excel файла)
  List<TournamentModel> getAllTournaments() {
    return [
      // ЯНВАРЬ
      TournamentModel(
        id: 'jan_1',
        name: 'Чемпионат г. Алматы по спортивному подледному лову рыбы на мормышку',
        startDate: DateTime(2025, 1, 17),
        endDate: DateTime(2025, 1, 19),
        duration: 48,
        location: 'озеро «Кульсай»',
        organizer: 'ФСРА УС г. Алматы',
        month: 'ЯНВАРЬ',
        fishingType: FishingType.iceFishing,
      ),

      // ФЕВРАЛЬ
      TournamentModel(
        id: 'feb_1',
        name: 'Чемпионат мира по спортивному лову рыбы со льда на мормышку',
        startDate: DateTime(2025, 2, 10),
        endDate: DateTime(2025, 2, 17),
        duration: 168,
        location: 'США, штат Мичиган, озеро Тамарак',
        organizer: 'FIPSed, ФСРРК',
        month: 'ФЕВРАЛЬ',
        fishingType: FishingType.iceFishing,
      ),

      // МАРТ
      TournamentModel(
        id: 'mar_1',
        name: 'Чемпионат РК по спортивному лову рыбы на мормышку',
        startDate: DateTime(2025, 3, 13),
        endDate: DateTime(2025, 3, 16),
        duration: 72,
        location: 'Карагандинская обл. Самаркандское вдхр.',
        organizer: 'РГКП ДРС УСФК',
        month: 'МАРТ',
        fishingType: FishingType.iceFishing,
      ),
      TournamentModel(
        id: 'mar_2',
        name: 'Чемпионат г. Алматы по спортивному лову форели на спиннинг',
        startDate: DateTime(2025, 3, 30),
        duration: 8,
        location: 'водохранилище "Fish-ка"',
        organizer: 'ФСРА УС г. Алматы',
        month: 'МАРТ',
        fishingType: FishingType.spinning,
      ),

      // АПРЕЛЬ
      TournamentModel(
        id: 'apr_1',
        name: 'Кастинг область Абай',
        startDate: DateTime(2025, 4, 24),
        duration: 8,
        location: 'г. Семей',
        organizer: 'Карповый клуб Семей',
        month: 'АПРЕЛЬ',
        fishingType: FishingType.casting,
      ),
      TournamentModel(
        id: 'apr_2',
        name: 'Кастинг г. Алматы',
        startDate: DateTime(2025, 4, 25),
        duration: 8,
        location: 'г. Алматы',
        organizer: 'FDL г. Алматы',
        month: 'АПРЕЛЬ',
        fishingType: FishingType.casting,
      ),
      TournamentModel(
        id: 'apr_3',
        name: 'Кастинг Туркестанская область',
        startDate: DateTime(2025, 4, 26),
        duration: 8,
        location: 'вдх. Бадам г. Шымкент',
        organizer: 'ФСР Туркестанской области',
        month: 'АПРЕЛЬ',
        fishingType: FishingType.casting,
      ),
      TournamentModel(
        id: 'apr_4',
        name: 'Кубок РК по спортивному лову форели на спиннинг',
        startDate: DateTime(2025, 4, 11),
        endDate: DateTime(2025, 4, 13),
        duration: 48,
        location: 'г. Алматы водохранилище "Fish-ка"',
        organizer: 'РГКП ДРС УСФК',
        month: 'АПРЕЛЬ',
        fishingType: FishingType.spinning,
      ),

      // МАЙ
      TournamentModel(
        id: 'may_1',
        name: 'Турнир в честь открытия озера "KazFish"',
        startDate: DateTime(2025, 5, 8),
        endDate: DateTime(2025, 5, 11),
        duration: 72,
        location: 'вдх. KazFish г. Алматы',
        organizer: 'Jetysu Carp Club',
        month: 'МАЙ',
        fishingType: FishingType.carpFishing,
      ),
      TournamentModel(
        id: 'may_2',
        name: 'Чемпионат РК по спортивному лову форели на спиннинг',
        startDate: DateTime(2025, 5, 16),
        endDate: DateTime(2025, 5, 18),
        duration: 48,
        location: 'г. Алматы водохранилище "Fish-ка"',
        organizer: 'РГКП ДРС УС г. Алматы ФСРРК',
        month: 'МАЙ',
        fishingType: FishingType.spinning,
      ),
      TournamentModel(
        id: 'may_3',
        name: 'Открытый кубок "Jetysu Carp Club"',
        startDate: DateTime(2025, 5, 29),
        endDate: DateTime(2025, 6, 1),
        duration: 72,
        location: 'вдх. KazFish г. Алматы',
        organizer: 'Jetysu Carp Club',
        month: 'МАЙ',
        fishingType: FishingType.carpFishing,
      ),

      // ИЮНЬ
      TournamentModel(
        id: 'jun_1',
        name: 'Чемпионат Области Абай',
        startDate: DateTime(2025, 6, 19),
        endDate: DateTime(2025, 6, 22),
        duration: 72,
        location: 'оз. Тополек Область Абай (г. Семей)',
        organizer: 'ФСР области Абай/Карповый клуб Семей',
        month: 'ИЮНЬ',
        fishingType: FishingType.carpFishing,
      ),
      TournamentModel(
        id: 'jun_2',
        name: 'Кубок г. Актобе',
        startDate: DateTime(2025, 6, 5),
        endDate: DateTime(2025, 6, 8),
        duration: 72,
        location: 'вдх. г. Актобе',
        organizer: 'ФСР Актюбинской области',
        month: 'ИЮНЬ',
        fishingType: FishingType.carpFishing,
      ),
      TournamentModel(
        id: 'jun_3',
        name: 'Кубок Касыма',
        startDate: DateTime(2025, 6, 5),
        endDate: DateTime(2025, 6, 8),
        duration: 72,
        location: 'оз. К-28 г. Алматы',
        organizer: 'FDL г. Алматы',
        month: 'ИЮНЬ',
        fishingType: FishingType.carpFishing,
      ),
      TournamentModel(
        id: 'jun_4',
        name: 'Чемпионат Мира по спортивному лову рыбы на фидер',
        startDate: DateTime(2025, 6, 9),
        endDate: DateTime(2025, 6, 16),
        duration: 168,
        location: 'Литва, Русне, река Скирвит',
        organizer: 'FIPSed, ФСРРК',
        month: 'ИЮНЬ',
        fishingType: FishingType.feeder,
      ),
      TournamentModel(
        id: 'jun_5',
        name: 'KUKA PARTY',
        startDate: DateTime(2025, 6, 12),
        endDate: DateTime(2025, 6, 15),
        duration: 72,
        location: 'вдх. Шардара Туркестанская область (г. Шардара)',
        organizer: 'СКК/Алтын балык',
        month: 'ИЮНЬ',
        fishingType: FishingType.carpFishing,
      ),
      TournamentModel(
        id: 'jun_6',
        name: 'Турнир "Family"',
        startDate: DateTime(2025, 6, 12),
        endDate: DateTime(2025, 6, 15),
        duration: 72,
        location: 'вдх. KazFish г. Алматы',
        organizer: 'Jetysu Carp Club',
        month: 'ИЮНЬ',
        fishingType: FishingType.carpFishing,
      ),
      TournamentModel(
        id: 'jun_7',
        name: 'Кубок Профи',
        startDate: DateTime(2025, 6, 12),
        endDate: DateTime(2025, 6, 16),
        duration: 96,
        location: 'вдх. KazFish г. Алматы',
        organizer: 'Jetysu Carp Club',
        month: 'ИЮНЬ',
        fishingType: FishingType.carpFishing,
      ),
      TournamentModel(
        id: 'jun_8',
        name: 'Кубок "Мечтарыбака"',
        startDate: DateTime(2025, 6, 25),
        endDate: DateTime(2025, 6, 29),
        duration: 96,
        location: 'вдх. Шардара Туркестанская область (г. Шардара)',
        organizer: 'Мечта Рыбака',
        month: 'ИЮНЬ',
        fishingType: FishingType.carpFishing,
      ),
      TournamentModel(
        id: 'jun_9',
        name: 'Чемпионат СКО 1 этап',
        startDate: DateTime(2025, 6, 26),
        endDate: DateTime(2025, 6, 29),
        duration: 72,
        location: 'СКО Джамбульский район оз. Симаки',
        organizer: 'Петропавловский карповый клуб',
        month: 'ИЮНЬ',
        fishingType: FishingType.carpFishing,
      ),

      // ИЮЛЬ
      TournamentModel(
        id: 'jul_1',
        name: 'Лига Чемпионов 1 этап',
        startDate: DateTime(2025, 7, 3),
        endDate: DateTime(2025, 7, 6),
        duration: 72,
        location: 'вдх. KazFish г. Алматы',
        organizer: 'Jetysu Carp Club',
        month: 'ИЮЛЬ',
        fishingType: FishingType.carpFishing,
      ),
      TournamentModel(
        id: 'jul_2',
        name: 'Чемпионат г. Алматы по спортивному лову рыбы на фидер',
        startDate: DateTime(2025, 7, 4),
        endDate: DateTime(2025, 7, 6),
        duration: 48,
        location: 'Водохранилище «Октябрьское-3»',
        organizer: 'ФСРА УС г. Алматы',
        month: 'ИЮЛЬ',
        fishingType: FishingType.feeder,
      ),
      TournamentModel(
        id: 'jul_3',
        name: 'Чемпионат СКО 2 этап',
        startDate: DateTime(2025, 7, 10),
        endDate: DateTime(2025, 7, 13),
        duration: 72,
        location: 'СКО Джамбульский район оз. Симаки',
        organizer: 'Петропавловский карповый клуб',
        month: 'ИЮЛЬ',
        fishingType: FishingType.carpFishing,
      ),
      TournamentModel(
        id: 'jul_4',
        name: 'Лига Чемпионов 2 этап',
        startDate: DateTime(2025, 7, 17),
        endDate: DateTime(2025, 7, 20),
        duration: 72,
        location: 'вдх. KazFish г. Алматы',
        organizer: 'Jetysu Carp Club',
        month: 'ИЮЛЬ',
        fishingType: FishingType.carpFishing,
      ),
      TournamentModel(
        id: 'jul_5',
        name: 'Чемпионат Республики Казахстан 1 тур',
        startDate: DateTime(2025, 7, 19),
        endDate: DateTime(2025, 7, 22),
        duration: 72,
        location: 'вдх. Шардара Туркестанская область (г. Шардара)',
        organizer: 'ФСР РК ФСР Туркестанской области',
        month: 'ИЮЛЬ',
        fishingType: FishingType.carpFishing,
      ),
      TournamentModel(
        id: 'jul_6',
        name: 'Чемпионат Республики Казахстан 2 тур',
        startDate: DateTime(2025, 7, 24),
        endDate: DateTime(2025, 7, 27),
        duration: 72,
        location: 'вдх. Шардара Туркестанская область (г. Шардара)',
        organizer: 'ФСР РК ФСР Туркестанской области',
        month: 'ИЮЛЬ',
        fishingType: FishingType.carpFishing,
      ),
      TournamentModel(
        id: 'jul_7',
        name: 'Лига Чемпионов Финал',
        startDate: DateTime(2025, 7, 31),
        endDate: DateTime(2025, 8, 3),
        duration: 72,
        location: 'вдх. KazFish г. Алматы',
        organizer: 'Jetysu Carp Club',
        month: 'ИЮЛЬ',
        fishingType: FishingType.carpFishing,
      ),

      // АВГУСТ
      TournamentModel(
        id: 'aug_1',
        name: 'Кубок ФСР Туркестанской области',
        startDate: DateTime(2025, 8, 7),
        endDate: DateTime(2025, 8, 10),
        duration: 72,
        location: 'вдх. Шардара Туркестанская область (г. Шардара)',
        organizer: 'ФСР Туркестанской области',
        month: 'АВГУСТ',
        fishingType: FishingType.carpFishing,
      ),
      TournamentModel(
        id: 'aug_2',
        name: 'Чемпионат Актюбинской области',
        startDate: DateTime(2025, 8, 7),
        endDate: DateTime(2025, 8, 10),
        duration: 72,
        location: 'вдх. г. Актобе',
        organizer: 'ФСР Актюбинской области',
        month: 'АВГУСТ',
        fishingType: FishingType.carpFishing,
      ),
      TournamentModel(
        id: 'aug_3',
        name: 'Чемпионат РК по спортивному лову рыбы на фидер',
        startDate: DateTime(2025, 8, 7),
        endDate: DateTime(2025, 8, 10),
        duration: 72,
        location: 'г. Алматы, Водохранилище «Октябрьское-3»',
        organizer: 'РГКП ДРС УС г. Алматы ФСРРК',
        month: 'АВГУСТ',
        fishingType: FishingType.feeder,
      ),
      TournamentModel(
        id: 'aug_4',
        name: 'УТС перед Чемпионатом мира по спортивному лову карпа',
        startDate: DateTime(2025, 8, 10),
        endDate: DateTime(2025, 8, 17),
        duration: 168,
        location: 'Хорватия',
        organizer: 'ФСРРК',
        month: 'АВГУСТ',
        fishingType: FishingType.carpFishing,
      ),
      TournamentModel(
        id: 'aug_5',
        name: 'Чемпионат г. Алматы по спортивному лову карпа',
        startDate: DateTime(2025, 8, 14),
        endDate: DateTime(2025, 8, 17),
        duration: 72,
        location: 'Водохранилище «Казфиш»',
        organizer: 'ФСРА УС г. Алматы',
        month: 'АВГУСТ',
        fishingType: FishingType.carpFishing,
      ),
      TournamentModel(
        id: 'aug_6',
        name: 'Чемпионат г. Астана',
        startDate: DateTime(2025, 8, 21),
        endDate: DateTime(2025, 8, 24),
        duration: 72,
        location: 'оз. Тойганколь Акмолинская область Ерейментауский район',
        organizer: 'ФСР г. Астаны/Карповый клуб Астана',
        month: 'АВГУСТ',
        fishingType: FishingType.carpFishing,
      ),
      TournamentModel(
        id: 'aug_7',
        name: '"Gold Carp" большая коммерция',
        startDate: DateTime(2025, 8, 21),
        endDate: DateTime(2025, 8, 24),
        duration: 72,
        location: 'вдх. KazFish г. Алматы',
        organizer: 'Jetysu Carp Club',
        month: 'АВГУСТ',
        fishingType: FishingType.carpFishing,
      ),
      TournamentModel(
        id: 'aug_8',
        name: 'Чемпионат РК по спортивному лову рыбы на поплавочную удочку',
        startDate: DateTime(2025, 8, 28),
        endDate: DateTime(2025, 8, 31),
        duration: 72,
        location: 'г. Астана, река Есиль',
        organizer: 'РГКП ДРС УСФК',
        month: 'АВГУСТ',
        fishingType: FishingType.floatFishing,
      ),

      // СЕНТЯБРЬ
      TournamentModel(
        id: 'sep_1',
        name: 'Чемпионат ЮККК',
        startDate: DateTime(2025, 9, 3),
        endDate: DateTime(2025, 9, 7),
        duration: 96,
        location: 'вдх. Шардара Туркестанская область',
        organizer: 'Клуб ЮККК',
        month: 'СЕНТЯБРЬ',
        fishingType: FishingType.carpFishing,
      ),
      TournamentModel(
        id: 'sep_2',
        name: 'Коммерческий турнир "Осенний Карп"',
        startDate: DateTime(2025, 9, 4),
        endDate: DateTime(2025, 9, 7),
        duration: 72,
        location: 'оз. Тополек Область Абай (г. Семей)',
        organizer: 'ФСР области Абай/Карповый клуб Семей',
        month: 'СЕНТЯБРЬ',
        fishingType: FishingType.carpFishing,
      ),
      TournamentModel(
        id: 'sep_3',
        name: 'Чемпионат РК по спортивному лову рыбы на спиннинг с лодок',
        startDate: DateTime(2025, 9, 4),
        endDate: DateTime(2025, 9, 7),
        duration: 72,
        location: 'ВКО Бухтарминское вдхр.',
        organizer: 'РГКП ДРС УСФК',
        month: 'СЕНТЯБРЬ',
        fishingType: FishingType.spinning,
      ),
      TournamentModel(
        id: 'sep_4',
        name: 'Чемпионат РК по спортивному лову рыбы "Street Fishing"',
        startDate: DateTime(2025, 9, 9),
        endDate: DateTime(2025, 9, 12),
        duration: 72,
        location: 'г. Астана, река Есиль',
        organizer: 'РГКП ДРС УСФК',
        month: 'СЕНТЯБРЬ',
        fishingType: FishingType.spinning,
      ),
      TournamentModel(
        id: 'sep_5',
        name: 'Кубок Капитанов',
        startDate: DateTime(2025, 9, 11),
        endDate: DateTime(2025, 9, 14),
        duration: 72,
        location: 'вдх. KazFish г. Алматы',
        organizer: 'Jetysu Carp Club',
        month: 'СЕНТЯБРЬ',
        fishingType: FishingType.carpFishing,
      ),
      TournamentModel(
        id: 'sep_6',
        name: 'Чемпионат мира по спортивному лову карпа',
        startDate: DateTime(2025, 9, 15),
        endDate: DateTime(2025, 9, 21),
        duration: 144,
        location: 'Хорватия, Даково, озеро Йосава',
        organizer: 'FIPSed, ФСРРК',
        month: 'СЕНТЯБРЬ',
        fishingType: FishingType.carpFishing,
      ),
      TournamentModel(
        id: 'sep_7',
        name: 'Чемпионат Alash-SKK',
        startDate: DateTime(2025, 9, 19),
        endDate: DateTime(2025, 9, 21),
        duration: 48,
        location: 'вдх. Шардара Туркестанская область',
        organizer: 'Alash-SKK',
        month: 'СЕНТЯБРЬ',
        fishingType: FishingType.carpFishing,
      ),
      TournamentModel(
        id: 'sep_8',
        name: 'Чемпионат г. Алматы по спортивному лову рыбы на поплавочную удочку',
        startDate: DateTime(2025, 9, 20),
        endDate: DateTime(2025, 9, 21),
        duration: 24,
        location: 'Водохранилище «К-30»',
        organizer: 'ФСРА УС г. Алматы',
        month: 'СЕНТЯБРЬ',
        fishingType: FishingType.floatFishing,
      ),
      TournamentModel(
        id: 'sep_9',
        name: 'Международный турнир по спортивному лову карпа "Carp KZ"',
        startDate: DateTime(2025, 9, 24),
        endDate: DateTime(2025, 9, 28),
        duration: 96,
        location: 'Акмолинская обл. Еремейтауский р-он, озеро Тойганколь',
        organizer: 'РГКП ДРС УС г. Алматы',
        month: 'СЕНТЯБРЬ',
        fishingType: FishingType.carpFishing,
      ),
      TournamentModel(
        id: 'sep_10',
        name: 'Чемпионат Туркестанской области',
        startDate: DateTime(2025, 9, 25),
        endDate: DateTime(2025, 9, 28),
        duration: 72,
        location: 'вдх. Шардара Туркестанская область',
        organizer: 'ФСР Туркестанской области',
        month: 'СЕНТЯБРЬ',
        fishingType: FishingType.carpFishing,
      ),

      // ОКТЯБРЬ
      TournamentModel(
        id: 'oct_1',
        name: 'Чемпионат мира по спортивному лову рыбы на спиннинг с лодок',
        startDate: DateTime(2025, 10, 1),
        endDate: DateTime(2025, 10, 5),
        duration: 96,
        location: 'Эстония, озеро Вортсьярв',
        organizer: 'FIPSed, ФСРРК',
        month: 'ОКТЯБРЬ',
        fishingType: FishingType.spinning,
      ),
      TournamentModel(
        id: 'oct_2',
        name: 'Чемпионат г. Алматы по спортивному лову рыбы на спиннинг с лодок',
        startDate: DateTime(2025, 10, 3),
        endDate: DateTime(2025, 10, 5),
        duration: 48,
        location: 'Капчагайское вдхр.',
        organizer: 'ФСРА УС г. Алматы',
        month: 'ОКТЯБРЬ',
        fishingType: FishingType.spinning,
      ),
      TournamentModel(
        id: 'oct_3',
        name: 'Чемпионат Клубов по спортивному лову рыбы на фидер',
        startDate: DateTime(2025, 10, 6),
        endDate: DateTime(2025, 10, 13),
        duration: 168,
        location: 'Сербия, Бела Церква канал DTD',
        organizer: 'FIPSed, ФСРРК',
        month: 'ОКТЯБРЬ',
        fishingType: FishingType.feeder,
      ),
      TournamentModel(
        id: 'oct_4',
        name: 'Чемпионат "Жалгыз батыр"',
        startDate: DateTime(2025, 10, 9),
        endDate: DateTime(2025, 10, 12),
        duration: 72,
        location: 'вдх. Шардара Туркестанская область',
        organizer: 'CKK',
        month: 'ОКТЯБРЬ',
        fishingType: FishingType.carpFishing,
      ),
      TournamentModel(
        id: 'oct_5',
        name: 'Закрытие сезона',
        startDate: DateTime(2025, 10, 9),
        endDate: DateTime(2025, 10, 12),
        duration: 72,
        location: 'вдх. KazFish г. Алматы',
        organizer: 'Jetysu Carp Club',
        month: 'ОКТЯБРЬ',
        fishingType: FishingType.carpFishing,
      ),
      TournamentModel(
        id: 'oct_6',
        name: 'Кубок РК по спортивному лову на спиннинг с лодок памяти Болата Турлыханова',
        startDate: DateTime(2025, 10, 23),
        endDate: DateTime(2025, 10, 26),
        duration: 72,
        location: 'Алматинская обл. Капчагайское вдхр.',
        organizer: 'РГКП ДРС УСФК',
        month: 'ОКТЯБРЬ',
        fishingType: FishingType.spinning,
      ),

      // НОЯБРЬ
      TournamentModel(
        id: 'nov_1',
        name: 'Чемпионат мира по спортивному лову форели на спиннинг',
        startDate: DateTime(2025, 11, 17),
        endDate: DateTime(2025, 11, 23),
        duration: 144,
        location: 'Италия, Кампли озеро Веччио Мулино',
        organizer: 'FIPSed, ФСРРК',
        month: 'НОЯБРЬ',
        fishingType: FishingType.spinning,
      ),

      // ДЕКАБРЬ
      TournamentModel(
        id: 'dec_1',
        name: 'Международный турнир по спортивному лову рыбы со льда на мормышку "Ice Masters 2025"',
        startDate: DateTime(2025, 12, 18),
        endDate: DateTime(2025, 12, 21),
        duration: 72,
        location: 'Карагандинская обл. г. Темиртау, Самаркандское вдхр.',
        organizer: 'РГКП ДРС УС г. Алматы',
        month: 'ДЕКАБРЬ',
        fishingType: FishingType.iceFishing,
      ),
    ];
  }

  // Фильтры по типу рыбалки
  List<TournamentModel> getTournamentsByFishingType(FishingType fishingType) {
    return getAllTournaments().where((t) => t.fishingType == fishingType).toList();
  }

  // Фильтры по категории турнира
  List<TournamentModel> getTournamentsByCategory(TournamentCategory category) {
    return getAllTournaments().where((t) => t.category == category).toList();
  }

  // Фильтры по месяцу
  List<TournamentModel> getTournamentsByMonth(String month) {
    return getAllTournaments().where((t) => t.month == month).toList();
  }

  // Фильтры по статусу
  List<TournamentModel> getUpcomingTournaments() {
    return getAllTournaments().where((t) => t.isFuture).toList();
  }

  List<TournamentModel> getActiveTournaments() {
    return getAllTournaments().where((t) => t.isActive).toList();
  }

  List<TournamentModel> getPastTournaments() {
    return getAllTournaments().where((t) => t.isPast).toList();
  }

  // Поиск турниров
  List<TournamentModel> searchTournaments(String query) {
    final lowercaseQuery = query.toLowerCase();
    return getAllTournaments().where((t) =>
    t.name.toLowerCase().contains(lowercaseQuery) ||
        t.location.toLowerCase().contains(lowercaseQuery) ||
        t.organizer.toLowerCase().contains(lowercaseQuery)
    ).toList();
  }

  // Получить статистику по типам рыбалки
  Map<FishingType, int> getFishingTypeStatistics() {
    final tournaments = getAllTournaments();
    final Map<FishingType, int> stats = {};

    for (final tournament in tournaments) {
      stats[tournament.fishingType] = (stats[tournament.fishingType] ?? 0) + 1;
    }

    return stats;
  }

  // Получить ближайшие турниры (следующие 30 дней)
  List<TournamentModel> getUpcomingTournamentsInMonth() {
    final now = DateTime.now();
    final nextMonth = now.add(const Duration(days: 30));

    return getAllTournaments().where((t) =>
    t.startDate.isAfter(now) && t.startDate.isBefore(nextMonth)
    ).toList()..sort((a, b) => a.startDate.compareTo(b.startDate));
  }
}