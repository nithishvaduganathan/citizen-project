"""
Chat schemas for AI chatbot API
"""
from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel, Field

from app.db.models.chat import MessageRole, MessageLanguage


class SourceDocumentSchema(BaseModel):
    """Source document reference schema"""
    title: str
    section: Optional[str] = None
    article: Optional[str] = None
    content_snippet: str
    relevance_score: float


# Request Schemas
class ChatMessageRequest(BaseModel):
    """Chat message request"""
    content: str = Field(..., min_length=1, max_length=2000)
    language: MessageLanguage = MessageLanguage.ENGLISH


class CreateSessionRequest(BaseModel):
    """Create chat session request"""
    title: Optional[str] = "New Chat"
    preferred_language: MessageLanguage = MessageLanguage.ENGLISH


class TranslateRequest(BaseModel):
    """Translation request"""
    text: str = Field(..., min_length=1, max_length=5000)
    source_language: MessageLanguage
    target_language: MessageLanguage


# Response Schemas
class ChatMessageResponse(BaseModel):
    """Chat message response"""
    id: str
    session_id: str
    role: MessageRole
    content: str
    input_language: MessageLanguage
    output_language: MessageLanguage
    sources: List[SourceDocumentSchema] = Field(default_factory=list)
    created_at: datetime


class ChatSessionResponse(BaseModel):
    """Chat session response"""
    id: str
    user_id: str
    title: str
    preferred_language: MessageLanguage
    message_count: int
    is_active: bool
    created_at: datetime
    updated_at: datetime
    last_message_at: Optional[datetime] = None


class ChatSessionListResponse(BaseModel):
    """Chat session list response"""
    sessions: List[ChatSessionResponse]
    total: int


class ChatCompletionResponse(BaseModel):
    """Chat completion response from AI"""
    message: ChatMessageResponse
    sources: List[SourceDocumentSchema]
    processing_time_ms: int
    tokens_used: int


class TranslateResponse(BaseModel):
    """Translation response"""
    original_text: str
    translated_text: str
    source_language: MessageLanguage
    target_language: MessageLanguage


class SupportedLanguagesResponse(BaseModel):
    """Supported languages response"""
    languages: List[dict]  # [{"code": "en", "name": "English"}, ...]
