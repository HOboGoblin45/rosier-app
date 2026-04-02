# Rosier App Store Submission Package

**Complete collection of all materials needed for App Store Connect submission**

Last Updated: April 2026
Prepared by: Dev 3
For: Charlie Cresci (Founder, Rosier Inc.)

---

## Overview

This submission package contains everything needed to submit Rosier to the Apple App Store. All documents are comprehensive, step-by-step, and designed to be followed by someone on Windows without needing a Mac.

---

## What's Included

### 📋 Document 1: App Store Connect Metadata
**File:** `app_store_connect_metadata.md`
**Purpose:** Complete metadata for Apple's App Store Connect
**Contains:**
- App name, subtitle, description (4000 char max)
- Keywords (100 char max)
- What's New release notes
- Promotional text
- Support/Marketing/Privacy URLs
- Privacy Nutrition Label mapping
- Age rating questionnaire
- Demo account credentials
- App Review notes for Apple's team
- Screenshots specifications
- Content rights information

**Time to Complete:** 30-45 minutes
**Action Items:** Copy/paste sections into App Store Connect
**Ready to Use:** Yes

---

### 📱 Document 2: Apple Developer Setup from Windows
**File:** `apple_developer_setup_windows.md`
**Purpose:** Step-by-step guide for Charlie to set up everything from Windows
**Contains:**
- Part 1: Apple Developer Program enrollment ($99)
- Part 2: App Store Connect setup (browser-based)
- Part 3: Bundle ID and app creation
- Part 4: Three options for code signing on Windows
  - Option A: GitHub Actions + Fastlane (RECOMMENDED)
  - Option B: Cloud Mac service ($2-5/hour)
  - Option C: Manual CSR with OpenSSL (advanced)
- Part 5: Building on Windows
- Part 6: Final submission steps
- Part 7: Troubleshooting guide

**Estimated Timeline:**
- Option A (GitHub Actions): 4-5 hours + 24-48 hour wait
- Option B (Cloud Mac): 2.5-3 hours + $3-10
- Option C (OpenSSL): 3-4 hours (complex)

**Time to Read:** 20-30 minutes
**Time to Execute:** 3-5 hours (depending on path chosen)
**Best For:** Charlie (Windows user, no Mac access)
**Ready to Use:** Yes

---

### ✅ Document 3: App Review Preparation
**File:** `app_review_preparation.md`
**Purpose:** Comprehensive preparation to pass Apple's review on first try
**Contains:**
- Common rejection reasons for shopping/fashion apps (10 categories)
- How Rosier avoids each rejection
- Affiliate link disclosure requirements (3-place requirement)
- Privacy manifest compliance checklist
- Required API usage justifications
- Login and demo account handling
- In-App Purchase policy compliance
- Metadata and screenshot accuracy verification
- Pre-submission testing checklist (8 phases)
- If rejected - response templates for each issue type

**Phase 1: Local Testing** — 40 minutes
**Phase 2: Device Testing** — 30 minutes
**Phase 3: Account Testing** — 10 minutes
**Phase 4: Affiliate Links** — 15 minutes
**Phase 5: Privacy/Security** — 10 minutes
**Phase 6: Offline Mode** — 5 minutes
**Phase 7: Metadata Check** — 5 minutes
**Phase 8: Full Journey** — 10 minutes

**Total Testing Time:** ~2 hours
**Ready to Use:** Yes - run all phases before submission

---

### 🧪 Document 4: Test Account Configuration
**File:** `test_account_configuration.md`
**Purpose:** Specification for the reviewer@rosier.app test account
**Contains:**
- Account credentials (email, password)
- Pre-populated test data:
  - 50 swipes across 8 brands
  - 12 saved dresser items
  - Completed Style DNA profile
  - Notification settings enabled
  - Dark mode enabled
- Backend seeding SQL
- Account verification checklist
- Post-launch cleanup instructions

**Setup Time:** 15 minutes (backend team)
**Verification Time:** 5 minutes (QA)
**Ready to Use:** Yes - hand to backend team for seeding

---

## How to Use This Package

### For Charlie (Founder):

**Step 1: Read the Windows Setup Guide (20 min)**
- File: `apple_developer_setup_windows.md`
- Understand the 3 code signing options
- Choose which option works for you

**Step 2: Complete Developer Enrollment (1 hour)**
- Follow Part 1-3 of Windows Setup Guide
- Enroll in Apple Developer Program ($99)
- Create App Store Connect app
- Register Bundle ID

**Step 3: Handle Code Signing (2-3 hours)**
- Follow your chosen option (A, B, or C)
- Option A (recommended): Set up GitHub Actions
- Option B: Rent a cloud Mac
- Option C: Use manual CSR method

