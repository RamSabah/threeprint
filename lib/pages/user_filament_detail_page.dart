import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/filament.dart';
import '../services/filament_service.dart';

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
            const SnackBar(
              content: Text('Filament deleted successfully'),
              backgroundColor: Colors.green,
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
            backgroundColor: filamentColor,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.filament.brand,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      filamentColor,
                      filamentColor.withOpacity(0.7),
                    ],
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.print, size: 80, color: Colors.white38),
                ),
              ),
            ),
            actions: [
              IconButton(
                onPressed: _isDeleting ? null : _deleteFilament,
                icon: _isDeleting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.delete, color: Colors.white),
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
            if (widget.filament.emptySpoolWeight != null)
              _buildInfoRow('Empty Spool Weight', '${widget.filament.emptySpoolWeight!.toInt()}g'),
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
}