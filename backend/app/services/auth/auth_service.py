"""
Authentication service for user management
"""
from datetime import datetime
from typing import Optional
from bson import ObjectId

from app.db.models.user import User, UserRole
from app.schemas.user import (
    UserRegisterRequest,
    UserLoginRequest,
    FirebaseAuthRequest,
    UserResponse,
    AuthResponse,
)
from app.core.security import (
    get_password_hash,
    verify_password,
    create_access_token,
    verify_firebase_token,
)


class AuthService:
    """Authentication service"""
    
    async def register_user(self, request: UserRegisterRequest) -> AuthResponse:
        """Register a new user (citizen only)"""
        # Check if email already exists
        existing_user = await User.find_one(User.email == request.email)
        if existing_user:
            raise ValueError("Email already registered")
        
        # Check if username already exists
        existing_username = await User.find_one(User.username == request.username)
        if existing_username:
            raise ValueError("Username already taken")
        
        # Create user
        user = User(
            email=request.email,
            password_hash=get_password_hash(request.password),
            full_name=request.full_name,
            username=request.username,
            role=UserRole.CITIZEN,  # Default role for signup
            profile=request.profile if request.profile else {},
        )
        
        await user.insert()
        
        # Create access token
        token_data = {
            "sub": str(user.id),
            "email": user.email,
            "role": user.role.value,
        }
        access_token = create_access_token(token_data)
        
        return AuthResponse(
            access_token=access_token,
            user=self._user_to_response(user)
        )
    
    async def login_user(self, request: UserLoginRequest) -> AuthResponse:
        """Login user with email and password"""
        user = await User.find_one(User.email == request.email)
        
        if not user or not user.password_hash:
            raise ValueError("Invalid email or password")
        
        if not verify_password(request.password, user.password_hash):
            raise ValueError("Invalid email or password")
        
        if not user.is_active:
            raise ValueError("Account is deactivated")
        
        # Update last login
        user.last_login = datetime.utcnow()
        await user.save()
        
        # Create access token
        token_data = {
            "sub": str(user.id),
            "email": user.email,
            "role": user.role.value,
        }
        access_token = create_access_token(token_data)
        
        return AuthResponse(
            access_token=access_token,
            user=self._user_to_response(user)
        )
    
    async def admin_login(self, request: UserLoginRequest) -> AuthResponse:
        """Login for admin users only (no signup allowed for admin)"""
        user = await User.find_one(User.email == request.email)
        
        if not user or not user.password_hash:
            raise ValueError("Invalid email or password")
        
        if user.role != UserRole.ADMIN:
            raise ValueError("Access denied. Admin only.")
        
        if not verify_password(request.password, user.password_hash):
            raise ValueError("Invalid email or password")
        
        if not user.is_active:
            raise ValueError("Account is deactivated")
        
        # Update last login
        user.last_login = datetime.utcnow()
        await user.save()
        
        # Create access token
        token_data = {
            "sub": str(user.id),
            "email": user.email,
            "role": user.role.value,
        }
        access_token = create_access_token(token_data)
        
        return AuthResponse(
            access_token=access_token,
            user=self._user_to_response(user)
        )
    
    async def firebase_auth(self, request: FirebaseAuthRequest) -> AuthResponse:
        """Authenticate or register user via Firebase"""
        # Verify Firebase token
        firebase_data = await verify_firebase_token(request.firebase_token)
        if not firebase_data:
            raise ValueError("Invalid Firebase token")
        
        firebase_uid = firebase_data.get("uid")
        email = firebase_data.get("email")
        name = firebase_data.get("name") or request.full_name
        
        # Check if user exists
        user = await User.find_one(User.firebase_uid == firebase_uid)
        
        if not user:
            # Check by email
            user = await User.find_one(User.email == email)
            if user:
                # Link Firebase UID to existing user
                user.firebase_uid = firebase_uid
                await user.save()
            else:
                # Create new user
                username = request.username or email.split("@")[0].lower()
                
                # Ensure unique username
                base_username = username
                counter = 1
                while await User.find_one(User.username == username):
                    username = f"{base_username}{counter}"
                    counter += 1
                
                user = User(
                    email=email,
                    firebase_uid=firebase_uid,
                    full_name=name or "User",
                    username=username,
                    role=UserRole.CITIZEN,
                )
                await user.insert()
        
        # Update last login
        user.last_login = datetime.utcnow()
        await user.save()
        
        # Create access token
        token_data = {
            "sub": str(user.id),
            "email": user.email,
            "role": user.role.value,
        }
        access_token = create_access_token(token_data)
        
        return AuthResponse(
            access_token=access_token,
            user=self._user_to_response(user)
        )
    
    async def get_user_by_id(self, user_id: str) -> Optional[User]:
        """Get user by ID"""
        try:
            return await User.get(ObjectId(user_id))
        except Exception:
            return None
    
    async def get_user_by_email(self, email: str) -> Optional[User]:
        """Get user by email"""
        return await User.find_one(User.email == email)
    
    def _user_to_response(self, user: User) -> UserResponse:
        """Convert User model to UserResponse"""
        return UserResponse(
            id=str(user.id),
            email=user.email,
            full_name=user.full_name,
            username=user.username,
            role=user.role,
            profile=user.profile,
            is_active=user.is_active,
            is_verified=user.is_verified,
            authority_type=user.authority_type,
            authority_verified=user.authority_verified,
            followers_count=len(user.followers),
            following_count=len(user.following),
            created_at=user.created_at,
        )


# Singleton instance
auth_service = AuthService()