**Step 4: Prepare Metadata (30-45 min)**
- File: `app_store_connect_metadata.md`
- Copy description, keywords, etc. from document
- Paste into App Store Connect
- Fill in all required fields

**Step 5: Verify Everything (2 hours)**
- File: `app_review_preparation.md`
- Run all 8 testing phases
- Verify metadata accuracy
- Check all links work

**Step 6: Submit (10 min)**
- Upload build to App Store Connect
- Fill in final metadata
- Add demo account info
- Click "Submit for Review"

**Total Time:** 6-8 hours (over several days) + 24-48 hour wait for approval

---

### For Dev Team:

**Step 1: Seed Test Account (15 min)**
- File: `test_account_configuration.md`
- Use provided SQL to populate reviewer@rosier.app
- Verify account has all test data

**Step 2: Run Pre-Submission Tests (2 hours)**
- File: `app_review_preparation.md`
- Complete all 8 testing phases
- Fix any issues found
- Sign off that app is ready

**Step 3: Support Charlie (as needed)**
- Help with code signing if needed
- Answer questions about documents
- Prepare build for upload

---

### For QA/Testing Team:

**Step 1: Verify Test Account (30 min)**
- File: `test_account_configuration.md`
- Log in with reviewer@rosier.app
- Verify all test data is present
- Verify all features accessible

**Step 2: Run Full Test Suite (2 hours)**
- File: `app_review_preparation.md`
- Complete all 8 testing phases
- Verify nothing crashes
- Sign off on readiness

---

## Document Dependencies

```
┌─────────────────────────────────────────┐
│ Apple Developer Setup (Windows)          │
│ - Required FIRST                         │
│ - Sets up account and app in App Store   │
│ - Needed before submission               │
└────────────────┬────────────────────────┘
                 │
    ┌────────────┴────────────┐
    │                         │
    ▼                         ▼
┌──────────────────┐  ┌─────────────────┐
│ Metadata         │  │ Test Account    │
│ (copy/paste      │  │ (seed DB)       │
│  into App Store) │  │                 │
└──────────────────┘  └─────────────────┘
    │                         │
    └────────────┬────────────┘
                 │
                 ▼
┌─────────────────────────────────────┐
│ App Review Preparation              │
│ - Testing & verification BEFORE     │
│ - Rejection avoidance               │
│ - Final quality check               │
└─────────────────────────────────────┘
                 │
                 ▼
          SUBMIT FOR REVIEW
```

---

## Submission Checklist

### Pre-Submission (Done Before Clicking Submit)

**Account Setup:**
- [ ] Apple Developer Program enrolled ($99 paid)
- [ ] Account approved (24-48 hour wait)
- [ ] App created in App Store Connect
- [ ] Bundle ID: com.rosier.app registered
- [ ] Tax & Banking info complete

**Metadata Completed:**
- [ ] App name: "Rosier"
- [ ] Subtitle: "Niche Fashion Discovery"
- [ ] Description: ~1,547 chars (from metadata doc)
- [ ] Keywords: "niche fashion, fashion discovery..." (from metadata doc)
- [ ] What's New: Version 1.0 release notes
- [ ] URLs: Support, Marketing, Privacy all valid
- [ ] Age rating: 4+
- [ ] Screenshots: 5+ at correct dimensions
- [ ] App icon: 1024x1024 PNG

**Build Ready:**
- [ ] Build uploaded to App Store Connect
- [ ] Build processing complete (green checkmark)
- [ ] Build number: 1
- [ ] Version: 1.0.0

**Testing Complete:**
- [ ] All 8 phases of testing completed
- [ ] No crashes on real device
- [ ] Demo account works: reviewer@rosier.app
- [ ] All affiliate links tested
- [ ] Offline mode works
- [ ] Dark mode works

**Review Info Added:**
- [ ] Demo account: reviewer@rosier.app / ReviewTest2026!
- [ ] App Review Notes: (from metadata doc, Section 5.2)
- [ ] Contact info: review@rosier.app
- [ ] Encryption: "No controlled information"
- [ ] IDFA: "No"
- [ ] Content Rights: "Yes"

**Final Verification:**
- [ ] All URLs tested and working
- [ ] Privacy Policy complete and valid
- [ ] Terms of Service includes affiliate disclosure
- [ ] Privacy manifest included in build
- [ ] No hardcoded secrets or test data
- [ ] Version number matches submission

### Submission Itself

