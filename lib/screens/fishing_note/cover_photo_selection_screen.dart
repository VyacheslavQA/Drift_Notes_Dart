// Путь: lib/screens/fishing_note/cover_photo_selection_screen.dart

import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../constants/responsive_constants.dart';
import '../../utils/responsive_utils.dart';
import '../../widgets/universal_image.dart';
import '../../localization/app_localizations.dart';

class CoverPhotoSelectionScreen extends StatefulWidget {
  final List<String> photoUrls;
  final String? currentCoverPhotoUrl;
  final Map<String, dynamic>? currentCropSettings;

  const CoverPhotoSelectionScreen({
    super.key,
    required this.photoUrls,
    this.currentCoverPhotoUrl,
    this.currentCropSettings,
  });

  @override
  State<CoverPhotoSelectionScreen> createState() =>
      _CoverPhotoSelectionScreenState();
}

class _CoverPhotoSelectionScreenState extends State<CoverPhotoSelectionScreen> {
  late String _selectedPhotoUrl;
  Map<String, dynamic>? _cropSettings;
  bool _isCropping = false;

  // Значения смещения и масштаба для кадрирования
  double _offsetX = 0.0;
  double _offsetY = 0.0;
  double _scale = 1.0;

  @override
  void initState() {
    super.initState();

    // Если есть текущая обложка, используем её, иначе берём первое фото
    _selectedPhotoUrl =
        widget.currentCoverPhotoUrl ??
            (widget.photoUrls.isNotEmpty ? widget.photoUrls.first : '');

    // Если есть настройки кадрирования, загружаем их
    if (widget.currentCropSettings != null) {
      _cropSettings = widget.currentCropSettings;
      _offsetX = widget.currentCropSettings!['offsetX'] ?? 0.0;
      _offsetY = widget.currentCropSettings!['offsetY'] ?? 0.0;
      _scale = widget.currentCropSettings!['scale'] ?? 1.0;
    }
  }

  // Сохранение выбранной обложки
  void _saveCoverPhoto() {
    final result = {
      'coverPhotoUrl': _selectedPhotoUrl,
      'cropSettings':
      _cropSettings ??
          {'offsetX': _offsetX, 'offsetY': _offsetY, 'scale': _scale},
    };

    Navigator.pop(context, result);
  }

