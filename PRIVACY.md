# Privacy Policy — BarBox

*Last updated: 16 August 2026*

BarBox is a menu bar utility for macOS. **It does not collect, store or transmit
any personal data.** There are no accounts, no sign-in, no tracking, no
analytics, no advertising and no third-party SDKs.

## Data the developer receives

**None.** The developer of BarBox receives no data from the app whatsoever —
not usage statistics, not crash reports, not device identifiers.

## Network connections

BarBox contacts exactly four public services, and only to display information
you asked for. No account, cookie or identifier is sent with these requests.

| Service | Purpose | What is sent |
|---|---|---|
| `api.open-meteo.com` | Current weather and 5-day forecast | Approximate coordinates (or the fallback place you typed in the settings) |
| `api.frankfurter.dev` | CHF → EUR/USD exchange rates | Nothing but the request itself |
| `data.snb.ch` | Swiss SARON and SNB policy rate | Nothing but the request itself |
| `api.ipify.org` | Your public IP address, shown on request | Nothing but the request itself; only contacted when you click the button |

The internet speed test (GitHub build only) uses Apple's built-in
`networkQuality` tool and contacts Apple's measurement servers.

## Data that stays on your Mac

- **Location** — used only to look up the weather for your area. The coordinates
  are sent to Open-Meteo for that request and are never stored by the developer.
  You can switch location off and type a fallback place instead.
- **Clipboard history** — kept in memory only, limited to the last 20 text
  entries, and discarded when you quit the app.
- **Images, PDFs and files** — processed entirely on your Mac. Text recognition
  (OCR) runs offline via Apple Vision. Nothing is uploaded.
- **Settings and app favorites** — stored locally in macOS preferences and in
  `~/Library/Application Support/BarBox`. No credentials are stored.
- **Bluetooth and Wi-Fi status** — read locally to display an indicator.

## Permissions

Each permission is requested only when the corresponding feature is first used:
location (weather), Bluetooth (status display), notifications (timer),
automation (light/dark toggle and the Focus shortcut) and folder access when
saving files.

## Children

BarBox contains no objectionable content and is rated 4+. It does not knowingly
collect data from anyone, regardless of age.

## Changes

If this policy ever changes, the updated version will be published in this
repository together with the app release it belongs to.

## Contact

Questions about privacy in BarBox: please open an issue at
<https://github.com/ipstyle/barbox/issues>.

## Source code

BarBox is open source under the GPL-3.0 licence. Every statement above can be
verified in the source code at <https://github.com/ipstyle/barbox>.
