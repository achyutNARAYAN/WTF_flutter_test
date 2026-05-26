import 'package:flutter_test/flutter_test.dart';
import 'package:wtf_shared/models/models.dart';
import 'package:wtf_shared/services/services.dart';

void main() {
  test('message serializes and deserializes', () {
    final createdAt = DateTime(2026, 5, 26, 18);
    final message = Message(
      id: 'm1',
      chatId: 'member_dk_trainer_aarav',
      senderId: 'member_dk',
      receiverId: 'trainer_aarav',
      text: 'Hi Coach',
      createdAt: createdAt,
      status: MessageStatus.sent,
    );

    final parsed = Message.fromJson(message.toJson());

    expect(parsed.id, message.id);
    expect(parsed.createdAt, createdAt);
    expect(parsed.status, MessageStatus.sent);
  });

  test('scheduler rejects past time', () {
    final service = CallService();

    expect(
      service.isValidSlot(DateTime.now().subtract(const Duration(minutes: 1))),
      isFalse,
    );
  });

  test('session log duration is calculated in seconds', () {
    final service = LogService();
    final start = DateTime(2026, 5, 26, 18);
    final end = start.add(const Duration(minutes: 12, seconds: 5));

    final log = service.createLog(
      memberId: 'member_dk',
      trainerId: 'trainer_aarav',
      startedAt: start,
      endedAt: end,
    );

    expect(log.durationSec, 725);
  });
}
