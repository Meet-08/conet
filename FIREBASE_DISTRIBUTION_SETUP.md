# Firebase App Distribution — Setup Guide

Complete setup guide for the `build-and-distribute` GitHub Actions workflow.

---

## Prerequisites

- A Google account
- Admin access to the GitHub repository
- Flutter project builds locally with `flutter build apk --release`

---

## Step 1: Create a Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **Add project** → name it (e.g., `conet`)
3. Disable Google Analytics if not needed → **Create project**

---

## Step 2: Register the Android App

1. In Firebase Console → **Project settings** → **Add app** → **Android**
2. Enter your Android package name:
   - Find it in `conet_app/android/app/build.gradle.kts` under `namespace` or `applicationId`
   - Typically something like `com.example.conet_app`
3. Enter app nickname: `CoNet`
4. Skip the SHA-1 (only needed for Google Sign-In)
5. Click **Register app**
6. **Skip** the `google-services.json` download — click **Continue** through the remaining steps

> **Note**: `google-services.json` and Gradle plugin changes are only needed if your app uses Firebase SDKs (e.g., Firebase Auth, Firestore). Since this project uses Supabase, Firebase is only used as a distribution mechanism — no SDK integration required.

---

## Step 3: Enable Firebase App Distribution

1. In Firebase Console → left sidebar → **Release & Monitor** → **App Distribution**
2. Click **Get started**
3. Go to the **Testers & Groups** tab
4. Create a group called **`dev-testers`**
5. Add tester email addresses to this group
   - Testers will receive an email invitation to accept

> **Important**: Testers must accept the invitation before they can receive builds.

---

## Step 4: Create a Service Account for CI/CD

1. Go to [Google Cloud Console → IAM → Service Accounts](https://console.cloud.google.com/iam-admin/serviceaccounts)
2. Select your Firebase project
3. Click **Create Service Account**:
   - Name: `github-actions-distribution`
   - Role: **Firebase App Distribution Admin**
4. Click on the created service account → **Keys** tab
5. **Add Key** → **Create new key** → **JSON** → Download

### Encode the key for GitHub:

**On Linux/Mac:**

```bash
base64 -w 0 path/to/your-service-account-key.json
```

**On Windows (PowerShell):**

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("path\to\your-service-account-key.json"))
```

Copy the entire output — this is your `FIREBASE_SERVICE_ACCOUNT_KEY` secret.

---

## Step 5: Configure GitHub Secrets

Go to your GitHub repo → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

Add these secrets:

| Secret Name                    | Value                                                                                                     |
| ------------------------------ | --------------------------------------------------------------------------------------------------------- |
| `FIREBASE_APP_ID`              | From Firebase Console → Project settings → Your Android app → App ID (e.g., `1:123456789:android:abcdef`) |
| `FIREBASE_SERVICE_ACCOUNT_KEY` | Base64-encoded service account JSON from Step 4                                                           |
| `API_URL`                      | Your production backend URL                                                                               |
| `SUPABASE_URL`                 | Your Supabase project URL                                                                                 |
| `SUPABASE_ANON_KEY`            | Your Supabase anon key                                                                                    |

---

## Step 6: Verify the Pipeline

1. Push a commit to the `main` branch
2. Go to GitHub repo → **Actions** tab
3. Watch the `build-and-distribute` workflow run
4. Once complete:
   - Check Firebase Console → App Distribution → **Releases** for the uploaded APK
   - Testers in the `dev-testers` group will receive an email with the download link

---

## How Testers Install the APK

1. Tester receives an email from Firebase
2. Clicks the link → opens Firebase App Tester web page
3. First time only: installs the **Firebase App Tester** app (or downloads APK directly)
4. Downloads and installs the APK

> Testers do NOT need a Firebase account — just the email they were invited with.

---

## Troubleshooting

| Issue                                 | Solution                                                          |
| ------------------------------------- | ----------------------------------------------------------------- |
| Build fails at `flutter build apk`    | Ensure the app builds locally first                               |
| Firebase upload fails with auth error | Verify `FIREBASE_SERVICE_ACCOUNT_KEY` is correctly base64-encoded |
| Testers don't receive emails          | Ensure they accepted the initial Firebase invitation              |
| Wrong App ID                          | Copy from Firebase Console → Project settings → App ID            |
| `.env` file issues                    | Verify all env secrets are set in GitHub                          |

---

## Optional: Trigger Only on Tags

To build only on version tags instead of every commit, change the trigger in `build-and-distribute.yml`:

```yaml
on:
  push:
    tags:
      - "v*"
```

Then create builds with: `git tag v1.0.1 && git push --tags`
