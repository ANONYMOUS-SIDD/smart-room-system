import 'package:cloud_firestore/cloud_firestore.dart';

class ChatUser {
  ChatUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.sessionId,
    required this.profilePath,
    required this.createdAt,
    this.lastSeen,
    this.isOnline = false,
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final String sessionId;
  final String profilePath; // Supabase URL
  final DateTime createdAt;
  final DateTime? lastSeen;
  final bool isOnline;

  factory ChatUser.fromFirestore(Map<String, dynamic> data) {
    print('📄 ChatUser.fromFirestore data: $data');

    return ChatUser(
      id: data['SessionId']?.toString() ?? '', // Use SessionId as id
      name: data['Name']?.toString() ?? '',
      email: data['Email']?.toString() ?? '',
      phone: data['Phone']?.toString() ?? '',
      sessionId: data['SessionId']?.toString() ?? '',
      profilePath: data['Path']?.toString() ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastSeen: data['lastSeen'] != null
          ? (data['lastSeen'] as Timestamp).toDate()
          : null,
      isOnline: data['isOnline'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'Name': name,
      'Email': email,
      'Phone': phone,
      'SessionId': sessionId,
      'Path': profilePath,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastSeen': lastSeen != null ? Timestamp.fromDate(lastSeen!) : null,
      'isOnline': isOnline,
    };
  }
}
