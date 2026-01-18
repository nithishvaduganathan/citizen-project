"""
Citizen Civic AI - FastAPI Main Application
"""
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
import os

from app.core.config import settings
from app.db.mongodb import connect_to_mongo, close_mongo_connection
from app.api.v1.router import api_router


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan - startup and shutdown events"""
    # Startup
    await connect_to_mongo()
    
    # Create upload directory if not exists
    os.makedirs(settings.UPLOAD_DIRECTORY, exist_ok=True)
    
    yield
    
    # Shutdown
    await close_mongo_connection()


# Create FastAPI application
app = FastAPI(
    title=settings.APP_NAME,
    description="""
    Citizen Civic AI - A comprehensive civic engagement platform for Indian citizens.
    
    ## Features
    
    - **Authentication**: Firebase + Email/Password authentication with role-based access
    - **AI Chatbot**: RAG-powered chatbot trained on Indian Constitution and laws
    - **Complaint Reporting**: Report civic issues with images and GPS location
    - **Community**: Social features for civic discussions and updates
    - **Admin Panel**: Dashboard for authorities to manage complaints and users
    
    ## Roles
    
    - **Citizen**: Default role for registered users
    - **Authority**: Government officials who can manage complaints
    - **Admin**: Full system access (login-only, no signup)
    
    ## Languages
    
    Supports English, Tamil (தமிழ்), and Hindi (हिन्दी)
    """,
    version=settings.APP_VERSION,
    docs_url="/docs",
    redoc_url="/redoc",
    lifespan=lifespan,
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include API router
app.include_router(api_router, prefix=settings.API_V1_PREFIX)


# Health check endpoint
@app.get("/health", tags=["Health"])
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "app": settings.APP_NAME,
        "version": settings.APP_VERSION,
    }


# Root endpoint
@app.get("/", tags=["Root"])
async def root():
    """Root endpoint with API information"""
    return {
        "app": settings.APP_NAME,
        "version": settings.APP_VERSION,
        "docs": "/docs",
        "redoc": "/redoc",
        "api_prefix": settings.API_V1_PREFIX,
    }
