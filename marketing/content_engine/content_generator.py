"""
Rosier Content Engine - Social Media Content Generator

Generates Instagram Reels and TikTok scripts from app data (trending brands,
style insights, product drops, price alerts). Maintains brand voice and
aesthetic consistency across platforms.
"""

import json
import random
from datetime import datetime
from typing import Dict, List, Optional, Tuple
from dataclasses import dataclass, asdict


@dataclass
class ContentPost:
    """Structured content output"""
    platform: str  # 'instagram', 'tiktok', 'stories'
    content_type: str  # 'trending', 'brand_spotlight', 'style_dna', etc
    caption: str
    hashtags: List[str]
    hook: Optional[str] = None  # For TikTok (first 3 sec script)
    cta: Optional[str] = None  # Call to action
    image_specs: Optional[Dict] = None  # Image generation specs
    posting_time: Optional[str] = None  # Optimal posting time


class RosierContentEngine:
    """
    Generates social media content from Rosier app data.

    Data sources: trending brands, popular products, style archetypes,
    daily drops, price changes, user activity insights.
    """

    # Brand roster for content generation
    BRAND_ROSTER = [
        'Ganni', 'Staud', 'Nanushka', 'Deiji Studios', 'Khaite', 'The Row',
        'Jacquemus', 'Reformation', 'COS', 'Aesther Ekme', 'Vince', 'Rag & Bone',
        'Lemaire', 'Totême', 'Apparis', 'Rixo', 'Miaou', 'Nili Lotan',
        'Baserange', 'Matériel', 'Maison Margiela', 'Jil Sander', 'Armedangels',
        'Christy Ng', 'Eterne', 'Knitwear Stories', 'LAQUAN', 'Lemaire',
        'Olivia Rubin', 'Partow', 'Raised in the System', 'Recto Verso',
        'Storlek', 'Three Graces London', 'Uli Herzner', 'Vêtements', 'Wales Bonner'
    ]

    # Style archetypes
    STYLE_ARCHETYPES = [
        'Dark Academia', 'Quiet Luxury', 'Coastal Minimalist',
        'Maximalist', '90s Minimalism', 'Romantic', 'Avant-Garde',
        'Heritage Preppy', 'Artistic', 'Tailored Androgynous',
        'Boho Luxe', 'Cyberpunk Chic', 'Vintage Soul'
    ]

    # Rosier brand colors
    BRAND_COLORS = {
        'primary': '#1A1A2E',
        'accent': '#C4A77D',
        'surface': '#F8F6F3'
    }

    def __init__(self):
        """Initialize content engine with templates"""
        self.templates = self._load_templates()

    def _load_templates(self) -> Dict:
        """Load caption and hashtag templates (would load from JSON in production)"""
        return {
            'instagram': {
                'trending': [
                    "What's trending on Rosier this week? {brand_1} leads with {score_1}% love, followed by {brand_2} and {brand_3}. Your taste is showing 👀\n\n{hashtags}",
                    "The brands taking over your Rosier feed right now:\n\n#1: {brand_1} (+{change_1}% this week)\n#2: {brand_2} ({score_2}% saved)\n#3: {brand_3} (emerging)\n\nWhich one has YOUR name on it? {hashtags}",
                    "Fashion is moving. Here's proof:\n\n{brand_1} is your #1 most-swiped brand this week\n{brand_2} broke into top 5 overnight\n{brand_3} is the dark horse everyone's sleeping on\n\nDownload Rosier. Stay ahead. {hashtags}",
                    "Hot take: {brand_1}'s moment isn't peaking yet. Rosier data shows {brand_2} catching up fast. Both are going in your cart this season. Which first? {hashtags}",
                    "Trending right now on Rosier:\n→ {brand_1}\n→ {brand_2}\n→ {brand_3}\n\nNone of these were trending 2 weeks ago. Taste evolves fast. {hashtags}",
                ],
                'brand_spotlight': [
                    "{brand} just hit {position} on Rosier. Here's why:\n\n• {stat_1}\n• {stat_2}\n• {stat_3}\n\nYour next favorite brand is waiting. {hashtags}",
                    "One brand, infinite outfits:\n\n{brand}\n\n{description} Rosier users can't stop swiping. Can you?\n\n{hashtags}",
                    "{brand} is having a moment. {growth}% growth this month. The pieces? Unmissable. {hashtags}",
                    "Style blueprint: {brand}\n\nWhy Rosier users love it:\n{description}\n\nDiscover your version on Rosier. {hashtags}",
                ],
                'style_dna': [
                    "Your Style DNA is calling.\n\nSwipe through 20 brands in 2 minutes. Watch Rosier learn what you love. Get your personalized Style DNA card.\n\nIt's disturbingly accurate. \n\n{hashtags}",
                    "POV: You just discovered your personal style aesthetic in one app.\n\nThat's what {archetype} energy is telling us. What's yours?\n\nDownload Rosier. Swipe. Find out. {hashtags}",
                    "Your taste isn't boring. The algorithm you've been using just was.\n\nDiscover your real Style DNA on Rosier.\n\n{hashtags}",
                    "Dark Academia? Quiet Luxury? Both? {archetype} users just got their style confirmed.\n\nWhat's your mix? {hashtags}",
                ],
                'daily_drop': [
                    "Daily Drop is live.\n\nToday's 5:\n{products}\n\nFirst 100 to swipe get price alerts. {hashtags}",
                    "It's Thursday morning. New brands just dropped on Rosier.\n\nThe edit:\n{products}\n\n{hashtags}",
                    "New on Rosier:\n{products}\n\n(These disappear fast. Link in bio.) {hashtags}",
                ],
                'price_alert': [
                    "{product} just dropped from {old_price} to {new_price}.\n\nThat's {savings}% off. \n\nRosier users with this saved? Notification just sent. Are you one of them? {hashtags}",
                    "Price drop: {product}\n{old_price} → {new_price}\n\nSave {savings}%. Rosier catches these so you don't have to. {hashtags}",
                ],
                'engagement': [
                    "Finish this sentence: 'I'd wear {brand} to...'\n\n(This is how Rosier learns your style.) {hashtags}",
                    "Would you or would you nah?\n\n{product} on Rosier\n\nComment below. Tag someone. {hashtags}",
                    "Hot take: {brand} is underrated.\n\nChange my mind in the comments. Or download Rosier and let the data speak. {hashtags}",
                ],
                'ugc_prompt': [
                    "Share your Style DNA.\n\nSwipe on Rosier. Get your personal style card. Post it to Stories. Tag #MyRosierStyle.\n\nBest ones get featured here + in the app. Let's see your vibe. {hashtags}",
                    "Style Check: What's your dominant aesthetic on Rosier?\n\nDownload, swipe 20 brands, get your answer. Share it. We're featuring the best. {hashtags}",
                ],
            },
            'tiktok': {
                'hook_and_reveal': [
                    {"hook": "This brand is about to take over your feed...", "body": "It's {brand}. Rosier data shows {stat}. Here's why.", "cta": "Link in bio to discover"},
                    {"hook": "POV: You finally found the brand that gets your aesthetic", "body": "Rosier just matched me with {brand} and I'm not recovering", "cta": "Try Rosier"},
                    {"hook": "The app algorithm everyone's switching to:", "body": "{brand} just hit #{position} trending on Rosier", "cta": "See the full top 10"},
                ],
                'style_quiz': [
                    {"hook": "What's your style DNA?", "body": "Take 2 minutes on Rosier. Swipe 20 brands. Get your personalized aesthetic.", "cta": "Try the quiz"},
                    {"hook": "This describes my fashion taste too well", "body": "Dark Academia meets Quiet Luxury? That's {archetype}. What's yours?", "cta": "Download Rosier"},
                ],
                'trend_breakdown': [
                    {"hook": "{brand} is trending. Here's the tea.", "body": "{stat}% more swipes this week. Rosier data doesn't lie.", "cta": "See what's trending now"},
                    {"hook": "Fashion trends live here now:", "body": "Not Instagram. Not TikTok. Rosier. {brand} is the proof.", "cta": "Download Rosier"},
                ],
                'swipe_along': [
                    {"hook": "Swipe if you'd wear this brand", "body": "Stopping on brands from Rosier because taste test", "cta": "Swipe along on Rosier"},
                    {"hook": "Your style in one app", "body": "Fast swipes. Real discovery. No algorithm BS.", "cta": "Try it"},
                ],
                'app_demo': [
                    {"hook": "Finally an app that understands niche fashion", "body": "Rosier: swipe brands, learn your style, get notifications for drops", "cta": "Download now"},
                    {"hook": "Instagram algorithm vs Rosier", "body": "Rosier showed me {brand} and I've never felt so seen", "cta": "Link in bio"},
                ],
            }
        }

    def generate_trending_post(self, trending_data: Dict) -> ContentPost:
        """
        Creates 'Trending on Rosier' Instagram post and TikTok script.

        Args:
            trending_data: {
                'top_brands': [{'name': str, 'score': int, 'change': int}],
                'period': str (e.g., 'this week', 'today')
            }

        Returns:
            ContentPost with platform-specific caption and specs
        """
        brands = trending_data.get('top_brands', [])[:3]
        if len(brands) < 3:
            brands += [{'name': random.choice(self.BRAND_ROSTER), 'score': 75, 'change': 5}
                      for _ in range(3 - len(brands))]

        # Instagram caption
        template = random.choice(self.templates['instagram']['trending'])
        ig_caption = template.format(
            brand_1=brands[0]['name'],
            score_1=brands[0].get('score', 80),
            brand_2=brands[1]['name'],
            brand_3=brands[2]['name'],
            change_1=brands[0].get('change', 12),
            score_2=brands[1].get('score', 75),
            position='#1' if brands[0]['score'] > 85 else '#2',
            growth=trending_data.get('growth', 23),
            hashtags=self._get_hashtags('trending', 'instagram')
        )

        # TikTok hook
        tt_template = random.choice(self.templates['tiktok']['trend_breakdown'])
        tt_hook = tt_template['hook'].format(brand=brands[0]['name']) if '{brand}' in tt_template['hook'] else tt_template['hook']
        tt_body = tt_template['body'].format(stat=brands[0].get('change', 12)) if '{stat}' in tt_template['body'] else tt_template['body']

        return ContentPost(
            platform='instagram',
            content_type='trending',
            caption=ig_caption,
            hashtags=self._get_hashtags('trending', 'instagram', return_list=True),
            hook=tt_hook,
            cta='Link in bio to discover trending brands',
            image_specs={
                'type': 'trending_card',
                'brands': [b['name'] for b in brands],
                'scores': [b.get('score', 80) for b in brands],
                'size': '1080x1080'
            },
            posting_time='11:00'  # EST
        )

    def generate_brand_spotlight(self, brand_data: Dict) -> ContentPost:
        """
        Creates brand spotlight content.

        Args:
            brand_data: {
                'name': str,
                'position': int,
                'growth': int,
                'description': str,
                'stats': [str]
            }
        """
        template = random.choice(self.templates['instagram']['brand_spotlight'])
        caption = template.format(
            brand=brand_data['name'],
            position=brand_data.get('position', 5),
            stat_1=brand_data.get('stats', ['Growing momentum', 'Fresh aesthetic', 'Fan favorite'])[0],
            stat_2=brand_data.get('stats', ['Growing momentum', 'Fresh aesthetic', 'Fan favorite'])[1],
            stat_3=brand_data.get('stats', ['Growing momentum', 'Fresh aesthetic', 'Fan favorite'])[2],
            description=brand_data.get('description', 'Contemporary meets emerging'),
            growth=brand_data.get('growth', 15),
            hashtags=self._get_hashtags('brand', 'instagram')
        )

        return ContentPost(
            platform='instagram',
            content_type='brand_spotlight',
            caption=caption,
            hashtags=self._get_hashtags('brand', 'instagram', return_list=True),
            cta=f"Discover {brand_data['name']} on Rosier",
            image_specs={
                'type': 'brand_spotlight',
                'brand': brand_data['name'],
                'stats': brand_data.get('stats', []),
                'size': '1080x1080'
            },
            posting_time='14:00'  # 2 PM EST
        )

    def generate_style_dna_post(self, archetype_stats: Dict) -> ContentPost:
        """
        Creates 'What's your Style DNA?' engagement post.

        Args:
            archetype_stats: {
                'top_archetype': str,
                'percentage': int,
                'users_this_week': int,
                'related_archetypes': [str]
            }
        """
        archetype = archetype_stats.get('top_archetype', random.choice(self.STYLE_ARCHETYPES))
        related = archetype_stats.get('related_archetypes', [random.choice(self.STYLE_ARCHETYPES) for _ in range(2)])

        template = random.choice(self.templates['instagram']['style_dna'])
        caption = template.format(
            archetype=archetype,
            hashtags=self._get_hashtags('engagement', 'instagram')
        )

        return ContentPost(
            platform='instagram',
            content_type='style_dna',
            caption=caption,
            hashtags=self._get_hashtags('engagement', 'instagram', return_list=True),
            cta='Discover your Style DNA on Rosier',
            image_specs={
                'type': 'style_archetype_card',
                'archetype': archetype,
                'related': related,
                'percentage': archetype_stats.get('percentage', 23),
                'size': '1080x1080'
            },
            posting_time='19:00'  # 7 PM EST
        )

    def generate_daily_drop_teaser(self, products: List[Dict]) -> ContentPost:
        """
        Creates teaser for today's Daily Drop.

        Args:
            products: [{'name': str, 'brand': str, 'price': str}]
        """
        products = products[:5]
        product_list = '\n'.join([f"• {p['brand']} — {p['name']}" for p in products])

        template = random.choice(self.templates['instagram']['daily_drop'])
        caption = template.format(
            products=product_list,
            hashtags=self._get_hashtags('trending', 'instagram')
        )

        return ContentPost(
            platform='instagram',
            content_type='daily_drop',
            caption=caption,
            hashtags=self._get_hashtags('trending', 'instagram', return_list=True),
            cta='Save these now on Rosier',
            image_specs={
                'type': 'daily_drop_card',
                'products': [p['name'] for p in products],
                'brands': [p['brand'] for p in products],
                'size': '1080x1920'
            },
            posting_time='08:00'  # 8 AM EST
        )

    def generate_price_drop_alert(self, product: Dict, old_price: str, new_price: str) -> ContentPost:
        """
        Creates urgency post for major price drops.

        Args:
            product: {'name': str, 'brand': str}
            old_price: str (e.g., '$450')
            new_price: str (e.g., '$299')
        """
        # Calculate savings
        try:
            old = float(old_price.replace('$', '').replace(',', ''))
            new = float(new_price.replace('$', '').replace(',', ''))
            savings_pct = int((old - new) / old * 100)
        except:
            savings_pct = 33

        template = random.choice(self.templates['instagram']['price_alert'])
        caption = template.format(
            product=f"{product['brand']} — {product['name']}",
            old_price=old_price,
            new_price=new_price,
            savings=savings_pct,
            hashtags=self._get_hashtags('engagement', 'instagram')
        )

        return ContentPost(
            platform='instagram',
            content_type='price_alert',
            caption=caption,
            hashtags=self._get_hashtags('engagement', 'instagram', return_list=True),
            cta='See all price drops on Rosier',
            image_specs={
                'type': 'price_drop_card',
                'brand': product['brand'],
                'product': product['name'],
                'old_price': old_price,
                'new_price': new_price,
                'savings': savings_pct,
                'size': '1080x1920'
            },
            posting_time='12:00'  # 12 PM EST
        )

    def generate_weekly_roundup(self, weekly_stats: Dict) -> ContentPost:
        """
        Creates weekly trend roundup post.

        Args:
            weekly_stats: {
                'top_brands': [str],
                'top_categories': [str],
                'total_swipes': int,
                'new_brands': int
            }
        """
        brands_str = ', '.join(weekly_stats.get('top_brands', [])[:3])
        caption = f"""This week on Rosier:

{weekly_stats.get('total_swipes', 50000):,} swipes
{weekly_stats.get('new_brands', 8)} new brands discovered
Top brands: {brands_str}

Your taste made this. Weekly roundup is live. See your impact.

{self._get_hashtags('trending', 'instagram')}"""

        return ContentPost(
            platform='instagram',
            content_type='weekly_roundup',
            caption=caption,
            hashtags=self._get_hashtags('trending', 'instagram', return_list=True),
            cta='See the full weekly roundup on Rosier',
            image_specs={
                'type': 'weekly_roundup',
                'brands': weekly_stats.get('top_brands', [])[:3],
                'stats': weekly_stats,
                'size': '1080x1080'
            },
            posting_time='10:00'  # 10 AM EST Friday
        )

    def generate_ugc_prompt(self) -> ContentPost:
        """Creates user-generated content prompt/challenge."""
        template = random.choice(self.templates['instagram']['ugc_prompt'])
        caption = template.format(
            brand=random.choice(self.BRAND_ROSTER),
            hashtags=self._get_hashtags('engagement', 'instagram')
        )

        return ContentPost(
            platform='instagram',
            content_type='ugc_prompt',
            caption=caption,
            hashtags=self._get_hashtags('engagement', 'instagram', return_list=True),
            cta='Tag #MyRosierStyle to be featured',
            image_specs={
                'type': 'ugc_prompt_card',
                'prompt': 'What is your Style DNA?',
                'size': '1080x1920'
            },
            posting_time='15:00'  # 3 PM EST
        )

    def _get_hashtags(self, content_type: str, platform: str, return_list: bool = False) -> str:
        """Returns hashtag string for content type"""
        hashtag_sets = {
            'core': ['#rosierapp', '#fashiondiscovery', '#swipestyle'],
            'trending': ['#fashiontok', '#outfitinspo', '#stylecheck', '#fashiontrend'],
            'brand': ['#nichefashion', '#emergingdesigners', '#contemporaryfashion', '#designerbrand'],
            'engagement': ['#whatsmystyle', '#styledna', '#fashionswipe', '#myrioerstyle'],
            'price': ['#fashiondeals', '#dealsandsteals', '#shopthedrop']
        }

        core = hashtag_sets['core']
        category = hashtag_sets.get(content_type, hashtag_sets['trending'])

        selected = core + random.sample(category, min(3, len(category)))

        if return_list:
            return selected
        return ' '.join(selected)


if __name__ == '__main__':
    # Test the content engine
    engine = RosierContentEngine()

    # Example: Generate trending post
    trending_data = {
        'top_brands': [
            {'name': 'Ganni', 'score': 85, 'change': 23},
            {'name': 'Deiji Studios', 'score': 78, 'change': 15},
            {'name': 'Khaite', 'score': 72, 'change': 8}
        ],
        'growth': 23
    }

    post = engine.generate_trending_post(trending_data)
    print(f"Platform: {post.platform}")
    print(f"Type: {post.content_type}")
    print(f"Caption:\n{post.caption}\n")
    print(f"Hashtags: {', '.join(post.hashtags)}")
    print(f"Posting time: {post.posting_time}")
