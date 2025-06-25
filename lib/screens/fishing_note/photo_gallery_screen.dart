// Путь: lib/screens/fishing_note/photo_gallery_screen.dart

import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../constants/responsive_constants.dart';
import '../../utils/responsive_utils.dart';
import '../../widgets/universal_image.dart';
import '../../localization/app_localizations.dart';

class PhotoGalleryScreen extends StatefulWidget {
  final List<String> photos;
  final int initialIndex;

  const PhotoGalleryScreen({
    super.key,
    required this.photos,
    this.initialIndex = 0,
  });

  @override
  State<PhotoGalleryScreen> createState() => _PhotoGalleryScreenState();
}

class _PhotoGalleryScreenState extends State<PhotoGalleryScreen> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final isSmallScreen = ResponsiveUtils.isSmallScreen(context);
    final isTablet = ResponsiveUtils.isTablet(context);

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.5),
        elevation: 0,
        toolbarHeight: isTablet ? kToolbarHeight + 8 : kToolbarHeight, // Адаптивная высота
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.white,
            size: isSmallScreen ? 24 : 28, // Адаптивный размер иконки
          ),
          onPressed: () => Navigator.pop(context),
          constraints: BoxConstraints(
            minWidth: ResponsiveConstants.minTouchTarget,
            minHeight: ResponsiveConstants.minTouchTarget,
          ),
        ),
        title: Text(
          '${localizations.translate('photo_number')} ${_currentIndex + 1}/${widget.photos.length}',
          style: TextStyle(
            color: Colors.white,
            fontSize: isSmallScreen ? 16 : (isTablet ? 20 : 18), // Адаптивный шрифт
            fontWeight: FontWeight.w500,
          ),
          overflow: TextOverflow.ellipsis, // Защита от overflow
          maxLines: 1,
        ),
        centerTitle: true, // Центрируем заголовок
      ),
      body: GestureDetector(
        onTap: () {
          Navigator.pop(context);
        },
        child: PageView.builder(
          controller: _pageController,
          itemCount: widget.photos.length,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          itemBuilder: (context, index) {
            return Center(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  // Адаптивные отступы для лучшего просмотра
                  horizontal: isSmallScreen ? 8 : 16,
                  vertical: isSmallScreen ? 16 : 24,
                ),
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: isTablet ? 5.0 : 3.0, // Больше зум на планшетах
                  child: UniversalImage(
                    imageUrl: widget.photos[index],
                    fit: BoxFit.contain,
                    placeholder: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: isSmallScreen ? 32 : 40, // Адаптивный размер loader
                            height: isSmallScreen ? 32 : 40,
                            child: CircularProgressIndicator(
                              strokeWidth: isSmallScreen ? 2 : 3, // Адаптивная толщина
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppConstants.textColor,
                              ),
                            ),
                          ),
                          SizedBox(height: ResponsiveConstants.spacingM),
                          // Показываем текст загрузки только на больших экранах
                          if (!isSmallScreen)
                            Text(
                              localizations.translate('loading'),
                              style: TextStyle(
                                color: AppConstants.textColor,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                        ],
                      ),
                    ),
                    errorWidget: Center(
                      child: Container(
                        padding: EdgeInsets.all(
                          isSmallScreen ? ResponsiveConstants.spacingM : ResponsiveConstants.spacingL,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: isSmallScreen ? 40 : (isTablet ? 56 : 48), // Адаптивный размер иконки ошибки
                            ),
                            SizedBox(height: ResponsiveConstants.spacingM),
                            Text(
                              localizations.translate('error_loading_image'),
                              style: TextStyle(
                                color: AppConstants.textColor,
                                fontSize: isSmallScreen ? 14 : 16, // Адаптивный шрифт
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            // Показываем кнопку повтора только на больших экранах
                            if (!isSmallScreen) ...[
                              SizedBox(height: ResponsiveConstants.spacingM),
                              TextButton(
                                onPressed: () {
                                  // Принудительная перерисовка для повторной загрузки
                                  setState(() {});
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: AppConstants.textColor,
                                  minimumSize: Size(
                                    ResponsiveConstants.minTouchTarget * 2,
                                    ResponsiveConstants.minTouchTarget,
                                  ),
                                ),
                                child: Text(
                                  localizations.translate('retry'),
                                  style: TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
      // Адаптивный индикатор страниц внизу (только если несколько фото)
      bottomNavigationBar: widget.photos.length > 1
          ? Container(
        color: Colors.black.withValues(alpha: 0.3),
        padding: EdgeInsets.symmetric(
          vertical: isSmallScreen ? 8 : 12,
          horizontal: ResponsiveConstants.spacingM,
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Индикаторы точками для небольшого количества фото
              if (widget.photos.length <= 10)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    widget.photos.length,
                        (index) => Container(
                      margin: EdgeInsets.symmetric(
                        horizontal: ResponsiveConstants.spacingXS,
                      ),
                      width: isSmallScreen ? 6 : 8,
                      height: isSmallScreen ? 6 : 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: index == _currentIndex
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                )
              // Текстовый индикатор для большого количества фото
              else
                Text(
                  '${_currentIndex + 1} / ${widget.photos.length}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isSmallScreen ? 12 : 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
      )
          : null,
    );
  }
}