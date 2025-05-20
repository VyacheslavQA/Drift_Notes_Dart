// Путь: lib/widgets/fishing_photo_grid.dart

import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../models/fishing_note_model.dart';
import '../widgets/universal_image.dart';
import '../screens/fishing_note/photo_gallery_screen.dart'; // Исправленный импорт

class FishingPhotoGrid extends StatefulWidget {
  final List<String> photoUrls;
  final Function()? onViewAllPressed;
  final bool showEmpty;
  final String emptyText;
  final int maxDisplayed;

  const FishingPhotoGrid({
    Key? key,
    required this.photoUrls,
    this.onViewAllPressed,
    this.showEmpty = true,
    this.emptyText = 'Нет фотографий',
    this.maxDisplayed = 4,
  }) : super(key: key);

  @override
  State<FishingPhotoGrid> createState() => _FishingPhotoGridState();
}

class _FishingPhotoGridState extends State<FishingPhotoGrid> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    // Отображение заглушки, если список пустой
    if (widget.photoUrls.isEmpty) {
      if (!widget.showEmpty) {
        return const SizedBox.shrink();
      }

      return _buildEmptyState();
    }

    // Ограничиваем количество отображаемых фото (для превью)
    final displayedPhotos = widget.photoUrls.length > widget.maxDisplayed
        ? widget.photoUrls.sublist(0, widget.maxDisplayed)
        : widget.photoUrls;

    final hasMore = widget.photoUrls.length > widget.maxDisplayed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Фотографии в сетке
        GridView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.2,
          ),
          itemCount: displayedPhotos.length,
          itemBuilder: (context, index) {
            return _buildPhotoItem(displayedPhotos[index], index);
          },
        ),

        // Кнопка "Показать все", если есть дополнительные фото
        if (hasMore && widget.onViewAllPressed != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: GestureDetector(
              onTap: widget.onViewAllPressed,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Смотреть все (${widget.photoUrls.length})',
                    style: TextStyle(
                      color: AppConstants.primaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right,
                    color: AppConstants.primaryColor,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // Карточка для отдельного фото
  Widget _buildPhotoItem(String photoUrl, int index) {
    return GestureDetector(
      onTap: () => _openPhotoViewer(index),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Изображение с обработкой ошибок и состояний загрузки
              UniversalImage(
                imageUrl: photoUrl,
                fit: BoxFit.cover,
                placeholder: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppConstants.textColor),
                    strokeWidth: 2.0,
                  ),
                ),
                errorWidget: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.broken_image,
                        color: Colors.red.withOpacity(0.7),
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Ошибка загрузки',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

              // Затемнение для улучшения видимости
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.3),
                    ],
                    stops: const [0.7, 1.0],
                  ),
                ),
              ),

              // Индикатор загрузки для офлайн-фото
              if (photoUrl == 'offline_photo' || _isLoading)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Отображение, когда нет фотографий
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppConstants.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            color: AppConstants.textColor.withOpacity(0.5),
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            widget.emptyText,
            style: TextStyle(
              color: AppConstants.textColor.withOpacity(0.7),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Открытие просмотрщика фотографий
  void _openPhotoViewer(int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhotoGalleryScreen(
          photos: widget.photoUrls,
          initialIndex: initialIndex,
        ),
      ),
    );
  }
}