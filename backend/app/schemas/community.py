"""
Community schemas for API requests and responses
"""
from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel, Field

from app.db.models.community import PostType, PostVisibility


class PostLocationSchema(BaseModel):
    """Post location schema"""
    latitude: float
    longitude: float
    city: Optional[str] = None
    state: Optional[str] = None


class PollOptionSchema(BaseModel):
    """Poll option schema"""
    id: str
    text: str
    vote_count: int = 0


# Request Schemas
class CreatePostRequest(BaseModel):
    """Create post request"""
    content: str = Field(..., min_length=1, max_length=2000)
    post_type: PostType = PostType.UPDATE
    location: Optional[PostLocationSchema] = None
    tags: List[str] = Field(default_factory=list)
    mentions: List[str] = Field(default_factory=list)  # Usernames
    visibility: PostVisibility = PostVisibility.PUBLIC
    
    # Poll options (if post_type is POLL)
    poll_options: List[str] = Field(default_factory=list)
    poll_duration_hours: Optional[int] = None


class UpdatePostRequest(BaseModel):
    """Update post request"""
    content: Optional[str] = Field(None, min_length=1, max_length=2000)
    visibility: Optional[PostVisibility] = None


class CreateCommentRequest(BaseModel):
    """Create comment request"""
    content: str = Field(..., min_length=1, max_length=1000)
    parent_id: Optional[str] = None  # For nested comments


class PostQueryParams(BaseModel):
    """Query parameters for post listing"""
    post_type: Optional[PostType] = None
    author_id: Optional[str] = None
    tag: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    radius_km: float = 10.0
    page: int = 1
    page_size: int = 20


# Response Schemas
class CommentResponse(BaseModel):
    """Comment response"""
    id: str
    post_id: str
    parent_id: Optional[str] = None
    content: str
    author_id: str
    author_name: str
    author_avatar: Optional[str] = None
    like_count: int
    user_has_liked: bool = False
    created_at: datetime


class PostResponse(BaseModel):
    """Post response"""
    id: str
    content: str
    post_type: PostType
    images: List[str]
    location: Optional[PostLocationSchema] = None
    author_id: str
    author_name: str
    author_avatar: Optional[str] = None
    like_count: int
    comment_count: int
    shares: int
    visibility: PostVisibility
    tags: List[str]
    is_pinned: bool
    user_has_liked: bool = False
    created_at: datetime
    updated_at: datetime


class PostDetailResponse(PostResponse):
    """Detailed post response with poll and comments"""
    poll_options: List[PollOptionSchema] = Field(default_factory=list)
    poll_ends_at: Optional[datetime] = None
    user_voted_option: Optional[str] = None


class PostListResponse(BaseModel):
    """Post list response"""
    posts: List[PostResponse]
    total: int
    page: int
    page_size: int


class UserFollowResponse(BaseModel):
    """User follow response"""
    id: str
    username: str
    full_name: str
    avatar_url: Optional[str] = None
    is_following: bool = False


class FollowListResponse(BaseModel):
    """Follow list response"""
    users: List[UserFollowResponse]
    total: int
    page: int
    page_size: int
