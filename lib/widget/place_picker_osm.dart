import 'dart:async';
import 'dart:convert';
import 'package:customer/themes/app_colors.dart';
import 'package:customer/utils/DarkThemeProvider.dart';
import 'package:customer/utils/utils.dart';
import 'package:customer/widget/osm_map_search_place.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart' as ll;
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

class LocationResult {
  final String displayName;
  final double latitude;
  final double longitude;
  final Map<String, dynamic>? address;

  LocationResult({
    required this.displayName,
    required this.latitude,
    required this.longitude,
    this.address,
  });
}

class LocationPicker extends StatefulWidget {
  final bool isSource;
  const LocationPicker({super.key, this.isSource = true});

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  ll.LatLng? selectedLocation;
  late fm.MapController mapController;
  LocationResult? locationResult;
  TextEditingController textController = TextEditingController();
  List<fm.Marker> _markers = [];
  bool _isLoading = false;
  Timer? _regionChangeDebounce;

  @override
  void initState() {
    super.initState();
    mapController = fm.MapController();
    _setUserLocation();
  }

  Future<void> addMarker(ll.LatLng position) async {
    setState(() {
      _markers.clear();
      _markers.add(
        fm.Marker(
          point: position,
          child: const Icon(
            Icons.location_on,
            color: Colors.red,
            size: 40,
          ),
        ),
      );
      selectedLocation = position;
    });

    // Fetch location data with a timeout
    try {
      final response = await http.get(
        Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}'),
      ).timeout(const Duration(seconds: 5), onTimeout: () {
        throw Exception('Location search timed out');
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        locationResult = LocationResult(
          displayName: data['display_name'] ?? "Selected location",
          latitude: position.latitude,
          longitude: position.longitude,
          address: data['address'],
        );
      } else {
        throw Exception('Failed to get location name');
      }
    } catch (e) {
      print("Error fetching location: $e");
      // Set a default placeholder if reverse geocoding fails
      locationResult = LocationResult(
        displayName: "Selected location",
        latitude: position.latitude,
        longitude: position.longitude,
      );
    }

    setState(() {});
  }

  Future<void> _setUserLocation() async {
    try {
      setState(() {
        _isLoading = true;
      });
      final locationData = await Utils.getCurrentLocation();
      selectedLocation = ll.LatLng(
        locationData.latitude,
        locationData.longitude,
      );
      await addMarker(selectedLocation!);
      mapController.move(selectedLocation!, 16.0);
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print("Error getting location: $e");
    }
  }

  @override
  void dispose() {
    _regionChangeDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Picker'),
      ),
      body: Stack(
        children: [
          fm.FlutterMap(
            mapController: mapController,
            options: fm.MapOptions(
              initialCenter: selectedLocation ?? ll.LatLng(45.521563, -122.677433),
              initialZoom: 16.0,
              onTap: (tapPosition, point) async {
                setState(() {
                  _isLoading = true;
                });
                await addMarker(point);
                setState(() {
                  _isLoading = false;
                });
              },
            ),
            children: [
              fm.TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.buzryde.com',
              ),
              fm.MarkerLayer(markers: _markers),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          if (locationResult?.displayName != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                margin: const EdgeInsets.only(bottom: 100, left: 40, right: 40),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        locationResult?.displayName ?? '',
                        style: const TextStyle(fontSize: 16, color: Colors.black),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: (_isLoading || (locationResult?.displayName == null || locationResult!.displayName.isEmpty))
                          ? null
                          : () {
                              Get.back(result: locationResult);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: (_isLoading || (locationResult?.displayName == null || locationResult!.displayName.isEmpty))
                            ? Colors.grey[400]
                            : (themeChange.getThem() ? AppColors.darkModePrimary : AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      child: Text(
                        widget.isSource ? 'Confirm Pickup' : 'Confirm Destination',
                        style: TextStyle(
                          color: (_isLoading || (locationResult?.displayName == null || locationResult!.displayName.isEmpty))
                              ? Colors.white.withOpacity(0.7)
                              : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 00),
                  child: InkWell(
                    onTap: () async {
                      Get.to(const OsmSearchPlacesApi())?.then((value) async {
                        if (value != null) {
                          setState(() {
                            _isLoading = true;
                          });
                          SearchResult place = value;
                          textController = TextEditingController(text: place.displayName);
                          await addMarker(ll.LatLng(place.lat, place.lon));
                          mapController.move(ll.LatLng(place.lat, place.lon), 16.0);
                          setState(() {
                            _isLoading = false;
                          });
                        }
                      });
                    },
                    child: buildTextField(
                      title: "Search Address".tr,
                      textController: textController,
                    ),
                  ),
                )),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _setUserLocation,
        child: Icon(Icons.my_location, color: themeChange.getThem() ? AppColors.darkModePrimary : AppColors.primary),
      ),
    );
  }

  Widget buildTextField({required title, required TextEditingController textController}) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: TextField(
        controller: textController,
        textInputAction: TextInputAction.done,
        style: const TextStyle(color: Colors.black),
        decoration: InputDecoration(
          prefixIcon: IconButton(
            icon: const Icon(Icons.location_on, color: Colors.black),
            onPressed: () {},
          ),
          fillColor: Colors.white,
          filled: true,
          hintText: title,
          hintStyle: const TextStyle(color: Colors.black),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          enabled: false,
        ),
      ),
    );
  }
}