import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../auth/login_screen.dart';
import '../auth/signup_screen.dart';

/// Main Home Screen For Room Rental Application
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // -------------------------------------------
            // 1. TOP BAR (Logo + Login / Signup)
            // -------------------------------------------
            _buildTopBar(),

            const SizedBox(height: 10),

            // -------------------------------------------
            // 2. CITY + CURRENCY ROW
            // -------------------------------------------
            _buildCityCurrencyRow(),

            const SizedBox(height: 10),

            // -------------------------------------------
            // 3. SORT / FILTER / PRICE / DISTANCE
            // -------------------------------------------
            _buildFilterOptions(),

            const SizedBox(height: 10),

            // -------------------------------------------
            // 4. TITLE TEXT
            // -------------------------------------------
            _buildTitleSection(),

            // -------------------------------------------
            // 5. LIST OF ROOM CARDS
            // -------------------------------------------
            _buildRoomList(),
          ],
        ),
      ),
    );
  }

  /// Build Top Navigation Bar With Logo And Authentication Buttons
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Application Logo
          Image.asset("assets/images/img_logo.jpg", width: 50, height: 50),

          Row(
            children: [
              // Login Button
              _buildAuthButton(iconPath: "assets/images/login_img.png", label: "Login", onPressed: () => Get.to(() => LoginScreen())),
              const SizedBox(width: 12),

              // Signup Button
              _buildAuthButton(iconPath: "assets/images/signup_img.png", label: "Signup", onPressed: () => Get.to(() => SignUpScreen())),
            ],
          ),
        ],
      ),
    );
  }

  /// Build Authentication Button With Icon And Label
  Widget _buildAuthButton({required String iconPath, required String label, required VoidCallback onPressed}) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(children: [Image.asset(iconPath, width: 20, height: 20), const SizedBox(width: 6), Text(label)]),
      ),
    );
  }

  /// Build City And Currency Selection Row
  Widget _buildCityCurrencyRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // City Selection Container
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade400),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: const [Text("Dhulikhel"), Icon(Icons.edit)]),
            ),
          ),
          const SizedBox(width: 12),

          // Currency Selection Container
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade400),
            ),
            child: Row(children: const [Text("NPR"), SizedBox(width: 6), Icon(Icons.keyboard_arrow_down)]),
          ),
        ],
      ),
    );
  }

  /// Build Filter Options Row
  Widget _buildFilterOptions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [_buildFilterBox("Sort By"), const SizedBox(width: 10), _buildFilterBox("Filters"), const SizedBox(width: 10), _buildFilterBox("Price"), const SizedBox(width: 10), _buildFilterBox("Distance")]),
      ),
    );
  }

  /// Build Individual Filter Box
  Widget _buildFilterBox(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: Row(children: [Text(text), const SizedBox(width: 4), const Icon(Icons.keyboard_arrow_down)]),
    );
  }

  /// Build Title Section
  Widget _buildTitleSection() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Text("Showing Rooms in Dhulikhel", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  /// Build Room List Section
  Widget _buildRoomList() {
    return Expanded(
      child: SingleChildScrollView(
        child: Column(
          children: const [
            RoomCard(id: "1", imagePath: "assets/images/room1_img.jpg", houseNumber: "10801", location: "Khadpu | 10 mins walk from KU", features: "Attached bathroom | Sunlight", size: "12 x 15 ft²", price: "NPR 5,850"),
            RoomCard(id: "2", imagePath: "assets/images/room2_img.jpg", houseNumber: "20235", location: "Khadpu | 8 mins walk from KU", features: "Attached bathroom | Sunlight", size: "14 x 16 ft²", price: "NPR 6,200"),
          ],
        ),
      ),
    );
  }
}

/// Room Card Widget For Displaying Room Details
class RoomCard extends StatelessWidget {
  final String id;
  final String imagePath;
  final String houseNumber;
  final String location;
  final String features;
  final String size;
  final String price;

  const RoomCard({super.key, required this.id, required this.imagePath, required this.houseNumber, required this.location, required this.features, required this.size, required this.price});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(20),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Room Image
          _buildRoomImage(),

          // Room Details
          _buildRoomDetails(),
        ],
      ),
    );
  }

  /// Build Room Image Section
  Widget _buildRoomImage() {
    return ClipRRect(
      borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
      child: Image.asset(imagePath, width: double.infinity, height: 180, fit: BoxFit.cover),
    );
  }

  /// Build Room Details Section
  Widget _buildRoomDetails() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // House Number
          Text("House no: $houseNumber", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),

          // Location
          Text(location),
          const SizedBox(height: 4),

          // Features
          Text(features),
          const SizedBox(height: 4),

          // Size
          Text(size),
          const SizedBox(height: 8),

          // Price Section
          _buildPriceSection(),
        ],
      ),
    );
  }

  /// Build Price Display Section
  Widget _buildPriceSection() {
    return Align(
      alignment: Alignment.centerRight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Price
          Text(price, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          // Per Month Label
          const Text("per month"),
        ],
      ),
    );
  }
}
