# CurseForge publishing guide — SnapPost Forever

End-to-end checklist to become a CurseForge author, create the project, pass
moderation, and publish **SnapPost Forever** for **WoW Forever** and **Retail / Midnight**
(dual-ship from v0.2.0).

Official portals:

| Role | URL |
|------|-----|
| Author Portal (create / upload) | https://authors.curseforge.com/ |
| Public project pages | https://www.curseforge.com/wow/addons |
| Upload API docs | https://support.curseforge.com/en/support/solutions/articles/9000197321-curseforge-upload-api |
| Author help / moderation tips | Search CurseForge Support for “Project Moderation” and “Author Portal” |

Comparable Forever projects already on CurseForge (for flavor/version tagging reference):
[Classic UI (Forever)](https://www.curseforge.com/wow/addons/classic-ui-for-forever),
[FCUI](https://www.curseforge.com/wow/addons/fcui-foreverclassicui).

---

## 1. Apply as a creator (Author account)

1. Create / sign in to a CurseForge account (Overwolf login is fine).
2. Open **https://authors.curseforge.com/** → join or activate **Author** status if prompted.
3. Complete any required profile fields (display name, contact email).
4. (Optional but recommended) Create an **API token** under Account → API tokens for later automated uploads. Store it outside the repo (never commit tokens).
5. You do **not** need a separate “application form” beyond Author Portal access; the first project submission is what moderation reviews.

If the Author Portal is blocked in your region, use a supported login method or CurseForge support — do not scrape or bypass their systems.

---

## 2. Prepare the project (before you click Create)

### 2.1 Product identity

| Field | Suggested value |
|-------|-----------------|
| Author / display name | **Terynas** (bio: [AUTHOR.md](AUTHOR.md)) |
| Project name | `SnapPost Forever` |
| Slug (URL) | `snappost-forever` (or whatever CurseForge assigns) |
| Game | **World of Warcraft** |
| Category | Mail / Bags & Inventory / Profession (pick the closest; Mail fits) |
| Summary (short) | Map classic profession materials across Forever alts and mail them with safe delays. |
| License | Match `SnapPostForever/LICENSE` (All Rights Reserved) or change both if you prefer MIT |

### 2.2 Technical readiness (this repo)

- [x] `.toc` has `## Interface: 16001, 120105, 120107`, `## AllowLoadGameType: forever, standard`, title/notes/author/version
- [x] Dual-ship: Forever + Retail/Midnight; `ExcludeLoadGameType: classic`
- [x] `LICENSE` in the addon root
- [x] `README.md` with install + commands
- [x] Packaging script: `scripts/package_snappost_forever.sh`
- [x] Fresh in-game screenshots — prefer `docs/screenshots/04-*.jpg`, `05-*.jpg`, `06-*.jpg` (see [screenshots/README.md](screenshots/README.md))
- [ ] Project logo ≥ **400×400** — draft at `docs/branding/logo-400x400.png` (replace if you want a custom mark)
- [ ] English project description (draft: [DESCRIPTION.md](DESCRIPTION.md))
- [ ] Bump `## Version` in the `.toc` to the release you will upload (e.g. `0.1.28` or `0.2.0`)

### 2.3 What moderators typically reject

Avoid these in the **uploaded zip** and on the project page:

- Broken / empty addon folders (zip must contain `SnapPostForever/SnapPostForever.toc` at the expected path)
- Missing or non-English primary description
- Logo smaller than 400×400, or stolen art
- Unrelated binaries, malware, or credential files
- Claiming ownership of Blizzard assets incorrectly; keep a clear “not affiliated” note
- Misleading title (e.g. pretending to be an official Blizzard tool)
- Shipping another author’s full addon inside yours without credit/license

SnapPost Forever is UI/mail workflow only — it does not automate combat math. That fits Forever’s modern addon rules better than combat parsers.

---

## 3. Create the CurseForge project

1. Author Portal → **Create Project** → World of Warcraft → Addon.
2. Fill name, summary, categories, license.
3. Upload **logo**: `docs/branding/logo-400x400.png` (or your replacement).
4. Paste the **Description** from [DESCRIPTION.md](DESCRIPTION.md) (HTML or Markdown, whichever the form accepts).
5. Attach gallery images from `docs/screenshots/` (and any new captures you take).
6. Save as draft if you want to upload the file next.

---

## 4. Package the Release zip

From the **repo root**:

```bash
./scripts/package_snappost_forever.sh
```

This writes something like:

```text
dist/SnapPostForever-0.1.28.zip
```

Zip layout (required):

```text
SnapPostForever/
  SnapPostForever.toc
  LICENSE
  README.md
  *.lua
  Data/
```

**Do not** include:

- `docs/` (screenshots/branding stay on the project page, not in the zip)
- `.git`, deploy scripts, CraftLib import tooling, or Windows client paths
- SavedVariables / `WTF` data

Manual install path for testers:

```text
World of Warcraft/_classic_beta_/Interface/AddOns/SnapPostForever/
```

---

## 5. Upload a file (Release)

1. Project → **Files** → **Upload File**.
2. Choose the zip from `dist/`.
3. Set **Release Type**: `Release` for the first public build (or `Beta` if you want softer expectations).
4. **Game versions / Flavors**: select **Forever** (and the matching game version if listed, e.g. around `1.60.x` / interface era). Do **not** mark Retail-only unless you also ship a Retail build.
5. Changelog: paste the relevant bullets from root `CHANGELOG.md` (Markdown).
6. Submit. First files often go to **moderation** before they appear publicly.

Moderation can take hours to a few days. Respond politely in Author messages if they ask for changes.

---

## 6. Post-approval checklist

- [ ] Project page shows Forever flavor
- [ ] Install via CurseForge app / WowUp / manual zip and confirm `/spostf` loads
- [ ] Description screenshots match the live UI
- [ ] Pin a short “How to start” comment or wiki if useful:
  1. Log each alt → `/spostf scan`
  2. Open mapper → select alt tab → toggle profession chips / map materials
  3. Open mailbox → send from the SnapPost Forever Mail prompt
- [ ] Keep `## Version` and CurseForge file display name in sync on every upload

---

## 7. Recurring release workflow

1. Ship code + update root `CHANGELOG.md` under `[Unreleased]`, then move bullets into a dated section when you cut a version.
2. Bump `## Version` in `SnapPostForever.toc`.
3. `./scripts/package_snappost_forever.sh`
4. Upload zip on CurseForge with Forever flavor + changelog.
5. Optionally automate later with the Upload API + `X-API-TOKEN` (see support article above). Keep tokens out of git.

Local Forever testing still uses:

```bash
./scripts/deploy_snappost_forever.sh
```

---

## 8. Assets ready in this repo

| Asset | Path | Use |
|-------|------|-----|
| Publishing guide | `docs/CURSEFORGE.md` | This file |
| Description draft | `docs/DESCRIPTION.md` | Project About text |
| Logo 400×400 | `docs/branding/logo-400x400.png` | Project icon |
| UI screenshots | `docs/screenshots/04`–`06` (+ older `01`–`03`) | Gallery (see captions) |
| License | `LICENSE` | Project + zip |
| Package script | `../scripts/package_snappost_forever.sh` | Release zip |

### Screenshots for the gallery

Use the current set in `docs/screenshots/`:

1. `04-mail-prompt-current.jpg`
2. `05-mapper-current-ui.jpg`
3. `06-options-addons.jpg`

Optional: minimap button + mapper open if you want a fourth gallery image.
