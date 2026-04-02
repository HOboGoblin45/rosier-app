"""
Analytics Tracker for Rosier Content Engine

Tracks content performance metrics and feeds insights back into
content generation to optimize for high-performing formats.
"""

import json
import csv
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Tuple
from dataclasses import dataclass, asdict, field
from pathlib import Path


@dataclass
class PostMetrics:
    """Post performance metrics"""
    post_id: str
    platform: str
    content_type: str
    posted_at: datetime
    caption_preview: str

    # Metrics
    impressions: int = 0
    reach: int = 0
    engagement: int = 0  # likes + comments + shares
    likes: int = 0
    comments: int = 0
    shares: int = 0
    saves: int = 0
    clicks: int = 0  # clicks to bio link

    # Calculated
    engagement_rate: float = field(default=0.0, init=False)
    save_rate: float = field(default=0.0, init=False)

    def __post_init__(self):
        """Calculate derived metrics"""
        self.engagement_rate = (
            (self.engagement / self.impressions * 100)
            if self.impressions > 0 else 0
        )
        self.save_rate = (
            (self.saves / self.impressions * 100)
            if self.impressions > 0 else 0
        )


class AnalyticsTracker:
    """Tracks content performance and generates insights"""

    def __init__(self, log_file: str = '/tmp/rosier_analytics.json'):
        """Initialize tracker"""
        self.log_file = Path(log_file)
        self.metrics: List[PostMetrics] = []
        self._load_existing_logs()

    def _load_existing_logs(self) -> None:
        """Load existing analytics from file"""
        if self.log_file.exists():
            try:
                with open(self.log_file, 'r') as f:
                    data = json.load(f)
                    # Load metrics (simplified for this example)
            except:
                pass

    def log_post(self, post_data: Dict) -> None:
        """Log a newly posted piece of content"""
        metric = PostMetrics(
            post_id=post_data.get('post_id'),
            platform=post_data.get('platform'),
            content_type=post_data.get('content_type'),
            posted_at=datetime.now(),
            caption_preview=post_data.get('caption', '')[:100]
        )
        self.metrics.append(metric)
        self._save_metrics()

    def update_metrics(self, post_id: str, metrics_data: Dict) -> None:
        """Update metrics for a posted piece"""
        for metric in self.metrics:
            if metric.post_id == post_id:
                metric.impressions = metrics_data.get('impressions', 0)
                metric.reach = metrics_data.get('reach', 0)
                metric.likes = metrics_data.get('likes', 0)
                metric.comments = metrics_data.get('comments', 0)
                metric.shares = metrics_data.get('shares', 0)
                metric.saves = metrics_data.get('saves', 0)
                metric.clicks = metrics_data.get('clicks', 0)
                metric.engagement = metric.likes + metric.comments + metric.shares
                metric.engagement_rate = (
                    (metric.engagement / metric.impressions * 100)
                    if metric.impressions > 0 else 0
                )
                metric.save_rate = (
                    (metric.saves / metric.impressions * 100)
                    if metric.impressions > 0 else 0
                )
                break

        self._save_metrics()

    def get_top_performing_content_types(self, days: int = 7) -> Dict[str, Dict]:
        """
        Returns top-performing content types by engagement rate.

        Args:
            days: Look back period

        Returns:
            Dict of content types with avg metrics
        """
        cutoff_date = datetime.now() - timedelta(days=days)
        recent_posts = [
            m for m in self.metrics
            if m.posted_at >= cutoff_date
        ]

        performance_by_type = {}

        for post in recent_posts:
            content_type = post.content_type

            if content_type not in performance_by_type:
                performance_by_type[content_type] = {
                    'posts': 0,
                    'avg_engagement_rate': 0,
                    'avg_reach': 0,
                    'avg_saves': 0,
                    'total_engagement': 0,
                    'top_post_id': None,
                    'top_engagement': 0
                }

            data = performance_by_type[content_type]
            data['posts'] += 1
            data['avg_engagement_rate'] += post.engagement_rate
            data['avg_reach'] += post.reach
            data['avg_saves'] += post.saves
            data['total_engagement'] += post.engagement

            # Track top post
            if post.engagement > data['top_engagement']:
                data['top_engagement'] = post.engagement
                data['top_post_id'] = post.post_id

        # Calculate averages
        for content_type in performance_by_type:
            data = performance_by_type[content_type]
            posts_count = data['posts']

            data['avg_engagement_rate'] = data['avg_engagement_rate'] / posts_count if posts_count > 0 else 0
            data['avg_reach'] = int(data['avg_reach'] / posts_count) if posts_count > 0 else 0
            data['avg_saves'] = int(data['avg_saves'] / posts_count) if posts_count > 0 else 0

        return dict(sorted(
            performance_by_type.items(),
            key=lambda x: x[1]['avg_engagement_rate'],
            reverse=True
        ))

    def get_platform_performance(self, days: int = 7) -> Dict[str, Dict]:
        """Returns performance breakdown by platform"""
        cutoff_date = datetime.now() - timedelta(days=days)
        recent_posts = [
            m for m in self.metrics
            if m.posted_at >= cutoff_date
        ]

        performance_by_platform = {}

        for post in recent_posts:
            platform = post.platform

            if platform not in performance_by_platform:
                performance_by_platform[platform] = {
                    'posts': 0,
                    'total_impressions': 0,
                    'total_engagement': 0,
                    'avg_engagement_rate': 0,
                    'total_clicks': 0
                }

            data = performance_by_platform[platform]
            data['posts'] += 1
            data['total_impressions'] += post.impressions
            data['total_engagement'] += post.engagement
            data['total_clicks'] += post.clicks

        # Calculate averages
        for platform in performance_by_platform:
            data = performance_by_platform[platform]
            posts = data['posts']
            if posts > 0:
                data['avg_engagement_rate'] = (
                    data['total_engagement'] / data['total_impressions'] * 100
                    if data['total_impressions'] > 0 else 0
                )

        return performance_by_platform

    def get_optimal_posting_times(self, platform: str, days: int = 14) -> Dict[int, Dict]:
        """
        Analyzes which hours get best engagement for a platform.

        Args:
            platform: Platform name
            days: Analysis period

        Returns:
            Dict of hour -> {avg_engagement_rate, avg_reach, post_count}
        """
        cutoff_date = datetime.now() - timedelta(days=days)
        platform_posts = [
            m for m in self.metrics
            if m.platform == platform and m.posted_at >= cutoff_date
        ]

        hourly_performance = {}

        for post in platform_posts:
            hour = post.posted_at.hour

            if hour not in hourly_performance:
                hourly_performance[hour] = {
                    'posts': 0,
                    'total_engagement': 0,
                    'total_reach': 0,
                    'total_impressions': 0
                }

            data = hourly_performance[hour]
            data['posts'] += 1
            data['total_engagement'] += post.engagement
            data['total_reach'] += post.reach
            data['total_impressions'] += post.impressions

        # Calculate averages and engagement rates
        for hour in hourly_performance:
            data = hourly_performance[hour]
            posts = data['posts']
            if posts > 0:
                data['avg_engagement'] = int(data['total_engagement'] / posts)
                data['avg_reach'] = int(data['total_reach'] / posts)
                data['engagement_rate'] = (
                    (data['total_engagement'] / data['total_impressions'] * 100)
                    if data['total_impressions'] > 0 else 0
                )

        # Sort by engagement rate
        return dict(sorted(
            hourly_performance.items(),
            key=lambda x: x[1].get('engagement_rate', 0),
            reverse=True
        ))

    def get_hashtag_performance(self, days: int = 7) -> Dict[str, int]:
        """
        Analyzes which hashtags drive best engagement.
        (Simplified - in production would parse hashtags from captions)
        """
        return {}

    def generate_daily_report(self) -> Dict:
        """Generates a daily performance report"""
        today = datetime.now().date()
        today_posts = [
            m for m in self.metrics
            if m.posted_at.date() == today
        ]

        if not today_posts:
            return {
                'date': today.isoformat(),
                'posts': 0,
                'message': 'No posts published today'
            }

        total_impressions = sum(m.impressions for m in today_posts)
        total_engagement = sum(m.engagement for m in today_posts)
        avg_engagement_rate = (
            (total_engagement / total_impressions * 100)
            if total_impressions > 0 else 0
        )

        return {
            'date': today.isoformat(),
            'posts_published': len(today_posts),
            'total_impressions': total_impressions,
            'total_engagement': total_engagement,
            'avg_engagement_rate': round(avg_engagement_rate, 2),
            'by_platform': {
                m.platform: {
                    'posts': len([x for x in today_posts if x.platform == m.platform]),
                    'impressions': sum(x.impressions for x in today_posts if x.platform == m.platform)
                }
                for m in today_posts
            },
            'top_post': max(today_posts, key=lambda x: x.engagement).post_id if today_posts else None
        }

    def generate_weekly_report(self) -> Dict:
        """Generates a weekly performance report"""
        week_start = datetime.now() - timedelta(days=7)
        week_posts = [m for m in self.metrics if m.posted_at >= week_start]

        if not week_posts:
            return {'message': 'No posts in past 7 days'}

        top_types = self.get_top_performing_content_types(days=7)
        platform_perf = self.get_platform_performance(days=7)

        return {
            'period': f"{(week_start).date()} to {datetime.now().date()}",
            'total_posts': len(week_posts),
            'total_impressions': sum(m.impressions for m in week_posts),
            'total_engagement': sum(m.engagement for m in week_posts),
            'avg_engagement_rate': round(
                sum(m.engagement_rate for m in week_posts) / len(week_posts),
                2
            ) if week_posts else 0,
            'top_content_types': dict(list(top_types.items())[:3]),
            'platform_performance': platform_perf,
            'recommendation': self._generate_recommendation(top_types, platform_perf)
        }

    def _generate_recommendation(self, content_types: Dict, platform_perf: Dict) -> str:
        """Generate AI recommendation for next week's content"""
        if not content_types:
            return "Insufficient data. Continue current posting strategy."

        top_type = list(content_types.keys())[0]
        top_engagement = content_types[top_type]['avg_engagement_rate']

        recommendation = f"Focus on '{top_type}' content (avg {top_engagement:.1f}% engagement). "

        best_platform = max(
            platform_perf.items(),
            key=lambda x: x[1].get('avg_engagement_rate', 0)
        )[0]

        recommendation += f"Prioritize {best_platform} for maximum reach."

        return recommendation

    def _save_metrics(self) -> None:
        """Save metrics to file"""
        self.log_file.parent.mkdir(parents=True, exist_ok=True)

        with open(self.log_file, 'w') as f:
            json.dump({
                'saved_at': datetime.now().isoformat(),
                'total_posts': len(self.metrics),
                'posts': [
                    {
                        'post_id': m.post_id,
                        'platform': m.platform,
                        'content_type': m.content_type,
                        'posted_at': m.posted_at.isoformat(),
                        'impressions': m.impressions,
                        'engagement': m.engagement,
                        'engagement_rate': round(m.engagement_rate, 2),
                        'saves': m.saves,
                        'clicks': m.clicks
                    }
                    for m in self.metrics
                ]
            }, f, indent=2)

    def export_to_csv(self, filepath: str) -> None:
        """Export metrics to CSV"""
        with open(filepath, 'w', newline='') as f:
            writer = csv.DictWriter(f, fieldnames=[
                'post_id', 'platform', 'content_type', 'posted_at',
                'impressions', 'reach', 'likes', 'comments', 'shares', 'saves',
                'engagement_rate', 'save_rate', 'clicks'
            ])
            writer.writeheader()

            for metric in self.metrics:
                writer.writerow({
                    'post_id': metric.post_id,
                    'platform': metric.platform,
                    'content_type': metric.content_type,
                    'posted_at': metric.posted_at.isoformat(),
                    'impressions': metric.impressions,
                    'reach': metric.reach,
                    'likes': metric.likes,
                    'comments': metric.comments,
                    'shares': metric.shares,
                    'saves': metric.saves,
                    'engagement_rate': round(metric.engagement_rate, 2),
                    'save_rate': round(metric.save_rate, 2),
                    'clicks': metric.clicks
                })


if __name__ == '__main__':
    # Test analytics tracker
    tracker = AnalyticsTracker()

    # Log some test posts
    tracker.log_post({
        'post_id': '2026-04-01_instagram_reel_trending',
        'platform': 'instagram_reel',
        'content_type': 'trending',
        'caption': 'Trending on Rosier this week...'
    })

    # Update with metrics
    tracker.update_metrics('2026-04-01_instagram_reel_trending', {
        'impressions': 15000,
        'reach': 12500,
        'likes': 1200,
        'comments': 85,
        'shares': 45,
        'saves': 450,
        'clicks': 320
    })

    # Generate reports
    daily_report = tracker.generate_daily_report()
    print("Daily Report:")
    print(json.dumps(daily_report, indent=2))

    tracker.export_to_csv('/tmp/analytics.csv')
    print("\nExported metrics to /tmp/analytics.csv")
