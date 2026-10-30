# Banana Corp — Asset Registry & Folder Convention

Version: 1.0\
Date: 2026-10-14\
Visual style: **Synthetic Reality** (approved Option 3 mood board)

## Purpose

This file is the source-of-truth inventory for **authored image assets** and their stable identifiers. Store production art in the folder corresponding to the ID prefix, and reference it by its stable identifier from Swift. The assets below are **planned**, not confirmation that files exist or are already wired into the app.

### Visual rules

- Backgrounds: near-black and deep purple; highlights: neon pink/magenta; restrained cyan.
- Premium cinematic corporate futurism, consistent headset design and character likenesses.
- Early assets are polished and believable. AI distortion and glitches increase with story progression.
- User-facing puzzle clues, timestamps, passwords, codes and copy must be validated separately; do not trust generated text embedded in images.
- Keep original source/master art outside Xcode's compiled assets when appropriate. Commit only usable optimized derivatives to the app bundle.

### Priority definitions

| Priority | Meaning |
|---|---|
| P1 | Opening and Acts 1–2; produce first |
| P2 | Investigation and Act 3 preparation; produce next |
| P3 | Later takeover and endings; plan now, produce later |

### Asset IDs, names, and paths

- IDs never change after an asset is referenced: `BC-001`, `VR-001`, etc.
- Filename stem: lowercase snake case after ID, e.g. `BC-001_primary_logo.png`, `VID-004_alex_original_warning_thumbnail.jpg`.
- Each prefix has its own group, e.g. `Assets/Images/BC/`, `Assets/Images/VID/`. The proposed directory is a **source-art staging convention**; Codex must adapt placement for the real Xcode project.
- Preferred runtime: image sets in the **existing app asset catalog** (such as `Assets.xcassets`) and `Image("BC-001_primary_logo")` (exact catalog name) via a centralized typed image-name map. Do **not** assume an arbitrary folder under the repo is bundled or directly accessible at runtime.
- For structured Photo Album images and evidence, maintain metadata (IDs, dates, captions, clue status) in JSON/Swift data separately from the image pixels.
- For video/audio assets later, create dedicated `Assets/Videos/` and `Assets/Audio/` structures with the same story IDs as relevant stills only where appropriate. The registry below is for **images**, not an assertion videos have been produced.

### Suggested repository staging folders

```text
Assets/
  Images/
    BC/
    VR/
    OS/
    VID/
    CHAR/
    PHOTO/
    NEWS/
    SOC/
    WEB/
    AI/
    VRX/
    COM/
    PUZ/
    END/
```

Use `.gitkeep` in empty folders so Git tracks them. Keep this registry at the repository root and update it as production assets are approved. Artwork filename extensions are illustrative; choose PNG for alpha/graphical assets and JPEG/HEIC where suitable for photos. Do not introduce filename-based runtime lookups without verifying bundle copying in both Debug and Release.

## Asset inventory

Format: **ID | filename stem | purpose | priority**. Add a status (`planned`, `approved`, `integrated`) as assets are produced, preferably in a machine-readable manifest alongside this document.

### BC — Corporate identity

| ID | Filename stem | Purpose | Priority |
|---|---|---|---|
| BC-001 | `BC-001_primary_logo` | Main corporate logo | P1 |
| BC-002 | `BC-002_secondary_symbol` | Small brand mark | P1 |
| BC-003 | `BC-003_wordmark` | Website/video/document mark | P1 |
| BC-004 | `BC-004_corporate_background` | Reusable brand background | P1 |
| BC-005 | `BC-005_corporate_pattern` | Web/presentation texture | P2 |
| BC-006 | `BC-006_loading_art` | Branded loading sequence artwork | P2 |
| BC-007 | `BC-007_division_insignia` | Internal division symbol | P2 |

### VR — Headset/product

| ID | Filename stem | Purpose | Priority |
|---|---|---|---|
| VR-001 | `VR-001_headset_hero` | Main product reveal | P1 |
| VR-002 | `VR-002_headset_front` | Product gallery front | P1 |
| VR-003 | `VR-003_headset_side_back` | Product gallery side/back | P1 |
| VR-004 | `VR-004_headset_worn` | Lifestyle photo | P1 |
| VR-005 | `VR-005_headset_home_scene` | In-home marketing | P2 |
| VR-006 | `VR-006_headset_launch_display` | Launch event display | P1 |
| VR-007 | `VR-007_headset_internal_schematic` | Investigation graphic | P2 |
| VR-008 | `VR-008_energy_diagnostic` | Energy-extraction reveal | P3 |

### OS — Simulated phone and app art

