import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/spoolman_service.dart';

class FilamentDetail extends StatelessWidget {
  final SpoolmanFilament filament;

  const FilamentDetail({
    super.key,
    required this.filament,
  });

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
    if (filament.colorHexes != null && filament.colorHexes!.isNotEmpty) {
      // Multi-color filament
      return Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: filament.colorHexes!
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
          if (filament.multiColorDirection != null)
            Text(
              filament.multiColorDirection!.toUpperCase(),
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 10,
              ),
            ),
        ],
      );
    } else if (filament.colorHex != null) {
      // Single color filament
      return Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getColorFromHex(filament.colorHex),
              border: Border.all(color: Colors.grey.shade300, width: 2),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            filament.colorHex!.toUpperCase(),
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
        title: Text(filament.displayName),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // Share filament details
              final details = '''
${filament.displayName}
Material: ${filament.material}
Diameter: ${filament.diameter}mm
Weight: ${filament.weight}g
Extruder: ${_formatTemperature(filament.extruderTemp, filament.extruderTempRange)}
Bed: ${_formatTemperature(filament.bedTemp, filament.bedTempRange)}
              '''.trim();
              
              Clipboard.setData(ClipboardData(text: details));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Filament details copied to clipboard'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
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
                    filament.displayName,
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
                      '${filament.material} • ${filament.diameter}mm',
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
                _buildInfoRow('ID', filament.id, onTap: () => _copyToClipboard(context, filament.id)),
                _buildInfoRow('Manufacturer', filament.manufacturer),
                _buildInfoRow('Product Name', filament.name),
                _buildInfoRow('Material', filament.material),
                _buildInfoRow('Diameter', '${filament.diameter}mm'),
              ],
            ),

            // Physical Properties
            _buildInfoCard(
              'Physical Properties',
              [
                _buildInfoRow('Weight', '${filament.weight.toInt()}g', icon: Icons.scale),
                _buildInfoRow('Density', '${filament.density} g/cm³', icon: Icons.science),
                _buildInfoRow('Spool Weight', 
                  filament.spoolWeight != null ? '${filament.spoolWeight!.toInt()}g' : null, 
                  icon: Icons.data_usage),
                _buildInfoRow('Spool Type', filament.spoolType?.toUpperCase(), icon: Icons.album),
              ],
            ),

            // Temperature Settings
            _buildInfoCard(
              'Temperature Settings',
              [
                _buildInfoRow('Extruder Temperature', 
                  _formatTemperature(filament.extruderTemp, filament.extruderTempRange),
                  icon: Icons.thermostat),
                _buildInfoRow('Bed Temperature', 
                  _formatTemperature(filament.bedTemp, filament.bedTempRange),
                  icon: Icons.thermostat),
              ],
            ),

            // Color Information
            _buildInfoCard(
              'Color Information',
              [
                if (filament.colorHex != null)
                  _buildInfoRow('Color Code', filament.colorHex, 
                    icon: Icons.palette,
                    onTap: () => _copyToClipboard(context, filament.colorHex!)),
                if (filament.colorHexes != null && filament.colorHexes!.isNotEmpty) ...[
                  _buildInfoRow('Color Count', '${filament.colorHexes!.length} colors'),
                  ...filament.colorHexes!.asMap().entries.map((entry) =>
                    _buildInfoRow('Color ${entry.key + 1}', entry.value,
                      onTap: () => _copyToClipboard(context, entry.value))),
                ],
                if (filament.multiColorDirection != null)
                  _buildInfoRow('Color Direction', filament.multiColorDirection!.toUpperCase()),
              ],
            ),

            // Special Properties
            _buildInfoCard(
              'Special Properties',
              [
                _buildInfoRow('Finish', filament.finish?.toUpperCase(), icon: Icons.brush),
                _buildInfoRow('Pattern', filament.pattern?.toUpperCase(), icon: Icons.texture),
                _buildInfoRow('Translucent', filament.translucent ? 'Yes' : 'No', 
                  icon: filament.translucent ? Icons.visibility : Icons.visibility_off),
                _buildInfoRow('Glow in Dark', filament.glow ? 'Yes' : 'No', 
                  icon: filament.glow ? Icons.flash_on : Icons.flash_off),
              ],
            ),

            // Special Features Badge Row
            if (filament.translucent || filament.glow || filament.pattern != null || filament.finish != null)
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
                          if (filament.translucent)
                            Chip(
                              avatar: const Icon(Icons.visibility, size: 18),
                              label: const Text('Translucent'),
                              backgroundColor: Colors.blue.shade100,
                            ),
                          if (filament.glow)
                            Chip(
                              avatar: const Icon(Icons.flash_on, size: 18),
                              label: const Text('Glow in Dark'),
                              backgroundColor: Colors.green.shade100,
                            ),
                          if (filament.pattern != null)
                            Chip(
                              avatar: const Icon(Icons.texture, size: 18),
                              label: Text(filament.pattern!.toUpperCase()),
                              backgroundColor: Colors.purple.shade100,
                            ),
                          if (filament.finish != null)
                            Chip(
                              avatar: const Icon(Icons.brush, size: 18),
                              label: Text(filament.finish!.toUpperCase()),
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