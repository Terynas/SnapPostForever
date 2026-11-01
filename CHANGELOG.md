# Changelog — SnapPost Forever

All notable changes to **SnapPost Forever** (and related SnapPost Mainline notes that lived in the old root changelog) are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added

- Classic Era (1.15.x) support. The addon now loads on Classic Era with the same vanilla material catalog and profession list as WoW Forever, normal realm-style character names, and professions read from the Skills tab.
- GitHub-facing docs and policy: polished README + banner, `AGENTS.md` / multi-tool AI loaders, `SECURITY.md`, issue/PR templates, and maintainer git hooks that require interactive push confirmation. Store description updated for Forever + Midnight dual-ship.
- CurseForge gallery screenshots refreshed (`docs/screenshots/04`–`06`) with Classic Era mail prompt, mapper, and Options captures.
- BigWigs Packager kit: `.pkgmeta` + `.github/workflows/release.yml` so a `v*` tag can build the zip and upload to CurseForge; setup steps in `docs/CURSEFORGE.md`.

## [0.2.19] - 2026-10-25

### Fixed

- Midnight / mainline: 69 Classic materials were missing professions that use them. Leathers and cloth now list Blacksmithing, Engineering and Tailoring where those recipes exist, and herbs list Alchemy. Light Leather, for example, now shows up for Blacksmithing in the mapper and in shared-mat conflicts.

### Added

- With ProfessionMaster installed, SnapPost also adds professions that ProfessionMaster has seen use a material in recipes read from your profession windows, so both addons agree on who can use a mat. This runs at login and whenever the mapper opens.

## [0.2.18] - 2026-10-25

### Fixed

- Item tooltips, chat messages, the guide and Options used an arrow character the game font can't draw (shown as a box); they now use ">" (for example "SnapPost > Alayro").

## [0.2.17] - 2026-10-25

### Added

- **Shared** button in the Mapper: lists mats used by more than one profession in the selected expansion, for the focused profession chip (for example Classic Mining shows bars and stones Blacksmithing and Engineering also use).
- Per-profession rows name the other professions that use a mat ("also Blacksmithing, Engineering").

### Fixed

- **All mats** ignored the expansion dropdown and dumped every material from every expansion (846 on Midnight) into one list. It now shows all professions' mats for the selected expansion; typing a search still looks across all expansions.

## [0.2.16] - 2026-10-25

### Added

- **Shared-mat priority**: right-click one of your own profession chips to cycle its priority (normal → high → low). When a mat is used by professions mapped to different characters (for example Iron Bar for Blacksmithing and Engineering), the highest-priority claim gets it. Each character sets priority only for its own professions. A chip shows a small *high* / *low* badge when it isn't normal.
- **Shared-mat conflicts in the Mapper**: rows for mats several alts claim show a *shared* tag. The tooltip lists every claim, who gets the mat and why. Ties decided only by catalog order get an orange border and *shared* tag, and the footer counts them. Left-clicking the row (item map) or raising a priority settles a tie.
- Bag item tooltips add "· shared" to the SnapPost destination when the mat is contested.

### Changed

- Routing order for mapped mats is now: item map, then the highest priority claim; on equal priority an expansion+profession map beats a whole-profession map, then catalog order. With every priority left at normal, routing is the same as before.

## [0.2.15] - 2026-10-25

### Changed

- **Mapper look closer to the Shorts**: larger gold title with a two-line parchment subtitle and gold divider; alts sidebar rows with gold-rimmed class icons and a bright blue selected row; wide profession chips (icon + label) where the focused profession glows gold and a green marker shows professions routed to that alt; "Search materials..." placeholder with inline clear (Esc clears); material rows with framed item icons, parchment names, and a dropdown-style chevron.
- **Mail prompt**: centered title with gold divider, inset stack list, and a "SnapPost Forever Mail" progress card (envelope icon, green progress bar, live send status).

## [0.2.14] - 2026-10-25

### Changed

- **Per-character routing**: only the logged-in character can change its own mat routing. It can claim an unmapped profession, item or DE-greens slot for itself and release only its own claims; slots claimed by another alt stay locked until that alt logs in (claims by deleted characters can be taken over). Other alts in the sidebar are view-only and show a **view only** marker.
- **Auto Map Common** is now **Claim My Profs**: claims every unmapped profession the logged-in character knows instead of assigning professions to other alts.
- `/spostf de` now takes `me` or `clear` and is refused when another character owns the DE-greens slot.

## [0.2.13] - 2026-10-24

### Changed

- **Materials catalog**: filled all mainline professions (gather + craft + cooking/fishing) across Classic→Shadowlands (~670 reagents). Forever still loads only `Materials_Forever.lua` (CraftLib Classic); retail packs stay `pack = "mainline"`.

## [0.2.12] - 2026-10-24

### Changed

- **Materials catalog**: filled Mining ores/stones and Blacksmithing bars/alloys for Classic→Shadowlands (was sample-only); DF/TWW ores also tagged for Blacksmithing consumers.

## [0.2.11] - 2026-10-24

### Changed

