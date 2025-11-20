import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as gc;

// Import halaman peta (akan dibuat di langkah berikutnya)
import 'map_page.dart';
import 'osm_map_page.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Event Kampus Locator',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Position? _pos;
  String? _address;
  StreamSubscription<Position>? _sub;
  bool _tracking = false;
  String _status = 'Mulai pengecekan...';
  // State untuk menyimpan akurasi saat ini
  LocationAccuracy _currentAccuracy = LocationAccuracy.high;

  // Daftar Event Kampus dan Koordinat
  final events = [
    {'title': 'Seminar AI', 'lat': -7.4246, 'lng': 109.2332},
    {'title': 'Job Fair', 'lat': -7.4261, 'lng': 109.2315},
    {'title': 'Expo UKM', 'lat': -7.4229, 'lng': 109.2350},
  ];

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  // Helper: Memastikan layanan lokasi aktif dan izin diberikan
  Future<bool> _ensureServiceAndPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(
        () => _status =
            'Location service OFF. Buka pengaturan untuk mengaktifkan.',
      );
      await Geolocator.openLocationSettings();
      return false;
    }

    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }

    if (perm == LocationPermission.deniedForever ||
        perm == LocationPermission.denied) {
      setState(() => _status = 'Izin lokasi ditolak. Aktifkan via Settings.');
      return false;
    }
    return true;
  }

  // Fungsi BARU: Mengubah akurasi
  void _toggleAccuracy() {
    // Hentikan tracking jika sedang aktif, karena stream harus dimulai ulang dengan setting baru
    if (_tracking) {
      _sub?.cancel();
    }

    setState(() {
      _currentAccuracy = _currentAccuracy == LocationAccuracy.high
          ? LocationAccuracy.low
          : LocationAccuracy.high;

      final accuracyName = _currentAccuracy
          .toString()
          .split('.')
          .last
          .toUpperCase();
      _status = 'Akurasi diubah ke $accuracyName. (Perlu Start Tracking ulang)';
      _tracking = false;
    });
  }

  // Lokasi satu kali (Get Current)
  Future<void> _getCurrent() async {
    if (!await _ensureServiceAndPermission()) return;
    try {
      final p = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
      setState(() {
        _pos = p;
        _status = 'Lokasi diambil sekali.';
      });
      await _reverseGeocode(p);
    } catch (e) {
      setState(() => _status = 'Gagal mengambil lokasi: $e');
    }
  }

  // Reverse Geocoding (Koordinat -> Alamat)
  Future<void> _reverseGeocode(Position p) async {
    try {
      final placemarks = await gc.placemarkFromCoordinates(
        p.latitude,
        p.longitude,
      );
      if (placemarks.isNotEmpty) {
        final m = placemarks.first;
        setState(() {
          _address = '${m.street}, ${m.locality}, ${m.administrativeArea}';
        });
      }
    } catch (_) {
      // Mengabaikan error geocoding jika ada masalah koneksi
    }
  }

  // Pelacakan kontinu (Start/Stop Tracking)
  Future<void> _toggleTracking() async {
    if (_tracking) {
      await _sub?.cancel();
      setState(() {
        _tracking = false;
        _status = 'Tracking dihentikan.';
      });
      return;
    }
    if (!await _ensureServiceAndPermission()) return;
    final settings = LocationSettings(
      accuracy: _currentAccuracy, // MENGGUNAKAN STATE BARU
      distanceFilter: 10,
    );

    _sub = Geolocator.getPositionStream(locationSettings: settings).listen(
      (p) {
        setState(() {
          _pos = p;
          _tracking = true;
          _status = 'Tracking aktif.';
        });
        _reverseGeocode(p);
      },
      onError: (e) {
        setState(() => _status = 'Error stream: $e');
      },
    );
  }

  // Menghitung Jarak ke Event
  double _distanceM(Position me, Map e) => Geolocator.distanceBetween(
    me.latitude,
    me.longitude,
    e['lat'] as double,
    e['lng'] as double,
  );

  Widget _buildEventList(Position me) {
    final items = events.map((e) {
      final d = _distanceM(me, e);
      return ListTile(
        leading: const Icon(Icons.event),
        title: Text(e['title'] as String),
        subtitle: Text('${d.toStringAsFixed(0)} m dari lokasi Anda'),
      );
    }).toList();
    return ListView(children: items);
  }

  @override
  Widget build(BuildContext context) {
    // Variabel Baru Accuracy
    final accuracyLabel = _currentAccuracy == LocationAccuracy.high
        ? 'High'
        : 'Low';
    return Scaffold(
      appBar: AppBar(title: const Text('Event Kampus Locator')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: $_status'),
            const SizedBox(height: 8),

            // Tampilan Data Lokasi
            if (_pos != null) ...[
              Text('Lat: ${_pos!.latitude.toStringAsFixed(6)}'),
              Text('Lng: ${_pos!.longitude.toStringAsFixed(6)}'),
              Text('Accuracy: ${_pos!.accuracy.toStringAsFixed(1)} m'),
              // Kecepatan diubah dari m/s ke km/h
              Text('Speed: ${(_pos!.speed * 3.6).toStringAsFixed(1)} km/h'),
              Text('Heading: ${_pos!.heading.toStringAsFixed(0)}°'),
              Text(
                'Time: ${_pos!.timestamp!.toLocal().toString().split('.')[0]}',
              ),
              if (_address != null) Text('Alamat: $_address'),
            ] else
              const Text('Belum ada data lokasi.'),

            const Divider(),
            const Text(
              'Event Terdekat:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            // Daftar Event (Hanya muncul jika lokasi tersedia)
            Expanded(
              child: _pos != null
                  ? _buildEventList(_pos!)
                  : const Center(
                      child: Text('Ambil lokasi dahulu untuk melihat event.'),
                    ),
            ),
            const Divider(),

            // Tombol Aksi dan Navigasi
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton.icon(
                  onPressed: _getCurrent,
                  icon: const Icon(Icons.my_location),
                  label: const Text('Get Current'),
                ),
                FilledButton.icon(
                  onPressed: _toggleTracking,
                  icon: Icon(_tracking ? Icons.stop : Icons.play_arrow),
                  label: Text(_tracking ? 'Stop Tracking' : 'Start Tracking'),
                ),
                // Tombol BARU: Toggle Akurasi
                OutlinedButton.icon(
                  onPressed: _toggleAccuracy,
                  icon: Icon(
                    accuracyLabel == 'High'
                        ? Icons.battery_alert
                        : Icons.battery_saver,
                  ),
                  label: Text('Akurasi: $accuracyLabel'),
                ),
                // Tombol Google Maps (Akan menyebabkan runtime error jika API Key salah/kosong)
                OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MapPage()),
                  ),
                  icon: const Icon(Icons.map),
                  label: const Text('Google Maps'),
                ),
                // Tombol OpenStreetMap (Aman tanpa API Key)
                OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const OsmMapPage()),
                  ),
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('OSM'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
