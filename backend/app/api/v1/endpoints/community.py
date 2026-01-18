"""
Community API endpoints
"""
from fastapi import APIRouter, HTTPException, status, Depends, UploadFile, File, Form
from typing import Dict, Any, List, Optional

from app.schemas.community import (
    CreatePostRequest,
    UpdatePostRequest,
    CreateCommentRequest,
    PostResponse,
    PostDetailResponse,
    PostListResponse,
    CommentResponse,
    FollowListResponse,
)
from app.schemas.user import MessageResponse
from app.core.security import get_current_user_from_token
from app.services.community.community_service import community_service
from app.services.auth.auth_service import auth_service
from app.db.models.community import PostType, PostVisibility

router = APIRouter(prefix="/community", tags=["Community"])


# Posts
@router.post("/posts", response_model=PostResponse)
async def create_post(
    request: CreatePostRequest,
    current_user: Dict[str, Any] = Depends(get_current_user_from_token)
):
    """
    Create a new community post.
    """
    user_id = current_user.get("sub")
    user = await auth_service.get_user_by_id(user_id)
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    return await community_service.create_post(
        user_id=user_id,
        user_name=user.full_name,
        avatar_url=user.profile.avatar_url if user.profile else None,
        request=request,
    )


@router.get("/posts", response_model=PostListResponse)
async def list_posts(
    page: int = 1,
    page_size: int = 20,
    post_type: Optional[PostType] = None,
    author_id: Optional[str] = None,
    tag: Optional[str] = None,
):
    """
    List public community posts.
    """
    return await community_service.list_posts(
        page=page,
        page_size=page_size,
        post_type=post_type,
        author_id=author_id,
        tag=tag,
    )


@router.get("/feed", response_model=PostListResponse)
async def get_feed(
    page: int = 1,
    page_size: int = 20,
    current_user: Dict[str, Any] = Depends(get_current_user_from_token)
):
    """
    Get personalized feed (posts from followed users + public).
    """
    user_id = current_user.get("sub")
    
    return await community_service.list_feed_posts(
        user_id=user_id,
        page=page,
        page_size=page_size,
    )


@router.get("/posts/{post_id}", response_model=PostDetailResponse)
async def get_post(
    post_id: str,
    current_user: Optional[Dict[str, Any]] = Depends(get_current_user_from_token)
):
    """
    Get post details by ID.
    """
    user_id = current_user.get("sub") if current_user else None
    
    post = await community_service.get_post(post_id, user_id)
    
    if not post:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Post not found"
        )
    
    return post


@router.put("/posts/{post_id}", response_model=PostResponse)
async def update_post(
    post_id: str,
    request: UpdatePostRequest,
    current_user: Dict[str, Any] = Depends(get_current_user_from_token)
):
    """
    Update a post (by author only).
    """
    user_id = current_user.get("sub")
    
    result = await community_service.update_post(post_id, user_id, request)
    
    if not result:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Post not found or not authorized"
        )
    
    return result


@router.delete("/posts/{post_id}", response_model=MessageResponse)
async def delete_post(
    post_id: str,
    current_user: Dict[str, Any] = Depends(get_current_user_from_token)
):
    """
    Delete a post (by author only).
    """
    user_id = current_user.get("sub")
    
    success = await community_service.delete_post(post_id, user_id)
    
    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Post not found or not authorized"
        )
    
    return MessageResponse(message="Post deleted successfully")


@router.post("/posts/{post_id}/like", response_model=MessageResponse)
async def like_post(
    post_id: str,
    current_user: Dict[str, Any] = Depends(get_current_user_from_token)
):
    """
    Toggle like on a post.
    """
    user_id = current_user.get("sub")
    
    success = await community_service.like_post(post_id, user_id)
    
    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Post not found"
        )
    
    return MessageResponse(message="Like toggled successfully")