- **Mapper chrome**: dropped the heavy custom ornate frame; outer window uses native Blizzard gold dialog border over the charcoal stone fill, with thin gold tooltip rails on inner panels.

## [0.2.10] - 2026-10-24

### Changed

- **Mapper textures**: OpenArt-generated charcoal `panel-stone` fill and refreshed 8-piece ornate gold frame (no UI text baked into fills). Masters kept under `docs/marketing/openart-sources/`.

## [0.2.9] - 2026-10-24

### Fixed

- **Mapper fill**: replaced broken `panel-stone` asset (was a full UI screenshot, so labels tiled across the window) with a clean seamless charcoal stone texture.

## [0.2.8] - 2026-10-24

### Changed

- **Mapper interiors**: sidebar, main pane, material list, chips, and rows use the same Shorts charcoal stone fill (`Media/panel-stone.tga`) with thin gold rails instead of flat dark dialog wells.
- **Mapper fill**: outer frame background matches the Shorts stone panel (cleaned frame piece alphas kept).

## [0.2.7] - 2026-10-24

### Added

- **Mapper frame art**: commissioned-style ornate gold/stone UI textures under `Media/frame-*.tga` (8 separate corner/edge pieces so corners never stretch).

## [0.2.6] - 2026-10-24

### Fixed

- **Mapper chrome**: removed broken custom Shorts TGA 9-slice (warped corners / black voids). Restored clean Blizzard dialog rock+border chrome. Marketing layout (alt sidebar, profession buttons, material rows) kept.

## [0.2.5] - 2026-10-24

### Changed

- **Mapper frame** experimental custom 9-slice from Shorts art (reverted in 0.2.6).

## [0.2.4] - 2026-10-24

### Changed

- **Mapper chrome** matches the Shorts ornate look: gold metal double rim, stone/marble fill, dialog title header plate, gold-tinted inset wells for alts/main/list (no more flat cool-grey panel).

## [0.2.3] - 2026-10-24

### Changed

- **Mapper UI** restyled to match the marketing layout: titled header + subtitle, left alt sidebar (class icon + colored name, selection glow), large profession buttons with icons, material rows with item icon and `Name (Class)` destination, footer with Auto Map Common / mapped count / Scan. SpellBook outer tabs removed.

## [0.2.2] - 2026-10-24

### Fixed

- Mapper open crash on Midnight when the selected character has no scanned professions (`format` got nil for the profession label). Profession dropdown falls back to the full list so materials stay browsable before Scan.

## [0.2.1] - 2026-10-24

### Changed

- TOC Interface includes Midnight live `120105` and PTR `120107` (client build 12.1.7 / `wowt`).
- Deploy also targets `_ptr_/Interface/AddOns` when the Midnight PTR client is present.

## [0.2.0] - 2026-10-24

### Added

- **Dual-ship** for Forever (`Interface 16001`) and Midnight/Mainline (`120100`): `AllowLoadGameType: forever, standard`; runtime flavor detect.
- Mainline material packs: Classic→SL catalog, Dragonflight, The War Within, and **Midnight** reagents (Wowhead-verified item IDs). Forever still loads only `Materials_Forever.lua`.
- `scripts/import_midnight_materials.py` to refresh Midnight item IDs.
- Deploy script also copies into `_retail_/Interface/AddOns` when present.

### Changed

- Title on Mainline: **SnapPost** (`Title-Mainline`); Forever keeps **SnapPost Forever**.
- CharKey / mail To use first+surname only when Forever (or Regional Unique Names); Mainline uses name-realm.

## [0.1.5] - 2026-10-20

### Changed

- Mapper, mail prompt, intro, and dropdowns use opaque Blizzard dialog chrome (rock background + dialog border) instead of translucent parchment/tooltip panels.

## [0.1.4] - 2026-10-20

### Fixed

- Cleared remaining luacheck warnings (mail/UI globals, long intro/options strings). No gameplay change.

## [0.1.3] - 2026-10-20

### Fixed

- Cleaned luacheck hygiene warnings: unused file locals, an empty soulbound skip branch, shadowed chip/layout locals, and unused color defaults on bag tooltips. No gameplay change.

## [0.1.2] - 2026-10-20

### Fixed

- Profession scan no longer treats every trade-skill catalog line as learned when a character has none. Only lines with skill level greater than zero are stored, so a new character shows no profession chips until they actually learn one.
- Load / Options version string matched the `.toc` again (`0.1.2`). It was still printing `0.1.28` after the release bump.

## [0.1.1] - 2026-10-18

### Added

- First-time guide when opening the mapper on a character (scan → map → mailbox). Skip with the guide’s Skip button, Esc, or Options → **Skip first-time guide**. Replay via Options → Tools → **Show Guide**.

## [0.1.0] - 2026-10-18

First public release. Author credited as **Terynas**; CurseForge bio draft in `docs/AUTHOR.md`.

### Added

