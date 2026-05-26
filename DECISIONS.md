# Decisions

## ADR-001: State Management

Use Riverpod for app state. It gives typed providers, simple stream integration, and keeps service construction testable without heavy generated code.

## ADR-002: Storage And Sync

Use `shared_preferences` for auth/onboarding persistence and in-memory streams for live UX. For two-app local sync, use the tiny `token_server` as an in-memory HTTP bus. This avoids a cloud dependency while keeping both apps runnable on Android emulator.

## ADR-003: RTC Strategy

Use `hmssdk_flutter` in both apps and fetch tokens from `token_server`. The server can mint 100ms JWTs when credentials are present. Without credentials, calls fall back to mock join so the reviewer can still inspect the call UX, session logging, and error handling.

## ADR-004: Shared Package Shape

Expose shared code as a local package named `wtf_shared`, while keeping the requested top-level folders (`models`, `services`, `widgets`, `utils`) for reviewer readability.
