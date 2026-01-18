"""
RAG-based chatbot service for Indian Constitution and laws
"""
import os
import time
from datetime import datetime
from typing import List, Optional, Dict, Any
from bson import ObjectId

from app.db.models.chat import ChatSession, ChatMessage, MessageRole, MessageLanguage, SourceDocument
from app.schemas.chat import (
    ChatMessageRequest,
    CreateSessionRequest,
    ChatMessageResponse,
    ChatSessionResponse,
    ChatCompletionResponse,
    SourceDocumentSchema,
)
from app.core.config import settings


class RAGChatbotService:
    """RAG-based chatbot service for constitutional knowledge"""
    
    def __init__(self):
        self._vectorstore = None
        self._llm = None
        self._embeddings = None
        self._initialized = False
    
    async def initialize(self):
        """Initialize RAG components (LangChain, vector store, embeddings)"""
        if self._initialized:
            return
        
        try:
            # Note: In production, these would be properly initialized
            # with actual API keys and vector database connections
            self._initialized = True
            print("RAG Chatbot service initialized (demo mode)")
        except Exception as e:
            print(f"RAG initialization error: {e}")
            self._initialized = True  # Continue in demo mode
    
    async def create_session(
        self, 
        user_id: str, 
        request: CreateSessionRequest
    ) -> ChatSessionResponse:
        """Create a new chat session"""
        session = ChatSession(
            user_id=user_id,
            title=request.title or "New Chat",
            preferred_language=request.preferred_language,
        )
        await session.insert()
        
        return self._session_to_response(session)
    
    async def get_session(self, session_id: str, user_id: str) -> Optional[ChatSession]:
        """Get chat session by ID"""
        try:
            session = await ChatSession.get(ObjectId(session_id))
            if session and session.user_id == user_id:
                return session
            return None
        except Exception:
            return None
    
    async def list_sessions(self, user_id: str) -> List[ChatSessionResponse]:
        """List user's chat sessions"""
        sessions = await ChatSession.find(
            ChatSession.user_id == user_id,
            ChatSession.is_active == True
        ).sort(-ChatSession.updated_at).to_list()
        
        return [self._session_to_response(s) for s in sessions]
    
    async def get_session_messages(
        self, 
        session_id: str, 
        user_id: str
    ) -> List[ChatMessageResponse]:
        """Get messages for a chat session"""
        session = await self.get_session(session_id, user_id)
        if not session:
            raise ValueError("Session not found")
        
        messages = await ChatMessage.find(
            ChatMessage.session_id == session_id
        ).sort(ChatMessage.created_at).to_list()
        
        return [self._message_to_response(m) for m in messages]
    
    async def chat(
        self,
        session_id: str,
        user_id: str,
        request: ChatMessageRequest
    ) -> ChatCompletionResponse:
        """Process a chat message and return AI response"""
        start_time = time.time()
        
        # Verify session
        session = await self.get_session(session_id, user_id)
        if not session:
            raise ValueError("Session not found")
        
        # Save user message
        user_message = ChatMessage(
            session_id=session_id,
            role=MessageRole.USER,
            content=request.content,
            input_language=request.language,
            output_language=request.language,
        )
        await user_message.insert()
        
        # Detect language and translate if needed
        input_language = request.language
        query_text = request.content
        
        if input_language != MessageLanguage.ENGLISH:
            # In production, translate to English for RAG
            query_text = await self._translate_to_english(request.content)
        
        # Retrieve relevant documents
        sources = await self._retrieve_documents(query_text)
        
        # Generate response using LLM
        response_text, tokens_used = await self._generate_response(
            query_text, 
            sources,
            input_language
        )
        
        # Translate response if needed
        if input_language != MessageLanguage.ENGLISH:
            response_text = await self._translate_from_english(
                response_text, 
                input_language
            )
        
        processing_time = int((time.time() - start_time) * 1000)
        
        # Save assistant message
        assistant_message = ChatMessage(
            session_id=session_id,
            role=MessageRole.ASSISTANT,
            content=response_text,
            input_language=MessageLanguage.ENGLISH,
            output_language=input_language,
            sources=[SourceDocument(**s.model_dump()) for s in sources],
            tokens_used=tokens_used,
            processing_time_ms=processing_time,
        )
        await assistant_message.insert()
        
        # Update session
        session.message_count += 2
        session.total_tokens += tokens_used
        session.last_message_at = datetime.utcnow()
        session.updated_at = datetime.utcnow()
        
        # Update title if first message
        if session.message_count == 2:
            session.title = request.content[:50] + "..." if len(request.content) > 50 else request.content
        
        await session.save()
        
        return ChatCompletionResponse(
            message=self._message_to_response(assistant_message),
            sources=sources,
            processing_time_ms=processing_time,
            tokens_used=tokens_used,
        )
    
    async def _retrieve_documents(
        self, 
        query: str
    ) -> List[SourceDocumentSchema]:
        """Retrieve relevant documents from vector store"""
        # In production, this would use ChromaDB or similar
        # For demo, return sample constitutional content
        
        sample_sources = [
            SourceDocumentSchema(
                title="Constitution of India",
                section="Fundamental Rights",
                article="Article 21",
                content_snippet="No person shall be deprived of his life or personal liberty except according to procedure established by law.",
                relevance_score=0.95
            ),
            SourceDocumentSchema(
                title="Constitution of India",
                section="Fundamental Rights",
                article="Article 14",
                content_snippet="The State shall not deny to any person equality before the law or the equal protection of the laws within the territory of India.",
                relevance_score=0.88
            ),
        ]
        
        # Return top relevant sources based on query
        if "right" in query.lower() or "fundamental" in query.lower():
            return sample_sources
        
        return [sample_sources[0]]
    
    async def _generate_response(
        self,
        query: str,
        sources: List[SourceDocumentSchema],
        language: MessageLanguage
    ) -> tuple:
        """Generate response using LLM with retrieved context"""
        # In production, this would use OpenAI/LangChain
        # For demo, return informative response
        
        context = "\n".join([
            f"{s.article}: {s.content_snippet}" 
            for s in sources
        ])
        
        response = f"""Based on the Indian Constitution and relevant laws, I can provide the following information:

{context}

This information is derived from the Constitution of India. For specific legal advice, please consult a qualified legal professional.

Is there anything specific about these constitutional provisions you would like me to explain further?"""
        
        tokens_used = len(query.split()) + len(response.split()) + 100
        
        return response, tokens_used
    
    async def _translate_to_english(self, text: str) -> str:
        """Translate text to English"""
        # In production, use Google Translate API or similar
        return text
    
    async def _translate_from_english(
        self, 
        text: str, 
        target_language: MessageLanguage
    ) -> str:
        """Translate text from English to target language"""
        # In production, use Google Translate API or similar
        return text
    
    async def delete_session(self, session_id: str, user_id: str) -> bool:
        """Delete a chat session"""
        session = await self.get_session(session_id, user_id)
        if not session:
            return False
        
        session.is_active = False
        await session.save()
        return True
    
    def _session_to_response(self, session: ChatSession) -> ChatSessionResponse:
        """Convert ChatSession to response schema"""
        return ChatSessionResponse(
            id=str(session.id),
            user_id=session.user_id,
            title=session.title,
            preferred_language=session.preferred_language,
            message_count=session.message_count,
            is_active=session.is_active,
            created_at=session.created_at,
            updated_at=session.updated_at,
            last_message_at=session.last_message_at,
        )
    
    def _message_to_response(self, message: ChatMessage) -> ChatMessageResponse:
        """Convert ChatMessage to response schema"""
        return ChatMessageResponse(
            id=str(message.id),
            session_id=message.session_id,
            role=message.role,
            content=message.content,
            input_language=message.input_language,
            output_language=message.output_language,
            sources=[SourceDocumentSchema(**s.model_dump()) for s in message.sources],
            created_at=message.created_at,
        )


# Singleton instance
chatbot_service = RAGChatbotService()
