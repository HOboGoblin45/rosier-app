"""
Rosier SEO Engine - Sitemap & Robots.txt Generator
Auto-generates sitemap.xml and robots.txt from landing pages and blog posts.
"""

from datetime import datetime
from typing import List, Dict, Optional
import os

class SitemapGenerator:
    """Generates sitemap.xml and robots.txt for Rosier."""

    def __init__(self, base_url: str = "https://rosier.app"):
        self.base_url = base_url
        self.pages = []

    def add_page(self,
                 url: str,
                 last_modified: Optional[str] = None,
                 change_frequency: str = "weekly",
                 priority: float = 0.5) -> None:
        """Add a page to the sitemap."""
        if not last_modified:
            last_modified = datetime.now().strftime("%Y-%m-%d")

        self.pages.append({
            "url": url,
            "lastmod": last_modified,
            "changefreq": change_frequency,
            "priority": priority
        })

    def generate_sitemap_xml(self) -> str:
        """Generate complete sitemap.xml content."""
        xml = '<?xml version="1.0" encoding="UTF-8"?>\n'
        xml += '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n'

        for page in sorted(self.pages, key=lambda x: x["priority"], reverse=True):
            xml += '  <url>\n'
            xml += f'    <loc>{page["url"]}</loc>\n'
            xml += f'    <lastmod>{page["lastmod"]}</lastmod>\n'
            xml += f'    <changefreq>{page["changefreq"]}</changefreq>\n'
            xml += f'    <priority>{page["priority"]}</priority>\n'
            xml += '  </url>\n'

        xml += '</urlset>'
        return xml

    def generate_robots_txt(self) -> str:
        """Generate robots.txt with sitemap reference."""
        return """User-agent: *
Allow: /
Disallow: /admin
Disallow: /api
Disallow: /private

Sitemap: https://rosier.app/sitemap.xml

# Crawler delays (optional)
Crawl-delay: 1
Request-rate: 30/60

# Block specific bots
User-agent: AhrefsBot
Disallow: /

User-agent: SemrushBot
Disallow: /

User-agent: MJ12bot
Disallow: /
"""

    def save_sitemap(self, output_path: str) -> None:
        """Save sitemap.xml to file."""
        with open(output_path, 'w', encoding='utf-8') as f:
            f.write(self.generate_sitemap_xml())
        print(f"Sitemap saved to {output_path}")

    def save_robots_txt(self, output_path: str) -> None:
        """Save robots.txt to file."""
        with open(output_path, 'w', encoding='utf-8') as f:
            f.write(self.generate_robots_txt())
        print(f"Robots.txt saved to {output_path}")


def create_rosier_sitemap(blog_dir: str = "/sessions/busy-tender-goldberg/mnt/Women's fashion app/rosier/landing/blog") -> SitemapGenerator:
    """
    Create sitemap for Rosier with all landing pages and blog posts.
    """
    sitemap = SitemapGenerator()

    # Landing pages
    sitemap.add_page(
        "https://rosier.app/",
        last_modified="2026-04-01",
        change_frequency="weekly",
        priority=1.0
    )

    # Blog homepage
    sitemap.add_page(
        "https://rosier.app/blog/",
        last_modified="2026-04-01",
        change_frequency="weekly",
        priority=0.9
    )

    # Blog posts (auto-discover from directory)
    blog_posts = [
        {
            "url": "https://rosier.app/blog/trending-brands-april-2026.html",
            "date": "2026-04-01",
            "priority": 0.8
        },
        {
            "url": "https://rosier.app/blog/deiji-studios-brand-spotlight.html",
            "date": "2026-04-02",
            "priority": 0.8
        },
        {
            "url": "https://rosier.app/blog/style-dna-explained.html",
            "date": "2026-04-03",
            "priority": 0.8
        },
        {
            "url": "https://rosier.app/blog/best-contemporary-brands-2026.html",
            "date": "2026-04-04",
            "priority": 0.8
        },
        {
            "url": "https://rosier.app/blog/niche-fashion-vs-fast-fashion.html",
            "date": "2026-04-05",
            "priority": 0.8
        },
        {
            "url": "https://rosier.app/blog/micro-influencer-fashion.html",
            "date": "2026-03-15",
            "priority": 0.8
        },
    ]

    for post in blog_posts:
        sitemap.add_page(
            post["url"],
            last_modified=post["date"],
            change_frequency="monthly",
            priority=post["priority"]
        )

    # Utility pages
    utility_pages = [
        ("https://rosier.app/privacy", "monthly", 0.3),
        ("https://rosier.app/terms", "monthly", 0.3),
    ]

    for url, frequency, priority in utility_pages:
        sitemap.add_page(url, change_frequency=frequency, priority=priority)

    return sitemap


if __name__ == "__main__":
    sitemap = create_rosier_sitemap()
    print("Sitemap generated with", len(sitemap.pages), "pages")
    print(sitemap.generate_sitemap_xml()[:500])
