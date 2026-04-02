"""Initial schema migration.

Revision ID: 001
Revises:
Create Date: 2026-04-01 00:00:00.000000

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision = '001'
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    """Upgrade to initial schema."""
    # Create users table
    op.create_table(
        'users',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('apple_id', sa.String(255), nullable=True),
        sa.Column('email', sa.String(255), nullable=True),
        sa.Column('hashed_password', sa.String(255), nullable=True),
        sa.Column('display_name', sa.String(255), nullable=True),
        sa.Column('onboarding_completed', sa.Boolean(), nullable=False, server_default='false'),
        sa.Column('quiz_responses', postgresql.JSON(astext_type=sa.Text()), nullable=True),
        sa.Column('preference_vector', postgresql.ARRAY(sa.Float()), nullable=True),
        sa.Column('settings', postgresql.JSON(astext_type=sa.Text()), nullable=False, server_default='{}'),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('apple_id'),
        sa.UniqueConstraint('email'),
    )
    op.create_index('idx_user_apple_id', 'users', ['apple_id'])
    op.create_index('idx_user_email', 'users', ['email'])
    op.create_index('idx_user_created_at', 'users', ['created_at'])

    # Create brands table
    op.create_table(
        'brands',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('name', sa.String(255), nullable=False),
        sa.Column('slug', sa.String(255), nullable=False),
        sa.Column('tier', sa.Enum('luxury', 'premium', 'contemporary', 'fast_fashion', 'indie', name='brandtier'), nullable=False),
        sa.Column('aesthetics', postgresql.JSON(astext_type=sa.Text()), nullable=True),
        sa.Column('price_range_low', sa.Float(), nullable=True),
        sa.Column('price_range_high', sa.Float(), nullable=True),
        sa.Column('logo_url', sa.String(512), nullable=True),
        sa.Column('website_url', sa.String(512), nullable=True),
        sa.Column('is_active', sa.Boolean(), nullable=False, server_default='true'),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('name'),
        sa.UniqueConstraint('slug'),
    )
    op.create_index('idx_brand_slug', 'brands', ['slug'])
    op.create_index('idx_brand_is_active', 'brands', ['is_active'])
    op.create_index('idx_brand_tier', 'brands', ['tier'])

    # Create retailers table
    op.create_table(
        'retailers',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('name', sa.String(255), nullable=False),
        sa.Column('slug', sa.String(255), nullable=False),
        sa.Column('affiliate_network', sa.Enum('rakuten', 'impact', 'awin', 'skimlinks', 'direct', name='affiliatenetwork'), nullable=False),
        sa.Column('affiliate_publisher_id', sa.String(255), nullable=True),
        sa.Column('commission_rate', sa.Float(), nullable=True),
        sa.Column('cookie_window_days', sa.Integer(), nullable=False, server_default='30'),
        sa.Column('product_feed_url', sa.String(512), nullable=True),
        sa.Column('product_feed_format', sa.Enum('csv', 'json', 'xml', 'tsv', name='productfeedformat'), nullable=True),
        sa.Column('favicon_url', sa.String(512), nullable=True),
        sa.Column('is_active', sa.Boolean(), nullable=False, server_default='true'),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('name'),
        sa.UniqueConstraint('slug'),
    )
    op.create_index('idx_retailer_slug', 'retailers', ['slug'])
    op.create_index('idx_retailer_is_active', 'retailers', ['is_active'])
    op.create_index('idx_retailer_affiliate_network', 'retailers', ['affiliate_network'])

    # Create products table
    op.create_table(
        'products',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('external_id', sa.String(255), nullable=False),
        sa.Column('retailer_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('brand_id', postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column('name', sa.String(512), nullable=False),
        sa.Column('description', sa.String(2048), nullable=True),
        sa.Column('category', sa.String(128), nullable=True),
        sa.Column('subcategory', sa.String(128), nullable=True),
        sa.Column('current_price', sa.Float(), nullable=False),
        sa.Column('original_price', sa.Float(), nullable=True),
        sa.Column('currency', sa.String(3), nullable=False, server_default='USD'),
        sa.Column('is_on_sale', sa.Boolean(), nullable=False, server_default='false'),
        sa.Column('sale_end_date', sa.DateTime(timezone=True), nullable=True),
        sa.Column('sizes_available', postgresql.JSON(astext_type=sa.Text()), nullable=True),
        sa.Column('colors', postgresql.JSON(astext_type=sa.Text()), nullable=True),
        sa.Column('materials', postgresql.JSON(astext_type=sa.Text()), nullable=True),
        sa.Column('image_urls', postgresql.ARRAY(sa.String(512)), nullable=True),
        sa.Column('product_url', sa.String(512), nullable=False),
        sa.Column('affiliate_url', sa.String(512), nullable=True),
        sa.Column('tags', postgresql.JSON(astext_type=sa.Text()), nullable=True),
        sa.Column('visual_embedding', postgresql.ARRAY(sa.Float()), nullable=True),
        sa.Column('image_quality_score', sa.Float(), nullable=True),
        sa.Column('is_active', sa.Boolean(), nullable=False, server_default='true'),
        sa.Column('last_price_check', sa.DateTime(timezone=True), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(['brand_id'], ['brands.id'], ),
        sa.ForeignKeyConstraint(['retailer_id'], ['retailers.id'], ),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('external_id', 'retailer_id', name='uq_product_external_id_retailer'),
    )
    op.create_index('idx_product_retailer_id', 'products', ['retailer_id'])
    op.create_index('idx_product_category', 'products', ['category'])
    op.create_index('idx_product_subcategory', 'products', ['subcategory'])
    op.create_index('idx_product_is_active', 'products', ['is_active'])
    op.create_index('idx_product_is_on_sale', 'products', ['is_on_sale'])
    op.create_index('idx_product_brand_id', 'products', ['brand_id'])
    op.create_index('idx_product_created_at', 'products', ['created_at'])

    # Create swipe_events table
    op.create_table(
        'swipe_events',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('product_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('action', sa.Enum('like', 'reject', 'super_like', 'undo', 'view_detail', 'shop_click', name='swipeaction'), nullable=False),
        sa.Column('dwell_time_ms', sa.Integer(), nullable=True),
        sa.Column('session_position', sa.Integer(), nullable=True),
        sa.Column('expanded', sa.Boolean(), nullable=False, server_default='false'),
        sa.Column('session_id', sa.String(255), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(['product_id'], ['products.id'], ),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index('idx_swipe_user_id', 'swipe_events', ['user_id'])
    op.create_index('idx_swipe_product_id', 'swipe_events', ['product_id'])
    op.create_index('idx_swipe_action', 'swipe_events', ['action'])
    op.create_index('idx_swipe_user_created', 'swipe_events', ['user_id', 'created_at'])
    op.create_index('idx_swipe_product_action', 'swipe_events', ['product_id', 'action'])
    op.create_index('idx_swipe_session_id', 'swipe_events', ['session_id'])
    op.create_index('idx_swipe_created_at', 'swipe_events', ['created_at'])

    # Create dresser_drawers table
    op.create_table(
        'dresser_drawers',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('name', sa.String(255), nullable=False),
        sa.Column('sort_order', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('is_default', sa.Boolean(), nullable=False, server_default='false'),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index('idx_drawer_user_id', 'dresser_drawers', ['user_id'])
    op.create_index('idx_drawer_user_sort', 'dresser_drawers', ['user_id', 'sort_order'])

    # Create dresser_items table
    op.create_table(
        'dresser_items',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('product_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('drawer_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('price_at_save', sa.Float(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(['drawer_id'], ['dresser_drawers.id'], ),
        sa.ForeignKeyConstraint(['product_id'], ['products.id'], ),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('user_id', 'product_id', 'drawer_id', name='uq_dresser_item_user_product_drawer'),
    )
    op.create_index('idx_dresser_item_user_id', 'dresser_items', ['user_id'])
    op.create_index('idx_dresser_item_product_id', 'dresser_items', ['product_id'])
    op.create_index('idx_dresser_item_drawer_id', 'dresser_items', ['drawer_id'])

    # Create refresh_tokens table
    op.create_table(
        'refresh_tokens',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('token', sa.String(512), nullable=False),
        sa.Column('expires_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('is_revoked', sa.Boolean(), nullable=False, server_default='false'),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('token'),
    )
    op.create_index('idx_refresh_token_user_id', 'refresh_tokens', ['user_id'])
    op.create_index('idx_refresh_token_expires_at', 'refresh_tokens', ['expires_at'])
    op.create_index('idx_refresh_token_is_revoked', 'refresh_tokens', ['is_revoked'])

    # Create device_tokens table
    op.create_table(
        'device_tokens',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('token', sa.String(512), nullable=False),
        sa.Column('platform', sa.String(32), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('token'),
    )
    op.create_index('idx_device_token_user_id', 'device_tokens', ['user_id'])

    # Create notification_log table
    op.create_table(
        'notification_log',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('type', sa.String(128), nullable=False),
        sa.Column('title', sa.String(255), nullable=False),
        sa.Column('body', sa.Text(), nullable=False),
        sa.Column('product_id', postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column('sent_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('tapped_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('dismissed_at', sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(['product_id'], ['products.id'], ),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index('idx_notification_log_user_id', 'notification_log', ['user_id'])
    op.create_index('idx_notification_log_type', 'notification_log', ['type'])
    op.create_index('idx_notification_log_sent_at', 'notification_log', ['sent_at'])

    # Create sale_events table
    op.create_table(
        'sale_events',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('retailer_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('name', sa.String(255), nullable=False),
        sa.Column('description', sa.Text(), nullable=True),
        sa.Column('start_date', sa.DateTime(timezone=True), nullable=False),
        sa.Column('end_date', sa.DateTime(timezone=True), nullable=False),
        sa.Column('is_active', sa.Boolean(), nullable=False, server_default='true'),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(['retailer_id'], ['retailers.id'], ),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index('idx_sale_event_retailer_id', 'sale_events', ['retailer_id'])
    op.create_index('idx_sale_event_is_active', 'sale_events', ['is_active'])
    op.create_index('idx_sale_event_start_date', 'sale_events', ['start_date'])
    op.create_index('idx_sale_event_end_date', 'sale_events', ['end_date'])

    # Create daily_drops table
    op.create_table(
        'daily_drops',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('product_ids', postgresql.JSON(astext_type=sa.Text()), nullable=False),
        sa.Column('streak_count', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('generated_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('viewed_at', sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index('idx_daily_drop_user_id', 'daily_drops', ['user_id'])
    op.create_index('idx_daily_drop_generated_at', 'daily_drops', ['generated_at'])


def downgrade() -> None:
    """Downgrade from initial schema."""
    # Drop tables in reverse order of creation
    op.drop_table('daily_drops')
    op.drop_table('sale_events')
    op.drop_table('notification_log')
    op.drop_table('device_tokens')
    op.drop_table('refresh_tokens')
    op.drop_table('dresser_items')
    op.drop_table('dresser_drawers')
    op.drop_table('swipe_events')
    op.drop_table('products')
    op.drop_table('retailers')
    op.drop_table('brands')
    op.drop_table('users')

    # Drop enums
    sa.Enum('luxury', 'premium', 'contemporary', 'fast_fashion', 'indie', name='brandtier').drop(op.get_bind())
    sa.Enum('rakuten', 'impact', 'awin', 'skimlinks', 'direct', name='affiliatenetwork').drop(op.get_bind())
    sa.Enum('csv', 'json', 'xml', 'tsv', name='productfeedformat').drop(op.get_bind())
    sa.Enum('like', 'reject', 'super_like', 'undo', 'view_detail', 'shop_click', name='swipeaction').drop(op.get_bind())
