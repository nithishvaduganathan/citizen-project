"""
Security utilities for authentication and authorization
"""
from datetime import datetime, timedelta
from typing import Optional, Dict, Any
import secrets
from jose import JWTError, jwt
from passlib.context import CryptContext
from fastapi import HTTPException, status, Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
import firebase_admin
from firebase_admin import credentials, auth as firebase_auth

from app.core.config import settings

# Password hashing context
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# HTTP Bearer scheme for token authentication
security = HTTPBearer()

# Firebase initialization flag
_firebase_initialized = False


def get_secret_key() -> str:
    """Get secret key for JWT encoding.
    
    If SECRET_KEY is not set in environment, generates a random key for development.
    WARNING: In production, always set SECRET_KEY via environment variable.
    """
    if settings.SECRET_KEY:
        return settings.SECRET_KEY
    # Generate a random key for development only
    # This will change on each restart, invalidating existing tokens
    return secrets.token_urlsafe(32)


def init_firebase():
    """Initialize Firebase Admin SDK"""
    global _firebase_initialized
    if _firebase_initialized:
        return
    
    try:
        if settings.FIREBASE_CREDENTIALS_PATH:
            cred = credentials.Certificate(settings.FIREBASE_CREDENTIALS_PATH)
        else:
            cred = credentials.Certificate({
                "type": "service_account",
                "project_id": settings.FIREBASE_PROJECT_ID,
                "private_key": settings.FIREBASE_PRIVATE_KEY.replace("\\n", "\n"),
                "client_email": settings.FIREBASE_CLIENT_EMAIL,
                "token_uri": "https://oauth2.googleapis.com/token",
            })
        firebase_admin.initialize_app(cred)
        _firebase_initialized = True
    except Exception as e:
        print(f"Firebase initialization warning: {e}")
        _firebase_initialized = True  # Continue without Firebase for development


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verify a password against its hash"""
    return pwd_context.verify(plain_password, hashed_password)


def get_password_hash(password: str) -> str:
    """Generate password hash"""
    return pwd_context.hash(password)


def create_access_token(data: Dict[str, Any], expires_delta: Optional[timedelta] = None) -> str:
    """Create a JWT access token"""
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, get_secret_key(), algorithm="HS256")
    return encoded_jwt


def decode_access_token(token: str) -> Optional[Dict[str, Any]]:
    """Decode and verify a JWT access token"""
    try:
        payload = jwt.decode(token, get_secret_key(), algorithms=["HS256"])
        return payload
    except JWTError:
        return None


async def verify_firebase_token(token: str) -> Optional[Dict[str, Any]]:
    """Verify Firebase ID token"""
    try:
        init_firebase()
        decoded_token = firebase_auth.verify_id_token(token)
        return decoded_token
    except Exception as e:
        print(f"Firebase token verification error: {e}")
        return None


async def get_current_user_from_token(
    credentials: HTTPAuthorizationCredentials = Depends(security)
) -> Dict[str, Any]:
    """Extract and verify the current user from JWT token"""
    token = credentials.credentials
    
    # First try to decode as our JWT
    payload = decode_access_token(token)
    if payload:
        return payload
    
    # Then try Firebase token
    firebase_payload = await verify_firebase_token(token)
    if firebase_payload:
        return firebase_payload
    
    raise HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Invalid authentication credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )


def check_admin_role(user: Dict[str, Any]) -> bool:
    """Check if user has admin role"""
    return user.get("role") == "admin"


def check_authority_role(user: Dict[str, Any]) -> bool:
    """Check if user has authority role"""
    return user.get("role") in ["authority", "admin"]
