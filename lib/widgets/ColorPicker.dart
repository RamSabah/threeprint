import 'package:flutter/material.dart';
import 'dart:math' as math;

class ColorPickerWidget extends StatefulWidget {
  final Color initialColor;
  final Function(Color) onColorChanged;
  final double width;
  final double height;

  const ColorPickerWidget({
    super.key,
    this.initialColor = Colors.red,
    required this.onColorChanged,
    this.width = 300,
    this.height = 400,
  });

  @override
  State<ColorPickerWidget> createState() => _ColorPickerWidgetState();
}

class _ColorPickerWidgetState extends State<ColorPickerWidget> {
  late HSVColor _currentHsv;
  late Color _currentColor;
  
  // Position controllers for the color selection
  double _hueSliderValue = 0.0;
  Offset _colorPosition = const Offset(0.5, 0.5);
  
  @override
  void initState() {
    super.initState();
    _currentColor = widget.initialColor;
    _currentHsv = HSVColor.fromColor(widget.initialColor);
    _hueSliderValue = _currentHsv.hue / 360.0;
    _colorPosition = Offset(_currentHsv.saturation, 1.0 - _currentHsv.value);
  }

  void _updateColor() {
    _currentHsv = HSVColor.fromAHSV(
      1.0,
      _hueSliderValue * 360.0,
      _colorPosition.dx,
      1.0 - _colorPosition.dy,
    );
    _currentColor = _currentHsv.toColor();
    widget.onColorChanged(_currentColor);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Color selection area
          Container(
            width: widget.width - 32,
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: GestureDetector(
                onPanUpdate: (details) {
                  final RenderBox box = context.findRenderObject() as RenderBox;
                  final Offset localPosition = box.globalToLocal(details.globalPosition);
                  final double dx = math.max(0.0, math.min(1.0, (localPosition.dx - 16) / (widget.width - 32)));
                  final double dy = math.max(0.0, math.min(1.0, (localPosition.dy - 56) / 200));
                  
                  setState(() {
                    _colorPosition = Offset(dx, dy);
                    _updateColor();
                  });
                },
                onTapDown: (details) {
                  final RenderBox box = context.findRenderObject() as RenderBox;
                  final Offset localPosition = box.globalToLocal(details.globalPosition);
                  final double dx = math.max(0.0, math.min(1.0, (localPosition.dx - 16) / (widget.width - 32)));
                  final double dy = math.max(0.0, math.min(1.0, (localPosition.dy - 56) / 200));
                  
                  setState(() {
                    _colorPosition = Offset(dx, dy);
                    _updateColor();
                  });
                },
                child: Stack(
                  children: [
                    // Base hue color
                    Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            HSVColor.fromAHSV(1.0, _hueSliderValue * 360.0, 1.0, 1.0).toColor(),
                            HSVColor.fromAHSV(1.0, _hueSliderValue * 360.0, 1.0, 1.0).toColor(),
                          ],
                        ),
                      ),
                    ),
                    // White to transparent gradient (saturation)
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [Colors.white, Colors.transparent],
                        ),
                      ),
                    ),
                    // Transparent to black gradient (value)
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black],
                        ),
                      ),
                    ),
                    // Selection indicator
                    Positioned(
                      left: _colorPosition.dx * (widget.width - 32) - 10,
                      top: _colorPosition.dy * 200 - 10,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Hue slider
          Container(
            height: 30,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFFF0000), // Red
                  Color(0xFFFFFF00), // Yellow
                  Color(0xFF00FF00), // Green
                  Color(0xFF00FFFF), // Cyan
                  Color(0xFF0000FF), // Blue
                  Color(0xFFFF00FF), // Magenta
                  Color(0xFFFF0000), // Red
                ],
              ),
            ),
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 30,
                thumbColor: Colors.white,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
                overlayShape: SliderComponentShape.noOverlay,
                activeTrackColor: Colors.transparent,
                inactiveTrackColor: Colors.transparent,
              ),
              child: Slider(
                value: _hueSliderValue,
                onChanged: (value) {
                  setState(() {
                    _hueSliderValue = value;
                    _updateColor();
                  });
                },
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Color information display
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                // HEX value
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'HEX',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        '#${_currentColor.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: _currentColor,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Color values grid
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  childAspectRatio: 2.5,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                  children: [
                    _buildColorValueCard('RGB', '${(_currentColor.r * 255).round()}, ${(_currentColor.g * 255).round()},\n${(_currentColor.b * 255).round()}'),
                    _buildColorValueCard('CMYK', _getCMYKString(_currentColor)),
                    _buildColorValueCard('HSV', '${_currentHsv.hue.round()}° ${(_currentHsv.saturation * 100).round()}%\n${(_currentHsv.value * 100).round()}%'),
                    _buildColorValueCard('HSL', _getHSLString(_currentColor)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorValueCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 2),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 9,
                fontFamily: 'monospace',
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }

  String _getCMYKString(Color color) {
    double r = color.r;
    double g = color.g;
    double b = color.b;
    
    double k = 1 - math.max(r, math.max(g, b));
    double c = k == 1 ? 0 : (1 - r - k) / (1 - k);
    double m = k == 1 ? 0 : (1 - g - k) / (1 - k);
    double y = k == 1 ? 0 : (1 - b - k) / (1 - k);
    
    return '${(c * 100).round()}% ${(m * 100).round()}%\n${(y * 100).round()}% ${(k * 100).round()}%';
  }

  String _getHSLString(Color color) {
    HSLColor hsl = HSLColor.fromColor(color);
    return '${hsl.hue.round()}° ${(hsl.saturation * 100).round()}%\n${(hsl.lightness * 100).round()}%';
  }
}

