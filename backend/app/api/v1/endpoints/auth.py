"""
Authentication endpoints.
"""
from datetime import timedelta, datetime
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.security import create_access_token, create_refresh_token, decode_token
from app.db.session import get_db
from app.schemas.user import LoginRequest, Token, RefreshTokenRequest
from app.services.user_service import UserService

router = APIRouter()


@router.post("/login", response_model=Token)
async def login(
    login_data: LoginRequest,
    db: Session = Depends(get_db)
):
    """
    OAuth2 compatible token login.

    Args:
        login_data: Username and password
        db: Database session

    Returns:
        Access token and refresh token

    Raises:
        HTTPException: If credentials are invalid
    """
    user = UserService.authenticate_user(
        db,
        username=login_data.username,
        password=login_data.password
    )

    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # Update last login
    user.last_login = datetime.utcnow()
    db.commit()

    # Create access token
    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={
            "sub": user.user_id,
            "username": user.username,
            "role": user.role
        },
        expires_delta=access_token_expires
    )

    # Create refresh token
    refresh_token = create_refresh_token(
        data={
            "sub": user.user_id,
            "username": user.username
        }
    )

    return {
        "access_token": access_token,
        "refresh_token": refresh_token,
        "token_type": "bearer",
        "expires_in": settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60
    }


@router.post("/refresh", response_model=Token)
async def refresh_token(
    refresh_data: RefreshTokenRequest,
    db: Session = Depends(get_db)
):
    """
    Refresh access token using refresh token.

    Args:
        refresh_data: Refresh token
        db: Database session

    Returns:
        New access token and refresh token

    Raises:
        HTTPException: If refresh token is invalid
    """
    try:
        payload = decode_token(refresh_data.refresh_token)

        # Check if it's a refresh token
        if payload.get("type") != "refresh":
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid refresh token"
            )

        user_id = payload.get("sub")
        username = payload.get("username")

        # Verify user still exists and is active
        user = UserService.get_user_by_id(db, user_id)
        if not user or not user.is_active:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="User not found or inactive"
            )

        # Create new access token
        access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
        access_token = create_access_token(
            data={
                "sub": user.user_id,
                "username": user.username,
                "role": user.role
            },
            expires_delta=access_token_expires
        )

        # Create new refresh token
        new_refresh_token = create_refresh_token(
            data={
                "sub": user.user_id,
                "username": user.username
            }
        )

        return {
            "access_token": access_token,
            "refresh_token": new_refresh_token,
            "token_type": "bearer",
            "expires_in": settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60
        }

    except HTTPException:
        raise
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid refresh token"
        )


@router.post("/logout")
async def logout():
    """
    Logout endpoint (client-side token removal).

    Returns:
        Success message
    """
    # In a stateless JWT system, logout is handled client-side by removing the token
    # For more security, implement a token blacklist using Redis
    return {"message": "Successfully logged out"}
