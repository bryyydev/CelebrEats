import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class RealTimeMap extends StatefulWidget {
  final ValueChanged<LatLng>? onLocationChanged;

  /// If true, user can tap on the map to set a pin (overrides the marker point).
  final bool allowPin;

  final double zoom;

  const RealTimeMap({
    super.key,
    this.onLocationChanged,
    this.allowPin = true,
    this.zoom = 15.0,
  });

  @override
  State<RealTimeMap> createState() => _RealTimeMapState();
}

class _RealTimeMapState extends State<RealTimeMap> {
  LatLng? _currentLocation;
  LatLng? _pinnedLocation;

  final MapController _mapController = MapController();
  StreamSubscription<Position>? _positionSubscription;

  bool _isLoading = true;
  bool _hasMovedMap = false;

  LatLng? get _markerLocation => _pinnedLocation ?? _currentLocation;

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
          if (!mounted) return;

          final updated = LatLng(position.latitude, position.longitude);

          setState(() {
            _currentLocation = updated;
          });

          // Only auto-move/emit when user hasn't pinned a location yet.
          if (_pinnedLocation == null) {
            _mapController.move(updated, widget.zoom);
            widget.onLocationChanged?.call(updated);
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

  void _handlePin(LatLng point) {
    if (!mounted) return;

    setState(() {
      _pinnedLocation = point;
    });

    _mapController.move(point, widget.zoom);
    widget.onLocationChanged?.call(point);
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
        initialCenter: _markerLocation ?? const LatLng(0, 0),
        initialZoom: widget.zoom,
        onMapReady: () {
          if (_markerLocation != null && !_hasMovedMap) {
            _hasMovedMap = true;
            _mapController.move(_markerLocation!, widget.zoom);
          }
        },

        // Tap-to-pin
        onTap: widget.allowPin
            ? (tapPosition, latLng) => _handlePin(latLng)
            : null,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.celebreats',
        ),
        MarkerLayer(
          markers: [
            if (_markerLocation != null)
              Marker(
                point: _markerLocation!,
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