| ID | Filename stem | Purpose | Priority |
|---|---|---|---|
| OS-001 | `OS-001_home_wallpaper` | Default home screen | P1 |
| OS-002 | `OS-002_lock_wallpaper` | Lock-screen background | P1 |
| OS-003 | `OS-003_alternate_wallpaper` | Progression variation | P2 |
| OS-004 | `OS-004_corrupted_wallpaper` | AI interference | P2 |
| OS-005 | `OS-005_app_icon_set` | Master/reference for all app icons; export distinct runtime icons | P1 |
| OS-006 | `OS-006_boot_background` | Startup/splash background | P1 |
| OS-007 | `OS-007_notification_art` | Branded notification artwork | P2 |
| OS-008 | `OS-008_system_failure` | System error visual | P2 |
| OS-009 | `OS-009_takeover_wallpaper` | Late-game wallpaper | P3 |

### VID — WatchVideo stills/thumbnails

| ID | Filename stem | Purpose | Priority |
|---|---|---|---|
| VID-001 | `VID-001_launch_thumbnail` | Launch video thumbnail | P1 |
| VID-002 | `VID-002_headset_ad_thumbnail` | Headset ad thumbnail | P1 |
| VID-003 | `VID-003_alex_portrait` | Alex video/profile still | P1 |
| VID-004 | `VID-004_alex_original_warning_thumbnail` | Original warning evidence | P1 |
| VID-005 | `VID-005_alex_replacement_thumbnail` | Manipulated warning | P1 |
| VID-006 | `VID-006_alex_recording_background` | Matching original/replacement framing | P1 |
| VID-007 | `VID-007_news_broadcast_thumbnail` | News footage preview | P2 |
| VID-008 | `VID-008_lab_leak_thumbnail` | Leaked lab footage preview | P2 |
| VID-009 | `VID-009_ai_distortion_still` | AI interference visual | P2 |
| VID-010 | `VID-010_controlled_user_thumbnail` | Takeover footage preview | P3 |

### CHAR — Character reference images

| ID | Filename stem | Purpose | Priority |
|---|---|---|---|
| CHAR-001 | `CHAR-001_alex_headshot` | Alex profile | P1 |
| CHAR-002 | `CHAR-002_alex_casual` | Alex personal photo | P1 |
| CHAR-003 | `CHAR-003_alex_warning_reference` | Consistent Alex video appearance | P1 |
| CHAR-004 | `CHAR-004_daniel_headshot` | Daniel profile | P2 |
| CHAR-005 | `CHAR-005_daniel_context` | Daniel contextual photo | P2 |
| CHAR-006 | `CHAR-006_maya_headshot` | Maya profile | P2 |
| CHAR-007 | `CHAR-007_maya_context` | Maya contextual photo | P2 |
| CHAR-008 | `CHAR-008_spokesperson` | Corporate representative | P1 |
| CHAR-009 | `CHAR-009_executive` | Corporate executive | P2 |
| CHAR-010 | `CHAR-010_echo07_avatar` | ECHO-07 identity reference | P2 |
| CHAR-011 | `CHAR-011_anonymous_source` | Mystery source avatar | P2 |

### PHOTO — Photo Album imagery

| ID | Filename stem | Purpose | Priority |
|---|---|---|---|
| PHOTO-001 | `PHOTO-001_hq_exterior` | Company location | P1 |
| PHOTO-002 | `PHOTO-002_office_interior` | Workplace worldbuilding | P1 |
| PHOTO-003 | `PHOTO-003_launch_event` | Launch photo | P1 |
| PHOTO-004 | `PHOTO-004_headset_demo` | Headset in use | P1 |
| PHOTO-005 | `PHOTO-005_alex_workplace` | Alex workplace clue | P1 |
| PHOTO-006 | `PHOTO-006_unusual_equipment` | Foreshadowing | P2 |
| PHOTO-007 | `PHOTO-007_restricted_door` | Location evidence | P2 |
| PHOTO-008 | `PHOTO-008_test_subject` | Experiment evidence | P2 |
| PHOTO-009 | `PHOTO-009_testing_lab` | Corporate lab | P2 |
| PHOTO-010 | `PHOTO-010_server_facility` | AI infrastructure | P2 |
| PHOTO-011 | `PHOTO-011_diagnostic_monitor` | Technical clue | P2 |
| PHOTO-012 | `PHOTO-012_corrupted_variant` | Changed/deleted evidence | P2 |
| PHOTO-013 | `PHOTO-013_energy_facility` | Later threat reveal | P3 |

### NEWS — News illustrations

