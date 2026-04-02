"""
Content Scheduling System for Rosier

Manages scheduling of generated content across platforms.
Optimizes posting times based on audience behavior.
"""

import json
from datetime import datetime, timedelta, time
from typing import List, Dict, Optional
from dataclasses import dataclass, asdict
from enum import Enum


class Platform(Enum):
    """Supported social platforms"""
    INSTAGRAM_REEL = 'instagram_reel'
    INSTAGRAM_STORY = 'instagram_story'
    INSTAGRAM_FEED = 'instagram_feed'
    TIKTOK = 'tiktok'
    THREADS = 'threads'


@dataclass
class ScheduledPost:
    """Scheduled content post"""
    post_id: str
    platform: Platform
    content_type: str
    caption: str
    hashtags: List[str]
    scheduled_time: datetime
    image_path: Optional[str] = None
    video_path: Optional[str] = None
    created_at: Optional[datetime] = None
    status: str = 'scheduled'  # scheduled, posted, failed


class ContentScheduler:
    """Schedules and optimizes content posting across platforms"""

    # Optimal posting times (EST) for Rosier's target audience: women 18-35
    OPTIMAL_TIMES = {
        'instagram_reel': {
            'primary': [
                (11, 0),      # 11 AM
                (14, 0),      # 2 PM
                (19, 0),      # 7 PM
            ],
            'secondary': [
                (8, 0),       # 8 AM
                (12, 0),      # 12 PM
                (18, 0),      # 6 PM
            ],
            'best_days': [1, 2, 3],  # Tue, Wed, Thu
        },
        'instagram_story': {
            'primary': [
                (8, 0),       # 8 AM
                (12, 0),      # 12 PM
                (17, 0),      # 5 PM
                (21, 0),      # 9 PM
            ],
            'secondary': [
                (10, 0),      # 10 AM
                (15, 0),      # 3 PM
                (19, 0),      # 7 PM
            ],
            'best_days': [0, 1, 2, 3, 4],  # Mon-Fri
        },
        'tiktok': {
            'primary': [
                (7, 0),       # 7 AM
                (12, 0),      # 12 PM
                (19, 0),      # 7 PM
                (22, 0),      # 10 PM
            ],
            'secondary': [
                (6, 0),       # 6 AM
                (14, 0),      # 2 PM
                (18, 0),      # 6 PM
                (20, 0),      # 8 PM
            ],
            'best_days': [2, 3, 4],  # Wed, Thu, Fri
        },
        'instagram_feed': {
            'primary': [
                (11, 0),      # 11 AM
                (19, 0),      # 7 PM
            ],
            'secondary': [
                (10, 0),      # 10 AM
                (14, 0),      # 2 PM
                (18, 0),      # 6 PM
            ],
            'best_days': [1, 3],  # Wed, Fri
        }
    }

    def __init__(self):
        """Initialize scheduler"""
        self.scheduled_posts: List[ScheduledPost] = []
        self.posting_schedule: Dict[str, List[datetime]] = {}

    def get_optimal_times(self, platform: str, audience: str = 'women_18_35', days_ahead: int = 7) -> List[datetime]:
        """
        Returns optimal posting times for platform.

        Args:
            platform: Platform name (instagram_reel, tiktok, etc)
            audience: Target audience segment
            days_ahead: Number of days to schedule ahead

        Returns:
            List of optimal datetime objects (EST)
        """
        if platform not in self.OPTIMAL_TIMES:
            return []

        optimal_times = self.OPTIMAL_TIMES[platform]
        best_days = optimal_times.get('best_days', [0, 1, 2, 3, 4])
        primary_times = optimal_times.get('primary', [])

        scheduled_datetimes = []
        now = datetime.now()

        for days_offset in range(1, days_ahead + 1):
            target_date = now + timedelta(days=days_offset)

            # Only schedule on best days
            if target_date.weekday() in best_days:
                for hour, minute in primary_times:
                    scheduled_dt = target_date.replace(hour=hour, minute=minute, second=0)
                    # Only schedule future times
                    if scheduled_dt > now:
                        scheduled_datetimes.append(scheduled_dt)

        return scheduled_datetimes[:7]  # Return next 7 optimal slots

    def create_content_calendar(self, days: int = 7) -> List[Dict]:
        """
        Auto-generates a content calendar from optimal times.

        Args:
            days: Number of days to plan

        Returns:
            List of scheduled slots with platform and time
        """
        calendar = []

        platforms_sequence = [
            'instagram_reel',
            'tiktok',
            'instagram_story',
            'instagram_reel',
            'tiktok',
            'instagram_story',
            'instagram_feed'
        ]

        content_types_sequence = [
            'trending',
            'app_demo',
            'brand_spotlight',
            'style_dna',
            'daily_drop',
            'ugc_prompt',
            'weekly_roundup'
        ]

        now = datetime.now()

        for day_offset in range(1, days + 1):
            target_date = now + timedelta(days=day_offset)

            # Rotate through platforms and content types
            platform = platforms_sequence[(day_offset - 1) % len(platforms_sequence)]
            content_type = content_types_sequence[(day_offset - 1) % len(content_types_sequence)]

            optimal_times = self.get_optimal_times(platform, days_ahead=1)
            if optimal_times:
                slot = {
                    'date': target_date.date(),
                    'platform': platform,
                    'content_type': content_type,
                    'optimal_times': optimal_times[:3],  # Top 3 optimal times
                    'scheduled_time': optimal_times[0],  # Default to first optimal
                    'status': 'planning'
                }
                calendar.append(slot)

        return calendar

    def schedule_week(self, content_calendar: List[Dict]) -> None:
        """
        Schedules a full week of content.

        Args:
            content_calendar: List of content slots with timing
        """
        for slot in content_calendar:
            platform_str = slot.get('platform', 'instagram_reel')

            try:
                platform = Platform[platform_str.upper()]
            except KeyError:
                platform = Platform.INSTAGRAM_REEL

            post = ScheduledPost(
                post_id=f"{slot['date']}_{platform_str}",
                platform=platform,
                content_type=slot.get('content_type', 'trending'),
                caption='',  # Will be populated by content generator
                hashtags=[],  # Will be populated by content generator
                scheduled_time=slot.get('scheduled_time'),
                created_at=datetime.now(),
                status='scheduled'
            )

            self.scheduled_posts.append(post)

    def get_schedule_status(self) -> Dict:
        """Returns current schedule status"""
        return {
            'total_scheduled': len(self.scheduled_posts),
            'next_post': min(
                [p for p in self.scheduled_posts if p.status == 'scheduled'],
                key=lambda p: p.scheduled_time,
                default=None
            ),
            'posted_today': len([
                p for p in self.scheduled_posts
                if p.status == 'posted' and p.scheduled_time.date() == datetime.now().date()
            ]),
            'scheduled_by_platform': self._get_platform_counts()
        }

    def _get_platform_counts(self) -> Dict[str, int]:
        """Count scheduled posts by platform"""
        counts = {}
        for post in self.scheduled_posts:
            key = post.platform.value
            counts[key] = counts.get(key, 0) + 1
        return counts

    def export_to_json(self, filepath: str) -> None:
        """Export schedule to JSON"""
        schedule_data = {
            'exported_at': datetime.now().isoformat(),
            'total_posts': len(self.scheduled_posts),
            'posts': [
                {
                    'post_id': p.post_id,
                    'platform': p.platform.value,
                    'content_type': p.content_type,
                    'scheduled_time': p.scheduled_time.isoformat(),
                    'status': p.status
                }
                for p in self.scheduled_posts
            ]
        }

        with open(filepath, 'w') as f:
            json.dump(schedule_data, f, indent=2)

    def get_next_posting_slot(self, platform: Optional[str] = None) -> Optional[ScheduledPost]:
        """Returns the next unposted content slot"""
        unposted = [p for p in self.scheduled_posts if p.status == 'scheduled']

        if platform:
            unposted = [p for p in unposted if p.platform.value == platform]

        if unposted:
            return min(unposted, key=lambda p: p.scheduled_time)

        return None

    def mark_as_posted(self, post_id: str) -> None:
        """Mark a post as published"""
        for post in self.scheduled_posts:
            if post.post_id == post_id:
                post.status = 'posted'
                break

    def reschedule_post(self, post_id: str, new_time: datetime) -> None:
        """Reschedule a post to a different time"""
        for post in self.scheduled_posts:
            if post.post_id == post_id:
                post.scheduled_time = new_time
                break

    def get_daily_posts(self, date_str: str) -> List[ScheduledPost]:
        """Get all posts scheduled for a specific date"""
        from datetime import datetime as dt

        target_date = dt.strptime(date_str, '%Y-%m-%d').date()

        return [
            p for p in self.scheduled_posts
            if p.scheduled_time.date() == target_date
        ]

    def suggest_best_time_for_platform(self, platform: str) -> datetime:
        """Suggests the best time to post next for a given platform"""
        times = self.get_optimal_times(platform, days_ahead=1)
        return times[0] if times else datetime.now() + timedelta(hours=1)


