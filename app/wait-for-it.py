#!/usr/bin/env python3
"""
Simple wait script to ensure services are ready before starting the application
"""
import asyncio
import sys
import time
from elasticsearch import AsyncElasticsearch
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

async def wait_for_elasticsearch(host="elasticsearch:9200", timeout=60):
    """Wait for Elasticsearch to be ready"""
    start_time = time.time()
    client = AsyncElasticsearch([f"http://{host}"])
    
    while time.time() - start_time < timeout:
        try:
            health = await client.cluster.health()
            if health['status'] in ['yellow', 'green']:
                logger.info("Elasticsearch is ready!")
                await client.close()
                return True
        except Exception as e:
            logger.info(f"Waiting for Elasticsearch... ({e})")
            await asyncio.sleep(2)
    
    await client.close()
    logger.error("Elasticsearch not ready within timeout")
    return False

async def main():
    """Main wait function"""
    logger.info("Waiting for services to be ready...")
    
    if not await wait_for_elasticsearch():
        sys.exit(1)
    
    logger.info("All services ready! Starting application...")
    return True

if __name__ == "__main__":
    asyncio.run(main())