@router.post("/posts/{post_id}/vote/{option_id}", response_model=MessageResponse)
async def vote_poll(
    post_id: str,
    option_id: str,
    current_user: Dict[str, Any] = Depends(get_current_user_from_token)
):
    """
    Vote on a poll option.
    """
    user_id = current_user.get("sub")
    
    success = await community_service.vote_poll(post_id, user_id, option_id)
    
    if not success:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid poll or voting not allowed"
        )
    
    return MessageResponse(message="Vote recorded successfully")


# Comments
@router.post("/posts/{post_id}/comments", response_model=CommentResponse)
async def create_comment(
    post_id: str,
    request: CreateCommentRequest,
    current_user: Dict[str, Any] = Depends(get_current_user_from_token)
):
    """
    Create a comment on a post.
    """
    user_id = current_user.get("sub")
    user = await auth_service.get_user_by_id(user_id)
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    result = await community_service.create_comment(
        post_id=post_id,
        user_id=user_id,
        user_name=user.full_name,
        avatar_url=user.profile.avatar_url if user.profile else None,
        request=request,
    )
    
    if not result:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Post not found"
        )
    
    return result


@router.get("/posts/{post_id}/comments", response_model=List[CommentResponse])
async def list_comments(
    post_id: str,
    page: int = 1,
    page_size: int = 50,
    current_user: Optional[Dict[str, Any]] = Depends(get_current_user_from_token)
):
    """
    List comments for a post.
    """
    user_id = current_user.get("sub") if current_user else None
    
    return await community_service.list_comments(
        post_id=post_id,
        user_id=user_id,
        page=page,
        page_size=page_size,
    )


@router.post("/comments/{comment_id}/like", response_model=MessageResponse)
async def like_comment(
    comment_id: str,
    current_user: Dict[str, Any] = Depends(get_current_user_from_token)
):
    """
    Toggle like on a comment.
    """
    user_id = current_user.get("sub")
    
    success = await community_service.like_comment(comment_id, user_id)
    
    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Comment not found"
        )
    
    return MessageResponse(message="Like toggled successfully")


@router.delete("/comments/{comment_id}", response_model=MessageResponse)
async def delete_comment(
    comment_id: str,
    current_user: Dict[str, Any] = Depends(get_current_user_from_token)
):
    """
    Delete a comment (by author only).
    """
    user_id = current_user.get("sub")
    
    success = await community_service.delete_comment(comment_id, user_id)
    
    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Comment not found or not authorized"
        )
    
    return MessageResponse(message="Comment deleted successfully")


# Follow system
@router.post("/users/{user_id}/follow", response_model=MessageResponse)
async def follow_user(
    user_id: str,
    current_user: Dict[str, Any] = Depends(get_current_user_from_token)
):
    """
    Follow a user.
    """
    current_user_id = current_user.get("sub")
    
    success = await community_service.follow_user(current_user_id, user_id)
    
    if not success:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot follow user"
        )
    
    return MessageResponse(message="User followed successfully")


@router.post("/users/{user_id}/unfollow", response_model=MessageResponse)
async def unfollow_user(
    user_id: str,
    current_user: Dict[str, Any] = Depends(get_current_user_from_token)
):
    """
    Unfollow a user.
    """
    current_user_id = current_user.get("sub")
    
    success = await community_service.unfollow_user(current_user_id, user_id)
    
    if not success:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot unfollow user"
        )
    
    return MessageResponse(message="User unfollowed successfully")


@router.get("/users/{user_id}/followers", response_model=FollowListResponse)
async def get_followers(
    user_id: str,
    page: int = 1,
    page_size: int = 20,
):
    """
    Get user's followers.
    """
    return await community_service.get_followers(user_id, page, page_size)


@router.get("/users/{user_id}/following", response_model=FollowListResponse)
async def get_following(
    user_id: str,
    page: int = 1,
    page_size: int = 20,
):
    """
    Get users that user is following.
    """
    return await community_service.get_following(user_id, page, page_size)
