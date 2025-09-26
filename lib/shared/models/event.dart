import 'user.dart';

class Event {
  final String id;
  final String name;
  final String description;
  final DateTime date;
  final String location;
  final String? coverImage;
  final String? qrCodeUrl;
  final User? creator;
  final int participantsCount;
  final int mediaCount;
  final String privacy;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Event({
    required this.id,
    required this.name,
    required this.description,
    required this.date,
    required this.location,
    this.coverImage,
    this.qrCodeUrl,
    this.creator,
    required this.participantsCount,
    required this.mediaCount,
    required this.privacy,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      date: DateTime.parse(json['date']),
      location: json['location'],
      coverImage: json['cover_image'],
      qrCodeUrl: json['qr_code_url'],
      creator: json['creator'] != null ? User.fromJson(json['creator']) : null,
      participantsCount: json['participants_count'] ?? 0,
      mediaCount: json['media_count'] ?? 0,
      privacy: json['privacy'] ?? 'public',
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'date': date.toIso8601String(),
      'location': location,
      'cover_image': coverImage,
      'qr_code_url': qrCodeUrl,
      'creator': creator?.toJson(),
      'participants_count': participantsCount,
      'media_count': mediaCount,
      'privacy': privacy,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Event copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? date,
    String? location,
    String? coverImage,
    String? qrCodeUrl,
    User? creator,
    int? participantsCount,
    int? mediaCount,
    String? privacy,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Event(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      date: date ?? this.date,
      location: location ?? this.location,
      coverImage: coverImage ?? this.coverImage,
      qrCodeUrl: qrCodeUrl ?? this.qrCodeUrl,
      creator: creator ?? this.creator,
      participantsCount: participantsCount ?? this.participantsCount,
      mediaCount: mediaCount ?? this.mediaCount,
      privacy: privacy ?? this.privacy,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}