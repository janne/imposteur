# Plan for "Imposteur" (Flutter, local MVP)

Goal: Local "pass-the-phone" word-impostor game. One word known by all except impostor. Each player says a related word in turn, then vote. No timer, no multi-round scoring. Riverpod for state.

Product decisions (locked unless you change)
- One word/phrase allowed (e.g., "sommarlov").
- Vote after the round only.
- Majority vote decides; tie = no elimination (continue or end round).
- Local multiplayer on one device.

Core flows (screens)
1) Start: New game, settings (language, categories on/off, AI toggle placeholder).
2) Players: Add player names (3-8), shuffle order.
3) Role reveal: Pass-the-phone reveal with "hide screen" guard.
4) Turn order: Display current player; "say your word" and tap next.
5) Voting: Select suspected impostor; reveal votes after all vote.
6) Result: Show impostor + word; play again.

Architecture (Flutter + Riverpod)
- GameState: players, word, impostorIndex, phase, turnIndex, votes.
- GamePhase: start, reveal, turn, vote, result.
- WordProvider: local JSON word list.
- GameController (StateNotifier): handles transitions and validations.
- SettingsState: categories, language, AI-toggle (off by default).

Data
- assets/words_sv.json (simple list + optional categories).
- Start with Swedish words; allow English later.

AI-ready design (no API yet)
- Define interface ClueGenerator with stub implementation.
- Provide a placeholder toggle in settings (disabled unless configured).
- No external keys or calls in MVP.

UX details
- "Pass the phone" privacy guard (hold-to-reveal or tap-to-reveal).
- Big, clear buttons; minimal text per screen.
- No timers; one "Next player" action.

Naming
- App display name: Imposteur.
- Bundle id ASCII: com.<you>.imposteur.
