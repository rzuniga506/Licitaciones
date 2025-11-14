"""
User management endpoints.
"""
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session

from app.core.security import get_current_user, require_admin, require_coordinator
from app.db.session import get_db
from app.models.user import User
from app.schemas.user import UserCreate, UserUpdate, UserResponse, ChangePassword
from app.services.user_service import UserService

router = APIRouter()


@router.get("/me", response_model=UserResponse)
async def get_current_user_info(
    current_user: User = Depends(get_current_user)
):
    """
    Get current authenticated user information.

    Args:
        current_user: Current authenticated user

    Returns:
        User information
    """
    return current_user


@router.get("/", response_model=List[UserResponse])
async def get_users(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=100),
    role: Optional[str] = None,
    is_active: Optional[bool] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_coordinator)
):
    """
    Get list of users (requires coordinator or admin role).

    Args:
        skip: Number of records to skip
        limit: Maximum number of records to return
        role: Filter by role
        is_active: Filter by active status
        db: Database session
        current_user: Current authenticated user

    Returns:
        List of users
    """
    users = UserService.get_users(
        db,
        skip=skip,
        limit=limit,
        role=role,
        is_active=is_active
    )
    return users


@router.get("/{user_id}", response_model=UserResponse)
async def get_user(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_coordinator)
):
    """
    Get user by ID (requires coordinator or admin role).

    Args:
        user_id: User ID
        db: Database session
        current_user: Current authenticated user

    Returns:
        User information

    Raises:
        HTTPException: If user not found
    """
    user = UserService.get_user_by_id(db, user_id)

    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )

    return user


@router.post("/", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def create_user(
    user_data: UserCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin)
):
    """
    Create new user (requires admin role).

    Args:
        user_data: User creation data
        db: Database session
        current_user: Current authenticated user

    Returns:
        Created user

    Raises:
        HTTPException: If email or username already exists
    """
    user = UserService.create_user(db, user_data)
    return user


@router.put("/{user_id}", response_model=UserResponse)
async def update_user(
    user_id: int,
    user_data: UserUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Update user information.

    Users can update their own information.
    Admins can update any user.
    Role changes require admin permissions.

    Args:
        user_id: User ID to update
        user_data: Update data
        db: Database session
        current_user: Current authenticated user

    Returns:
        Updated user

    Raises:
        HTTPException: If user not found or insufficient permissions
    """
    # Check permissions
    if current_user.user_id != user_id and current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not enough permissions"
        )

    # Only admins can change roles
    if user_data.role is not None and current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only admins can change user roles"
        )

    user = UserService.update_user(db, user_id, user_data)
    return user


@router.delete("/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_user(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin)
):
    """
    Delete user (soft delete, requires admin role).

    Args:
        user_id: User ID to delete
        db: Database session
        current_user: Current authenticated user

    Raises:
        HTTPException: If user not found or trying to delete self
    """
    if current_user.user_id == user_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot delete yourself"
        )

    UserService.delete_user(db, user_id)
    return None


@router.post("/change-password", status_code=status.HTTP_200_OK)
async def change_password(
    password_data: ChangePassword,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Change current user's password.

    Args:
        password_data: Current and new password
        db: Database session
        current_user: Current authenticated user

    Returns:
        Success message

    Raises:
        HTTPException: If current password is incorrect
    """
    UserService.change_password(
        db,
        current_user.user_id,
        password_data.current_password,
        password_data.new_password
    )

    return {"message": "Password changed successfully"}
