"""
Community social features service
"""
from datetime import datetime, timedelta
from typing import List, Optional
from bson import ObjectId
import uuid

from app.db.models.community import Post, Comment, PostType, PostVisibility, PollOption
from app.db.models.user import User
from app.schemas.community import (
    CreatePostRequest,
    UpdatePostRequest,
    CreateCommentRequest,
    PostResponse,
    PostDetailResponse,
    PostListResponse,
    CommentResponse,
    PollOptionSchema,
    UserFollowResponse,
    FollowListResponse,
)


class CommunityService:
    """Community and social features service"""
    
    # Posts
    async def create_post(
        self,
        user_id: str,
        user_name: str,
        avatar_url: Optional[str],
        request: CreatePostRequest,
        image_urls: List[str] = None
    ) -> PostResponse:
        """Create a new post"""
        # Create poll options if poll type
        poll_options = []
        poll_ends_at = None
        
        if request.post_type == PostType.POLL and request.poll_options:
            poll_options = [
                PollOption(id=str(uuid.uuid4()), text=opt)
                for opt in request.poll_options
            ]
            if request.poll_duration_hours:
                poll_ends_at = datetime.utcnow() + timedelta(hours=request.poll_duration_hours)
        
        post = Post(
            content=request.content,
            post_type=request.post_type,
            images=image_urls or [],
            poll_options=poll_options,
            poll_ends_at=poll_ends_at,
            location=request.location,
            author_id=user_id,
            author_name=user_name,
            author_avatar=avatar_url,
            visibility=request.visibility,
            tags=request.tags,
            mentions=request.mentions,
        )
        
        await post.insert()
        
        return self._post_to_response(post)
    
    async def get_post(
        self, 
        post_id: str, 
        user_id: Optional[str] = None
    ) -> Optional[PostDetailResponse]:
        """Get post by ID with details"""
        try:
            post = await Post.get(ObjectId(post_id))
            if not post or not post.is_active:
                return None
            
            user_has_liked = user_id in post.likes if user_id else False
            
            # Get vote info for polls
            user_voted_option = None
            if post.post_type == PostType.POLL and user_id:
                for opt in post.poll_options:
                    if user_id in opt.votes:
                        user_voted_option = opt.id
                        break
            
            # Get comment count
            comment_count = await Comment.find(
                Comment.post_id == str(post.id),
                Comment.is_active == True
            ).count()
            
            return PostDetailResponse(
                **self._post_to_response(post, comment_count).model_dump(),
                poll_options=[
                    PollOptionSchema(
                        id=opt.id,
                        text=opt.text,
                        vote_count=len(opt.votes)
                    )
                    for opt in post.poll_options
                ],
                poll_ends_at=post.poll_ends_at,
                user_voted_option=user_voted_option,
                user_has_liked=user_has_liked,
            )
        except Exception:
            return None
    
    async def list_posts(
        self,
        page: int = 1,
        page_size: int = 20,
        post_type: Optional[PostType] = None,
        author_id: Optional[str] = None,
        tag: Optional[str] = None,
    ) -> PostListResponse:
        """List posts with filters"""
        query = {"is_active": True, "visibility": PostVisibility.PUBLIC.value}
        
        if post_type:
            query["post_type"] = post_type.value
        if author_id:
            query["author_id"] = author_id
        if tag:
            query["tags"] = tag
        
        total = await Post.find(query).count()
        
        skip = (page - 1) * page_size
        posts = await Post.find(query).sort(
            -Post.created_at
        ).skip(skip).limit(page_size).to_list()
        
        return PostListResponse(
            posts=[self._post_to_response(p) for p in posts],
            total=total,
            page=page,
            page_size=page_size,
        )
    
    async def list_feed_posts(
        self,
        user_id: str,
        page: int = 1,
        page_size: int = 20,
    ) -> PostListResponse:
        """List posts for user's feed (from followed users + public)"""
        # Get user's following list
        user = await User.get(ObjectId(user_id))
        if not user:
            return PostListResponse(posts=[], total=0, page=page, page_size=page_size)
        
        following_ids = user.following
        
        # Query for posts from followed users or public posts
        query = {
            "is_active": True,
            "$or": [
                {"author_id": {"$in": following_ids}},
                {"visibility": PostVisibility.PUBLIC.value}
            ]
        }
        
        total = await Post.find(query).count()
        
        skip = (page - 1) * page_size
        posts = await Post.find(query).sort(
            -Post.created_at
        ).skip(skip).limit(page_size).to_list()
        
        return PostListResponse(
            posts=[self._post_to_response(p) for p in posts],
            total=total,
            page=page,
            page_size=page_size,
        )
    
    async def update_post(
        self,
        post_id: str,
        user_id: str,
        request: UpdatePostRequest
    ) -> Optional[PostResponse]:
        """Update post (by author only)"""
        try:
            post = await Post.get(ObjectId(post_id))
            if not post or post.author_id != user_id:
                return None
            
            if request.content:
                post.content = request.content
            if request.visibility:
                post.visibility = request.visibility
            
            post.updated_at = datetime.utcnow()
            await post.save()
            
            return self._post_to_response(post)
        except Exception:
            return None
    
    async def delete_post(self, post_id: str, user_id: str) -> bool:
        """Delete post (soft delete)"""
        try:
            post = await Post.get(ObjectId(post_id))
            if not post or post.author_id != user_id:
                return False
            
            post.is_active = False
            await post.save()
            return True
        except Exception:
            return False
    
    async def like_post(self, post_id: str, user_id: str) -> bool:
        """Toggle like on post"""
        try:
            post = await Post.get(ObjectId(post_id))
            if not post:
                return False
            
            if user_id in post.likes:
                post.likes.remove(user_id)
            else:
                post.likes.append(user_id)
            
            await post.save()
            return True
        except Exception:
            return False
    
    async def vote_poll(
        self, 
        post_id: str, 
        user_id: str, 
        option_id: str
    ) -> bool:
        """Vote on a poll option"""
        try:
            post = await Post.get(ObjectId(post_id))
            if not post or post.post_type != PostType.POLL:
                return False
            
            # Check if poll has ended
            if post.poll_ends_at and datetime.utcnow() > post.poll_ends_at:
                return False
            
            # Remove previous vote if any
            for opt in post.poll_options:
                if user_id in opt.votes:
                    opt.votes.remove(user_id)
            
            # Add vote to selected option
            for opt in post.poll_options:
                if opt.id == option_id:
                    opt.votes.append(user_id)
                    break
            
            await post.save()
            return True
        except Exception:
            return False
    
    # Comments
    async def create_comment(
        self,
        post_id: str,
        user_id: str,
        user_name: str,
        avatar_url: Optional[str],
        request: CreateCommentRequest
    ) -> Optional[CommentResponse]:
        """Create a comment on a post"""
        try:
            post = await Post.get(ObjectId(post_id))
            if not post or not post.is_active:
                return None
            
            comment = Comment(
                post_id=post_id,
                parent_id=request.parent_id,
                content=request.content,
                author_id=user_id,
                author_name=user_name,
                author_avatar=avatar_url,
            )
            
            await comment.insert()
            
            return CommentResponse(
                id=str(comment.id),
                post_id=comment.post_id,
                parent_id=comment.parent_id,
                content=comment.content,
                author_id=comment.author_id,
                author_name=comment.author_name,
                author_avatar=comment.author_avatar,
                like_count=0,
                user_has_liked=False,
                created_at=comment.created_at,
            )
        except Exception:
            return None
    
    async def list_comments(
        self,
        post_id: str,
        user_id: Optional[str] = None,
        page: int = 1,
        page_size: int = 50
    ) -> List[CommentResponse]:
        """List comments for a post"""
        skip = (page - 1) * page_size
        comments = await Comment.find(
            Comment.post_id == post_id,
            Comment.is_active == True
        ).sort(Comment.created_at).skip(skip).limit(page_size).to_list()
        
        return [
            CommentResponse(
                id=str(c.id),
                post_id=c.post_id,
                parent_id=c.parent_id,
                content=c.content,
                author_id=c.author_id,
                author_name=c.author_name,
                author_avatar=c.author_avatar,
                like_count=len(c.likes),
                user_has_liked=user_id in c.likes if user_id else False,
                created_at=c.created_at,
            )
            for c in comments
        ]
    
    async def like_comment(self, comment_id: str, user_id: str) -> bool:
        """Toggle like on comment"""
        try:
            comment = await Comment.get(ObjectId(comment_id))
            if not comment:
                return False
            
            if user_id in comment.likes:
                comment.likes.remove(user_id)
            else:
                comment.likes.append(user_id)
            
            await comment.save()
            return True
        except Exception:
            return False
    
    async def delete_comment(self, comment_id: str, user_id: str) -> bool:
        """Delete comment (soft delete)"""
        try:
            comment = await Comment.get(ObjectId(comment_id))
            if not comment or comment.author_id != user_id:
                return False
            
            comment.is_active = False
            await comment.save()
            return True
        except Exception:
            return False
    
    # Follow system
    async def follow_user(self, user_id: str, target_user_id: str) -> bool:
        """Follow a user"""
        try:
            if user_id == target_user_id:
                return False
            
            user = await User.get(ObjectId(user_id))
            target = await User.get(ObjectId(target_user_id))
            
            if not user or not target:
                return False
            
            if target_user_id not in user.following:
                user.following.append(target_user_id)
                await user.save()
            
            if user_id not in target.followers:
                target.followers.append(user_id)
                await target.save()
            
            return True
        except Exception:
            return False
    
    async def unfollow_user(self, user_id: str, target_user_id: str) -> bool:
        """Unfollow a user"""
        try:
            user = await User.get(ObjectId(user_id))
            target = await User.get(ObjectId(target_user_id))
            
            if not user or not target:
                return False
            
            if target_user_id in user.following:
                user.following.remove(target_user_id)
                await user.save()
            
            if user_id in target.followers:
                target.followers.remove(user_id)
                await target.save()
            
            return True
        except Exception:
            return False
    
    async def get_followers(
        self, 
        user_id: str, 
        page: int = 1, 
        page_size: int = 20
    ) -> FollowListResponse:
        """Get user's followers"""
        user = await User.get(ObjectId(user_id))
        if not user:
            return FollowListResponse(users=[], total=0, page=page, page_size=page_size)
        
        total = len(user.followers)
        start = (page - 1) * page_size
        end = start + page_size
        follower_ids = user.followers[start:end]
        
        followers = []
        for fid in follower_ids:
            try:
                f = await User.get(ObjectId(fid))
                if f:
                    followers.append(UserFollowResponse(
                        id=str(f.id),
                        username=f.username,
                        full_name=f.full_name,
                        avatar_url=f.profile.avatar_url if f.profile else None,
                        is_following=str(f.id) in user.following,
                    ))
            except Exception:
                continue
        
        return FollowListResponse(
            users=followers,
            total=total,
            page=page,
            page_size=page_size,
        )
    
    async def get_following(
        self, 
        user_id: str, 
        page: int = 1, 
        page_size: int = 20
    ) -> FollowListResponse:
        """Get users that user is following"""
        user = await User.get(ObjectId(user_id))
        if not user:
            return FollowListResponse(users=[], total=0, page=page, page_size=page_size)
        
        total = len(user.following)
        start = (page - 1) * page_size
        end = start + page_size
        following_ids = user.following[start:end]
        
        following = []
        for fid in following_ids:
            try:
                f = await User.get(ObjectId(fid))
                if f:
                    following.append(UserFollowResponse(
                        id=str(f.id),
                        username=f.username,
                        full_name=f.full_name,
                        avatar_url=f.profile.avatar_url if f.profile else None,
                        is_following=True,
                    ))
            except Exception:
                continue
        
        return FollowListResponse(
            users=following,
            total=total,
            page=page,
            page_size=page_size,
        )
    
    def _post_to_response(
        self, 
        post: Post, 
        comment_count: int = 0
    ) -> PostResponse:
        """Convert Post to response schema"""
        return PostResponse(
            id=str(post.id),
            content=post.content,
            post_type=post.post_type,
            images=post.images,
            location=post.location,
            author_id=post.author_id,
            author_name=post.author_name,
            author_avatar=post.author_avatar,
            like_count=len(post.likes),
            comment_count=comment_count,
            shares=post.shares,
            visibility=post.visibility,
            tags=post.tags,
            is_pinned=post.is_pinned,
            user_has_liked=False,
            created_at=post.created_at,
            updated_at=post.updated_at,
        )


# Singleton instance
community_service = CommunityService()
