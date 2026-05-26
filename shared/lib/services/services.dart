import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:wtf_shared/models/models.dart';
import 'package:wtf_shared/utils/utils.dart';

enum LogTag { auth, chat, schedule, rtc, general }

class LogEntry {
  final LogTag tag;
  final String message;
  final Object? error;
  final DateTime timestamp;

  LogEntry(this.tag, this.message, {this.error}) : timestamp = DateTime.now();
}

class AppLogger {
  static final _controller = StreamController<List<LogEntry>>.broadcast();
  static final List<LogEntry> _entries = [];

  static Stream<List<LogEntry>> get stream => _controller.stream;
  static List<LogEntry> get entries => List.unmodifiable(_entries);

  static void log(LogTag tag, String message, {Object? error}) {
    final entry = LogEntry(tag, message, error: error);
    _entries.add(entry);
    _controller.add(List.unmodifiable(_entries));
  }
}

class AuthService {
  User? _currentUser;
  bool _initialized = false;
  final _controller = StreamController<User?>.broadcast();

  User? get currentUser => _currentUser;
  Stream<User?> get userStream => _controller.stream;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    final prefs = await SharedPreferences.getInstance();
    final onboarded = prefs.getBool('onboarded') ?? false;
    if (onboarded) {
      _currentUser = User(
        id: 'member_default',
        role: UserRole.member,
        name: prefs.getString('memberName') ?? 'DK',
        email: prefs.getString('memberEmail') ?? 'dk@wtf.fit',
        avatarUrl:
            prefs.getString('memberAvatarUrl') ??
            'https://i.pravatar.cc/150?u=member_default',
        assignedTrainerId:
            prefs.getString('assignedTrainerId') ?? SeedData.trainer.id,
      );
    }
    _controller.add(_currentUser);
  }

  Future<bool> isOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboarded') ?? false;
  }

  Future<void> completeMemberOnboarding(String name, String trainerId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarded', true);
    await prefs.setString('memberName', name);
    await prefs.setString('assignedTrainerId', trainerId);
    _currentUser = User(
      id: 'member_default',
      role: UserRole.member,
      name: name,
      email: '$name@wtf.fit'.toLowerCase(),
      avatarUrl: 'https://i.pravatar.cc/150?u=$name',
      assignedTrainerId: trainerId,
    );
    _controller.add(_currentUser);
  }

  Future<void> loginAsTrainer() async {
    _currentUser = SeedData.trainer;
    _controller.add(_currentUser);
  }

  void dispose() {
    _controller.close();
  }
}

class ChatService {
  final List<Message> _messages = [];
  final _controller = StreamController<List<Message>>.broadcast();
  final _typingController = StreamController<Map<String, bool>>.broadcast();

  ChatService() {
    _initializeSeedMessages();
  }

  Stream<List<Message>> get messagesStream => _controller.stream;
  Stream<Map<String, bool>> get typingStream => _typingController.stream;

  List<Message> getMessages(String chatId) =>
      _messages.where((m) => m.chatId == chatId).toList();

  List<Message> getRecentChats(String userId) {
    final latestByChat = <String, Message>{};
    for (final message in _messages) {
      if (message.senderId == userId || message.receiverId == userId) {
        latestByChat[message.chatId] = message;
      }
    }
    return latestByChat.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  int unreadCount(String chatId, String userId) {
    return _messages
        .where((m) => m.chatId == chatId && m.receiverId == userId)
        .where((m) => m.status != MessageStatus.read)
        .length;
  }

  void markRead(String chatId, String userId) {
    var updated = false;
    for (var i = 0; i < _messages.length; i++) {
      final message = _messages[i];
      if (message.chatId == chatId && message.receiverId == userId) {
        if (message.status != MessageStatus.read) {
          _messages[i] = message.copyWith(status: MessageStatus.read);
          updated = true;
        }
      }
    }
    if (updated) {
      _controller.add(List.unmodifiable(_messages));
    }
  }

  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String receiverId,
    required String text,
  }) async {
    final message = Message(
      id: const Uuid().v4(),
      chatId: chatId,
      senderId: senderId,
      receiverId: receiverId,
      text: text,
      createdAt: DateTime.now(),
      status: MessageStatus.sent,
    );
    _messages.add(message);
    _controller.add(List.unmodifiable(_messages));
  }

  void _initializeSeedMessages() {
    final now = DateTime.now();
    _messages.addAll([
      Message(
        id: const Uuid().v4(),
        chatId: chatIdFor(SeedData.member.id, SeedData.trainer.id),
        senderId: SeedData.trainer.id,
        receiverId: SeedData.member.id,
        text: 'Hey! Ready for your session today?',
        createdAt: now.subtract(const Duration(minutes: 35)),
        status: MessageStatus.read,
      ),
      Message(
        id: const Uuid().v4(),
        chatId: chatIdFor(SeedData.member.id, SeedData.trainer.id),
        senderId: SeedData.member.id,
        receiverId: SeedData.trainer.id,
        text: 'Yes, I am ready. See you soon!',
        createdAt: now.subtract(const Duration(minutes: 15)),
        status: MessageStatus.sent,
      ),
    ]);
    _controller.add(List.unmodifiable(_messages));
    _typingController.add({});
  }
}

class CallService {
  final List<CallRequest> _requests = [];
  final _controller = StreamController<List<CallRequest>>.broadcast();

