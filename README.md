# dbt Snowflake Project

This is a dbt project configured to work with Snowflake as the data warehouse.

## Project Structure

```
dbt-poc/
├── dbt_project.yml          # Project configuration
├── profiles.yml             # Connection profiles (keep secure!)
├── requirements.txt         # Python dependencies
├── packages.yml            # dbt package dependencies
├── models/                 # SQL models
│   ├── staging/           # Staging models (views)
│   └── marts/             # Mart models (tables)
├── macros/                # Reusable SQL macros
├── tests/                 # Custom data tests
├── seeds/                 # CSV files to load as tables
└── snapshots/             # Slowly changing dimension tracking
```

## Setup Instructions

### 1. Install dbt

```bash
# Create a virtual environment (recommended)
python -m venv dbt-venv
source dbt-venv/bin/activate  # On Windows: dbt-venv\Scripts\activate

# Install dbt and dependencies
pip install -r requirements.txt
```

### 2. Configure Snowflake Connection

Update the `profiles.yml` file with your Snowflake credentials:

```yaml
dbt_poc:
  target: dev
  outputs:
    dev:
      type: snowflake
      account: your-account.region  # e.g., abc12345.us-east-1
      user: your_username
      password: your_password       # Consider using environment variables
      role: your_role              # e.g., ACCOUNTADMIN
      database: your_database      # e.g., DBT_DATABASE
      warehouse: your_warehouse    # e.g., COMPUTE_WH
      schema: your_schema          # e.g., DBT_SCHEMA
      threads: 4
```

**Security Note**: Consider using environment variables for sensitive information:

```yaml
user: "{{ env_var('DBT_SNOWFLAKE_USER') }}"
password: "{{ env_var('DBT_SNOWFLAKE_PASSWORD') }}"
```

### 3. Set Environment Variables (Optional but Recommended)

```bash
export DBT_SNOWFLAKE_USER="your_username"
export DBT_SNOWFLAKE_PASSWORD="your_password"
export DBT_SNOWFLAKE_ACCOUNT="your_account"
export DBT_SNOWFLAKE_ROLE="your_role"
export DBT_SNOWFLAKE_DATABASE="your_database"
export DBT_SNOWFLAKE_WAREHOUSE="your_warehouse"
export DBT_SNOWFLAKE_SCHEMA="your_schema"
```

### 4. Test Connection

```bash
# Test the connection
dbt debug

# Install dbt packages
dbt deps

# Compile models (doesn't run them)
dbt compile
```

### 5. Set Up Source Tables

Before running the models, ensure you have the following tables in your Snowflake database:
- `raw.customers`
- `raw.orders`

Example table creation scripts:

```sql
-- Create raw schema
CREATE SCHEMA IF NOT EXISTS raw;

-- Create customers table
CREATE OR REPLACE TABLE raw.customers (
    customer_id NUMBER PRIMARY KEY,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    email VARCHAR(255),
    phone VARCHAR(20),
    address VARCHAR(500),
    city VARCHAR(100),
    state VARCHAR(50),
    zip_code VARCHAR(10),
    created_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    updated_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- Create orders table
CREATE OR REPLACE TABLE raw.orders (
    order_id NUMBER PRIMARY KEY,
    customer_id NUMBER,
    order_date DATE,
    status VARCHAR(50),
    total_amount DECIMAL(10,2),
    created_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    updated_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);
```

## Running dbt

### Basic Commands

```bash
# Run all models
dbt run

# Run specific model
dbt run --models stg_customers

# Run staging models only
dbt run --models staging

# Run tests
dbt test

# Run tests for specific model
dbt test --models stg_customers

# Load seed files
dbt seed

# Generate documentation
dbt docs generate
dbt docs serve
```

### Development Workflow

1. **Build staging models**: `dbt run --models staging`
2. **Test staging models**: `dbt test --models staging`
3. **Build mart models**: `dbt run --models marts`
4. **Test everything**: `dbt test`
5. **Generate docs**: `dbt docs generate && dbt docs serve`

## Model Descriptions

### Staging Models (`models/staging/`)
- `stg_customers`: Cleaned customer data from raw source
- `stg_orders`: Cleaned order data from raw source

### Mart Models (`models/marts/`)
- `dim_customers`: Customer dimension with order history and segmentation

## Key Features

- **Data Quality Tests**: Built-in tests for uniqueness, null values, and referential integrity
- **Documentation**: Schema files document all models and columns
- **Macros**: Reusable SQL logic in the `macros/` folder
- **Seeds**: Reference data in CSV format
- **Snapshots**: Track slowly changing dimensions
- **Materializations**: Views for staging, tables for marts

## Best Practices Implemented

1. **Staging Layer**: Raw data cleaning and standardization
2. **Mart Layer**: Business logic and dimensional modeling
3. **Testing**: Comprehensive data quality tests
4. **Documentation**: All models and columns documented
5. **Version Control**: Git-friendly project structure
6. **Security**: Environment variables for credentials

## Troubleshooting

### Common Issues

1. **Connection Failed**
   - Verify Snowflake credentials in `profiles.yml`
   - Check network access to Snowflake
   - Ensure role has necessary permissions

2. **Model Compilation Errors**
   - Check SQL syntax in model files
   - Verify source table names and schemas
   - Run `dbt compile` to check for issues

3. **Test Failures**
   - Review test results: `dbt test --store-failures`
   - Check data quality in source tables
   - Adjust test thresholds if needed

### Getting Help

- dbt Documentation: https://docs.getdbt.com/
- dbt Community: https://community.getdbt.com/
- Snowflake + dbt Guide: https://docs.getdbt.com/reference/warehouse-setups/snowflake-setup
