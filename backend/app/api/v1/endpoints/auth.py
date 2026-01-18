"""
Authentication API endpoints
"""
from fastapi import APIRouter, HTTPException, status

from app.schemas.user import (
    UserRegisterRequest,
    UserLoginRequest,
    FirebaseAuthRequest,
    AuthResponse,
    MessageResponse,
)
from app.services.auth.auth_service import auth_service

router = APIRouter(prefix="/auth", tags=["Authentication"])


@router.post("/register", response_model=AuthResponse)
async def register(request: UserRegisterRequest):
    """
    Register a new citizen user.
    
    - Only citizens can register via this endpoint
    - Admin accounts cannot be created via signup
    """
    try:
        return await auth_service.register_user(request)
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )


@router.post("/login", response_model=AuthResponse)
async def login(request: UserLoginRequest):
    """
    Login with email and password.
    """
    try:
        return await auth_service.login_user(request)
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=str(e)
        )


@router.post("/admin/login", response_model=AuthResponse)
async def admin_login(request: UserLoginRequest):
    """
    Login for admin users only.
    
    - Admin accounts cannot be created via signup
    - Only existing admin accounts can login
    """
    try:
        return await auth_service.admin_login(request)
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=str(e)
        )


@router.post("/firebase", response_model=AuthResponse)
async def firebase_auth(request: FirebaseAuthRequest):
    """
    Authenticate or register via Firebase (Google/Social login).
    
    - Creates new user if not exists
    - Links Firebase UID to existing user if email matches
    """
    try:
        return await auth_service.firebase_auth(request)
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=str(e)
        )


@router.post("/verify-token", response_model=MessageResponse)
async def verify_token():
    """
    Verify if the current token is valid.
    
    This endpoint requires authentication.
    """
    # Token verification is handled by the dependency
    return MessageResponse(message="Token is valid")
