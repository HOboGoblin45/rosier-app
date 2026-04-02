"""Product ingestion pipeline service for importing from affiliate networks and retailers."""

import csv
import logging
import re
from dataclasses import dataclass
from datetime import datetime, timezone
from typing import Optional

import httpx
from sqlalchemy import and_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import Brand, Product, Retailer
from app.core.redis import delete_cache

logger = logging.getLogger(__name__)


@dataclass
class IngestionProduct:
    """Normalized product data from ingestion."""

    external_id: str
    retailer_id: str
    brand_name: Optional[str]
    name: str
    description: Optional[str]
    category: Optional[str]
    subcategory: Optional[str]
    current_price: float
    original_price: Optional[float]
    currency: str
    colors: Optional[dict]
    sizes_available: Optional[dict]
    image_urls: list[str]
    product_url: str
    tags: dict[str, float]


class RakutenAPIClient:
    """Rakuten Advertising API client for product feed ingestion."""

    BASE_URL = "https://api.rakutenmarketing.com/feed/v1"

    def __init__(self, api_key: str, api_secret: str):
        """Initialize Rakuten client."""
        self.api_key = api_key
        self.api_secret = api_secret
        self.client = httpx.AsyncClient(timeout=30.0)

    async def get_products(
        self,
        merchant_id: str,
        limit: int = 1000,
        offset: int = 0,
    ) -> list[dict]:
        """
        Fetch product feed from Rakuten API.

        Args:
            merchant_id: Rakuten merchant/program ID
            limit: Maximum products to fetch
            offset: Offset for pagination

        Returns:
            List of product dictionaries from API
        """
        try:
            params = {
                "apikey": self.api_key,
                "mid": merchant_id,
                "limit": limit,
                "offset": offset,
            }
            url = f"{self.BASE_URL}/products"
            response = await self.client.get(url, params=params)
            response.raise_for_status()
            data = response.json()
            return data.get("products", [])
        except Exception as e:
            logger.error(f"Rakuten API error: {e}")
            return []

    async def close(self) -> None:
        """Close HTTP client."""
        await self.client.aclose()


class AwninAPIClient:
    """Awin (formerly Daisycon) API client for product feed ingestion."""

    BASE_URL = "https://api.awin.com"

    def __init__(self, api_key: str):
        """Initialize Awin client."""
        self.api_key = api_key
        self.client = httpx.AsyncClient(
            timeout=30.0,
            headers={"Authorization": f"Bearer {api_key}"},
        )

    async def get_products(
        self,
        advertiser_id: str,
        limit: int = 1000,
        offset: int = 0,
    ) -> list[dict]:
        """
        Fetch product feed from Awin API.

        Args:
            advertiser_id: Awin advertiser ID
            limit: Maximum products to fetch
            offset: Offset for pagination

        Returns:
            List of product dictionaries from API
        """
        try:
            params = {"limit": limit, "offset": offset}
            url = f"{self.BASE_URL}/advertisers/{advertiser_id}/products"
            response = await self.client.get(url, params=params)
            response.raise_for_status()
            data = response.json()
            return data.get("products", [])
        except Exception as e:
            logger.error(f"Awin API error: {e}")
            return []

    async def close(self) -> None:
        """Close HTTP client."""
        await self.client.aclose()


