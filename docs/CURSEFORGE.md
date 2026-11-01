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

## 7. Recurring release workflow (manual)

1. Ship code + update `CHANGELOG.md` under `[Unreleased]`, then move bullets into a dated section when you cut a version.
2. Bump `## Version` in `SnapPostForever.toc` (or let the packager fill `@project-version@` if you switch to that).
3. Either:
   - **Manual:** `./scripts/package_snappost_forever.sh` from the WoWAddons workspace root → upload `dist/SnapPostForever-<version>.zip` on CurseForge, **or**
   - **Automatic:** push a `v*` tag (see §8).
4. Tag flavors Forever + Classic Era + Retail/Midnight as appropriate.
5. Keep tokens out of git.

Local testing still uses:

```bash
./scripts/deploy_snappost_forever.sh
```

---

## 8. GitHub → CurseForge automation (BigWigs Packager)

CurseForge does **not** pull your repo by itself. The standard pattern is:

**GitHub tag → GitHub Actions → [BigWigs Packager](https://github.com/BigWigsMods/packager) → CurseForge Upload API**

This repo already has:

| File | Role |
|------|------|
| [`.pkgmeta`](../.pkgmeta) | What to ship / ignore (`docs/` stays out of the zip) |
| [`.github/workflows/release.yml`](../.github/workflows/release.yml) | Runs the packager on `v*` tags |

Gallery screenshots stay in `docs/screenshots/` and are uploaded **once** on the CurseForge Media tab — they are not part of the auto zip.

### Do not use a GitHub → CurseForge webhook

The Author Portal “package webhook” URL is **not** how WoW addons auto-publish with BigWigs Packager. A `push` webhook will not build your zip or replace the Actions upload. If you added one under GitHub → Settings → Webhooks, delete it. Use `CF_API_KEY` + this workflow instead.

Also set **GitHub → Settings → Actions → General → Workflow permissions** to **Read and write** (or keep Read and rely on this workflow’s `permissions: contents: write`). Without write, the packager cannot attach a GitHub Release even if CurseForge upload works.

### One-time setup (you do this in the browsers)

1. **Create the CurseForge project** (Author Portal) if it does not exist yet — §3 above. Note the numeric **Project ID** from the project URL or project settings (digits only, e.g. `1753123` — no letter suffix).
2. **Create an API token** at [authors.curseforge.com](https://authors.curseforge.com/) → Account → API tokens. Copy it once; you will not see it again. Prefer the account **API Token** used by BigWigs Packager (`CF_API_KEY`), not a webhook query-string token.
3. **Push SnapPostForever as its own GitHub repo** (or ensure this folder is the repo root). The workflow must live at the addon repo root next to `.pkgmeta` and the `.toc`.
4. On that GitHub repo: **Settings → Secrets and variables → Actions → New repository secret**
   - Name: `CF_API_KEY`
   - Value: the CurseForge API token  
   Never commit the token.
5. Add the project id to the TOC (packager reads this):

```toc
## X-Curse-Project-ID: 1753123
```

Digits only. Optional but useful:

```toc
## Version: @project-version@
```

Then the packager sets Version from the git tag (`v0.2.20` → `0.2.20`). If you keep a hard-coded `## Version:`, bump it yourself before tagging.

6. Commit `.pkgmeta`, the workflow, and the TOC line; push to `main` / `master`.

### Every release after that

```bash
# on the SnapPostForever GitHub repo, after changelog + commit
git tag v0.2.20
git push origin v0.2.20
```

GitHub Actions runs `BigWigsMods/packager@v2`, which:

1. Builds a clean `SnapPostForever/` zip (no `docs/`, no `.github/`)
2. Attaches it to a **GitHub Release** for that tag
3. Uploads the same zip to **CurseForge** using `CF_API_KEY` + `X-Curse-Project-ID`

Dry-run locally (no upload):

```bash
curl -sSL https://raw.githubusercontent.com/BigWigsMods/packager/master/release.sh | bash -s -- -d
```

### What automation does *not* do

- Does **not** upload logo / gallery images — keep Media tab updates manual (or CF web UI).
- Does **not** create the CurseForge project for you.
- Does **not** replace moderation on first publish.
- Screenshots and description HTML stay author-portal content.

Official upload API reference: https://support.curseforge.com/en/support/solutions/articles/9000197321-curseforge-upload-api

---

## 9. Assets ready in this repo

| Asset | Path | Use |
|-------|------|-----|
| Publishing guide | `docs/CURSEFORGE.md` | This file |
| Description draft | `docs/DESCRIPTION.md` | Project About text |
| Logo 400×400 | `docs/branding/logo-400x400.png` | Project icon |
| UI screenshots | `docs/screenshots/04`–`06` | Gallery (Classic Era new look) |
| Packager meta | `.pkgmeta` | Zip include/exclude for CI |
| Release workflow | `.github/workflows/release.yml` | Tag → CurseForge |
| License | `LICENSE` | Project + zip |
| Manual package script | `../scripts/package_snappost_forever.sh` | Local zip without CI |

### Screenshots for the gallery

1. `04-mail-prompt-current.jpg` — mailbox send queue  
2. `05-mapper-current-ui.jpg` — alt / profession mapper  
3. `06-options-addons.jpg` — Settings → AddOns  

Upload these on **Images / Media**, not inside the release zip.
