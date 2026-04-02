"""Add wallpaper house, pattern, and impression tables for brand partnerships.

Revision ID: 003
Revises: 002
Create Date: 2026-04-01 00:00:00.000000

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers
revision = '003'
down_revision = '002'
branch_labels = None
depends_on = None


def upgrade():
    """Create tables for wallpaper partnership system."""

    # Create wallpaper_houses table
    op.create_table(
        'wallpaper_houses',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('name', sa.String(255), nullable=False, unique=True),
        sa.Column('slug', sa.String(255), nullable=False, unique=True),
        sa.Column('description', sa.Text(), nullable=True),
        sa.Column('website_url', sa.String(500), nullable=True),
        sa.Column('logo_url', sa.String(500), nullable=True),
        sa.Column('partnership_status', sa.String(50), nullable=False, default='prospect'),
        sa.Column('monthly_fee', sa.Float(), nullable=False, default=0.0),
        sa.Column('contract_start', sa.DateTime(timezone=True), nullable=True),
        sa.Column('contract_end', sa.DateTime(timezone=True), nullable=True),
        sa.Column('impression_count', sa.Integer(), nullable=False, default=0),
        sa.Column('is_active', sa.Boolean(), nullable=False, default=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('name', name='uq_wallpaper_house_name'),
        sa.UniqueConstraint('slug', name='uq_wallpaper_house_slug'),
    )
    op.create_index('idx_wallpaper_house_slug', 'wallpaper_houses', ['slug'])
    op.create_index('idx_wallpaper_house_status', 'wallpaper_houses', ['partnership_status'])
    op.create_index('idx_wallpaper_house_is_active', 'wallpaper_houses', ['is_active'])

    # Create wallpaper_patterns table
    op.create_table(
        'wallpaper_patterns',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('house_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('name', sa.String(255), nullable=False),
        sa.Column('slug', sa.String(255), nullable=False, unique=True),
        sa.Column('description', sa.Text(), nullable=True),
        sa.Column('pattern_type', sa.String(50), nullable=False),
        sa.Column('primary_color_light', sa.String(7), nullable=False, default='#FFFFFF'),
        sa.Column('secondary_color_light', sa.String(7), nullable=True),
        sa.Column('primary_color_dark', sa.String(7), nullable=False, default='#000000'),
        sa.Column('secondary_color_dark', sa.String(7), nullable=True),
        sa.Column('opacity_light', sa.Float(), nullable=False, default=0.15),
        sa.Column('opacity_dark', sa.Float(), nullable=False, default=0.1),
        sa.Column('style_archetypes', postgresql.JSON(astext_type=sa.Text()), nullable=False),
        sa.Column('asset_key', sa.String(500), nullable=False),
        sa.Column('is_active', sa.Boolean(), nullable=False, default=True),
        sa.Column('display_priority', sa.Integer(), nullable=False, default=0),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint('id'),
        sa.ForeignKeyConstraint(['house_id'], ['wallpaper_houses.id'], ),
        sa.UniqueConstraint('slug', name='uq_wallpaper_pattern_slug'),
    )
    op.create_index('idx_wallpaper_pattern_house_id', 'wallpaper_patterns', ['house_id'])
    op.create_index('idx_wallpaper_pattern_slug', 'wallpaper_patterns', ['slug'])
    op.create_index('idx_wallpaper_pattern_is_active', 'wallpaper_patterns', ['is_active'])
    op.create_index('idx_wallpaper_pattern_priority', 'wallpaper_patterns', ['display_priority'])

    # Create wallpaper_impressions table
    op.create_table(
        'wallpaper_impressions',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('pattern_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('house_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('session_id', sa.String(255), nullable=True),
        sa.Column('swipe_position', sa.Integer(), nullable=False, default=0),
        sa.Column('dwell_ms', sa.Integer(), nullable=False, default=0),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint('id'),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ),
        sa.ForeignKeyConstraint(['pattern_id'], ['wallpaper_patterns.id'], ),
        sa.ForeignKeyConstraint(['house_id'], ['wallpaper_houses.id'], ),
    )
    op.create_index('idx_wallpaper_impression_user_id', 'wallpaper_impressions', ['user_id'])
    op.create_index('idx_wallpaper_impression_pattern_id', 'wallpaper_impressions', ['pattern_id'])
    op.create_index('idx_wallpaper_impression_house_id', 'wallpaper_impressions', ['house_id'])
    op.create_index('idx_wallpaper_impression_created_at', 'wallpaper_impressions', ['created_at'])


def downgrade():
    """Drop wallpaper tables."""
    op.drop_index('idx_wallpaper_impression_created_at', table_name='wallpaper_impressions')
    op.drop_index('idx_wallpaper_impression_house_id', table_name='wallpaper_impressions')
    op.drop_index('idx_wallpaper_impression_pattern_id', table_name='wallpaper_impressions')
    op.drop_index('idx_wallpaper_impression_user_id', table_name='wallpaper_impressions')
    op.drop_table('wallpaper_impressions')

    op.drop_index('idx_wallpaper_pattern_priority', table_name='wallpaper_patterns')
    op.drop_index('idx_wallpaper_pattern_is_active', table_name='wallpaper_patterns')
    op.drop_index('idx_wallpaper_pattern_slug', table_name='wallpaper_patterns')
    op.drop_index('idx_wallpaper_pattern_house_id', table_name='wallpaper_patterns')
    op.drop_table('wallpaper_patterns')

    op.drop_index('idx_wallpaper_house_is_active', table_name='wallpaper_houses')
    op.drop_index('idx_wallpaper_house_status', table_name='wallpaper_houses')
    op.drop_index('idx_wallpaper_house_slug', table_name='wallpaper_houses')
    op.drop_table('wallpaper_houses')
