"""
Complaint API endpoints
"""
from fastapi import APIRouter, HTTPException, status, Depends, UploadFile, File, Form
from typing import Dict, Any, List, Optional
import json

from app.schemas.complaint import (
    CreateComplaintRequest,
    UpdateComplaintRequest,
    UpdateComplaintStatusRequest,
    ComplaintResponse,
    ComplaintDetailResponse,
    ComplaintListResponse,
    ComplaintStatsResponse,
    CommentCreateRequest,
    CommentResponse,
    ComplaintLocationSchema,
)
from app.schemas.user import MessageResponse
from app.core.security import get_current_user_from_token, check_authority_role
from app.services.complaints.complaint_service import complaint_service
from app.services.auth.auth_service import auth_service
from app.db.models.complaint import ComplaintCategory, ComplaintStatus

router = APIRouter(prefix="/complaints", tags=["Complaints"])


@router.post("", response_model=ComplaintResponse)
async def create_complaint(
    title: str = Form(...),
    description: str = Form(...),
    category: ComplaintCategory = Form(...),
    latitude: float = Form(...),
    longitude: float = Form(...),
    address: Optional[str] = Form(None),
    landmark: Optional[str] = Form(None),
    city: Optional[str] = Form(None),
    state: Optional[str] = Form(None),
    pincode: Optional[str] = Form(None),
    mentioned_authorities: str = Form("[]"),
    is_public: bool = Form(True),
    images: List[UploadFile] = File(default=[]),
    current_user: Dict[str, Any] = Depends(get_current_user_from_token)
):
    """
    Create a new complaint.
    
    - Upload live images
    - Automatically captures GPS location
    - Tag authorities using mentions like @police, @municipality
    """
    user_id = current_user.get("sub")
    user = await auth_service.get_user_by_id(user_id)
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    # Parse mentioned authorities
    try:
        authorities_list = json.loads(mentioned_authorities)
    except json.JSONDecodeError:
        authorities_list = []
    
    # Handle image uploads (in production, upload to cloud storage)
    image_urls = []
    for image in images:
        # In production: upload to S3/GCS and get URL
        # For now, we'll skip actual file handling
        image_urls.append(f"/uploads/{image.filename}")
    
    request = CreateComplaintRequest(
        title=title,
        description=description,
        category=category,
        location=ComplaintLocationSchema(
            latitude=latitude,
            longitude=longitude,
            address=address,
            landmark=landmark,
            city=city,
            state=state,
            pincode=pincode,
        ),
        mentioned_authorities=authorities_list,
        is_public=is_public,
    )
    
    return await complaint_service.create_complaint(
        user_id=user_id,
        user_name=user.full_name,
        request=request,
        image_urls=image_urls,
    )


@router.get("", response_model=ComplaintListResponse)
async def list_complaints(
    page: int = 1,
    page_size: int = 20,
    category: Optional[ComplaintCategory] = None,
    status: Optional[ComplaintStatus] = None,
):
    """
    List all public complaints with optional filters.
    """
    return await complaint_service.list_complaints(
        page=page,
        page_size=page_size,
        category=category.value if category else None,
        status=status.value if status else None,
    )


@router.get("/nearby", response_model=ComplaintListResponse)
async def list_nearby_complaints(
    latitude: float,
    longitude: float,
    radius_km: float = 10.0,
    page: int = 1,
    page_size: int = 20,
):
    """
    List complaints near a location.
    
    - Uses GPS coordinates
    - Returns complaints within specified radius
    """
    return await complaint_service.list_nearby_complaints(
        latitude=latitude,
        longitude=longitude,
        radius_km=radius_km,
        page=page,
        page_size=page_size,
    )


@router.get("/my", response_model=ComplaintListResponse)
async def list_my_complaints(
    page: int = 1,
    page_size: int = 20,
    status: Optional[ComplaintStatus] = None,
    current_user: Dict[str, Any] = Depends(get_current_user_from_token)
):
    """
    List complaints created by current user.
    """
    user_id = current_user.get("sub")
    
    return await complaint_service.list_complaints(
        page=page,
        page_size=page_size,
        user_id=user_id,
        status=status.value if status else None,
    )


@router.get("/stats", response_model=ComplaintStatsResponse)
async def get_complaint_stats():
    """
    Get complaint statistics.
    """
    return await complaint_service.get_complaint_stats()


@router.get("/{complaint_id}", response_model=ComplaintDetailResponse)
async def get_complaint(
    complaint_id: str,
    current_user: Optional[Dict[str, Any]] = Depends(get_current_user_from_token)
):
    """
    Get complaint details by ID.
    """
    user_id = current_user.get("sub") if current_user else None
    
    complaint = await complaint_service.get_complaint(complaint_id, user_id)
    
    if not complaint:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Complaint not found"
        )
    
    return complaint


@router.put("/{complaint_id}", response_model=ComplaintResponse)
async def update_complaint(
    complaint_id: str,
    request: UpdateComplaintRequest,
    current_user: Dict[str, Any] = Depends(get_current_user_from_token)
):
    """
    Update complaint (by reporter only).
    """
    user_id = current_user.get("sub")
    
    result = await complaint_service.update_complaint(
        complaint_id=complaint_id,
        user_id=user_id,
        request=request,
    )
    
    if not result:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Complaint not found or not authorized"
        )
    
    return result


@router.put("/{complaint_id}/status", response_model=ComplaintResponse)
async def update_complaint_status(
    complaint_id: str,
    request: UpdateComplaintStatusRequest,
    current_user: Dict[str, Any] = Depends(get_current_user_from_token)
):
    """
    Update complaint status (by authority/admin only).
    """
    user_id = current_user.get("sub")
    user = await auth_service.get_user_by_id(user_id)
    
    if not user or not check_authority_role({"role": user.role.value}):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only authorities can update complaint status"
        )
    
    result = await complaint_service.update_complaint_status(
        complaint_id=complaint_id,
        authority_id=user_id,
        request=request,
    )
    
    if not result:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Complaint not found"
        )
    
    return result


@router.post("/{complaint_id}/upvote", response_model=MessageResponse)
async def upvote_complaint(
    complaint_id: str,
    current_user: Dict[str, Any] = Depends(get_current_user_from_token)
):
    """
    Toggle upvote on a complaint.
    """
    user_id = current_user.get("sub")
    
    success = await complaint_service.upvote_complaint(complaint_id, user_id)
    
    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Complaint not found"
        )
    
    return MessageResponse(message="Upvote toggled successfully")


@router.post("/{complaint_id}/comments", response_model=CommentResponse)
async def add_comment(
    complaint_id: str,
    request: CommentCreateRequest,
    current_user: Dict[str, Any] = Depends(get_current_user_from_token)
):
    """
    Add a comment to a complaint.
    """
    user_id = current_user.get("sub")
    user = await auth_service.get_user_by_id(user_id)
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    result = await complaint_service.add_comment(
        complaint_id=complaint_id,
        user_id=user_id,
        user_name=user.full_name,
        request=request,
    )
    
    if not result:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Complaint not found"
        )
    
    return result


@router.delete("/{complaint_id}", response_model=MessageResponse)
async def delete_complaint(
    complaint_id: str,
    current_user: Dict[str, Any] = Depends(get_current_user_from_token)
):
    """
    Delete a complaint (by reporter or admin).
    """
    user_id = current_user.get("sub")
    
    success = await complaint_service.delete_complaint(complaint_id, user_id)
    
    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Complaint not found or not authorized"
        )
    
    return MessageResponse(message="Complaint deleted successfully")
