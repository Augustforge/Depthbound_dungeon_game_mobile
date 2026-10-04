# Реестр ассетов

Каждый ассет в игре: откуда он, кто сделал, лицензия. Ведёт агент (GDD 18.3).

| Ассет | Путь в проекте | Источник | Task id / ссылка | Лицензия | Дата |
|---|---|---|---|---|---|
| Концепты автора (герой м/ж, Грюм, Мортен, мокап, меню, карта, мобы) | `references/` | сгенерированы автором | — | собственность автора | 2026-10-02 |
| Герой (мужской), модель + 10 анимаций | `assets/models/hero_m/` | Meshy: image-to-image → image-to-3D → rigging → animate | 01a0fc26-0006…, 01a0fc26-6ac6…, 01a0fc27-f19b…, 01a0fc28-a61e… | Meshy, платный аккаунт автора — коммерческое использование | 2026-10-02 |
| Меч героя | `scripts/view/sword_mesh.gd` | собран кодом | — | свой | 2026-10-02 |
| Узник, тюремщик, арбалетчик, утопленница (модели с ригом) | `assets/models/<id>/` | Meshy: image-to-image → image-to-3D → rigging; задания в `art/source/mobs/<id>/*.json` | см. json | Meshy, платный аккаунт автора | 2026-10-03 |
| Общий пакет анимаций (ходьба монстра и раненого, тяжёлый удар, удар о землю, выстрел, смерть, парирование, бросок, взаимодействие, заряженный удар) | `assets/models/shared/anims_pack2.glb` | Meshy animate на риге героя | см. `art/source/hero_m/anim2_out.json` | Meshy | 2026-10-03 |
| Крыса (модель без рига, анимация кодом) | `assets/models/rat/rat.glb` | Meshy image-to-3D | 01a0ff88-7e58… | Meshy | 2026-10-03 |
| Дубина, щит, арбалет | `scripts/view/sword_mesh.gd` | собраны кодом | — | свой | 2026-10-03 |
| Концепты автора: Цепной громила, Ульм, лагерь | `references/` | сгенерированы автором | — | собственность автора | 2026-10-03 |
| Цепной громила, Ульм (модели с ригом) | `assets/models/chain_brute/`, `assets/models/ulm/` | Meshy: image-to-image → image-to-3D → rigging | `art/source/mobs/<id>/*.json` | Meshy | 2026-10-03 |
| Цепь с крюком, посох с фонарём | `scripts/view/sword_mesh.gd` | собраны кодом | — | свой | 2026-10-03 |
| Надзиратель Грюм, Палач Мортен (модели с ригом) | `assets/models/warden_grum/`, `assets/models/executioner_morten/` | Meshy: image-to-image → image-to-3D → rigging | `art/source/mobs/<id>/*.json` | Meshy | 2026-10-03 |
| Пакет анимаций боссов (удар и вращение топором, рывок, крик, угроза, рёв, стойка) | `assets/models/shared/anims_pack3.glb` | Meshy animate на риге героя | `art/source/hero_m/anim3_out.json` | Meshy | 2026-10-03 |
| Дубина Грюма, топор Мортена | `scripts/view/sword_mesh.gd` | собраны кодом | — | свой | 2026-10-03 |
| Героиня (женский облик), модель с ригом; анимации — общие с героем | `assets/models/hero_f/` | Meshy: image-to-image → image-to-3D → rigging по концепту автора | `art/source/mobs/hero_f/*.json` | Meshy | 2026-10-03 |
| Фоны главного меню и лагеря | `assets/ui/main_menu.webp`, `assets/ui/camp.webp` | арты автора из `references/` | — | собственность автора | 2026-10-03 |
| Портреты облика (мужской, женский) | `assets/ui/portrait_*.webp` | вырезаны из концептов автора (фон убран) | — | собственность автора | 2026-10-03 |
| Шрифты Philosopher, Ruslan Display, Noto Sans Symbols 2 (подмножество ★☆▲▼◆●✓✗☰) | `assets/fonts/` | Google Fonts (github.com/google/fonts) | `assets/fonts/OFL-*.txt` | SIL Open Font License 1.1 | 2026-10-03 |
| Звуки: удары, шаги, ткань, сундук, монеты, рычаги, двери (RPG Audio), удары по металлу и колокол (Impact Sounds), интерфейс (Interface Sounds) | `assets/audio/sfx/` | Kenney.nl | `assets/audio/LICENSE-kenney.txt` | CC0 | 2026-10-03 |
| Звуки воды: всплески, пузыри, петля воды | `assets/audio/sfx/splash_*.ogg`, `bubble_01.ogg`, `loop_*.ogg` | OpenGameArt «40 CC0 water splash / slime SFX» (rubberduck) | opengameart.org/content/40-cc0-water-splash-slime-sfx | CC0 | 2026-10-03 |
| Музыка зоны 1 (камеры) | `assets/audio/music/zone_cells.ogg` | OpenGameArt «Dungeon Ambience» (yd) | opengameart.org/content/dungeon-ambience | CC0 | 2026-10-03 |
| Музыка зоны 2 (казематы) | `assets/audio/music/zone_casemates.ogg` | OpenGameArt «Dark Cavern Ambient» (Paul Wortmann) | opengameart.org/content/dark-cavern-ambient | CC0 | 2026-10-03 |
| Музыка лагеря и меню | `assets/audio/music/camp.ogg` | OpenGameArt «Dark Shrine Loop» (qubodup, yd) | opengameart.org/content/dark-shrine-loop | CC0 | 2026-10-03 |
| Музыка боссов | `assets/audio/music/boss.ogg` | OpenGameArt «Boss Battle Music» (Juhani Junkala), перекодировано в ogg | opengameart.org/content/boss-battle-music | CC0 | 2026-10-03 |
| Объекты: сундуки (деревянный, окованный, реликварий), вентиль, Родник, капкан, рычаг; декор: бочка, ящик, дыба, клетка, стойка с оружием, стол, кости, череп | `assets/models/props/` | Meshy: text-to-image (nano-banana-2) → image-to-3D (smart topology) | `art/source/objects/<id>/*.json`, скрипт `art/source/objects/pipeline.sh` | Meshy, платный аккаунт автора | 2026-10-03 |
| Иконки 12 навыков и 6 слотов снаряжения | `assets/ui/icons/` | Meshy text-to-image (nano-banana-2), два листа 3×3, нарезаны | `art/source/icons/sheet_*.json` | Meshy | 2026-10-03 |
| Кадры интро (4) | `assets/ui/intro/frame*.webp` | Meshy text-to-image (nano-banana-2), 16:9 | `art/source/intro/frame*.json` | Meshy | 2026-10-03 |
| Портреты боссов для реплик | `assets/ui/portrait_warden_grum.webp`, `portrait_executioner_morten.webp` | вырезаны из концептов автора | — | собственность автора | 2026-10-03 |
| Текстуры камня: пол из плит, стена из блоков (бесшовные) | `assets/textures/*_stone.webp` | Meshy text-to-image (nano-banana-2) | `art/source/textures/*.json` | Meshy | 2026-10-03 |

