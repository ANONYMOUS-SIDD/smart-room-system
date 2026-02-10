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
  final String profilePath;
  final DateTime createdAt;
  final DateTime? lastSeen;
  final bool isOnline;

  // Creates Chat User From Firestore Data Map
  factory ChatUser.fromFirestore(Map<String, dynamic> data) {
    final name = _extractName(data);
    final sessionId = _extractSessionId(data);
    final id = sessionId.isNotEmpty ? sessionId : (data['id']?.toString() ?? '');
    final finalId = id.isNotEmpty ? id : DateTime.now().millisecondsSinceEpoch.toString();

    return ChatUser(
      id: finalId,
      name: name.isNotEmpty ? name : 'Room Owner',
      email: data['Email']?.toString() ?? data['email']?.toString() ?? '',
      phone: data['Phone']?.toString() ?? data['phone']?.toString() ?? '',
      sessionId: sessionId,
      profilePath: _extractProfilePath(data),
      createdAt: _extractDateTime(data['createdAt']) ?? DateTime.now(),
      lastSeen: _extractDateTime(data['lastSeen']),
      isOnline: data['isOnline'] ?? data['online'] ?? false,
    );
  }

  // Extracts Name From Multiple Possible Field Names
  static String _extractName(Map<String, dynamic> data) {
    final List<String> possibleNameFields = [
      'Name',
      'name',
      'displayName',
      'fullName',
      'username',
      'userName',
    ];

    for (final field in possibleNameFields) {
      if (data[field] != null && data[field].toString().isNotEmpty) {
        return data[field].toString().trim();
      }
    }

    return '';
  }

  // Extracts Session ID From Multiple Possible Field Names
  static String _extractSessionId(Map<String, dynamic> data) {
    final List<String> possibleIdFields = [
      'SessionId',
      'sessionId',
      'uid',
      'userId',
      'firebaseUid',
      'UID',
    ];

    for (final field in possibleIdFields) {
      if (data[field] != null && data[field].toString().isNotEmpty) {
        return data[field].toString().trim();
      }
    }

    return '';
  }

  // Extracts Profile Path From Multiple Possible Field Names
  static String _extractProfilePath(Map<String, dynamic> data) {
    final List<String> possibleImageFields = [
      'Path',
      'path',
      'profilePath',
      'profileUrl',
      'imageUrl',
      'photoURL',
      'avatar',
      'profileImage',
    ];

    for (final field in possibleImageFields) {
      if (data[field] != null && data[field].toString().isNotEmpty) {
        return data[field].toString().trim();
      }
    }

    return '';
  }

  // Converts Various Timestamp Formats To DateTime
  static DateTime? _extractDateTime(dynamic timestamp) {
    if (timestamp == null) return null;

    if (timestamp is Timestamp) {
      return timestamp.toDate();
    }

    if (timestamp is DateTime) {
      return timestamp;
    }

    if (timestamp is String) {
      try {
        return DateTime.parse(timestamp);
      } catch (e) {
        final millis = int.tryParse(timestamp);
        if (millis != null) {
          return DateTime.fromMillisecondsSinceEpoch(millis);
        }
      }
    }

    if (timestamp is int) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }

    return null;
  }

  // Creates Temporary User For Room Owners Not In User Collection
  factory ChatUser.createTemporary({
    required String userId,
    String name = 'Room Owner',
    String email = '',
    String phone = '',
    String profilePath = '',
  }) {
    return ChatUser(
      id: userId,
      name: name,
      email: email,
      phone: phone,
      sessionId: userId,
      profilePath: profilePath,
      createdAt: DateTime.now(),
      lastSeen: DateTime.now(),
      isOnline: false,
    );
  }

  // Converts To Firestore Format For Database Storage
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

  // Converts To Simplified JSON For UI Display
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'sessionId': sessionId,
      'profilePath': profilePath,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastSeen': lastSeen?.millisecondsSinceEpoch,
      'isOnline': isOnline,
    };
  }

  // Creates Copy With Updated Values
  ChatUser copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? sessionId,
    String? profilePath,
    DateTime? createdAt,
    DateTime? lastSeen,
    bool? isOnline,
  }) {
    return ChatUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      sessionId: sessionId ?? this.sessionId,
      profilePath: profilePath ?? this.profilePath,
      createdAt: createdAt ?? this.createdAt,
      lastSeen: lastSeen ?? this.lastSeen,
      isOnline: isOnline ?? this.isOnline,
    );
  }

  // Checks If User Has Required Fields
  bool get isValid => id.isNotEmpty && name.isNotEmpty && sessionId.isNotEmpty;

  // Gets User Initials For Avatar Display
  String get initials {
    if (name.isEmpty) return '?';

    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (name.length >= 2) {
      return name.substring(0, 2).toUpperCase();
    } else {
      return name[0].toUpperCase();
    }
  }

  // Checks If User Was Active Within Last Five Minutes
  bool get isRecentlyActive {
    if (lastSeen == null) return false;

    final now = DateTime.now();
    final difference = now.difference(lastSeen!);
    return difference.inMinutes <= 5;
  }

  // Formats Last Seen Time For User Friendly Display
  String get formattedLastSeen {
    if (lastSeen == null) return 'Never';

    final now = DateTime.now();
    final difference = now.difference(lastSeen!);

    if (difference.inSeconds < 60) return 'Just Now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}M Ago';
    if (difference.inHours < 24) return '${difference.inHours}H Ago';
    if (difference.inDays < 7) return '${difference.inDays}D Ago';

    return '${difference.inDays ~/ 7}W Ago';
  }

  @override
  String toString() {
    return 'ChatUser{Id: $id, Name: $name, Email: $email, SessionId: $sessionId, IsOnline: $isOnline}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is ChatUser &&
              runtimeType == other.runtimeType &&
              id == other.id &&
              sessionId == other.sessionId;

  @override
  int get hashCode => id.hashCode ^ sessionId.hashCode;
}