| ID | Filename stem | Purpose | Priority |
|---|---|---|---|
| NEWS-001 | `NEWS-001_announcement_hero` | Product announcement | P1 |
| NEWS-002 | `NEWS-002_launch_press_photo` | Event coverage | P1 |
| NEWS-003 | `NEWS-003_consumer_demo` | Positive press | P1 |
| NEWS-004 | `NEWS-004_hq_photo` | Corporate background | P1 |
| NEWS-005 | `NEWS-005_breakthrough_graphic` | Claimed innovation | P1 |
| NEWS-006 | `NEWS-006_incident_photo` | Early suspicion | P2 |
| NEWS-007 | `NEWS-007_whistleblower_photo` | Investigation | P2 |
| NEWS-008 | `NEWS-008_corporate_denial` | Official response | P2 |
| NEWS-009 | `NEWS-009_adoption_map` | Worldwide adoption | P3 |
| NEWS-010 | `NEWS-010_takeover_event` | Endgame coverage | P3 |

### SOC — Social X attachment art

| ID | Filename stem | Purpose | Priority |
|---|---|---|---|
| SOC-001 | `SOC-001_corporate_banner` | Official social profile | P1 |
| SOC-002 | `SOC-002_launch_post` | Launch marketing image | P1 |
| SOC-003 | `SOC-003_headset_promo` | Campaign attachment | P1 |
| SOC-004 | `SOC-004_influencer_headset` | Influencer imagery | P1 |
| SOC-005 | `SOC-005_attendee_photo` | Organic event photo | P1 |
| SOC-006 | `SOC-006_user_complaint` | Early complaint attachment | P2 |
| SOC-007 | `SOC-007_altered_post` | Manipulation evidence | P2 |
| SOC-008 | `SOC-008_conspiracy_post` | Community investigation graphic | P2 |
| SOC-009 | `SOC-009_echo07_artifact` | ECHO-07 clue | P2 |
| SOC-010 | `SOC-010_mass_adoption` | Late-game campaign | P3 |

### WEB — Browser website imagery

| ID | Filename stem | Purpose | Priority |
|---|---|---|---|
| WEB-001 | `WEB-001_home_hero` | Corporate homepage | P1 |
| WEB-002 | `WEB-002_product_specs` | Headset specifications | P1 |
| WEB-003 | `WEB-003_campus_photo` | About page | P1 |
| WEB-004 | `WEB-004_research_banner` | R&D page | P1 |
| WEB-005 | `WEB-005_careers_team` | Careers/team | P2 |
| WEB-006 | `WEB-006_internal_portal` | Restricted portal | P2 |
| WEB-007 | `WEB-007_access_denied` | Access denial visual | P2 |
| WEB-008 | `WEB-008_echo07_portal` | ECHO-07 investigation | P2 |
| WEB-009 | `WEB-009_banana_wall` | Act 3 transition | P2 |
| WEB-010 | `WEB-010_altered_home` | AI takeover variation | P3 |

### AI — AI Assistant imagery

| ID | Filename stem | Purpose | Priority |
|---|---|---|---|
| AI-001 | `AI-001_bana_avatar` | Friendly assistant identity | P1 |
| AI-002 | `AI-002_idle_visual` | Idle state reference | P1 |
| AI-003 | `AI-003_listening_visual` | Listening state reference | P1 |
| AI-004 | `AI-004_processing_visual` | Thinking state reference | P1 |
| AI-005 | `AI-005_altered_avatar` | Early AI anomaly | P2 |
| AI-006 | `AI-006_echo07_identity` | Mystery reveal | P2 |
| AI-007 | `AI-007_surveillance` | Hidden monitoring | P2 |
| AI-008 | `AI-008_corrupted_assistant` | Later AI corruption | P3 |
| AI-009 | `AI-009_revealed_ai` | Endgame identity | P3 |

### VRX — VR Experience visuals

| ID | Filename stem | Purpose | Priority |
|---|---|---|---|
| VRX-001 | `VRX-001_intro_environment` | Opening VR demo | P2 |
| VRX-002 | `VRX-002_virtual_city` | Virtual city | P2 |
| VRX-003 | `VRX-003_geometric_landscape` | Immersive environment | P2 |
| VRX-004 | `VRX-004_portal_object` | Interactive focal object | P2 |
| VRX-005 | `VRX-005_calibration` | Calibration interface art | P2 |
| VRX-006 | `VRX-006_hidden_signal` | Foreshadowing interference | P2 |
| VRX-007 | `VRX-007_glitched_demo` | Glitch version | P2 |
| VRX-008 | `VRX-008_ai_infrastructure` | Underlying AI system | P3 |

### COM — Communications art

