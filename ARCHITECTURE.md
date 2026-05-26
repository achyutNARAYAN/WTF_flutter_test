# Architecture

## Apps

`guru_app` and `trainer_app` are separate Flutter apps that depend on `shared` through a local path package named `wtf_shared`.

## Shared Package

`shared/lib/models` defines the assessment data model. `shared/lib/services` owns:

- auth persistence with `shared_preferences`
- chat streams and read receipts
- call request lifecycle and room metadata
- session log creation and notes
- 100ms token lookup
- structured in-app logs

The services run in memory first and opportunistically sync through `token_server`. This preserves local-first behavior and gives both apps a common process to exchange messages/requests/logs when running together.

## Local Sync

The apps try these bases in order:

1. `http://10.0.2.2:3001` for Android emulator
2. `http://localhost:3001` for desktop

If neither responds, the service layer degrades gracefully to single-app in-memory state.

## RTC

`call_screen.dart` integrates `hmssdk_flutter` with:

- token request through `HmsTokenService`
- pre-join mic/camera toggles
- join/leave
- local/remote video track handling
- reconnect and reconnected callbacks
- post-call session logging

When a live 100ms token cannot be obtained, the UI uses the mock fallback path so reviewers can still complete the workflow locally.
