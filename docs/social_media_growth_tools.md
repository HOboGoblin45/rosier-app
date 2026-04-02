# Social Media Growth Tools for Rosier
## Organic Growth Strategy & Open-Source Stack

**Last Updated**: April 2026
**Status**: Comprehensive Guide for Zero-Budget Social Media Growth
**Target Platforms**: Instagram + TikTok (Primary), Threads, LinkedIn (Secondary)

---

## Section 1: Open-Source Tools

### A. Content Scheduling Platforms

#### Mixpost (Recommended for Rosier)
- **GitHub**: https://github.com/inovector/mixpost
- **GitHub Stars**: 3.5K+
- **Last Updated**: Actively maintained (2026)
- **What it does**: Self-hosted social media management platform for scheduling and publishing content across 10+ social networks
- **Platforms supported**: Instagram, Facebook, TikTok, X (Twitter), LinkedIn, Threads, Bluesky, Mastodon, YouTube
- **Self-hosted requirements**: Laravel, PHP 8.1+, MySQL/PostgreSQL, Docker recommended
- **Risk level**: SAFE - Uses official APIs where available; no automation flags
- **Setup difficulty**: Moderate (Docker setup takes 30 mins)
- **Rosier-specific use case**: Schedule Reels, carousel posts, and TikTok content across multiple channels from one dashboard. Post versions feature lets you tailor captions per platform
- **Pricing**: $299 one-time for self-hosted (no recurring fees)
- **Key features**:
  - Team collaboration workspaces
  - Post versions for platform-specific content
  - Scheduled comments automation (safe engagement)
  - Analytics and performance tracking
  - Bulk scheduling and content calendar

#### Postiz (Modern Alternative)
- **GitHub**: https://github.com/gitroomhq/postiz-app
- **GitHub Stars**: 4.2K+
- **License**: Apache 2.0
- **Last Updated**: Actively maintained (2026)
- **What it does**: All-in-one agentic social media scheduling with AI-assisted content creation
- **Platforms supported**: 30+ platforms including Instagram, TikTok, LinkedIn, Facebook, Threads
- **Self-hosted requirements**: Docker, Node.js, minimal CPU/RAM
- **Risk level**: SAFE - Official API integrations, no detection risks
- **Setup difficulty**: Easy (Docker compose provided)
- **Rosier-specific use case**: Combine with n8n for workflow automation (trending audio detection → auto-schedule to Reels)
- **Pricing**: Free self-hosted (pay only for cloud infrastructure ~$5-15/mo) OR $23/month managed cloud
- **Key features**:
  - Canva-like design editor for graphics and video
  - AI content generation
  - Bulk content upload and scheduling
  - Multi-channel analytics
  - Integrations with Make.com, n8n, Zapier for workflow automation

#### Socioboard
- **GitHub**: https://github.com/socioboard/Socioboard-5.0
- **What it does**: Open-source social media management and analytics platform
- **Platforms supported**: Facebook, Instagram, Twitter, LinkedIn, YouTube, TikTok
- **Risk level**: SAFE - Public API focus
- **Setup difficulty**: Moderate
- **Rosier-specific use case**: Team analytics dashboard if scaling to multiple team members managing accounts

### B. Instagram Content Libraries

#### Instagrapi (Primary)
- **GitHub**: https://github.com/subzeroid/instagrapi
- **GitHub Stars**: 4K+
- **PyPI**: https://pypi.org/project/instagrapi/
- **Last Updated**: Actively maintained (2026)
- **What it does**: Fast, powerful Python library for Instagram Private API access
- **Risk level**: MODERATE - Unofficial API; Instagram can adjust reverse-engineered endpoints
  - **Safety notes**: Good for scheduled posting, reading feed, insights. Avoid aggressive automation like mass-liking or commenting
  - **Best practices**: Use longer delays between actions (5-10 second gaps), don't exceed 100 interactions/hour
- **Installation**: `pip install instagrapi`
- **Rosier-specific use case**: Programmatically post Stories, Reels, and carousel posts; pull analytics; read comments for sentiment analysis
- **Code example**:
  ```python
  from instagrapi import Client
  cl = Client()
  cl.login(username, password)
  cl.clip_upload(video_path, caption="Check out our latest style picks!")
  ```

#### aiograpi (Async Alternative)
- **GitHub**: https://github.com/subzeroid/aiograpi
- **What it does**: Asynchronous version of Instagrapi for concurrent operations
- **Use case**: Scaling to multiple Reels/Stories per day without blocking

#### instagram_private_api
- **GitHub**: https://github.com/ping/instagram_private_api
- **What it does**: Python wrapper for Instagram's private app API
- **Risk level**: MODERATE - Same reverse-engineering risks as Instagrapi
- **Rosier-specific use case**: Alternative if Instagrapi endpoints fail; has smaller feature set but stable

### C. TikTok Content Libraries

