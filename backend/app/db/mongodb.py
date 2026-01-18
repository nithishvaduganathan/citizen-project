"""
MongoDB database connection and initialization
"""
from motor.motor_asyncio import AsyncIOMotorClient
from beanie import init_beanie
from typing import Optional

from app.core.config import settings

# Global database client
_client: Optional[AsyncIOMotorClient] = None
_db = None


async def get_database():
    """Get the database instance"""
    global _db
    return _db


async def connect_to_mongo():
    """Connect to MongoDB and initialize Beanie ODM"""
    global _client, _db
    
    _client = AsyncIOMotorClient(settings.MONGODB_URL)
    _db = _client[settings.MONGODB_DB_NAME]
    
    # Import models for Beanie initialization
    from app.db.models.user import User
    from app.db.models.complaint import Complaint
    from app.db.models.community import Post, Comment
    from app.db.models.chat import ChatSession, ChatMessage
    
    await init_beanie(
        database=_db,
        document_models=[User, Complaint, Post, Comment, ChatSession, ChatMessage]
    )
    
    print(f"Connected to MongoDB: {settings.MONGODB_DB_NAME}")


async def close_mongo_connection():
    """Close MongoDB connection"""
    global _client
    if _client:
        _client.close()
        print("MongoDB connection closed")
