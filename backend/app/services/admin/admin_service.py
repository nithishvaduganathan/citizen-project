"""
Admin and authority management service
"""
from datetime import datetime
from typing import List, Optional, Dict, Any
from bson import ObjectId

from app.db.models.user import User, UserRole, AuthorityType
from app.db.models.complaint import Complaint, ComplaintStatus
from app.db.models.community import Post
from app.schemas.user import UserResponse, UserListResponse, UserProfileSchema
from app.schemas.complaint import ComplaintStatsResponse


class AdminService:
    """Admin and authority management service"""
    
    # User Management
    async def list_users(
        self,
        page: int = 1,
        page_size: int = 20,
        role: Optional[UserRole] = None,
        is_active: Optional[bool] = None,
    ) -> UserListResponse:
        """List all users with filters"""
        query = {}
        
        if role:
            query["role"] = role.value
        if is_active is not None:
            query["is_active"] = is_active
        
        total = await User.find(query).count()
        
        skip = (page - 1) * page_size
        users = await User.find(query).sort(
            -User.created_at
        ).skip(skip).limit(page_size).to_list()
        
        return UserListResponse(
            users=[self._user_to_response(u) for u in users],
            total=total,
            page=page,
            page_size=page_size,
        )
    
    async def get_user(self, user_id: str) -> Optional[UserResponse]:
        """Get user by ID"""
        try:
            user = await User.get(ObjectId(user_id))
            if user:
                return self._user_to_response(user)
            return None
        except Exception:
            return None
    
    async def update_user_role(
        self,
        user_id: str,
        new_role: UserRole,
        authority_type: Optional[AuthorityType] = None,
        department: Optional[str] = None,
        jurisdiction: Optional[str] = None,
    ) -> Optional[UserResponse]:
        """Update user role (admin only)"""
        try:
            user = await User.get(ObjectId(user_id))
            if not user:
                return None
            
            user.role = new_role
            
            if new_role == UserRole.AUTHORITY:
                user.authority_type = authority_type
                user.authority_department = department
                user.authority_jurisdiction = jurisdiction
            
            user.updated_at = datetime.utcnow()
            await user.save()
            
            return self._user_to_response(user)
        except Exception:
            return None
    
    async def verify_authority(self, user_id: str, verified: bool) -> bool:
        """Verify or unverify an authority account"""
        try:
            user = await User.get(ObjectId(user_id))
            if not user or user.role != UserRole.AUTHORITY:
                return False
            
            user.authority_verified = verified
            user.updated_at = datetime.utcnow()
            await user.save()
            
            return True
        except Exception:
            return False
    
    async def toggle_user_active(self, user_id: str) -> bool:
        """Activate or deactivate user account"""
        try:
            user = await User.get(ObjectId(user_id))
            if not user:
                return False
            
            user.is_active = not user.is_active
            user.updated_at = datetime.utcnow()
            await user.save()
            
            return True
        except Exception:
            return False
    
    # Dashboard and Statistics
    async def get_dashboard_stats(self) -> Dict[str, Any]:
        """Get dashboard statistics"""
        # User stats
        total_users = await User.find().count()
        citizens = await User.find(User.role == UserRole.CITIZEN).count()
        authorities = await User.find(User.role == UserRole.AUTHORITY).count()
        verified_authorities = await User.find(
            User.role == UserRole.AUTHORITY,
            User.authority_verified == True
        ).count()
        
        # Complaint stats
        total_complaints = await Complaint.find().count()
        pending = await Complaint.find(
            Complaint.status == ComplaintStatus.PENDING
        ).count()
        in_progress = await Complaint.find(
            Complaint.status == ComplaintStatus.IN_PROGRESS
        ).count()
        resolved = await Complaint.find(
            Complaint.status == ComplaintStatus.RESOLVED
        ).count()
        
        # Post stats
        total_posts = await Post.find().count()
        
        return {
            "users": {
                "total": total_users,
                "citizens": citizens,
                "authorities": authorities,
                "verified_authorities": verified_authorities,
            },
            "complaints": {
                "total": total_complaints,
                "pending": pending,
                "in_progress": in_progress,
                "resolved": resolved,
            },
            "community": {
                "total_posts": total_posts,
            }
        }
    
    async def get_complaint_heatmap_data(self) -> List[Dict[str, Any]]:
        """Get complaint data for heatmap visualization"""
        pipeline = [
            {"$match": {"is_public": True}},
            {
                "$group": {
                    "_id": {
                        "lat": {"$round": [{"$arrayElemAt": ["$location.geo.coordinates", 1]}, 2]},
                        "lng": {"$round": [{"$arrayElemAt": ["$location.geo.coordinates", 0]}, 2]},
                    },
                    "count": {"$sum": 1},
                    "categories": {"$push": "$category"},
                }
            },
            {"$limit": 1000}
        ]
        
        result = await Complaint.aggregate(pipeline).to_list()
        
        return [
            {
                "latitude": item["_id"]["lat"],
                "longitude": item["_id"]["lng"],
                "count": item["count"],
                "categories": list(set(item["categories"])),
            }
            for item in result
        ]
    
    async def get_authority_complaints(
        self,
        authority_type: str,
        page: int = 1,
        page_size: int = 20,
        status: Optional[ComplaintStatus] = None,
    ) -> Dict[str, Any]:
        """Get complaints assigned to or mentioning an authority type"""
        query = {
            "mentioned_authorities.authority_type": authority_type
        }
        
        if status:
            query["status"] = status.value
        
        total = await Complaint.find(query).count()
        
        skip = (page - 1) * page_size
        complaints = await Complaint.find(query).sort(
            -Complaint.created_at
        ).skip(skip).limit(page_size).to_list()
        
        return {
            "complaints": [
                {
                    "id": str(c.id),
                    "title": c.title,
                    "category": c.category.value,
                    "status": c.status.value,
                    "priority": c.priority.value,
                    "created_at": c.created_at.isoformat(),
                    "upvote_count": len(c.upvotes),
                }
                for c in complaints
            ],
            "total": total,
            "page": page,
            "page_size": page_size,
        }
    
    # Content Moderation
    async def hide_post(self, post_id: str) -> bool:
        """Hide a post (moderation)"""
        try:
            post = await Post.get(ObjectId(post_id))
            if not post:
                return False
            
            post.is_active = False
            await post.save()
            return True
        except Exception:
            return False
    
    async def hide_complaint(self, complaint_id: str) -> bool:
        """Hide a complaint (moderation)"""
        try:
            complaint = await Complaint.get(ObjectId(complaint_id))
            if not complaint:
                return False
            
            complaint.is_public = False
            await complaint.save()
            return True
        except Exception:
            return False
    
    async def list_pending_authority_verifications(
        self,
        page: int = 1,
        page_size: int = 20
    ) -> UserListResponse:
        """List authorities pending verification"""
        query = {
            "role": UserRole.AUTHORITY.value,
            "authority_verified": False,
            "is_active": True,
        }
        
        total = await User.find(query).count()
        
        skip = (page - 1) * page_size
        users = await User.find(query).sort(
            User.created_at
        ).skip(skip).limit(page_size).to_list()
        
        return UserListResponse(
            users=[self._user_to_response(u) for u in users],
            total=total,
            page=page,
            page_size=page_size,
        )
    
    def _user_to_response(self, user: User) -> UserResponse:
        """Convert User model to UserResponse"""
        return UserResponse(
            id=str(user.id),
            email=user.email,
            full_name=user.full_name,
            username=user.username,
            role=user.role,
            profile=UserProfileSchema(
                phone=user.profile.phone if user.profile else None,
                bio=user.profile.bio if user.profile else None,
                avatar_url=user.profile.avatar_url if user.profile else None,
                preferred_language=user.profile.preferred_language if user.profile else "en",
            ),
            is_active=user.is_active,
            is_verified=user.is_verified,
            authority_type=user.authority_type,
            authority_verified=user.authority_verified,
            followers_count=len(user.followers),
            following_count=len(user.following),
            created_at=user.created_at,
        )


# Singleton instance
admin_service = AdminService()
