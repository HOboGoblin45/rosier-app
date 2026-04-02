#!/usr/bin/env python3
"""
Auto-Posting Script for Rosier Content Engine

Runs daily via cron. Fetches trending data from Rosier API, generates
content, creates images, and schedules to Mixpost or exports for manual posting.

Setup:
  crontab -e
  # Add line:
  0 6 * * * /usr/bin/python3 /path/to/auto_post.py >> /tmp/rosier_autopost.log 2>&1
"""

import json
import os
import sys
import logging
from datetime import datetime, timedelta
from pathlib import Path
from typing import Dict, List, Optional

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent))

from content_generator import RosierContentEngine, ContentPost
from image_generator import RosierImageGenerator
from scheduler import ContentScheduler, ScheduleExporter
from analytics_tracker import AnalyticsTracker


# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('/tmp/rosier_autopost.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)


class AutoPostingPipeline:
    """Automated content generation and posting pipeline"""

    def __init__(self, config_path: Optional[str] = None):
        """Initialize pipeline with config"""
        self.config = self._load_config(config_path)
        self.engine = RosierContentEngine()
        self.image_gen = RosierImageGenerator()
        self.scheduler = ContentScheduler()
        self.tracker = AnalyticsTracker()

        self.output_dir = Path(self.config.get('output_dir', '/tmp/rosier_content'))
        self.output_dir.mkdir(parents=True, exist_ok=True)

        logger.info(f"AutoPostingPipeline initialized. Output: {self.output_dir}")

    def _load_config(self, config_path: Optional[str]) -> Dict:
        """Load configuration from file or use defaults"""
        if config_path and Path(config_path).exists():
            with open(config_path, 'r') as f:
                return json.load(f)

        return {
            'output_dir': '/tmp/rosier_content',
            'api_base': 'http://localhost:3000/api',  # Rosier backend
            'mixpost_enabled': True,
            'mixpost_url': 'http://localhost:8000',
            'max_posts_per_day': 4,
            'posting_times': {
                'instagram_reel': ['11:00', '19:00'],
                'tiktok': ['07:00', '19:00'],
                'stories': ['09:00', '17:00']
            }
        }

    def fetch_app_data(self) -> Dict:
        """
        Fetch trending data from Rosier backend API.

        In production, this would call actual Rosier API endpoints:
        - /api/trending/brands
        - /api/trending/styles
        - /api/daily/drops
        - /api/price/alerts
        """
        logger.info("Fetching app data from Rosier API...")

        # For now, return sample data (in production, would make real API calls)
        sample_data = {
            'trending_brands': [
                {'name': 'Ganni', 'score': 85, 'change': 23},
                {'name': 'Deiji Studios', 'score': 78, 'change': 15},
                {'name': 'Khaite', 'score': 72, 'change': 8},
                {'name': 'The Row', 'score': 68, 'change': 3},
                {'name': 'Nanushka', 'score': 65, 'change': -2},
            ],
            'trending_styles': {
                'top_archetype': 'Dark Academia',
                'percentage': 28,
                'related': ['Quiet Luxury', 'Romantic']
            },
            'daily_drops': [
                {'brand': 'Ganni', 'name': 'Brixon Crepe Blazer', 'price': '$395'},
                {'brand': 'Staud', 'name': 'Shirley Bag', 'price': '$295'},
                {'brand': 'Nanushka', 'name': 'Megan Vegan Leather', 'price': '$445'},
                {'brand': 'Jacquemus', 'name': 'Knit Top', 'price': '$350'},
                {'brand': 'Reformation', 'name': 'Vestige Jean', 'price': '$168'},
            ],
            'price_drops': [
                {
                    'brand': 'The Row',
                    'name': 'Margot Leather Clutch',
                    'old_price': '$890',
                    'new_price': '$623',
                    'percentage': 30
                }
            ],
            'weekly_stats': {
                'total_swipes': 125400,
                'new_brands': 8,
                'top_brands': ['Ganni', 'Deiji Studios', 'Khaite']
            }
        }

        logger.info(f"Loaded sample data for {len(sample_data['trending_brands'])} brands")
        return sample_data

    def generate_daily_content(self, app_data: Dict) -> List[ContentPost]:
        """Generate content for the day"""
        logger.info("Generating daily content...")

        posts = []

        # 1. Trending post
        trending_post = self.engine.generate_trending_post({
            'top_brands': app_data['trending_brands'],
            'growth': app_data['trending_brands'][0].get('change', 23)
        })
        posts.append(trending_post)
        logger.info(f"Generated trending post")

        # 2. Brand spotlight
        featured_brand = app_data['trending_brands'][1]
        spotlight_post = self.engine.generate_brand_spotlight({
            'name': featured_brand['name'],
            'position': 2,
            'growth': featured_brand.get('change', 15),
            'description': f"Contemporary + Emerging. #{featured_brand['name']} energy.",
            'stats': [f"Trending {featured_brand.get('change', 15)}% this week",
                     "Favorite among micro-influencers",
                     "Quality over quantity always"]
        })
        posts.append(spotlight_post)
        logger.info(f"Generated brand spotlight for {featured_brand['name']}")

        # 3. Style DNA post
        style_post = self.engine.generate_style_dna_post({
            'top_archetype': app_data['trending_styles']['top_archetype'],
            'percentage': app_data['trending_styles']['percentage'],
            'related_archetypes': app_data['trending_styles']['related']
        })
        posts.append(style_post)
        logger.info(f"Generated style DNA post")

        # 4. Daily drop teaser
        if app_data.get('daily_drops'):
            drop_post = self.engine.generate_daily_drop_teaser(app_data['daily_drops'])
            posts.append(drop_post)
            logger.info(f"Generated daily drop post")

        # 5. Price alert (if applicable)
        if app_data.get('price_drops'):
            price_drop = app_data['price_drops'][0]
            price_post = self.engine.generate_price_drop_alert(
                {'brand': price_drop['brand'], 'name': price_drop['name']},
                price_drop['old_price'],
                price_drop['new_price']
            )
            posts.append(price_post)
            logger.info(f"Generated price alert post")

        logger.info(f"Generated {len(posts)} posts total")
        return posts

    def generate_images(self, posts: List[ContentPost]) -> List[Dict]:
        """Generate images for each post"""
        logger.info("Generating images...")

        images = []

        for i, post in enumerate(posts):
            if not post.image_specs:
                continue

            specs = post.image_specs
            image_type = specs.get('type')
            image_bytes = None

            try:
                if image_type == 'trending_card':
                    image_bytes = self.image_gen.create_trending_card(
                        specs.get('brands', []),
                        specs.get('scores', [])
                    )
                elif image_type == 'brand_spotlight':
                    image_bytes = self.image_gen.create_brand_spotlight(
                        specs.get('brand', 'Brand'),
                        {'growth': 15, 'position': 1, 'description': 'Featured'}
                    )
                elif image_type == 'style_archetype_card':
                    image_bytes = self.image_gen.create_style_archetype_card(
                        specs.get('archetype', 'Dark Academia'),
                        {'percentage': 45, 'related_archetypes': specs.get('related', [])}
                    )
                elif image_type == 'daily_drop_card':
                    image_bytes = self.image_gen.create_daily_drop_preview(
                        specs.get('brands', [])
                    )
                elif image_type == 'price_drop_card':
                    image_bytes = self.image_gen.create_price_drop_card(
                        {
                            'brand': specs.get('brand', ''),
                            'name': specs.get('product', ''),
                            'old_price': specs.get('old_price', '$500'),
                            'new_price': specs.get('new_price', '$250')
                        },
                        specs.get('savings', 30)
                    )

                if image_bytes:
                    # Save image
                    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
                    filename = f"{timestamp}_{i}_{image_type}.png"
                    filepath = self.output_dir / filename

                    self.image_gen.save_image(image_bytes, str(filepath))
                    logger.info(f"Generated image: {filename}")

                    images.append({
                        'post_index': i,
                        'filename': filename,
                        'filepath': str(filepath),
                        'type': image_type
                    })

            except Exception as e:
                logger.error(f"Error generating image for post {i}: {e}")
                continue

        logger.info(f"Generated {len(images)} images")
        return images

    def schedule_posts(self, posts: List[ContentPost], images: List[Dict]) -> None:
        """Schedule posts for posting"""
        logger.info("Scheduling posts...")

        # Create content calendar
        calendar = self.scheduler.create_content_calendar(days=1)

        # Assign posts to calendar slots
        for i, post in enumerate(posts[:len(calendar)]):
            slot = calendar[i]
            slot['caption'] = post.caption
            slot['hashtags'] = post.hashtags

            # Find matching image
            matching_image = next(
                (img for img in images if img['post_index'] == i),
                None
            )
            if matching_image:
                slot['image_path'] = matching_image['filepath']

        self.scheduler.schedule_week(calendar)

        # Export schedules
        schedule_json = self.output_dir / 'schedule_today.json'
        schedule_csv = self.output_dir / 'schedule_today.csv'

        self.scheduler.export_to_json(str(schedule_json))
        ScheduleExporter.export_to_csv(self.scheduler.scheduled_posts, str(schedule_csv))

        logger.info(f"Exported schedule to {schedule_json} and {schedule_csv}")

    def export_for_mixpost(self) -> Optional[str]:
        """Export content for Mixpost scheduling"""
        logger.info("Exporting for Mixpost...")

        if not self.config.get('mixpost_enabled'):
            logger.info("Mixpost export disabled")
            return None

        try:
            mixpost_file = self.output_dir / 'mixpost_schedule.json'
            ScheduleExporter.export_to_mixpost_json(
                self.scheduler.scheduled_posts,
                str(mixpost_file)
            )
            logger.info(f"Exported Mixpost schedule to {mixpost_file}")
            return str(mixpost_file)
        except Exception as e:
            logger.error(f"Error exporting to Mixpost: {e}")
            return None

    def run(self) -> bool:
        """Execute the full pipeline"""
        try:
            logger.info("=" * 60)
            logger.info("Starting Rosier AutoPosting Pipeline")
            logger.info("=" * 60)

            # Step 1: Fetch data
            app_data = self.fetch_app_data()

            # Step 2: Generate content
            posts = self.generate_daily_content(app_data)

            # Step 3: Generate images
            images = self.generate_images(posts)

            # Step 4: Schedule posts
            self.schedule_posts(posts, images)

            # Step 5: Export for Mixpost
            self.export_for_mixpost()

            logger.info("=" * 60)
            logger.info("AutoPosting Pipeline completed successfully")
            logger.info(f"Generated {len(posts)} posts with {len(images)} images")
            logger.info("=" * 60)

            return True

        except Exception as e:
            logger.error(f"Pipeline failed: {e}", exc_info=True)
            return False


def main():
    """Main entry point"""
    pipeline = AutoPostingPipeline()
    success = pipeline.run()
    sys.exit(0 if success else 1)


if __name__ == '__main__':
    main()
