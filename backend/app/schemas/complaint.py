"""
Complaint schemas for API requests and responses
"""
from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel, Field

from app.db.models.complaint import (
    ComplaintCategory, 
    ComplaintStatus, 
    ComplaintPriority
)


class GeoLocationSchema(BaseModel):
    """Geo location schema"""
    type: str = "Point"
    coordinates: List[float]  # [longitude, latitude]


class ComplaintLocationSchema(BaseModel):
    """Complaint location schema"""
    latitude: float
    longitude: float
    address: Optional[str] = None
    landmark: Optional[str] = None
    city: Optional[str] = None
    state: Optional[str] = None
    pincode: Optional[str] = None


class ComplaintImageSchema(BaseModel):
    """Complaint image schema"""
    url: str
    thumbnail_url: Optional[str] = None
    is_primary: bool = False


class AuthorityMentionSchema(BaseModel):
    """Authority mention schema"""
    authority_type: str
    user_id: Optional[str] = None


class CommentCreateRequest(BaseModel):
    """Create comment request"""
    content: str = Field(..., min_length=1, max_length=1000)


class CommentResponse(BaseModel):
    """Comment response"""
    id: str
    user_id: str
    user_name: str
    content: str
    created_at: datetime


# Request Schemas
class CreateComplaintRequest(BaseModel):
    """Create complaint request"""
    title: str = Field(..., min_length=5, max_length=200)
    description: str = Field(..., min_length=10, max_length=2000)
    category: ComplaintCategory
    location: ComplaintLocationSchema
    mentioned_authorities: List[str] = Field(default_factory=list)  # e.g., ["@police", "@municipality"]
    is_public: bool = True


class UpdateComplaintRequest(BaseModel):
    """Update complaint request"""
    title: Optional[str] = Field(None, min_length=5, max_length=200)
    description: Optional[str] = Field(None, min_length=10, max_length=2000)
    category: Optional[ComplaintCategory] = None


class UpdateComplaintStatusRequest(BaseModel):
    """Update complaint status request (for authorities)"""
    status: ComplaintStatus
    notes: Optional[str] = None


class ComplaintQueryParams(BaseModel):
    """Query parameters for complaint listing"""
    category: Optional[ComplaintCategory] = None
    status: Optional[ComplaintStatus] = None
    priority: Optional[ComplaintPriority] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    radius_km: float = 10.0
    page: int = 1
    page_size: int = 20


# Response Schemas
class StatusUpdateResponse(BaseModel):
    """Status update history response"""
    status: ComplaintStatus
    updated_by: str
    updated_at: datetime
    notes: Optional[str] = None


class ComplaintResponse(BaseModel):
    """Complaint response"""
    id: str
    title: str
    description: str
    category: ComplaintCategory
    location: ComplaintLocationSchema
    images: List[ComplaintImageSchema]
    status: ComplaintStatus
    priority: ComplaintPriority
    mentioned_authorities: List[AuthorityMentionSchema]
    assigned_to: Optional[str] = None
    reporter_id: str
    reporter_name: str
    upvote_count: int
    comment_count: int
    is_public: bool
    created_at: datetime
    updated_at: datetime
    resolved_at: Optional[datetime] = None


class ComplaintDetailResponse(ComplaintResponse):
    """Detailed complaint response with comments and history"""
    comments: List[CommentResponse]
    status_history: List[StatusUpdateResponse]
    user_has_upvoted: bool = False


class ComplaintListResponse(BaseModel):
    """Complaint list response"""
    complaints: List[ComplaintResponse]
    total: int
    page: int
    page_size: int


class ComplaintStatsResponse(BaseModel):
    """Complaint statistics response"""
    total_complaints: int
    pending: int
    in_progress: int
    resolved: int
    by_category: dict
