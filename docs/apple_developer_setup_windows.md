# Apple Developer Account Setup from Windows

**Complete step-by-step guide for Charlie to set up Apple Developer account and submit Rosier to the App Store from a Windows PC**

Last Updated: April 2026
Audience: Charlie Cresci (Founder)

---

## Table of Contents

1. [Part 1: Apple Developer Program Enrollment](#part-1-apple-developer-program-enrollment)
2. [Part 2: App Store Connect Setup (Browser-Based)](#part-2-app-store-connect-setup-browser-based)
3. [Part 3: Bundle ID and App Creation](#part-3-bundle-id-and-app-creation)
4. [Part 4: Certificates & Code Signing (Windows Challenge)](#part-4-certificates--code-signing-windows-challenge)
5. [Part 5: Building on Windows](#part-5-building-on-windows)
6. [Part 6: Final Submission](#part-6-final-submission)
7. [Support & Troubleshooting](#support--troubleshooting)

---

## PART 1: Apple Developer Program Enrollment

### Step 1.1: Create/Verify Apple ID

**Prerequisite:** You need an Apple ID (personal, not business)

1. Go to https://appleid.apple.com
2. If you have an Apple ID, sign in
3. If not, click "Create an Apple ID" and follow prompts
4. Use your email: **crescicharles@gmail.com**
5. Note the Apple ID and password (you'll need it)

**⏱ Time: 5-10 minutes**

---

### Step 1.2: Enroll in Apple Developer Program

1. **Go to:** https://developer.apple.com/programs/enroll/
2. **Click:** "Enroll Now" (right side of page)
3. **Sign in** with your Apple ID (crescicharles@gmail.com)
4. **Choose entity type:**
   - Recommended for you: **Individual**
   - Why: Faster approval (24-48 hours), simpler setup
   - Alternative: Organization (3-5 days, requires business documentation)
5. **Select "Individual"** → Continue

**⏱ Time: 2 minutes**

---

### Step 1.3: Enter Personal Information

**You will fill out:**

```
Legal Name:           Charlie Cresci
Email Address:        crescicharles@gmail.com
Address:              [Your address]
City/State/ZIP:       [Your location]
Country:              United States
Phone:                [Your phone]
```

Important: Use your REAL name as it appears on government ID

**⏱ Time: 5 minutes**

---

### Step 1.4: Enter Payment Information

1. **Enrollment Cost:** $99 USD per year
2. **Payment method:** Credit card (Visa, Mastercard, AmEx)
3. **Information needed:**
   - Card number
   - Expiration date (MM/YY)
   - CVV (3-digit code on back)
   - Billing address

**⚠️ CRITICAL SECURITY NOTE:**
- Use YOUR personal credit card (not shared)
- Apple will charge $99 immediately
- Receipt will be emailed to you
- This confirms your enrollment

4. **Enter information** on the Apple payment page
5. **Click "Complete Purchase"**

**⏱ Time: 5 minutes**

---

### Step 1.5: Agree to Legal Agreements

After payment, you'll see Apple's legal agreements:

1. **Apple Developer Agreement and Program License Agreement** - Read and agree
2. **Apple Developer Program License Agreement** - Read and agree

**Required action:**
- Click checkbox: "I agree to the above terms and conditions"
- Click button: "Agree and Continue"

**⚠️ Important:** You MUST agree to these. These are binding agreements with Apple.

**⏱ Time: 5 minutes**

---

### Step 1.6: Email Verification

After enrollment:

1. **Check your email:** crescicharles@gmail.com
2. **Look for:** "Verify your Apple Developer Account" email from Apple
3. **Click the verification link** in the email
4. **Your status should now show:** "Active" or "Membership Active"

**Typical timeline:** 24-48 hours for approval

**During this time, you can proceed with the next sections to prepare.**

**⏱ Time: 5 minutes + 24-48 hours waiting**

---

## PART 2: App Store Connect Setup (Browser-Based)

### Step 2.1: Access App Store Connect

**Once your developer account is active:**

1. **Go to:** https://appstoreconnect.apple.com
2. **Sign in** with Apple ID: crescicharles@gmail.com
3. **Enter 2-factor authentication code** (sent to your device)
4. **You should now be at the App Store Connect dashboard**

**⏱ Time: 3 minutes**

---

### Step 2.2: Complete Tax and Banking Information

**REQUIRED before you can submit apps:**

1. **Navigate to:** Agreements, Tax, and Banking (left sidebar)
2. **Click:** "Agreement" tab
3. **Sign the required agreement:**
   - Paid Applications Agreement OR Free Applications Agreement
   - For Rosier (free app): Click **Free Applications Agreement**
   - Agree to terms
   - Click "Continue"

4. **Complete Tax Information:**
   - Go to **Tax** tab
   - Click "Add Tax Information" (if you see it)
   - You're a US Individual → No special tax setup needed for $99 income
   - If prompted, enter SSN or Individual Tax ID
   - Save

5. **Complete Banking Information (optional but recommended):**
   - Go to **Banking** tab
   - Add banking info IF you plan to earn money from affiliate revenue
   - For now, you can skip if you're not collecting revenue yet

**⏱ Time: 15-30 minutes**

---

### Step 2.3: Verify Your Account Details

1. **Go to:** Account Holder (top right corner) → Account
2. **Verify that you see:**
   - Apple ID: crescicharles@gmail.com
   - Full Name: Charlie Cresci
   - Status: **Active**
3. **Agreements tab shows:** Green checkmark next to Free Applications Agreement

**✓ You're now ready to create your app**

**⏱ Time: 3 minutes**

---

## PART 3: Bundle ID and App Creation

### Step 3.1: Create Bundle ID in Developer Portal

1. **Go to:** https://developer.apple.com/account/resources/certificates/list
2. **Sign in** with your Apple ID
3. **Navigate to:** Certificates, IDs & Profiles → Identifiers
4. **Click:** Blue "+" button (top left)
5. **Select:** App IDs
6. **Click:** Continue

**⏱ Time: 2 minutes**

---

### Step 3.2: Register App ID

**Fill out the form as follows:**

```
Platform:           iOS, iPadOS
Type:               App
Description:        Rosier Fashion Discovery App
Bundle ID:          com.rosier.app
```

**Select Capabilities (check these boxes):**
- ☑ Push Notifications
- ☑ Sign In with Apple
- ☑ Background Modes

**Click:** Continue → Register → Done

**⏱ Time: 3 minutes**

---

### Step 3.3: Create App in App Store Connect

1. **Go to:** https://appstoreconnect.apple.com
2. **Navigate to:** My Apps (top left)
3. **Click:** Blue "+" button → **New App**
4. **Fill out:**

```
Platform:               iOS
Name:                   Rosier
Primary Language:       English
Bundle ID:              com.rosier.app
SKU:                    ROSIER-APP-001
User Access:            Full Access
```

5. **Click:** Create

**⏱ Time: 3 minutes**

---

### Step 3.4: Fill in Basic App Information

1. **You're now in the app's settings**
2. **Go to:** App Information (left sidebar)
3. **Fill in:**

```
App Name:               Rosier
Subtitle:              Niche Fashion Discovery
Description:          [Copy from app_store_connect_metadata.md]
Keywords:             [Copy from metadata file]
Support URL:          https://rosier.app/support
Marketing URL:        https://rosier.app
Privacy Policy URL:   https://rosier.app/privacy
```

4. **Categories:**
   - Primary: Shopping
   - Secondary: Lifestyle

5. **Content Rights:** "Yes, my organization owns the rights"

6. **Click:** Save

**⏱ Time: 10 minutes**

---

## PART 4: Certificates & Code Signing (Windows Challenge)

### The Problem

You're on Windows, but:
- Xcode only runs on macOS
- Code signing requires iOS Distribution Certificate
- Provisioning profiles need to be created on Apple's server

### The Solution: Choose Your Path

There are three options. Pick ONE:

---

## OPTION A: Use GitHub Actions + Fastlane (RECOMMENDED for Windows)

### A.1: What This Does

Uses GitHub Actions (cloud-based) to:
- Generate certificates automatically
- Create provisioning profiles
- Build the app on a macOS runner
- Handle all the certificate complexity for you

**Pros:** No Mac needed, fully automated, industry standard
**Cons:** Requires GitHub account and repo

---

### A.2: Initial Setup (Do This ONCE)

**On your Windows PC:**

1. **Install Fastlane** (requires Ruby, or use pre-built installer)
   ```
   Download: https://docs.fastlane.tools/getting-started/ios/setup/
   Follow the Windows installation guide
   ```

2. **If using GitHub (recommended):**
   - Create free GitHub account: https://github.com/signup
   - Your repo should be: `github.com/yourname/rosier`
   - Push your iOS project to GitHub

3. **Generate App Store Connect API Key:**
   - Go to: https://appstoreconnect.apple.com/access/api
   - Click "+" button
   - Name: "Rosier-Fastlane"
   - Access Level: "Admin"
   - Click "Generate"
   - Download the key file (save it: `AuthKey_XXXXXXXXXX.p8`)
   - **KEEP THIS FILE SAFE** - it's like a password

**⏱ Time: 20-30 minutes**

---

### A.3: Create GitHub Actions Workflow

Create a new file in your repo:

```
Path: .github/workflows/build-and-submit.yml
```

**Content:**

```yaml
name: Build and Submit to App Store

on:
  workflow_dispatch:

jobs:
  build:
    runs-on: macos-latest

    steps:
    - uses: actions/checkout@v3

    - name: Setup Ruby
      uses: ruby/setup-ruby@v1
      with:
        ruby-version: '2.7'
        bundler-cache: true

    - name: Setup Fastlane
      run: |
        sudo gem install fastlane
        fastlane install_plugins

    - name: Build and Sign App
      env:
        APPLE_ID: ${{ secrets.APPLE_ID }}
        APPLE_ID_PASSWORD: ${{ secrets.APPLE_ID_PASSWORD }}
        APP_STORE_CONNECT_API_KEY: ${{ secrets.APP_STORE_CONNECT_API_KEY }}
      run: |
        cd ios/Rosier
        fastlane build_and_upload

    - name: Upload IPA to App Store Connect
      run: |
        fastlane upload
```

---

### A.4: Configure GitHub Secrets

1. **Go to:** GitHub repo → Settings → Secrets and variables → Actions
2. **Click:** "New repository secret"
3. **Add these secrets:**

   **Secret 1: APPLE_ID**
   - Name: APPLE_ID
   - Value: crescicharles@gmail.com

   **Secret 2: APPLE_ID_PASSWORD**
   - Name: APPLE_ID_PASSWORD
   - Value: [Your Apple ID password - 16-char app password, not your regular password]
   - How to create app password: https://support.apple.com/en-us/102654

   **Secret 3: APP_STORE_CONNECT_API_KEY**
   - Name: APP_STORE_CONNECT_API_KEY
   - Value: [Contents of your AuthKey_XXXXXXXXXX.p8 file]

**⏱ Time: 10 minutes**

---

### A.5: Run the Workflow

1. **Go to:** GitHub repo → Actions tab
2. **Select:** "Build and Submit to App Store" workflow
3. **Click:** "Run workflow" → "Run workflow" button
4. **Wait 30-60 minutes** while it builds on GitHub's Mac servers
5. **Check output** for "Build successful" message

**⏱ Time: 60 minutes (automated)**

---

## OPTION B: Use a Cloud Mac Service (Easier Setup)

### B.1: Rent a Mac for 1 Hour

Services:
- **MacStadium:** https://www.macstadium.com/ (pay-as-you-go)
- **MacInCloud:** https://www.macincloud.com/ (remote desktop)
- **Rent a Mac:** https://www.rentmac.com/ (hourly rental)

Typical cost: $2-5 per hour

### B.2: Steps

1. **Rent a Mac** for 1-2 hours
2. **SSH into the remote Mac**
3. **On the Mac, do these steps:**
   - Install Xcode (already installed on most Mac rentals)
   - Download your iOS project
   - Follow the standard macOS certificate setup (see SUBMISSION_GUIDE.md)
   - Generate distribution certificate
   - Create provisioning profile
   - Download both to local Mac
4. **Download the certificate and profile** to your Windows PC via email
5. **Done** - you can now close the Mac rental

**⏱ Time: 1-2 hours + cost**

---

## OPTION C: Manual CSR + OpenSSL on Windows (Advanced)

### C.1: What This Does

Creates a Certificate Signing Request (CSR) on Windows, uploads to Apple, and manages certificates without Xcode.

**Pros:** Works entirely on Windows
**Cons:** More steps, more manual work, error-prone

### C.2: Steps (Simplified)

1. **Generate CSR using OpenSSL (Windows):**

   Download Git Bash (includes OpenSSL): https://git-scm.com/download/win

2. **Open Git Bash and run:**
   ```bash
   openssl req -new -newkey rsa:2048 -nodes \
     -keyout rosier_private.key -out rosier.csr \
     -subj "/CN=Charlie Cresci/emailAddress=crescicharles@gmail.com/C=US"
   ```

3. **This creates two files:**
   - `rosier.csr` - Certificate Signing Request
   - `rosier_private.key` - Your private key (KEEP SAFE)

4. **Upload to Apple:**
   - Go to: https://developer.apple.com/account/resources/certificates/list
   - Click "+" to create new certificate
   - Upload rosier.csr
   - Apple signs it and you download the `.cer` file

5. **Convert to p12 (personal certificate format):**
   ```bash
   openssl pkcs12 -export -in certificate.cer \
     -inkey rosier_private.key \
     -out rosier_certificate.p12
   ```

6. **Use the .p12 file in your build**

**⏱ Time: 30-45 minutes (complex)**

---

### Recommendation

**Use Option A (GitHub Actions)** if you:
- Have a GitHub account (free)
- Want fully automated builds
- Don't want to rent a Mac

**Use Option B (Cloud Mac)** if you:
- Want to be hands-on
- Need to troubleshoot interactively
- Are willing to spend $2-5

**Use Option C (OpenSSL)** only if:
- You prefer maximum control
- You're comfortable with command-line tools
- You have experience with certificates

---

## PART 5: Building on Windows

### Scenario 1: Using GitHub Actions

**No Windows build needed.** The entire build happens on GitHub's Mac servers.

1. **Push your code to GitHub**
2. **Trigger the Actions workflow** (as described in Option A)
3. **Wait for it to complete**
4. **Download the built .ipa file** from the workflow output

**⏱ Time: 60 minutes (mostly waiting)**

---

### Scenario 2: Using a Cloud Mac

**Build on the cloud Mac:**

1. **SSH into the Mac**
2. **Download Rosier project**
3. **Follow standard Mac build steps:**
   ```bash
   cd ios/Rosier
   xcodebuild archive \
     -scheme Rosier \
     -configuration Release \
     -archivePath build/Rosier.xcarchive
   ```
4. **Export for App Store:**
   ```bash
   xcodebuild -exportArchive \
     -archivePath build/Rosier.xcarchive \
     -exportOptionsPlist ExportOptions.plist \
     -exportPath build/export
   ```
5. **Get the `Rosier.ipa` file**

**⏱ Time: 20-30 minutes on the Mac**

---

### Scenario 3: Building on Your Windows PC

**This requires Xcode, which only runs on Mac.**

**Alternative on Windows:**
- Install Xamarin.iOS (limited support, not recommended for SwiftUI)
- Use a Mac build server (like Option B)

**Not recommended for Rosier since it uses native SwiftUI**

---

## PART 6: Final Submission

### Step 6.1: Upload Build to App Store Connect

**From whatever build method you used:**

1. **You should have a .ipa file** (about 50-100 MB)

2. **Option 1: Use App Store Connect web interface**
   - Go to: https://appstoreconnect.apple.com
   - Your App → Build → Upload new build
   - Drag and drop the .ipa file
   - Wait 5-10 minutes for processing

3. **Option 2: Use Transporter app** (Apple's upload tool)
   - Download: https://apps.apple.com/us/app/transporter/id1450874784
   - (Runs on Mac, but you can run it briefly in a cloud Mac)

**⏱ Time: 15-20 minutes**

---

### Step 6.2: Fill in Version Information

1. **In App Store Connect, go to:** Prepare for Submission
2. **Fill in:**

   **What's New (Release Notes):**
   ```
   Welcome to Rosier — the fashion discovery app built for women who love niche brands.

   In this first release:
   • Swipe to discover fashion from niche and designer brands
   • Save your favorites to your personal digital dresser
   • Get personalized recommendations with Style DNA
   • Receive daily alerts about new collections
   • Shop directly through authorized retailers
   ```

   **Encryption Export:**
   - Select: "This app does not contain, use, or access any controlled information"

   **IDFA:**
   - Select: "No, this app does not request the App Tracking Transparency framework"

   **Content Rights:**
   - Select: "Yes, my organization owns the rights to all content in the app"

   **Age Rating:**
   - Select: 4+

3. **Click:** Save

**⏱ Time: 10 minutes**

---

### Step 6.3: Add Screenshots and Icon

1. **Screenshots:**
   - Go to: App Store → Localization → English (U.S.) → Screenshots
   - For each device type (iPhone 15, 16 Pro Max, etc.):
     - Click "Add Screenshot"
     - Upload PNG from `/docs/screenshots/output/`
     - Add optional description (1-2 lines)
   - Upload 5-10 screenshots (minimum 2)

2. **App Icon:**
   - Go to: App Store → Localization → English (U.S.) → App Preview
   - Upload 1024x1024 PNG icon

**⏱ Time: 20 minutes**

---

### Step 6.4: Add Test Account Info

1. **Go to:** Build section
2. **Scroll to:** "Test Information"
3. **Add Demo Account:**
   ```
   Email: reviewer@rosier.app
   Password: ReviewTest2026!
   Notes: Account is pre-populated with test data. Full access to all features.
   ```

**⏱ Time: 5 minutes**

---

### Step 6.5: Add App Review Notes

1. **Go to:** Build section
2. **Scroll to:** "App Review Information"
3. **Click in the Notes field**
4. **Paste the complete review notes from:** `app_store_connect_metadata.md` → Section 5.2

**⏱ Time: 5 minutes**

---

### Step 6.6: Final Check

Before submitting, verify:

**App Information:**
- [ ] App name: Rosier
- [ ] Subtitle: Niche Fashion Discovery
- [ ] Description: Present and compelling
- [ ] Keywords: Present and relevant
- [ ] Category: Shopping (primary), Lifestyle (secondary)

**URLs:**
- [ ] Support URL: Valid and accessible
- [ ] Marketing URL: Valid and accessible
- [ ] Privacy Policy URL: Valid and accessible

**Content:**
- [ ] Age Rating: 4+
- [ ] Screenshots: 5+ uploaded for at least one device type
- [ ] App Icon: 1024x1024 PNG uploaded
- [ ] Test Account: reviewer@rosier.app provided

**Metadata:**
- [ ] What's New: Filled in
- [ ] Build: Selected and processing complete
- [ ] Encryption Export: Answered
- [ ] IDFA: Answered
- [ ] Content Rights: Answered

**⏱ Time: 5 minutes**

---

### Step 6.7: SUBMIT FOR REVIEW

1. **In App Store Connect:**
2. **Click the "Submit for Review" button** (in Build section, near top)
3. **Confirm:** "Yes, I'm ready to submit this build for review"
4. **Status changes to:** "Waiting for Review"

**CONGRATULATIONS!** Your app is now in Apple's review queue.

---

## PART 7: Support & Troubleshooting

### Common Issues and Fixes

#### Issue: "Bundle ID not found"

**Cause:** You didn't register the Bundle ID in the Developer Portal

**Fix:**
1. Go to: https://developer.apple.com/account/resources/certificates/list
2. Click: Identifiers
3. Register Bundle ID: `com.rosier.app`
4. Try again in App Store Connect

---

#### Issue: "Provisioning profile is invalid"

**Cause:** Certificate expired or profile doesn't exist

**Fix:**
1. Go to Apple Developer Portal
2. Delete old provisioning profiles
3. Create new one:
   - Name: "Rosier Distribution"
   - Type: "App Store"
   - Bundle ID: "com.rosier.app"
   - Download and import

---

#### Issue: "Build processing is taking too long"

**Cause:** Apple's servers are busy (rare)

**Fix:**
- Wait up to 30 minutes
- If still stuck, contact Apple Support
- Reupload the IPA file

---

#### Issue: "App was rejected"

**Possible causes and fixes:**

| Rejection Reason | Fix |
|-----------------|-----|
| Crash on launch | Test on real device, fix, rebuild |
| Missing privacy policy | Add URL in App Info |
| Misleading screenshots | Replace with accurate ones |
| Missing demo account | Add reviewer@rosier.app |
| Incomplete affiliate disclosure | Add to Terms of Service |
| Missing privacy manifest | Ensure PrivacyInfo.xcprivacy is included in build |

**Resubmission:**
1. Fix the issue locally
2. Increment build number
3. Rebuild
4. Upload new build
5. Update What's New text
6. Submit again

---

### Apple Support Contacts

**If you get stuck:**

1. **In-app support:**
   - App Store Connect → Help (top right)
   - Submit a request with your issue

2. **Email:**
   - App Review: review@rosier.app (your contact)
   - Developer Support: https://developer.apple.com/contact/

3. **Community Forums:**
   - Apple Developer Forums: https://developer.apple.com/forums/

4. **Rosier Internal Support:**
   - Dev team: [Contact information]
   - Review notes: See `app_store_connect_metadata.md`

---

## Timeline Summary

### Option A (GitHub Actions) - Recommended
```
Day 1:
  - Enroll in Apple Developer Program: 30 min
  - Set up App Store Connect: 30 min
  - Create app in App Store Connect: 15 min
  - Set up GitHub Actions: 30 min

Day 2 (After Account Approval - 24-48 hours):
  - Create Bundle ID: 10 min
  - Generate API Key: 10 min
  - Run GitHub Actions: 60 min (automated)
  - Upload to App Store Connect: 15 min
  - Fill metadata: 30 min
  - Submit for Review: 5 min

TOTAL: ~4-5 hours of work + 1-2 days waiting for approval
```

### Option B (Cloud Mac)
```
Day 1:
  - Enroll in Apple Developer Program: 30 min
  - Set up App Store Connect: 30 min
  - Create app in App Store Connect: 15 min

Day 2 (After Account Approval):
  - Rent cloud Mac: 5 min
  - Build on cloud Mac: 45 min
  - Download IPA: 5 min
  - Upload to App Store: 15 min
  - Fill metadata: 30 min
  - Submit for Review: 5 min

TOTAL: ~2.5-3 hours + $3-10 Mac rental + 1-2 days waiting for approval
```

### Option C (OpenSSL)
```
Day 1:
  - Enroll in Apple Developer Program: 30 min
  - Set up App Store Connect: 30 min
  - Create app in App Store Connect: 15 min
  - Manual CSR and certificates: 60 min

Day 2 (After Account Approval):
  - Need a Mac for build (cloud or friend's)
  - Build on Mac: 45 min
  - Upload to App Store: 15 min
  - Fill metadata: 30 min
  - Submit for Review: 5 min

TOTAL: ~3-4 hours + $3-10 Mac rental + 1-2 days waiting for approval
```

---

## Final Checklist

### Before Submitting

- [ ] Apple Developer account is Active
- [ ] Tax and Banking information is complete
- [ ] App created in App Store Connect
- [ ] Bundle ID registered (com.rosier.app)
- [ ] Build uploaded and processing complete
- [ ] App name is "Rosier"
- [ ] Description is complete and compelling
- [ ] Keywords are filled in
- [ ] Screenshots uploaded for at least one device size
- [ ] App icon uploaded (1024x1024)
- [ ] Support URL is valid
- [ ] Privacy Policy URL is valid
- [ ] Marketing URL is valid
- [ ] Age rating is 4+
- [ ] Demo account info provided (reviewer@rosier.app)
- [ ] App Review notes are complete
- [ ] "What's New" text is filled in
- [ ] Encryption Export question answered
- [ ] IDFA question answered
- [ ] Content Rights question answered

### After Submission

- [ ] Status shows "Waiting for Review"
- [ ] Email received confirming submission
- [ ] Check back in 1-3 days for review completion
- [ ] Monitor email for approval or rejection notice

---

## Success!

Once approved, your app will be:
1. Available on the App Store
2. Searchable for keywords like "niche fashion"
3. Visible on Rosier's app page
4. Ready for users to download

---

**Questions?** Contact the Rosier team or Apple Developer Support at https://developer.apple.com/contact/
