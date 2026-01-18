"""
User profile API endpoints
"""
from fastapi import APIRouter, HTTPException, status, Depends
from typing import Dict, Any

from app.schemas.user import (
    UserResponse,
    UpdateProfileRequest,
    MessageResponse,
)
from app.core.security import get_current_user_from_token
from app.services.auth.auth_service import auth_service

router = APIRouter(prefix="/users", tags=["Users"])


@router.get("/me", response_model=UserResponse)
async def get_current_user(
    current_user: Dict[str, Any] = Depends(get_current_user_from_token)
):
    """
    Get current authenticated user's profile.
    """
    user_id = current_user.get("sub")
    user = await auth_service.get_user_by_id(user_id)
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    return auth_service._user_to_response(user)


@router.put("/me", response_model=UserResponse)
async def update_profile(
    request: UpdateProfileRequest,
    current_user: Dict[str, Any] = Depends(get_current_user_from_token)
):
    """
    Update current user's profile.
    """
    user_id = current_user.get("sub")
    user = await auth_service.get_user_by_id(user_id)
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    if request.full_name:
        user.full_name = request.full_name
    if request.profile:
        if request.profile.phone:
            user.profile.phone = request.profile.phone
        if request.profile.bio:
            user.profile.bio = request.profile.bio
        if request.profile.avatar_url:
            user.profile.avatar_url = request.profile.avatar_url
        if request.profile.preferred_language:
            user.profile.preferred_language = request.profile.preferred_language
        if request.profile.location:
            user.profile.location = request.profile.location
    
    await user.save()
    
    return auth_service._user_to_response(user)


@router.get("/{username}", response_model=UserResponse)
async def get_user_by_username(username: str):
    """
    Get user profile by username.
    """
    from app.db.models.user import User
    
    user = await User.find_one(User.username == username)
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    return auth_service._user_to_response(user)


@router.delete("/me", response_model=MessageResponse)
async def deactivate_account(
    current_user: Dict[str, Any] = Depends(get_current_user_from_token)
):
    """
    Deactivate current user's account.
    """
    user_id = current_user.get("sub")
    user = await auth_service.get_user_by_id(user_id)
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    user.is_active = False
    await user.save()
    
    return MessageResponse(message="Account deactivated successfully")