class FeedParser:
    """Generic CSV/XML/JSON feed parser."""

    @staticmethod
    async def parse_csv(feed_url: str) -> list[dict]:
        """Parse CSV product feed."""
        try:
            async with httpx.AsyncClient(timeout=30.0) as client:
                response = await client.get(feed_url)
                response.raise_for_status()

            lines = response.text.split("\n")
            reader = csv.DictReader(lines)
            products = list(reader)
            logger.info(f"Parsed {len(products)} products from CSV feed")
            return products
        except Exception as e:
            logger.error(f"CSV parsing error: {e}")
            return []

    @staticmethod
    async def parse_json(feed_url: str) -> list[dict]:
        """Parse JSON product feed."""
        try:
            async with httpx.AsyncClient(timeout=30.0) as client:
                response = await client.get(feed_url)
                response.raise_for_status()

            data = response.json()
            products = data.get("products", data) if isinstance(data, dict) else data
            if isinstance(products, list):
                logger.info(f"Parsed {len(products)} products from JSON feed")
                return products
            return []
        except Exception as e:
            logger.error(f"JSON parsing error: {e}")
            return []

    @staticmethod
    async def parse_xml(feed_url: str) -> list[dict]:
        """Parse XML product feed (Google Shopping format)."""
        try:
            import xml.etree.ElementTree as ET

            async with httpx.AsyncClient(timeout=30.0) as client:
                response = await client.get(feed_url)
                response.raise_for_status()

            root = ET.fromstring(response.content)
            products = []

            # Handle Google Shopping format
            for item in root.findall(".//item"):
                product = {}
                for child in item:
                    # Remove namespace
                    tag = child.tag.split("}")[-1] if "}" in child.tag else child.tag
                    product[tag] = child.text

                if product:
                    products.append(product)

            logger.info(f"Parsed {len(products)} products from XML feed")
            return products
        except Exception as e:
            logger.error(f"XML parsing error: {e}")
            return []


