"""
Complaint model for MongoDB
"""
from datetime import datetime
from typing import Optional, List
from enum import Enum
from beanie import Document, Indexed, Link
from pydantic import BaseModel, Field


class ComplaintCategory(str, Enum):
    """Complaint category enumeration"""
    WATER_LEAKAGE = "water_leakage"
    STREET_LIGHT = "street_light"
    GARBAGE = "garbage"
    LAW_AND_ORDER = "law_and_order"
    ROAD_DAMAGE = "road_damage"
    DRAINAGE = "drainage"
    ELECTRICITY = "electricity"
    SANITATION = "sanitation"
    NOISE_POLLUTION = "noise_pollution"
    OTHER = "other"


class ComplaintStatus(str, Enum):
    """Complaint status enumeration"""
    PENDING = "pending"
    ACKNOWLEDGED = "acknowledged"
    IN_PROGRESS = "in_progress"
    RESOLVED = "resolved"
    REJECTED = "rejected"
    ESCALATED = "escalated"


class ComplaintPriority(str, Enum):
    """Complaint priority enumeration"""
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    CRITICAL = "critical"


class GeoLocation(BaseModel):
    """Geo location for complaint"""
    type: str = "Point"
    coordinates: List[float]  # [longitude, latitude]


class ComplaintLocation(BaseModel):
    """Location details for complaint"""
    geo: GeoLocation
    address: Optional[str] = None
    landmark: Optional[str] = None
    city: Optional[str] = None
    state: Optional[str] = None
    pincode: Optional[str] = None


class ComplaintImage(BaseModel):
    """Image attached to complaint"""
    url: str
    thumbnail_url: Optional[str] = None
    uploaded_at: datetime = Field(default_factory=datetime.utcnow)
    is_primary: bool = False


class AuthorityMention(BaseModel):
    """Authority mentioned in complaint"""
    authority_type: str  # e.g., @police, @municipality
    user_id: Optional[str] = None  # If specific authority user is tagged
    notified: bool = False
    notified_at: Optional[datetime] = None


class ComplaintComment(BaseModel):
    """Comment on complaint"""
    id: str
    user_id: str
    user_name: str
    content: str
    created_at: datetime = Field(default_factory=datetime.utcnow)


class StatusUpdate(BaseModel):
    """Status update history"""
    status: ComplaintStatus
    updated_by: str  # User ID
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    notes: Optional[str] = None


class Complaint(Document):
    """Complaint document model"""
    
    # Basic info
    title: str
    description: str
    category: ComplaintCategory
    
    # Location
    location: ComplaintLocation
    
    # Media
    images: List[ComplaintImage] = Field(default_factory=list)
    
    # Status and priority
    status: ComplaintStatus = ComplaintStatus.PENDING
    priority: ComplaintPriority = ComplaintPriority.MEDIUM
    
    # Authority mentions
    mentioned_authorities: List[AuthorityMention] = Field(default_factory=list)
    assigned_to: Optional[str] = None  # Authority user ID
    
    # User interactions
    reporter_id: Indexed(str)
    reporter_name: str
    upvotes: List[str] = Field(default_factory=list)  # List of user IDs
    comments: List[ComplaintComment] = Field(default_factory=list)
    
    # Status history
    status_history: List[StatusUpdate] = Field(default_factory=list)
    
    # Visibility
    is_public: bool = True
    
    # Timestamps
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    resolved_at: Optional[datetime] = None
    
    class Settings:
        name = "complaints"
        indexes = [
            "reporter_id",
            "category",
            "status",
            "priority",
            [("location.geo", "2dsphere")],  # Geospatial index
        ]
    
    @property
    def upvote_count(self) -> int:
        """Get upvote count"""
        return len(self.upvotes)
    
    @property
    def comment_count(self) -> int:
        """Get comment count"""
        return len(self.comments)
    
    def get_coordinates(self) -> tuple:
        """Get latitude and longitude"""
        coords = self.location.geo.coordinates
        return (coords[1], coords[0])  # (lat, lng)
