"""
Admin API endpoints
"""
from fastapi import APIRouter, HTTPException, status, Depends
from typing import Dict, Any, Optional

from app.schemas.user import UserResponse, UserListResponse, MessageResponse
from app.core.security import get_current_user_from_token, check_admin_role
from app.services.admin.admin_service import admin_service
from app.services.auth.auth_service import auth_service
from app.db.models.user import UserRole, AuthorityType
from app.db.models.complaint import ComplaintStatus

router = APIRouter(prefix="/admin", tags=["Admin"])


async def verify_admin(current_user: Dict[str, Any] = Depends(get_current_user_from_token)):
    """Verify that the current user is an admin."""
    user_id = current_user.get("sub")
    user = await auth_service.get_user_by_id(user_id)
    
    if not user or not user.is_admin():
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin access required"
        )
    
    return current_user


# Dashboard
@router.get("/dashboard")
async def get_dashboard(
    current_user: Dict[str, Any] = Depends(verify_admin)
):
    """
    Get admin dashboard statistics.
    """
    return await admin_service.get_dashboard_stats()


# User Management
@router.get("/users", response_model=UserListResponse)
async def list_users(
    page: int = 1,
    page_size: int = 20,
    role: Optional[UserRole] = None,
    is_active: Optional[bool] = None,
    current_user: Dict[str, Any] = Depends(verify_admin)
):
    """
    List all users with filters.
    """
    return await admin_service.list_users(
        page=page,
        page_size=page_size,
        role=role,
        is_active=is_active,
    )


@router.get("/users/{user_id}", response_model=UserResponse)
async def get_user(
    user_id: str,
    current_user: Dict[str, Any] = Depends(verify_admin)
):
    """
    Get user details by ID.
    """
    user = await admin_service.get_user(user_id)
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    return user


@router.put("/users/{user_id}/role", response_model=UserResponse)
async def update_user_role(
    user_id: str,
    new_role: UserRole,
    authority_type: Optional[AuthorityType] = None,
    department: Optional[str] = None,
    jurisdiction: Optional[str] = None,
    current_user: Dict[str, Any] = Depends(verify_admin)
):
    """
    Update user role (admin only).
    """
    result = await admin_service.update_user_role(
        user_id=user_id,
        new_role=new_role,
        authority_type=authority_type,
        department=department,
        jurisdiction=jurisdiction,
    )
    
    if not result:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    return result


@router.put("/users/{user_id}/toggle-active", response_model=MessageResponse)
async def toggle_user_active(
    user_id: str,
    current_user: Dict[str, Any] = Depends(verify_admin)
):
    """
    Activate or deactivate user account.
    """
    success = await admin_service.toggle_user_active(user_id)
    
    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    return MessageResponse(message="User status toggled successfully")


# Authority Verification
@router.get("/authorities/pending", response_model=UserListResponse)
async def list_pending_verifications(
    page: int = 1,
    page_size: int = 20,
    current_user: Dict[str, Any] = Depends(verify_admin)
):
    """
    List authorities pending verification.
    """
    return await admin_service.list_pending_authority_verifications(page, page_size)


@router.put("/authorities/{user_id}/verify", response_model=MessageResponse)
async def verify_authority(
    user_id: str,
    verified: bool = True,
    current_user: Dict[str, Any] = Depends(verify_admin)
):
    """
    Verify or unverify an authority account.
    """
    success = await admin_service.verify_authority(user_id, verified)
    
    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Authority not found"
        )
    
    return MessageResponse(
        message=f"Authority {'verified' if verified else 'unverified'} successfully"
    )


# Complaints Management
@router.get("/complaints/heatmap")
async def get_complaint_heatmap(
    current_user: Dict[str, Any] = Depends(verify_admin)
):
    """
    Get complaint data for heatmap visualization.
    """
    return await admin_service.get_complaint_heatmap_data()


@router.get("/complaints/by-authority/{authority_type}")
async def get_authority_complaints(
    authority_type: str,
    page: int = 1,
    page_size: int = 20,
    status: Optional[ComplaintStatus] = None,
    current_user: Dict[str, Any] = Depends(verify_admin)
):
    """
    Get complaints for a specific authority type.
    """
    return await admin_service.get_authority_complaints(
        authority_type=authority_type,
        page=page,
        page_size=page_size,
        status=status,
    )


# Content Moderation
@router.put("/posts/{post_id}/hide", response_model=MessageResponse)
async def hide_post(
    post_id: str,
    current_user: Dict[str, Any] = Depends(verify_admin)
):
    """
    Hide a post (content moderation).
    """
    success = await admin_service.hide_post(post_id)
    
    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Post not found"
        )
    
    return MessageResponse(message="Post hidden successfully")


@router.put("/complaints/{complaint_id}/hide", response_model=MessageResponse)
async def hide_complaint(
    complaint_id: str,
    current_user: Dict[str, Any] = Depends(verify_admin)
):
    """
    Hide a complaint (content moderation).
    """
    success = await admin_service.hide_complaint(complaint_id)
    
    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Complaint not found"
        )
    
    return MessageResponse(message="Complaint hidden successfully")
