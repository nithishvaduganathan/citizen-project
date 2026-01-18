"""
API v1 Router - combines all endpoint routers
"""
from fastapi import APIRouter

from app.api.v1.endpoints import auth, users, complaints, chat, community, admin

api_router = APIRouter()

# Include all routers
api_router.include_router(auth.router)
api_router.include_router(users.router)
api_router.include_router(complaints.router)
api_router.include_router(chat.router)
api_router.include_router(community.router)
api_router.include_router(admin.router)
