// ============================================================
// Shared Data Models — WTF Flutter Assessment
// ============================================================

enum UserRole { trainer, member }

enum MessageStatus { sending, sent, read }

enum CallRequestStatus { pending, approved, declined, cancelled }

// ── User ────────────────────────────────────────────────────
class User {
  final String id;
  final UserRole role;
  final String name;
  final String email;
  final String? avatarUrl;
  final String? assignedTrainerId;

  const User({
    required this.id,
    required this.role,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.assignedTrainerId,
  });

  factory User.fromJson(Map<String, dynamic> j) => User(
    id: j['id'] as String,
    role: UserRole.values.byName(j['role'] as String),
    name: j['name'] as String,
    email: j['email'] as String,
    avatarUrl: j['avatarUrl'] as String?,
    assignedTrainerId: j['assignedTrainerId'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'role': role.name,
    'name': name,
    'email': email,
    if (avatarUrl != null) 'avatarUrl': avatarUrl,
    if (assignedTrainerId != null) 'assignedTrainerId': assignedTrainerId,
  };

  User copyWith({
    String? id,
    UserRole? role,
    String? name,
    String? email,
    String? avatarUrl,
    String? assignedTrainerId,
  }) => User(
    id: id ?? this.id,
    role: role ?? this.role,
    name: name ?? this.name,
    email: email ?? this.email,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    assignedTrainerId: assignedTrainerId ?? this.assignedTrainerId,
  );
}

// ── Message ─────────────────────────────────────────────────
class Message {
  final String id;
  final String chatId;
  final String senderId;
  final String receiverId;
  final String text;
  final DateTime createdAt;
  final MessageStatus status;

  const Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.createdAt,
    this.status = MessageStatus.sending,
  });

  factory Message.fromJson(Map<String, dynamic> j) => Message(
    id: j['id'] as String,
    chatId: j['chatId'] as String,
    senderId: j['senderId'] as String,
    receiverId: j['receiverId'] as String,
    text: j['text'] as String,
    createdAt: DateTime.parse(j['createdAt'] as String),
    status: MessageStatus.values.byName(j['status'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'chatId': chatId,
    'senderId': senderId,
    'receiverId': receiverId,
    'text': text,
    'createdAt': createdAt.toIso8601String(),
    'status': status.name,
  };

  Message copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? receiverId,
    String? text,
    DateTime? createdAt,
    MessageStatus? status,
  }) => Message(
    id: id ?? this.id,
    chatId: chatId ?? this.chatId,
    senderId: senderId ?? this.senderId,
    receiverId: receiverId ?? this.receiverId,
    text: text ?? this.text,
    createdAt: createdAt ?? this.createdAt,
    status: status ?? this.status,
  );
}

// ── CallRequest ──────────────────────────────────────────────
class CallRequest {
  final String id;
  final String memberId;
  final String trainerId;
  final DateTime requestedAt;
  final DateTime scheduledFor;
  final String? note;
  final CallRequestStatus status;
  final String? declineReason;

  const CallRequest({
    required this.id,
    required this.memberId,
    required this.trainerId,
    required this.requestedAt,
    required this.scheduledFor,
    this.note,
    this.status = CallRequestStatus.pending,
    this.declineReason,
  });

  factory CallRequest.fromJson(Map<String, dynamic> j) => CallRequest(
    id: j['id'] as String,
    memberId: j['memberId'] as String,
    trainerId: j['trainerId'] as String,
    requestedAt: DateTime.parse(j['requestedAt'] as String),
    scheduledFor: DateTime.parse(j['scheduledFor'] as String),
    note: j['note'] as String?,
    status: CallRequestStatus.values.byName(j['status'] as String),
    declineReason: j['declineReason'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'memberId': memberId,
    'trainerId': trainerId,
    'requestedAt': requestedAt.toIso8601String(),
    'scheduledFor': scheduledFor.toIso8601String(),
    if (note != null) 'note': note,
    'status': status.name,
    if (declineReason != null) 'declineReason': declineReason,
  };

  CallRequest copyWith({
    String? id,
    String? memberId,
    String? trainerId,
    DateTime? requestedAt,
    DateTime? scheduledFor,
    String? note,
    CallRequestStatus? status,
    String? declineReason,
  }) => CallRequest(
    id: id ?? this.id,
    memberId: memberId ?? this.memberId,
    trainerId: trainerId ?? this.trainerId,
    requestedAt: requestedAt ?? this.requestedAt,
    scheduledFor: scheduledFor ?? this.scheduledFor,
    note: note ?? this.note,
    status: status ?? this.status,
    declineReason: declineReason ?? this.declineReason,
  );
}

// ── SessionLog ───────────────────────────────────────────────
class SessionLog {
  final String id;
  final String memberId;
  final String trainerId;
  final DateTime startedAt;
  final DateTime endedAt;
  final int durationSec;
  final int? rating;
  final String? trainerNotes;
  final String? memberNotes;