class ScheduleExporter:
    """Exports content schedule to external tools (Mixpost, CSV, etc)"""

    @staticmethod
    def export_to_mixpost_json(posts: List[ScheduledPost], filepath: str) -> None:
        """
        Exports schedule in Mixpost API format.

        Mixpost expects JSON with specific fields for scheduling.
        """
        mixpost_format = {
            'workspace': 'rosier_content',
            'posts': [
                {
                    'content': post.caption,
                    'media': [post.image_path] if post.image_path else [],
                    'platforms': [post.platform.value],
                    'schedule': {
                        'date': post.scheduled_time.isoformat(),
                        'timezone': 'America/New_York'
                    },
                    'hashtags': ' '.join(post.hashtags)
                }
                for post in posts
            ]
        }

        with open(filepath, 'w') as f:
            json.dump(mixpost_format, f, indent=2)

    @staticmethod
    def export_to_csv(posts: List[ScheduledPost], filepath: str) -> None:
        """Export schedule as CSV for spreadsheet import"""
        import csv

        with open(filepath, 'w', newline='') as f:
            writer = csv.writer(f)
            writer.writerow([
                'Date', 'Time (EST)', 'Platform', 'Content Type',
                'Caption', 'Hashtags', 'Image Path', 'Status'
            ])

            for post in posts:
                writer.writerow([
                    post.scheduled_time.date(),
                    post.scheduled_time.time(),
                    post.platform.value,
                    post.content_type,
                    post.caption[:100],  # Truncate caption
                    ' '.join(post.hashtags),
                    post.image_path or 'N/A',
                    post.status
                ])


if __name__ == '__main__':
    # Test the scheduler
    scheduler = ContentScheduler()

    # Get next week's optimal times
    optimal_times = scheduler.get_optimal_times('instagram_reel', days_ahead=7)
    print(f"Optimal Instagram Reel times (next 7 days): {len(optimal_times)} slots")
    for t in optimal_times[:3]:
        print(f"  - {t}")

    # Create a content calendar
    calendar = scheduler.create_content_calendar(days=7)
    print(f"\nGenerated {len(calendar)}-day content calendar:")
    for slot in calendar[:3]:
        print(f"  {slot['date']}: {slot['platform']} - {slot['content_type']}")

    # Schedule the week
    scheduler.schedule_week(calendar)
    status = scheduler.get_schedule_status()
    print(f"\nSchedule status:")
    print(f"  Total scheduled: {status['total_scheduled']}")
    print(f"  By platform: {status['scheduled_by_platform']}")

    # Export
    scheduler.export_to_json('/tmp/schedule.json')
    ScheduleExporter.export_to_csv(scheduler.scheduled_posts, '/tmp/schedule.csv')
    print("\nExported to /tmp/schedule.json and /tmp/schedule.csv")
