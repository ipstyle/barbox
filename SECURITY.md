# Security Policy

*[Deutsch weiter unten](#sicherheitshinweise)*

## Supported versions

Only the latest release receives fixes. Older versions are not maintained.

| Version | Supported |
| --- | --- |
| 1.8 | ✅ |
| < 1.8 | ❌ |

## Reporting a vulnerability

**Please do not open a public issue for security problems.**

Use GitHub's private reporting instead:
[**Report a vulnerability**](https://github.com/ipstyle/toolbox/security/advisories/new)

The report stays private between you and the maintainer until a fix is published. No email address is needed on either side.

What helps:

- Which version (see Settings → About)
- Your macOS version
- What an attacker could achieve, not just what looks unusual
- Steps to reproduce

This is a spare-time project, so please allow a few days for a first response.

## Scope

Toolbox runs **unsandboxed** and requests Accessibility, Automation, Bluetooth and Notification permissions. That is by design — desktop switching and the light/dark toggle are not possible otherwise. Reports of the form "the app can do X because it has permission X" are expected behaviour, not vulnerabilities.

Genuinely in scope:

- Ways to make the app execute commands or code it was not meant to execute
- Data leaving the machine that the About screen does not disclose
- Clipboard, file or permission handling that exposes data to other processes

---

# Sicherheitshinweise

## Unterstützte Versionen

Nur das jeweils neueste Release bekommt Korrekturen. Ältere Versionen werden nicht gepflegt.

| Version | Unterstützt |
| --- | --- |
| 1.8 | ✅ |
| < 1.8 | ❌ |

## Schwachstelle melden

**Bitte kein öffentliches Issue für Sicherheitsprobleme eröffnen.**

Stattdessen die private Meldefunktion von GitHub nutzen:
[**Schwachstelle melden**](https://github.com/ipstyle/toolbox/security/advisories/new)

Die Meldung bleibt privat zwischen dir und dem Betreuer, bis eine Korrektur veröffentlicht ist. Niemand muss dafür eine Mailadresse herausgeben.

Hilfreich sind:

- Welche Version (Einstellungen → Über)
- Deine macOS-Version
- Was ein Angreifer damit erreichen könnte, nicht nur was ungewöhnlich aussieht
- Schritte zum Nachstellen

Das ist ein Freizeitprojekt — für eine erste Rückmeldung bitte ein paar Tage einrechnen.

## Was zählt und was nicht

Toolbox läuft **ohne Sandbox** und fragt Freigaben für Bedienungshilfen, Automation, Bluetooth und Mitteilungen an. Das ist Absicht — Desktop-Wechsel und der Hell/Dunkel-Umschalter gehen anders nicht. Meldungen der Art «die App kann X, weil sie die Freigabe X hat» beschreiben beabsichtigtes Verhalten, keine Lücke.

Tatsächlich im Rahmen:

- Wege, die App Befehle oder Code ausführen zu lassen, die nicht vorgesehen sind
- Daten, die den Rechner verlassen und im Über-Fenster nicht genannt sind
- Umgang mit Zwischenablage, Dateien oder Freigaben, der Daten für andere Prozesse zugänglich macht
