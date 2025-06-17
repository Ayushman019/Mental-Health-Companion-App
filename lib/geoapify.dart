// geoapify.dart
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<List<dynamic>> fetchNearbyPsychiatrists(double lat, double lon) async {
  const apiKey = '0b852b20cbc24e0faeb214f808935687';

  final formattedLat = lat.toStringAsFixed(6);
  final formattedLon = lon.toStringAsFixed(6);

  final url = Uri.parse(
    'https://api.geoapify.com/v2/places'
        '?categories=healthcare'
        '&filter=circle:$formattedLon,$formattedLat,5000'
        '&limit=50'
        '&apiKey=$apiKey',
  );

  print('📡 Geoapify URL: $url');

  try {
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final allPlaces = data['features'] ?? [];

      print('✅ Total places received: ${allPlaces.length}');

      // 🔍 Filter by psychiatrist-related keywords
      final filtered = allPlaces.where((place) {
        final name = place['properties']['name']?.toString().toLowerCase() ?? '';
        final address = place['properties']['formatted']?.toString().toLowerCase() ?? '';
        return name.contains('psychiatrist') ||
            address.contains('psychiatrist') ||
            name.contains('mental') ||
            address.contains('mental') ||
            name.contains('counsel') ||
            address.contains('counsel') ||
            name.contains('psycholog') ||
            address.contains('psycholog');
      }).toList();

      print('🧠 Filtered psychiatrist-related places: ${filtered.length}');

      // fallback: if none match psychiatrist keywords, show all
      return filtered.isNotEmpty ? filtered : allPlaces;
    } else {
      print('❌ Error ${response.statusCode}: ${response.body}');
      return [];
    }
  } catch (e) {
    print('❌ Exception during Geoapify API call: $e');
    return [];
  }
}
