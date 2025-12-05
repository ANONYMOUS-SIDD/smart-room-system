import 'package:flutter/material.dart';

void main() {
  runApp(const RoomRentalApp());
}

class RoomRentalApp extends StatelessWidget {
  const RoomRentalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const RoomListingScreen(),
    );
  }
}

class RoomListingScreen extends StatelessWidget {
  const RoomListingScreen({super.key});

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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Logo
                  Image.asset(
                    "assets/images/img_logo.jpg",
                    width: 50,
                    height: 50,
                  ),

                  Row(
                    children: [
                      // Login Button
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Image.asset("assets/images/login_img.png",
                                width: 20, height: 20),
                            const SizedBox(width: 6),
                            const Text("Login"),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Signup Button
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Image.asset("assets/images/signup_img.png",
                                width: 20, height: 20),
                            const SizedBox(width: 6),
                            const Text("Signup"),
                          ],
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),

            const SizedBox(height: 10),

            // -------------------------------------------
            // 2. CITY + CURRENCY ROW
            // -------------------------------------------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text("Dhulikhel"),
                          Icon(Icons.edit),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: Row(
                      children: const [
                        Text("NPR"),
                        SizedBox(width: 6),
                        Icon(Icons.keyboard_arrow_down),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // -------------------------------------------
            // 3. SORT / FILTER / PRICE / DISTANCE
            // -------------------------------------------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _smallBox("Sort By"),
                    const SizedBox(width: 10),
                    _smallBox("Filters"),
                    const SizedBox(width: 10),
                    _smallBox("Price"),
                    const SizedBox(width: 10),
                    _smallBox("Distance"),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            // -------------------------------------------
            // 4. TITLE TEXT
            // -------------------------------------------
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Text(
                "Showing Rooms in Dhulikhel",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // -------------------------------------------
            // 5. LIST OF CARDS
            // -------------------------------------------
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: const [
                    RoomCard(
                      imagePath: "assets/images/room1_img.jpg",
                      houseNumber: "10801",
                      location: "Khadpu | 10 mins walk from KU",
                      features: "Attached bathroom | Sunlight",
                      size: "12 x 15 ft²",
                      price: "NPR 5,850",
                    ),
                    RoomCard(
                      imagePath: "assets/images/room2_img.jpg",
                      houseNumber: "20235",
                      location: "Khadpu | 8 mins walk from KU",
                      features: "Attached bathroom | Sunlight",
                      size: "14 x 16 ft²",
                      price: "NPR 6,200",
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _smallBox(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: Row(
        children: [
          Text(text),
          const SizedBox(width: 4),
          const Icon(Icons.keyboard_arrow_down),
        ],
      ),
    );
  }
}

class RoomCard extends StatelessWidget {
  final String imagePath;
  final String houseNumber;
  final String location;
  final String features;
  final String size;
  final String price;

  const RoomCard({
    super.key,
    required this.imagePath,
    required this.houseNumber,
    required this.location,
    required this.features,
    required this.size,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(20),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12), topRight: Radius.circular(12)),
            child: Image.asset(
              imagePath,
              width: double.infinity,
              height: 180,
              fit: BoxFit.cover,
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("House no: $houseNumber",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),

                const SizedBox(height: 4),
                Text(location),

                const SizedBox(height: 4),
                Text(features),

                const SizedBox(height: 4),
                Text(size),

                const SizedBox(height: 8),

                Align(
                  alignment: Alignment.centerRight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(price,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18)),
                      const Text("per month"),
                    ],
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
