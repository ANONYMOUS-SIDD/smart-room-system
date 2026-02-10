// Booking Confirmation Dialog - Complete Production Solution With Owner ID Fetching
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookingConfirmationDialog extends StatefulWidget {
  final Map<String, dynamic> room;
  final String? roomDocumentId; // Accept Document ID As Parameter

  const BookingConfirmationDialog({
    super.key,
    required this.room,
    this.roomDocumentId,
  });

  @override
  State<BookingConfirmationDialog> createState() => _BookingConfirmationDialogState();
}

class _BookingConfirmationDialogState extends State<BookingConfirmationDialog> {
  bool _isSubmitting = false;
  bool _bookingConfirmed = false;

  Future<void> _submitBooking() async {
    setState(() {
      _isSubmitting = true;
    });

    final firestore = FirebaseFirestore.instance;
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showErrorDialog("Please Login To Book This Room");
      return;
    }

    try {
      final room = widget.room;
      final currentUserSessionId = user.uid;

      // Critical Part: Get Room Owner's Session ID
      String roomOwnerSessionId = '';
      String roomDocumentId = '';

      // Strategy 1: Use Passed Document ID If Available
      roomDocumentId = widget.roomDocumentId ?? room['id']?.toString() ?? '';

      // Strategy 2: Try To Get Session ID From Room Data First
      roomOwnerSessionId = room['sessionId']?.toString() ?? '';

      // Strategy 3: If Session ID Is Not In Room Data, Fetch Complete Room Document
      if (roomOwnerSessionId.isEmpty) {
        if (roomDocumentId.isNotEmpty) {
          // Fetch Complete Document Using Document ID
          final roomDoc = await firestore.collection('room').doc(roomDocumentId).get();

          if (roomDoc.exists) {
            final fullData = roomDoc.data() as Map<String, dynamic>;
            roomOwnerSessionId = fullData['sessionId']?.toString() ?? '';

            if (roomOwnerSessionId.isEmpty) {
              _showErrorDialog("Could Not Find Room Owner Information. Please Contact Support.");
              return;
            }
          } else {
            _showErrorDialog("Room Information Not Found. Please Try Again.");
            return;
          }
        } else {
          // No Document ID Available, Find By Unique Room Combination
          final roomName = room['roomName']?.toString() ?? '';
          final roomLocation = room['location']?.toString() ?? '';

          if (roomName.isNotEmpty && roomLocation.isNotEmpty) {
            final querySnapshot = await firestore
                .collection('room')
                .where('roomName', isEqualTo: roomName)
                .where('location', isEqualTo: roomLocation)
                .limit(1)
                .get();

            if (querySnapshot.docs.isNotEmpty) {
              final doc = querySnapshot.docs.first;
              roomDocumentId = doc.id;
              final fullData = doc.data() as Map<String, dynamic>;
              roomOwnerSessionId = fullData['sessionId']?.toString() ?? '';
            } else {
              _showErrorDialog("Could Not Find Room Information. Please Contact Support.");
              return;
            }
          } else {
            _showErrorDialog("Incomplete Room Information. Please Contact Support.");
            return;
          }
        }
      }

      // Final Validation Check For Owner Session ID
      if (roomOwnerSessionId.isEmpty) {
        _showErrorDialog("Could Not Find Room Owner Information. Please Contact Support.");
        return;
      }

      // Generate Unique Booking ID
      final bookingId = '${DateTime.now().millisecondsSinceEpoch}_${room['roomName']?.toString().replaceAll(' ', '_')}';

      // Prepare Booking Data With Essential Fields Only
      final Map<String, dynamic> bookingData = {
        'bookingId': bookingId,
        'roomDocumentId': roomDocumentId,
        'userId': currentUserSessionId,
        'ownerId': roomOwnerSessionId,
        'userEmail': user.email ?? '',
        'bookingStatus': 'requested',
        'bookingDate': DateTime.now(),
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
      };

      // Save Booking Document To Firestore
      await firestore.collection('bookings').doc(bookingId).set(bookingData);

      // Update Room Status To 'Requested' If Document ID Available
      if (roomDocumentId.isNotEmpty) {
        try {
          await firestore.collection('room').doc(roomDocumentId).update({
            'status': 'Requested',
            'updatedAt': DateTime.now(),
          });
        } catch (e) {
          // Log Error But Continue Since Booking Is Already Created
          print("Warning: Could Not Update Room Status: $e");
        }
      }

      setState(() {
        _isSubmitting = false;
        _bookingConfirmed = true;
      });

      _showSuccessDialog();

    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });

      _showErrorDialog("Failed To Book Room. Please Try Again.");
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4CAF50).withOpacity(0.25),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: const Icon(Icons.check, size: 36, color: Colors.white),
              ),
              const SizedBox(height: 14),
              Text(
                "Booking Request Sent!",
                style: GoogleFonts.quicksand(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Your Booking Request Has Been Sent To The Room Owner. They Will Contact You Soon.",
                textAlign: TextAlign.center,
                style: GoogleFonts.quicksand(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close Success Dialog
                    Navigator.of(context).pop(); // Close Booking Dialog
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    "Continue",
                    style: GoogleFonts.quicksand(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Booking Failed",
          style: GoogleFonts.quicksand(
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          message,
          style: GoogleFonts.quicksand(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              "OK",
              style: GoogleFonts.quicksand(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;

    return Dialog(
      insetPadding: EdgeInsets.zero,
      backgroundColor: Colors.transparent,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.9,
        width: MediaQuery.of(context).size.width,
        margin: EdgeInsets.zero,
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Section
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(28),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey.shade100,
                      ),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        size: 20,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Center(
                      child: Text(
                        "Confirm Booking",
                        style: GoogleFonts.quicksand(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          foreground: Paint()
                            ..shader = const LinearGradient(
                              colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
                            ).createShader(
                              const Rect.fromLTWH(0, 0, 200, 70),
                            ),
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 36),
                ],
              ),
            ),

            // Main Content Area
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      // Room Summary Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(
                            color: Colors.grey.shade200,
                            width: 1.0,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Room Details",
                              style: GoogleFonts.quicksand(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Room Name Field
                            _buildDetailRow(
                              icon: Icons.holiday_village_rounded,
                              label: "Room Name",
                              value: room['roomName']?.toString() ?? "Unnamed Room",
                              iconColor: const Color(0xFF4CAF50),
                            ),
                            const SizedBox(height: 8),

                            // Location Field
                            _buildDetailRow(
                              icon: Icons.location_on_rounded,
                              label: "Location",
                              value: room['location']?.toString() ?? "Location Not Specified",
                              iconColor: Colors.red,
                            ),
                            const SizedBox(height: 8),

                            // Size Field
                            _buildDetailRow(
                              icon: Icons.square_foot_rounded,
                              label: "Size",
                              value: "${room['size'] is int ? room['size'] as int : int.tryParse(room['size']?.toString() ?? '0') ?? 0} Sq Ft",
                              iconColor: const Color(0xFF9C27B0),
                            ),
                            const SizedBox(height: 8),

                            // Monthly Rent Field
                            _buildDetailRow(
                              icon: Icons.attach_money_rounded,
                              label: "Monthly Rent",
                              value: "NPR ${room['price'] is int ? room['price'] as int : int.tryParse(room['price']?.toString() ?? '0') ?? 0}",
                              iconColor: Colors.green,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Booking Terms Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(
                            color: Colors.grey.shade200,
                            width: 1.0,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Booking Terms",
                              style: GoogleFonts.quicksand(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 12),

                            _buildTermItem(
                              "This Booking Request Will Be Sent To The Room Owner",
                              Icons.send_rounded,
                              const Color(0xFF2196F3),
                            ),
                            const SizedBox(height: 8),

                            _buildTermItem(
                              "Owner Will Contact You Within 24 Hours",
                              Icons.access_time_rounded,
                              const Color(0xFFFF9800),
                            ),
                            const SizedBox(height: 8),

                            _buildTermItem(
                              "You Can Cancel Booking Request Anytime Before Confirmation",
                              Icons.cancel_rounded,
                              const Color(0xFFF44336),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Action Buttons Section
                      if (!_bookingConfirmed)
                        Column(
                          children: [
                            // Confirm Booking Button
                            Container(
                              width: double.infinity,
                              height: 52,
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF1565C0).withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _isSubmitting ? null : _submitBooking,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                  padding: EdgeInsets.zero,
                                ),
                                child: _isSubmitting
                                    ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                                    : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.bookmark_add_rounded, size: 20),
                                    const SizedBox(width: 10),
                                    Text(
                                      "Confirm Booking",
                                      style: GoogleFonts.quicksand(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Cancel Button
                            Container(
                              width: double.infinity,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.grey.shade400,
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: Text(
                                  "Cancel",
                                  style: GoogleFonts.quicksand(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                      // Bottom Spacing
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 18,
            color: iconColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.quicksand(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.quicksand(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTermItem(String text, IconData icon, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          margin: const EdgeInsets.only(top: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 14,
            color: color,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.quicksand(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ),
      ],
    );
  }
}