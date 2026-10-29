import 'plan_member.dart';

/// What an invite link says before the person joins.
enum InviteState {
  ok,
  alreadyMember,
  expired,
  revoked,
  full,
  invalid;

  static InviteState parse(Object? value) => switch (value) {
    'ok' => ok,
    'already_member' => alreadyMember,
    'expired' => expired,
    'revoked' => revoked,
    'full' => full,
    _ => invalid,
  };

  /// The person can join (or is already in) and the plan's name is known.
  bool get showsPlan => this == ok || this == alreadyMember;
}

class InvitePreview {
  const InvitePreview({
    required this.state,
    this.planId,
    this.title,
    this.role = PlanRole.editor,
    this.inviterHandle,
  });

  final InviteState state;
  final String? planId;
  final String? title;
  final PlanRole role;
  final String? inviterHandle;

  static InvitePreview fromJson(Object? json) {
    if (json is! Map) return const InvitePreview(state: InviteState.invalid);
    final handle = json['inviter_handle'];
    final title = json['title'];
    final planId = json['plan_id'];
    return InvitePreview(
      state: InviteState.parse(json['state']),
      planId: planId is String ? planId : null,
      title: title is String ? title : null,
      role: PlanRole.parse(json['role']),
      inviterHandle: handle is String ? handle : null,
    );
  }
}

/// A link just made. The token is shown once; the server keeps only a hash.
class PlanInviteLink {
  const PlanInviteLink({
    required this.id,
    required this.token,
    required this.role,
    required this.expiresAt,
  });

  final String id;
  final String token;
  final PlanRole role;
  final DateTime expiresAt;

  /// What gets shared: the landing site opens the app, or the store.
  String get url => 'https://kaunti47.com/p/$token';

  static PlanInviteLink? fromJson(Object? json) {
    if (json is! Map ||
        json['id'] is! String ||
        json['token'] is! String ||
        DateTime.tryParse('${json['expires_at']}') == null) {
      return null;
    }
    return PlanInviteLink(
      id: json['id'] as String,
      token: json['token'] as String,
      role: PlanRole.parse(json['role']),
      expiresAt: DateTime.parse('${json['expires_at']}'),
    );
  }
}

/// A live link in the invite sheet.
class PlanInviteInfo {
  const PlanInviteInfo({
    required this.id,
    required this.role,
    required this.expiresAt,
    required this.uses,
    this.maxUses,
    this.createdByHandle,
  });

  final String id;
  final PlanRole role;
  final DateTime expiresAt;
  final int uses;
  final int? maxUses;
  final String? createdByHandle;

  static PlanInviteInfo? fromJson(Object? json) {
    if (json is! Map ||
        json['id'] is! String ||
        DateTime.tryParse('${json['expires_at']}') == null) {
      return null;
    }
    final handle = json['created_by_handle'];
    return PlanInviteInfo(
      id: json['id'] as String,
      role: PlanRole.parse(json['role']),
      expiresAt: DateTime.parse('${json['expires_at']}'),
      uses: json['uses'] is num ? (json['uses'] as num).toInt() : 0,
      maxUses: json['max_uses'] is num ? (json['max_uses'] as num).toInt() : null,
      createdByHandle: handle is String ? handle : null,
    );
  }
}

/// A plan someone invited me to by username, waiting for my answer.
class PlanInvitation {
  const PlanInvitation({
    required this.planId,
    required this.title,
    required this.role,
    this.inviterHandle,
  });

  final String planId;
  final String title;
  final PlanRole role;
  final String? inviterHandle;

  static PlanInvitation? fromJson(Object? json) {
    if (json is! Map || json['plan_id'] is! String || json['title'] is! String) {
      return null;
    }
    final handle = json['inviter_handle'];
    return PlanInvitation(
      planId: json['plan_id'] as String,
      title: json['title'] as String,
      role: PlanRole.parse(json['role']),
      inviterHandle: handle is String ? handle : null,
    );
  }
}

/// A person found by username: username and avatar only.
class UsernameHit {
  const UsernameHit({required this.handle, this.avatarUrl});

  final String handle;
  final String? avatarUrl;

  static UsernameHit? fromJson(Object? json) {
    if (json is! Map || json['handle'] is! String) return null;
    final avatar = json['avatar_url'];
    return UsernameHit(
      handle: json['handle'] as String,
      avatarUrl: avatar is String && avatar.isNotEmpty ? avatar : null,
    );
  }
}
