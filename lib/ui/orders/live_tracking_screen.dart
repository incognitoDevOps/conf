import 'package:customer/constant/constant.dart';
import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/controller/live_tracking_controller.dart';
import 'package:customer/themes/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart' as ll;
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LiveTrackingScreen extends StatelessWidget {
  const LiveTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetBuilder<LiveTrackingController>(
      init: LiveTrackingController(),
      builder: (controller) {
        return Scaffold(
          appBar: AppBar(
            elevation: 2,
            backgroundColor: AppColors.primary,
            title: Text("Map view".tr),
            leading: InkWell(
                onTap: () {
                  Get.back();
                },
                child: const Icon(
                  Icons.arrow_back,
                )),
          ),
          body: Constant.selectedMapType == 'osm'
              ? fm.FlutterMap(
                  options: fm.MapOptions(
                    initialCenter: ll.LatLng(
                      Constant.currentLocation?.latitude ?? 45.521563,
                      Constant.currentLocation?.longitude ?? -122.677433,
                    ),
                    initialZoom: 16.0,
                    minZoom: 2.0,
                    maxZoom: 19.0,
                  ),
                  children: [
                    fm.TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.buzryde.com',
                    ),
                    fm.MarkerLayer(
                      markers: _buildFlutterMapMarkers(controller),
                    ),
                    fm.PolylineLayer(
                      polylines: [
                        if (controller.routePoints.isNotEmpty)
                          fm.Polyline(
                            points: controller.routePoints,
                            strokeWidth: 4.0,
                            color: AppColors.primary,
                          ),
                      ],
                    ),
                  ],
                )
              : Obx(
                  () => GoogleMap(
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    mapType: MapType.terrain,
                    zoomControlsEnabled: false,
                    polylines: Set<Polyline>.of(controller.polyLines.values),
                    padding: const EdgeInsets.only(
                      top: 22.0,
                    ),
                    markers: Set<Marker>.of(controller.markers.values),
                    onMapCreated: (GoogleMapController mapController) {
                      controller.mapController = mapController;
                    },
                    initialCameraPosition: CameraPosition(
                      zoom: 15,
                      target: LatLng(Constant.currentLocation != null ? Constant.currentLocation!.latitude : 45.521563,
                          Constant.currentLocation != null ? Constant.currentLocation!.longitude : -122.677433),
                    ),
                  ),
                ),
        );
      },
    );
  }

  List<fm.Marker> _buildFlutterMapMarkers(LiveTrackingController controller) {
    List<fm.Marker> markers = [];
    
    // Add driver marker
    if (controller.driverUserModel.value.location != null) {
      markers.add(
        fm.Marker(
          point: ll.LatLng(
            controller.driverUserModel.value.location!.latitude!,
            controller.driverUserModel.value.location!.longitude!,
          ),
          child: const Icon(Icons.local_taxi, color: Colors.blue, size: 30),
        ),
      );
    }
    
    // Add source marker
    if (controller.type.value == "orderModel" && controller.orderModel.value.sourceLocationLAtLng != null) {
      markers.add(
        fm.Marker(
          point: ll.LatLng(
            controller.orderModel.value.sourceLocationLAtLng!.latitude!,
            controller.orderModel.value.sourceLocationLAtLng!.longitude!,
          ),
          child: const Icon(Icons.location_on, color: Colors.green, size: 30),
        ),
      );
    }
    
    // Add destination marker
    if (controller.type.value == "orderModel" && controller.orderModel.value.destinationLocationLAtLng != null) {
      markers.add(
        fm.Marker(
          point: ll.LatLng(
            controller.orderModel.value.destinationLocationLAtLng!.latitude!,
            controller.orderModel.value.destinationLocationLAtLng!.longitude!,
          ),
          child: const Icon(Icons.flag, color: Colors.red, size: 30),
        ),
      );
    }
    
    return markers;
  }
}
