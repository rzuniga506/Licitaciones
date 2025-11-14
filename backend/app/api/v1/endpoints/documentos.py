"""
Documentos endpoints for file and document management.
"""
from typing import Optional, List
from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File, Query
from fastapi.responses import FileResponse
from sqlalchemy.orm import Session
from datetime import date
import os
import shutil
from pathlib import Path

from app.core.security import get_current_user, check_permission
from app.db.session import get_db
from app.models.user import User
from app.schemas.documento import (
    DocumentoCreate,
    DocumentoUpdate,
    DocumentoResponse,
    DocumentoList
)
from app.services.documento_service import DocumentoService

router = APIRouter()

# Configure upload directory
UPLOAD_DIR = Path("uploads/documentos")
UPLOAD_DIR.mkdir(parents=True, exist_ok=True)


@router.get("/", response_model=DocumentoList)
async def get_documentos(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    licitacion_id: Optional[int] = Query(None, gt=0),
    tipo_documento: Optional[str] = None,
    estado_documento: Optional[str] = None,
    vencimiento_desde: Optional[date] = None,
    vencimiento_hasta: Optional[date] = None,
    search: Optional[str] = None,
    tags: Optional[str] = Query(None, description="Comma-separated tags"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get list of documentos with advanced filters and pagination.

    Filters:
    - licitacion_id: Filter by licitacion
    - tipo_documento: Filter by document type
    - estado_documento: Filter by estado (activo, vencido, archivado, etc.)
    - vencimiento_desde/hasta: Filter by expiration date range
    - search: Search in nombre, descripcion, and filename
    - tags: Comma-separated list of tags to filter by

    Returns paginated list of documentos.
    """
    # Parse tags if provided
    tags_list = tags.split(",") if tags else None

    return DocumentoService.get_documentos_paginated(
        db=db,
        page=page,
        page_size=page_size,
        licitacion_id=licitacion_id,
        tipo_documento=tipo_documento,
        estado_documento=estado_documento,
        vencimiento_desde=vencimiento_desde,
        vencimiento_hasta=vencimiento_hasta,
        search=search,
        tags=tags_list
    )


@router.get("/venciendo", response_model=List[DocumentoResponse])
async def get_documentos_venciendo(
    dias: int = Query(15, ge=1, le=90, description="Days until expiration"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get documentos expiring in the next X days.

    Args:
        dias: Number of days to look ahead (default: 15, max: 90)

    Returns:
        List of documentos expiring soon, ordered by expiration date
    """
    documentos = DocumentoService.get_documentos_venciendo(db, dias)
    return [DocumentoResponse.model_validate(doc) for doc in documentos]


@router.get("/vencidos", response_model=List[DocumentoResponse])
async def get_documentos_vencidos(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get all expired documentos.

    Returns:
        List of expired documentos, ordered by expiration date (most recent first)
    """
    documentos = DocumentoService.get_documentos_vencidos(db)
    return [DocumentoResponse.model_validate(doc) for doc in documentos]


@router.get("/{documento_id}", response_model=DocumentoResponse)
async def get_documento(
    documento_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get documento by ID."""
    documento = DocumentoService.get_documento_by_id(db, documento_id)
    if not documento:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Documento not found"
        )
    return DocumentoResponse.model_validate(documento)


@router.get("/{documento_id}/versions", response_model=List[DocumentoResponse])
async def get_documento_versions(
    documento_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get all versions of a documento.

    Returns complete version history ordered by version number.
    """
    versions = DocumentoService.get_version_history(db, documento_id)
    return [DocumentoResponse.model_validate(doc) for doc in versions]


@router.post("/", response_model=DocumentoResponse, status_code=status.HTTP_201_CREATED)
async def create_documento(
    documento: DocumentoCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(check_permission(["admin", "coordinator", "analyst"]))
):
    """
    Create new documento metadata (without file upload).

    For file uploads, use POST /documentos/upload endpoint.

    Requires: analyst role or higher
    """
    db_documento = DocumentoService.create_documento(
        db=db,
        documento=documento,
        user_id=current_user.user_id
    )
    return DocumentoResponse.model_validate(db_documento)


@router.post("/upload", response_model=DocumentoResponse, status_code=status.HTTP_201_CREATED)
async def upload_documento(
    licitacion_id: int,
    nombre_documento: str,
    tipo_documento: str,
    file: UploadFile = File(...),
    descripcion: Optional[str] = None,
    fecha_vencimiento: Optional[date] = None,
    es_confidencial: bool = False,
    tags: Optional[str] = Query(None, description="Comma-separated tags"),
    db: Session = Depends(get_db),
    current_user: User = Depends(check_permission(["admin", "coordinator", "analyst"]))
):
    """
    Upload a new documento with file.

    Args:
        licitacion_id: ID of the licitacion
        nombre_documento: Display name for the documento
        tipo_documento: Type of documento
        file: The file to upload
        descripcion: Optional description
        fecha_vencimiento: Optional expiration date
        es_confidencial: Whether document is confidential
        tags: Comma-separated tags

    Returns:
        Created Documento with file metadata

    Requires: analyst role or higher
    """
    # Validate file
    if not file.filename:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No file provided"
        )

    # Get file extension
    file_extension = os.path.splitext(file.filename)[1].lower()

    # Generate unique filename
    from datetime import datetime
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    stored_filename = f"{licitacion_id}_{timestamp}_{file.filename}"
    file_path = UPLOAD_DIR / stored_filename

    # Save file
    try:
        with file_path.open("wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error saving file: {str(e)}"
        )

    # Calculate file hash
    try:
        file_hash = DocumentoService.calculate_file_hash(str(file_path))
    except Exception as e:
        # Clean up file if hash calculation fails
        file_path.unlink(missing_ok=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error calculating file hash: {str(e)}"
        )

    # Get file size
    file_size = file_path.stat().st_size

    # Parse tags
    tags_list = tags.split(",") if tags else None

    # Create documento record
    documento_data = DocumentoCreate(
        licitacion_id=licitacion_id,
        nombre_documento=nombre_documento,
        descripcion=descripcion,
        tipo_documento=tipo_documento,
        nombre_archivo_original=file.filename,
        ruta_almacenamiento=str(UPLOAD_DIR),
        tamano_bytes=file_size,
        extension_archivo=file_extension,
        fecha_vencimiento=fecha_vencimiento,
        es_confidencial=es_confidencial,
        tags=tags_list
    )

    try:
        db_documento = DocumentoService.create_documento(
            db=db,
            documento=documento_data,
            user_id=current_user.user_id,
            file_path=stored_filename,
            file_hash=file_hash
        )
        return DocumentoResponse.model_validate(db_documento)
    except Exception as e:
        # Clean up file if database operation fails
        file_path.unlink(missing_ok=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error creating documento record: {str(e)}"
        )


@router.post("/{documento_id}/new-version", response_model=DocumentoResponse)
async def upload_new_version(
    documento_id: int,
    file: UploadFile = File(...),
    descripcion: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(check_permission(["admin", "coordinator", "analyst"]))
):
    """
    Upload a new version of an existing documento.

    Creates a new documento record linked to the original, with incremented version number.

    Requires: analyst role or higher
    """
    # Verify original documento exists
    original = DocumentoService.get_documento_by_id(db, documento_id)
    if not original:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Original documento not found"
        )

    # Validate file
    if not file.filename:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No file provided"
        )

    # Generate unique filename for new version
    from datetime import datetime
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    version_number = original.version + 1
    stored_filename = f"{original.licitacion_id}_{timestamp}_v{version_number}_{file.filename}"
    file_path = UPLOAD_DIR / stored_filename

    # Save file
    try:
        with file_path.open("wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error saving file: {str(e)}"
        )

    # Calculate file hash
    try:
        file_hash = DocumentoService.calculate_file_hash(str(file_path))
    except Exception as e:
        file_path.unlink(missing_ok=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error calculating file hash: {str(e)}"
        )

    try:
        new_version = DocumentoService.create_new_version(
            db=db,
            documento_id=documento_id,
            new_file_path=stored_filename,
            file_hash=file_hash,
            user_id=current_user.user_id,
            descripcion=descripcion
        )
        return DocumentoResponse.model_validate(new_version)
    except Exception as e:
        file_path.unlink(missing_ok=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error creating new version: {str(e)}"
        )


@router.get("/{documento_id}/download")
async def download_documento(
    documento_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Download documento file.

    Returns the actual file for download.
    """
    documento = DocumentoService.get_documento_by_id(db, documento_id)
    if not documento:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Documento not found"
        )

    if not documento.nombre_archivo_almacenado:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="File not found for this documento"
        )

    file_path = UPLOAD_DIR / documento.nombre_archivo_almacenado

    if not file_path.exists():
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="File not found on server"
        )

    # Return file with original filename
    return FileResponse(
        path=str(file_path),
        filename=documento.nombre_archivo_original or documento.nombre_documento,
        media_type="application/octet-stream"
    )


@router.put("/{documento_id}", response_model=DocumentoResponse)
async def update_documento(
    documento_id: int,
    documento_update: DocumentoUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(check_permission(["admin", "coordinator", "analyst"]))
):
    """
    Update documento metadata.

    Note: This does not update the file. To update the file, create a new version.

    Requires: analyst role or higher
    """
    db_documento = DocumentoService.update_documento(
        db=db,
        documento_id=documento_id,
        documento_update=documento_update,
        user_id=current_user.user_id
    )

    if not db_documento:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Documento not found"
        )

    return DocumentoResponse.model_validate(db_documento)


@router.delete("/{documento_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_documento(
    documento_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(check_permission(["admin", "coordinator"]))
):
    """
    Delete documento (soft delete).

    Note: This does not delete the physical file, only marks it as deleted in the database.

    Requires: coordinator role or higher
    """
    success = DocumentoService.delete_documento(
        db=db,
        documento_id=documento_id,
        user_id=current_user.user_id
    )

    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Documento not found"
        )

    return None
