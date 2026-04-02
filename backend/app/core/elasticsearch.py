"""Elasticsearch client and index management."""

import logging
from typing import Optional

from elasticsearch import AsyncElasticsearch

from app.core.config import get_settings

logger = logging.getLogger(__name__)

# Elasticsearch client instance
_es_client: Optional[AsyncElasticsearch] = None


async def get_elasticsearch() -> AsyncElasticsearch:
    """Get or create Elasticsearch client."""
    global _es_client
    if _es_client is None:
        settings = get_settings()
        _es_client = AsyncElasticsearch([settings.ELASTICSEARCH_URL])
    return _es_client


async def close_elasticsearch() -> None:
    """Close Elasticsearch client."""
    global _es_client
    if _es_client:
        await _es_client.close()
        _es_client = None


def get_products_index_mapping() -> dict:
    """Get the index mapping for products."""
    return {
        "mappings": {
            "properties": {
                "product_id": {"type": "keyword"},
                "brand_name": {
                    "type": "text",
                    "fields": {"keyword": {"type": "keyword"}},
                },
                "name": {"type": "text"},
                "description": {"type": "text"},
                "category": {"type": "keyword"},
                "subcategory": {"type": "keyword"},
                "price": {"type": "float"},
                "colors": {"type": "keyword"},
                "materials": {"type": "keyword"},
                "tags": {"type": "keyword"},
                "retailer": {"type": "keyword"},
                "brand_tier": {"type": "keyword"},
                "is_on_sale": {"type": "boolean"},
                "is_active": {"type": "boolean"},
                "image_quality_score": {"type": "float"},
                "visual_embedding": {
                    "type": "dense_vector",
                    "dims": 512,
                    "index": True,
                    "similarity": "cosine",
                },
                "created_at": {"type": "date"},
                "global_like_rate": {"type": "float"},
            }
        }
    }


async def create_products_index(index_name: str = "products") -> None:
    """Create the products index if it doesn't exist."""
    es = await get_elasticsearch()
    try:
        exists = await es.indices.exists(index=index_name)
        if not exists:
            mapping = get_products_index_mapping()
            await es.indices.create(index=index_name, body=mapping)
            logger.info(f"Created Elasticsearch index: {index_name}")
    except Exception as e:
        logger.error(f"Error creating Elasticsearch index: {e}")
        raise


async def delete_index(index_name: str = "products") -> None:
    """Delete an index."""
    es = await get_elasticsearch()
    try:
        exists = await es.indices.exists(index=index_name)
        if exists:
            await es.indices.delete(index=index_name)
            logger.info(f"Deleted Elasticsearch index: {index_name}")
    except Exception as e:
        logger.error(f"Error deleting Elasticsearch index: {e}")


async def index_document(
    doc_id: str,
    body: dict,
    index_name: str = "products",
) -> None:
    """Index a single document."""
    es = await get_elasticsearch()
    try:
        await es.index(index=index_name, id=doc_id, body=body)
    except Exception as e:
        logger.error(f"Error indexing document {doc_id}: {e}")
        raise


async def bulk_index_documents(
    documents: list[tuple[str, dict]],
    index_name: str = "products",
) -> None:
    """Bulk index documents. documents = [(doc_id, body), ...]"""
    if not documents:
        return

    es = await get_elasticsearch()
    try:
        operations = []
        for doc_id, body in documents:
            operations.append({"index": {"_index": index_name, "_id": doc_id}})
            operations.append(body)

        await es.bulk(operations=operations)
        logger.info(f"Bulk indexed {len(documents)} documents")
    except Exception as e:
        logger.error(f"Error bulk indexing documents: {e}")
        raise


async def delete_document(doc_id: str, index_name: str = "products") -> None:
    """Delete a document by ID."""
    es = await get_elasticsearch()
    try:
        await es.delete(index=index_name, id=doc_id)
    except Exception as e:
        logger.error(f"Error deleting document {doc_id}: {e}")


async def search_products(
    query: dict,
    index_name: str = "products",
    size: int = 20,
    from_: int = 0,
) -> dict:
    """Execute a search query on products index."""
    es = await get_elasticsearch()
    try:
        body = {
            "query": query,
            "size": size,
            "from": from_,
        }
        results = await es.search(index=index_name, body=body)
        return results
    except Exception as e:
        logger.error(f"Error searching products: {e}")
        raise


async def vector_search(
    vector: list[float],
    k: int = 10,
    index_name: str = "products",
) -> dict:
    """Search by vector similarity (kNN search)."""
    es = await get_elasticsearch()
    try:
        query = {
            "knn": {
                "visual_embedding": {
                    "vector": vector,
                    "k": k,
                }
            }
        }
        results = await es.search(index=index_name, body={"query": query, "size": k})
        return results
    except Exception as e:
        logger.error(f"Error performing vector search: {e}")
        raise


async def reindex(
    source_index: str = "products",
    dest_index: str = "products_v2",
) -> None:
    """Reindex from one index to another."""
    es = await get_elasticsearch()
    try:
        await es.reindex(
            body={"source": {"index": source_index}, "dest": {"index": dest_index}}
        )
        logger.info(f"Reindexed from {source_index} to {dest_index}")
    except Exception as e:
        logger.error(f"Error reindexing: {e}")
        raise


async def health_check() -> bool:
    """Check Elasticsearch cluster health."""
    try:
        es = await get_elasticsearch()
        await es.info()
        return True
    except Exception as e:
        logger.error(f"Elasticsearch health check failed: {e}")
        return False
