import 'package:flutter/material.dart';
import '../services/bambu_lab_service.dart';

class BambuLabIntegrationWidget extends StatefulWidget {
  const BambuLabIntegrationWidget({super.key});

  @override
  State<BambuLabIntegrationWidget> createState() => _BambuLabIntegrationWidgetState();
}

class _BambuLabIntegrationWidgetState extends State<BambuLabIntegrationWidget> {
  bool _isBambuConnectAvailable = false;
  bool _isChecking = true;
  String? _lastError;

  @override
  void initState() {
    super.initState();
    _checkBambuConnectAvailability();
  }

  Future<void> _checkBambuConnectAvailability() async {
    setState(() => _isChecking = true);
    try {
      final available = await BambuLabService.isBambuConnectAvailable();
      setState(() {
        _isBambuConnectAvailable = available;
        _isChecking = false;
        _lastError = null;
      });
    } catch (e) {
      setState(() {
        _isChecking = false;
        _lastError = e.toString();
      });
    }
  }

  Future<void> _sendSampleFileToBambu() async {
    try {
      setState(() => _lastError = null);
      
      // Generate a sample 3MF file
      final sampleFilePath = await BambuLabService.generateSample3MF();
      
      if (sampleFilePath == null) {
        throw Exception('Failed to generate sample 3MF file');
      }

      // Send to Bambu Connect
      final success = await BambuLabService.sendFileToBambuConnect(
        filePath: sampleFilePath,
        fileName: 'Test Cube from ThreePrint',
      );

      if (success) {
        _showSuccessSnackBar('File sent to Bambu Connect successfully!');
      } else {
        throw Exception('Failed to launch Bambu Connect');
      }
    } catch (e) {
      setState(() => _lastError = e.toString());
      _showErrorSnackBar('Error: $e');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.precision_manufacturing,
                    color: Colors.orange,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bambu Lab Integration',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Send files directly to your Bambu Lab printer',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Status Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isChecking 
                    ? Colors.blue.shade50
                    : _isBambuConnectAvailable 
                        ? Colors.green.shade50
                        : Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _isChecking
                      ? Colors.blue.shade200
                      : _isBambuConnectAvailable
                          ? Colors.green.shade200
                          : Colors.red.shade200,
                ),
              ),
              child: Row(
                children: [
                  if (_isChecking)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Icon(
                      _isBambuConnectAvailable ? Icons.check_circle : Icons.error,
                      color: _isBambuConnectAvailable ? Colors.green : Colors.red,
                      size: 20,
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isChecking
                          ? 'Checking Bambu Connect availability...'
                          : _isBambuConnectAvailable
                              ? 'Bambu Connect is available'
                              : 'Bambu Connect not found',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: _isChecking
                            ? Colors.blue.shade700
                            : _isBambuConnectAvailable
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (!_isBambuConnectAvailable && !_isChecking) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.amber.shade700, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Installation Required',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'To use this feature, please install Bambu Connect from Bambu Lab:\n'
                      '• Download from the official Bambu Lab website\n'
                      '• Or use Developer Mode on your printer for direct LAN access',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _checkBambuConnectAvailability,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Check Again'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isBambuConnectAvailable ? _sendSampleFileToBambu : null,
                    icon: const Icon(Icons.send),
                    label: const Text('Test Print'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),

            // Error Display
            if (_lastError != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.error, color: Colors.red.shade700, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Error',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _lastError!,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Info Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.grey.shade600, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Integration Methods',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Bambu Connect: Easy file transfer via URL scheme\n'
                    '• Developer Mode: Direct LAN access (requires printer setup)\n'
                    '• Local Server: Enterprise solution (requires SDK approval)',
                    style: TextStyle(fontSize: 13),
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