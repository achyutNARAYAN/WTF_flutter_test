// ============================================================
// Guru App Providers (Riverpod)
// ============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wtf_shared/models/models.dart';
import 'package:wtf_shared/services/services.dart';

// ── Singletons ────────────────────────────────────────────────
final authServiceProvider = Provider<AuthService>((ref) {
  final svc = AuthService();
  ref.onDispose(svc.dispose);
  return svc;
});

final chatServiceProvider = Provider<ChatService>((ref) => ChatService());
final callServiceProvider = Provider<CallService>((ref) => CallService());
final logServiceProvider = Provider<LogService>((ref) => LogService());
final hmsTokenServiceProvider = Provider<HmsTokenService>(
  (ref) => HmsTokenService(),
);

// ── Current User ──────────────────────────────────────────────
final currentUserProvider = StreamProvider<User?>((ref) async* {
  final svc = ref.watch(authServiceProvider);
  await svc.init();
  yield svc.currentUser;
  yield* svc.userStream;
});

// ── Messages for a chat ───────────────────────────────────────
final messagesProvider = StreamProvider.family<List<Message>, String>((
  ref,
  chatId,
) {
  final svc = ref.watch(chatServiceProvider);
  return svc.messagesStream.map((_) => svc.getMessages(chatId));
});

// ── Typing state ──────────────────────────────────────────────
final typingProvider = StreamProvider.family<bool, String>((ref, userId) {
  final svc = ref.watch(chatServiceProvider);
  return svc.typingStream.map((map) => map[userId] ?? false);
});

// ── Call requests ─────────────────────────────────────────────
final memberRequestsProvider = StreamProvider.family<List<CallRequest>, String>(
  (ref, memberId) {
    final svc = ref.watch(callServiceProvider);
    return svc.requestStream.map((_) => svc.getRequestsForMember(memberId));
  },
);

final upcomingCallsProvider = StreamProvider.family<List<CallRequest>, String>((
  ref,
  userId,
) {
  final svc = ref.watch(callServiceProvider);
  return svc.requestStream.map((_) => svc.getUpcomingForUser(userId));
});

// ── Session logs ──────────────────────────────────────────────
final memberLogsProvider = StreamProvider.family<List<SessionLog>, String>((
  ref,
  memberId,
) {
  final svc = ref.watch(logServiceProvider);
  return svc.logStream.map((_) => svc.getLogsForMember(memberId));
});

// ── Recent chats ──────────────────────────────────────────────
final recentChatsProvider = StreamProvider.family<List<Message>, String>((
  ref,
  userId,
) {
  final svc = ref.watch(chatServiceProvider);
  return svc.messagesStream.map((_) => svc.getRecentChats(userId));
});
