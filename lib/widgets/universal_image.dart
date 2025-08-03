// Путь: lib/widgets/universal_image.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../constants/app_constants.dart';
import '../services/local/local_file_service.dart';
import '../localization/app_localizations.dart';

/// Виджет для отображения изображений из различных источников (сеть, локальный файл)
class UniversalImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;
  final bool isLoading;

  const UniversalImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    // Если URL пустой, показываем заглушку
    if (imageUrl.isEmpty) {
      return _buildPlaceholderOrError(context, isError: true);
    }

    // Если URL начинается с 'file://', это локальный файл
    if (imageUrl.startsWith('file://')) {
      return _buildLocalImage(context);
    }

    // Если URL начинается с 'http', это сетевое изображение
    if (imageUrl.startsWith('http')) {
      return _buildNetworkImage(context);
    }

    // Если URL - это 'offline_photo', показываем заглушку с индикатором
    if (imageUrl == 'offline_photo') {
      return _buildOfflineIndicator(context);
    }

    // Если URL неизвестного типа, показываем заглушку с ошибкой
    return _buildPlaceholderOrError(context, isError: true);
  }

  /// Построение виджета для локального изображения
  Widget _buildLocalImage(BuildContext context) {
    try {
      // Важно: получаем File напрямую из пути, не используя CachedNetworkImage
      final filePath = imageUrl.substring(7); // Удаляем 'file://'
      final file = File(filePath);

      if (!file.existsSync()) {
        debugPrint('🚫 Локальный файл не существует: $filePath');
        return _buildPlaceholderOrError(context, isError: true);
      }

      return ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        child: Image.file(
          file,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('🚫 Ошибка при загрузке локального файла: $error');
            return _buildPlaceholderOrError(context, isError: true);
          },
          cacheWidth: width?.toInt(),
          cacheHeight: height?.toInt(),
        ),
      );
    } catch (e) {
      debugPrint('🚫 Ошибка при отображении локального изображения: $e');
      return _buildPlaceholderOrError(context, isError: true);
    }
  }

  /// Построение виджета для сетевого изображения
  Widget _buildNetworkImage(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        memCacheWidth: width?.toInt(),
        memCacheHeight: height?.toInt(),
        maxWidthDiskCache: 800, // Ограничиваем размер кэша для экономии памяти
        fadeInDuration: const Duration(milliseconds: 200),
        placeholder:
            (context, url) => placeholder ?? _buildPlaceholderOrError(context),
        errorWidget: (context, url, error) {
          debugPrint('🚫 Ошибка при загрузке сетевого изображения: $error');
          return errorWidget ??
              _buildPlaceholderOrError(context, isError: true);
        },
      ),
    );
  }

  /// Построение заглушки или виджета ошибки
  Widget _buildPlaceholderOrError(
    BuildContext context, {
    bool isError = false,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppConstants.backgroundColor.withValues(alpha: 0.7),
        borderRadius: borderRadius ?? BorderRadius.zero,
      ),
      child: Center(
        child:
            isError
                ? errorWidget ??
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image_outlined,
                          color: Colors.grey[400],
                          size: 40,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppLocalizations.of(
                            context,
                          ).translate('photo_unavailable'),
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    )
                : placeholder ??
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppConstants.textColor,
                      ),
                      strokeWidth: 2.0,
                    ),
      ),
    );
  }

  /// Построение индикатора для офлайн-фото (ожидающего синхронизации)
  Widget _buildOfflineIndicator(BuildContext context) {
    return Stack(
      children: [
        _buildPlaceholderOrError(context),
        Positioned(
          right: 8,
          bottom: 8,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.cloud_upload,
              color: Colors.white,
              size: 16,
            ),
          ),
        ),
      ],
    );
  }
}
