import aioredis
import json
import os
from typing import List, Optional
from models.log_schemas import LogEntry

class LogCollector:
    def __init__(self):
        self.redis_url = os.getenv("REDIS_URL", "redis://localhost:6379")
        self.redis_client: Optional[aioredis.Redis] = None
        
    async def initialize(self):
        """Initialize Redis connection"""
        self.redis_client = aioredis.from_url(self.redis_url, decode_responses=True)
    
    async def queue_log(self, log: LogEntry) -> bool:
        """Queue a log for processing"""
        try:
            log_data = log.json()
            await self.redis_client.lpush("log_queue", log_data)
            return True
        except Exception as e:
            print(f"Error queuing log: {e}")
            return False
    
    async def queue_logs_batch(self, logs: List[LogEntry]) -> int:
        """Queue multiple logs"""
        try:
            pipe = self.redis_client.pipeline()
            for log in logs:
                log_data = log.json()
                pipe.lpush("log_queue", log_data)
            await pipe.execute()
            return len(logs)
        except Exception as e:
            print(f"Error queuing logs batch: {e}")
            return 0
    
    async def dequeue_logs(self, batch_size: int = 100) -> List[LogEntry]:
        """Dequeue logs for processing"""
        try:
            logs = []
            for _ in range(batch_size):
                log_data = await self.redis_client.rpop("log_queue")
                if log_data:
                    logs.append(LogEntry.parse_raw(log_data))
                else:
                    break
            return logs
        except Exception as e:
            print(f"Error dequeuing logs: {e}")
            return []
    
    async def get_queue_size(self) -> int:
        """Get current queue size"""
        try:
            return await self.redis_client.llen("log_queue")
        except Exception:
            return 0
