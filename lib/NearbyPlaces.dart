import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class NearbyPlacesScreen extends StatefulWidget {
  final double lat;
  final double lon;

  NearbyPlacesScreen({required this.lat, required this.lon});

  @override
  _NearbyPlacesScreenState createState() => _NearbyPlacesScreenState();
}

class _NearbyPlacesScreenState extends State<NearbyPlacesScreen> {
  List<Map<String, String>> _places = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchPlaces();
  }

  Future<void> _fetchPlaces() async {
    final apiKey = '0b852b20cbc24e0faeb214f808935687'; // Replace with your key
    final formattedLat = widget.lat.toStringAsFixed(6);
    final formattedLon = widget.lon.toStringAsFixed(6);

    final url = Uri.parse(
      'https://api.geoapify.com/v2/places'
          '?categories=healthcare'
          '&filter=circle:$formattedLon,$formattedLat,5000'
          '&limit=50'
          '&apiKey=$apiKey',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final features = data['features'] as List;

        final filtered = features.where((place) {
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

        final selectedList = filtered.isNotEmpty ? filtered : features;

        setState(() {
          _places = selectedList.map<Map<String, String>>((place) {
            final props = place['properties'] as Map<String, dynamic>;
            final coordinates = place['geometry']['coordinates']; // [lon, lat]

            return {
              'name': (props['name'] ?? 'Unnamed Facility').toString(),
              'address': (props['formatted'] ?? 'Address not available').toString(),
              'phone': (props['phone'] ?? 'Phone not available').toString(),
              'lat': coordinates[1].toString(), // lat
              'lon': coordinates[0].toString(), // lon
            };
          }).toList();
          _loading = false;
        });
      } else {
        print('❌ Failed to load places: ${response.body}');
        setState(() => _loading = false);
      }
    } catch (e) {
      print('❌ Exception: $e');
      setState(() => _loading = false);
    }
  }

  void _launchDialer(String phone) async {
    if (phone == 'Phone not available') return;
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      print('❌ Could not launch dialer.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // Allows image to show behind AppBar
      appBar: AppBar(
        title: Text('Nearby Psychiatrists'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/xy.jpeg', // Replace with your actual asset path
              fit: BoxFit.cover,
            ),
          ),
          // Foreground content
          _loading
              ? Center(child: CircularProgressIndicator())
              : _places.isEmpty
              ? Center(child: Text('No nearby psychiatrists found.'))
              : ListView.builder(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + kToolbarHeight + 16), // leave space under AppBar
            itemCount: _places.length,
            itemBuilder: (context, index) {
              final place = _places[index];
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                elevation: 5,
                color: Colors.white.withOpacity(0.85),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place['name'] ?? '',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        place['address'] ?? '',
                        style: TextStyle(color: Colors.black87),
                      ),
                      SizedBox(height: 6),
                      GestureDetector(
                        onTap: () => _launchDialer(place['phone'] ?? ''),
                        child: Text(
                          place['phone'] ?? '',
                          style: TextStyle(
                            color: Colors.black,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          final lat = place['lat'];
                          final lon = place['lon'];
                          final mapsUrl =
                              'https://www.google.com/maps/search/?api=1&query=$lat,$lon';
                          launchUrl(Uri.parse(mapsUrl));
                        },
                        child: Text('Get Directions'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
