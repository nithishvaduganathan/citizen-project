"""
Chat models for AI chatbot
"""
from datetime import datetime
from typing import Optional, List
from enum import Enum
from beanie import Document, Indexed
from pydantic import BaseModel, Field


class MessageRole(str, Enum):
    """Message role enumeration"""
    USER = "user"
    ASSISTANT = "assistant"
    SYSTEM = "system"


class MessageLanguage(str, Enum):
    """Supported languages"""
    ENGLISH = "en"
    TAMIL = "ta"
    HINDI = "hi"


class SourceDocument(BaseModel):
    """Source document reference for RAG"""
    title: str
    section: Optional[str] = None
    article: Optional[str] = None
    content_snippet: str
    relevance_score: float


class ChatMessage(Document):
    """Chat message document"""
    
    # Session reference
    session_id: Indexed(str)
    
    # Message content
    role: MessageRole
    content: str
    
    # Language
    input_language: MessageLanguage = MessageLanguage.ENGLISH
    output_language: MessageLanguage = MessageLanguage.ENGLISH
    
    # RAG sources (for assistant messages)
    sources: List[SourceDocument] = Field(default_factory=list)
    
    # Metadata
    tokens_used: int = 0
    processing_time_ms: int = 0
    
    # Timestamps
    created_at: datetime = Field(default_factory=datetime.utcnow)
    
    class Settings:
        name = "chat_messages"
        indexes = [
            "session_id",
            "created_at",
        ]


class ChatSession(Document):
    """Chat session document"""
    
    # User reference
    user_id: Indexed(str)
    
    # Session info
    title: str = "New Chat"
    
    # Language preference
    preferred_language: MessageLanguage = MessageLanguage.ENGLISH
    
    # Status
    is_active: bool = True
    
    # Statistics
    message_count: int = 0
    total_tokens: int = 0
    
    # Timestamps
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    last_message_at: Optional[datetime] = None
    
    class Settings:
        name = "chat_sessions"
        indexes = [
            "user_id",
            "is_active",
            "created_at",
        ]
