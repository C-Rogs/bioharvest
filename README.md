# bioharvest

iOS app that harvests Apple Health data (HRV, resting heart rate, sleep, activity, nutrition, and more) and exports schema v2 JSON for Coach.

## Quick start (fastest test on your phone)

1. Open `bioharvest.xcodeproj` in Xcode
2. Plug in your iPhone (USB), unlock it
3. Select the **bioharvest** target → **Signing & Capabilities** → choose your **Team**
4. Select your iPhone in the device dropdown (top bar)
5. Press **Run** (⌘R)
6. On iPhone: allow Health permissions when prompted
7. Set the export window → **Generate JSON & Share** → pick **Coach** from the share sheet

## Daily workflow

1. Open bioharvest
2. Set the **Export Window** (start/end dates)
3. Optionally adjust **Metric Visibility** toggles to include or exclude HealthKit fields
4. Tap **Generate JSON & Share**
5. Choose **Coach** from the share sheet (primary path)

**Fallback:** after export, use **Copy JSON** under Transmit and paste into Coach manually.

Coach is a separate app (iOS 26+, install from the Coach repo). Both apps must be on the same device for Share handoff.

## Requirements

- iPhone with iOS 18+
- Apple Watch recommended for HRV and sleep data
- Apple Developer account (free works for personal device install)
- **Coach** app (iOS 26+) for Share import; paste/file import works without Share

See [TESTFLIGHT.md](TESTFLIGHT.md) for TestFlight distribution.

## Share → Coach verification

With Coach installed on the same device:

1. bioharvest → **Generate JSON & Share**
2. Share sheet → **Coach**
3. Coach opens and loads context without paste

If Coach is missing from the share sheet, confirm Coach is installed and retry. The export should appear as **bioharvest coach export** with a `Bioharvest_Export_*.json` filename.