class ProductNormalizer:
    """Normalizes product data from various sources to unified schema."""

    # Category regex patterns for MVP classification
    CATEGORY_PATTERNS = {
        "dresses": r"dress|gown|maxi|cocktail",
        "tops": r"shirt|blouse|sweater|top|cardigan|jacket",
        "bottoms": r"pant|jean|skirt|short|trouser|legging",
        "outerwear": r"coat|parka|blazer|cardigan|jacket",
        "accessories": r"bag|shoe|scarf|hat|belt|jewelry",
        "activewear": r"yoga|gym|athletic|workout|training",
    }

    @staticmethod
    async def normalize_product(
        session: AsyncSession,
        raw_product: dict,
        retailer: Retailer,
    ) -> Optional[IngestionProduct]:
        """
        Normalize raw product data to IngestionProduct schema.

        Args:
            session: SQLAlchemy async session
            raw_product: Raw product dictionary from feed
            retailer: Retailer model

        Returns:
            Normalized IngestionProduct or None if invalid
        """
        try:
            # Extract basic fields (handle various naming conventions)
            external_id = (
                raw_product.get("id")
                or raw_product.get("product_id")
                or raw_product.get("sku")
            )
            if not external_id:
                logger.warning("Product missing ID")
                return None

            name = (
                raw_product.get("title")
                or raw_product.get("name")
                or raw_product.get("product_name")
            )
            if not name:
                logger.warning(f"Product {external_id} missing name")
                return None

            # Price extraction
            price_str = (
                raw_product.get("price")
                or raw_product.get("current_price")
                or raw_product.get("sale_price")
            )
            try:
                current_price = float(re.sub(r"[^\d.]", "", str(price_str)))
            except (ValueError, TypeError):
                logger.warning(f"Product {external_id} has invalid price: {price_str}")
                return None

            original_price = None
            original_price_str = raw_product.get("original_price") or raw_product.get(
                "list_price"
            )
            if original_price_str:
                try:
                    original_price = float(
                        re.sub(r"[^\d.]", "", str(original_price_str))
                    )
                except ValueError:
                    pass

            # Image URLs
            image_urls = []
            if raw_product.get("image_url"):
                image_urls = [raw_product["image_url"]]
            elif raw_product.get("image_urls"):
                image_urls = raw_product["image_urls"]
                if isinstance(image_urls, str):
                    image_urls = image_urls.split(",")

            # Product URL
            product_url = (
                raw_product.get("link")
                or raw_product.get("url")
                or raw_product.get("product_url")
            )
            if not product_url:
                logger.warning(f"Product {external_id} missing URL")
                return None

            # Brand extraction
            brand_name = raw_product.get(
                "brand"
            ) or ProductNormalizer._extract_brand_from_name(name)

            # Category classification
            description = raw_product.get("description") or ""
            category = ProductNormalizer._classify_category(name, description)
            subcategory = ProductNormalizer._classify_subcategory(name, description)

            # Colors extraction
            colors = ProductNormalizer._extract_colors(raw_product)

            # Sizes
            sizes_available = ProductNormalizer._extract_sizes(raw_product)

            # Tags generation
            tags = ProductNormalizer._generate_tags(name, description, category)

            return IngestionProduct(
                external_id=str(external_id),
                retailer_id=str(retailer.id),
                brand_name=brand_name,
                name=name,
                description=description[:2048] if description else None,
                category=category,
                subcategory=subcategory,
                current_price=current_price,
                original_price=original_price,
                currency="USD",
                colors=colors,
                sizes_available=sizes_available,
                image_urls=image_urls[:5],  # Limit to 5 images
                product_url=product_url,
                tags=tags,
            )
        except Exception as e:
            logger.error(
                f"Normalization error for product {raw_product.get('id')}: {e}"
            )
            return None

    @staticmethod
    def _extract_brand_from_name(name: str) -> Optional[str]:
        """Extract brand name from product name."""
        # Take first word as potential brand
        parts = name.split()
        if parts:
            return parts[0]
        return None

    @staticmethod
    def _classify_category(name: str, description: str) -> Optional[str]:
        """Classify product into category using regex patterns."""
        combined = f"{name} {description}".lower()

        for category, pattern in ProductNormalizer.CATEGORY_PATTERNS.items():
            if re.search(pattern, combined):
                return category

        return None

    @staticmethod
    def _classify_subcategory(name: str, description: str) -> Optional[str]:
        """Extract subcategory from product attributes."""
        combined = f"{name} {description}".lower()

        # More granular classification
        subcategories = {
            "mini dresses": r"mini dress",
            "midi dresses": r"midi dress",
            "maxi dresses": r"maxi dress",
            "casual dresses": r"casual dress",
            "formal dresses": r"formal|gown",
            "white tees": r"white t.?shirt|white tee",
            "graphic tees": r"graphic t.?shirt|graphic tee",
            "button ups": r"button.?up|oxford",
            "skinny jeans": r"skinny jean",
            "wide leg jeans": r"wide leg jean",
            "straight jeans": r"straight jean",
        }

        for subcategory, pattern in subcategories.items():
            if re.search(pattern, combined):
                return subcategory

        return None

    @staticmethod
    def _extract_colors(product: dict) -> Optional[dict]:
        """Extract color information from product attributes."""
        color_field = (
            product.get("color")
            or product.get("colors")
            or product.get("available_colors")
        )

        if color_field:
            if isinstance(color_field, dict):
                return color_field
            elif isinstance(color_field, str):
                # Split comma-separated colors
                colors = [c.strip() for c in color_field.split(",")]
                return {color: True for color in colors}

        return None

    @staticmethod
    def _extract_sizes(product: dict) -> Optional[dict]:
        """Extract size information from product attributes."""
        size_field = (
            product.get("sizes")
            or product.get("available_sizes")
            or product.get("size")
        )

        if size_field:
            if isinstance(size_field, dict):
                return size_field
            elif isinstance(size_field, str):
                sizes = [s.strip() for s in size_field.split(",")]
                return {size: True for size in sizes}

        return None

    @staticmethod
    def _generate_tags(
        name: str, description: str, category: Optional[str]
    ) -> dict[str, float]:
        """Generate descriptive tags for product."""
        tags = {}

        # Category tag
        if category:
            tags[category] = 1.0

        # Aesthetic tags from description
        aesthetic_keywords = {
            "minimalist": r"minimal|simple|clean",
            "bohemian": r"boho|bohemian|ethnic",
            "vintage": r"vintage|retro|classic",
            "modern": r"modern|contemporary|sleek",
            "edgy": r"edge|edgy|punk|rock",
            "romantic": r"romantic|floral|feminine",
            "sporty": r"sporty|athletic|active",
            "casual": r"casual|comfy|relaxed",
            "formal": r"formal|elegant|evening|cocktail",
            "luxury": r"luxury|designer|premium|high.?end",
        }

        combined = f"{name} {description}".lower()
        for tag, pattern in aesthetic_keywords.items():
            if re.search(pattern, combined):
                tags[tag] = 0.8

        # Quality indicators
        if re.search(r"organic|sustainable|eco|ethical|fair trade", combined):
            tags["sustainable"] = 0.7

        return tags


