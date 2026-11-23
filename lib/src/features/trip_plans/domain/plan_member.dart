/// What a member may do in a plan. Only the owner archives, deletes and
/// changes members; viewers can only read.
enum PlanRole {
  owner,
  editor,
  viewer;

  bool get canEdit => this != viewer;

  static PlanRole parse(Object? value) => switch (value) {
    'owner' => owner,
    'editor' => editor,
    _ => viewer,
  };
}

/// A person in a plan, by username and avatar only (never a real name).
class PlanMember {
  const PlanMember({
    required this.userId,
    required this.role,
    this.handle,
    this.avatarUrl,
    this.joined = true,
  });

  final String userId;
  final PlanRole role;
  final String? handle;
  final String? avatarUrl;
  final bool joined;

  /// The letter on an avatar without a photo.
  String get initial {
    final name = handle?.trim() ?? '';
    return name.isEmpty ? '?' : name.substring(0, 1).toUpperCase();
  }

  static PlanMember? fromJson(Object? json) {
    if (json is! Map || json['user_id'] is! String) return null;
    final handle = json['handle'];
    final avatar = json['avatar_url'];
    return PlanMember(
      userId: json['user_id'] as String,
      role: PlanRole.parse(json['role']),
      handle: handle is String ? handle : null,
      avatarUrl: avatar is String && avatar.isNotEmpty ? avatar : null,
      joined: json['status'] == null || json['status'] == 'joined',
    );
  }

  Map<String, Object?> toJson() => {
    'user_id': userId,
    'role': role.name,
    'handle': handle,
    'avatar_url': avatarUrl,
    'status': joined ? 'joined' : 'invited',
  };
}
