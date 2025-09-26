import 'user.dart';

enum FriendshipStatus { pending, accepted, blocked }

class Friendship {
  final int id;
  final User fromUser;
  final User toUser;
  final FriendshipStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Friendship({
    required this.id,
    required this.fromUser,
    required this.toUser,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Friendship.fromJson(Map<String, dynamic> json) {
    return Friendship(
      id: json['id'],
      fromUser: User.fromJson(json['from_user']),
      toUser: User.fromJson(json['to_user']),
      status: _statusFromString(json['status']),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'from_user': fromUser.toJson(),
      'to_user': toUser.toJson(),
      'status': status.toString().split('.').last,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  static FriendshipStatus _statusFromString(String status) {
    switch (status) {
      case 'pending':
        return FriendshipStatus.pending;
      case 'accepted':
        return FriendshipStatus.accepted;
      case 'blocked':
        return FriendshipStatus.blocked;
      default:
        return FriendshipStatus.pending;
    }
  }
}