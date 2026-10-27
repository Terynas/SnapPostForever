<p align="center">
  <img src=".github/banner.jpg" alt="SnapPost Forever — Forever & Midnight" width="100%">
</p>

<p align="center">
  <b>Map profession materials across your alts and mail them with safe delays.</b><br>
  One dual-ship addon for <b>WoW Forever</b> and <b>Midnight / Mainline</b>.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/WoW%20Forever-Interface%2016001-d6a64a?style=flat-square" alt="WoW Forever: Interface 16001">
  <img src="https://img.shields.io/badge/Midnight-Interface%20120105%20%7C%20120107-d6a64a?style=flat-square" alt="Midnight: Interface 120105 and 120107">
  <img src="https://img.shields.io/badge/Lua-5.1-2c2d72?style=flat-square&logo=lua" alt="Lua 5.1">
  <img src="https://img.shields.io/badge/license-ARR-6b6b6b?style=flat-square" alt="All Rights Reserved">
</p>

---

SavedVariables: `SnapPostForeverDB` (does not share maps with any legacy `SnapPost/` package).

## Features

- **Scan** each alt’s professions (`/spostf scan`)
- **Mapper** — alt sidebar, profession chips, search, shared mats, per-item claims
- **Mailbox prompt** — icons, skip stacks, delayed sends
- **DE greens** — optional low-value Uncommon gear to your enchanter
- **First-open guide** + Options + minimap button

## Commands

| Command | Action |
|---------|--------|
| `/spostf` | Open mapper |
| `/spostf options` | Options → AddOns |
| `/spostf minimap` | Show / hide minimap icon |
| `/spostf de <Char-Realm>` | DE greens target (`clear` to remove) |
| `/spostf scan` | Save this character’s professions |
| `/spostf bags` | Mail plan (mailbox open to send) |
| `/spostf delay N` | Seconds between sends |
| `/spostf reset` | Clear maps (keeps scanned characters) |
| `/spostf setmail Char-Realm - Name` | Exact mailbox **To** text |

Also accepts `/snappostf` and `/snappost`.

## Install

1. Install from CurseForge (when published) or copy this folder into `Interface/AddOns/SnapPostForever`.
2. Clients: Forever `_classic_beta_`, Midnight `_retail_` / `_ptr_`.
3. **Full client restart** after adding the addon or changing the `.toc`.
4. Log each alt → `/spostf scan` → map materials → open mailbox → Send.

TOC: `## Interface: 16001, 120105, 120107` · `AllowLoadGameType: forever, standard`.

Maintainer deploy / package (WoWAddons workspace):

```bash
./scripts/deploy_snappost_forever.sh
./scripts/package_snappost_forever.sh   # → dist/SnapPostForever-<version>.zip
```

## Client differences

| | Forever | Midnight / Mainline |
|--|---------|---------------------|
| Materials | Classic Forever pack | Catalog + DF + TWW + Midnight |
| Expansions | Classic | Classic → Midnight |
| Professions | Vanilla + First Aid | Retail set (JC / Inscription; no First Aid) |

## Documentation

| Doc | Purpose |
|-----|---------|
| [`CHANGELOG.md`](CHANGELOG.md) | Version history |
| [`docs/DESCRIPTION.md`](docs/DESCRIPTION.md) | CurseForge / store description |
| [`docs/CURSEFORGE.md`](docs/CURSEFORGE.md) | Publishing checklist |
| [`docs/screenshots/`](docs/screenshots/) | Screenshot notes |
| [`CONTRIBUTING.md`](CONTRIBUTING.md) | **No external PRs** — maintainer rules |
| [`AGENTS.md`](AGENTS.md) | Instructions for AI coding tools |
| [`LICENSE`](LICENSE) | All Rights Reserved |

## Related

- [ProfessionMaster](https://github.com/Terynas/ProfessionMaster) — craft toasts + alt profession browser
- [First Timers](https://github.com/Terynas/First-Timers) — learn to write WoW addons

## Credits

Author: **Terynas**. Not affiliated with Blizzard Entertainment. World of Warcraft is a trademark of Blizzard Entertainment, Inc.
