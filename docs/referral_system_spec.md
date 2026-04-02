# ROSIER REFERRAL SYSTEM SPEC
**Viral Loop Mechanics | Backend + Frontend Design**

---

## EXECUTIVE SUMMARY

The referral system is the core viral growth engine. Target: **0.3+ viral coefficient** (each user brings 0.3-0.4 additional users).

**Key Mechanic:** Unlock premium features by inviting friends. Make referrals frictionless, rewarding, and shareable.

---

## USER JOURNEY

### Trigger Point (Day 1 of App)
1. User completes onboarding
2. Swipes through 10-15 items
3. System generates personalized "Style DNA" card
4. **Prompt appears:** "Share your Style DNA with friends. Unlock exclusive features!"

### Referral Action (Day 1-7)
1. User taps "Share with Friends" button
2. Modal shows:
   - Personal referral code: `ROSIER_[USER_ID]_[6_CHAR_CODE]` (e.g., `ROSIER_john_abc123`)
   - Copy code button
   - Share buttons: iMessage, WhatsApp, Instagram DM, Discord
   - Custom message: "I found your next favorite niche brands on Rosier. Use code [CODE] to get early access to style discoveries. ✨"
3. User shares via preferred channel

### Friend Receives Invite (Day 1-14)
1. Friend sees code + link in message
2. Taps link → App Store → Downloads app
3. App opens to custom invite screen: "You were invited by [Name]"
4. Shows referrer's Style DNA card + "What you'll unlock together"
5. Friend signs up, enters code at account creation screen

### Reward Unlocked (Immediate)
1. **Referrer sees:** "Sarah joined! You're 1 invite away from unlocking Style DNA Share."
2. **Referred friend sees:** "Unlock features as you invite friends" (gamification)
3. Both users get **referral streak bonus** (every 3 in a row = bonus XP)

### Future Invites (Day 8+)
1. User sees "Invites" tab on home screen
2. Shows: "You've invited 2 friends | 1 more for Next Reward"
3. Leaderboard: "You're #47 this month! Invite 3 more for top 10"
4. Each invite shows: Status (pending/completed), date, username of friend

---

## REWARD TIERS

### Tier 1: 1 Successful Invite
**Unlock: Style DNA Shareable Card**
- Aesthetic card showing: User's dominant style (e.g., "Dark Academia 👩‍🎓"), top 5 brands, vibe emoji
- Card is shareable to Instagram Stories (with referral code embedded as QR code)
- Card is screenshot-able for TikTok/Pinterest
- Instagram Story template with user's data + CTA: "Download Rosier"

**Why This Reward:**
- Low barrier to first invite (1 friend)
- Immediately shareable (extends reach)
- Instagram Stories = viral distribution
- QR code = trackable conversions

---

### Tier 2: 3 Successful Invites
**Unlock: Early Access to Daily Drop (24-hour early access to new brands)**
- Every day at 6 AM, new emerging brands drop
- Non-members see drops at 10 AM (4-hour delay)
- Members with 3+ invites get 6 AM early access
- Exclusive notification: "Your brands are dropping in 1 hour"
- Competitive advantage: First to see emerging brands, first to save before others

