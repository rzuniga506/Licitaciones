"""
SQLAlchemy Base and declarative base setup.
"""
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy import Column, DateTime, Boolean, func

Base = declarative_base()


class BaseModel:
    """Base model with common fields for all tables."""

    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)
    is_deleted = Column(Boolean, default=False, nullable=False)  # Soft delete


# Import all models here for Alembic to detect them
from app.models.user import User  # noqa
