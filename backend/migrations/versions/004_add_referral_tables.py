"""Add referral system tables.

Revision ID: 004
Create Date: 2026-04-01 12:00:00.000000
"""
import uuid
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers
revision = "004"
down_revision = "003"
branch_labels = None
depends_on = None


def upgrade() -> None:
    """Create referral system tables."""
    # Create referral_codes table
    op.create_table(
        "referral_codes",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False, default=uuid.uuid4),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("code", sa.String(20), nullable=False, unique=True),
        sa.Column("total_referrals", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("successful_referrals", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("current_tier", sa.String(50), nullable=False, server_default="none"),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default="true"),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"]),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("idx_referral_code_user_id", "referral_codes", ["user_id"])
    op.create_index("idx_referral_code_code", "referral_codes", ["code"])
    op.create_index("idx_referral_code_is_active", "referral_codes", ["is_active"])

    # Create referrals table
    op.create_table(
        "referrals",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False, default=uuid.uuid4),
        sa.Column("referrer_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("referred_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("referral_code_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("status", sa.String(50), nullable=False, server_default="pending"),
        sa.Column("referred_completed_onboarding", sa.Boolean(), nullable=False, server_default="false"),
        sa.Column("reward_granted", sa.Boolean(), nullable=False, server_default="false"),
        sa.Column("source", sa.String(50), nullable=False, server_default="other"),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("completed_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(["referrer_id"], ["users.id"]),
        sa.ForeignKeyConstraint(["referred_id"], ["users.id"]),
        sa.ForeignKeyConstraint(["referral_code_id"], ["referral_codes.id"]),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("idx_referral_referrer_id", "referrals", ["referrer_id"])
    op.create_index("idx_referral_referred_id", "referrals", ["referred_id"])
    op.create_index("idx_referral_status", "referrals", ["status"])
    op.create_index("idx_referral_created_at", "referrals", ["created_at"])

    # Create referral_rewards table
    op.create_table(
        "referral_rewards",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False, default=uuid.uuid4),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("reward_type", sa.String(50), nullable=False),
        sa.Column("milestone_count", sa.Integer(), nullable=False),
        sa.Column("granted_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default="true"),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"]),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("idx_referral_reward_user_id", "referral_rewards", ["user_id"])
    op.create_index("idx_referral_reward_type", "referral_rewards", ["reward_type"])
    op.create_index("idx_referral_reward_milestone", "referral_rewards", ["milestone_count"])

    # Create referral_shares table
    op.create_table(
        "referral_shares",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False, default=uuid.uuid4),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("referral_code_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("platform", sa.String(50), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"]),
        sa.ForeignKeyConstraint(["referral_code_id"], ["referral_codes.id"]),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("idx_referral_share_user_id", "referral_shares", ["user_id"])
    op.create_index("idx_referral_share_platform", "referral_shares", ["platform"])
    op.create_index("idx_referral_share_created_at", "referral_shares", ["created_at"])


def downgrade() -> None:
    """Drop referral system tables."""
    op.drop_index("idx_referral_share_created_at", table_name="referral_shares")
    op.drop_index("idx_referral_share_platform", table_name="referral_shares")
    op.drop_index("idx_referral_share_user_id", table_name="referral_shares")
    op.drop_table("referral_shares")

    op.drop_index("idx_referral_reward_milestone", table_name="referral_rewards")
    op.drop_index("idx_referral_reward_type", table_name="referral_rewards")
    op.drop_index("idx_referral_reward_user_id", table_name="referral_rewards")
    op.drop_table("referral_rewards")

    op.drop_index("idx_referral_created_at", table_name="referrals")
    op.drop_index("idx_referral_status", table_name="referrals")
    op.drop_index("idx_referral_referred_id", table_name="referrals")
    op.drop_index("idx_referral_referrer_id", table_name="referrals")
    op.drop_table("referrals")

    op.drop_index("idx_referral_code_is_active", table_name="referral_codes")
    op.drop_index("idx_referral_code_code", table_name="referral_codes")
    op.drop_index("idx_referral_code_user_id", table_name="referral_codes")
    op.drop_table("referral_codes")
