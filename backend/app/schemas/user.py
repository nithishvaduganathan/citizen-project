"""
User schemas for API requests and responses
"""
from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel, EmailStr, Field, field_validator
import re

from app.db.models.user import UserRole, AuthorityType


class LocationSchema(BaseModel):
    """Location schema"""
    latitude: float
    longitude: float
    address: Optional[str] = None
    city: Optional[str] = None
    state: Optional[str] = None
    country: str = "India"
    pincode: Optional[str] = None


class UserProfileSchema(BaseModel):
    """User profile schema"""
    phone: Optional[str] = None
    bio: Optional[str] = None
    avatar_url: Optional[str] = None
    preferred_language: str = "en"
    location: Optional[LocationSchema] = None


# Request Schemas
class UserRegisterRequest(BaseModel):
    """User registration request"""
    email: EmailStr
    password: str = Field(..., min_length=8)
    full_name: str = Field(..., min_length=2, max_length=100)
    username: str = Field(..., min_length=3, max_length=30)
    profile: Optional[UserProfileSchema] = None
    
    @field_validator('username')
    @classmethod
    def validate_username(cls, v):
        if not re.match(r'^[a-zA-Z0-9_]+$', v):
            raise ValueError('Username can only contain letters, numbers, and underscores')
        return v.lower()
    
    @field_validator('password')
    @classmethod
    def validate_password(cls, v):
        if not re.search(r'[A-Z]', v):
            raise ValueError('Password must contain at least one uppercase letter')
        if not re.search(r'[a-z]', v):
            raise ValueError('Password must contain at least one lowercase letter')
        if not re.search(r'\d', v):
            raise ValueError('Password must contain at least one digit')
        return v


class UserLoginRequest(BaseModel):
    """User login request"""
    email: EmailStr
    password: str


class FirebaseAuthRequest(BaseModel):
    """Firebase authentication request"""
    firebase_token: str
    full_name: Optional[str] = None
    username: Optional[str] = None


class AdminLoginRequest(BaseModel):
    """Admin login request (no signup allowed)"""
    email: EmailStr
    password: str


class UpdateProfileRequest(BaseModel):
    """Update user profile request"""
    full_name: Optional[str] = Field(None, min_length=2, max_length=100)
    profile: Optional[UserProfileSchema] = None


class AuthorityRegistrationRequest(BaseModel):
    """Authority registration request"""
    authority_type: AuthorityType
    department: str
    jurisdiction: str


# Response Schemas
class UserResponse(BaseModel):
    """User response"""
    id: str
    email: EmailStr
    full_name: str
    username: str
    role: UserRole
    profile: UserProfileSchema
    is_active: bool
    is_verified: bool
    authority_type: Optional[AuthorityType] = None
    authority_verified: bool = False
    followers_count: int = 0
    following_count: int = 0
    created_at: datetime


class UserListResponse(BaseModel):
    """User list response"""
    users: List[UserResponse]
    total: int
    page: int
    page_size: int


class AuthResponse(BaseModel):
    """Authentication response"""
    access_token: str
    token_type: str = "bearer"
    user: UserResponse


class MessageResponse(BaseModel):
    """Generic message response"""
    message: str
    success: bool = True
