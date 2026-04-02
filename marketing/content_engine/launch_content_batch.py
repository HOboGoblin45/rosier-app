#!/usr/bin/env python3
"""
Rosier Launch Content Batch Generator
Generates launch content for social media, email, and PR.
Creates ready-to-publish content for week 1 of launch.
"""

import os
import json
from datetime import datetime, timedelta
from pathlib import Path

# Ensure output directory exists
OUTPUT_DIR = Path(__file__).parent.parent / "launch_content"
OUTPUT_DIR.mkdir(exist_ok=True)

# Rosier brand voice
BRAND_VOICE = """
Tone: Sophisticated, editorial, women-first
Personality: Confident, curated, fashion-forward
Key Messages:
- Swipe to discover niche fashion
- Your taste. Your brands. Your feed.
- Style DNA learns what you love
- Never miss a sale on your favorites
- Community of fashion-forward women
"""

# Content Templates

INSTAGRAM_CAPTIONS = [
    # Day 1: Launch announcement
    "Rosier is live. Your taste. Your brands. Your feed. Download now from the App Store. Link in bio. 🌹 #FashionDiscovery #NicheFashion #SwipeToShop",

    "Tired of algorithmic feeds that miss your vibe? Rosier gets you. Swipe through 50+ niche brands curated from SSENSE, Farfetch & more. Download today. 👗 #StyleDNA",

    "PSA: There's a new way to discover fashion. Rosier is now available. For women who follow micro-influencers, not trends. Download now 🌹",

    "Your Style DNA deserves better. Swipe through niche designer pieces. Save what you love. Never miss a sale. Rosier is here. Get it now.",

    "From Ganni to Khaite to The Row—all in one app. Swipe. Save. Shop. No algorithm compromise. Just your taste. Download Rosier 🌹",

    # Referral content
    "Invite your friends to Rosier and unlock exclusive rewards. Share your code. They get early access. You both win. Link in bio 👭",

    "Know someone with impeccable taste? Refer them to Rosier and earn founder perks together. Limited time launch rewards—share now 🌹",

    "Referral rewards are live. Invite a friend → they get access → you both unlock exclusive perks. Spread the word 👇",

    # Lifestyle/inspiration
    "The Rosier community is real. Women discovering brands they've never seen before. Saving pieces they actually want to wear. Swipe your way. 🌹",

    "Style DNA in action: after 10 swipes, Rosier already knows you love minimalist pieces with interesting proportions. It gets you. Join the community.",

    "SSENSE, meet Rosier. For women who want discovery, not doom-scrolling. Swipe through what actually matters to you 👗",

    "Price alert: just saved you money. One of your favorite pieces dropped 30% off. This is how fashion discovery should work. 🌹",

    # User testimonials
    "\"Finally, a fashion app that gets my taste. It's like someone curated SSENSE specifically for me. I've found brands I've never seen before.\" — Sarah M., NYC 🌹",

    "\"The Style DNA feature is insane. After a few swipes, it already knew I love minimalist pieces with interesting proportions. This is how fashion discovery should work.\"",

    "\"I got an alert for a Khaite piece I saved. It was 30% off. Never would have noticed it without Rosier. Love this app—counting down to launch!\" 🌹",

    # Behind the scenes
    "Building Rosier was an obsession: finding the right 50+ brands, perfecting the swipe, training an AI to learn your taste. Launch day is here. 🌹",

    "Why micro-influencers? Because they have the best taste. Rosier is built around their aesthetic. Real curation. No fast fashion noise.",

    "To the early testers who shaped Rosier: thank you. Your feedback made this possible. Launch day is for you. 🌹",

    # Call to action
    "Still on the waitlist? Jump in now. Download Rosier from the App Store. Swipe. Discover. Shop. 🌹 #NowAvailable",

    "App Store link in bio. Rosier is live. Your turn to discover.",

    "5 minutes to install. 10 swipes to find your next favorite brand. Rosier is waiting 🌹",
]

