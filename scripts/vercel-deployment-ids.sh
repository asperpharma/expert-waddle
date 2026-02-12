#!/bin/bash

# Vercel Deployment IDs Script
#
# This script lists Vercel deployment IDs using the Vercel CLI.
# Useful for tracking deployments, debugging issues, and CI/CD integration.
#
# Usage:
#   ./vercel-deployment-ids.sh
#   ./vercel-deployment-ids.sh --limit 20
#   ./vercel-deployment-ids.sh --production
#   ./vercel-deployment-ids.sh --json > deployments.json
#
# Requirements:
#   - Vercel CLI installed (npm i -g vercel)
#   - Authenticated with Vercel (vercel login)

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Default values
LIMIT=10
PRODUCTION_ONLY=false
JSON_OUTPUT=false
PROJECT=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --limit)
      LIMIT="$2"
      shift 2
      ;;
    --production)
      PRODUCTION_ONLY=true
      shift
      ;;
    --json)
      JSON_OUTPUT=true
      shift
      ;;
    --project)
      PROJECT="$2"
      shift 2
      ;;
    --help)
      echo "Usage: $0 [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  --limit N          Number of deployments to list (default: 10)"
      echo "  --production       Show only production deployments"
      echo "  --json             Output in JSON format"
      echo "  --project NAME     Specify project name"
      echo "  --help             Show this help message"
      echo ""
      echo "Examples:"
      echo "  $0"
      echo "  $0 --limit 20"
      echo "  $0 --production"
      echo "  $0 --json > deployments.json"
      exit 0
      ;;
    *)
      echo -e "${RED}Error: Unknown option $1${NC}"
      echo "Use --help for usage information"
      exit 1
      ;;
  esac
done

# Check if Vercel CLI is installed
if ! command -v vercel &> /dev/null; then
    echo -e "${RED}Error: Vercel CLI is not installed.${NC}"
    echo -e "${YELLOW}Install it with: npm i -g vercel${NC}"
    echo -e "${YELLOW}Or visit: https://vercel.com/docs/cli${NC}"
    exit 1
fi

# Check if user is logged in
if ! vercel whoami &> /dev/null; then
    echo -e "${RED}Error: Not logged in to Vercel.${NC}"
    echo -e "${YELLOW}Run: vercel login${NC}"
    exit 1
fi

echo -e "${GREEN}=== Vercel Deployment IDs ===${NC}"
echo -e "${CYAN}Fetching deployments...${NC}"
echo ""

# Build the vercel ls command
VERCEL_CMD="vercel ls"

if [ -n "$PROJECT" ]; then
    VERCEL_CMD="$VERCEL_CMD $PROJECT"
fi

# Add production filter if requested
if [ "$PRODUCTION_ONLY" = true ]; then
    VERCEL_CMD="$VERCEL_CMD --prod"
fi

# Execute and format output
if [ "$JSON_OUTPUT" = true ]; then
    # JSON output - use Vercel API via CLI
    echo -e "${YELLOW}Note: Using text output as Vercel CLI doesn't provide direct JSON export${NC}"
    echo -e "${YELLOW}Consider using the Vercel API directly for JSON output${NC}"
    echo ""
fi

# Get deployments
DEPLOYMENTS=$($VERCEL_CMD 2>&1)

if [ $? -ne 0 ]; then
    echo -e "${RED}Error fetching deployments:${NC}"
    echo "$DEPLOYMENTS"
    exit 1
fi

# Display deployments
echo "$DEPLOYMENTS" | head -n $((LIMIT + 5))

echo ""
echo -e "${GREEN}=== Deployment Details ===${NC}"
echo ""

# Extract and display deployment URLs and IDs
echo "$DEPLOYMENTS" | tail -n +2 | head -n $LIMIT | while IFS= read -r line; do
    if [ -n "$line" ]; then
        # Parse deployment URL (first column)
        DEPLOYMENT_URL=$(echo "$line" | awk '{print $1}')
        
        if [ -n "$DEPLOYMENT_URL" ] && [ "$DEPLOYMENT_URL" != "Age" ]; then
            # Extract deployment ID from URL (subdomain before .vercel.app)
            DEPLOYMENT_ID=$(echo "$DEPLOYMENT_URL" | sed -E 's/https?:\/\///' | sed -E 's/\.vercel\.app.*//')
            
            if [ -n "$DEPLOYMENT_ID" ]; then
                echo -e "${CYAN}Deployment:${NC} $DEPLOYMENT_URL"
                echo -e "${YELLOW}ID:${NC} $DEPLOYMENT_ID"
                echo ""
            fi
        fi
    fi
done

echo -e "${GREEN}=== Complete ===${NC}"
echo ""
echo -e "${YELLOW}Helpful commands:${NC}"
echo -e "${CYAN}  vercel inspect [deployment-url]${NC} - Get detailed deployment info"
echo -e "${CYAN}  vercel logs [deployment-url]${NC} - View deployment logs"
echo -e "${CYAN}  vercel ls --prod${NC} - List only production deployments"
echo -e "${CYAN}  vercel rollback [deployment-url]${NC} - Rollback to a previous deployment"
echo ""
echo -e "${YELLOW}Vercel Dashboard:${NC} https://vercel.com/dashboard"
