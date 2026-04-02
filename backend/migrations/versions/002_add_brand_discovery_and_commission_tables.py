"""Add brand discovery, brand candidates, and commission tables.

Revision ID: 002
Revises: 001
Create Date: 2026-04-01 00:00:00.000000

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers
revision = '002'
down_revision = '001'
branch_labels = None
depends_on = None


def upgrade():
    """Create new tables for brand discovery system."""

    # Create brand_candidates table
    op.create_table(
        'brand_candidates',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('name', sa.String(255), nullable=False, unique=True),
        sa.Column('website', sa.String(512), nullable=True),
        sa.Column('instagram', sa.String(255), nullable=True),
        sa.Column('description', sa.String(1024), nullable=True),
        sa.Column('price_range_low', sa.Float(), nullable=True),
        sa.Column('price_range_high', sa.Float(), nullable=True),
        sa.Column('aesthetic_tags', postgresql.JSON(astext_type=sa.Text()), nullable=True),
        sa.Column('affiliate_network', sa.String(50), nullable=True),
        sa.Column('affiliate_publisher_id', sa.String(255), nullable=True),
        sa.Column('affiliate_merchant_id', sa.String(255), nullable=True),
        sa.Column('commission_rate', sa.Float(), nullable=True),
        sa.Column('has_ambassador_program', sa.Boolean(), default=False),
        sa.Column('ambassador_program_url', sa.String(512), nullable=True),
        sa.Column('status', sa.String(50), nullable=False, default='pending'),
        sa.Column('fit_score', sa.Float(), nullable=True),
        sa.Column('evaluation_notes', sa.String(2048), nullable=True),
        sa.Column('evaluated_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('activated_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('name', name='uq_brand_candidate_name'),
    )
    op.create_index('idx_brand_candidate_status', 'brand_candidates', ['status'])
    op.create_index('idx_brand_candidate_created_at', 'brand_candidates', ['created_at'])
    op.create_index('idx_brand_candidate_affiliate_network', 'brand_candidates', ['affiliate_network'])

    # Create brand_discovery_cards table
    op.create_table(
        'brand_discovery_cards',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('brand_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('brand_name', sa.String(255), nullable=False),
        sa.Column('description', sa.String(1024), nullable=True),
        sa.Column('logo_url', sa.String(512), nullable=True),
        sa.Column('aesthetic_tags', postgresql.JSON(astext_type=sa.Text()), nullable=True),
        sa.Column('price_range_low', sa.Float(), nullable=True),
        sa.Column('price_range_high', sa.Float(), nullable=True),
        sa.Column('ambassador_program_url', sa.String(512), nullable=True),
        sa.Column('has_ambassador_program', sa.Boolean(), default=False),
        sa.Column('total_views', sa.Integer(), default=0),
        sa.Column('total_likes', sa.Integer(), default=0),
        sa.Column('total_dislikes', sa.Integer(), default=0),
        sa.Column('total_skips', sa.Integer(), default=0),
        sa.Column('status', sa.String(50), nullable=False, default='active'),
        sa.Column('is_active', sa.Boolean(), default=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(['brand_id'], ['brands.id']),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index('idx_brand_discovery_card_brand_id', 'brand_discovery_cards', ['brand_id'])
    op.create_index('idx_brand_discovery_card_status', 'brand_discovery_cards', ['status'])
    op.create_index('idx_brand_discovery_card_is_active', 'brand_discovery_cards', ['is_active'])
    op.create_index('idx_brand_discovery_card_created_at', 'brand_discovery_cards', ['created_at'])

    # Create brand_discovery_swipes table
    op.create_table(
        'brand_discovery_swipes',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('card_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('brand_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('action', sa.String(50), nullable=False),
        sa.Column('dwell_time_ms', sa.Integer(), default=0),
        sa.Column('session_id', sa.String(255), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(['user_id'], ['users.id']),
        sa.ForeignKeyConstraint(['card_id'], ['brand_discovery_cards.id']),
        sa.ForeignKeyConstraint(['brand_id'], ['brands.id']),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index('idx_brand_discovery_swipe_user_id', 'brand_discovery_swipes', ['user_id'])
    op.create_index('idx_brand_discovery_swipe_card_id', 'brand_discovery_swipes', ['card_id'])
    op.create_index('idx_brand_discovery_swipe_brand_id', 'brand_discovery_swipes', ['brand_id'])
    op.create_index('idx_brand_discovery_swipe_action', 'brand_discovery_swipes', ['action'])
    op.create_index('idx_brand_discovery_swipe_created_at', 'brand_discovery_swipes', ['created_at'])

    # Create commissions table
    op.create_table(
        'commissions',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('product_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('brand_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('retailer_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('product_price', sa.Float(), nullable=False),
        sa.Column('commission_rate', sa.Float(), nullable=False),
        sa.Column('commission_amount', sa.Float(), nullable=False),
        sa.Column('affiliate_link_used', sa.String(512), nullable=True),
        sa.Column('click_timestamp', sa.DateTime(timezone=True), nullable=True),
        sa.Column('conversion_timestamp', sa.DateTime(timezone=True), nullable=True),
        sa.Column('is_pending', sa.Boolean(), default=True),
        sa.Column('is_confirmed', sa.Boolean(), default=False),
        sa.Column('is_rejected', sa.Boolean(), default=False),
        sa.Column('rejection_reason', sa.String(512), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(['user_id'], ['users.id']),
        sa.ForeignKeyConstraint(['product_id'], ['products.id']),
        sa.ForeignKeyConstraint(['brand_id'], ['brands.id']),
        sa.ForeignKeyConstraint(['retailer_id'], ['retailers.id']),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index('idx_commission_user_id', 'commissions', ['user_id'])
    op.create_index('idx_commission_brand_id', 'commissions', ['brand_id'])
    op.create_index('idx_commission_product_id', 'commissions', ['product_id'])
    op.create_index('idx_commission_retailer_id', 'commissions', ['retailer_id'])
    op.create_index('idx_commission_is_pending', 'commissions', ['is_pending'])
    op.create_index('idx_commission_is_confirmed', 'commissions', ['is_confirmed'])
    op.create_index('idx_commission_created_at', 'commissions', ['created_at'])


def downgrade():
    """Drop new tables."""
    op.drop_table('commissions')
    op.drop_table('brand_discovery_swipes')
    op.drop_table('brand_discovery_cards')
    op.drop_table('brand_candidates')
