"""
Rosier SEO Engine - Blog Generator
Auto-generates SEO-optimized blog posts from app data, curated brand lists, and trending insights.
"""

from datetime import datetime, timedelta
from typing import Dict, List, Optional
import json

class BlogGenerator:
    """Auto-generates SEO-optimized blog posts for Rosier blog."""

    def __init__(self):
        self.brand_roster = [
            "Ganni", "Khaite", "The Row", "Jacquemus", "Staud", "Nanushka",
            "Reformation", "Deiji Studios", "Sandy Liang", "Lemaire", "Baserange",
            "Collina Strada", "ROTATE", "Olivela", "Auralee", "Needles", "Visvim",
            "Jil Sander", "COS", "Ami", "Raf Simons", "Margiela", "Rick Owens",
            "Undercover", "Craig Green", "Sacai", "C.P. Company", "Stone Island",
            "Dries Van Noten", "Haider Ackermann", "Damir Doma", "Lemaire",
            "Lemaire", "Issey Miyake", "Comme des Garçons", "Yohji Yamamoto"
        ]

        self.design_colors = {
            "primary": "#1A1A2E",
            "accent": "#C4A77D",
            "surface": "#F8F6F3",
            "text": "#1A1A1A",
            "text_secondary": "#6B6B6B",
            "text_tertiary": "#9B9B9B",
            "border": "#E8E8E8"
        }

    def generate_html_template(self,
                               title: str,
                               meta_description: str,
                               h1: str,
                               category: str,
                               content_html: str,
                               related_posts: List[Dict],
                               publication_date: Optional[str] = None,
                               article_schema: Optional[Dict] = None) -> str:
        """Generate complete, valid HTML blog post with all SEO tags."""

        if not publication_date:
            publication_date = datetime.now().strftime("%Y-%m-%d")

        # Generate JSON-LD Article schema
        if not article_schema:
            article_schema = {
                "@context": "https://schema.org",
                "@type": "BlogPosting",
                "headline": h1,
                "description": meta_description,
                "image": "https://rosier.app/og-image.png",
                "datePublished": publication_date,
                "dateModified": publication_date,
                "author": {
                    "@type": "Organization",
                    "name": "Rosier"
                },
                "publisher": {
                    "@type": "Organization",
                    "name": "Rosier",
                    "logo": {
                        "@type": "ImageObject",
                        "url": "https://rosier.app/logo.png"
                    }
                }
            }

        # Create related posts HTML
        related_html = self._generate_related_posts(related_posts)

        html = f"""<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="description" content="{meta_description}">
    <meta name="theme-color" content="{self.design_colors['primary']}">

    <!-- Open Graph Tags -->
    <meta property="og:title" content="{title}">
    <meta property="og:description" content="{meta_description}">
    <meta property="og:image" content="https://rosier.app/og-image.png">
    <meta property="og:type" content="article">
    <meta property="og:site_name" content="Rosier">

    <!-- Twitter Card Tags -->
    <meta name="twitter:card" content="summary_large_image">
    <meta name="twitter:title" content="{title}">
    <meta name="twitter:description" content="{meta_description}">
    <meta name="twitter:site" content="@rosier_app">

    <title>{title}</title>

    <!-- JSON-LD Structured Data -->
    <script type="application/ld+json">
    {json.dumps(article_schema)}
    </script>

    <style>
        * {{
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }}

        @import url('https://rsms.me/inter/inter.css');

        :root {{
            --primary: {self.design_colors['primary']};
            --accent: {self.design_colors['accent']};
            --surface: {self.design_colors['surface']};
            --text: {self.design_colors['text']};
            --text-secondary: {self.design_colors['text_secondary']};
            --text-tertiary: {self.design_colors['text_tertiary']};
            --border: {self.design_colors['border']};
        }}

        html {{
            scroll-behavior: smooth;
        }}

        body {{
            font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
            color: var(--text);
            background: white;
            line-height: 1.7;
        }}

        /* HEADER */
        header {{
            padding: 24px 20px;
            border-bottom: 1px solid var(--border);
            background: white;
            position: sticky;
            top: 0;
            z-index: 100;
        }}

        .header-container {{
            max-width: 1200px;
            margin: 0 auto;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }}

        .logo {{
            font-size: 20px;
            font-weight: 700;
            color: var(--primary);
            text-decoration: none;
            letter-spacing: -0.5px;
        }}

        .nav-links {{
            display: flex;
            gap: 32px;
            list-style: none;
        }}

        .nav-links a {{
            text-decoration: none;
            color: var(--text-secondary);
            font-size: 14px;
            font-weight: 500;
            transition: color 0.2s;
        }}

        .nav-links a:hover {{
            color: var(--accent);
        }}

        @media (max-width: 768px) {{
            .nav-links {{
                display: none;
            }}
        }}

        /* ARTICLE CONTAINER */
        .article-wrapper {{
            max-width: 800px;
            margin: 0 auto;
            padding: 80px 20px;
        }}

        /* ARTICLE HEADER */
        .article-header {{
            margin-bottom: 60px;
        }}

        .article-category {{
            display: inline-block;
            padding: 6px 14px;
            background: rgba(196, 167, 125, 0.1);
            color: var(--accent);
            border-radius: 6px;
            font-size: 12px;
            font-weight: 600;
            margin-bottom: 16px;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }}

        .article-title {{
            font-size: clamp(28px, 6vw, 44px);
            font-weight: 700;
            line-height: 1.3;
            margin-bottom: 20px;
            color: var(--text);
        }}

        .article-meta {{
            display: flex;
            flex-wrap: wrap;
            gap: 20px;
            font-size: 14px;
            color: var(--text-secondary);
            border-bottom: 1px solid var(--border);
            padding-bottom: 24px;
        }}

        .article-meta span {{
            display: flex;
            align-items: center;
            gap: 6px;
        }}

        /* ARTICLE CONTENT */
        .article-content {{
            font-size: 16px;
            color: var(--text);
            line-height: 1.8;
        }}

        .article-content h2 {{
            font-size: 28px;
            font-weight: 700;
            margin: 48px 0 20px;
            color: var(--text);
            line-height: 1.3;
        }}

        .article-content h3 {{
            font-size: 20px;
            font-weight: 700;
            margin: 36px 0 16px;
            color: var(--text);
        }}

        .article-content p {{
            margin-bottom: 20px;
            line-height: 1.9;
        }}

        .article-content ul,
        .article-content ol {{
            margin: 24px 0 24px 24px;
            line-height: 1.9;
        }}

        .article-content li {{
            margin-bottom: 12px;
        }}

        .article-content a {{
            color: var(--accent);
            text-decoration: none;
            font-weight: 500;
            transition: opacity 0.2s;
        }}

        .article-content a:hover {{
            opacity: 0.8;
            text-decoration: underline;
        }}

        .article-content blockquote {{
            border-left: 4px solid var(--accent);
            padding: 20px 24px;
            margin: 32px 0;
            background: var(--surface);
            font-style: italic;
            color: var(--text-secondary);
        }}

        /* HIGHLIGHT BOX */
        .highlight-box {{
            background: linear-gradient(135deg, rgba(196, 167, 125, 0.05) 0%, rgba(26, 26, 46, 0.02) 100%);
            border: 1px solid var(--border);
            border-radius: 12px;
            padding: 28px;
            margin: 40px 0;
        }}

        .highlight-box h3 {{
            color: var(--accent);
            margin-top: 0;
        }}

        /* CTA SECTION */
        .article-cta {{
            background: var(--surface);
            border: 1px solid var(--border);
            border-radius: 12px;
            padding: 40px;
            margin: 60px 0;
            text-align: center;
        }}

        .article-cta h3 {{
            font-size: 22px;
            margin-bottom: 12px;
            color: var(--text);
        }}

        .article-cta p {{
            font-size: 15px;
            color: var(--text-secondary);
            margin-bottom: 24px;
        }}

        .cta-button {{
            display: inline-block;
            padding: 14px 32px;
            background: var(--primary);
            color: white;
            text-decoration: none;
            border-radius: 8px;
            font-weight: 600;
            font-size: 15px;
            transition: all 0.2s;
        }}

        .cta-button:hover {{
            transform: translateY(-2px);
            box-shadow: 0 8px 24px rgba(0, 0, 0, 0.15);
        }}

        /* SOCIAL SHARE */
        .social-share {{
            display: flex;
            gap: 16px;
            margin: 40px 0;
            padding: 24px 0;
            border-top: 1px solid var(--border);
            border-bottom: 1px solid var(--border);
        }}

        .social-share-label {{
            font-weight: 600;
            color: var(--text);
            margin-right: 16px;
            white-space: nowrap;
        }}

        .social-share-buttons {{
            display: flex;
            gap: 12px;
        }}

        .share-btn {{
            width: 44px;
            height: 44px;
            border-radius: 50%;
            background: var(--surface);
            border: 1px solid var(--border);
            display: flex;
            align-items: center;
            justify-content: center;
            cursor: pointer;
            transition: all 0.2s;
            text-decoration: none;
            color: var(--text-secondary);
            font-size: 18px;
        }}

        .share-btn:hover {{
            background: var(--accent);
            color: white;
            border-color: var(--accent);
        }}

        /* RELATED POSTS */
        .related-posts {{
            margin-top: 80px;
            padding-top: 40px;
            border-top: 1px solid var(--border);
        }}

        .related-posts-title {{
            font-size: 22px;
            font-weight: 700;
            margin-bottom: 32px;
            color: var(--text);
        }}

        .related-posts-grid {{
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 24px;
        }}

        .related-post-card {{
            padding: 20px;
            background: var(--surface);
            border: 1px solid var(--border);
            border-radius: 8px;
            transition: all 0.2s;
            text-decoration: none;
        }}

        .related-post-card:hover {{
            border-color: var(--accent);
            transform: translateY(-2px);
        }}

        .related-post-title {{
            font-size: 15px;
            font-weight: 600;
            color: var(--text);
            margin-bottom: 8px;
        }}

        .related-post-category {{
            font-size: 12px;
            color: var(--text-secondary);
        }}

        /* FOOTER */
        footer {{
            padding: 40px 20px;
            background: var(--primary);
            color: white;
            text-align: center;
            border-top: 1px solid rgba(196, 167, 125, 0.1);
            margin-top: 80px;
        }}

        .footer-content {{
            max-width: 1200px;
            margin: 0 auto;
            display: flex;
            flex-direction: column;
            align-items: center;
            gap: 24px;
        }}

        .footer-text {{
            font-size: 13px;
            opacity: 0.8;
        }}

        .social-links {{
            display: flex;
            gap: 20px;
            justify-content: center;
        }}

        .social-link {{
            color: var(--accent);
            text-decoration: none;
            font-weight: 600;
            font-size: 13px;
            transition: opacity 0.2s;
        }}

        .social-link:hover {{
            opacity: 0.8;
        }}

        .footer-logo {{
            font-size: 18px;
            font-weight: 700;
            color: var(--accent);
        }}

        @media (max-width: 768px) {{
            .article-wrapper {{
                padding: 40px 20px;
            }}

            .article-title {{
                font-size: 28px;
            }}

            .article-content h2 {{
                font-size: 24px;
            }}

            .article-meta {{
                gap: 12px;
            }}

            .social-share {{
                flex-direction: column;
            }}

            .social-share-label {{
                margin-right: 0;
            }}

            .related-posts-grid {{
                grid-template-columns: 1fr;
            }}
        }}
    </style>
</head>
<body>
    <!-- HEADER -->
    <header>
        <div class="header-container">
            <a href="/" class="logo">✦ Rosier</a>
            <nav>
                <ul class="nav-links">
                    <li><a href="/blog/">← Back to Blog</a></li>
                    <li><a href="/">Back to App</a></li>
                </ul>
            </nav>
        </div>
    </header>

    <!-- ARTICLE -->
    <article class="article-wrapper">
        <div class="article-header">
            <span class="article-category">{category}</span>
            <h1 class="article-title">{h1}</h1>
            <div class="article-meta">
                <span>📅 Published {publication_date}</span>
                <span>📍 by Rosier</span>
            </div>
        </div>

        <div class="article-content">
            {content_html}
        </div>

        <!-- SOCIAL SHARE -->
        <div class="social-share">
            <span class="social-share-label">Share this article:</span>
            <div class="social-share-buttons">
                <a href="https://twitter.com/intent/tweet?url=https://rosier.app/blog/&text={title}&via=rosier_app" class="share-btn" title="Share on Twitter" target="_blank" rel="noopener noreferrer">𝕏</a>
                <a href="https://www.facebook.com/sharer/sharer.php?u=https://rosier.app/blog/" class="share-btn" title="Share on Facebook" target="_blank" rel="noopener noreferrer">f</a>
                <a href="https://www.linkedin.com/sharing/share-offsite/?url=https://rosier.app/blog/" class="share-btn" title="Share on LinkedIn" target="_blank" rel="noopener noreferrer">in</a>
                <a href="https://www.pinterest.com/pin/create/button/?url=https://rosier.app/blog/&description={meta_description}" class="share-btn" title="Share on Pinterest" target="_blank" rel="noopener noreferrer">📌</a>
            </div>
        </div>

        {related_html}
    </article>

    <!-- FOOTER -->
    <footer>
        <div class="footer-content">
            <div class="footer-logo">✦ Rosier</div>
            <div class="footer-text">Discover niche fashion. Save what you love. Never miss a sale.</div>
            <div class="social-links">
                <a href="https://instagram.com/rosier_app" class="social-link" target="_blank" rel="noopener noreferrer">Instagram</a>
                <a href="https://twitter.com/rosier_app" class="social-link" target="_blank" rel="noopener noreferrer">Twitter</a>
                <a href="/blog/" class="social-link">Blog</a>
                <a href="/privacy" class="social-link">Privacy</a>
                <a href="/terms" class="social-link">Terms</a>
            </div>
            <div class="footer-text" style="margin-top: 20px; padding-top: 20px; border-top: 1px solid rgba(196, 167, 125, 0.1);">
                © 2026 Rosier. All rights reserved.
            </div>
        </div>
    </footer>
</body>
</html>
"""
        return html

    def _generate_related_posts(self, related_posts: List[Dict]) -> str:
        """Generate HTML for related posts section."""
        if not related_posts:
            return ""

        posts_html = ""
        for post in related_posts:
            posts_html += f"""
                <a href="{post['url']}" class="related-post-card">
                    <div class="related-post-title">{post['title']}</div>
                    <div class="related-post-category">{post['category']} • {post['read_time']} min read</div>
                </a>
            """

        return f"""
        <!-- RELATED POSTS -->
        <div class="related-posts">
            <h2 class="related-posts-title">Read Next</h2>
            <div class="related-posts-grid">
                {posts_html}
            </div>
        </div>
        """

    def add_cta_section(self) -> str:
        """Generate a standard CTA section."""
        return """
        <div class="article-cta">
            <h3>Discover Niche Fashion on Rosier</h3>
            <p>This is exactly what Rosier is built for: discovering contemporary brands and styles curated through authentic taste, not algorithmic feeds. Swipe to discover, save what you love, get price alerts on your favorites.</p>
            <a href="/" class="cta-button">Join the Waitlist</a>
        </div>
        """


if __name__ == "__main__":
    generator = BlogGenerator()
    print("Blog Generator initialized. Ready to generate SEO-optimized blog posts.")
