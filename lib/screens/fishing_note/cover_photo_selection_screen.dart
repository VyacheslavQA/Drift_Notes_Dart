// Путь: lib/screens/fishing_note/cover_photo_selection_screen.dart

import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../widgets/universal_image.dart'; // Добавляем импорт UniversalImage

class CoverPhotoSelectionScreen extends StatefulWidget {
  final List<String> photoUrls;
  final String? currentCoverPhotoUrl;
  final Map<String, dynamic>? currentCropSettings;

  const CoverPhotoSelectionScreen({
    Key? key,
    required this.photoUrls,
    this.currentCoverPhotoUrl,
    this.currentCropSettings,
  }) : super(key: key);

  @override
  _CoverPhotoSelectionScreenState createState() => _CoverPhotoSelectionScreenState();
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
    _selectedPhotoUrl = widget.currentCoverPhotoUrl ??
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
      'cropSettings': _cropSettings ?? {
        'offsetX': _offsetX,
        'offsetY': _offsetY,
        'scale': _scale,
      },
    };

    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Выбор обложки',
          style: TextStyle(
            color: AppConstants.textColor,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppConstants.textColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
                _isCropping ? Icons.crop : Icons.check,
                color: AppConstants.textColor
            ),
            onPressed: _isCropping ? _toggleCropping : _saveCoverPhoto,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Отображение выбранного фото с возможностью кадрирования
            if (_selectedPhotoUrl.isNotEmpty) ...[
              Expanded(
                flex: 3,
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppConstants.primaryColor,
                      width: 2,
                    ),
                  ),
                  child: _isCropping
                      ? _buildCroppingView()
                      : ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: UniversalImage(
                      imageUrl: _selectedPhotoUrl,
                      fit: BoxFit.cover,
                      placeholder: Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                              AppConstants.textColor),
                        ),
                      ),
                      errorWidget: const Icon(
                        Icons.error,
                        color: Colors.red,
                        size: 50,
                      ),
                    ),
                  ),
                ),
              ),

              // Кнопка для включения/выключения режима кадрирования
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: ElevatedButton.icon(
                  onPressed: _toggleCropping,
                  icon: Icon(_isCropping ? Icons.check : Icons.crop),
                  label: Text(_isCropping ? 'Применить кадрирование' : 'Кадрировать'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isCropping
                        ? Colors.green
                        : AppConstants.primaryColor,
                    foregroundColor: AppConstants.textColor,
                    minimumSize: const Size(double.infinity, 46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Выбор фотографии из доступных
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'Выберите фото',
                      style: TextStyle(
                        color: AppConstants.textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: widget.photoUrls.isEmpty
                        ? Center(
                      child: Text(
                        'Нет доступных фотографий',
                        style: TextStyle(
                          color: AppConstants.textColor,
                          fontSize: 16,
                        ),
                      ),
                    )
                        : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 1,
                      ),
                      itemCount: widget.photoUrls.length,
                      itemBuilder: (context, index) {
                        final photoUrl = widget.photoUrls[index];
                        final isSelected = photoUrl == _selectedPhotoUrl;

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
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? AppConstants.primaryColor
                                    : Colors.transparent,
                                width: 3,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(5),
                              child: UniversalImage(
                                imageUrl: photoUrl,
                                fit: BoxFit.cover,
                                placeholder: Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          AppConstants.textColor),
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                                errorWidget: const Icon(
                                  Icons.error,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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

  // Виджет для кадрирования фото
  Widget _buildCroppingView() {
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
              borderRadius: BorderRadius.circular(10),
              child: Transform.scale(
                scale: _scale,
                child: Transform.translate(
                  offset: Offset(_offsetX, _offsetY),
                  child: UniversalImage(
                    imageUrl: _selectedPhotoUrl,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            'Перемещайте и масштабируйте изображение',
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }
}