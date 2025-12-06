import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/spoolman_service.dart';
import '../services/filament_service.dart';

class FilamentDetail extends StatefulWidget {
  final SpoolmanFilament filament;

  const FilamentDetail({
    super.key,
    required this.filament,
  });

  @override
  State<FilamentDetail> createState() => _FilamentDetailState();
}

class _FilamentDetailState extends State<FilamentDetail> {
  final FilamentService _filamentService = FilamentService();
  bool _isSaved = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkIfSaved();
  }

  Future<void> _checkIfSaved() async {
    final saved = await _filamentService.isSpoolmanFilamentSaved(widget.filament.id.toString());
    if (mounted) {
      setState(() {
        _isSaved = saved;
      });
    }
  }

  Future<void> _saveToLibrary() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _filamentService.saveSpoolmanFilament(
        spoolmanId: widget.filament.id.toString(),
        displayName: widget.filament.displayName,
        manufacturer: widget.filament.manufacturer,
        material: widget.filament.material,
        diameter: widget.filament.diameter,
        weight: widget.filament.weight,
        colorHex: widget.filament.colorHex,
        colorHexes: widget.filament.colorHexes,
        extruderTemp: widget.filament.extruderTemp,
        bedTemp: widget.filament.bedTemp,
        quantity: 1,
        notes: 'Saved from Spoolman search',
      );

      if (mounted) {
        setState(() {
          _isSaved = true;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Filament saved to your library!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save filament: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Color _getColorFromHex(String? hexColor) {
    if (hexColor == null || hexColor.isEmpty) {
      return Colors.grey;
    }
    try {
      String cleanHex = hexColor.replaceAll('#', '');
      if (cleanHex.length == 6) {
        return Color(int.parse('FF$cleanHex', radix: 16));
      }
      return Colors.grey;
    } catch (e) {
      return Colors.grey;
    }
  }

  Widget _buildColorDisplay() {
    if (widget.filament.colorHexes != null && widget.filament.colorHexes!.isNotEmpty) {
      // Multi-color filament
      return Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: widget.filament.colorHexes!
                    .map((hex) => _getColorFromHex(hex))
                    .toList(),
              ),
              border: Border.all(color: Colors.grey.shade300, width: 2),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Multi-Color',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (widget.filament.multiColorDirection != null)
            Text(
              widget.filament.multiColorDirection!.toUpperCase(),
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 10,
              ),
            ),
        ],
      );
    } else if (widget.filament.colorHex != null) {
      // Single color filament
      return Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getColorFromHex(widget.filament.colorHex),
              border: Border.all(color: Colors.grey.shade300, width: 2),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.filament.colorHex!.toUpperCase(),
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    } else {
      // No color info
      return Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.shade300,
              border: Border.all(color: Colors.grey.shade400, width: 2),
            ),
            child: const Icon(
              Icons.help_outline,
              color: Colors.grey,
              size: 30,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Unknown Color',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 12,
            ),
          ),
        ],
      );
    }
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value, {IconData? icon, VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: Colors.grey.shade600),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value ?? 'N/A',
                style: TextStyle(
                  color: value != null ? Colors.black87 : Colors.grey.shade500,
                  fontWeight: value != null ? FontWeight.w500 : FontWeight.normal,
                ),
                textAlign: TextAlign.right,
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 8),
              Icon(Icons.copy, size: 16, color: Colors.grey.shade500),
            ],
          ],
        ),
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied "$text" to clipboard'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _formatTemperature(int? temp, List<int>? range) {
    if (range != null && range.length == 2) {
      return '${range[0]} - ${range[1]}°C';
    } else if (temp != null) {
      return '${temp}°C';
    }
    return 'N/A';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.filament.displayName),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          _isLoading
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                )
              : IconButton(
                  icon: Icon(
                    _isSaved ? Icons.bookmark : Icons.bookmark_border,
                    color: _isSaved ? Colors.amber : null,
                  ),
                  onPressed: _isSaved ? null : _saveToLibrary,
                  tooltip: _isSaved ? 'Already in library' : 'Save to library',
                ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with color and basic info
            Center(
              child: Column(
                children: [
                  _buildColorDisplay(),
                  const SizedBox(height: 16),
                  Text(
                    widget.filament.displayName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${widget.filament.material} • ${widget.filament.diameter}mm',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Basic Information
            _buildInfoCard(
              'Basic Information',
              [
                _buildInfoRow('ID', widget.filament.id, onTap: () => _copyToClipboard(context, widget.filament.id)),
                _buildInfoRow('Manufacturer', widget.filament.manufacturer),
                _buildInfoRow('Product Name', widget.filament.name),
                _buildInfoRow('Material', widget.filament.material),
                _buildInfoRow('Diameter', '${widget.filament.diameter}mm'),
              ],
            ),

            // Physical Properties
            _buildInfoCard(
              'Physical Properties',
              [
                _buildInfoRow('Weight', '${widget.filament.weight.toInt()}g', icon: Icons.scale),
                _buildInfoRow('Density', '${widget.filament.density} g/cm³', icon: Icons.science),
                _buildInfoRow('Spool Weight', 
                  widget.filament.spoolWeight != null ? '${widget.filament.spoolWeight!.toInt()}g' : null, 
                  icon: Icons.data_usage),
                _buildInfoRow('Spool Type', widget.filament.spoolType?.toUpperCase(), icon: Icons.album),
              ],
            ),

            // Temperature Settings
            _buildInfoCard(
              'Temperature Settings',
              [
                _buildInfoRow('Extruder Temperature', 
                  _formatTemperature(widget.filament.extruderTemp, widget.filament.extruderTempRange),
                  icon: Icons.thermostat),
                _buildInfoRow('Bed Temperature', 
                  _formatTemperature(widget.filament.bedTemp, widget.filament.bedTempRange),
                  icon: Icons.thermostat),
              ],
            ),

            // Color Information
            _buildInfoCard(
              'Color Information',
              [
                if (widget.filament.colorHex != null)
                  _buildInfoRow('Color Code', widget.filament.colorHex, 
                    icon: Icons.palette,
                    onTap: () => _copyToClipboard(context, widget.filament.colorHex!)),
                if (widget.filament.colorHexes != null && widget.filament.colorHexes!.isNotEmpty) ...[
                  _buildInfoRow('Color Count', '${widget.filament.colorHexes!.length} colors'),
                  ...widget.filament.colorHexes!.asMap().entries.map((entry) =>
                    _buildInfoRow('Color ${entry.key + 1}', entry.value,
                      onTap: () => _copyToClipboard(context, entry.value))),
                ],
                if (widget.filament.multiColorDirection != null)
                  _buildInfoRow('Color Direction', widget.filament.multiColorDirection!.toUpperCase()),
              ],
            ),

            // Special Properties
            _buildInfoCard(
              'Special Properties',
              [
                _buildInfoRow('Finish', widget.filament.finish?.toUpperCase(), icon: Icons.brush),
                _buildInfoRow('Pattern', widget.filament.pattern?.toUpperCase(), icon: Icons.texture),
                _buildInfoRow('Translucent', widget.filament.translucent ? 'Yes' : 'No', 
                  icon: widget.filament.translucent ? Icons.visibility : Icons.visibility_off),
                _buildInfoRow('Glow in Dark', widget.filament.glow ? 'Yes' : 'No', 
                  icon: widget.filament.glow ? Icons.flash_on : Icons.flash_off),
              ],
            ),

            // Special Features Badge Row
            if (widget.filament.translucent || widget.filament.glow || widget.filament.pattern != null || widget.filament.finish != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Special Features',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (widget.filament.translucent)
                            Chip(
                              avatar: const Icon(Icons.visibility, size: 18),
                              label: const Text('Translucent'),
                              backgroundColor: Colors.blue.shade100,
                            ),
                          if (widget.filament.glow)
                            Chip(
                              avatar: const Icon(Icons.flash_on, size: 18),
                              label: const Text('Glow in Dark'),
                              backgroundColor: Colors.green.shade100,
                            ),
                          if (widget.filament.pattern != null)
                            Chip(
                              avatar: const Icon(Icons.texture, size: 18),
                              label: Text(widget.filament.pattern!.toUpperCase()),
                              backgroundColor: Colors.purple.shade100,
                            ),
                          if (widget.filament.finish != null)
                            Chip(
                              avatar: const Icon(Icons.texture, size: 18),
                              label: Text(widget.filament.finish!.toUpperCase()),
                              backgroundColor: Colors.orange.shade100,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}