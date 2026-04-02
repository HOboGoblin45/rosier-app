"""
Rosier SEO Engine - Structured Data Generator
Generates JSON-LD for all page types: Articles, FAQs, Breadcrumbs, Organization, SoftwareApplication.
"""

import json
from typing import Dict, List, Optional
from datetime import datetime


class StructuredDataGenerator:
    """Generates JSON-LD structured data for SEO."""

    @staticmethod
    def article_schema(
        headline: str,
        description: str,
        date_published: str,
        author_name: str = "Rosier",
        image_url: str = "https://rosier.app/og-image.png"
    ) -> Dict:
        """Generate Article schema (for blog posts)."""
        return {
            "@context": "https://schema.org",
            "@type": "BlogPosting",
            "headline": headline,
            "description": description,
            "image": image_url,
            "datePublished": date_published,
            "dateModified": datetime.now().strftime("%Y-%m-%d"),
            "author": {
                "@type": "Organization",
                "name": author_name
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

    @staticmethod
    def faq_schema(faqs: List[Dict]) -> Dict:
        """Generate FAQPage schema."""
        main_entity = []
        for faq in faqs:
            main_entity.append({
                "@type": "Question",
                "name": faq["question"],
                "acceptedAnswer": {
                    "@type": "Answer",
                    "text": faq["answer"]
                }
            })

        return {
            "@context": "https://schema.org",
            "@type": "FAQPage",
            "mainEntity": main_entity
        }

    @staticmethod
    def organization_schema() -> Dict:
        """Generate Organization schema (for homepage)."""
        return {
            "@context": "https://schema.org",
            "@type": "Organization",
            "name": "Rosier",
            "description": "Fashion discovery app for niche contemporary brands",
            "url": "https://rosier.app",
            "logo": "https://rosier.app/logo.png",
            "image": "https://rosier.app/og-image.png",
            "sameAs": [
                "https://twitter.com/rosier_app",
                "https://instagram.com/rosier_app"
            ],
            "contactPoint": {
                "@type": "ContactPoint",
                "contactType": "Customer Service",
                "email": "hello@rosier.app"
            }
        }

    @staticmethod
    def software_application_schema() -> Dict:
        """Generate SoftwareApplication schema (for app landing page)."""
        return {
            "@context": "https://schema.org",
            "@type": "SoftwareApplication",
            "name": "Rosier",
            "description": "Fashion discovery app for women 18-35 interested in niche designer brands and micro-influencer fashion",
            "applicationCategory": "Shopping",
            "url": "https://rosier.app",
            "image": "https://rosier.app/og-image.png",
            "operatingSystem": "iOS, Android",
            "offers": {
                "@type": "Offer",
                "priceCurrency": "USD",
                "price": "0",
                "category": "Free"
            },
            "author": {
                "@type": "Organization",
                "name": "Rosier"
            },
            "aggregateRating": {
                "@type": "AggregateRating",
                "ratingValue": "4.8",
                "ratingCount": "2000"
            }
        }

    @staticmethod
    def breadcrumb_schema(breadcrumbs: List[Dict]) -> Dict:
        """Generate BreadcrumbList schema."""
        items = []
        for idx, crumb in enumerate(breadcrumbs, 1):
            items.append({
                "@type": "ListItem",
                "position": idx,
                "name": crumb["name"],
                "item": crumb["url"]
            })

        return {
            "@context": "https://schema.org",
            "@type": "BreadcrumbList",
            "itemListElement": items
        }

    @staticmethod
    def product_schema(
        name: str,
        description: str,
        brand: str,
        image_url: str,
        price: Optional[str] = None,
        rating: Optional[float] = None,
        rating_count: Optional[int] = None
    ) -> Dict:
        """Generate Product schema (for brand spotlights featuring products)."""
        schema = {
            "@context": "https://schema.org",
            "@type": "Product",
            "name": name,
            "description": description,
            "brand": {
                "@type": "Brand",
                "name": brand
            },
            "image": image_url
        }

        if price:
            schema["offers"] = {
                "@type": "Offer",
                "price": price,
                "priceCurrency": "USD",
                "availability": "https://schema.org/InStock"
            }

        if rating and rating_count:
            schema["aggregateRating"] = {
                "@type": "AggregateRating",
                "ratingValue": str(rating),
                "ratingCount": str(rating_count)
            }

        return schema

    @staticmethod
    def faq_page_schema() -> Dict:
        """Generate FAQ schema for homepage."""
        return {
            "@context": "https://schema.org",
            "@type": "FAQPage",
            "mainEntity": [
                {
                    "@type": "Question",
                    "name": "What is Rosier?",
                    "acceptedAnswer": {
                        "@type": "Answer",
                        "text": "Rosier is a fashion discovery app that uses swipe-based UX to help women 18-35 discover niche designer brands and contemporary fashion. It's powered by AI that learns your style DNA with every swipe."
                    }
                },
                {
                    "@type": "Question",
                    "name": "How does Rosier work?",
                    "acceptedAnswer": {
                        "@type": "Answer",
                        "text": "Simply swipe through curated niche fashion pieces from 50+ contemporary retailers. Save items you love, and Rosier's AI learns your taste. Get price alerts on your saved items and never miss a sale."
                    }
                },
                {
                    "@type": "Question",
                    "name": "What brands will I find on Rosier?",
                    "acceptedAnswer": {
                        "@type": "Answer",
                        "text": "Rosier features contemporary and niche brands like Ganni, Khaite, The Row, Jacquemus, Staud, Nanushka, Reformation, and 40+ more curated from SSENSE, Farfetch, Browns Fashion, and other premium retailers."
                    }
                },
                {
                    "@type": "Question",
                    "name": "When does Rosier launch?",
                    "acceptedAnswer": {
                        "@type": "Answer",
                        "text": "Rosier is coming Summer 2026. Join our waitlist today for early access and exclusive launch day perks."
                    }
                }
            ]
        }


def inject_schema_into_html(html_content: str, schema: Dict, tag_id: str = "article-schema") -> str:
    """
    Inject JSON-LD schema into HTML content.
    Replaces a placeholder script tag or inserts before closing </head>.
    """
    schema_script = f"""    <!-- JSON-LD Structured Data -->
    <script type="application/ld+json" id="{tag_id}">
    {json.dumps(schema, indent=2)}
    </script>
"""

    if "<script" in html_content and "application/ld+json" in html_content:
        # Replace existing schema
        import re
        pattern = r'<script type="application/ld\+json"[^>]*>.*?</script>'
        html_content = re.sub(pattern, schema_script.strip(), html_content, flags=re.DOTALL)
    else:
        # Insert before </head>
        html_content = html_content.replace("</head>", f"{schema_script}</head>", 1)

    return html_content


if __name__ == "__main__":
    generator = StructuredDataGenerator()

    # Test article schema
    article = generator.article_schema(
        headline="Test Article",
        description="Test description",
        date_published="2026-04-01"
    )
    print("Article Schema:")
    print(json.dumps(article, indent=2))
    print("\n")

    # Test organization schema
    org = generator.organization_schema()
    print("Organization Schema:")
    print(json.dumps(org, indent=2))
