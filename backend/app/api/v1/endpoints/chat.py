"""
Chat API endpoints for AI chatbot
"""
from fastapi import APIRouter, HTTPException, status, Depends
from typing import Dict, Any, List

from app.schemas.chat import (
    ChatMessageRequest,
    CreateSessionRequest,
    ChatMessageResponse,
    ChatSessionResponse,
    ChatSessionListResponse,
    ChatCompletionResponse,
    SupportedLanguagesResponse,
)
from app.schemas.user import MessageResponse
from app.core.security import get_current_user_from_token
from app.services.chatbot.rag_service import chatbot_service
from app.db.models.chat import MessageLanguage

router = APIRouter(prefix="/chat", tags=["AI Chatbot"])


@router.post("/sessions", response_model=ChatSessionResponse)
async def create_session(
    request: CreateSessionRequest,
    current_user: Dict[str, Any] = Depends(get_current_user_from_token)
):
    """
    Create a new chat session.
    """
    user_id = current_user.get("sub")
    
    return await chatbot_service.create_session(user_id, request)


@router.get("/sessions", response_model=ChatSessionListResponse)
async def list_sessions(
    current_user: Dict[str, Any] = Depends(get_current_user_from_token)
):
    """
    List user's chat sessions.
    """
    user_id = current_user.get("sub")
    
    sessions = await chatbot_service.list_sessions(user_id)
    
    return ChatSessionListResponse(
        sessions=sessions,
        total=len(sessions)
    )


@router.get("/sessions/{session_id}", response_model=ChatSessionResponse)
async def get_session(
    session_id: str,
    current_user: Dict[str, Any] = Depends(get_current_user_from_token)
):
    """
    Get chat session by ID.
    """
    user_id = current_user.get("sub")
    
    session = await chatbot_service.get_session(session_id, user_id)
    
    if not session:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Session not found"
        )
    
    return chatbot_service._session_to_response(session)


@router.get("/sessions/{session_id}/messages", response_model=List[ChatMessageResponse])
async def get_session_messages(
    session_id: str,
    current_user: Dict[str, Any] = Depends(get_current_user_from_token)
):
    """
    Get messages for a chat session.
    """
    user_id = current_user.get("sub")
    
    try:
        return await chatbot_service.get_session_messages(session_id, user_id)
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )


@router.post("/sessions/{session_id}/messages", response_model=ChatCompletionResponse)
async def send_message(
    session_id: str,
    request: ChatMessageRequest,
    current_user: Dict[str, Any] = Depends(get_current_user_from_token)
):
    """
    Send a message and get AI response.
    
    - Supports multi-language input/output (English, Tamil, Hindi)
    - Returns relevant constitutional sources
    - Uses RAG for accurate responses
    """
    user_id = current_user.get("sub")
    
    try:
        return await chatbot_service.chat(session_id, user_id, request)
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )


@router.delete("/sessions/{session_id}", response_model=MessageResponse)
async def delete_session(
    session_id: str,
    current_user: Dict[str, Any] = Depends(get_current_user_from_token)
):
    """
    Delete a chat session.
    """
    user_id = current_user.get("sub")
    
    success = await chatbot_service.delete_session(session_id, user_id)
    
    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Session not found"
        )
    
    return MessageResponse(message="Session deleted successfully")


@router.get("/languages", response_model=SupportedLanguagesResponse)
async def get_supported_languages():
    """
    Get list of supported languages for the chatbot.
    """
    languages = [
        {"code": "en", "name": "English", "native_name": "English"},
        {"code": "ta", "name": "Tamil", "native_name": "தமிழ்"},
        {"code": "hi", "name": "Hindi", "native_name": "हिन्दी"},
    ]
    
    return SupportedLanguagesResponse(languages=languages)
