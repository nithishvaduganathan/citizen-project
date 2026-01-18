"""
User model for MongoDB
"""
from datetime import datetime
from typing import Optional, List
from enum import Enum
from beanie import Document, Indexed
from pydantic import BaseModel, EmailStr, Field


class UserRole(str, Enum):
    """User role enumeration"""
    CITIZEN = "citizen"
    AUTHORITY = "authority"
    ADMIN = "admin"


class AuthorityType(str, Enum):
    """Authority type enumeration for tagging"""
    POLICE = "police"
    MUNICIPALITY = "municipality"
    ELECTRICITY = "electricity"
    WATER = "water"
    HEALTH = "health"
    EDUCATION = "education"
    TRANSPORT = "transport"
    OTHER = "other"


class Location(BaseModel):
    """Location model for geolocation data"""
    latitude: float
    longitude: float
    address: Optional[str] = None
    city: Optional[str] = None
    state: Optional[str] = None
    country: str = "India"
    pincode: Optional[str] = None


class UserProfile(BaseModel):
    """User profile information"""
    phone: Optional[str] = None
    bio: Optional[str] = None
    avatar_url: Optional[str] = None
    preferred_language: str = "en"
    location: Optional[Location] = None


class User(Document):
    """User document model"""
    
    # Authentication fields
    email: Indexed(EmailStr, unique=True)
    firebase_uid: Optional[str] = None
    password_hash: Optional[str] = None
    
    # Basic info
    full_name: str
    username: Indexed(str, unique=True)
    role: UserRole = UserRole.CITIZEN
    
    # Profile
    profile: UserProfile = Field(default_factory=UserProfile)
    
    # Authority specific fields
    authority_type: Optional[AuthorityType] = None
    authority_verified: bool = False
    authority_department: Optional[str] = None
    authority_jurisdiction: Optional[str] = None
    
    # Social features
    followers: List[str] = Field(default_factory=list)  # List of user IDs
    following: List[str] = Field(default_factory=list)  # List of user IDs
    
    # Status
    is_active: bool = True
    is_verified: bool = False
    
    # Timestamps
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    last_login: Optional[datetime] = None
    
    class Settings:
        name = "users"
        indexes = [
            "email",
            "username",
            "firebase_uid",
            "role",
            "authority_type",
        ]
    
    def is_admin(self) -> bool:
        """Check if user is admin"""
        return self.role == UserRole.ADMIN
    
    def is_authority(self) -> bool:
        """Check if user is authority"""
        return self.role == UserRole.AUTHORITY
    
    def can_manage_complaints(self) -> bool:
        """Check if user can manage complaints"""
        return self.role in [UserRole.AUTHORITY, UserRole.ADMIN]
