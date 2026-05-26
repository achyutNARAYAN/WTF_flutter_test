# WTF Flutter Test

Two local Flutter apps for the 100ms + chat assessment:

- `guru_app`: member app for DK.
- `trainer_app`: trainer app for Aarav.
- `shared`: reusable models, services, widgets, theme, and local sync clients.
- `token_server`: tiny local HTTP server for 100ms token generation and local demo data sync.

## Quick Start

```powershell
cd token_server
copy .env.example .env
node server.js
```

In another terminal:

```powershell
cd guru_app
flutter pub get
flutter run
```

In a third terminal:

```powershell
cd trainer_app
flutter pub get
flutter run
```

Android emulator apps use `http://10.0.2.2:3001`; desktop uses `http://localhost:3001`. If the server is not running, both apps keep working with in-memory fallback, but cross-app sync is disabled.

## Verification

```powershell
C:\flutter\bin\cache\dart-sdk\bin\dart.exe --suppress-analytics analyze shared
C:\flutter\bin\cache\dart-sdk\bin\dart.exe --suppress-analytics analyze guru_app
C:\flutter\bin\cache\dart-sdk\bin\dart.exe --suppress-analytics analyze trainer_app
```

## Demo Script

1. Start `token_server`.
2. Launch Guru App, onboard DK, and open Chat.
3. Launch Trainer App, login as Aarav, and open Chats.
4. DK sends a message Aarav sees it after local polling and replies.
5. DK schedules a call Aarav approves from Requests.
6. Both see the approved call and can enter the 100ms pre-join/call UI.
7. End the call and review Sessions.

## Known Fallbacks

- A real 100ms JWT is returned only when `.env` contains 100ms credentials. Otherwise the server returns a dev token shape and the app falls back to mock join behavior.
- Local sync is intentionally lightweight and in-memory for the assessment. Restarting `token_server` clears chat/request/log state.
