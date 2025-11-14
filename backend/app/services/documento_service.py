"""
Documento service for business logic.
"""
from typing import Optional, List
from sqlalchemy.orm import Session
from sqlalchemy import func, or_, and_
from datetime import date, timedelta
from math import ceil
import hashlib
import os

from app.models.documento import Documento
from app.schemas.documento import (
    DocumentoCreate,
    DocumentoUpdate,
    DocumentoList,
    DocumentoResponse
)


class DocumentoService:
    """Service for documento operations."""

    @staticmethod
    def get_documentos_paginated(
        db: Session,
        page: int = 1,
        page_size: int = 20,
        licitacion_id: Optional[int] = None,
        tipo_documento: Optional[str] = None,
        estado_documento: Optional[str] = None,
        vencimiento_desde: Optional[date] = None,
        vencimiento_hasta: Optional[date] = None,
        search: Optional[str] = None,
        tags: Optional[List[str]] = None
    ) -> DocumentoList:
        """
        Get paginated list of documentos with filters.

        Args:
            db: Database session
            page: Page number
            page_size: Items per page
            licitacion_id: Filter by licitacion
            tipo_documento: Filter by tipo
            estado_documento: Filter by estado
            vencimiento_desde: Filter documents expiring from this date
            vencimiento_hasta: Filter documents expiring until this date
            search: Search in nombre_documento and descripcion
            tags: Filter by tags (documents containing any of these tags)

        Returns:
            DocumentoList with paginated results
        """
        query = db.query(Documento).filter(Documento.is_deleted == False)

        # Apply filters
        if licitacion_id:
            query = query.filter(Documento.licitacion_id == licitacion_id)

        if tipo_documento:
            query = query.filter(Documento.tipo_documento == tipo_documento)

        if estado_documento:
            query = query.filter(Documento.estado_documento == estado_documento)

        if vencimiento_desde:
            query = query.filter(Documento.fecha_vencimiento >= vencimiento_desde)

        if vencimiento_hasta:
            query = query.filter(Documento.fecha_vencimiento <= vencimiento_hasta)

        if search:
            search_filter = f"%{search}%"
            query = query.filter(
                or_(
                    Documento.nombre_documento.ilike(search_filter),
                    Documento.descripcion.ilike(search_filter),
                    Documento.nombre_archivo_original.ilike(search_filter)
                )
            )

        if tags and len(tags) > 0:
            # Filter documents that contain any of the specified tags
            query = query.filter(Documento.tags.overlap(tags))

        # Get total count
        total = query.count()

        # Calculate pagination
        total_pages = ceil(total / page_size) if total > 0 else 0
        offset = (page - 1) * page_size

        # Get paginated results ordered by creation date
        items = query.order_by(Documento.created_at.desc()).offset(offset).limit(page_size).all()

        return DocumentoList(
            total=total,
            items=[DocumentoResponse.model_validate(item) for item in items],
            page=page,
            page_size=page_size,
            total_pages=total_pages
        )

    @staticmethod
    def get_documento_by_id(db: Session, documento_id: int) -> Optional[Documento]:
        """Get documento by ID."""
        return db.query(Documento).filter(
            Documento.documento_id == documento_id,
            Documento.is_deleted == False
        ).first()

    @staticmethod
    def create_documento(
        db: Session,
        documento: DocumentoCreate,
        user_id: int,
        file_path: Optional[str] = None,
        file_hash: Optional[str] = None
    ) -> Documento:
        """
        Create new documento.

        Args:
            db: Database session
            documento: Documento data
            user_id: ID of user creating the documento
            file_path: Path where file was stored (optional)
            file_hash: SHA256 hash of file (optional)

        Returns:
            Created Documento
        """
        db_documento = Documento(
            **documento.model_dump(exclude_unset=True),
            created_by=user_id
        )

        if file_path:
            db_documento.nombre_archivo_almacenado = file_path

        if file_hash:
            db_documento.hash_archivo = file_hash

        db.add(db_documento)
        db.commit()
        db.refresh(db_documento)
        return db_documento

    @staticmethod
    def update_documento(
        db: Session,
        documento_id: int,
        documento_update: DocumentoUpdate,
        user_id: int
    ) -> Optional[Documento]:
        """Update documento."""
        db_documento = DocumentoService.get_documento_by_id(db, documento_id)
        if not db_documento:
            return None

        update_data = documento_update.model_dump(exclude_unset=True)
        for field, value in update_data.items():
            setattr(db_documento, field, value)

        db_documento.updated_by = user_id
        db.commit()
        db.refresh(db_documento)
        return db_documento

    @staticmethod
    def delete_documento(db: Session, documento_id: int, user_id: int) -> bool:
        """Soft delete documento."""
        db_documento = DocumentoService.get_documento_by_id(db, documento_id)
        if not db_documento:
            return False

        db_documento.is_deleted = True
        db_documento.updated_by = user_id
        db.commit()
        return True

    @staticmethod
    def get_documentos_venciendo(db: Session, dias: int = 15) -> List[Documento]:
        """
        Get documentos expiring in the next X days.

        Args:
            db: Database session
            dias: Number of days to look ahead (default 15, max 90)

        Returns:
            List of documentos expiring soon
        """
        if dias > 90:
            dias = 90

        fecha_limite = date.today() + timedelta(days=dias)

        return db.query(Documento).filter(
            Documento.is_deleted == False,
            Documento.estado_documento == "activo",
            Documento.fecha_vencimiento.isnot(None),
            Documento.fecha_vencimiento <= fecha_limite,
            Documento.fecha_vencimiento >= date.today()
        ).order_by(Documento.fecha_vencimiento).all()

    @staticmethod
    def get_documentos_vencidos(db: Session) -> List[Documento]:
        """Get expired documentos."""
        return db.query(Documento).filter(
            Documento.is_deleted == False,
            Documento.estado_documento == "activo",
            Documento.fecha_vencimiento.isnot(None),
            Documento.fecha_vencimiento < date.today()
        ).order_by(Documento.fecha_vencimiento.desc()).all()

    @staticmethod
    def create_new_version(
        db: Session,
        documento_id: int,
        new_file_path: str,
        file_hash: str,
        user_id: int,
        descripcion: Optional[str] = None
    ) -> Documento:
        """
        Create a new version of an existing documento.

        Args:
            db: Database session
            documento_id: ID of original documento
            new_file_path: Path to new file version
            file_hash: SHA256 hash of new file
            user_id: ID of user creating new version
            descripcion: Optional description of changes

        Returns:
            New Documento version
        """
        original = DocumentoService.get_documento_by_id(db, documento_id)
        if not original:
            raise ValueError("Documento original not found")

        # Create new version
        new_version = Documento(
            licitacion_id=original.licitacion_id,
            nombre_documento=original.nombre_documento,
            descripcion=descripcion or original.descripcion,
            tipo_documento=original.tipo_documento,
            nombre_archivo_original=original.nombre_archivo_original,
            nombre_archivo_almacenado=new_file_path,
            ruta_almacenamiento=original.ruta_almacenamiento,
            tamano_bytes=original.tamano_bytes,
            extension_archivo=original.extension_archivo,
            hash_archivo=file_hash,
            version=original.version + 1,
            version_anterior_id=original.documento_id,
            estado_documento=original.estado_documento,
            fecha_vencimiento=original.fecha_vencimiento,
            es_confidencial=original.es_confidencial,
            tags=original.tags,
            metadata_adicional=original.metadata_adicional,
            created_by=user_id
        )

        db.add(new_version)
        db.commit()
        db.refresh(new_version)
        return new_version

    @staticmethod
    def calculate_file_hash(file_path: str) -> str:
        """Calculate SHA256 hash of a file."""
        sha256_hash = hashlib.sha256()
        with open(file_path, "rb") as f:
            # Read file in chunks to handle large files
            for byte_block in iter(lambda: f.read(4096), b""):
                sha256_hash.update(byte_block)
        return sha256_hash.hexdigest()

    @staticmethod
    def get_version_history(db: Session, documento_id: int) -> List[Documento]:
        """
        Get all versions of a documento.

        Args:
            db: Database session
            documento_id: ID of any version of the documento

        Returns:
            List of all versions ordered by version number
        """
        # First get the documento to find its version chain
        documento = DocumentoService.get_documento_by_id(db, documento_id)
        if not documento:
            return []

        # Find the original (version 1) documento
        # Walk back through version_anterior_id until we find version 1
        original_id = documento_id
        current = documento
        while current.version_anterior_id:
            current = db.query(Documento).filter(
                Documento.documento_id == current.version_anterior_id
            ).first()
            if current:
                original_id = current.documento_id
            else:
                break

        # Now find all documentos that are in this version chain
        # This includes the original and all its descendants
        versions = []

        # Get the original
        original = db.query(Documento).filter(
            Documento.documento_id == original_id
        ).first()

        if original:
            versions.append(original)

            # Recursively get all versions that reference this chain
            # For simplicity, we'll query all documentos with the same nombre_documento
            # and licitacion_id, ordered by version
            all_versions = db.query(Documento).filter(
                Documento.licitacion_id == original.licitacion_id,
                Documento.nombre_documento == original.nombre_documento,
                Documento.is_deleted == False
            ).order_by(Documento.version).all()

            return all_versions

        return []