#### TiktokAutoUploader
- **GitHub**: https://github.com/makiisthenes/TiktokAutoUploader
- **What it does**: Automatically edits and uploads videos to TikTok via CLI
- **Requirements**: TikTok login credentials
- **Risk level**: RISKY - Direct browser automation; TikTok actively detects automation
  - **Warning**: Use sparingly; space uploads 24+ hours apart minimum
  - **Best practice**: Test with side account first
- **Setup difficulty**: Moderate (uses requests instead of Selenium, which is faster)
- **Rosier-specific use case**: Batch upload pre-recorded content during off-peak hours

#### tiktok-uploader (Recommended)
- **GitHub**: https://github.com/wkaisertexas/tiktok-uploader
- **PyPI**: https://pypi.org/project/tiktok-uploader/
- **What it does**: Automatic TikTok video uploader using Playwright automation
- **Requirements**: Python >=3.10
- **Risk level**: MODERATE-RISKY - Browser automation detected; use with caution
  - **Spacing rule**: Max 1 video per 24 hours to avoid action blocks
  - **Account requirement**: Phone-verified, established account (>100 followers recommended)
- **Rosier-specific use case**: Nightly upload of pre-created content; pair with CapCut export pipeline

#### TikTok API (Official - Read-Only)
- **URL**: https://developers.tiktok.com/
- **What it does**: Official TikTok business/creator APIs for analytics and limited publishing
- **Risk level**: SAFE - Official, no ban risk
- **Limitation**: Posting via official API requires TikTok Shop or advanced account status
- **Rosier-specific use case**: Pull analytics on video performance, hashtag trends, audience demographics

#### TikTokApi (Unofficial Python Wrapper)
- **GitHub**: https://github.com/davidteather/TikTok-Api
- **PyPI**: https://pypi.org/project/TikTokApi/
- **What it does**: Python wrapper for TikTok trending data, user info, video metadata
- **Risk level**: SAFE for read-only; data extraction only
- **Rosier-specific use case**: Scrape trending audio/hashtags on fashion niche to inform content creation

### D. Content Creation Tools (Free/Open-Source)

#### CapCut (Free Desktop + Mobile)
- **URL**: https://www.capcut.com/
- **Cost**: 100% free (no watermark, no premium tier required for basic use)
- **What it does**: AI-powered video editor with auto-captions, transitions, effects, and templates
- **Rosier-specific use case**:
  - Create Reels: 15-30 second fashion clips with trending audio, auto-captions
  - Create TikToks: 30-60 second try-on videos, style tips, app demos
  - Auto-caption feature is critical for algorithm reach on both platforms
- **Key features for Rosier**:
  - Free trending templates (updates weekly)
  - Auto-caption with 95%+ accuracy (multi-language support)
  - Green screen/background removal
  - Batch editing (edit multiple videos simultaneously)
  - Direct export to TikTok/Instagram at platform-native aspect ratios
- **Workflow**: Film on phone → Import to CapCut → Add trending audio/captions → Export → Upload

#### FFmpeg (Command-line Video Processing)
- **GitHub**: https://github.com/FFmpeg/FFmpeg
- **Cost**: Free, open-source
- **Use case**: Batch convert video formats, resize for different platforms, compress videos for faster upload
- **Example**: `ffmpeg -i input.mp4 -vf scale=1080:1920 -c:v libx264 -c:a aac output.mp4`

### E. Analytics & Insights (Free Options)

#### Native Platform Insights
- **Instagram**: Creator Studio + Creator Account (free)
  - Reach, impressions, saves, shares, DM engagement
  - Best time to post analytics
  - Hashtag performance
  - Reel performance vs. feed posts
- **TikTok**: Creator Center (free with Pro account)
  - Video analytics (views, watch time, shares, favorite)
  - Audience demographics, location, device
  - Engagement rate by video
- **Rosier-specific use case**: Track which content types drive app installs (track via UTM parameters in bio link)

#### BrandMentions Free Hashtag Tracker
- **URL**: https://brandmentions.com/hashtag-tracker/
- **Cost**: Free version available
- **Use case**: Real-time hashtag performance tracking; see what hashtags get engagement for fashion/app niches

#### Social Rails Hashtag Research Tool
- **URL**: https://socialrails.com/free-tools/hashtag-research-tool
- **Cost**: Free
- **Use case**: Research Instagram/TikTok hashtag difficulty and trends; identify micro-niche hashtags (5K-50K search volume = sweet spot)

#### Inflact AI Hashtag Generator
- **URL**: https://hashtagsforlikes.com/ (or https://inflact.com/)
- **Cost**: Free version
- **Use case**: Generate hashtag recommendations from image upload; better than manual hashtag research

---

## Section 2: Safe Organic Growth Tactics

### Instagram Reels Strategy

**Algorithm Priority (2026)**: DM sends > Saves > Shares > Comments > Likes > Views

