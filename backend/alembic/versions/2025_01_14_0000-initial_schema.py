"""Initial schema - all phases

Revision ID: 001_initial_schema
Revises:
Create Date: 2025-01-14 00:00:00.000000

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision = '001_initial_schema'
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    # Create users table
    op.create_table('users',
    sa.Column('user_id', sa.Integer(), nullable=False),
    sa.Column('email', sa.String(length=255), nullable=False),
    sa.Column('username', sa.String(length=100), nullable=False),
    sa.Column('hashed_password', sa.String(length=255), nullable=False),
    sa.Column('full_name', sa.String(length=255), nullable=False),
    sa.Column('role', sa.String(length=50), nullable=False),
    sa.Column('is_active', sa.Boolean(), nullable=False),
    sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
    sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('now()')),
    sa.Column('last_login', sa.DateTime(timezone=True), nullable=True),
    sa.Column('is_deleted', sa.Boolean(), nullable=False),
    sa.PrimaryKeyConstraint('user_id')
    )
    op.create_index(op.f('ix_users_email'), 'users', ['email'], unique=True)
    op.create_index(op.f('ix_users_user_id'), 'users', ['user_id'], unique=False)
    op.create_index(op.f('ix_users_username'), 'users', ['username'], unique=True)

    # Create clientes table
    op.create_table('clientes',
    sa.Column('cliente_id', sa.Integer(), nullable=False),
    sa.Column('nombre_cliente', sa.String(length=255), nullable=False),
    sa.Column('tipo_cliente', sa.String(length=50), nullable=False),
    sa.Column('identificacion', sa.String(length=50), nullable=True),
    sa.Column('telefono', sa.String(length=50), nullable=True),
    sa.Column('email', sa.String(length=255), nullable=True),
    sa.Column('direccion', sa.Text(), nullable=True),
    sa.Column('contacto_principal', sa.String(length=255), nullable=True),
    sa.Column('notas', sa.Text(), nullable=True),
    sa.Column('is_active', sa.Boolean(), nullable=False),
    sa.Column('is_deleted', sa.Boolean(), nullable=False),
    sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
    sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('now()')),
    sa.Column('created_by', sa.Integer(), nullable=True),
    sa.ForeignKeyConstraint(['created_by'], ['users.user_id'], ),
    sa.PrimaryKeyConstraint('cliente_id')
    )
    op.create_index(op.f('ix_clientes_cliente_id'), 'clientes', ['cliente_id'], unique=False)
    op.create_index(op.f('ix_clientes_identificacion'), 'clientes', ['identificacion'], unique=True)
    op.create_index(op.f('ix_clientes_nombre_cliente'), 'clientes', ['nombre_cliente'], unique=False)

    # Create licitaciones table
    op.create_table('licitaciones',
    sa.Column('licitacion_id', sa.Integer(), nullable=False),
    sa.Column('numero_licitacion', sa.String(length=100), nullable=False),
    sa.Column('cliente_id', sa.Integer(), nullable=False),
    sa.Column('nombre_licitacion', sa.String(length=500), nullable=False),
    sa.Column('descripcion', sa.Text(), nullable=True),
    sa.Column('objeto_contrato', sa.Text(), nullable=True),
    sa.Column('monto_ofertado', sa.Numeric(precision=15, scale=2), nullable=True),
    sa.Column('monto_adjudicado', sa.Numeric(precision=15, scale=2), nullable=True),
    sa.Column('moneda', sa.String(length=10), nullable=True),
    sa.Column('estado_licitacion', sa.String(length=50), nullable=False),
    sa.Column('fecha_publicacion', sa.Date(), nullable=True),
    sa.Column('fecha_presentacion', sa.Date(), nullable=True),
    sa.Column('fecha_apertura', sa.Date(), nullable=True),
    sa.Column('fecha_adjudicacion', sa.Date(), nullable=True),
    sa.Column('fecha_inicio_contrato', sa.Date(), nullable=True),
    sa.Column('fecha_fin_contrato', sa.Date(), nullable=True),
    sa.Column('tipo_licitacion', sa.String(length=50), nullable=True),
    sa.Column('categoria', sa.String(length=100), nullable=True),
    sa.Column('prioridad', sa.String(length=20), nullable=True),
    sa.Column('url_portal_compras', sa.Text(), nullable=True),
    sa.Column('numero_expediente', sa.String(length=100), nullable=True),
    sa.Column('monto_garantia_participacion', sa.Numeric(precision=15, scale=2), nullable=True),
    sa.Column('fecha_vence_garantia_participacion', sa.Date(), nullable=True),
    sa.Column('monto_garantia_cumplimiento', sa.Numeric(precision=15, scale=2), nullable=True),
    sa.Column('fecha_vence_garantia_cumplimiento', sa.Date(), nullable=True),
    sa.Column('observaciones', sa.Text(), nullable=True),
    sa.Column('motivo_rechazo', sa.Text(), nullable=True),
    sa.Column('is_active', sa.Boolean(), nullable=False),
    sa.Column('is_deleted', sa.Boolean(), nullable=False),
    sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
    sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('now()')),
    sa.Column('created_by', sa.Integer(), nullable=True),
    sa.Column('updated_by', sa.Integer(), nullable=True),
    sa.ForeignKeyConstraint(['cliente_id'], ['clientes.cliente_id'], ),
    sa.ForeignKeyConstraint(['created_by'], ['users.user_id'], ),
    sa.ForeignKeyConstraint(['updated_by'], ['users.user_id'], ),
    sa.PrimaryKeyConstraint('licitacion_id')
    )
    op.create_index(op.f('ix_licitaciones_categoria'), 'licitaciones', ['categoria'], unique=False)
    op.create_index(op.f('ix_licitaciones_estado_licitacion'), 'licitaciones', ['estado_licitacion'], unique=False)
    op.create_index(op.f('ix_licitaciones_fecha_fin_contrato'), 'licitaciones', ['fecha_fin_contrato'], unique=False)
    op.create_index(op.f('ix_licitaciones_fecha_presentacion'), 'licitaciones', ['fecha_presentacion'], unique=False)
    op.create_index(op.f('ix_licitaciones_licitacion_id'), 'licitaciones', ['licitacion_id'], unique=False)
    op.create_index(op.f('ix_licitaciones_numero_licitacion'), 'licitaciones', ['numero_licitacion'], unique=True)

    # Create documentos table
    op.create_table('documentos',
    sa.Column('documento_id', sa.Integer(), nullable=False),
    sa.Column('licitacion_id', sa.Integer(), nullable=True),
    sa.Column('nombre_documento', sa.String(length=255), nullable=False),
    sa.Column('nombre_archivo_original', sa.String(length=255), nullable=False),
    sa.Column('nombre_archivo_almacenado', sa.String(length=255), nullable=False),
    sa.Column('ruta_archivo', sa.Text(), nullable=False),
    sa.Column('extension', sa.String(length=10), nullable=False),
    sa.Column('tamanio_bytes', sa.BigInteger(), nullable=False),
    sa.Column('mime_type', sa.String(length=100), nullable=True),
    sa.Column('tipo_documento', sa.String(length=100), nullable=False),
    sa.Column('categoria_documento', sa.String(length=100), nullable=True),
    sa.Column('version', sa.Integer(), nullable=True),
    sa.Column('documento_padre_id', sa.Integer(), nullable=True),
    sa.Column('is_ultima_version', sa.Boolean(), nullable=True),
    sa.Column('fecha_emision', sa.Date(), nullable=True),
    sa.Column('fecha_vencimiento', sa.Date(), nullable=True),
    sa.Column('dias_alerta_vencimiento', sa.Integer(), nullable=True),
    sa.Column('estado_documento', sa.String(length=50), nullable=True),
    sa.Column('descripcion', sa.Text(), nullable=True),
    sa.Column('tags', postgresql.ARRAY(sa.String()), nullable=True),
    sa.Column('hash_archivo', sa.String(length=64), nullable=True),
    sa.Column('is_active', sa.Boolean(), nullable=False),
    sa.Column('is_deleted', sa.Boolean(), nullable=False),
    sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
    sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('now()')),
    sa.Column('uploaded_by', sa.Integer(), nullable=True),
    sa.ForeignKeyConstraint(['documento_padre_id'], ['documentos.documento_id'], ),
    sa.ForeignKeyConstraint(['licitacion_id'], ['licitaciones.licitacion_id'], ),
    sa.ForeignKeyConstraint(['uploaded_by'], ['users.user_id'], ),
    sa.PrimaryKeyConstraint('documento_id')
    )
    op.create_index(op.f('ix_documentos_documento_id'), 'documentos', ['documento_id'], unique=False)
    op.create_index(op.f('ix_documentos_estado_documento'), 'documentos', ['estado_documento'], unique=False)
    op.create_index(op.f('ix_documentos_fecha_vencimiento'), 'documentos', ['fecha_vencimiento'], unique=False)
    op.create_index(op.f('ix_documentos_licitacion_id'), 'documentos', ['licitacion_id'], unique=False)
    op.create_index(op.f('ix_documentos_nombre_archivo_almacenado'), 'documentos', ['nombre_archivo_almacenado'], unique=True)
    op.create_index(op.f('ix_documentos_tipo_documento'), 'documentos', ['tipo_documento'], unique=False)

    # Create ampliaciones table
    op.create_table('ampliaciones',
    sa.Column('ampliacion_id', sa.Integer(), nullable=False),
    sa.Column('licitacion_id', sa.Integer(), nullable=False),
    sa.Column('tipo_ampliacion', sa.String(length=50), nullable=False),
    sa.Column('numero_ampliacion', sa.String(length=50), nullable=True),
    sa.Column('titulo', sa.String(length=255), nullable=False),
    sa.Column('descripcion', sa.Text(), nullable=False),
    sa.Column('justificacion', sa.Text(), nullable=True),
    sa.Column('fecha_anterior_fin', sa.Date(), nullable=True),
    sa.Column('fecha_nueva_fin', sa.Date(), nullable=True),
    sa.Column('dias_ampliados', sa.Integer(), nullable=True),
    sa.Column('monto_anterior', sa.Numeric(precision=15, scale=2), nullable=True),
    sa.Column('monto_nuevo', sa.Numeric(precision=15, scale=2), nullable=True),
    sa.Column('monto_ampliado', sa.Numeric(precision=15, scale=2), nullable=True),
    sa.Column('porcentaje_ampliacion', sa.Numeric(precision=5, scale=2), nullable=True),
    sa.Column('fecha_solicitud', sa.Date(), nullable=False),
    sa.Column('fecha_aprobacion', sa.Date(), nullable=True),
    sa.Column('fecha_inicio_vigencia', sa.Date(), nullable=True),
    sa.Column('fecha_fin_vigencia', sa.Date(), nullable=True),
    sa.Column('estado_ampliacion', sa.String(length=50), nullable=True),
    sa.Column('numero_adenda', sa.String(length=100), nullable=True),
    sa.Column('numero_resolucion', sa.String(length=100), nullable=True),
    sa.Column('numero_oficio', sa.String(length=100), nullable=True),
    sa.Column('solicitante_nombre', sa.String(length=255), nullable=True),
    sa.Column('solicitante_cargo', sa.String(length=100), nullable=True),
    sa.Column('aprobador_nombre', sa.String(length=255), nullable=True),
    sa.Column('aprobador_cargo', sa.String(length=100), nullable=True),
    sa.Column('observaciones', sa.Text(), nullable=True),
    sa.Column('motivo_rechazo', sa.Text(), nullable=True),
    sa.Column('impacto_cronograma', sa.Boolean(), nullable=True),
    sa.Column('impacto_presupuesto', sa.Boolean(), nullable=True),
    sa.Column('impacto_alcance', sa.Boolean(), nullable=True),
    sa.Column('is_active', sa.Boolean(), nullable=False),
    sa.Column('is_deleted', sa.Boolean(), nullable=False),
    sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
    sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('now()')),
    sa.Column('created_by', sa.Integer(), nullable=True),
    sa.Column('updated_by', sa.Integer(), nullable=True),
    sa.ForeignKeyConstraint(['created_by'], ['users.user_id'], ),
    sa.ForeignKeyConstraint(['licitacion_id'], ['licitaciones.licitacion_id'], ),
    sa.ForeignKeyConstraint(['updated_by'], ['users.user_id'], ),
    sa.PrimaryKeyConstraint('ampliacion_id')
    )
    op.create_index(op.f('ix_ampliaciones_ampliacion_id'), 'ampliaciones', ['ampliacion_id'], unique=False)
    op.create_index(op.f('ix_ampliaciones_estado_ampliacion'), 'ampliaciones', ['estado_ampliacion'], unique=False)
    op.create_index(op.f('ix_ampliaciones_fecha_solicitud'), 'ampliaciones', ['fecha_solicitud'], unique=False)
    op.create_index(op.f('ix_ampliaciones_licitacion_id'), 'ampliaciones', ['licitacion_id'], unique=False)
    op.create_index(op.f('ix_ampliaciones_tipo_ampliacion'), 'ampliaciones', ['tipo_ampliacion'], unique=False)

    # Create prorrogas table
    op.create_table('prorrogas',
    sa.Column('prorroga_id', sa.Integer(), nullable=False),
    sa.Column('licitacion_id', sa.Integer(), nullable=False),
    sa.Column('numero_prorroga', sa.String(length=50), nullable=True),
    sa.Column('descripcion', sa.Text(), nullable=False),
    sa.Column('fecha_fin_anterior', sa.Date(), nullable=False),
    sa.Column('fecha_fin_nueva', sa.Date(), nullable=False),
    sa.Column('meses_prorrogados', sa.Integer(), nullable=True),
    sa.Column('dias_prorrogados', sa.Integer(), nullable=True),
    sa.Column('fecha_solicitud', sa.Date(), nullable=False),
    sa.Column('fecha_aprobacion', sa.Date(), nullable=True),
    sa.Column('fecha_inicio_vigencia', sa.Date(), nullable=True),
    sa.Column('estado_prorroga', sa.String(length=50), nullable=True),
    sa.Column('numero_resolucion', sa.String(length=100), nullable=True),
    sa.Column('numero_oficio', sa.String(length=100), nullable=True),
    sa.Column('justificacion', sa.Text(), nullable=True),
    sa.Column('observaciones', sa.Text(), nullable=True),
    sa.Column('motivo_rechazo', sa.Text(), nullable=True),
    sa.Column('is_active', sa.Boolean(), nullable=False),
    sa.Column('is_deleted', sa.Boolean(), nullable=False),
    sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
    sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('now()')),
    sa.Column('created_by', sa.Integer(), nullable=True),
    sa.Column('updated_by', sa.Integer(), nullable=True),
    sa.ForeignKeyConstraint(['created_by'], ['users.user_id'], ),
    sa.ForeignKeyConstraint(['licitacion_id'], ['licitaciones.licitacion_id'], ),
    sa.ForeignKeyConstraint(['updated_by'], ['users.user_id'], ),
    sa.PrimaryKeyConstraint('prorroga_id')
    )
    op.create_index(op.f('ix_prorrogas_estado_prorroga'), 'prorrogas', ['estado_prorroga'], unique=False)
    op.create_index(op.f('ix_prorrogas_licitacion_id'), 'prorrogas', ['licitacion_id'], unique=False)
    op.create_index(op.f('ix_prorrogas_prorroga_id'), 'prorrogas', ['prorroga_id'], unique=False)

    # Create contactos table
    op.create_table('contactos',
    sa.Column('contacto_id', sa.Integer(), nullable=False),
    sa.Column('cliente_id', sa.Integer(), nullable=False),
    sa.Column('nombre_contacto', sa.String(length=255), nullable=False),
    sa.Column('cargo', sa.String(length=100), nullable=True),
    sa.Column('departamento', sa.String(length=100), nullable=True),
    sa.Column('telefono', sa.String(length=50), nullable=True),
    sa.Column('celular', sa.String(length=50), nullable=True),
    sa.Column('email', sa.String(length=255), nullable=True),
    sa.Column('extension', sa.String(length=20), nullable=True),
    sa.Column('linkedin_url', sa.Text(), nullable=True),
    sa.Column('es_contacto_principal', sa.Boolean(), nullable=True),
    sa.Column('puede_firmar', sa.Boolean(), nullable=True),
    sa.Column('nivel_decision', sa.String(length=50), nullable=True),
    sa.Column('preferencia_contacto', sa.String(length=50), nullable=True),
    sa.Column('mejor_horario_contacto', sa.String(length=100), nullable=True),
    sa.Column('notas', sa.Text(), nullable=True),
    sa.Column('is_active', sa.Boolean(), nullable=False),
    sa.Column('is_deleted', sa.Boolean(), nullable=False),
    sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
    sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('now()')),
    sa.Column('created_by', sa.Integer(), nullable=True),
    sa.ForeignKeyConstraint(['cliente_id'], ['clientes.cliente_id'], ),
    sa.ForeignKeyConstraint(['created_by'], ['users.user_id'], ),
    sa.PrimaryKeyConstraint('contacto_id')
    )
    op.create_index(op.f('ix_contactos_cliente_id'), 'contactos', ['cliente_id'], unique=False)
    op.create_index(op.f('ix_contactos_contacto_id'), 'contactos', ['contacto_id'], unique=False)

    # Create interacciones_cliente table
    op.create_table('interacciones_cliente',
    sa.Column('interaccion_id', sa.Integer(), nullable=False),
    sa.Column('cliente_id', sa.Integer(), nullable=False),
    sa.Column('contacto_id', sa.Integer(), nullable=True),
    sa.Column('licitacion_id', sa.Integer(), nullable=True),
    sa.Column('tipo_interaccion', sa.String(length=50), nullable=False),
    sa.Column('titulo', sa.String(length=255), nullable=False),
    sa.Column('descripcion', sa.Text(), nullable=False),
    sa.Column('fecha_interaccion', sa.DateTime(timezone=True), nullable=False),
    sa.Column('duracion_minutos', sa.Integer(), nullable=True),
    sa.Column('ubicacion', sa.String(length=255), nullable=True),
    sa.Column('modalidad', sa.String(length=50), nullable=True),
    sa.Column('resultado', sa.String(length=100), nullable=True),
    sa.Column('nivel_interes', sa.Integer(), nullable=True),
    sa.Column('requiere_seguimiento', sa.Boolean(), nullable=True),
    sa.Column('fecha_proximo_seguimiento', sa.Date(), nullable=True),
    sa.Column('accion_siguiente', sa.Text(), nullable=True),
    sa.Column('responsable_seguimiento', sa.Integer(), nullable=True),
    sa.Column('participantes', postgresql.ARRAY(sa.String()), nullable=True),
    sa.Column('asistentes_internos', postgresql.ARRAY(sa.String()), nullable=True),
    sa.Column('documentos_vinculados', postgresql.ARRAY(sa.Integer()), nullable=True),
    sa.Column('observaciones', sa.Text(), nullable=True),
    sa.Column('puntos_clave', sa.Text(), nullable=True),
    sa.Column('compromisos', sa.Text(), nullable=True),
    sa.Column('is_active', sa.Boolean(), nullable=False),
    sa.Column('is_deleted', sa.Boolean(), nullable=False),
    sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
    sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('now()')),
    sa.Column('created_by', sa.Integer(), nullable=True),
    sa.ForeignKeyConstraint(['cliente_id'], ['clientes.cliente_id'], ),
    sa.ForeignKeyConstraint(['contacto_id'], ['contactos.contacto_id'], ),
    sa.ForeignKeyConstraint(['created_by'], ['users.user_id'], ),
    sa.ForeignKeyConstraint(['licitacion_id'], ['licitaciones.licitacion_id'], ),
    sa.ForeignKeyConstraint(['responsable_seguimiento'], ['users.user_id'], ),
    sa.PrimaryKeyConstraint('interaccion_id')
    )
    op.create_index(op.f('ix_interacciones_cliente_cliente_id'), 'interacciones_cliente', ['cliente_id'], unique=False)
    op.create_index(op.f('ix_interacciones_cliente_fecha_interaccion'), 'interacciones_cliente', ['fecha_interaccion'], unique=False)
    op.create_index(op.f('ix_interacciones_cliente_interaccion_id'), 'interacciones_cliente', ['interaccion_id'], unique=False)
    op.create_index(op.f('ix_interacciones_cliente_tipo_interaccion'), 'interacciones_cliente', ['tipo_interaccion'], unique=False)

    # Create alertas table
    op.create_table('alertas',
    sa.Column('alerta_id', sa.Integer(), nullable=False),
    sa.Column('tipo_alerta', sa.String(length=50), nullable=False),
    sa.Column('licitacion_id', sa.Integer(), nullable=True),
    sa.Column('documento_id', sa.Integer(), nullable=True),
    sa.Column('ampliacion_id', sa.Integer(), nullable=True),
    sa.Column('cliente_id', sa.Integer(), nullable=True),
    sa.Column('user_id', sa.Integer(), nullable=True),
    sa.Column('titulo', sa.String(length=255), nullable=False),
    sa.Column('mensaje', sa.Text(), nullable=False),
    sa.Column('nivel_prioridad', sa.String(length=20), nullable=True),
    sa.Column('estado_alerta', sa.String(length=50), nullable=True),
    sa.Column('fecha_alerta', sa.DateTime(timezone=True), nullable=False),
    sa.Column('fecha_leida', sa.DateTime(timezone=True), nullable=True),
    sa.Column('fecha_resuelta', sa.DateTime(timezone=True), nullable=True),
    sa.Column('fecha_descartada', sa.DateTime(timezone=True), nullable=True),
    sa.Column('requiere_accion', sa.Boolean(), nullable=True),
    sa.Column('url_accion', sa.Text(), nullable=True),
    sa.Column('accion_sugerida', sa.String(length=255), nullable=True),
    sa.Column('enviada_email', sa.Boolean(), nullable=True),
    sa.Column('fecha_envio_email', sa.DateTime(timezone=True), nullable=True),
    sa.Column('email_destinatario', sa.String(length=255), nullable=True),
    sa.Column('es_recurrente', sa.Boolean(), nullable=True),
    sa.Column('frecuencia_dias', sa.Integer(), nullable=True),
    sa.Column('ultima_generacion', sa.DateTime(timezone=True), nullable=True),
    sa.Column('notas_usuario', sa.Text(), nullable=True),
    sa.Column('is_active', sa.Boolean(), nullable=False),
    sa.Column('is_deleted', sa.Boolean(), nullable=False),
    sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
    sa.Column('created_by', sa.Integer(), nullable=True),
    sa.ForeignKeyConstraint(['ampliacion_id'], ['ampliaciones.ampliacion_id'], ),
    sa.ForeignKeyConstraint(['cliente_id'], ['clientes.cliente_id'], ),
    sa.ForeignKeyConstraint(['created_by'], ['users.user_id'], ),
    sa.ForeignKeyConstraint(['documento_id'], ['documentos.documento_id'], ),
    sa.ForeignKeyConstraint(['licitacion_id'], ['licitaciones.licitacion_id'], ),
    sa.ForeignKeyConstraint(['user_id'], ['users.user_id'], ),
    sa.PrimaryKeyConstraint('alerta_id')
    )
    op.create_index(op.f('ix_alertas_alerta_id'), 'alertas', ['alerta_id'], unique=False)
    op.create_index(op.f('ix_alertas_estado_alerta'), 'alertas', ['estado_alerta'], unique=False)
    op.create_index(op.f('ix_alertas_fecha_alerta'), 'alertas', ['fecha_alerta'], unique=False)
    op.create_index(op.f('ix_alertas_nivel_prioridad'), 'alertas', ['nivel_prioridad'], unique=False)
    op.create_index(op.f('ix_alertas_tipo_alerta'), 'alertas', ['tipo_alerta'], unique=False)

    # Create configuracion_alertas table
    op.create_table('configuracion_alertas',
    sa.Column('config_id', sa.Integer(), nullable=False),
    sa.Column('user_id', sa.Integer(), nullable=False),
    sa.Column('alertas_documentos_vencidos', sa.Boolean(), nullable=True),
    sa.Column('dias_alerta_documentos', sa.Integer(), nullable=True),
    sa.Column('alertas_contratos_proximos', sa.Boolean(), nullable=True),
    sa.Column('dias_alerta_contratos', sa.Integer(), nullable=True),
    sa.Column('alertas_garantias', sa.Boolean(), nullable=True),
    sa.Column('dias_alerta_garantias', sa.Integer(), nullable=True),
    sa.Column('alertas_seguimientos', sa.Boolean(), nullable=True),
    sa.Column('dias_alerta_seguimientos', sa.Integer(), nullable=True),
    sa.Column('alertas_licitaciones', sa.Boolean(), nullable=True),
    sa.Column('alertas_ampliaciones', sa.Boolean(), nullable=True),
    sa.Column('notificar_email', sa.Boolean(), nullable=True),
    sa.Column('notificar_push', sa.Boolean(), nullable=True),
    sa.Column('notificar_sms', sa.Boolean(), nullable=True),
    sa.Column('horario_inicio', sa.Time(), nullable=True),
    sa.Column('horario_fin', sa.Time(), nullable=True),
    sa.Column('notificar_fines_semana', sa.Boolean(), nullable=True),
    sa.Column('enviar_resumen_diario', sa.Boolean(), nullable=True),
    sa.Column('hora_resumen_diario', sa.Time(), nullable=True),
    sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('now()')),
    sa.ForeignKeyConstraint(['user_id'], ['users.user_id'], ),
    sa.PrimaryKeyConstraint('config_id'),
    sa.UniqueConstraint('user_id')
    )
    op.create_index(op.f('ix_configuracion_alertas_config_id'), 'configuracion_alertas', ['config_id'], unique=False)

    # Create auditoria table
    op.create_table('auditoria',
    sa.Column('auditoria_id', sa.Integer(), nullable=False),
    sa.Column('user_id', sa.Integer(), nullable=True),
    sa.Column('accion', sa.String(length=100), nullable=False),
    sa.Column('tabla_afectada', sa.String(length=100), nullable=True),
    sa.Column('registro_id', sa.Integer(), nullable=True),
    sa.Column('datos_anteriores', postgresql.JSONB(astext_type=sa.Text()), nullable=True),
    sa.Column('datos_nuevos', postgresql.JSONB(astext_type=sa.Text()), nullable=True),
    sa.Column('ip_address', sa.String(length=50), nullable=True),
    sa.Column('user_agent', sa.Text(), nullable=True),
    sa.Column('endpoint', sa.String(length=255), nullable=True),
    sa.Column('metodo_http', sa.String(length=10), nullable=True),
    sa.Column('exitosa', sa.Boolean(), nullable=True),
    sa.Column('codigo_respuesta', sa.Integer(), nullable=True),
    sa.Column('mensaje_error', sa.Text(), nullable=True),
    sa.Column('descripcion', sa.Text(), nullable=True),
    sa.Column('metadata', postgresql.JSONB(astext_type=sa.Text()), nullable=True),
    sa.Column('timestamp', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
    sa.ForeignKeyConstraint(['user_id'], ['users.user_id'], ),
    sa.PrimaryKeyConstraint('auditoria_id')
    )
    op.create_index(op.f('ix_auditoria_accion'), 'auditoria', ['accion'], unique=False)
    op.create_index(op.f('ix_auditoria_tabla_afectada'), 'auditoria', ['tabla_afectada'], unique=False)
    op.create_index(op.f('ix_auditoria_timestamp'), 'auditoria', ['timestamp'], unique=False)
    op.create_index(op.f('ix_auditoria_user_id'), 'auditoria', ['user_id'], unique=False)


def downgrade() -> None:
    # Drop tables in reverse order
    op.drop_index(op.f('ix_auditoria_user_id'), table_name='auditoria')
    op.drop_index(op.f('ix_auditoria_timestamp'), table_name='auditoria')
    op.drop_index(op.f('ix_auditoria_tabla_afectada'), table_name='auditoria')
    op.drop_index(op.f('ix_auditoria_accion'), table_name='auditoria')
    op.drop_table('auditoria')

    op.drop_index(op.f('ix_configuracion_alertas_config_id'), table_name='configuracion_alertas')
    op.drop_table('configuracion_alertas')

    op.drop_index(op.f('ix_alertas_tipo_alerta'), table_name='alertas')
    op.drop_index(op.f('ix_alertas_nivel_prioridad'), table_name='alertas')
    op.drop_index(op.f('ix_alertas_fecha_alerta'), table_name='alertas')
    op.drop_index(op.f('ix_alertas_estado_alerta'), table_name='alertas')
    op.drop_index(op.f('ix_alertas_alerta_id'), table_name='alertas')
    op.drop_table('alertas')

    op.drop_index(op.f('ix_interacciones_cliente_tipo_interaccion'), table_name='interacciones_cliente')
    op.drop_index(op.f('ix_interacciones_cliente_interaccion_id'), table_name='interacciones_cliente')
    op.drop_index(op.f('ix_interacciones_cliente_fecha_interaccion'), table_name='interacciones_cliente')
    op.drop_index(op.f('ix_interacciones_cliente_cliente_id'), table_name='interacciones_cliente')
    op.drop_table('interacciones_cliente')

    op.drop_index(op.f('ix_contactos_contacto_id'), table_name='contactos')
    op.drop_index(op.f('ix_contactos_cliente_id'), table_name='contactos')
    op.drop_table('contactos')

    op.drop_index(op.f('ix_prorrogas_prorroga_id'), table_name='prorrogas')
    op.drop_index(op.f('ix_prorrogas_licitacion_id'), table_name='prorrogas')
    op.drop_index(op.f('ix_prorrogas_estado_prorroga'), table_name='prorrogas')
    op.drop_table('prorrogas')

    op.drop_index(op.f('ix_ampliaciones_tipo_ampliacion'), table_name='ampliaciones')
    op.drop_index(op.f('ix_ampliaciones_licitacion_id'), table_name='ampliaciones')
    op.drop_index(op.f('ix_ampliaciones_fecha_solicitud'), table_name='ampliaciones')
    op.drop_index(op.f('ix_ampliaciones_estado_ampliacion'), table_name='ampliaciones')
    op.drop_index(op.f('ix_ampliaciones_ampliacion_id'), table_name='ampliaciones')
    op.drop_table('ampliaciones')

    op.drop_index(op.f('ix_documentos_tipo_documento'), table_name='documentos')
    op.drop_index(op.f('ix_documentos_nombre_archivo_almacenado'), table_name='documentos')
    op.drop_index(op.f('ix_documentos_licitacion_id'), table_name='documentos')
    op.drop_index(op.f('ix_documentos_fecha_vencimiento'), table_name='documentos')
    op.drop_index(op.f('ix_documentos_estado_documento'), table_name='documentos')
    op.drop_index(op.f('ix_documentos_documento_id'), table_name='documentos')
    op.drop_table('documentos')

    op.drop_index(op.f('ix_licitaciones_numero_licitacion'), table_name='licitaciones')
    op.drop_index(op.f('ix_licitaciones_licitacion_id'), table_name='licitaciones')
    op.drop_index(op.f('ix_licitaciones_fecha_presentacion'), table_name='licitaciones')
    op.drop_index(op.f('ix_licitaciones_fecha_fin_contrato'), table_name='licitaciones')
    op.drop_index(op.f('ix_licitaciones_estado_licitacion'), table_name='licitaciones')
    op.drop_index(op.f('ix_licitaciones_categoria'), table_name='licitaciones')
    op.drop_table('licitaciones')

    op.drop_index(op.f('ix_clientes_nombre_cliente'), table_name='clientes')
    op.drop_index(op.f('ix_clientes_identificacion'), table_name='clientes')
    op.drop_index(op.f('ix_clientes_cliente_id'), table_name='clientes')
    op.drop_table('clientes')

    op.drop_index(op.f('ix_users_username'), table_name='users')
    op.drop_index(op.f('ix_users_user_id'), table_name='users')
    op.drop_index(op.f('ix_users_email'), table_name='users')
    op.drop_table('users')
