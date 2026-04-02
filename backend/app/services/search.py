"""Product search service using Elasticsearch."""

import logging
from typing import Any, Optional

from app.core.elasticsearch import (
    search_products,
    vector_search,
    index_document,
    bulk_index_documents,
    delete_document,
)

logger = logging.getLogger(__name__)


async def search_full_text(
    query: str,
    filters: Optional[dict] = None,
    page: int = 1,
    size: int = 20,
) -> dict:
    """
    Perform full-text search on products.

    Args:
        query: Search query string
        filters: Optional filters dict with keys like category, brand_tier, price_range
        page: Page number (1-indexed)
        size: Results per page
    """
    from_value = (page - 1) * size

    es_query: dict[str, Any] = {
        "bool": {
            "must": [
                {
                    "multi_match": {
                        "query": query,
                        "fields": [
                            "name^3",
                            "description^2",
                            "brand_name^2",
                            "tags",
                        ],
                    }
                }
            ],
            "filter": [],
        }
    }

    # Add filters
    if filters:
        if "category" in filters:
            es_query["bool"]["filter"].append(
                {"term": {"category": filters["category"]}}
            )
        if "brand_tier" in filters:
            es_query["bool"]["filter"].append(
                {"term": {"brand_tier": filters["brand_tier"]}}
            )
        if "is_on_sale" in filters:
            es_query["bool"]["filter"].append(
                {"term": {"is_on_sale": filters["is_on_sale"]}}
            )
        if "retailer" in filters:
            es_query["bool"]["filter"].append(
                {"term": {"retailer": filters["retailer"]}}
            )
        if "price_range" in filters:
            price_range = filters["price_range"]
            es_query["bool"]["filter"].append(
                {
                    "range": {
                        "price": {
                            "gte": price_range.get("min", 0),
                            "lte": price_range.get("max", 999999),
                        }
                    }
                }
            )

    results = await search_products(query=es_query, size=size, from_=from_value)

    return {
        "hits": [hit["_source"] for hit in results["hits"]["hits"]],
        "total": results["hits"]["total"].get("value", 0),
        "page": page,
        "size": size,
    }


async def find_similar_by_embedding(
    embedding: list[float],
    count: int = 10,
) -> dict:
    """
    Find similar products by visual embedding (kNN search).

    Args:
        embedding: Visual embedding vector
        count: Number of results to return
    """
    results = await vector_search(vector=embedding, k=count)

    return {
        "hits": [hit["_source"] for hit in results["hits"]["hits"]],
        "total": results["hits"]["total"].get("value", 0),
        "count": count,
    }


async def find_similar_by_tags(
    product_id: str,
    tags: dict[str, float],
    count: int = 10,
) -> dict:
    """
    Find similar products by tags (fallback method).

    Args:
        product_id: Product ID to exclude from results
        tags: Tag dictionary with weights
        count: Number of results to return
    """
    tag_list = list(tags.keys())

    es_query = {
        "bool": {
            "must": [{"terms": {"tags": tag_list}}],
            "must_not": [{"term": {"product_id": product_id}}],
        }
    }

    results = await search_products(query=es_query, size=count)

    return {
        "hits": [hit["_source"] for hit in results["hits"]["hits"]],
        "total": results["hits"]["total"].get("value", 0),
        "count": count,
    }


async def index_product(product: dict) -> None:
    """
    Add or update a product in Elasticsearch.

    Args:
        product: Product dict with structure:
            {
                "product_id": str,
                "brand_name": str,
                "name": str,
                "description": str,
                "category": str,
                "subcategory": str,
                "price": float,
                "colors": list,
                "materials": list,
                "tags": list,
                "retailer": str,
                "brand_tier": str,
                "is_on_sale": bool,
                "is_active": bool,
                "image_quality_score": float,
                "visual_embedding": list[float],
                "created_at": str,
                "global_like_rate": float,
            }
    """
    product_id = product.get("product_id")
    if not product_id:
        logger.warning("Product missing product_id, skipping indexing")
        return

    await index_document(doc_id=product_id, body=product)
    logger.info(f"Indexed product: {product_id}")


async def bulk_index_products(products: list[dict]) -> None:
    """
    Bulk index multiple products.

    Args:
        products: List of product dicts
    """
    if not products:
        return

    documents = [
        (product.get("product_id"), product)
        for product in products
        if product.get("product_id")
    ]

    if documents:
        await bulk_index_documents(documents=documents)
        logger.info(f"Bulk indexed {len(documents)} products")


async def remove_product(product_id: str) -> None:
    """
    Remove a product from Elasticsearch.

    Args:
        product_id: Product ID to remove
    """
    await delete_document(doc_id=product_id)
    logger.info(f"Removed product from index: {product_id}")


async def get_product_by_id(
    product_id: str, index_name: str = "products"
) -> Optional[dict]:
    """
    Get a single product by ID.

    Args:
        product_id: Product ID to retrieve
        index_name: Elasticsearch index name
    """
    try:
        from elasticsearch import NotFoundError
        from app.core.elasticsearch import get_elasticsearch

        es = await get_elasticsearch()
        result = await es.get(index=index_name, id=product_id)
        return result["_source"]
    except NotFoundError:
        return None
    except Exception as e:
        logger.error(f"Error retrieving product {product_id}: {e}")
        return None