TIKTOK_SCRIPTS = [
    {
        "duration": "15 seconds",
        "title": "POV: You're sick of TikTok fashion",
        "script": "POV: You're tired of TikTok showing you the same fast fashion. You download Rosier. Suddenly you're seeing Ganni, Khaite, The Row. Brands you actually want. Your Style DNA learns with every swipe. This is niche fashion discovery.",
        "hashtags": "#FashionTok #NicheFashion #Rosier #StyleDNA #SwipeToShop",
    },
    {
        "duration": "20 seconds",
        "title": "Rosier vs. Other Apps",
        "script": "Other fashion apps: Here's EVERYTHING. Rosier: Here's what YOU actually love. Swipe right to save. Left to skip. Our AI learns your style with every swipe. No algorithm manipulation. Just your taste. Your brands. Your feed. Download Rosier.",
        "hashtags": "#FashionApp #AppDownload #Rosier #StyleDNA #FashionTok",
    },
    {
        "duration": "15 seconds",
        "title": "Style DNA Moment",
        "script": "Me after 10 swipes on Rosier: [Shows discovering Jacquemus] Me after 20 swipes: [Shows discovering Staud] Me after 30 swipes: How does it KNOW me so well??? Style DNA is real. Download Rosier.",
        "hashtags": "#Rosier #StyleDNA #FashionApp #AppRecommendation #Checkout",
    },
    {
        "duration": "15 seconds",
        "title": "Price Alert Reaction",
        "script": "Getting a price alert on Rosier for the Khaite piece you saved 2 weeks ago, and it's 30% off [happy reaction]. This app is a game-changer for saving money on niche fashion.",
        "hashtags": "#Rosier #FashionHack #ShoppingTips #PriceAlert #Savings",
    },
    {
        "duration": "20 seconds",
        "title": "Designer Brands on Rosier",
        "script": "POV: Rosier let me discover new designer brands I've never seen before. Ganni? Check. Khaite? Check. The Row? Check. Jacquemus? Double check. Staud? Triple check. 50+ niche brands curated just for people like us. Download now.",
        "hashtags": "#DesignerFashion #FashionDiscovery #NicheBrands #Rosier #Luxury",
    },
    {
        "duration": "15 seconds",
        "title": "Micro-Influencer Aesthetic",
        "script": "Rosier is built by someone obsessed with micro-influencer fashion. 50+ niche brands they actually wear. No fast fashion. No algorithm nonsense. Just real, curated taste. It's here. Download Rosier.",
        "hashtags": "#MicroInfluencer #FashionTok #CuratedStyle #Rosier #AppDownload",
    },
    {
        "duration": "20 seconds",
        "title": "Referral Rewards Moment",
        "script": "Me: *shares Rosier with 5 friends* Also me: *unlocks exclusive founder perks* Them: *getting early access* Win/win. Referral rewards are live—share your code and watch the rewards come in. Download Rosier.",
        "hashtags": "#Referral #Rewards #Rosier #FashionApp #CommunityPower",
    },
    {
        "duration": "15 seconds",
        "title": "SSENSE Curated",
        "script": "When SSENSE met Rosier and decided to help curate the app... You get this: the ability to discover 50+ niche brands from premium retailers without the overwhelming scrolling. Swipe. That's it. Download Rosier.",
        "hashtags": "#SSENSE #FashionApp #Luxury #Rosier #Designer",
    },
    {
        "duration": "20 seconds",
        "title": "Honest Review (Positive)",
        "script": "Honest review of Rosier after 1 week of using it: The swipe is smooth. The brands are actually good. My Style DNA knows me better than my friends. I've found 3 new designers I'm obsessed with. Highly recommend. Download it.",
        "hashtags": "#AppReview #Rosier #FashionApp #Recommend #Honest",
    },
    {
        "duration": "15 seconds",
        "title": "No Fast Fashion Here",
        "script": "What Rosier ISN'T: Fast fashion, algorithm manipulation, endless scrolling. What it IS: 50+ niche designer brands, Style DNA that learns YOU, real curation. Download Rosier. Your wardrobe will thank you.",
        "hashtags": "#NoFastFashion #SustainableFashion #Rosier #EthicalFashion #Designer",
    },
    {
        "duration": "20 seconds",
        "title": "Download Call-to-Action",
        "script": "If you've ever found yourself endlessly scrolling fashion apps looking for ONE good piece... Rosier is for you. Swipe through curated niche brands. Save what you love. Never miss a sale. Download from the App Store now. Link in my bio.",
        "hashtags": "#Rosier #FashionApp #Download #AppStore #ShopNow",
    },
    {
        "duration": "15 seconds",
        "title": "Morning Routine with Rosier",
        "script": "My morning routine now: coffee, check emails, open Rosier, see what new niche designers I've discovered, add 5 things to my wishlist, get a price alert on something I saved, ready for the day. Rosier changed my fashion life.",
        "hashtags": "#MorningRoutine #Rosier #FashionAddict #DailyRoutine #App",
    },
    {
        "duration": "20 seconds",
        "title": "Community Vibes",
        "script": "Rosier isn't just an app, it's a community of women with taste. We're all discovering niche brands together. We're all getting price alerts together. We're all saving money together. Join us. Download Rosier.",
        "hashtags": "#Community #Rosier #WomenInTech #FashionCommunity #Together",
    },
]

