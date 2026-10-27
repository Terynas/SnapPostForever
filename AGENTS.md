# Agent instructions (SnapPost Forever)

Tool-agnostic contract for Claude Code, GitHub Copilot, Cursor, Codex, Gemini, Windsurf, and similar.

Maintainer-only repo: **no external PRs**, **never push**, never add `Co-authored-by` / `Generated-by` trailers. See `CONTRIBUTING.md`.

## Product

Profession material mapper + delayed mailbox sender. Dual-ship:

| Client | Interface |
|--------|-----------|
| WoW Forever | `16001` |
| Midnight / Mainline | `120105` / `120107` |

Forever ≠ Classic Era. SavedVariables: `SnapPostForeverDB`. TOC: `AllowLoadGameType: forever, standard`.

## Must

- Verify APIs against Forever/Midnight docs — do not invent symbols
- No `loadstring` on chat / addon messages / untrusted SV
- `hooksecurefunc` / `HookScript` only for Blizzard hooks
- `InCombatLockdown()` before secure frame mutations
- Events / `C_Timer` over bare `OnUpdate`; create frames once or pool
- Rate-limit automated mail/chat; opt-in only
- Init SavedVariables on `ADDON_LOADED`; `OnEvent` before `RegisterEvent`
- Update `CHANGELOG.md` under `[Unreleased]` for user-facing changes
- Package with `scripts/package_snappost_forever.sh`; deploy with `scripts/deploy_snappost_forever.sh` in the WoWAddons workspace — do not push

## Deep dives

[`docs/CURSEFORGE.md`](docs/CURSEFORGE.md), [`docs/DESCRIPTION.md`](docs/DESCRIPTION.md). Parent workspace: `First Timers/06-notes/addon-dev/` AI security/performance notes and Forever rules.