  const SessionLog({
    required this.id,
    required this.memberId,
    required this.trainerId,
    required this.startedAt,
    required this.endedAt,
    required this.durationSec,
    this.rating,
    this.trainerNotes,
    this.memberNotes,
  });

  factory SessionLog.fromJson(Map<String, dynamic> j) => SessionLog(
    id: j['id'] as String,
    memberId: j['memberId'] as String,
    trainerId: j['trainerId'] as String,
    startedAt: DateTime.parse(j['startedAt'] as String),
    endedAt: DateTime.parse(j['endedAt'] as String),
    durationSec: j['durationSec'] as int,
    rating: j['rating'] as int?,
    trainerNotes: j['trainerNotes'] as String?,
    memberNotes: j['memberNotes'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'memberId': memberId,
    'trainerId': trainerId,
    'startedAt': startedAt.toIso8601String(),
    'endedAt': endedAt.toIso8601String(),
    'durationSec': durationSec,
    if (rating != null) 'rating': rating,
    if (trainerNotes != null) 'trainerNotes': trainerNotes,
    if (memberNotes != null) 'memberNotes': memberNotes,
  };

  String get formattedDuration {
    final m = durationSec ~/ 60;
    final s = durationSec % 60;
    return m > 0 ? '${m}m ${s}s' : '${s}s';
  }

  SessionLog copyWith({
    String? id,
    String? memberId,
    String? trainerId,
    DateTime? startedAt,
    DateTime? endedAt,
    int? durationSec,
    int? rating,
    String? trainerNotes,
    String? memberNotes,
  }) => SessionLog(
    id: id ?? this.id,
    memberId: memberId ?? this.memberId,
    trainerId: trainerId ?? this.trainerId,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt ?? this.endedAt,
    durationSec: durationSec ?? this.durationSec,
    rating: rating ?? this.rating,
    trainerNotes: trainerNotes ?? this.trainerNotes,
    memberNotes: memberNotes ?? this.memberNotes,
  );
}

// ── RoomMeta ─────────────────────────────────────────────────
class RoomMeta {
  final String id;
  final String callRequestId;
  final String hmsRoomId;
  final String hmsRoleMember;
  final String hmsRoleTrainer;

  const RoomMeta({
    required this.id,
    required this.callRequestId,
    required this.hmsRoomId,
    required this.hmsRoleMember,
    required this.hmsRoleTrainer,
  });

  factory RoomMeta.fromJson(Map<String, dynamic> j) => RoomMeta(
    id: j['id'] as String,
    callRequestId: j['callRequestId'] as String,
    hmsRoomId: j['hmsRoomId'] as String,
    hmsRoleMember: j['hmsRoleMember'] as String,
    hmsRoleTrainer: j['hmsRoleTrainer'] as String,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'callRequestId': callRequestId,
    'hmsRoomId': hmsRoomId,
    'hmsRoleMember': hmsRoleMember,
    'hmsRoleTrainer': hmsRoleTrainer,
  };
}

// ── Seed Data ────────────────────────────────────────────────
class SeedData {
  static const trainer = User(
    id: 'trainer_aarav',
    role: UserRole.trainer,
    name: 'Aarav',
    email: 'aarav@wtf.fit',
    avatarUrl: 'https://i.pravatar.cc/150?u=aarav',
  );

  static const member = User(
    id: 'member_dk',
    role: UserRole.member,
    name: 'DK',
    email: 'dk@wtf.fit',
    avatarUrl: 'https://i.pravatar.cc/150?u=dk',
    assignedTrainerId: 'trainer_aarav',
  );

  static List<User> trainers = [trainer];
}
