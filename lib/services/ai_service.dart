// lib/services/ai_service.dart
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

class AIService {
  static const String _huggingFaceApiKey =
      ''; // Ganti dengan API key kamu (udah ada)
  static const String _huggingFaceEndpoint =
      'https://api-inference.huggingface.co/models/bert-base-uncased';

  static Future<String> predictCategory(String? itemName) async {
    if (itemName == null || itemName.isEmpty) return 'lainnya';

    // Rule-based spesifik untuk UMKM, termasuk merk warung
    final lowerName = itemName.toLowerCase();
    if (lowerName.contains('kopi') || // Minuman
        lowerName.contains('kapal api') ||
        lowerName.contains('abc') ||
        lowerName.contains('torabika') ||
        lowerName.contains('excelso') ||
        lowerName.contains('teh') ||
        lowerName.contains('sosro') ||
        lowerName.contains('poci') ||
        lowerName.contains('tarik') ||
        lowerName.contains('tubruk') ||
        lowerName.contains('jus') ||
        lowerName.contains('soda') ||
        lowerName.contains('bubuk') ||
        lowerName.contains('es') ||
        lowerName.contains('jeruk') ||
        lowerName.contains('fanta') ||
        lowerName.contains('nutrisari')) {
      return 'Minuman';
    } else if (lowerName.contains('roti') || // Makanan
        lowerName.contains('myroti') ||
        lowerName.contains('sari roti') ||
        lowerName.contains('roti o') ||
        lowerName.contains('kue') ||
        lowerName.contains('biskuit') ||
        lowerName.contains('roma') ||
        lowerName.contains('khong guan') ||
        lowerName.contains('danisa') ||
        lowerName.contains('sate') ||
        lowerName.contains('madura') ||
        lowerName.contains('pecel') ||
        lowerName.contains('pinrang') ||
        lowerName.contains('nasi') ||
        lowerName.contains('rawon') ||
        lowerName.contains('surabaya') ||
        lowerName.contains('lontong') ||
        lowerName.contains('kikil') ||
        lowerName.contains('rujak') ||
        lowerName.contains('soto') ||
        lowerName.contains('tahu') ||
        lowerName.contains('telor') ||
        lowerName.contains('rempeyek') ||
        lowerName.contains('kacang')) {
      return 'Makanan';
    } else if (lowerName.contains('beras') || // Sembako
        lowerName.contains('pandan wangi') ||
        lowerName.contains('ir 64') ||
        lowerName.contains('c4') ||
        lowerName.contains('gula') ||
        lowerName.contains('gulaku') ||
        lowerName.contains('pasir') ||
        lowerName.contains('rose brand') ||
        lowerName.contains('minyak') ||
        lowerName.contains('bimoli') ||
        lowerName.contains('sania') ||
        lowerName.contains('tropicana slim') ||
        lowerName.contains('tepung') ||
        lowerName.contains('segitiga biru') ||
        lowerName.contains('cakra') ||
        lowerName.contains('garam') ||
        lowerName.contains('cap kapal') ||
        lowerName.contains('sasa') ||
        lowerName.contains('telur') ||
        lowerName.contains('ayam ras') ||
        lowerName.contains('bebek')) {
      return 'Sembako';
    } else if (lowerName.contains('sabun') || // Kebutuhan Pribadi
        lowerName.contains('lifebuoy') ||
        lowerName.contains('dove') ||
        lowerName.contains('lux') ||
        lowerName.contains('shampoo') ||
        lowerName.contains('clear') ||
        lowerName.contains('sunsilk') ||
        lowerName.contains('pantene') ||
        lowerName.contains('pasta gigi') ||
        lowerName.contains('pepsodent') ||
        lowerName.contains('ciptadent') ||
        lowerName.contains('sikat gigi') ||
        lowerName.contains('oral-b') ||
        lowerName.contains('colgate')) {
      return 'Kebutuhan Pribadi';
    } else if (lowerName.contains('alat tulis') || // Kantor
        lowerName.contains('buku') ||
        lowerName.contains('pensil') ||
        lowerName.contains('pulpen') ||
        lowerName.contains('pilot') ||
        lowerName.contains('faber-castell') ||
        lowerName.contains('joyko') ||
        lowerName.contains('sidu') ||
        lowerName.contains('agenda') ||
        lowerName.contains('muji')) {
      return 'Kantor';
    } else {
      // Fallback ke Hugging Face kalau ga ketemu rule (opsional, kurang akurat buat merk lokal)
      try {
        final response = await http.post(
          Uri.parse(_huggingFaceEndpoint),
          headers: {
            'Authorization': 'Bearer $_huggingFaceApiKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'inputs': itemName,
            'parameters': {
              'candidate_labels': [
                'Sembako',
                'Kebutuhan Pribadi',
                'Kantor',
                'Minuman',
                'Makanan',
                'Lainnya'
              ],
            },
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data is Map && data.containsKey('labels')) {
            final labels = List<String>.from(data['labels']);
            return labels.firstWhere((label) => label != 'Lainnya',
                orElse: () => 'lainnya');
          }
          return 'lainnya';
        } else {
          debugPrint(
              'Hugging Face API Error: ${response.statusCode} - ${response.body}');
          return 'lainnya';
        }
      } catch (e) {
        debugPrint('Error predicting category: $e');
        return 'lainnya';
      }
    }
  }
}