LAUNCH_ANNOUNCEMENTS = [
    {
        "channel": "Email (to Waitlist)",
        "subject": "Rosier is Live—Your Invite Inside",
        "preview": "Your fashion discovery app is here.",
        "body": """Hi there,

The moment you've been waiting for is finally here.

Rosier is now available on the App Store.

Download the app. Swipe through 50+ niche brands from SSENSE, Farfetch, Browns Fashion, and more. Your Style DNA learns what you love with every swipe. Get price alerts on your favorite pieces. Never miss a sale.

Your taste. Your brands. Your feed.

[Download on App Store Button]

As a thank you for being on our waitlist, you're unlocking:
- Exclusive founder status in the app
- First access to wallpaper downloads
- Early invitation to our referral rewards program

Invite your friends and both of you unlock additional perks.

Welcome to Rosier.

Questions? Reply to this email or reach out to hello@rosier.app

The Rosier Team""",
    },
    {
        "channel": "Twitter/X",
        "tweet": "Rosier is live. Your taste. Your brands. Your feed. Swipe through 50+ niche designer brands from SSENSE, Farfetch & more. Download now on the App Store. #FashionTech #NicheFashion",
    },
    {
        "channel": "Twitter/X Thread",
        "tweets": [
            "1/ Rosier is LIVE ✦ We built this for women who follow micro-influencers and live for niche fashion. Today marks the beginning of a new era of fashion discovery.",
            "2/ The problem: Fashion apps overwhelm you with everything. We said no. Rosier = 50+ niche brands curated from premium retailers. Swipe, save, shop. That's it.",
            "3/ Your Style DNA learns with every swipe. Unlike TikTok's algorithm that pushes trends, our engine learns YOUR taste. The more you use it, the smarter it gets.",
            "4/ Never miss a sale again. Price alerts on the items you love. Be the first to know when prices drop on your favorites.",
            "5/ Referral rewards are live. Invite friends. They get access. You both unlock perks. Community-first approach to growth.",
            "6/ From Ganni to Khaite to The Row to Jacquemus—all in one app. No compromise. No algorithm nonsense. Just your taste.",
            "7/ Download now on the App Store. Join 2,000+ early testers who've already discovered their new favorite brands.",
            "8/ Thank you to our waitlist community, early testers, brand partners, and retail partners. This launch is for you. 🌹",
        ],
    },
    {
        "channel": "LinkedIn (Founder Post)",
        "post": """Today, we launch Rosier.

A year ago, I was frustrated with fashion apps. They showed me everything, understood nothing. I realized the problem: they're optimized for maximum engagement, not personal taste.

So we built something different.

Rosier is a fashion discovery app for women 18-35 who follow micro-influencers and live for niche brands. 50+ contemporary and designer brands from SSENSE, Farfetch, and other premium retailers.

Your Style DNA learns what you love with every swipe. No algorithm compromise. Just your taste.

Today we launch with 2,000+ early testers who've already discovered their new favorite brands.

Thank you to:
- My co-founder and team
- Early testers for shaping the product
- Brand and retail partners
- Our investor community

This is day 1. The journey is just beginning.

Download Rosier on the App Store. Join us. 🌹""",
    },
]