class QualityGate:
    """Quality assurance gate for ingested products."""

    MIN_IMAGE_HEIGHT = 800
    MIN_IMAGE_WIDTH = 1000
    PRICE_MIN = 30.0
    PRICE_MAX = 2000.0

    @staticmethod
    async def validate_product(
        product: IngestionProduct,
        retailer: Retailer,
    ) -> tuple[bool, Optional[str]]:
        """
        Validate product against quality criteria.

        Args:
            product: Normalized ingestion product
            retailer: Retailer model

        Returns:
            Tuple of (is_valid, error_message)
        """
        # Price range check
        if (
            product.current_price < QualityGate.PRICE_MIN
            or product.current_price > QualityGate.PRICE_MAX
        ):
            return (
                False,
                f"Price ${product.current_price} outside range ${QualityGate.PRICE_MIN}-${QualityGate.PRICE_MAX}",
            )

        # Image availability check
        if not product.image_urls:
            return False, "No images available"

        # Product URL check
        if not product.product_url or not product.product_url.startswith("http"):
            return False, "Invalid product URL"

        # Brand whitelist check (if configured)
        # TODO: Implement brand whitelist checking

        return True, None

    @staticmethod
    async def detect_duplicates(
        session: AsyncSession,
        product: IngestionProduct,
    ) -> Optional[str]:
        """
        Detect if product is duplicate of existing product.

        Returns product_id if duplicate found, None otherwise.

        Args:
            session: SQLAlchemy async session
            product: Normalized ingestion product

        Returns:
            Existing product ID if duplicate, None otherwise
        """
        # Check by external_id + retailer_id (exact match)
        stmt = select(Product.id).where(
            and_(
                Product.external_id == product.external_id,
                Product.retailer_id == product.retailer_id,
            )
        )
        result = await session.execute(stmt)
        existing_id = result.scalar_one_or_none()

        if existing_id:
            return str(existing_id)

        # Check by name + price (fuzzy duplicate detection)
        # Exclude exact match already checked
        stmt = select(Product.id).where(
            and_(
                Product.name.ilike(f"%{product.name[:20]}%"),
                Product.current_price >= product.current_price * 0.95,
                Product.current_price <= product.current_price * 1.05,
            )
        )
        result = await session.execute(stmt)
        similar_id = result.scalar_one_or_none()

        if similar_id:
            return str(similar_id)

        return None


