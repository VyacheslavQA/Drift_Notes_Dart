// Путь: lib/widgets/universal_image.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../constants/app_constants.dart';
import '../services/local/local_file_service.dart';

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
    Key? key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Если URL пустой, показываем заглушку
    if (imageUrl.isEmpty) {
      return _buildPlaceholderOrError(isError: true);
    }

    // Если URL начинается с 'file://', это локальный файл
    if (LocalFileService().isLocalFileUri(imageUrl)) {
      return _buildLocalImage();
    }

    // Если URL начинается с 'http', это сетевое изображение
    if (imageUrl.startsWith('http')) {
      return _buildNetworkImage();
    }

    // Если URL - это 'offline_photo', показываем заглушку с индикатором
    if (imageUrl == 'offline_photo') {
      return _buildOfflineIndicator();
    }

    // Если URL неизвестного типа, показываем заглушку с ошибкой
    return _buildPlaceholderOrError(isError: true);
  }

  /// Построение виджета для локального изображения
  Widget _buildLocalImage() {
    try {
      final localService = LocalFileService();
      final file = localService.localUriToFile(imageUrl);

      if (file == null || !file.existsSync()) {
        return _buildPlaceholderOrError(isError: true);
      }

      return ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        child: Image.file(
          file,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholderOrError(isError: true),
        ),
      );
    } catch (e) {
      debugPrint('Ошибка при отображении локального изображения: $e');
      return _buildPlaceholderOrError(isError: true);
    }
  }

  /// Построение виджета для сетевого изображения
  Widget _buildNetworkImage() {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => placeholder ?? _buildPlaceholderOrError(),
        errorWidget: (context, url, error) =>
        errorWidget ?? _buildPlaceholderOrError(isError: true),
      ),
    );
  }

  /// Построение заглушки или виджета ошибки
  Widget _buildPlaceholderOrError({bool isError = false}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppConstants.backgroundColor.withOpacity(0.7),
        borderRadius: borderRadius ?? BorderRadius.zero,
      ),
      child: Center(
        child: isError
            ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.broken_image_outlined,
              color: Colors.grey[400],
              size: 40,
            ),
            const SizedBox(height: 8),
            Text(
              'Изображение недоступно',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
              ),
            ),
          ],
        )
            : CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppConstants.textColor),
          strokeWidth: 2.0,
        ),
      ),
    );
  }

  /// Построение индикатора для офлайн-фото (ожидающего синхронизации)
  Widget _buildOfflineIndicator() {
    return Stack(
      children: [
        _buildPlaceholderOrError(),
        Positioned(
          right: 8,
          bottom: 8,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
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