import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class RealTimeMap extends StatefulWidget {
  final ValueChanged<LatLng>? onLocationChanged;
  final double zoom;

  const RealTimeMap({super.key, this.onLocationChanged, this.zoom = 15.0});

  @override
  State<RealTimeMap> createState() => _RealTimeMapState();
}

class _RealTimeMapState extends State<RealTimeMap> {
  LatLng? _currentLocation;
  final MapController _mapController = MapController();
  StreamSubscription<Position>? _positionSubscription;
  bool _isLoading = true;
  bool _hasMovedMap = false;

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndGetLocation();
  }

  // Check if GPS is enabled and permissions are granted
  Future<void> _checkPermissionsAndGetLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showError("Location services are disabled. Please enable them.");
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showError("Location permissions are denied.");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showError("Permissions are permanently denied. Check settings.");
      return;
    }

    // Get initial position
    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
      _isLoading = false;
    });
    widget.onLocationChanged?.call(_currentLocation!);

    // Start listening for real-time updates
    _listenToLocation();
  }

  void _listenToLocation() {
    _positionSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 5, // Update map every 5 meters
          ),
        ).listen((Position position) {
          if (mounted) {
            setState(() {
              _currentLocation = LatLng(position.latitude, position.longitude);
            });
            _mapController.move(_currentLocation!, widget.zoom);
            widget.onLocationChanged?.call(_currentLocation!);
          }
        });
  }

  void _showError(String message) {
    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_currentLocation == null) {
      return const Center(
        child: Icon(Icons.location_off, color: Colors.grey, size: 40),
      );
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _currentLocation ?? const LatLng(0, 0),
        initialZoom: widget.zoom,
        onMapReady: () {
          if (_currentLocation != null && !_hasMovedMap) {
            _hasMovedMap = true;
            _mapController.move(_currentLocation!, widget.zoom);
          }
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.celebreats',
        ),
        MarkerLayer(
          markers: [
            if (_currentLocation != null)
              Marker(
                point: _currentLocation!,
                width: 50,
                height: 50,
                child: const Icon(
                  Icons.location_on,
                  color: Colors.red,
                  size: 40,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
