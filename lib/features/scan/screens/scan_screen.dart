import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

import '../services/analyze_image_service.dart';
import 'ai_results_screen.dart';

/// The Scan tab — lets the user capture or pick an image and sends it to the
/// AI orchestration Edge Function.
///
/// Supports three scanning modes:
///   • **Fridge** — Google Vision label / object detection
///   • **Pantry** — Google Vision label / object detection
///   • **Receipt** — GPT-4o structured JSON extraction
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _picker = ImagePicker();
  final _service = AnalyzeImageService();

  String _mode = 'fridge'; // fridge | pantry | receipt
  bool _isLoading = false;

  // ── Image acquisition ───────────────────────────────────────────────────

  Future<void> _pickImage(ImageSource source) async {
    final xFile = await _picker.pickImage(
      source: source,
      imageQuality: 90,
      maxWidth: 1920,
    );
    if (xFile == null) return;

    setState(() => _isLoading = true);
    try {
      final Uint8List? compressed = await _compress(xFile);
      if (compressed == null) throw Exception('Failed to compress image');

      final items = await _service.analyzeImage(compressed, _mode);

      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AiResultsScreen(
            initialItems: items,
            mode: _mode,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<Uint8List?> _compress(XFile xFile) async {
    final bytes = await xFile.readAsBytes();
    
    return await FlutterImageCompress.compressWithList(
      bytes,
      minWidth: 1024,
      minHeight: 1024,
      quality: 75,
      format: CompressFormat.jpeg,
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        centerTitle: false,
        title: Text('Scan', style: AppTextStyles.headlineMedium),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                _ModeSelector(
                  selected: _mode,
                  onChanged: (m) => setState(() => _mode = m),
                ),
                const SizedBox(height: 32),
                _CameraPreviewPlaceholder(mode: _mode),
                const SizedBox(height: 32),
                _ActionButtons(
                  isLoading: _isLoading,
                  onCamera: kIsWeb
                      ? null
                      : () => _pickImage(ImageSource.camera),
                  onGallery: () => _pickImage(ImageSource.gallery),
                ),
                const SizedBox(height: 16),
                if (kIsWeb)
                  Center(
                    child: Text(
                      'Live camera is not available in web — use Gallery to pick a photo.',
                      style: AppTextStyles.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),

          // Full-screen loading overlay
          if (_isLoading)
            Container(
              color: AppColors.backgroundDark.withValues(alpha: 0.85),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: AppColors.green),
                    const SizedBox(height: 20),
                    Text(
                      'Analysing image…',
                      style: AppTextStyles.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Our AI is identifying your items.',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mode selector chips
// ---------------------------------------------------------------------------

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({required this.selected, required this.onChanged});

  final String selected;
  final ValueChanged<String> onChanged;

  static const _modes = [
    ('fridge', Icons.kitchen_rounded, 'Fridge'),
    ('pantry', Icons.shelves, 'Pantry'),
    ('receipt', Icons.receipt_long_rounded, 'Receipt'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('SCAN MODE', style: AppTextStyles.overlineMuted),
        const SizedBox(height: 10),
        Row(
          children: _modes.map((m) {
            final (value, icon, label) = m;
            final isSelected = selected == value;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => onChanged(value),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.green.withValues(alpha: 0.15)
                          : AppColors.surfaceDark,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.green
                            : AppColors.border,
                        width: isSelected ? 1.5 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icon,
                          color: isSelected
                              ? AppColors.green
                              : AppColors.textSecondary,
                          size: 22,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          label,
                          style: isSelected
                              ? AppTextStyles.titleSmall
                                  .copyWith(color: AppColors.green)
                              : AppTextStyles.titleSmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Camera preview placeholder
// ---------------------------------------------------------------------------

class _CameraPreviewPlaceholder extends StatelessWidget {
  const _CameraPreviewPlaceholder({required this.mode});

  final String mode;

  IconData get _icon {
    return switch (mode) {
      'receipt' => Icons.receipt_long_rounded,
      'pantry' => Icons.shelves,
      _ => Icons.kitchen_rounded,
    };
  }

  String get _hint {
    return switch (mode) {
      'receipt' => 'Point at a grocery receipt',
      'pantry' => 'Point at your pantry shelves',
      _ => 'Point at your fridge contents',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 260,
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        border: Border.all(
          color: AppColors.green.withValues(alpha: 0.3),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.green.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(_icon, color: AppColors.green, size: 36),
          ),
          const SizedBox(height: 16),
          Text(_hint, style: AppTextStyles.bodyLarge),
          const SizedBox(height: 8),
          Text(
            'Use the buttons below to capture or pick a photo',
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Camera / Gallery action buttons
// ---------------------------------------------------------------------------

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.isLoading,
    required this.onCamera,
    required this.onGallery,
  });

  final bool isLoading;
  final VoidCallback? onCamera;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (onCamera != null) ...[
          Expanded(
            child: _ScanButton(
              id: 'btn_camera',
              icon: Icons.camera_alt_rounded,
              label: 'Take Photo',
              primary: true,
              enabled: !isLoading,
              onTap: onCamera!,
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: _ScanButton(
            id: 'btn_gallery',
            icon: Icons.photo_library_rounded,
            label: 'Gallery',
            primary: onCamera == null,
            enabled: !isLoading,
            onTap: onGallery,
          ),
        ),
      ],
    );
  }
}

class _ScanButton extends StatelessWidget {
  const _ScanButton({
    required this.id,
    required this.icon,
    required this.label,
    required this.primary,
    required this.enabled,
    required this.onTap,
  });

  final String id;
  final IconData icon;
  final String label;
  final bool primary;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: primary
              ? (enabled ? AppColors.green : AppColors.green.withValues(alpha: 0.4))
              : AppColors.surfaceDark,
          border: Border.all(
            color: primary ? AppColors.green : AppColors.border,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: primary ? AppColors.black : AppColors.textSecondary,
              size: 26,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: primary
                  ? AppTextStyles.titleSmall
                      .copyWith(color: AppColors.black)
                  : AppTextStyles.titleSmall,
            ),
          ],
        ),
      ),
    );
  }
}
