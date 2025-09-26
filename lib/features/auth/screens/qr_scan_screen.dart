import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../providers/auth_provider.dart';
import '../../../shared/widgets/responsive_layout.dart';

class QRScanScreen extends StatefulWidget {
  const QRScanScreen({super.key});

  @override
  State<QRScanScreen> createState() => _QRScanScreenState();
}

class _QRScanScreenState extends State<QRScanScreen> {
  MobileScannerController controller = MobileScannerController();
  bool isScanning = true;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (!isScanning) return;
    
    final barcode = capture.barcodes.first;
    if (barcode.rawValue != null) {
      _handleQRCode(barcode.rawValue!);
    }
  }

  Future<void> _handleQRCode(String qrData) async {
    if (!isScanning) return;
    
    setState(() {
      isScanning = false;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.joinEventWithQR(qrData);

    if (mounted) {
      if (success) {
        context.go('/event/${authProvider.currentEventId}');
      } else {
        _showErrorDialog();
        setState(() {
          isScanning = true;
        });
      }
    }
  }

  void _showErrorDialog() {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        title: Text(
          'Invalid QR Code',
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        content: Text(
          'This QR code is not valid for joining an event. Please try scanning a different code.',
          style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'OK',
              style: TextStyle(color: theme.colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.background,

      body: ResponsiveLayout(
        child: Column(
          children: [
            // Header Section
            Padding(
              padding: const EdgeInsets.fromLTRB(24.0, 40.0, 24.0, 16.0),
              child: Column(
                children: [
                  Text(
                    'Scan QR Code',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onBackground,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Icon(
                    Icons.qr_code_scanner_rounded,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Point your camera at the QR code to join the event',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onBackground.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            // Camera Preview Area
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: theme.colorScheme.primary,
                    width: 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Stack(
                    children: [
                      MobileScanner(
                        controller: controller,
                        onDetect: _onDetect,
                      ),
                      
                      // Scanning overlay
                      Center(
                        child: Container(
                          width: 240,
                          height: 240,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: theme.colorScheme.primary,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Controls Section
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Flash toggle
                      _buildControlButton(
                        context: context,
                        icon: Icons.flash_on_rounded,
                        label: 'Flash',
                        isActive: false,
                        onTap: () => controller.toggleTorch(),
                      ),
                      
                      // Gallery button
                      _buildControlButton(
                        context: context,
                        icon: Icons.photo_library_rounded,
                        label: 'Gallery',
                        isActive: false,
                        onTap: () {
                          // TODO: Implement gallery QR scan
                        },
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isActive ? theme.colorScheme.primary : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.primary.withOpacity(0.3),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? theme.colorScheme.onPrimary : theme.colorScheme.primary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isActive ? theme.colorScheme.onPrimary : theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }



  List<Widget> _buildCornerFrames(ThemeData theme) {
    const double cornerSize = 20.0;
    const double cornerWidth = 3.0;
    
    return [
      // Top-left corner
      Positioned(
        top: -2,
        left: -2,
        child: Container(
          width: cornerSize,
          height: cornerSize,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: theme.colorScheme.primary, width: cornerWidth),
              left: BorderSide(color: theme.colorScheme.primary, width: cornerWidth),
            ),
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(16)),
          ),
        ),
      ),
      // Top-right corner
      Positioned(
        top: -2,
        right: -2,
        child: Container(
          width: cornerSize,
          height: cornerSize,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: theme.colorScheme.primary, width: cornerWidth),
              right: BorderSide(color: theme.colorScheme.primary, width: cornerWidth),
            ),
            borderRadius: const BorderRadius.only(topRight: Radius.circular(16)),
          ),
        ),
      ),
      // Bottom-left corner
      Positioned(
        bottom: -2,
        left: -2,
        child: Container(
          width: cornerSize,
          height: cornerSize,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: theme.colorScheme.primary, width: cornerWidth),
              left: BorderSide(color: theme.colorScheme.primary, width: cornerWidth),
            ),
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16)),
          ),
        ),
      ),
      // Bottom-right corner
      Positioned(
        bottom: -2,
        right: -2,
        child: Container(
          width: cornerSize,
          height: cornerSize,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: theme.colorScheme.primary, width: cornerWidth),
              right: BorderSide(color: theme.colorScheme.primary, width: cornerWidth),
            ),
            borderRadius: const BorderRadius.only(bottomRight: Radius.circular(16)),
          ),
        ),
      ),
    ];
  }

}