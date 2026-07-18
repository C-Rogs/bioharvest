# TestFlight and device install guide

## Option A: Direct install (fastest, do this first)

Takes about 5 minutes. No App Store Connect wait.

1. **Open project**
   ```bash
   cd /Users/cameronro/Development/bioharvest
   open bioharvest.xcodeproj
   ```

2. **Add Apple ID** (if not already)
   - Xcode → Settings → Accounts → `+` → Apple ID

3. **Enable signing**
   - Click **bioharvest** project (blue icon) → **bioharvest** target
   - **Signing & Capabilities** tab
   - Check **Automatically manage signing**
   - **Team**: select your personal team
   - If bundle ID conflicts, change `com.cameronro.bioharvest` to something unique (e.g. `com.yourname.bioharvest`)

4. **Connect iPhone**
   - USB cable, unlock phone, tap **Trust** on Mac prompt
   - Select your iPhone in Xcode device menu (top centre)

5. **Run**
   - Product → Run (⌘R)
   - First time: iPhone → Settings → General → VPN & Device Management → trust your developer cert

6. **Grant Health access**
   - Open bioharvest → allow all Health read prompts
   - Or: Settings → Privacy & Security → Health → bioharvest → enable Heart Rate, HRV, Sleep

7. **Test export**
   - Export Health Data → Copy JSON → paste into Gemini

## Option B: TestFlight

Use after direct install works. Adds 15-30 min Apple processing.

### Automated upload (recommended)

```bash
cd /Users/cameronro/Development/bioharvest

# First time only: create App Store Connect app record (interactive Apple ID login)
./scripts/create-asc-app.sh

# Archive + upload (or export only if archive already exists)
./scripts/testflight.sh archive export
```

`ITSAppUsesNonExemptEncryption` is set to `false` in `Info.plist` (standard HTTPS only).

### Manual setup (if scripts fail)

1. **Apple Developer Program** ($99/year) required for TestFlight external testers; internal testing works with paid membership.

2. **App Store Connect**
   - https://appstoreconnect.apple.com → My Apps → `+` → New App
   - Name: bioharvest
   - Bundle ID: match Xcode (`com.cameronro.bioharvest`)
   - SKU: `bioharvest`
   - Primary language: English
   - Category: Health & Fitness

3. **Archive**
   - Xcode device menu: **Any iOS Device (arm64)**
   - Product → Archive
   - Organizer opens → **Distribute App** → App Store Connect → Upload

   Or from Terminal: `./scripts/testflight.sh archive export`

4. **TestFlight tab** in App Store Connect
   - Wait for build processing
   - Add yourself as internal tester
   - Install TestFlight app on iPhone → accept invite

## App Privacy (App Store Connect questionnaire)

- **Data collected**: Health & Fitness (not linked, not used for tracking)
- **No third-party SDKs** in this app
- Health data stays on device until you export via Share Sheet

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Signing failed | Set Team; unique bundle ID |
| Health data all null | Wear Apple Watch; check Health app has data; grant permissions |
| "Untrusted developer" | Settings → General → VPN & Device Management → Trust |
| Build fails on HealthKit | HealthKit capability must be enabled (already in entitlements) |

## Regenerate Xcode project

If you edit `project.yml`:

```bash
cd /Users/cameronro/Development/bioharvest
xcodegen generate
```
