import 'dart:convert';
import 'package:http/http.dart' as http;

class GoogleTranslateService {
  static final Map<String, String> _cache = {};

  static Future<String> translate(String text, String targetLang) async {
    if (text.trim().isEmpty) return text;
    
    // Check if numeric or only symbols
    if (RegExp(r'^[0-9\s\-\+\(\)\/\\,\.:]+$').hasMatch(text)) {
      return text;
    }

    final cacheKey = '${targetLang}_$text';
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    try {
      final url = Uri.parse(
        'https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl=$targetLang&dt=t&q=${Uri.encodeComponent(text)}'
      );
      final response = await http.get(url).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded != null && decoded is List && decoded.isNotEmpty) {
          final firstList = decoded[0];
          if (firstList is List && firstList.isNotEmpty) {
            final buffer = StringBuffer();
            for (var part in firstList) {
              if (part is List && part.isNotEmpty) {
                buffer.write(part[0]);
              }
            }
            final result = buffer.toString();
            _cache[cacheKey] = result;
            return result;
          }
        }
      }
    } catch (_) {}
    return text; // Fallback
  }
}
