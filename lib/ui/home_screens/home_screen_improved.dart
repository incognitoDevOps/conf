import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/controller/home_controller.dart';
import 'package:customer/model/banner_model.dart';
import 'package:customer/model/order/location_lat_lng.dart';
import 'package:customer/model/place_picker_model.dart';
import 'package:customer/model/service_model.dart';
import 'package:customer/themes/app_colors.dart';
import 'package:customer/themes/responsive.dart';
import 'package:customer/ui/home_screens/booking_details_screen.dart';
import 'package:customer/ui/home_screens/last_active_ride_screen.dart';
import 'package:customer/utils/DarkThemeProvider.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:customer/widget/google_map_search_place.dart';
import 'package:customer/widget/place_picker_osm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_place_picker_mb/google_maps_place_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

class HomeScreenImproved extends StatelessWidget {
  const HomeScreenImproved({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);

    return GetX<HomeController>(
      init: HomeController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: AppColors.primary,
          body: controller.isLoading.value
              ? Constant.loader()
              : Column(
                  children: [
                    Container(
                      height: Responsive.width(8, context),
                      width: Responsive.width(100, context),
                      color: AppColors.primary,
                    ),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.background,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(25),
                            topRight: Radius.circular(25),
                          ),
                        ),
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 20),
                                _buildLocationInputs(context, controller, themeChange),
                                const SizedBox(height: 20),
                                _buildServiceSelection(context, controller, themeChange),
                                const SizedBox(height: 20),
                                _buildBannerSection(context, controller, themeChange),
                                const SizedBox(height: 20),
                                _buildActiveRideSection(context, controller, themeChange),
                                const SizedBox(height: 100), // Extra space for floating button
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildLocationInputs(BuildContext context, HomeController controller, DarkThemeProvider themeChange) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeChange.getThem() ? AppColors.darkContainerBackground : AppColors.containerBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Where you want to go?".tr,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 18,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 16),
          _buildLocationField(
            context: context,
            controller: controller.sourceLocationController.value,
            hintText: 'Enter Location'.tr,
            icon: Icons.my_location,
            onTap: () => _selectLocation(context, controller, true),
            themeChange: themeChange,
          ),
          const SizedBox(height: 12),
          _buildLocationField(
            context: context,
            controller: controller.destinationLocationController.value,
            hintText: 'Enter destination Location'.tr,
            icon: Icons.location_on,
            onTap: () => _selectLocation(context, controller, false),
            themeChange: themeChange,
          ),
        ],
      ),
    );
  }

  Widget _buildLocationField({
    required BuildContext context,
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required VoidCallback onTap,
    required DarkThemeProvider themeChange,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: themeChange.getThem() ? AppColors.darkTextField : AppColors.textField,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: themeChange.getThem() ? AppColors.darkTextFieldBorder : AppColors.textFieldBorder,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                controller.text.isEmpty ? hintText : controller.text,
                style: GoogleFonts.poppins(
                  color: controller.text.isEmpty
                      ? Colors.grey[600]
                      : (themeChange.getThem() ? Colors.white : Colors.black),
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceSelection(BuildContext context, HomeController controller, DarkThemeProvider themeChange) {
    return Obx(() {
      if (controller.serviceList.isEmpty) {
        return const SizedBox.shrink();
      }

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: themeChange.getThem() ? AppColors.darkContainerBackground : AppColors.containerBackground,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Select Vehicle".tr,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 18,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: controller.serviceList.length,
                itemBuilder: (context, index) {
                  ServiceModel service = controller.serviceList[index];
                  bool isSelected = controller.selectedType.value.id == service.id;
                  
                  return GestureDetector(
                    onTap: () {
                      controller.selectedType.value = service;
                      if (controller.sourceLocationLAtLng.value.latitude != null &&
                          controller.destinationLocationLAtLng.value.latitude != null) {
                        controller.calculateAmount();
                      }
                    },
                    child: Container(
                      width: 100,
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? AppColors.primary.withOpacity(0.1)
                            : controller.colors[index % controller.colors.length].withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CachedNetworkImage(
                            imageUrl: service.image ?? '',
                            height: 40,
                            width: 40,
                            placeholder: (context, url) => const Icon(Icons.directions_car),
                            errorWidget: (context, url, error) => const Icon(Icons.directions_car),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            service.title ?? '',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              color: isSelected ? AppColors.primary : null,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildBannerSection(BuildContext context, HomeController controller, DarkThemeProvider themeChange) {
    return Obx(() {
      if (controller.bannerList.isEmpty) {
        return const SizedBox.shrink();
      }

      return Container(
        height: 120,
        child: PageView.builder(
          controller: controller.pageController,
          itemCount: controller.bannerList.length,
          itemBuilder: (context, index) {
            BannerModel banner = controller.bannerList[index];
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage(
                  imageUrl: banner.image ?? '',
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[300],
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.error),
                  ),
                ),
              ),
            );
          },
        ),
      );
    });
  }

  Widget _buildActiveRideSection(BuildContext context, HomeController controller, DarkThemeProvider themeChange) {
    return FutureBuilder<bool>(
      future: FireStoreUtils.paymentStatusCheck(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        
        if (snapshot.data == true) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.orange, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Payment Required",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: Colors.orange[800],
                        ),
                      ),
                      Text(
                        "Complete payment for your previous ride",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.orange[700],
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Get.to(() => const LastActiveRideScreen()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    "Pay Now",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        
        return const SizedBox.shrink();
      },
    );
  }

  void _selectLocation(BuildContext context, HomeController controller, bool isSource) async {
    if (Constant.selectedMapType == 'google') {
      LatLng initialPosition = LatLng(
        Constant.currentLocation?.latitude ?? 45.521563,
        Constant.currentLocation?.longitude ?? -122.677433,
      );

      Get.to(() => PlacePicker(
        apiKey: Constant.mapAPIKey,
        initialPosition: initialPosition,
        useCurrentLocation: true,
        selectInitialPosition: true,
        usePinPointingSearch: true,
        usePlaceDetailSearch: true,
        zoomGesturesEnabled: true,
        zoomControlsEnabled: true,
        resizeToAvoidBottomInset: false,
        onPlacePicked: (result) {
          if (isSource) {
            controller.sourceLocationController.value.text = result.formattedAddress ?? '';
            controller.sourceLocationLAtLng.value = LocationLatLng(
              latitude: result.geometry?.location.lat,
              longitude: result.geometry?.location.lng,
            );
          } else {
            controller.destinationLocationController.value.text = result.formattedAddress ?? '';
            controller.destinationLocationLAtLng.value = LocationLatLng(
              latitude: result.geometry?.location.lat,
              longitude: result.geometry?.location.lng,
            );
          }
          
          if (controller.sourceLocationLAtLng.value.latitude != null &&
              controller.destinationLocationLAtLng.value.latitude != null) {
            controller.calculateAmount();
          }
          
          Get.back();
        },
      ));
    } else {
      // Use flutter_map based location picker
      Get.to(() => LocationPicker(isSource: isSource))?.then((value) {
        if (value != null) {
          if (isSource) {
            controller.sourceLocationController.value.text = value.displayName;
            controller.sourceLocationLAtLng.value = LocationLatLng(
              latitude: value.latitude,
              longitude: value.longitude,
            );
          } else {
            controller.destinationLocationController.value.text = value.displayName;
            controller.destinationLocationLAtLng.value = LocationLatLng(
              latitude: value.latitude,
              longitude: value.longitude,
            );
          }
          
          if (controller.sourceLocationLAtLng.value.latitude != null &&
              controller.destinationLocationLAtLng.value.latitude != null) {
            controller.calculateAmount();
          }
        }
      });
    }
  }
}