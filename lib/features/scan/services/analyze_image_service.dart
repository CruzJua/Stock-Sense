import 'dart:convert';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/confirmed_item.dart';

/// Calls the `analyze-image` Supabase Edge Function and returns the list
/// of items detected by AI.
///
/// [bytes]  — compressed JPEG bytes from the camera or gallery picker.
/// [mode]   — one of `"fridge"`, `"pantry"`, or `"receipt"`.
class AnalyzeImageService {
  final _supabase = Supabase.instance.client;

  Future<List<ConfirmedItem>> analyzeImage(
    Uint8List bytes,
    String mode,
  ) async {
    final imageBase64 = base64Encode(bytes);

    final response = await _supabase.functions.invoke(
      'analyze-image',
      body: {
        'imageBase64': imageBase64,
        'mode': mode,
      },
    );

    if (response.status != 200) {
      final errorData = response.data;
      throw Exception(
        'analyze-image failed (${response.status}): '
        '${errorData is Map ? errorData['error'] : errorData}',
      );
    }

    final data = response.data as Map<String, dynamic>;
    final rawItems = data['items'] as List<dynamic>? ?? [];

    return rawItems
        .map((e) => ConfirmedItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
