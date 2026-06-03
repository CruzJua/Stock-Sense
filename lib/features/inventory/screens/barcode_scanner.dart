import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  bool _isProcessing = false;

  Future<void> _handleBarcode(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty || barcodes.first.rawValue == null) return;

    setState(() => _isProcessing = true);
    final barcodeString = barcodes.first.rawValue!;

    try {
      // Fetch from Open Food Facts
      final url = Uri.parse('https://world.openfoodfacts.org/api/v0/product/$barcodeString.json');
      final response = await http.get(url);
      final data = jsonDecode(response.body);

      if (data['status'] == 1) {
        final product = data['product'];
        final itemName = product['product_name'] ?? '';
        final rawCategory = product['categories']?.split(',').first.toLowerCase() ?? 'other';
        
        // Map to our Supabase categories
        String safeCategory = 'other';
        if (rawCategory.contains('dairy')) safeCategory = 'dairy';
        else if (rawCategory.contains('meat')) safeCategory = 'meat';
        else if (rawCategory.contains('bakery')) safeCategory = 'bakery';
        else if (rawCategory.contains('frozen')) safeCategory = 'frozen';
        else if (rawCategory.contains('pantry') || rawCategory.contains('grocery')) safeCategory = 'pantry';
        else if (rawCategory.contains('beverage') || rawCategory.contains('drink')) safeCategory = 'beverage';
        else if (rawCategory.contains('snack')) safeCategory = 'snack';

        if (mounted) {
          // Return the pre-filled data back to the Inventory screen
          Navigator.pop(context, {'name': itemName, 'category': safeCategory});
        }
      } else {
        throw Exception('Product not found in database');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to find product.')),
        );
      }
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Barcode')),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: _handleBarcode,
          ),
          if (_isProcessing)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
