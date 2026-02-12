# Query Supabase Runtime IDs
# 
# This PowerShell script queries Supabase Postgres database to retrieve
# runtime-generated UUIDs and other identifiers from tables.
#
# Usage:
#   .\query-supabase-ids.ps1 -TableName "products" -Limit 10
#   .\query-supabase-ids.ps1 -TableName "orders" -DateFilter "2024-01-01"
#
# Requirements:
#   - PostgreSQL client (psql) installed
#   - Supabase connection string (set via environment variable or parameter)

param(
    [Parameter(Mandatory=$false)]
    [string]$ConnectionString = $env:SUPABASE_DB_URL,
    
    [Parameter(Mandatory=$false)]
    [string]$TableName = "products",
    
    [Parameter(Mandatory=$false)]
    [int]$Limit = 50,
    
    [Parameter(Mandatory=$false)]
    [string]$DateFilter = "",
    
    [Parameter(Mandatory=$false)]
    [string]$IdColumn = "id",
    
    [Parameter(Mandatory=$false)]
    [string]$DateColumn = "created_at",
    
    [Parameter(Mandatory=$false)]
    [switch]$ExportToCsv = $false,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputFile = "supabase-ids.csv"
)

# Check if connection string is provided
if ([string]::IsNullOrWhiteSpace($ConnectionString)) {
    Write-Host "Error: Connection string not provided." -ForegroundColor Red
    Write-Host "Set the SUPABASE_DB_URL environment variable or use -ConnectionString parameter." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Example:" -ForegroundColor Cyan
    Write-Host '  $env:SUPABASE_DB_URL = "postgresql://postgres:[password]@db.[project-ref].supabase.co:5432/postgres"'
    Write-Host "  .\query-supabase-ids.ps1 -TableName 'products'"
    exit 1
}

# Check if psql is installed
try {
    $psqlVersion = psql --version 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "psql not found"
    }
} catch {
    Write-Host "Error: PostgreSQL client (psql) is not installed or not in PATH." -ForegroundColor Red
    Write-Host "Install PostgreSQL: https://www.postgresql.org/download/" -ForegroundColor Yellow
    exit 1
}

Write-Host "=== Querying Supabase Runtime IDs ===" -ForegroundColor Green
Write-Host "Table: $TableName" -ForegroundColor Cyan
Write-Host "Limit: $Limit" -ForegroundColor Cyan

# Build the SQL query
$query = "SELECT $IdColumn"

# Add date column if filtering by date
if (![string]::IsNullOrWhiteSpace($DateFilter)) {
    $query += ", $DateColumn"
}

$query += " FROM $TableName"

# Add date filter if provided
if (![string]::IsNullOrWhiteSpace($DateFilter)) {
    $query += " WHERE $DateColumn >= '$DateFilter'"
}

# Add ordering and limit
$query += " ORDER BY $DateColumn DESC LIMIT $Limit;"

Write-Host "Query: $query" -ForegroundColor Gray
Write-Host ""

# Execute query and capture output
Write-Host "Executing query..." -ForegroundColor Yellow

if ($ExportToCsv) {
    # Export to CSV
    $csvQuery = "COPY ($query) TO STDOUT WITH CSV HEADER"
    $result = psql "$ConnectionString" -c "$csvQuery" 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        $result | Out-File -FilePath $OutputFile -Encoding utf8
        Write-Host "Results exported to: $OutputFile" -ForegroundColor Green
        
        # Show first few lines
        Write-Host ""
        Write-Host "Preview (first 10 rows):" -ForegroundColor Cyan
        Get-Content $OutputFile -TotalCount 11
    } else {
        Write-Host "Error executing query:" -ForegroundColor Red
        Write-Host $result
        exit 1
    }
} else {
    # Display in console
    $result = psql "$ConnectionString" -c "$query" 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host $result
    } else {
        Write-Host "Error executing query:" -ForegroundColor Red
        Write-Host $result
        exit 1
    }
}

Write-Host ""
Write-Host "=== Query Complete ===" -ForegroundColor Green

# Additional helpful commands
Write-Host ""
Write-Host "Helpful commands:" -ForegroundColor Yellow
Write-Host "  List all tables: psql `"$ConnectionString`" -c `"\dt`"" -ForegroundColor Gray
Write-Host "  Describe table: psql `"$ConnectionString`" -c `"\d $TableName`"" -ForegroundColor Gray
Write-Host "  Count records: psql `"$ConnectionString`" -c `"SELECT COUNT(*) FROM $TableName;`"" -ForegroundColor Gray