- [ ] Navigate to "Prepare for Submission" in App Store Connect
- [ ] Review all sections one more time
- [ ] Click "Submit for Review" button
- [ ] Confirm "Yes, I'm ready to submit"
- [ ] Status changes to "Waiting for Review"
- [ ] Email received confirming submission

### After Submission

- [ ] Wait 1-3 days for review to start
- [ ] Wait 24-48 hours for review to complete
- [ ] Monitor email for "Approved" or "Rejected" notice
- [ ] If approved: App goes live on App Store
- [ ] If rejected: Follow response templates from Document 3

---

## Key Contacts

### For Charlie:
- Developer Account Support: developer.apple.com/contact/
- App Review Issues: Use App Store Connect Help (top right)
- Rosier Team: [Your team contact info]

### For Team:
- Apple Review Escalation: review@rosier.app
- Privacy Questions: privacy@rosier.app
- Technical Support: support@rosier.app

---

## FAQ

### Q: Can I submit from my Windows PC?
**A:** Yes! Use the GitHub Actions method in Document 2 (Option A). Builds run on Mac servers automatically.

### Q: How long does the review process take?
**A:** Typically 1-3 days in queue, then 24-48 hours being reviewed. Total: 2-5 days.

### Q: What if my app is rejected?
**A:** Use the response templates in Document 3. Fix the issue and resubmit. Most rejections are fixable in 1-2 hours.

### Q: Do I need a Mac?
**A:** Not if you use GitHub Actions (Document 2, Option A). If you prefer hands-on building, Option B (cloud Mac rental) is $2-5/hour.

### Q: When should I do this?
**A:** After the app is fully tested locally and stable. Plan for 6-8 hours of your time over 2-3 days.

### Q: What if something goes wrong?
**A:** All documents have troubleshooting sections. Check Document 3 (App Review Preparation) for common issues.

### Q: Can I submit on behalf of someone else?
**A:** The Apple Developer account must be in Charlie's name. He must enroll and authorize submission.

---

## Timeline Overview

```
DAY 1:
  Morning:  Read Document 2 (Apple Developer Setup)
  Midday:   Enroll in Apple Developer Program ($99)
  Evening:  Create App Store Connect app

DAY 2 (After account approval):
  Morning:  Set up code signing (GitHub Actions or cloud Mac)
  Midday:   Fill in metadata from Document 1
  Evening:  Run testing from Document 3

DAY 3:
  Morning:  Final verification
  Midday:   Build and upload
  Evening:  Submit for review

DAYS 4-8:
  Monitor App Store Connect for review status
  If approved: App live on store
  If rejected: Fix issue + resubmit (1-2 hours)
```

---

## Success Criteria

**You'll know you're done when:**

✓ App submitted to App Store (status: "Waiting for Review")
✓ Demo account working and accessible
✓ All metadata filled in accurately
✓ Build uploaded and processing complete
✓ Review notes provided for Apple team
✓ No pending questions or requests

**You'll know you've succeeded when:**

✓ Email from Apple: "Your app has been approved"
✓ App visible on App Store
✓ App searchable by keywords: "niche fashion", "fashion discovery"
✓ Users can download and install
✓ All metadata displays correctly

---

## What Comes After Submission

**While in Review (1-5 days):**
- Monitor email for updates
- Don't make major changes to app
- Be ready to respond to questions within 24 hours

**After Approval:**
- App goes live on App Store
- Monitor download numbers and reviews
- Respond to user feedback
- Plan v1.1 features (social sharing, wishlist collab, etc.)

**Future Updates:**
- Each app update must go through review again
- Process is same as initial submission
- Most updates approved within 24-48 hours

---

## Document Filenames for Reference

```
/docs/app_store_connect_metadata.md ........... Metadata for App Store
/docs/apple_developer_setup_windows.md ....... Setup guide for Charlie
/docs/app_review_preparation.md .............. Testing & rejection avoidance
/docs/test_account_configuration.md .......... Test account spec
/docs/SUBMISSION_PACKAGE_README.md ........... This file
```

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | April 2026 | Initial submission package for Rosier v1.0 |

---

## Summary

**You have everything you need to submit Rosier to the App Store.**

All four documents are:
- Comprehensive
- Step-by-step
- Practical and actionable
- Written for Windows users
- Ready to use immediately

**Next Steps:**
1. Charlie reads Document 2 (Windows setup)
2. Dev team reads Documents 1 & 3
3. Backend seeds test account (Document 4)
4. Complete testing (Document 3)
5. Submit (Document 2)
6. Launch!

**Questions?** Check the FAQ section in each document or reach out to the Rosier team.

---

**You're ready to ship! Good luck with the App Store submission.**
