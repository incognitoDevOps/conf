import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/controller/interCity_controller.dart';
import 'package:customer/model/contact_model.dart';
import 'package:customer/model/freight_vehicle.dart';
import 'package:customer/model/intercity_service_model.dart';
import 'package:customer/model/order/location_lat_lng.dart';
import 'package:customer/themes/app_colors.dart';
import 'package:customer/themes/button_them.dart';
import 'package:customer/themes/responsive.dart';
import 'package:customer/themes/text_field_them.dart';
import 'package:customer/utils/DarkThemeProvider.dart';
import 'package:customer/widget/google_map_search_place.dart';
import 'package:customer/widget/place_picker_osm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_place_picker_mb/google_maps_place_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class InterCityScreen extends StatelessWidget {
  const InterCityScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);

    return GetX<InterCityController>(
      init: InterCityController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: AppColors.primary,
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            title: Text("City to city".tr),
            leading: InkWell(
              onTap: () => Get.back(),
              child: const Icon(Icons.arrow_back),
            ),
          ),
          body: Column(
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
                  child: controller.isLoading.value
                      ? Constant.loader()
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLocationSection(context, controller, themeChange),
                              const SizedBox(height: 20),
                              _buildServiceSelection(context, controller, themeChange),
                              const SizedBox(height: 20),
                              _buildTripDetails(context, controller, themeChange),
                              const SizedBox(height: 20),
                              _buildPassengerSection(context, controller, themeChange),
                              const SizedBox(height: 20),
                              _buildPaymentSection(context, controller, themeChange),
                              const SizedBox(height: 30),
                              _buildBookButton(context, controller),
                            ],
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

  Widget _buildLocationSection(BuildContext context, InterCityController controller, DarkThemeProvider themeChange) {
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
            "Trip Details",
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
            hintText: 'From'.tr,
            icon: Icons.my_location,
            onTap: () => _selectLocation(context, controller, true),
            themeChange: themeChange,
          ),
          const SizedBox(height: 12),
          _buildLocationField(
            context: context,
            controller: controller.destinationLocationController.value,
            hintText: 'To'.tr,
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

  Widget _buildServiceSelection(BuildContext context, InterCityController controller, DarkThemeProvider themeChange) {
    return Obx(() {
      if (controller.intercityService.isEmpty) {
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
              "Select Service",
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
                itemCount: controller.intercityService.length,
                itemBuilder: (context, index) {
                  IntercityServiceModel service = controller.intercityService[index];
                  bool isSelected = controller.selectedInterCityType.value.id == service.id;
                  
                  return GestureDetector(
                    onTap: () {
                      controller.selectedInterCityType.value = service;
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
                            service.name ?? '',
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

  Widget _buildTripDetails(BuildContext context, InterCityController controller, DarkThemeProvider themeChange) {
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
            "Trip Information",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 18,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 16),
          TextFieldThem.buildTextFiled(
            context,
            hintText: 'When'.tr,
            controller: controller.whenController.value,
          ),
          const SizedBox(height: 12),
          TextFieldThem.buildTextFiled(
            context,
            hintText: 'Number of Passengers'.tr,
            controller: controller.noOfPassengers.value,
            keyBoardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          TextFieldThem.buildTextFiled(
            context,
            hintText: 'Comments'.tr,
            controller: controller.commentsController.value,
            maxLine: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildPassengerSection(BuildContext context, InterCityController controller, DarkThemeProvider themeChange) {
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
            "Who's traveling?",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 18,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 16),
          Obx(() => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: themeChange.getThem() ? Colors.grey[800] : Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: themeChange.getThem() ? Colors.grey[700]! : Colors.grey[300]!,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Icon(
                    Icons.person,
                    color: AppColors.primary,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    controller.selectedTakingRide.value.fullName == "Myself"
                        ? "Myself".tr
                        : controller.selectedTakingRide.value.fullName.toString(),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildPaymentSection(BuildContext context, InterCityController controller, DarkThemeProvider themeChange) {
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
            "Payment Method",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 18,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 16),
          Obx(() => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: themeChange.getThem() ? Colors.grey[800] : Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: themeChange.getThem() ? Colors.grey[700]! : Colors.grey[300]!,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.payment, color: AppColors.primary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    controller.selectedPaymentMethod.value.isNotEmpty 
                      ? controller.selectedPaymentMethod.value 
                      : "Select Payment Method".tr,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: controller.selectedPaymentMethod.value.isNotEmpty
                        ? Theme.of(context).textTheme.bodyLarge?.color
                        : Colors.grey[600],
                    ),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.grey[400],
                  size: 20,
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildBookButton(BuildContext context, InterCityController controller) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: () {
          // Handle intercity booking
          ShowToastDialog.showToast("Intercity booking coming soon!");
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          "Book Intercity Ride".tr,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  void _selectLocation(BuildContext context, InterCityController controller, bool isSource) async {
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