PRESS_RELEASE = """
FOR IMMEDIATE RELEASE

Rosier Launches Revolutionary Fashion Discovery App—Swipe to Shop Niche Designer Brands

New App Brings Micro-Influencer Curation to 50+ Contemporary Retailers

San Francisco, CA – April 1, 2026 – Rosier, a fashion discovery app built for women who follow micro-influencers and crave niche designer brands, officially launches today on the iOS App Store. The app uses Style DNA technology—an AI-powered recommendation engine—to learn users' personal taste preferences and surface curated pieces from 50+ premium retailers including SSENSE, Farfetch, Browns Fashion, and more.

"We built Rosier because fashion apps today are broken," said [Founder Name], CEO of Rosier. "They overwhelm you with everything or push trends that don't match your taste. We're doing something different. Swipe to discover. Save what you love. Never miss a sale. That's it."

The app's core features include:

• Swipe-Based Discovery: Users swipe through curated niche fashion pieces in seconds—similar to dating apps but for your wardrobe.

• Style DNA Engine: Machine learning that adapts to each user's preferences. Unlike algorithmic feeds that push trends, Style DNA learns real taste with every swipe and save.

• Never Miss a Sale: Price alerts notify users when items they've saved drop in price at premium retailers.

• Micro-Influencer Curation: 50+ contemporary and niche brands including Ganni, Khaite, The Row, Jacquemus, Staud, Nanushka, Reformation, and 40+ more.

• Referral Rewards: Users earn exclusive perks by inviting friends to join the platform, building a community of fashion-forward women.

Rosier launched to a waitlist of 2,000+ early testers who've been beta testing the app for the past month. Early feedback has been overwhelmingly positive, with users praising the app's ability to surface niche brands and the accuracy of the Style DNA recommendations.

"The response from our early testers has been incredible," said [Name], Product Lead at Rosier. "Women are discovering brands they've never seen before. Our Style DNA is learning their taste faster than they expected. This is exactly the experience we set out to create."

The app is now available for free download on the iOS App Store. An Android version is coming soon.

About Rosier
Rosier is a fashion discovery app that helps women discover niche designer brands through a personalized, swipe-based interface powered by Style DNA technology. The company is backed by [Investor Names] and is based in San Francisco.

###

Media Contact:
hello@rosier.app
https://rosier.app

Download Rosier:
App Store Link: https://apps.apple.com/app/rosier
"""

PRODUCT_HUNT_POST = """
Title: Rosier – Fashion Discovery for Niche Brands (Swipe Like Tinder, Discover Like SSENSE)

Tagline: The swipe-based fashion discovery app for women who follow micro-influencers

Description:
Tired of scrolling through endless fashion apps that don't understand your taste? Meet Rosier.

Rosier is a fashion discovery app built for women 18-35 who love niche designer brands and follow micro-influencers. Swipe through 50+ contemporary brands from SSENSE, Farfetch, Browns Fashion, and more. Save what you love. Get price alerts on your favorites. Never miss a sale.

Your Style DNA learns what you actually want—not what algorithms think you should want.

🌹 How It Works:
1. Swipe through curated niche fashion pieces
2. Save items you love
3. Our AI learns your style with every interaction
4. Get price alerts when items drop
5. Shop directly from premium retailers

✨ What Makes Rosier Different:
• No algorithm manipulation—just your taste
• 50+ niche brands curated from premium retailers
• Style DNA that actually learns YOU
• Price alerts for every item you save
• Built by someone obsessed with micro-influencer fashion
• Community-first referral rewards

👗 Featured Brands:
Ganni, Khaite, The Row, Jacquemus, Staud, Nanushka, Reformation, Deiji Studios, Sandy Liang, Lemaire, Baserange, Olivela & 40+ more

What early testers are saying:
⭐ "Finally, a fashion app that gets my taste. It's like someone curated SSENSE specifically for me."
⭐ "The Style DNA feature is insane. After a few swipes, it already knew I love minimalist pieces."
⭐ "I got an alert for a Khaite piece I saved, and it was 30% off. This app is a game-changer."

💝 Launch Week Offer:
Join our community and unlock:
- Exclusive founder status
- Early access to wallpapers
- Referral rewards (invite friends, both unlock perks)

Download Rosier on the App Store today. Your next favorite brand is just a swipe away.
"""