**Content Formula**:
1. **Hook (First 3 seconds)**: Eye-catching text overlay, pattern interrupt, or question
   - Example: "POV: You open Rosier and find your dream style in 3 swipes"
   - Example: "Biggest fashion mistake? Not knowing this app exists"

2. **Hook Ideas for Fashion App**:
   - Before/after outfit transformations (user perspective)
   - "POV: You're tired of endless scrolling" (problem/solution format)
   - "Styling a [type of event] with Rosier" (how-to format)
   - Trend-jacking (participate in trending sounds/audio)
   - "Unpopular opinion:" openers (engagement bait, but works)

3. **Body (15-60 seconds)**: Deliver promised content
   - App demo with trending music
   - Styling tips with product close-ups
   - Micro-influencer testimonials (early user quotes)
   - "Swipe right if you'd wear this" (low friction engagement)

4. **CTA (Last 3 seconds)**: Clear call-to-action
   - "Link in bio to try Rosier for free"
   - "Save this for your next date night outfit"
   - "Tag someone who needs this app"
   - "DM me for early access"

**Reels Best Practices**:
- **Length**: 7-30 seconds for discovery, 30-90 seconds for deeper engagement
- **Audio**: Use trending audio (check TikTok trending first; trends migrate to Reels 3-5 days later)
- **Captions**: Add subtitles/keywords for SEO (Reels now indexed by Google)
- **Posting frequency**: 2 Reels + 1 carousel post per day
- **Posting times**: Tuesday-Thursday, 11 AM-1 PM, 7-9 PM (highest engagement for 18-35 female demographic)

**Hashtag Strategy**:
- Use 8-15 hashtags (Instagram limit is 30, but quality >quantity)
- Mix hashtag sizes:
  - Mega hashtags (1M+ posts): #FashionApp, #StyleApp
  - Mid-tier (100K-1M): #FashionDiscovery, #MicroInfluencer
  - Niche (5K-100K): #IndieHeartFashion, #SwipeableStyle
- Test hashtags in comments 1-2 minutes after posting (algorithm prioritizes early engagement)

### TikTok Content Formula for Fashion Apps

**Algorithm Priority (2026)**: Watch time > Completion rate > Shares > Comments > Favorites

**Content Types with Highest ROI**:

1. **Try-On Hauls** (30-60 seconds)
   - Film in natural lighting
   - Quick transitions between outfits
   - Include size/fit commentary
   - Example: "Unboxing my first @rosierapp haul"

2. **"Fit Checks" & Styling Tips** (20-45 seconds)
   - Show outfit from different angles
   - Provide honest commentary
   - Trending audio in background
   - Example: "Can I make this thrifted piece trendy? Let @rosierapp judge"

3. **App Demo & Navigation** (30-60 seconds)
   - Walkthrough the swipe mechanism
   - Show how easy it is to discover styles
   - Trending overlay text
   - Example: "Found a 10/10 fit in 2 minutes on Rosier"

4. **Micro-Influencer Testimonials** (15-30 seconds)
   - Frame as organic endorsement
   - Include real reactions
   - Encourage re-sharing

5. **Trending Sounds Participation** (15-45 seconds)
   - Monitor TikTok For You Page daily
   - Participate in trending sounds with app twist
   - Example: If sound is "Tell me without telling me," respond with "Tell me without telling me you use Rosier"