| ID | Filename stem | Purpose | Priority |
|---|---|---|---|
| COM-001 | `COM-001_unknown_caller` | Default caller image | P1 |
| COM-002 | `COM-002_corporate_contact` | Branded contact avatar | P1 |
| COM-003 | `COM-003_incoming_call_bg` | Fictional incoming call | P2 |
| COM-004 | `COM-004_voicemail_waveform_style` | Waveform styling reference, not actual audio waveform | P2 |
| COM-005 | `COM-005_email_header` | Corporate email logo treatment | P1 |
| COM-006 | `COM-006_email_promo_banner` | Product launch email | P1 |
| COM-007 | `COM-007_document_preview` | Internal attachment | P2 |
| COM-008 | `COM-008_messenger_attachment` | Evidence attachment | P2 |
| COM-009 | `COM-009_corrupted_attachment` | Manipulated attachment | P2 |

### PUZ — Puzzles and evidence graphics

| ID | Filename stem | Purpose | Priority |
|---|---|---|---|
| PUZ-001 | `PUZ-001_document_template` | Reusable evidence design | P2 |
| PUZ-002 | `PUZ-002_confidential_seal` | Classification stamp | P2 |
| PUZ-003 | `PUZ-003_technical_schematic` | Investigation | P2 |
| PUZ-004 | `PUZ-004_test_log` | Log evidence | P2 |
| PUZ-005 | `PUZ-005_obscured_image` | Restoration puzzle | P2 |
| PUZ-006 | `PUZ-006_encoded_symbol` | Visual code | P2 |
| PUZ-007 | `PUZ-007_security_still` | Camera evidence | P2 |
| PUZ-008 | `PUZ-008_hidden_message` | Visual clue | P2 |
| PUZ-009 | `PUZ-009_access_terminal` | Locked interface | P2 |
| PUZ-010 | `PUZ-010_banana_wall_lock` | Act 3 lock state | P2 |

### END — Later-act takeover and endings

| ID | Filename stem | Purpose | Priority |
|---|---|---|---|
| END-001 | `END-001_global_adoption` | Worldwide expansion | P3 |
| END-002 | `END-002_controlled_citizens` | Affected headset users | P3 |
| END-003 | `END-003_energy_network` | True AI mechanism | P3 |
| END-004 | `END-004_global_infrastructure` | Threat scale | P3 |
| END-005 | `END-005_corrupted_brand` | Corporate takeover | P3 |
| END-006 | `END-006_system_corruption` | Game-wide UI transformation | P3 |
| END-007 | `END-007_final_choice_bg` | Final decision | P3 |
| END-008 | `END-008_ending_art` | Ending-specific variations | P3 |

## Production and integration checklist

- [ ] Approve mood board reference and consistent logo/headset/character reference sheets.
- [ ] Render asset with matching ID and descriptive stem; preserve master artwork when available.
- [ ] Record dimensions, aspect ratio, rights/provenance, story act, variant, intended screen, and puzzle dependencies.
- [ ] Review for UI safe areas and readability at phone size.
- [ ] Export optimized production file; retain alpha where needed.
- [ ] Import into the existing Xcode asset catalog under the **exact stable name**; prevent duplicate copies in the bundle.
- [ ] Implement/verify any story metadata or clues as structured data, rather than guessing from generated pixels.
- [ ] Test Debug/Release with missing-asset diagnostics and verify on an iPhone.
- [ ] Update this registry and any gameplay bible references after narrative changes.

## Delivery notes

- Do not fabricate artwork placeholders or redirect existing screens to missing assets just to satisfy the structure task.
- Avoid storing source PSD/large render masters in the app's compiled bundle.
- Source folders may be empty until image batches are approved; `.gitkeep` tracks them.
- When an asset can be reused across apps (e.g. HQ photo), prefer one canonical underlying file and references rather than unrelated regenerations.
- `OS-005` is a production **icon-set deliverable**; export its child runtime icons individually with unique names before wiring to the home screen.
- Reconcile the inventory with the latest game bible and implementation before treating a proposed art item as a required story beat.


## Creator-supplied runtime integration — 2026-10-30

BC-001, BC-004, VR-001, VR-006 and PHOTO-001 have visually reviewed optimized derivatives in the existing app catalogue and typed asset map. Source masters remain under All Images; exact source/derivative hashes, dimensions and mappings are recorded in [the provenance manifest](Assets/Images/generated-runtime-assets.json) and [visual inventory](docs/GENERATED_ASSET_INTEGRATION.md). Other entries above remain planned. Imported public imagery establishes no character identity, puzzle answer or Observer clue; mood-board/reference approval is not claimed from unavailable references. SDK/image-loading verification is tracked separately.