**Why This Reward:**
- Creates repeat engagement (daily)
- Drives daily app opens
- Makes referral worthwhile (tangible feature, not just cosmetic)
- Encourages referrer to bring high-quality friends (who'll also invite)

---

### Tier 3: 5 Successful Invites
**Unlock: Founding Member Badge (Permanent, Visible in Community)**
- Purple/gold badge on user's profile (visible to all)
- Profile bio badge: "👑 Founding Member"
- Featured in "Top Referrers" leaderboard (in-app and monthly email)
- "You're in the top 500 referrers of all time" (social proof)
- Exclusive Discord role + channel access

**Why This Reward:**
- Status reward (psychology: people want to be seen)
- Permanent (badge doesn't go away, long-term motivation)
- Community recognition (drives more invites for status)
- Discord access = deeper community engagement

---

### Tier 4: 10 Successful Invites
**Unlock: VIP Dresser Features**
- VIP Dresser brand: 1 personalized style consultation per month (async video or chat)
- Priority support: Dedicated Slack channel for VIP Dressers + team responses within 4 hours
- Exclusive brand early access: See new brands 48 hours before general users
- Monthly VIP Dresser call: Group video chat with founder + top community members (networking)
- VIP-only Discord channel: Network with 50-100 other power users

**Why This Reward:**
- Exclusive, high-status (only top 1-2% of users reach this)
- Drives long-term engagement (monthly consultation, calls)
- Network effect (VIP dressers become advocates, drive more referrals)
- Creates "aspirational" tier (users want to reach it)

---

### Future Tier (Months 3+): 25 Successful Invites
**Unlock: Brand Ambassador Status**
- $100/month stipend (paid via Stripe)
- Co-marketing opportunities (featured in campaigns)
- Lifetime VIP status
- Commission on brand affiliate sales (if brand partners are launched)

**Why This Reward:**
- Monetizes top referrers (sustainable long-term incentive)
- Extends growth indefinitely (ambassadors recruit indefinitely)
- See Phase 3 of grassroots_marketing_plan.md for details

---

## BACKEND IMPLEMENTATION

### Data Model

```sql
-- Users table (existing, add referral fields)
ALTER TABLE users ADD COLUMN (
  referral_code VARCHAR(20) UNIQUE NOT NULL,  -- e.g., ROSIER_john_abc123
  referred_by VARCHAR(20) REFERENCES referral_codes(code),  -- invite code that brought them
  referral_count INT DEFAULT 0,  -- count of successful referrals
  created_at TIMESTAMP DEFAULT NOW()
);

-- Referral tracking table
CREATE TABLE referrals (
  id UUID PRIMARY KEY,
  referrer_id UUID NOT NULL REFERENCES users(id),
  referred_user_id UUID REFERENCES users(id),  -- NULL if invite not yet completed
  code VARCHAR(20) NOT NULL UNIQUE,  -- the code this referral is using
  status ENUM('pending', 'completed', 'expired') DEFAULT 'pending',
  created_at TIMESTAMP DEFAULT NOW(),
  completed_at TIMESTAMP,  -- when referred user signed up
  expires_at TIMESTAMP,  -- 90 days from created_at
  FOREIGN KEY (referrer_id) REFERENCES users(id)
);

-- Reward unlock tracking
CREATE TABLE user_reward_tiers (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id),
  tier INT NOT NULL (1, 3, 5, 10, 25),  -- unlocked at this invite count
  unlocked_at TIMESTAMP DEFAULT NOW(),
  reward_status ENUM('active', 'claimed', 'expired') DEFAULT 'active',
  UNIQUE(user_id, tier)
);

-- Leaderboard cache (optional, for performance)
CREATE TABLE leaderboard_monthly (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id),
  month_year VARCHAR(10),  -- e.g., "2026-04"
  invites_this_month INT DEFAULT 0,
  rank INT,
  updated_at TIMESTAMP DEFAULT NOW() ON UPDATE NOW(),
  UNIQUE(user_id, month_year)
);
```

### API Endpoints

**1. Generate Referral Code**
```
POST /api/referrals/generate-code
Authorization: Bearer [JWT_TOKEN]

Response:
{
  "code": "ROSIER_john_abc123",
  "shareUrl": "https://rosier.app/invite?code=ROSIER_john_abc123",
  "qrCode": "data:image/png;base64,..."
}
```

**2. Validate Referral Code**
```
GET /api/referrals/validate?code=ROSIER_john_abc123

Response:
{
  "valid": true,
  "referrer": {
    "id": "user_123",
    "name": "John",
    "styleDna": { ... },
    "invitesCount": 2
  },
  "reward": "unlock_daily_drop_early_access"
}
```

**3. Complete Referral (On Signup)**
```
POST /api/referrals/complete
Authorization: Bearer [JWT_TOKEN]
Content-Type: application/json

{
  "referral_code": "ROSIER_john_abc123"
}

Response:
{
  "success": true,
  "referrer_reward": {
    "tier": 1,
    "unlocked_feature": "style_dna_share",
    "next_threshold": 3
  },
  "referred_reward": {
    "bonus_xp": 10,
    "bonus_saves": 5
  }
}
```

**4. Get User Referral Status**
```
GET /api/user/referrals/status
Authorization: Bearer [JWT_TOKEN]

Response:
{
  "referral_code": "ROSIER_john_abc123",
  "total_invites": 5,
  "completed_invites": 4,
  "pending_invites": 1,
  "current_tier": 3,
  "next_tier": 5,
  "invites_until_next_tier": 1,
  "leaderboard_rank": 47,
  "leaderboard_month": "2026-04",
  "rewards_unlocked": [
    {
      "tier": 1,
      "feature": "style_dna_share",
      "unlocked_at": "2026-04-02T14:30:00Z"
    },
    {
      "tier": 3,
      "feature": "daily_drop_early_access",
      "unlocked_at": "2026-04-10T08:15:00Z"
    }
  ]
}
```

**5. Get Leaderboard**
```
GET /api/leaderboard?month=2026-04&limit=100
Authorization: Bearer [JWT_TOKEN]

Response:
{
  "month": "2026-04",
  "leaderboard": [
    {
      "rank": 1,
      "user_id": "user_456",
      "name": "Sarah",
      "invites": 23,
      "badge": "👑 Top Referrer",
      "reward_tier": "VIP Dresser"
    },
    {
      "rank": 2,
      "user_id": "user_789",
      "name": "Alex",
      "invites": 18,
      "badge": "🏅 Silver Referrer",
      "reward_tier": "Founding Member"
    },
    ...
  ],
  "your_rank": 47
}
```

**6. Update Referral Status (Backend Job)**
```
-- Daily job: Check if pending referrals have been completed
SELECT * FROM referrals WHERE status = 'pending' AND expires_at > NOW()

-- For each pending:
  -- Check if referred_user_id has made first app open (or first swipe)
  -- If yes, mark as 'completed', increment referrer's referral_count
  -- Trigger reward_checker job (see below)
  -- Send push notification to referrer: "[Friend] joined! You earned [XP]"

-- For expired (90 days): Mark as 'expired'
```

**7. Check Reward Thresholds (Backend Job)**
```
-- After referral is marked 'completed':
SELECT referral_count FROM users WHERE id = referrer_id

-- For each tier (1, 3, 5, 10, 25):
  -- If referral_count >= tier AND tier NOT IN (already unlocked):
    -- INSERT into user_reward_tiers
    -- Send push notification: "You unlocked [FEATURE]!"
    -- Send email: "Congratulations, you unlocked [FEATURE]"
    -- Add to Discord if applicable
```

---

## FRONTEND IMPLEMENTATION

### 1. Invite Button (Home Screen)
**Location:** Bottom of home screen, always visible

```
┌─────────────────────────────┐
│  Your Rosier Feed          │
│  ═════════════════════════ │
│  [Swipeable Cards]        │
│  [Swipeable Cards]        │
│  [Swipeable Cards]        │
│                            │
│ ┌──────────────────────── │
│ │ 📤 Invite Friends      │  ← Button (large, visible)
│ │ [Invites: 2 | 1 more]  │
│ └──────────────────────── │
└─────────────────────────────┘
```

**Tap Action:**
- Opens "Share with Friends" modal (see below)
- If already clicked today, show: "Shared today! Tap again to share another friend"

---

### 2. Share Modal

```
┌──────────────────────────────┐
│  Share Rosier with Friends   │
├──────────────────────────────┤
│                              │
│  Your Referral Code:         │
│  ┌────────────────────────┐  │
│  │ ROSIER_john_abc123     │  │ ← Large, tappable to copy
│  └────────────────────────┘  │
│  [📋 Copy Code]              │
│                              │
│  Or Share Directly:          │
│  [iMessage] [WhatsApp] [DM]  │
│  [Discord] [Instagram]       │
│                              │
│  Invite Progress:            │
│  ████░░░ 2 / 3 invites       │ ← Visual progress bar
│  1 more to unlock Daily Drop │
│                              │
│  Custom Message:             │
│  ┌────────────────────────┐  │
│  │ I found your next      │  │ ← Pre-filled, editable
│  │ favorite niche brands  │  │
│  │ on Rosier. Use code    │  │
│  │ [CODE] ✨              │  │
│  └────────────────────────┘  │
│                              │
│ [Share] [Cancel]             │
└──────────────────────────────┘
```

**Share Methods:**
- **Copy Code:** Copies to clipboard with toast: "Code copied! Paste in chat"
- **iMessage:** Opens Messages app with pre-filled text
- **WhatsApp:** Opens WhatsApp with pre-filled message
- **Instagram DM:** Copy code, user opens DM manually (iOS limitation)
- **Discord:** Copy code, user opens Discord manually
- **Email:** Opens Mail with pre-filled subject + body

---

### 3. Invite Tracking Tab

**Location:** Second tab, "Invites" screen

```
┌──────────────────────────────┐
│  Your Invites                │
├──────────────────────────────┤
│                              │
│ Progress to Next Tier:       │
│ ████████░░░░░░ 5 / 10        │
│ Unlock: VIP Dresser Features │
│                              │
│ This Month's Leaderboard:    │
│ You're #47 (9 invites)       │
│ [View Full Leaderboard]      │
│                              │
│ ─────── Active Invites ─────  │
│ ✓ Sarah (Completed)          │
│   Joined Apr 2 | #47 referrer│
│                              │
│ ✓ Marcus (Completed)         │
│   Joined Mar 28              │
│                              │
│ ⏳ Alex (Pending)            │
│   Invited Apr 10 | Expires.. │
│   7 days left                │
│                              │
│ ⏳ Jordan (Pending)          │
│   Invited Apr 8 | Expires..  │
│   5 days left                │
│                              │
│ [Invite More Friends]        │
└──────────────────────────────┘
```

**Functionality:**
- Click on completed invite → See friend's profile, Style DNA
- Click pending → Resend invite link
- Leaderboard tap → Full monthly leaderboard (name, invites, badge)

---

### 4. Leaderboard Screen

```
┌──────────────────────────────┐
│  April 2026 Referrers        │
├──────────────────────────────┤
│                              │
│ YOUR RANK: #47               │
│ Your invites: 9              │
│ Reward tier: Founding Member │
│                              │
│ ─────────────────────────── │
│ 🥇 1. Sarah (👑)             │
│    Invites: 23               │
│    Tier: VIP Dresser         │
│    "Top Referrer"            │
│                              │
│ 🥈 2. Alex                   │
│    Invites: 18               │
│    Tier: Founding Member     │
│                              │
│ 🥉 3. Jamie (💜)             │
│    Invites: 16               │
│    Tier: Founding Member     │
│                              │
│ 4. Casey                     │
│    Invites: 14               │
│    Tier: Daily Drop Access   │
│                              │
│ 5. Morgan                    │
│    Invites: 12               │
│    Tier: Daily Drop Access   │
│                              │
│ ───────────────────────────  │
│ 47. You (JOHN)               │
│     Invites: 9               │
│     Tier: Founding Member    │
│                              │
│ [Invite Friends to Climb]    │
└──────────────────────────────┘
```

**Gamification Elements:**
- Emojis for top 3 (🥇🥈🥉)
- Highlight user's position
- Show tier badges
- "You're 1 away from top 50" nudge

---

### 5. Style DNA Shareable Card Screen

**Triggered:** After Tier 1 unlocked (1st successful invite)

```
┌──────────────────────────────┐
│ Your Style DNA Card          │
├──────────────────────────────┤
│                              │
│ ┌──────────────────────────┐ │
│ │                          │ │
│ │  Dark Academia 👩‍🎓       │ │ ← Top 3 styles
│ │  Quiet Luxury            │ │
│ │  Y2K Revival             │ │
│ │                          │ │
│ │ YOUR FAVORITE BRANDS:    │ │
│ │ • Khaite                 │ │
│ │ • Jacquemus              │ │
│ │ • The Row                │ │
│ │ • Ganni                  │ │
│ │ • SSENSE                 │ │
│ │                          │ │
│ │ Discover brands like     │ │
│ │ yours on Rosier          │ │
│ │                          │ │
│ │ ┌──────────────────────┐ │
│ │ │ [QR: Download App]   │ │ ← QR code to download + referral
│ │ └──────────────────────┘ │
│ │                          │ │
│ │ rosier.app/invite?...    │ │
│ │                          │ │
│ └──────────────────────────┘ │
│                              │
│ [Share to Instagram Stories] │
│ [Share to TikTok]            │
│ [Share to Pinterest]         │
│ [Download as Image]          │
│ [Copy Share Link]            │
└──────────────────────────────┘
```

**Share Methods:**
- **Instagram Stories:** Opens Stories with card as sticker, user adds text/hashtags
- **TikTok:** Copy card, user uploads to TikTok manually (iOS limitation)
- **Pinterest:** Create pin with card image, user pins to fashion board
- **Download:** Save high-res PNG to Photos (for manual sharing)
- **Copy Link:** Share link that opens web version (fallback for any platform)

---

## NOTIFICATION STRATEGY

### Push Notifications (In-App Only, No Spam)

**1. Friend Joined (Immediate)**
```
"🎉 [Friend Name] joined! You're on your way to [NEXT REWARD]."
```
- Tap → Navigate to Invites tab
- Max 1 per day (batch if multiple friends join)

**2. Reward Unlocked**
```
"🏆 Unlocked: Daily Drop Early Access (24-hour head start on new brands)"
```
- Tap → Navigate to unlock details
- Sent immediately when tier is reached

**3. Daily Drop Ready (If Tier 2+)**
```
"⏰ Your emerging brands drop in 1 hour"
```
- Sent at 5:55 AM (if user has daily drop access)
- Drives daily app opens

**4. Leaderboard Milestone**
```
"🚀 You're now in the top 50 referrers! Keep inviting."
```
- Sent once per month when rank improves
- Motivates continued referrals

### Email Notifications (Weekly Digest)

**1. Weekly Referral Summary (Every Monday)**
```
Subject: "Your Rosier invites this week: +2 friends 👋"

Body:
- You've invited [X] friends total
- [Y] completed, [Z] pending
- You're #[RANK] this month
- Next reward: [INVITES_UNTIL_NEXT_REWARD] invites away
- Leaderboard rank: [RANK_EMOJI] #[RANK]

CTA: "Invite More Friends" → Share modal in app
```

---

## EDGE CASES & BUSINESS RULES

### Referral Expiration
- **Validity:** Code valid for 90 days from creation
- **If Expired:** User can generate new code, old code becomes inactive
- **User Message:** "Your code expired. Generate a new one" (soft notification, no punishment)

### Fraud Prevention
- **Max Invites Per Day:** 20 per user (prevents botting)
- **Min Time Between Invites:** 2 hours (prevents mechanical clicking)
- **Device Check:** If referred user has same device as referrer, flag as potential fraud (manual review)
- **Rate Limiting:** Max 100 referral codes generated per user per month

### Reward Consistency
- **Rewards Persist:** If user achieves Tier 1, loses Tier 2 later (impossible), but Tier 1 reward stays forever
- **Tier Progression:** Tiers are cumulative (you can't "lose" a tier)
- **Monthly Reset:** Leaderboard resets monthly, historical leaderboard is archived

### Referred User Dropoff
- **Pending → Expiry:** If friend never opens app, invite marked "expired" after 90 days
- **No Punishment:** Referrer still gets credit (we want to incentivize trying)
- **Metric Tracking:** Separate "sent", "completed", "converted" for analysis

---

## METRICS TO TRACK

### Primary (Weekly)
- Referral conversion rate: % of invites that become completed signups
- Viral coefficient: New users from referrals / total new users
- Invite-to-reward ratio: How many invites until first reward claimed
- Tier penetration: % of users unlocking each tier

### Secondary (Monthly)
- Cohort analysis: Do referred users have higher LTV than organic?
- Feature adoption: % of Tier 1 users who share Style DNA card
- Leaderboard engagement: % of users checking leaderboard
- Reward claim rate: Do users care about rewards we're offering?

### Tracking Implementation
```
// In-app events to log (PostHog):
posthog.capture('referral_code_shared', {
  share_method: 'instagram_dm',  // or 'copy_code', 'whatsapp', etc
  tier_current: 2,
  invites_count: 5,
  timestamp: Date.now()
})

posthog.capture('referral_completed', {
  referrer_id: user_id,
  referred_user_id: new_user_id,
  time_to_completion_days: 3,  // how long after invite
  referrer_invites_total: 6,
  referrer_reward_tier_unlocked: 3  // if applicable
})

posthog.capture('reward_tier_unlocked', {
  tier: 5,
  user_id: user_id,
  invites_count: 5,
  days_to_unlock: 12
})
```

---

## ROLLOUT PLAN

### Phase 1 (Launch Week)
- Basic referral code generation + tracking
- Copy code, manual share
- Simple reward tier (1, 3, 5, 10)

### Phase 2 (Weeks 2-4)
- Style DNA shareable card (Tier 1 unlock)
- Native share buttons (iMessage, WhatsApp, Instagram)
- Leaderboard (top 100)
- Push notifications

### Phase 3 (Month 2+)
- Email marketing integration (weekly summaries)
- Advanced fraud detection
- Monthly leaderboard reset + archive
- Tier 25+ ambassador program (monetization)

---

## FAQ

**Q: Can users game the system?**
A: Built-in fraud checks:
- Max 20 invites/day
- Device fingerprinting (flag suspicious patterns)
- 90-day expiry (encourages real friends, not mass farming)
- Manual review of top referrers

**Q: What if a referred user deletes the app?**
A: Referral is still "completed" (they signed up). Referrer gets credit.

**Q: Can two users refer each other?**
A: Yes, but system logs both. Analytics track "mutual referrals" separately.

**Q: What if someone loses their referral code?**
A: Users can regenerate code anytime in Invites tab. Old code deactivates.

**Q: How do we prevent spam in Discord referral channel?**
A: MEE6 bot mutes users who spam invites. Manual review by mods.

---

## SUCCESS METRICS

**Green Flags (You're Winning):**
- Viral coefficient ≥ 0.25 by Week 2
- 30%+ of users reach Tier 1 by Month 1
- 10%+ of users reach Tier 3 by Month 2
- 50%+ of Tier 1 users share Style DNA card
- Leaderboard engagement rate ≥ 20% (users checking rankings)

**Red Flags (Needs Iteration):**
- Viral coefficient < 0.1 by Week 2 → Messaging is weak, share friction too high
- <10% reach Tier 1 → Rewards not compelling
- <3% reach Tier 3 → System is too hard
- >20% fraud rate → Bots/gamers, tighten rules

---

Last Updated: April 1, 2026
Next Review: April 15, 2026 (after launch Week 2)
