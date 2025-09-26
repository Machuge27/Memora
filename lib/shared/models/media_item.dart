import 'user.dart';
import 'event.dart';

enum MediaType { image, video }

class MediaItem {
  final String id;
  final Event? event;
  final User? uploader;
  final String? fileUrl;
  final String? thumbnailUrl;
  final MediaType type;
  final String? caption;
  final List<User> taggedUsers;
  final DateTime createdAt;
  final DateTime updatedAt;

  MediaItem({
    required this.id,
    this.event,
    this.uploader,
    this.fileUrl,
    this.thumbnailUrl,
    required this.type,
    this.caption,
    required this.taggedUsers,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    return MediaItem(
      id: json['id'],
      event: json['event'] != null ? Event.fromJson(json['event']) : null,
      uploader: json['uploader'] != null ? User.fromJson(json['uploader']) : null,
      fileUrl: json['file_url'],
      thumbnailUrl: json['thumbnail_url'],
      type: json['media_type'] == 'video' ? MediaType.video : MediaType.image,
      caption: json['caption'],
      taggedUsers: (json['tagged_users'] as List<dynamic>? ?? [])
          .map((user) => User.fromJson(user))
          .toList(),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'event': event?.toJson(),
      'uploader': uploader?.toJson(),
      'file_url': fileUrl,
      'thumbnail_url': thumbnailUrl,
      'media_type': type == MediaType.video ? 'video' : 'image',
      'caption': caption,
      'tagged_users': taggedUsers.map((user) => user.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  MediaItem copyWith({
    String? id,
    Event? event,
    User? uploader,
    String? fileUrl,
    String? thumbnailUrl,
    MediaType? type,
    String? caption,
    List<User>? taggedUsers,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MediaItem(
      id: id ?? this.id,
      event: event ?? this.event,
      uploader: uploader ?? this.uploader,
      fileUrl: fileUrl ?? this.fileUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      type: type ?? this.type,
      caption: caption ?? this.caption,
      taggedUsers: taggedUsers ?? this.taggedUsers,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}