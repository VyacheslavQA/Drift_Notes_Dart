// Путь: lib/screens/shops/shop_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/app_constants.dart';
import '../../models/shop_model.dart';
import '../../localization/app_localizations.dart';

class ShopDetailScreen extends StatelessWidget {
  final ShopModel shop;

  const ShopDetailScreen({super.key, required this.shop});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          shop.name,
          style: TextStyle(
            color: AppConstants.textColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppConstants.textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        bottom: true,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Главная карточка с логотипом и основной информацией
              _buildMainInfoCard(localizations),

              const SizedBox(height: 16),

              // Описание
              _buildDescriptionCard(localizations),

              const SizedBox(height: 16),

              // Услуги (если есть)
              if (shop.services.isNotEmpty) _buildServicesCard(localizations),

              const SizedBox(height: 16),

              // Контактная информация
              _buildContactCard(localizations),

              const SizedBox(height: 24),

              // Кнопки действий
              _buildActionButtons(context, localizations),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainInfoCard(AppLocalizations localizations) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Логотип
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppConstants.primaryColor.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.asset(
                    'assets/shops/mastercarp_logo.png',
                    width: 76,
                    height: 76,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Text(
                          shop.specialization.icon,
                          style: const TextStyle(fontSize: 40),
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Название (убрали статус)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shop.name,
                      style: TextStyle(
                        color: AppConstants.textColor,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Особенности
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildFeatureItem(
                icon: Icons.shopping_cart,
                label: localizations.translate('internet_store'),
                isActive: shop.hasOnlineStore,
              ),
              _buildFeatureItem(
                icon: Icons.local_shipping,
                label: localizations.translate('delivery_service'),
                isActive: shop.hasDelivery,
              ),
              _buildFeatureItem(
                icon: Icons.build,
                label: localizations.translate('shop_services'),
                isActive: shop.services.isNotEmpty,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String label,
    required bool isActive,
  }) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color:
                isActive
                    ? AppConstants.primaryColor.withValues(alpha: 0.2)
                    : AppConstants.textColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color:
                isActive
                    ? AppConstants.primaryColor
                    : AppConstants.textColor.withValues(alpha: 0.5),
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color:
                isActive
                    ? AppConstants.textColor
                    : AppConstants.textColor.withValues(alpha: 0.5),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDescriptionCard(AppLocalizations localizations) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info, color: AppConstants.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                localizations.translate('description'),
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            localizations.translate(
              shop.description,
            ), // вместо shop.description
            style: TextStyle(
              color: AppConstants.textColor.withValues(alpha: 0.8),
              fontSize: 16,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesCard(AppLocalizations localizations) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.build, color: AppConstants.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                localizations.translate('shop_services'),
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...shop.services.map(
            (serviceKey) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: AppConstants.primaryColor,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      localizations.translate(serviceKey), // Переводим услуги
                      style: TextStyle(
                        color: AppConstants.textColor.withValues(alpha: 0.8),
                        fontSize: 14,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(AppLocalizations localizations) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.contact_mail,
                color: AppConstants.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                localizations.translate('contacts'),
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Адрес
          if (shop.address != null)
            _buildContactItem(
              icon: Icons.location_on,
              label: localizations.translate('address'),
              value: shop.address!,
              onTap: null,
            ),

          // Телефоны
          if (shop.phone != null)
            _buildContactItem(
              icon: Icons.phone,
              label: localizations.translate('phone'),
              value: shop.phone!,
              onTap: () => _launchPhone(shop.phone!),
            ),

          // Дополнительный телефон
          _buildContactItem(
            icon: Icons.phone,
            label: localizations.translate('phone'),
            value: '+7(705)111-18-88',
            onTap: () => _launchPhone('+7(705)111-18-88'),
          ),

          // Время работы
          if (shop.workingHours != null && shop.workingHours!.isNotEmpty)
            _buildContactItem(
              icon: Icons.access_time,
              label: 'Время работы',
              value: shop.workingHours!['monday'] ?? 'Пн-Вс 10.00 - 20.00',
              onTap: null,
            ),

          // Email
          if (shop.email != null)
            _buildContactItem(
              icon: Icons.email,
              label: localizations.translate('email'),
              value: shop.email!,
              onTap: () => _launchEmail(shop.email!),
            ),

          // Веб-сайт
          _buildContactItem(
            icon: Icons.language,
            label: localizations.translate('website'),
            value: shop.website,
            onTap: () => _launchWebsite(shop.website),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                color: AppConstants.textColor.withValues(alpha: 0.7),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: AppConstants.textColor.withValues(alpha: 0.6),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: TextStyle(
                        color:
                            onTap != null
                                ? AppConstants.primaryColor
                                : AppConstants.textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        decoration:
                            onTap != null ? TextDecoration.underline : null,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.launch,
                  color: AppConstants.textColor.withValues(alpha: 0.5),
                  size: 16,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    AppLocalizations localizations,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Кнопка перехода на сайт
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _launchWebsite(shop.website),
              icon: const Icon(Icons.language),
              label: Text(localizations.translate('visit_website')),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: AppConstants.textColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Кнопка звонка
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _launchPhone(shop.phone!),
              icon: const Icon(Icons.phone),
              label: Text(localizations.translate('call_shop')),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppConstants.textColor,
                side: BorderSide(color: AppConstants.textColor),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchWebsite(String url) async {
    try {
      final Uri uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Ошибка при открытии сайта: $e');
    }
  }

  Future<void> _launchPhone(String phone) async {
    try {
      final Uri uri = Uri.parse('tel:$phone');
      await launchUrl(uri);
    } catch (e) {
      debugPrint('Ошибка при совершении звонка: $e');
    }
  }

  Future<void> _launchEmail(String email) async {
    try {
      final Uri uri = Uri.parse('mailto:$email');
      await launchUrl(uri);
    } catch (e) {
      debugPrint('Ошибка при отправке email: $e');
    }
  }
}
