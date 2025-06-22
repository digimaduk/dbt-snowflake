# KYC Profile Incremental Sync - dbt Implementation

## Overview

This implementation provides a robust solution for maintaining the current state of KYC profiles by syncing the latest records from `kyc_profile_audit` to `kyc_profile` every 10 minutes.

## Architecture

```
kyc_profile_audit (Source)          kyc_profile_current (Target)
├── kyc_profile_id                  ├── kyc_profile_id
├── goldtier_id                     ├── goldtier_id  
├── cid                            ├── cid
├── party_id                       ├── party_id
├── created_date                   ├── created_date
├── updated_date                   ├── updated_date
├── op_type (INSERT/UPDATE/DELETE)  └── (managed by dbt)
└── op_time (audit timestamp)
```

## Models Created

### 1. `stg_kyc_profile_current.sql` (Staging)
- **Purpose**: Simple staging model for basic audit-to-current sync
- **Materialization**: Incremental
- **Strategy**: Merge on `kyc_profile_id`
- **Best for**: Development and testing

### 2. `kyc_profile_current.sql` (Mart)
- **Purpose**: Production-ready incremental sync model
- **Materialization**: Incremental  
- **Strategy**: Delete+Insert (handles edge cases better)
- **Best for**: Production use

## Key Features

### ✅ **Incremental Processing**
- Only processes records changed since last run
- Efficient performance for large datasets
- Handles catch-up scenarios gracefully

### ✅ **Operation Handling**
- **INSERT**: New profiles added to target
- **UPDATE**: Existing profiles updated with latest data
- **DELETE**: Profiles removed from target table

### ✅ **Data Quality**
- Comprehensive tests for uniqueness and null values
- Custom freshness checks to monitor sync health
- Schema documentation and lineage tracking

### ✅ **Error Handling**
- Graceful handling of missing data
- Robust incremental logic with fallbacks
- Clear logging and monitoring hooks

## Setup Instructions

### 1. Create Source Tables
```sql
-- Run in Snowflake
-- File: setup_kyc_tables.sql
CREATE SCHEMA IF NOT EXISTS ORI_RAW_DB.raw;
-- ... (see setup script for full details)
```

### 2. Test the Models
```bash
# Activate dbt environment
cd /Users/meghadureja/poc/dbt-poc
source dbt-venv/bin/activate

# Test staging model first
dbt run --profiles-dir ~/.dbt --select stg_kyc_profile_current
dbt test --profiles-dir ~/.dbt --select stg_kyc_profile_current

# Test production model
dbt run --profiles-dir ~/.dbt --select kyc_profile_current
dbt test --profiles-dir ~/.dbt --select kyc_profile_current
```

### 3. Schedule for Production
```bash
# Run every 10 minutes (example cron: */10 * * * *)
dbt run --profiles-dir ~/.dbt --select kyc_profile_current
```

## Sample Data Pattern

The setup script creates this audit trail pattern:

| kyc_profile_id | op_type | op_time | Result |
|----------------|---------|---------|---------|
| 1 | INSERT | 10:00 | Initial record |
| 1 | UPDATE | 11:30 | Updated record |
| 1 | UPDATE | 14:15 | **Latest** ← synced |
| 2 | INSERT | 09:30 | Initial record |
| 2 | UPDATE | 12:45 | **Latest** ← synced |
| 3 | INSERT | 08:00 | **Latest** ← synced |
| 4 | INSERT | 07:00 | Initial record |
| 4 | DELETE | 13:00 | **Deleted** ← excluded |

**Expected Result**: 3 active profiles (1, 2, 3) in `kyc_profile_current`

## Monitoring & Troubleshooting

### Data Freshness Check
```sql
-- Custom test: tests/kyc_profile_freshness_check.sql
-- Fails if any records are older than 15 minutes
-- Indicates sync job issues
```

### Common Issues & Solutions

1. **No incremental updates**
   - Check `op_time` is populated correctly
   - Verify incremental logic with `--full-refresh`

2. **Duplicate records**
   - Ensure `unique_key='kyc_profile_id'` is set
   - Check for concurrent audit writes

3. **Missing deletes**
   - Verify `op_type='DELETE'` is being filtered out
   - Check delete+insert strategy is working

### Performance Optimization

```yaml
# In dbt_project.yml
models:
  dbt_poc:
    marts:
      kyc_profile_current:
        +post-hook: "analyze table {{ this }}"  # Snowflake optimization
        +snowflake_warehouse: "COMPUTE_WH_LARGE"  # For large datasets
```

## Production Considerations

### 1. **Scheduling**
- Use dbt Cloud, Airflow, or cron for 10-minute frequency
- Consider business hours vs 24/7 requirements
- Plan for maintenance windows

### 2. **Monitoring**
- Set up alerts on test failures
- Monitor run duration (should be < 2 minutes typically)
- Track row counts and data freshness

### 3. **Backup Strategy**
- Keep audit table for historical analysis
- Consider snapshotting critical profile changes
- Plan for disaster recovery scenarios

## Example Commands

```bash
# Full refresh (reprocess all data)
dbt run --profiles-dir ~/.dbt --select kyc_profile_current --full-refresh

# Run with debug logging
dbt run --profiles-dir ~/.dbt --select kyc_profile_current --log-level debug

# Test data quality
dbt test --profiles-dir ~/.dbt --select kyc_profile_current

# Generate documentation
dbt docs generate --profiles-dir ~/.dbt
dbt docs serve --profiles-dir ~/.dbt --port 8080
```

This implementation provides a robust, scalable solution for your KYC profile sync requirements with comprehensive testing and monitoring capabilities.
