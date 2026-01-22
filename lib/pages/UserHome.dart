import 'package:flutter/material.dart';
import '../models/filament.dart';
import '../services/filament_service.dart';
import 'AddFilament.dart';

class UserFilamentDetailPage extends StatefulWidget {
  final Filament filament;

  const UserFilamentDetailPage({
    super.key,
    required this.filament,
  });

  @override
  State<UserFilamentDetailPage> createState() => _UserFilamentDetailPageState();
}

class _UserFilamentDetailPageState extends State<UserFilamentDetailPage> {
  final FilamentService _filamentService = FilamentService();
  bool _isDeleting = false;

  String _getBrandLogoPath(String brandName) {
    // For brands with hyphens (like "3D-Fuel"), use exact name with .jpg extension
    if (brandName.contains('-')) {
      return 'lib/assets/logo/brand/$brandName.jpg';
    }
    
    // For other brands, use first letter capitalized + rest lowercase + "logo"
    return 'lib/assets/logo/brand/${brandName[0]}${brandName.substring(1).toLowerCase()}logo.jpg';
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

  Future<void> _editFilament() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => AddFilamentPage(filamentToEdit: widget.filament),
      ),
    );

    // If the filament was updated, go back to refresh the parent page
    if (result == true && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _deleteFilament() async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Filament'),
        content: Text('Are you sure you want to delete ${widget.filament.brand} ${widget.filament.type}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      setState(() {
        _isDeleting = true;
      });

      try {
        await _filamentService.deleteFilament(widget.filament.id);
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Filament deleted successfully'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting filament: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isDeleting = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filamentColor = _getColorFromHex(widget.filament.color);
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
              title: Text(
                widget.filament.brand,
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              background: Container(
                color: Colors.white,
                child: Center(
                  child: Image.asset(
                    _getBrandLogoPath(widget.filament.brand),
                    fit: BoxFit.contain,
                    height: 150,
                    errorBuilder: (context, error, stackTrace) {
                      print('Error loading logo for ${widget.filament.brand}: $error');
                      print('Attempted path: ${_getBrandLogoPath(widget.filament.brand)}');
                      return Icon(Icons.print, size: 100, color: Colors.grey[300]);
                    },
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                onPressed: _editFilament,
                icon: const Icon(Icons.edit, color: Colors.black87),
                tooltip: 'Edit Filament',
              ),
              IconButton(
                onPressed: _isDeleting ? null : _deleteFilament,
                icon: _isDeleting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.black87),
                        ),
                      )
                    : const Icon(Icons.delete, color: Colors.black87),
                tooltip: 'Delete Filament',
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildInfoSection(),
                const SizedBox(height: 24),
                _buildSpecsSection(),
                const SizedBox(height: 24),
                _buildPhysicalPropertiesSection(),
                const SizedBox(height: 24),
                _buildTemperatureSection(),
                const SizedBox(height: 24),
                _buildColorInfoSection(),
                const SizedBox(height: 24),
                _buildSpecialPropertiesSection(),
                if (widget.filament.cost != null || 
                    widget.filament.storageLocation != null) ...[
                  const SizedBox(height: 24),
                  _buildAdditionalInfoSection(),
                ],
                if (widget.filament.notes != null && widget.filament.notes!.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _buildNotesSection(),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Basic Information',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Type', widget.filament.type),
            _buildInfoRow('Brand', widget.filament.brand),
            _buildInfoRow('Product Name', widget.filament.productName ?? 'N/A'),
            _buildInfoRow('Count', '${widget.filament.count} units'),
            Row(
              children: [
                Text(
                  'Color: ',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: _getColorFromHex(widget.filament.color),
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                Text(widget.filament.color),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Specifications',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Diameter', '${widget.filament.diameter}mm'),
            _buildInfoRow('Weight', '${widget.filament.weight.toInt()}g'),
            _buildInfoRow('Quantity', '${widget.filament.quantity} spool(s)'),
          ],
        ),
      ),
    );
  }

  Widget _buildPhysicalPropertiesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.science, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Physical Properties',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRowWithIcon(Icons.scale, 'Weight', '${widget.filament.weight.toInt()}g'),
            if (widget.filament.density != null)
              _buildInfoRowWithIcon(Icons.trending_up, 'Density', '${widget.filament.density!.toStringAsFixed(2)} g/cm³'),
            if (widget.filament.emptySpoolWeight != null)
              _buildInfoRowWithIcon(Icons.refresh, 'Spool Weight', '${widget.filament.emptySpoolWeight!.toInt()}g'),
            if (widget.filament.spoolType != null && widget.filament.spoolType!.isNotEmpty)
              _buildInfoRowWithIcon(Icons.album, 'Spool Type', widget.filament.spoolType!)
            else
              _buildInfoRowWithIcon(Icons.album, 'Spool Type', 'N/A'),
          ],
        ),
      ),
    );
  }

  Widget _buildTemperatureSection() {
    if (widget.filament.extruderTemp == null && widget.filament.bedTemp == null) {
      return const SizedBox.shrink();
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.thermostat, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Temperature Settings',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (widget.filament.extruderTempRange != null && widget.filament.extruderTempRange!.length == 2)
              _buildInfoRowWithIcon(Icons.whatshot, 'Extruder Temperature', '${widget.filament.extruderTempRange![0]}-${widget.filament.extruderTempRange![1]}°C')
            else if (widget.filament.extruderTemp != null)
              _buildInfoRowWithIcon(Icons.whatshot, 'Extruder Temperature', '${widget.filament.extruderTemp}°C'),
            if (widget.filament.bedTempRange != null && widget.filament.bedTempRange!.length == 2)
              _buildInfoRowWithIcon(Icons.layers, 'Bed Temperature', '${widget.filament.bedTempRange![0]}-${widget.filament.bedTempRange![1]}°C')
            else if (widget.filament.bedTemp != null)
              _buildInfoRowWithIcon(Icons.layers, 'Bed Temperature', '${widget.filament.bedTemp}°C'),
          ],
        ),
      ),
    );
  }

  Widget _buildColorInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.palette, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Color Information',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildColorCodeRow(),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecialPropertiesSection() {
    // Check if any special properties exist
    bool hasSpecialProps = (widget.filament.finish != null && widget.filament.finish!.isNotEmpty) ||
                           (widget.filament.pattern != null && widget.filament.pattern!.isNotEmpty) ||
                           widget.filament.isTranslucent != null ||
                           widget.filament.isGlowInDark != null;
    
    if (!hasSpecialProps) {
      return const SizedBox.shrink();
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Special Properties',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (widget.filament.finish != null && widget.filament.finish!.isNotEmpty)
              _buildInfoRowWithIcon(Icons.brush, 'Finish', widget.filament.finish!)
            else
              _buildInfoRowWithIcon(Icons.brush, 'Finish', 'N/A'),
            if (widget.filament.pattern != null && widget.filament.pattern!.isNotEmpty)
              _buildInfoRowWithIcon(Icons.pattern, 'Pattern', widget.filament.pattern!)
            else
              _buildInfoRowWithIcon(Icons.pattern, 'Pattern', 'N/A'),
            if (widget.filament.isTranslucent != null)
              _buildInfoRowWithIcon(Icons.visibility, 'Translucent', widget.filament.isTranslucent! ? 'Yes' : 'No')
            else
              _buildInfoRowWithIcon(Icons.visibility, 'Translucent', 'No'),
            if (widget.filament.isGlowInDark != null)
              _buildInfoRowWithIcon(Icons.nightlight_round, 'Glow in Dark', widget.filament.isGlowInDark! ? 'Yes' : 'No')
            else
              _buildInfoRowWithIcon(Icons.nightlight_round, 'Glow in Dark', 'No'),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Additional Information',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            if (widget.filament.cost != null)
              _buildInfoRow('Cost', '\$${widget.filament.cost!.toStringAsFixed(2)}'),
            if (widget.filament.storageLocation != null)
              _buildInfoRow('Storage Location', widget.filament.storageLocation!),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notes',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Text(
              widget.filament.notes!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRowWithIcon(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorCodeRow() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Icon(Icons.palette, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          SizedBox(
            width: 140,
            child: Text(
              'Color Code',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  widget.filament.color,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(width: 8),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: _getColorFromHex(widget.filament.color),
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}