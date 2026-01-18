"""
Complaint reporting service
"""
from datetime import datetime
from typing import List, Optional
from bson import ObjectId
import uuid

from app.db.models.complaint import (
    Complaint, 
    ComplaintStatus, 
    GeoLocation,
    ComplaintLocation,
    ComplaintComment,
    AuthorityMention,
    StatusUpdate,
)
from app.db.models.user import User
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
    ComplaintImageSchema,
    AuthorityMentionSchema,
    StatusUpdateResponse,
)


class ComplaintService:
    """Complaint management service"""
    
    async def create_complaint(
        self,
        user_id: str,
        user_name: str,
        request: CreateComplaintRequest,
        image_urls: List[str] = None
    ) -> ComplaintResponse:
        """Create a new complaint"""
        # Parse mentioned authorities
        mentioned_authorities = []
        for mention in request.mentioned_authorities:
            authority_type = mention.replace("@", "").lower()
            mentioned_authorities.append(
                AuthorityMention(authority_type=authority_type)
            )
        
        # Create complaint
        complaint = Complaint(
            title=request.title,
            description=request.description,
            category=request.category,
            location=ComplaintLocation(
                geo=GeoLocation(
                    coordinates=[request.location.longitude, request.location.latitude]
                ),
                address=request.location.address,
                landmark=request.location.landmark,
                city=request.location.city,
                state=request.location.state,
                pincode=request.location.pincode,
            ),
            images=[
                {"url": url, "is_primary": i == 0}
                for i, url in enumerate(image_urls or [])
            ],
            mentioned_authorities=mentioned_authorities,
            reporter_id=user_id,
            reporter_name=user_name,
            is_public=request.is_public,
            status_history=[
                StatusUpdate(
                    status=ComplaintStatus.PENDING,
                    updated_by=user_id,
                    notes="Complaint created"
                )
            ]
        )
        
        await complaint.insert()
        
        return self._complaint_to_response(complaint)
    
    async def get_complaint(
        self, 
        complaint_id: str, 
        user_id: Optional[str] = None
    ) -> Optional[ComplaintDetailResponse]:
        """Get complaint by ID"""
        try:
            complaint = await Complaint.get(ObjectId(complaint_id))
            if not complaint:
                return None
            
            user_has_upvoted = user_id in complaint.upvotes if user_id else False
            
            return ComplaintDetailResponse(
                **self._complaint_to_response(complaint).model_dump(),
                comments=[
                    CommentResponse(
                        id=c.id,
                        user_id=c.user_id,
                        user_name=c.user_name,
                        content=c.content,
                        created_at=c.created_at,
                    )
                    for c in complaint.comments
                ],
                status_history=[
                    StatusUpdateResponse(
                        status=s.status,
                        updated_by=s.updated_by,
                        updated_at=s.updated_at,
                        notes=s.notes,
                    )
                    for s in complaint.status_history
                ],
                user_has_upvoted=user_has_upvoted,
            )
        except Exception:
            return None
    
    async def list_complaints(
        self,
        page: int = 1,
        page_size: int = 20,
        category: Optional[str] = None,
        status: Optional[str] = None,
        user_id: Optional[str] = None,
    ) -> ComplaintListResponse:
        """List complaints with filters"""
        # Build query
        query = {"is_public": True}
        
        if category:
            query["category"] = category
        if status:
            query["status"] = status
        if user_id:
            query["reporter_id"] = user_id
        
        # Get total count
        total = await Complaint.find(query).count()
        
        # Get paginated results
        skip = (page - 1) * page_size
        complaints = await Complaint.find(query).sort(
            -Complaint.created_at
        ).skip(skip).limit(page_size).to_list()
        
        return ComplaintListResponse(
            complaints=[self._complaint_to_response(c) for c in complaints],
            total=total,
            page=page,
            page_size=page_size,
        )
    
    async def list_nearby_complaints(
        self,
        latitude: float,
        longitude: float,
        radius_km: float = 10.0,
        page: int = 1,
        page_size: int = 20,
    ) -> ComplaintListResponse:
        """List complaints near a location"""
        # MongoDB geospatial query
        # Convert km to radians (Earth radius ≈ 6371 km)
        radius_radians = radius_km / 6371
        
        query = {
            "is_public": True,
            "location.geo": {
                "$geoWithin": {
                    "$centerSphere": [[longitude, latitude], radius_radians]
                }
            }
        }
        
        total = await Complaint.find_many(query).count()
        
        skip = (page - 1) * page_size
        complaints = await Complaint.find_many(query).sort(
            -Complaint.created_at
        ).skip(skip).limit(page_size).to_list()
        
        return ComplaintListResponse(
            complaints=[self._complaint_to_response(c) for c in complaints],
            total=total,
            page=page,
            page_size=page_size,
        )
    
    async def update_complaint(
        self,
        complaint_id: str,
        user_id: str,
        request: UpdateComplaintRequest
    ) -> Optional[ComplaintResponse]:
        """Update complaint (by reporter only)"""
        try:
            complaint = await Complaint.get(ObjectId(complaint_id))
            if not complaint or complaint.reporter_id != user_id:
                return None
            
            if request.title:
                complaint.title = request.title
            if request.description:
                complaint.description = request.description
            if request.category:
                complaint.category = request.category
            
            complaint.updated_at = datetime.utcnow()
            await complaint.save()
            
            return self._complaint_to_response(complaint)
        except Exception:
            return None
    
    async def update_complaint_status(
        self,
        complaint_id: str,
        authority_id: str,
        request: UpdateComplaintStatusRequest
    ) -> Optional[ComplaintResponse]:
        """Update complaint status (by authority/admin)"""
        try:
            complaint = await Complaint.get(ObjectId(complaint_id))
            if not complaint:
                return None
            
            complaint.status = request.status
            complaint.updated_at = datetime.utcnow()
            
            if request.status == ComplaintStatus.RESOLVED:
                complaint.resolved_at = datetime.utcnow()
            
            # Add to status history
            complaint.status_history.append(
                StatusUpdate(
                    status=request.status,
                    updated_by=authority_id,
                    notes=request.notes,
                )
            )
            
            await complaint.save()
            
            return self._complaint_to_response(complaint)
        except Exception:
            return None
    
    async def upvote_complaint(
        self, 
        complaint_id: str, 
        user_id: str
    ) -> bool:
        """Toggle upvote on complaint"""
        try:
            complaint = await Complaint.get(ObjectId(complaint_id))
            if not complaint:
                return False
            
            if user_id in complaint.upvotes:
                complaint.upvotes.remove(user_id)
            else:
                complaint.upvotes.append(user_id)
            
            await complaint.save()
            return True
        except Exception:
            return False
    
    async def add_comment(
        self,
        complaint_id: str,
        user_id: str,
        user_name: str,
        request: CommentCreateRequest
    ) -> Optional[CommentResponse]:
        """Add comment to complaint"""
        try:
            complaint = await Complaint.get(ObjectId(complaint_id))
            if not complaint:
                return None
            
            comment = ComplaintComment(
                id=str(uuid.uuid4()),
                user_id=user_id,
                user_name=user_name,
                content=request.content,
            )
            
            complaint.comments.append(comment)
            complaint.updated_at = datetime.utcnow()
            await complaint.save()
            
            return CommentResponse(
                id=comment.id,
                user_id=comment.user_id,
                user_name=comment.user_name,
                content=comment.content,
                created_at=comment.created_at,
            )
        except Exception:
            return None
    
    async def get_complaint_stats(self) -> ComplaintStatsResponse:
        """Get complaint statistics"""
        total = await Complaint.find().count()
        pending = await Complaint.find(
            Complaint.status == ComplaintStatus.PENDING
        ).count()
        in_progress = await Complaint.find(
            Complaint.status == ComplaintStatus.IN_PROGRESS
        ).count()
        resolved = await Complaint.find(
            Complaint.status == ComplaintStatus.RESOLVED
        ).count()
        
        # Get by category
        pipeline = [
            {"$group": {"_id": "$category", "count": {"$sum": 1}}}
        ]
        by_category_cursor = await Complaint.aggregate(pipeline).to_list()
        by_category = {item["_id"]: item["count"] for item in by_category_cursor}
        
        return ComplaintStatsResponse(
            total_complaints=total,
            pending=pending,
            in_progress=in_progress,
            resolved=resolved,
            by_category=by_category,
        )
    
    async def delete_complaint(
        self, 
        complaint_id: str, 
        user_id: str
    ) -> bool:
        """Delete complaint (by reporter or admin)"""
        try:
            complaint = await Complaint.get(ObjectId(complaint_id))
            if not complaint:
                return False
            
            # Only reporter or admin can delete
            if complaint.reporter_id != user_id:
                user = await User.get(ObjectId(user_id))
                if not user or not user.is_admin():
                    return False
            
            await complaint.delete()
            return True
        except Exception:
            return False
    
    def _complaint_to_response(self, complaint: Complaint) -> ComplaintResponse:
        """Convert Complaint to response schema"""
        coords = complaint.location.geo.coordinates
        
        return ComplaintResponse(
            id=str(complaint.id),
            title=complaint.title,
            description=complaint.description,
            category=complaint.category,
            location=ComplaintLocationSchema(
                latitude=coords[1],
                longitude=coords[0],
                address=complaint.location.address,
                landmark=complaint.location.landmark,
                city=complaint.location.city,
                state=complaint.location.state,
                pincode=complaint.location.pincode,
            ),
            images=[
                ComplaintImageSchema(
                    url=img.get("url", "") if isinstance(img, dict) else img.url,
                    thumbnail_url=img.get("thumbnail_url") if isinstance(img, dict) else img.thumbnail_url,
                    is_primary=img.get("is_primary", False) if isinstance(img, dict) else img.is_primary,
                )
                for img in complaint.images
            ],
            status=complaint.status,
            priority=complaint.priority,
            mentioned_authorities=[
                AuthorityMentionSchema(
                    authority_type=m.authority_type,
                    user_id=m.user_id,
                )
                for m in complaint.mentioned_authorities
            ],
            assigned_to=complaint.assigned_to,
            reporter_id=complaint.reporter_id,
            reporter_name=complaint.reporter_name,
            upvote_count=len(complaint.upvotes),
            comment_count=len(complaint.comments),
            is_public=complaint.is_public,
            created_at=complaint.created_at,
            updated_at=complaint.updated_at,
            resolved_at=complaint.resolved_at,
        )


# Singleton instance
complaint_service = ComplaintService()
