"""
Community models for social features
"""
from datetime import datetime
from typing import Optional, List
from enum import Enum
from beanie import Document, Indexed
from pydantic import BaseModel, Field


class PostType(str, Enum):
    """Post type enumeration"""
    UPDATE = "update"
    DISCUSSION = "discussion"
    ANNOUNCEMENT = "announcement"
    POLL = "poll"
    EVENT = "event"


class PostVisibility(str, Enum):
    """Post visibility enumeration"""
    PUBLIC = "public"
    FOLLOWERS = "followers"
    LOCAL = "local"  # Based on location


class PollOption(BaseModel):
    """Poll option model"""
    id: str
    text: str
    votes: List[str] = Field(default_factory=list)  # User IDs


class PostLocation(BaseModel):
    """Location for post"""
    latitude: float
    longitude: float
    city: Optional[str] = None
    state: Optional[str] = None


class Post(Document):
    """Community post document"""
    
    # Content
    content: str
    post_type: PostType = PostType.UPDATE
    
    # Media
    images: List[str] = Field(default_factory=list)  # Image URLs
    
    # Poll (if post_type is POLL)
    poll_options: List[PollOption] = Field(default_factory=list)
    poll_ends_at: Optional[datetime] = None
    
    # Location
    location: Optional[PostLocation] = None
    
    # Author
    author_id: Indexed(str)
    author_name: str
    author_avatar: Optional[str] = None
    
    # Engagement
    likes: List[str] = Field(default_factory=list)  # User IDs
    shares: int = 0
    
    # Visibility
    visibility: PostVisibility = PostVisibility.PUBLIC
    
    # Tags and mentions
    tags: List[str] = Field(default_factory=list)
    mentions: List[str] = Field(default_factory=list)  # User IDs
    
    # Status
    is_pinned: bool = False
    is_active: bool = True
    
    # Timestamps
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    
    class Settings:
        name = "posts"
        indexes = [
            "author_id",
            "post_type",
            "visibility",
            "created_at",
        ]
    
    @property
    def like_count(self) -> int:
        """Get like count"""
        return len(self.likes)


class Comment(Document):
    """Comment document for posts"""
    
    # Reference
    post_id: Indexed(str)
    parent_id: Optional[str] = None  # For nested comments
    
    # Content
    content: str
    
    # Author
    author_id: Indexed(str)
    author_name: str
    author_avatar: Optional[str] = None
    
    # Engagement
    likes: List[str] = Field(default_factory=list)
    
    # Status
    is_active: bool = True
    
    # Timestamps
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    
    class Settings:
        name = "comments"
        indexes = [
            "post_id",
            "author_id",
            "parent_id",
        ]
    
    @property
    def like_count(self) -> int:
        """Get like count"""
        return len(self.likes)
