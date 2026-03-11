# iPhone Launch Roadmap Status

Status: In Progress (Updated: 2026-02-24)
Owner: Mobile Engineering
Scope: Lokaler iPhone-Dev-Flow (USB/Wireless Device Launch)

## Zielbild

Ein stabiler Ein-Befehl-Flow fuer iPhone, der alltagstauglich ist:
1. `make iphone` als home-screen-safe Standard.
2. `make iphone-debug` fuer Flutter Live-Debugging.
3. `make iphone-open` zum schnellen Reopen ohne Rebuild.
4. Klare Fehlerdiagnosen bei Lock/Device/Automation-Problemen.

## Umgesetzt

1. Makefile-Redesign abgeschlossen:
- `make iphone` baut/installiert/launcht in home-screen-safe Modus.
- `make iphone-debug` bleibt explizit fuer Debug-Attach.
- `make iphone-open` startet bereits installierte App ohne Rebuild.

2. Robuster Device-Launch umgesetzt:
- Launch via `xcrun devicectl device process launch`.
- Install via `xcrun devicectl device install app`.

3. Diagnoseausgaben verbessert:
- Kein Device: klare Fehlermeldung + Hinweis auf `flutter devices`.
- Lock-/Launch-Probleme mit konkreten Retry-Hinweisen.
- Debug-Hinweis fuer iOS 14+ Verhalten dokumentiert.

4. Dokumentation aktualisiert:
- Usage-Sektion in `README.md` fuer `iphone`, `iphone-debug`, `iphone-open`.

## Bekannte offene Punkte

1. Bundle-ID-Konsistenz:
- Aktuell wird teils `com.alexandermessinger.corejourney` gebaut, obwohl fuer Dev-Flow `...corejourney.dev` erwartet wird.
- Folge: Warning im Build-Output, funktional meist trotzdem lauffaehig.

2. Optionaler Feinschliff:
- Noch praezisere Mapping-/Scheme-Validierung vor Build (frueher Fail statt spaeter Warning).

## Akzeptanzstatus

1. `make iphone` ist nicht mehr Debug-default: Erfuellt.
2. App laesst sich nach `make iphone` vom Home Screen erneut oeffnen: Erfuellt.
3. Debug-Workflow bleibt separat verfuegbar: Erfuellt.
4. Haeufige Launchfehler werden klar kommuniziert: Weitgehend erfuellt.

## Nächste sinnvolle Schritte

1. Bundle-ID/Scheme-Mapping final haerten (Warning entfernen).
2. Kurztest-Matrix dokumentieren (locked, unplugged, debug, reopen).