// Color picker dialog
class ColorPickerDialog extends StatefulWidget {
  final Color initialColor;
  final String title;

  const ColorPickerDialog({
    super.key,
    required this.initialColor,
    this.title = 'Farbwähler',
  });

  @override
  State<ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<ColorPickerDialog> {
  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.initialColor;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.share),
                    tooltip: 'Share',
                  ),
                ],
              ),
            ),
            
            // Color picker
            ColorPickerWidget(
              initialColor: widget.initialColor,
              onColorChanged: (color) {
                setState(() {
                  _selectedColor = color;
                });
              },
              width: 350,
            ),
            
            const SizedBox(height: 16),
            
            // Action buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(_selectedColor),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedColor,
                      foregroundColor: _selectedColor.computeLuminance() > 0.5 
                          ? Colors.black 
                          : Colors.white,
                    ),
                    child: const Text('Select'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Utility functions for color picker
class ColorPickerUtils {
  static String colorToHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
  }

  static Color hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  static Future<Color?> showColorPicker({
    required BuildContext context,
    required Color initialColor,
    String title = 'Color Picker',
  }) async {
    return showDialog<Color>(
      context: context,
      builder: (context) => ColorPickerDialog(
        initialColor: initialColor,
        title: title,
      ),
    );
  }

  static String getColorName(Color color) {
    // Basic color name detection
    final hsl = HSLColor.fromColor(color);
    final hue = hsl.hue;
    final saturation = hsl.saturation;
    final lightness = hsl.lightness;

    if (saturation < 0.1) {
      if (lightness > 0.9) {
        return 'White';
      }
      if (lightness < 0.1) {
        return 'Black';
      }
      if (lightness > 0.7) {
        return 'Light Gray';
      }
      if (lightness < 0.3) {
        return 'Dark Gray';
      }
      return 'Gray';
    }

    String baseName;
    if (hue < 30 || hue >= 330) {
      baseName = 'Red';
    } else if (hue < 60) {
      baseName = 'Orange';
    } else if (hue < 90) {
      baseName = 'Yellow';
    } else if (hue < 150) {
      baseName = 'Green';
    } else if (hue < 210) {
      baseName = 'Blue';
    } else if (hue < 270) {
      baseName = 'Purple';
    } else if (hue < 330) {
      baseName = 'Pink';
    } else {
      baseName = 'Red';
    }

    if (lightness < 0.3) {
      return 'Dark $baseName';
    }
    if (lightness > 0.7) {
      return 'Light $baseName';
    }
    return baseName;
  }
}