  // Переключение режима кадрирования
  void _toggleCropping() {
    setState(() {
      _isCropping = !_isCropping;

      // Если выходим из режима кадрирования, сохраняем настройки
      if (!_isCropping) {
        _cropSettings = {
          'offsetX': _offsetX,
          'offsetY': _offsetY,
          'scale': _scale,
        };
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final horizontalPadding = ResponsiveUtils.getHorizontalPadding(context);

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          localizations.translate('select_cover'),
          style: TextStyle(
            color: AppConstants.textColor,
            fontSize: ResponsiveUtils.getOptimalFontSize(context, 20, maxSize: 22),
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: AppConstants.textColor,
            size: ResponsiveUtils.getIconSize(context),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isCropping ? Icons.crop : Icons.check,
              color: AppConstants.textColor,
              size: ResponsiveUtils.getIconSize(context),
            ),
            onPressed: _isCropping ? _toggleCropping : _saveCoverPhoto,
          ),
        ],
      ),
      body: SafeArea(
        child: _buildLayout(localizations, horizontalPadding),
      ),
    );
  }

  // Единый адаптивный layout
  Widget _buildLayout(AppLocalizations localizations, double horizontalPadding) {
    return Column(
      children: [
        // Отображение выбранного фото с возможностью кадрирования
        if (_selectedPhotoUrl.isNotEmpty) ...[
          Expanded(
            flex: ResponsiveUtils.getResponsiveValue(
              context,
              mobile: 3,
              tablet: 2,
            ),
            child: Container(
              margin: EdgeInsets.all(horizontalPadding),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(
                  ResponsiveUtils.getBorderRadius(context, baseRadius: ResponsiveConstants.radiusM),
                ),
                border: Border.all(
                  color: AppConstants.primaryColor,
                  width: 2,
                ),
              ),
              child: _isCropping
                  ? _buildCroppingView(localizations)
                  : _buildPhotoView(),
            ),
          ),

          // Кнопка для включения/выключения режима кадрирования
          Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: _buildCropButton(localizations),
          ),
        ],

        SizedBox(height: ResponsiveConstants.spacingM),

        // Выбор фотографии из доступных
        Expanded(
          flex: ResponsiveUtils.getResponsiveValue(
            context,
            mobile: 2,
            tablet: 3,
          ),
          child: _buildPhotoSelector(localizations, horizontalPadding),
        ),
      ],
    );
  }

  // Виджет просмотра фото
  Widget _buildPhotoView() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(
        ResponsiveUtils.getBorderRadius(context, baseRadius: ResponsiveConstants.radiusM) - 2,
      ),
      child: UniversalImage(
        imageUrl: _selectedPhotoUrl,
        fit: BoxFit.cover,
        placeholder: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppConstants.textColor),
          ),
        ),
        errorWidget: Icon(
          Icons.error,
          color: Colors.red,
          size: ResponsiveUtils.getIconSize(context, baseSize: 50),
        ),
      ),
    );
  }

  // Кнопка кадрирования
  Widget _buildCropButton(AppLocalizations localizations) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _toggleCropping,
        icon: Icon(
          _isCropping ? Icons.check : Icons.crop,
          size: ResponsiveUtils.getIconSize(context),
        ),
        label: Text(
          _isCropping
              ? localizations.translate('apply_cropping')
              : localizations.translate('crop'),
          style: TextStyle(
            fontSize: ResponsiveUtils.getOptimalFontSize(context, 14, maxSize: 16),
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _isCropping ? Colors.green : AppConstants.primaryColor,
          foregroundColor: AppConstants.textColor,
          minimumSize: Size(double.infinity, ResponsiveConstants.minTouchTarget),
          padding: EdgeInsets.symmetric(vertical: ResponsiveConstants.spacingM),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              ResponsiveUtils.getBorderRadius(context, baseRadius: ResponsiveConstants.radiusM),
            ),
          ),
        ),
      ),
    );
  }

  // Селектор фотографий
  Widget _buildPhotoSelector(AppLocalizations localizations, double sidePadding) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: sidePadding > 0 ? sidePadding : ResponsiveConstants.spacingM,
          ),
          child: Text(
            localizations.translate('select_photo'),
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: ResponsiveUtils.getOptimalFontSize(context, 16, maxSize: 18),
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        SizedBox(height: ResponsiveConstants.spacingS),
        Expanded(
          child: widget.photoUrls.isEmpty
              ? _buildEmptyState(localizations)
              : _buildPhotoGrid(sidePadding),
        ),
      ],
    );
  }

  // Пустое состояние
  Widget _buildEmptyState(AppLocalizations localizations) {
    return Center(
      child: Text(
        localizations.translate('no_photos_available'),
        style: TextStyle(
          color: AppConstants.textColor,
          fontSize: ResponsiveUtils.getOptimalFontSize(context, 14, maxSize: 16),
        ),
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
        maxLines: 2,
      ),
    );
  }

  // Сетка фотографий
  Widget _buildPhotoGrid(double sidePadding) {
    // Простое адаптивное количество колонок
    final crossAxisCount = ResponsiveUtils.getResponsiveValue(
      context,
      mobile: 3,
      tablet: 4,
    );

    final spacing = ResponsiveUtils.getResponsiveValue(
      context,
      mobile: ResponsiveConstants.spacingS,
      tablet: ResponsiveConstants.spacingM,
    );

    return GridView.builder(
      padding: EdgeInsets.all(
        sidePadding > 0 ? sidePadding : ResponsiveConstants.spacingM,
      ),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: 1,
      ),
      itemCount: widget.photoUrls.length,
      itemBuilder: (context, index) {
        final photoUrl = widget.photoUrls[index];
        final isSelected = photoUrl == _selectedPhotoUrl;

        return _buildPhotoGridItem(photoUrl, isSelected);
      },
    );
  }

  // Элемент сетки фотографий
  Widget _buildPhotoGridItem(String photoUrl, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPhotoUrl = photoUrl;
          // Сбрасываем настройки кадрирования при смене фото
          _offsetX = 0.0;
          _offsetY = 0.0;
          _scale = 1.0;
          _cropSettings = null;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.getBorderRadius(context, baseRadius: ResponsiveConstants.radiusS),
          ),
          border: Border.all(
            color: isSelected ? AppConstants.primaryColor : Colors.transparent,
            width: ResponsiveUtils.getResponsiveValue(context, mobile: 2.0, tablet: 3.0),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.getBorderRadius(context, baseRadius: ResponsiveConstants.radiusS) - 2,
          ),
          child: UniversalImage(
            imageUrl: photoUrl,
            fit: BoxFit.cover,
            placeholder: Center(
              child: SizedBox(
                width: ResponsiveUtils.getResponsiveValue(context, mobile: 20.0, tablet: 24.0),
                height: ResponsiveUtils.getResponsiveValue(context, mobile: 20.0, tablet: 24.0),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppConstants.textColor),
                  strokeWidth: 2,
                ),
              ),
            ),
            errorWidget: Icon(
              Icons.error,
              color: Colors.red,
              size: ResponsiveUtils.getIconSize(context, baseSize: 24),
            ),
          ),
        ),
      ),
    );
  }

  // Виджет для кадрирования фото
  Widget _buildCroppingView(AppLocalizations localizations) {
    return Column(
      children: [
        Expanded(
          child: InteractiveViewer(
            boundaryMargin: const EdgeInsets.all(0),
            minScale: 0.5,
            maxScale: 3.0,
            onInteractionUpdate: (details) {
              setState(() {
                _offsetX += details.focalPointDelta.dx;
                _offsetY += details.focalPointDelta.dy;

                if (details.scale != 1.0) {
                  _scale *= details.scale;
                }
              });
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                ResponsiveUtils.getBorderRadius(context, baseRadius: ResponsiveConstants.radiusM) - 2,
              ),
              child: Transform.scale(
                scale: _scale,
                child: Transform.translate(
                  offset: Offset(_offsetX, _offsetY),
                  child: UniversalImage(
                    imageUrl: _selectedPhotoUrl,
                    fit: BoxFit.contain,
                    placeholder: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppConstants.textColor),
                      ),
                    ),
                    errorWidget: Icon(
                      Icons.error,
                      color: Colors.red,
                      size: ResponsiveUtils.getIconSize(context, baseSize: 50),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.all(ResponsiveConstants.spacingS),
          child: Text(
            localizations.translate('move_and_scale'),
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: ResponsiveUtils.getOptimalFontSize(context, 12, maxSize: 14),
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }
}