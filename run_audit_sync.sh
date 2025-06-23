#!/bin/bash
# Source-to-Target Sync Runner Script
# Usage: ./run_audit_sync.sh <table_name> [full_refresh]
#
# Examples:
#   ./run_audit_sync.sh kyc_profile
#   ./run_audit_sync.sh kyc_profile_stg
#   ./run_audit_sync.sh kyc_profile full_refresh

set -e

if [ $# -eq 0 ]; then
    echo "Usage: $0 <table_name> [full_refresh]"
    echo ""
    echo "Available tables (from dbt_project.yml):"
    echo "  - kyc_profile"
    echo "  - kyc_profile_stg"
    echo ""
    echo "Examples:"
    echo "  $0 kyc_profile"
    echo "  $0 kyc_profile_stg"
    echo "  $0 kyc_profile full_refresh"
    exit 1
fi

TABLE_NAME=$1
FULL_REFRESH=${2:-""}

echo "🚀 Starting audit sync for table: $TABLE_NAME"

if [ "$FULL_REFRESH" = "full_refresh" ]; then
    echo "🔄 Running in full refresh mode..."
    dbt run --select audit_sync_dynamic --vars "sync_table: $TABLE_NAME" --full-refresh
else
    echo "📈 Running in incremental mode..."
    dbt run --select audit_sync_dynamic --vars "sync_table: $TABLE_NAME"
fi

echo "✅ Audit sync completed for $TABLE_NAME!"