- SnapPost Forever CurseForge publishing kit: `docs/CURSEFORGE.md` (author apply + moderation + upload), English description draft, `LICENSE`, branding logo (`docs/branding/logo-400x400.png`), UI gallery screenshots under `docs/screenshots/`, and `scripts/package_snappost_forever.sh` → `dist/SnapPostForever-<version>.zip`.
- **SnapPost Forever** (`SnapPostForever/`): Forever-client port with `Interface: 16001`, Classic materials catalog, vanilla professions (incl. First Aid), and `C_TradeSkillUI` profession scan fallback. Slash: `/spostf`.
- Bag tooltips show where a catalog material will be mailed (`SnapPost → character`), or that it is unmapped / stays on this character.
- SnapPost Forever mail prompt lists each stack with its item icon and Skip/Keep before send, and chat names the items that were mailed.
- SnapPost Forever appears under **Options → AddOns** (Settings API), with mail toggles/delay and a Tools panel to open the mapper; `/spostf options`.
- SnapPost Forever mapper: material name search box, plus Profession / All materials radio to list the full catalog at once.
- SnapPost Forever minimap icon (letter): left-click mapper, right-click options, drag to reposition; toggle via Options or `/spostf minimap`.
- SnapPost Forever can mail low-value Uncommon (green) armor/weapons to an enchanter for DE: level/vendor/AH caps (Auctionator when present), mapper **DE greens → char**, Options toggles, `/spostf de`.
- SnapPost Forever mapper: scanned characters appear as SpellBook-style square side tabs on the left edge of the frame; selecting a tab targets that alt for profession/item/DE maps. Selection uses a glow overlay so class icons stay visible. Layout cleaned up (spacing, shorter status line, material rows).
- SnapPost Forever mapper: profession chips toggle maps (green/gray); removed redundant **Map profession** and **Map exp + profession** buttons (chips cover all mats for a profession). Profession dropdown lists only professions the selected character knows.
- SnapPost Forever mapper: left-click a material to map it to the selected character; right-click to clear that item override.
- SnapPost Forever Options: **Chat: mail send progress** toggles Queuing / Sent to / finished chat lines (failures still print).
- SnapPost Forever Options → **Values**: type exact numbers for send delay, character tab size, and DE green caps (sliders stay in sync).

### Changed

- SnapPost Forever CurseForge gallery docs updated with current mail, mapper, and Options screenshots (`docs/screenshots/04`–`06`).
- SnapPost Forever mapper and mail windows use a rounded gold dialog border, with softer inset cards for the character panel, material list, and rows.
- SnapPost Forever mapper character tabs default to 40px. **Options → AddOns → SnapPost Forever → Character tab size** scales them from 24 to 64.
- SnapPost Forever mail prompt closes (and cancels any send queue) when the mailbox closes — via `MAIL_CLOSED`, MailFrame `OnHide`, interaction hide, and a short open-check while the prompt is shown.
- SnapPost Forever deploy: `scripts/deploy_snappost_forever.sh` rsyncs the workspace addon into `_classic_beta_/Interface/AddOns` (real files; Windows Forever client cannot reliably follow Linux symlinks).
- SnapPost Forever materials catalog imported from CraftLib Vanilla recipes (~430 reagents); each item is tagged with every profession that uses it (e.g. Rough Stone under Blacksmithing and Engineering).
- SnapPost Forever **0.1.3**: character keys and mail **To** use Forever first + surname full names; legacy single-name keys migrate on scan.

### Fixed

- SnapPost Forever mapper status line no longer draws missing-glyph squares (`>` instead of an arrow the game font cannot show). Expansion, Profession, and Search labels sit on their own rows so they are not covered by the controls below them.
- SnapPost Forever mail list rescans bags after each send so mailed stacks disappear from the prompt.
- SnapPost Forever mail queue: fill To/Subject edit boxes, attach via Postal-style click/pickup, send through `SendMailFrame_SendMail` / Send button, with timeout retry when `MAIL_SEND_SUCCESS` never fires.

---

## Related: SnapPost (Mainline)

Historical notes that previously lived in the monorepo root changelog:

### Changed

- SnapPost version **0.2.0**; default mapper view opens on Dragonflight.
- Project focus pivoted from Forever Path to SnapPost; Forever Path remains in-repo but paused.
- Root README rewritten around SnapPost install and mailbox workflow.

### Fixed / Added (Mainline SnapPost)

- **SnapPost** addon (Mainline): account-wide character profession scanning, material→character mapper UI, mailbox bag scan prompt, and a delayed mail send queue.
- Starter materials catalog covering Classic through Shadowlands (sample reagents), plus Midnight placeholders.
- Full **Dragonflight** and **The War Within** material packs (herbs/ores with quality tiers, cloth, leather/skinning, enchanting, common craft reagents).
- Mapper **dropdowns** for expansion, profession, and target character; scrollable material list; buttons to map profession or expansion+profession.
- Mapper controls to assign whole professions or individual items to characters; `/snappost` slash commands including configurable send delay.
- Mail queue waits for `MAIL_SEND_SUCCESS` / `MAIL_FAILED`, splits into 12-attachment mails, and pauses between recipients to reduce throttling risk.
