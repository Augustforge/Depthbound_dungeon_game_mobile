# Depthbound («Спуск»)

Мобильный экшен-roguelite: узник спускается по этажам затопленной темницы и должен пройти каждый этаж раньше, чем его зальёт вода.
Движок — Godot 4.7.2, платформа — Android (позже iOS).

- Дизайн-документ: [`docs/GDD.md`](docs/GDD.md)
- План и прогресс: [`docs/PLAN.md`](docs/PLAN.md)
- Решения по ходу работы: [`DECISIONS.md`](DECISIONS.md)

## Как поиграть в текущую сборку
GitHub → Actions → последний зелёный запуск «CI» → Artifacts:
- `depthbound-windows` — распаковать, запустить `Depthbound.exe`;
- `depthbound-macos` — распаковать, открыть через правый клик → «Открыть»;
- `depthbound-android-apk` — установить в эмулятор Android (BlueStacks, LDPlayer или Android Studio Emulator).

Управление на ПК: WASD или мышь (как палец), Пробел — уворот, 1–3 — навыки, E — действие, Esc — пауза, F3 — debug-меню.