**TikTok Best Practices**:
- **Posting frequency**: 2-3 videos per day (algorithm rewards consistency; spread out 6-8 hours apart)
- **Best posting times**: Wednesday & Friday 6-9 AM (fashion niche), evening 6-9 PM (secondary window)
- **Video length**: 30-60 seconds optimal (longer for storytelling, shorter for immediate hooks)
- **Quality**: Vertical video, 1080x1920 or 720x1280, 9:16 aspect ratio
- **Trending audio importance**: 70% of high-performing TikToks use trending audio (updated hourly)
- **Hashtag strategy**: 3-5 relevant hashtags (TikTok doesn't weight hashtags as heavily as Instagram)

**Trending Audio Strategy**:
- Check Sound page daily in TikTok Creator Center
- Use TikTokApi (Python library) to scrape trending sounds in fashion niche programmatically
- Set reminder to capture trending sounds before they peak (usually 3-5 day lifespan)
- Create multiple variations of same concept with different trending audios

### Comment Engagement Strategy (Manual but High-ROI)

**Why**: Comments are low-weight engagement signals but create algorithm re-distribution. Replying to comments in first 24 hours boosts reach by 15-25%.

**Process**:
1. Post content at optimal time
2. Every 30-60 minutes for first 6 hours, manually reply to ALL comments
3. Keep replies friendly, on-brand, 2-3 sentences max
4. Include light CTA: "Love this! Try Rosier 👇"
5. Example interaction:
   - Comment: "What's your styling trick?"
   - Reply: "Start with a statement piece and build around it! Rosier makes this SO easy because you can see how others styled the same item. Link in bio ✨"

**Time investment**: 15 minutes per post → 30+ replies = 15-25% reach multiplier

### Collaboration & Duet Strategy with Micro-Influencers

**Micro-influencer definition**: 1K-50K followers (NOT 100K+ macro-influencers; higher engagement rate, more affordable)

**Collaboration types**:
1. **Duets (TikTok)**: Respond to their try-on content with your Rosier perspective
2. **Comments (Instagram)**: Tag them in Reels, encourage duets/comments
3. **Paid Barter Gifting**: Send free early access + Rosier credit in exchange for 3-5 posts

**DM Outreach Process**:
- Identify 100 micro-influencers in fashion niche using Instagram/TikTok search (1K-20K followers)
- Send personalized DM (NOT template):
  ```
  Hey [Name]! Love your recent [specific video/reel].
  Building Rosier (a style discovery app) for people like you.
  Would love to send early access for free if you want to try it out.
  No strings attached—honest feedback is all we ask!
  ```
- Expect 5-10% response rate
- Those who respond get early access + affiliate link (10-15% commission on referrals)

### Hashtag Research Methodology

**Weekly process** (2 hours):
1. Use Social Rails free hashtag research tool
2. Identify 20-30 target hashtags in layers:
   - Branded: #RosierApp, #RosierStyle
   - Category: #FashionApp, #StyleDiscovery
   - Niche: #SwipeableFashion, #IndieHeartFashion, #MicroInfluencerStyle
   - Problem-focused: #TiredOfEndlessScrolling, #FashionDecisionFatigue
3. Track performance in spreadsheet:
   - Hashtag | Monthly posts | Engagement rate | Competition level
4. Rotate hashtags monthly; double down on 5-7 highest performers

**Tools**:
- Free: Social Rails, Inflact, BrandMentions hashtag tracker
- Identify long-tail hashtags (10K-100K volume) that have less competition but still good reach

### Best Posting Times for Fashion Content

**Instagram Reels**:
- **Highest engagement**: Tuesday-Thursday, 11 AM-1 PM, 7-9 PM
- **Secondary windows**: Wednesday 8 PM, Friday 6 PM
- **Time zone note**: Post according to YOUR AUDIENCE timezone, not your local time
- Use Instagram Insights to verify (Creator Account → Insights → Audience → Most active times)

**TikTok Videos**:
- **Fashion niche specific**: Wednesday-Friday 6-9 AM, 6-9 PM
- **General**: Tuesday-Thursday 8 AM & 8 PM
- **Time zone**: Post when your audience is waking up or post-work wind-down
- Test different times and track analytics for first 2 weeks

**Posting cadence**:
- Instagram: 1-2 posts + 2 Reels per day (spread 6 hours apart)
- TikTok: 2-3 videos per day (spread 6-8 hours apart)
- Consistency matters more than frequency; pick sustainable schedule

### Cross-Platform Repurposing Workflow

**From TikTok → Instagram Reels** (3-5 day lag):
- TikTok trends first
- Monitor top 10 TikTok videos in fashion niche daily
- Recreate similar format on Rosier for Instagram Reels 3-5 days later
- Reels algorithm rewards "new" takes on trending formats

**Content batching workflow**:
1. **Monday-Tuesday**: Film 10-15 short clips (30-60 sec) with phone in vertical format
2. **Wednesday**: Edit in CapCut with trending audio (batch 5 at a time)
3. **Thursday**: Upload to TikTok (3 videos)
4. **Friday-Saturday**: Adapt 2-3 TikTok videos for Instagram Reels
5. **Sunday**: Reschedule via Mixpost for next week

**Format conversions**:
- TikTok video (1080x1920) → Instagram Reel (1080x1920) = 1:1 aspect ratio ✓
- Both optimal for vertical mobile viewing
- No format conversion needed between platforms

---

## Section 3: Influencer Seeding (Zero Cost)

### Identifying Micro-Influencers (1K-50K Followers)

**Manual discovery method** (2-3 hours per week):
1. Search Instagram for hashtags your audience uses:
   - #IndieHeartFashion
   - #SustainableFashion
   - #StyleOver30
   - #MicroInfluencerStyle
2. Filter for accounts with:
   - 1K-50K followers (optimal sweet spot: 5K-20K)
   - Engagement rate >3% (likes+comments / followers)
   - Consistent posting (at least 1 post per week)
   - Audience similar to Rosier target (women 18-35, fashion-focused)
3. Save 100+ accounts to a spreadsheet with:
   - Handle | Follower count | Niche | Average engagement | Email/DM handle

**Tools**:
- Instagram search + manual spreadsheet (free)
- Optional paid tools: Hunter.io (to find business emails), Linktree (to get email from bio)
- BrandMentions offers free influencer identification features

**Quality check**:
- Avoid accounts with fake followers (use https://www.instagram.com/accountanalysis/ free check)
- Verify recent posts have real comments (not bot-like activity)
- Check if they've previously partnered with brands (credibility indicator)

### Gifting vs. Affiliate Commission Models

**Model 1: Pure Gifting (Best for Launch)**
- **Cost**: Early access to app + optional $50-100 gift card credit
- **Pitch**: "We're launching Rosier and want authentic feedback from creators like you"
- **Outcome**: 1 post + 3-5 stories, honest reviews
- **Best for**: Building initial social proof and content library
- **Expected reach**: 100K-500K combined impressions from 20 micro-influencers

**Model 2: Affiliate Commission (Best for Growth)**
- **Cost**: 10-15% commission on referred installs/purchases
- **Pitch**: "Free early access + earn commission on referrals"
- **Outcome**: Ongoing promotion as long as they're earning
- **Incentive structure**:
  - Share unique affiliate link (via bit.ly or custom short URL)
  - Track clicks + installs in spreadsheet
  - Pay commission monthly (min $50 threshold)
- **Expected conversion**: 1-3% of their audience converts to app install
  - 20K followers × 1% = 200 installs/month
  - 200 installs × $5 app value = $1000/month in value created
  - $150 commission/month reasonable

**Model 3: Hybrid (Recommended)**
- Initial gifting ($50 credit) + ongoing 10% commission on referrals
- Incentivizes both initial post and long-term promotion

### DM Outreach Templates

**Template 1: Cold Outreach (Best first message)**
```
Hey [First name]!

Love your recent [specific post/reel]. Your style is exactly what we're building for.

We're launching Rosier—an app that makes fashion discovery actually fun (no endless scrolling).
Think swipe-based, trend-focused, for people like you.

Would love to send you early access. Completely free—we'd just love genuine feedback.

[Your name]
Rosier Founder
```

**Template 2: Follow-up (If no response in 3 days)**
```
Hey [Name]—quick follow-up in case you missed my last message!

Rosier launches in [timeframe]. Early access is still available if you're interested.

No pressure if it's not your thing. Either way, keep crushing it with your content! 💯
```

**Template 3: Affiliate Pitch (After initial positive response)**
```
Thanks for trying Rosier! So glad you love it.

We're working with creators like you to build the community.
Want to partner? Share your link and earn 15% commission on each install.

Easy URL to share: [affiliate link]

Details in this doc: [one-pager with commission structure]
```

**Template 4: Collaboration Pitch (If they're highly engaged)**
```
[Name], your Rosier review got crazy engagement!

Quick ask: Would you want to collab on a [specific idea: duet series, styling challenge, ambassador program]?

We could offer [incentive: monthly stipend, free premium access, higher commission].

Thoughts?
```

### How to Use the App Itself as the "Gift"

**Psychology**: Access to exclusive/new products is powerful currency, even at no cost.

**Positioning**:
- "You're in the top 1% of creators we're inviting to early access"
- "Free premium access for 3 months" (implies normal version is paid)
- "Limited early access: only inviting 100 creators"

**Implementation**:
1. Create special "Creator" account tier (visible in app)
   - Free premium features for 3 months
   - Badge on profile: "Creator Partner"
   - 10% commission on referred users (tracked via unique code)
2. Send DM with:
   - Download link
   - Creator code (unique discount code for their followers)
   - How to activate Creator status
3. Follow up at 1 week, 2 weeks, 1 month to gather testimonials

**Expected outcome**:
- 1 post per influencer = 500 app downloads per 100 micro-influencers
- 5% of downloads = 25 paying users (assuming $3-5 monthly subscription)
- 25 users × $4 × 3 months = $300 LTV vs. $50 gifting cost = 6x ROI

---

## Section 4: Content Calendar Template

### 30-Day Launch Content Calendar (Instagram + TikTok)

**Week 1: Teaser & Concept**

| Day | Platform | Content Type | Concept | Hook/Caption |
|-----|----------|--------------|---------|--------------|
| Mon | TikTok | App concept | "POV: Designer finds perfect outfit in 3 swipes" | "Tired of endless scrolling?" |
| Mon | Instagram | Teaser post | Behind-the-scenes mockup | "Swipe right for the future of fashion" |
| Tue | TikTok | Problem-solution | "Fashion problem: decision paralysis" | "How Rosier solves this..." |
| Tue | Instagram | Reel | Founder philosophy | "Why we built Rosier" |
| Wed | TikTok | Founder intro | Casual intro video | "Hi, I'm [Name]. Built Rosier for you" |
| Wed | Instagram | Carousel post | 3-5 benefits of app | "5 reasons fashion lovers need this" |
| Thu | TikTok | Trend jack | Participate in trending sound | "[Sound] = me finding outfits on Rosier" |
| Thu | Instagram | Reel | Trending audio + app demo | 7-second app walkthrough |
| Fri | TikTok | UGC concept | Friend reaction to app | "My friend found her style in 5 minutes" |
| Fri | Instagram | Story series | 24-hour countdown | "Rosier launches soon..." |
| Sat-Sun | Both | Engagement push | Ask questions in comments | "What's your fashion struggle?" |

**Week 2: Launch & User Testimonials**

| Day | Platform | Content Type | Concept | Hook/Caption |
|-----|----------|--------------|---------|--------------|
| Mon | TikTok | Official launch | "Rosier is LIVE" announcement | "The app you've been waiting for" |
| Mon | Instagram | Launch post + Reel | Grid post + video | "Rosier is here" |
| Tue | TikTok | Influencer 1 | Micro-influencer try-on | Feature first partner creator |
| Tue | Instagram | Carousel | Early user testimonials | "What creators are saying" |
| Wed | TikTok | Styling tips | "How to use Rosier" tutorial | "Step-by-step guide" |
| Wed | Instagram | Reel | Trending sound + app demo | Recreate trending format |
| Thu | TikTok | Influencer 2 | Another micro-influencer | Different creator, same love |
| Thu | Instagram | Carousel | App features breakdown | "How it works" education |
| Fri | TikTok | Before/after | Outfit transformation | "Before Rosier vs. After" |
| Fri | Instagram | Reel | Engagement bait | "Swipe right if you'd wear this" |
| Sat-Sun | Both | Community engagement | Repost user content | Feature early users |

**Week 3: Educational Content & Growth**

| Day | Platform | Content Type | Concept | Hook/Caption |
|-----|----------|--------------|---------|--------------|
| Mon | TikTok | Styling tips | "How to make this work" | Fashion advice content |
| Mon | Instagram | Reel | Trending format | Participate in trending trend |
| Tue | TikTok | Q&A | Answer common questions | "How to find your style" |
| Tue | Instagram | Carousel | Style tips + Rosier integration | Educational content |
| Wed | TikTok | Unboxing/haul | Product feature | "Styling this piece" |
| Wed | Instagram | Reel | Trend jack | Trending sound + app mention |
| Thu | TikTok | Influencer 3 | Third creator partner | Different niche/style |
| Thu | Instagram | Post | Behind-the-scenes | Team/office culture |
| Fri | TikTok | Challenge concept | Propose fashion challenge | "Style challenge: [name]" |
| Fri | Instagram | Reel | Challenge response | Participate in own challenge |
| Sat-Sun | Both | User-generated content | Repost + feature users | Community celebration |

**Week 4: Momentum & Conversion Focus**

| Day | Platform | Content Type | Concept | Hook/Caption |
|-----|----------|--------------|---------|--------------|
| Mon | TikTok | Success story | Early user milestone | "Downloaded 10K times!" |
| Mon | Instagram | Milestone post | Growth celebration | "Look how far we've come" |
| Tue | TikTok | Limited offer | Early adopter incentive | "Free premium for first month" |
| Tue | Instagram | Carousel | Limited-time offer (visually appealing) | "Only this week" |
| Wed | TikTok | Social proof | Montage of user reactions | "Reactions to Rosier" |
| Wed | Instagram | Reel | Trending audio + testimonials | Multi-user testimonial edit |
| Thu | TikTok | Feature deep-dive | Detailed tutorial | "Advanced Rosier features" |
| Thu | Instagram | Carousel | Advanced features guide | Educational |
| Fri | TikTok | Influencer 4 | Fourth creator reveal | Biggest partner yet |
| Fri | Instagram | Reel | Trending + high-production | Best quality content |
| Sat-Sun | Both | Final push | Daily engagement | Comment replies, stories, DMs |

### Content Type Breakdown (by platform)

**Instagram Content Mix (30 days)**:
- 8-10 Reels (2-3 per week)
- 4-5 carousel posts
- 4-5 single grid posts
- 14+ Stories (2 per day)
- 7+ Saved moments/Guides

**TikTok Content Mix (30 days)**:
- 20-25 videos (2-3 per day)
- Mix: 30% trend-jacking, 30% educational, 20% entertainment, 20% direct promotion

### Content Pillars for Rosier

**Pillar 1: "How It Works" (25% of content)**
- App demo, walkthroughs, feature explainers
- Goal: Reduce friction, show ease of use

**Pillar 2: "Style Inspiration" (30% of content)**
- Styling tips, outfit ideas, trend participation
- Goal: Provide value beyond app

**Pillar 3: "Community & Social Proof" (25% of content)**
- User testimonials, creator features, community wins
- Goal: Build trust, show product-market fit

**Pillar 4: "Direct Promotion" (20% of content)**
- Download CTAs, limited offers, app features
- Goal: Drive installs, conversions

---

## Section 5: Recommended Tech Stack

### Complete $0-$50/Month Stack

**Tier 1: Content Creation (FREE)**
- **Video editing**: CapCut desktop (free, no watermark)
- **Graphic design**: Canva free (basic templates)
- **Audio selection**: TikTok Sounds API (track trending)
- **Caption generation**: CapCut AI (built-in)

**Tier 2: Scheduling & Publishing (FREE or $299 one-time)**
- **Primary**: Mixpost self-hosted (free, $299 for premium features)
  - Deploy on Railway.app (free tier) or Heroku (~$5-10/mo)
  - Or single $299 one-time payment for full features
- **Backup**: Postiz self-hosted (free, pay only for infrastructure)

**Tier 3: Analytics & Monitoring (FREE)**
- **Instagram**: Native Creator Studio insights
- **TikTok**: Native Creator Center analytics
- **Hashtag tracking**: Social Rails free tool
- **Spreadsheet tracking**: Google Sheets (free)

**Tier 4: Influencer Outreach (FREE)**
- **Manual outreach**: Instagram/TikTok DMs
- **Tracking**: Google Sheets
- **Email finding**: Hunter.io free tier (10 searches/mo)

**Tier 5: Automation & Workflow** (Optional)
- **n8n self-hosted** (free, open-source): Connect Mixpost → TikTokApi → trending sound alerts
- **Zapier free tier**: Instagram new comments → Google Sheets (basic automation)

### How These Tools Work Together

**Daily Workflow**:
```
Morning: Check trending audio/hashtags (15 mins)
  ↓
TikTok Creator Center + TikTokApi library check
  ↓
Identify trending sounds for fashion niche
  ↓
Batch create content (60 mins)
  ↓
Film 2-3 short videos
  ↓
Edit in CapCut with trending audio (45 mins)
  ↓
Mixpost scheduling (15 mins)
  ↓
Schedule 1 TikTok + 1 Reel for next day
  ↓
DM outreach to 10-15 micro-influencers (30 mins)
  ↓
Respond to comments on existing posts (30 mins)
  ↓
Total: ~3 hours/day of work
```

**Weekly Optimization**:
- Monday: Analyze previous week's performance
- Tuesday: Plan week's content themes
- Wednesday: Batch shoot content
- Thursday: Edit and schedule
- Friday: Monitor engagement, adjust strategy
- Sat-Sun: Engagement push (comment replies, DM conversations)

### Cost Breakdown

| Tool | Cost | Purpose |
|------|------|---------|
| CapCut | Free | Video editing |
| Canva | Free (or $13/mo pro) | Graphics |
| Mixpost | $0 (self-hosted, free tier) or $299 (one-time) | Scheduling |
| Postiz | $0 (self-hosted) or $23/mo cloud | Scheduling backup |
| n8n self-hosted | $0 (free, open-source) | Automation |
| Instagrapi | $0 | Instagram API access |
| TikTokApi | $0 | TikTok data access |
| Social Rails | Free | Hashtag research |
| Google Sheets | Free | Tracking |
| **TOTAL** | **$0-$50/month** | **Complete stack** |

### Expected Reach vs. Paid Ads

**Organic (This Stack)**:
- 30 days of consistent posting
- 2-3 Reels/day + 2-3 TikToks/day
- 10-15 micro-influencer partnerships
- Expected reach: 100K-300K impressions/month
- Expected app downloads: 500-1500 (assuming 0.5-1% click-through)
- Cost: $0 (time only)

**Paid Ads (Meta/TikTok)**:
- Same timeframe
- Expected reach: 500K-1M impressions/month (4x more)
- Expected app downloads: 2000-5000 (4x more)
- Cost: $2000-5000 (at $2-5 CPM)

**Hybrid (Recommended)**:
- 60% organic (this stack) = 1000 downloads
- 40% paid ads ($500-800) = 500-1000 downloads
- Total: 1500-2000 downloads/month
- Cost: $500-800
- Sweet spot between efficiency and scale

---

## Section 6: Risk Assessment & Safety Guidelines

### Tools by Ban Risk Level

**GREEN (Safe)**:
- Mixpost ✓ (official APIs)
- Postiz ✓ (official APIs)
- CapCut ✓ (no API use)
- Native platform scheduling (Creator Studio, Creator Center)
- Hashtag research tools ✓
- Manual DM outreach ✓

**YELLOW (Moderate Risk)**:
- Instagrapi (unofficial API, reversible endpoints)
- aiograpi (unofficial API)
- instagram_private_api (unofficial API)
- BrandMentions (scraping)
- **Mitigation**: Use sparingly, add delays, avoid aggressive automation

**RED (High Risk - Avoid for Primary Account)**:
- TiktokAutoUploader (direct browser automation)
- tiktok-uploader (Playwright automation, easily detected)
- Mass follow/unfollow bots (explicitly banned)
- Auto-liking/commenting bots (explicitly banned)
- **Recommendation**: Test on side account first; use manual content posting on primary account

### Instagram Automation Safety Rules (2026)

**SAFE PRACTICES**:
- Use Creator Studio for scheduling (official Instagram tool)
- 1-2 posts + 2 Reels per day maximum
- Manual comment replies (stay below 100 interactions/day)
- DM rate: max 50-100 per day (spread across 8+ hours)
- Delay 5-10 seconds between API calls
- Post from consistent geographic location (IP address)
- Enable 2FA and phone verification

**BANNED PRACTICES**:
- Auto-follow/unfollow (action blocking within 24 hours)
- Mass liking/commenting (shadowban risk)
- DM automation >200 per hour (rate-limited since Oct 2024)
- Multiple accounts on same browser/IP (geographic inconsistency flag)
- Scraping user data, follower lists, hashtag likers
- Engagement pods/ring exchanges
- False engagement (buying followers/likes)

### TikTok Automation Safety Rules (2026)

**SAFE PRACTICES**:
- Manual content uploads (1 video per day max)
- Native TikTok Studio scheduling
- Engagement: 30-50 manual comments/day
- DMs: Manual only
- 24-48 hour spacing if using automation tools
- Never upload from VPN (geographic inconsistency)

**BANNED PRACTICES**:
- Bot likes/comments (suspension within 24-48 hours)
- Automated uploads (1+ per day detected as bot activity)
- Following/unfollowing automation
- Comment/DM bulk automation
- Scraping For You Page data
- Using 3rd-party scheduling without official TikTok shop/business account

### Account Health Checklist

**Before deploying any automation**:
- [ ] Phone number verified
- [ ] 2FA enabled
- [ ] Email verified
- [ ] Profile 100% complete (bio, photo, website link)
- [ ] 1+ week of organic posting history (warm account)
- [ ] Age: Account 30+ days old (minimum "good standing" period)
- [ ] No previous violations or warnings
- [ ] Geographic consistency (posting from same region)

**While using tools**:
- [ ] Monitor action blocks (warning sign: can't like/comment for 24 hours)
- [ ] Check shadowban status weekly (search hashtags, see if you appear)
- [ ] Keep manual activity high (50%+ manual vs. automated)
- [ ] Avoid peak automation times (post human-like schedules)
- [ ] Maintain 1-2 week organic content buffer (if API breaks, have fallback)

**If action block occurs**:
1. Stop all automation immediately
2. Switch to 100% manual activity for 3-7 days
3. Engage with comments manually, like other accounts
4. Don't delete content
5. Wait for restriction to lift (usually 24-48 hours)

### Monitoring & Alert System

**Weekly checks** (20 minutes):
- Instagram: Check Insights for reach/engagement trend
- TikTok: Check analytics for any videos flagged/removed
- Both: Search 3-5 primary hashtags, verify your posts appear
- Review previous week comments for negative/spam feedback
- Monitor DM responses for account security issues

**Monthly audit**:
- Count interactions (likes, comments, follows) vs. prior month
- Verify no content removed
- Check account health (warnings, action blocks)
- Review follower growth rate (should be 10-20% month-over-month at launch)

---

## Key Takeaways

1. **Mixpost + Postiz** are the only self-hosted schedulers safe for large-scale automation
2. **Instagrapi** is powerful for Instagram but should be used with caution and delays
3. **Organic growth** (Reels + TikTok videos) requires consistency over perfection
4. **Micro-influencer partnerships** (10 influencers × 5K followers each = 50K reach) is highest ROI for $0 spend
5. **Trending audio** is the #1 algorithm signal on both platforms; it changes hourly
6. **Email + SMS capture** during organic acquisition phase sets up for retention marketing later
7. **Zero ad spend** is possible for first 10K downloads if you post 1 week before scaling, not simultaneously
8. **Avoid ALL automation** on primary account; test only on side accounts if needed

---

## Additional Resources

**Official Tools**:
- [Instagram Creator Studio](https://business.facebook.com/creatorstudio)
- [TikTok Creator Center](https://www.tiktok.com/creator-center/)
- [TikTok Business API](https://developers.tiktok.com/)
- [Meta Graph API Docs](https://developers.facebook.com/docs/graph-api)

**Community/Forums**:
- [r/FashionTech](https://reddit.com/r/fashiontech)
- [Indie Hackers Fashion Community](https://indiehackers.com)
- [Maker's Lounge (product makers)](https://themakers-lounge.com)

**Next Steps for Rosier**:
1. Set up Instagram Creator Account + TikTok Pro Account (today)
2. Deploy Mixpost instance on Railway.app ($5-10/month) (day 1-2)
3. Identify 100 micro-influencers, compile spreadsheet (day 3-5)
4. Batch-create 15 content pieces (day 6-7)
5. Launch week 1 with 1 Reel + 1 TikTok daily, 5 influencer DMs daily (day 8+)
6. Scale based on engagement (week 2: 2 Reels + 2 TikToks, 10 influencer DMs daily)

---

**Document version**: 1.0
**Last updated**: April 2026
**Maintained by**: Dev 3 (Rosier Growth Team)
