# bioharvest

iPhone app that reads Apple Health for a date window and writes schema v2 JSON. Share the file to Coach on the same phone, or copy it. Helm can import the same payload.

The app's job is the dump. Coaching is Coach or Helm.

Live source: [github.com/C-Rogs/bioharvest](https://github.com/C-Rogs/bioharvest)

## How to use it

1. Open `bioharvest.xcodeproj` in Xcode. Select your team, plug in an iPhone, Run.
2. Allow Health. Missing samples stay JSON `null`. They are not written as 0.
3. Set the export window. Turn metrics off if you want a thinner file.
4. **Generate JSON & Share**, then pick **Coach**.
5. Fallback: Copy JSON and paste.

iOS 18+. An Apple Watch is how HRV and sleep usually exist. Direct-install and TestFlight steps are in [`TESTFLIGHT.md`](TESTFLIGHT.md).

Coach must be installed on the same device for the share-sheet handoff. Paste still works without it.

## Precedent

Health.app's export is a zip of XML aimed at researchers and lawyers. A coaching prompt wants a dated log: resting HR, HRV (SDNN), sleep stages, intake, activity, body composition. Keys stay in the file when the sample is missing so a consumer can tell "no data" from "zero bpm."

That file was the glue between Apple Health and a Gemini thread. Helm now ingests HealthKit itself. bioharvest remains the portable dump: Coach, a paste into a model, a webhook, another device.

## Building blocks

- HealthKit read. No write-through into Health.
- `ExportPayload.currentSchemaVersion` is 2. `app` is `bioharvest`. `purpose` is `time_series_coach_export`.
- Share writes `latest_export.json` into App Group `group.com.cameronro.coach` and opens `coach://import/latest`.
- Settings can POST the same bytes to a webhook. Share is the path that matches how Coach loads context.

```bash
# only if you edited project.yml
xcodegen generate
open bioharvest.xcodeproj
```
