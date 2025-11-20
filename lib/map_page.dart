// lib/map_page.dart

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});
  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  GoogleMapController? _controller;
  Position? _pos;
  final Set<Marker> _markers = {};

  // Koordinat fallback (mis. Purwokerto)
  final LatLng _fallbackCenter = const LatLng(-7.4246, 109.2332);

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  // Menginisialisasi lokasi pengguna
  Future<void> _initLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever ||
        perm == LocationPermission.denied)
      return;

    // Ambil lokasi saat ini
    final p = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
    );
    if (mounted) {
      setState(() {
        _pos = p;
      });
    }

    _updateMarker();
    _moveCamera();
  }

  // Update Marker di Peta
  void _updateMarker() {
    if (_pos == null) return;
    _markers
      ..clear()
      ..add(
        Marker(
          markerId: const MarkerId('me'),
          position: LatLng(_pos!.latitude, _pos!.longitude),
          infoWindow: const InfoWindow(title: 'Posisi Saya'),
        ),
      );
  }

  // Pindahkan Kamera Peta
  void _moveCamera() {
    if (_controller == null || _pos == null) return;
    _controller!.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(_pos!.latitude, _pos!.longitude), 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    final center = _pos != null
        ? LatLng(_pos!.latitude, _pos!.longitude)
        : _fallbackCenter;

    return Scaffold(
      appBar: AppBar(title: const Text('Google Maps')),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(target: center, zoom: 14),
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        markers: _markers,
        onMapCreated: (c) {
          _controller = c;
          _moveCamera();
        },
      ),
    );
  }
}