class IngestionService:
    """Main product ingestion service orchestrating the pipeline."""

    @staticmethod
    async def ingest_feed(
        session: AsyncSession,
        retailer: Retailer,
    ) -> dict:
        """
        Ingest entire product feed for a retailer.

        Pipeline:
        1. FETCH: Pull from API or feed URL
        2. NORMALIZE: Map to unified Product schema
        3. QUALITY_GATE: Filter by criteria
        4. ENRICH: Generate embeddings, scores
        5. INDEX: Upsert to PostgreSQL and invalidate caches

        Args:
            session: SQLAlchemy async session
            retailer: Retailer model with feed configuration

        Returns:
            Ingestion report dictionary
        """
        report = {
            "retailer_id": str(retailer.id),
            "retailer_name": retailer.name,
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "products_fetched": 0,
            "products_normalized": 0,
            "products_validated": 0,
            "products_added": 0,
            "products_updated": 0,
            "products_rejected": 0,
            "duplicates_detected": 0,
            "errors": [],
        }

        if not retailer.product_feed_url:
            report["errors"].append("No feed URL configured")
            return report

        # FETCH: Get raw products
        raw_products = []
        try:
            if retailer.product_feed_format.value == "csv":
                raw_products = await FeedParser.parse_csv(retailer.product_feed_url)
            elif retailer.product_feed_format.value == "json":
                raw_products = await FeedParser.parse_json(retailer.product_feed_url)
            elif retailer.product_feed_format.value == "xml":
                raw_products = await FeedParser.parse_xml(retailer.product_feed_url)

            report["products_fetched"] = len(raw_products)
            logger.info(f"Fetched {len(raw_products)} products from {retailer.name}")
        except Exception as e:
            report["errors"].append(f"Fetch error: {str(e)}")
            logger.error(f"Feed fetch error for {retailer.name}: {e}")
            return report

        # NORMALIZE: Convert to unified schema
        normalized_products = []
        for raw_product in raw_products:
            normalized = await ProductNormalizer.normalize_product(
                session, raw_product, retailer
            )
            if normalized:
                normalized_products.append(normalized)

        report["products_normalized"] = len(normalized_products)
        logger.info(
            f"Normalized {len(normalized_products)} products from {retailer.name}"
        )

        # QUALITY_GATE: Validate and deduplicate
        valid_products = []
        for normalized in normalized_products:
            # Quality validation
            is_valid, error = await QualityGate.validate_product(normalized, retailer)
            if not is_valid:
                report["products_rejected"] += 1
                logger.debug(f"Product rejected: {normalized.name} - {error}")
                continue

            # Duplicate detection
            duplicate_id = await QualityGate.detect_duplicates(session, normalized)
            if duplicate_id:
                report["duplicates_detected"] += 1
                logger.debug(
                    f"Duplicate detected: {normalized.name} already exists as {duplicate_id}"
                )
                continue

            valid_products.append(normalized)

        report["products_validated"] = len(valid_products)
        logger.info(f"Validated {len(valid_products)} products from {retailer.name}")

        # INDEX: Upsert to database
        affected_user_ids = set()

        for ingestion_product in valid_products:
            # Get or find brand
            brand_id = None
            if ingestion_product.brand_name:
                stmt = select(Brand.id).where(
                    Brand.name.ilike(ingestion_product.brand_name)
                )
                result = await session.execute(stmt)
                brand_id = result.scalar_one_or_none()

            # Check if product already exists
            stmt = select(Product).where(
                and_(
                    Product.external_id == ingestion_product.external_id,
                    Product.retailer_id == ingestion_product.retailer_id,
                )
            )
            result = await session.execute(stmt)
            existing_product = result.scalar_one_or_none()

            if existing_product:
                # Update existing product
                existing_product.name = ingestion_product.name
                existing_product.description = ingestion_product.description
                existing_product.category = ingestion_product.category
                existing_product.subcategory = ingestion_product.subcategory
                existing_product.current_price = ingestion_product.current_price
                existing_product.original_price = ingestion_product.original_price
                existing_product.colors = ingestion_product.colors
                existing_product.sizes_available = ingestion_product.sizes_available
                existing_product.image_urls = ingestion_product.image_urls
                existing_product.product_url = ingestion_product.product_url
                existing_product.tags = ingestion_product.tags
                existing_product.updated_at = datetime.now(timezone.utc)
                report["products_updated"] += 1
                logger.debug(f"Updated product: {ingestion_product.name}")
            else:
                # Create new product
                new_product = Product(
                    external_id=ingestion_product.external_id,
                    retailer_id=ingestion_product.retailer_id,
                    brand_id=brand_id,
                    name=ingestion_product.name,
                    description=ingestion_product.description,
                    category=ingestion_product.category,
                    subcategory=ingestion_product.subcategory,
                    current_price=ingestion_product.current_price,
                    original_price=ingestion_product.original_price,
                    currency=ingestion_product.currency,
                    colors=ingestion_product.colors,
                    sizes_available=ingestion_product.sizes_available,
                    image_urls=ingestion_product.image_urls,
                    product_url=ingestion_product.product_url,
                    tags=ingestion_product.tags,
                    is_active=True,
                )
                session.add(new_product)
                report["products_added"] += 1
                logger.debug(f"Added new product: {ingestion_product.name}")

            affected_user_ids.add(ingestion_product.retailer_id)

        # Flush to database
        await session.flush()

        # Invalidate affected card queues
        for retailer_id in affected_user_ids:
            queue_key = f"card_queue:{retailer_id}"
            await delete_cache(queue_key)

        logger.info(
            f"Ingestion complete for {retailer.name}: {report['products_added']} added, {report['products_updated']} updated"
        )

        return report