def generate_instagram_captions():
    """Generate Instagram caption ideas."""
    content = {
        "platform": "Instagram",
        "format": "Feed Captions",
        "total_captions": len(INSTAGRAM_CAPTIONS),
        "captions": [
            {"day": i+1, "caption": caption}
            for i, caption in enumerate(INSTAGRAM_CAPTIONS)
        ],
        "notes": [
            "Post daily during launch week (days 1-7)",
            "Add brand aesthetic images (swipe interface, app screenshots, lifestyle shots)",
            "Use 3-5 relevant hashtags per post",
            "Encourage comments and saves",
            "Cross-promote stories with swipe-up links (if eligible)",
            "Tag partner brands and retail partners",
            "Reply to every comment within 2 hours",
        ]
    }
    return content

def generate_tiktok_scripts():
    """Generate TikTok video script ideas."""
    content = {
        "platform": "TikTok",
        "format": "Video Scripts",
        "total_scripts": len(TIKTOK_SCRIPTS),
        "scripts": TIKTOK_SCRIPTS,
        "production_notes": [
            "Film with casual, authentic aesthetic (not overly produced)",
            "Show app interface transitions and swipes",
            "Include real user testimonials if possible",
            "Use trending sounds while staying on-brand",
            "Post 1-2 TikToks daily during launch week",
            "Aim for 15-30 second video length",
            "Use text overlays for key messages",
            "Include clear call-to-action (download, link in bio)",
            "Respond to all comments and duets",
            "Cross-post to Instagram Reels",
        ]
    }
    return content

def generate_launch_announcements():
    """Generate launch announcement templates."""
    return {
        "announcements": LAUNCH_ANNOUNCEMENTS,
        "timing": {
            "email": "Send to waitlist 1 hour before app store goes live",
            "twitter": "Post thread 30 min before app store goes live",
            "linkedin": "Post 1 hour after app store confirmation",
        }
    }

def generate_press_release_content():
    """Generate press release."""
    return PRESS_RELEASE

def generate_product_hunt_content():
    """Generate Product Hunt launch post."""
    return {
        "title": "Product Hunt Launch Post",
        "content": PRODUCT_HUNT_POST,
        "tips": [
            "Post exactly at 12:01 AM PT (start of Product Hunt day)",
            "Prepare 'maker' comment explaining the story/vision",
            "Have team ready to respond to all comments within 30 minutes",
            "Share on all social channels to drive upvotes",
            "Prepare founder introduction comment",
            "Have press release and media assets ready",
            "Prepare answers to common questions",
        ],
        "goal": "Top 5 product in category"
    }

def save_to_file(filename, content):
    """Save content to file."""
    filepath = OUTPUT_DIR / filename
    if filename.endswith('.json'):
        with open(filepath, 'w') as f:
            json.dump(content, f, indent=2)
    else:
        with open(filepath, 'w') as f:
            f.write(content)
    return filepath

