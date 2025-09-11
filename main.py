from fastapi import FastAPI
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI()

@app.get("/")
async def root():
    logger.info("I'm alive! Someone accessed the root endpoint")
    return {"message": "Pay Log Aggregator is alive!"}

if __name__ == "__main__":
    import uvicorn
    logger.info("Starting Pay Log Aggregator API...")
    uvicorn.run(app, host="0.0.0.0", port=8000)