## Бюджет Meshy
Баланс проверяется перед каждой крупной генерацией (`meshy balance`). Баланс на старте: 1190 кредитов.

| Дата | Что | Потрачено | Остаток |
|---|---|---|---|
| 2026-10-04 | Кости и череп для декора (по 21) | 42 | 471 |
| 2026-10-03 | 2 текстуры камня (по 6) | 12 | 513 |
| 2026-10-03 | 4 кадра интро (по 6) | 24 | 525 |
| 2026-10-03 | 13 объектов (по 21: картинка 6 + 3D 15), 2 листа иконок (по 6) | 285 | 549 |
| 2026-10-03 | Героиня: A-поза 6, image-to-3D 15, риг 5 | 26 | 834 |
| 2026-10-03 | Боссы Грюм и Мортен (по 26), пакет из 7 анимаций (21) | 73 | 860 |
| 2026-10-03 | Громила и Ульм (по 26) | 52 | 933 |
| 2026-10-03 | 4 моба (по 26), пакет из 10 анимаций (30), крыса (15) | 149 | 985 |
| 2026-10-02 | Герой (мужской): A-поза (nano-banana-2) 6, image-to-3D smart-topology 12k 15, риг 5, 10 анимаций 30 | 56 | 1134 |

### Стоимость операций (замерено)
- image-to-image nano-banana-2 — 6; image-to-3D smart-topology, текстура 2k — 15; риг — 5; анимация — 3 за клип (до 10 в одном запросе).
- Анимации покупаются один раз на риге героя и переиспользуются на других персонажах Meshy (одинаковые имена костей).

### Смета на остаток MVP (≈ 980 из 1134)
- 8 двуногих (героиня, узник, тюремщик, арбалетчик, утопленник, громила, Грюм, Мортен): по ≈ 26 + свои клипы ≈ 300
- Крыса (без рига, процедурная анимация): ≈ 21
- Объекты (сундуки, рычаги, вентили, Родник, ловушки, решётки, бочки, клетки, факелы и т. п.): ≈ 20 шт. × 21 ≈ 420
- 2D (иконки, интерфейс, кадры интро, лагерь, портреты): ≈ 40 × 6 ≈ 240