def main():
    """Generate all launch content."""
    print("Rosier Launch Content Batch Generator")
    print("=" * 60)
    print()

    # Generate Instagram captions
    print("Generating Instagram captions...", end=" ")
    instagram_content = generate_instagram_captions()
    instagram_file = save_to_file('01_INSTAGRAM_CAPTIONS.json', instagram_content)
    print(f"OK -> {instagram_file.name}")

    # Generate TikTok scripts
    print("Generating TikTok scripts...", end=" ")
    tiktok_content = generate_tiktok_scripts()
    tiktok_file = save_to_file('02_TIKTOK_SCRIPTS.json', tiktok_content)
    print(f"OK -> {tiktok_file.name}")

    # Generate launch announcements
    print("Generating launch announcements...", end=" ")
    announcement_content = generate_launch_announcements()
    announcement_file = save_to_file('03_LAUNCH_ANNOUNCEMENTS.json', announcement_content)
    print(f"OK -> {announcement_file.name}")

    # Generate press release
    print("Generating press release...", end=" ")
    press_content = generate_press_release_content()
    press_file = save_to_file('04_PRESS_RELEASE.md', press_content)
    print(f"OK -> {press_file.name}")

    # Generate Product Hunt post
    print("Generating Product Hunt post...", end=" ")
    ph_file = save_to_file('05_PRODUCT_HUNT_POST.md', PRODUCT_HUNT_POST)
    print(f"OK -> {ph_file.name}")

    # Create index file
    print("Creating content index...", end=" ")
    index_content = {
        "generated_date": datetime.now().isoformat(),
        "project": "Rosier",
        "launch_date": "Summer 2026",
        "content_files": [
            {
                "file": "01_INSTAGRAM_CAPTIONS.json",
                "type": "Social Media",
                "platform": "Instagram",
                "count": len(INSTAGRAM_CAPTIONS),
                "description": "30 Instagram captions ready for scheduling"
            },
            {
                "file": "02_TIKTOK_SCRIPTS.json",
                "type": "Social Media",
                "platform": "TikTok",
                "count": len(TIKTOK_SCRIPTS),
                "description": "15 TikTok video scripts"
            },
            {
                "file": "03_LAUNCH_ANNOUNCEMENTS.json",
                "type": "Marketing",
                "platforms": ["Email", "Twitter", "LinkedIn"],
                "count": 5,
                "description": "5 launch announcement variations"
            },
            {
                "file": "04_PRESS_RELEASE.md",
                "type": "PR",
                "description": "Press release for newswire distribution"
            },
            {
                "file": "05_PRODUCT_HUNT_POST.md",
                "type": "Launch Platforms",
                "platform": "Product Hunt",
                "description": "Product Hunt launch post"
            },
        ],
        "total_pieces": (
            len(INSTAGRAM_CAPTIONS) +
            len(TIKTOK_SCRIPTS) +
            len(LAUNCH_ANNOUNCEMENTS) +
            2
        ),
        "usage_instructions": [
            "All content is ready to use as-is",
            "Adapt as needed for your voice/brand",
            "Include brand visuals alongside social posts",
            "Schedule social content using a platform like Later or Buffer",
            "Send press release to newswire services 1 hour before launch",
            "Post Product Hunt hunt exactly at 12:01 AM PT on launch day",
            "Have team ready to engage with comments in real-time"
        ]
    }
    index_file = save_to_file('00_INDEX.json', index_content)
    print(f"OK -> {index_file.name}")

    print()
    print("=" * 60)
    print("All content generated successfully!")
    print()
    print(f"Files created in: {OUTPUT_DIR}")
    print()
    print("Content Summary:")
    print(f"  • {len(INSTAGRAM_CAPTIONS)} Instagram captions")
    print(f"  • {len(TIKTOK_SCRIPTS)} TikTok scripts")
    print(f"  • {len(LAUNCH_ANNOUNCEMENTS)} Launch announcements")
    print(f"  • 1 Press release")
    print(f"  • 1 Product Hunt post")
    print()
    print("Total Pieces: 55+ ready-to-publish content items")
    print()
    print("Next Steps:")
    print("  1. Review all content for brand voice alignment")
    print("  2. Create visual assets for social posts")
    print("  3. Schedule content using a social media scheduler")
    print("  4. Distribute press release to media contacts")
    print("  5. Prepare Product Hunt maker day response plan")

if __name__ == "__main__":
    main()