  CallService() {
    _initializeSeedRequests();
  }

  Stream<List<CallRequest>> get requestStream => _controller.stream;

  List<CallRequest> getRequestsForTrainer(String trainerId) =>
      _requests.where((r) => r.trainerId == trainerId).toList();

  List<CallRequest> getRequestsForMember(String memberId) =>
      _requests.where((r) => r.memberId == memberId).toList();

  List<CallRequest> getUpcomingForUser(String userId) => _requests
      .where(
        (r) =>
            (r.trainerId == userId || r.memberId == userId) &&
            r.status == CallRequestStatus.approved &&
            r.scheduledFor.isAfter(DateTime.now()),
      )
      .toList();

  bool hasConflict(String trainerId, DateTime slot) {
    return _requests.any(
      (request) =>
          request.trainerId == trainerId &&
          request.scheduledFor == slot &&
          request.status == CallRequestStatus.approved,
    );
  }

  void createRequest({
    required String memberId,
    required String trainerId,
    required DateTime scheduledFor,
    String? note,
  }) {
    final request = CallRequest(
      id: const Uuid().v4(),
      memberId: memberId,
      trainerId: trainerId,
      requestedAt: DateTime.now(),
      scheduledFor: scheduledFor,
      note: note,
      status: CallRequestStatus.pending,
    );
    _requests.add(request);
    _controller.add(List.unmodifiable(_requests));
  }

  Future<void> approveRequest(String requestId) async {
    final index = _requests.indexWhere((r) => r.id == requestId);
    if (index == -1) return;
    _requests[index] = _requests[index].copyWith(
      status: CallRequestStatus.approved,
    );
    _controller.add(List.unmodifiable(_requests));
  }

  Future<void> declineRequest(String requestId, String reason) async {
    final index = _requests.indexWhere((r) => r.id == requestId);
    if (index == -1) return;
    _requests[index] = _requests[index].copyWith(
      status: CallRequestStatus.declined,
      declineReason: reason,
    );
    _controller.add(List.unmodifiable(_requests));
  }

  bool isValidSlot(DateTime slot) => slot.isAfter(DateTime.now());

  RoomMeta? getRoomForRequest(String requestId) {
    final index = _requests.indexWhere((r) => r.id == requestId);
    if (index == -1) return null;
    final request = _requests[index];
    return RoomMeta(
      id: const Uuid().v4(),
      callRequestId: request.id,
      hmsRoomId: 'room_${request.id}',
      hmsRoleMember: 'member',
      hmsRoleTrainer: 'trainer',
    );
  }

  void _initializeSeedRequests() {
    final now = DateTime.now();
    _requests.add(
      CallRequest(
        id: const Uuid().v4(),
        memberId: SeedData.member.id,
        trainerId: SeedData.trainer.id,
        requestedAt: now.subtract(const Duration(hours: 2)),
        scheduledFor: now.add(const Duration(days: 1, hours: 3)),
        note: 'Quick progress review ahead of tomorrow session.',
        status: CallRequestStatus.approved,
      ),
    );
    _controller.add(List.unmodifiable(_requests));
  }
}

class LogService {
  final List<SessionLog> _logs = [];
  final _controller = StreamController<List<SessionLog>>.broadcast();

  Stream<List<SessionLog>> get logStream => _controller.stream;

  SessionLog createLog({
    required String memberId,
    required String trainerId,
    required DateTime startedAt,
    required DateTime endedAt,
  }) {
    final log = SessionLog(
      id: const Uuid().v4(),
      memberId: memberId,
      trainerId: trainerId,
      startedAt: startedAt,
      endedAt: endedAt,
      durationSec: endedAt.difference(startedAt).inSeconds,
    );
    _logs.add(log);
    _controller.add(List.unmodifiable(_logs));
    return log;
  }

  List<SessionLog> getLogsForTrainer(String trainerId) =>
      _logs.where((log) => log.trainerId == trainerId).toList()
        ..sort((a, b) => b.startedAt.compareTo(a.startedAt));

  List<SessionLog> getLogsForMember(String memberId) =>
      _logs.where((log) => log.memberId == memberId).toList()
        ..sort((a, b) => b.startedAt.compareTo(a.startedAt));

  void updateTrainerNotes(String logId, String notes) {
    _updateLog(logId, trainerNotes: notes);
  }

  void updateMemberNotes(String logId, int rating, String? notes) {
    final index = _logs.indexWhere((log) => log.id == logId);
    if (index == -1) return;
    final original = _logs[index];
    _logs[index] = original.copyWith(
      rating: rating,
      memberNotes: notes ?? original.memberNotes,
    );
    _controller.add(List.unmodifiable(_logs));
  }

  void _updateLog(String logId, {String? trainerNotes, String? memberNotes}) {
    final index = _logs.indexWhere((log) => log.id == logId);
    if (index == -1) return;
    final original = _logs[index];
    _logs[index] = original.copyWith(
      trainerNotes: trainerNotes ?? original.trainerNotes,
      memberNotes: memberNotes ?? original.memberNotes,
    );
    _controller.add(List.unmodifiable(_logs));
  }
}

class HmsTokenService {
  Future<String> getToken({
    required String userId,
    required String role,
    required String roomId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return 'token-$userId-$role-$roomId';
  }
}
