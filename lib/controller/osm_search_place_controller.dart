import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class SearchResult {
  final String displayName;
  final double lat;
  final double lon;
  final Map<String, dynamic>? address;

  SearchResult({
    required this.displayName,
    required this.lat,
    required this.lon,
    this.address,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      displayName: json['display_name'] ?? '',
      lat: double.tryParse(json['lat']?.toString() ?? '0') ?? 0.0,
      lon: double.tryParse(json['lon']?.toString() ?? '0') ?? 0.0,
      address: json['address'],
    );
  }
}

class OsmSearchPlaceController extends GetxController {
  Rx<TextEditingController> searchTxtController = TextEditingController().obs;
  RxList<SearchResult> suggestionsList = <SearchResult>[].obs;

  @override
  void onInit() {
    super.onInit();
    searchTxtController.value.addListener(() {
      _onChanged();
    });
  }

  _onChanged() {
    fetchAddress(searchTxtController.value.text);
  }

  fetchAddress(String text) async {
    log(":: fetchAddress :: $text");
    try {
      if (text.isEmpty) {
        suggestionsList.clear();
        return;
      }

      final response = await http.get(
        Uri.parse('https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeComponent(text)}&limit=5'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        suggestionsList.value = data.map((item) => SearchResult.fromJson(item)).toList();
      } else {
        suggestionsList.clear();
      }
    } catch (e) {
      log(e.toString());
      suggestionsList.clear();
    }
  }
}