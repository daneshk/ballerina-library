#!/bin/bash

###############################################################################
# Deploy API Documentation Review Command to Multiple Ballerina Repositories
#
# This script deploys the /review-docs slash command to multiple repositories.
# It can work with both local repositories and remote repositories (will clone).
#
# Usage:
#   ./deploy-docs-review-command.sh repos.txt
#   ./deploy-docs-review-command.sh repos.txt --commit --push
#
# Options:
#   --commit    Commit the changes to git
#   --push      Push the changes to remote (requires --commit)
#   --dry-run   Show what would be done without making changes
###############################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parse command line arguments
REPO_LIST_FILE="$1"
DO_COMMIT=false
DO_PUSH=false
DRY_RUN=false

shift || true
while [[ $# -gt 0 ]]; do
    case $1 in
        --commit)
            DO_COMMIT=true
            shift
            ;;
        --push)
            DO_PUSH=true
            DO_COMMIT=true  # Push requires commit
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        *)
            echo -e "${RED}Error: Unknown option $1${NC}"
            exit 1
            ;;
    esac
done

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROMPT_SOURCE="$SCRIPT_DIR/../.claude/commands/review-docs.md"

# Validation
if [[ -z "$REPO_LIST_FILE" ]]; then
    echo -e "${RED}Error: No repository list file provided${NC}"
    echo "Usage: $0 <repo-list-file> [--commit] [--push] [--dry-run]"
    echo ""
    echo "Example repo-list-file format:"
    echo "  /path/to/local/repo1"
    echo "  /path/to/local/repo2"
    echo "  https://github.com/org/repo3.git"
    exit 1
fi

if [[ ! -f "$REPO_LIST_FILE" ]]; then
    echo -e "${RED}Error: Repository list file not found: $REPO_LIST_FILE${NC}"
    exit 1
fi

if [[ ! -f "$PROMPT_SOURCE" ]]; then
    echo -e "${RED}Error: Source prompt file not found: $PROMPT_SOURCE${NC}"
    exit 1
fi

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}Ballerina API Docs Review Command Deployment${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""
echo -e "${YELLOW}Configuration:${NC}"
echo "  Repository list: $REPO_LIST_FILE"
echo "  Source prompt: $PROMPT_SOURCE"
echo "  Commit changes: $DO_COMMIT"
echo "  Push changes: $DO_PUSH"
echo "  Dry run: $DRY_RUN"
echo ""

# Create a temporary directory for cloned repos
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Statistics
total_repos=0
successful_repos=0
failed_repos=0
skipped_repos=0

# Process each repository
while IFS= read -r repo_path || [[ -n "$repo_path" ]]; do
    # Skip empty lines and comments
    [[ -z "$repo_path" ]] && continue
    [[ "$repo_path" =~ ^[[:space:]]*# ]] && continue

    total_repos=$((total_repos + 1))

    echo -e "${BLUE}----------------------------------------${NC}"
    echo -e "${BLUE}[$total_repos] Processing: $repo_path${NC}"

    # Determine if it's a URL or local path
    if [[ "$repo_path" =~ ^https?:// ]] || [[ "$repo_path" =~ ^git@ ]]; then
        # It's a remote repository - clone it
        repo_name=$(basename "$repo_path" .git)
        local_path="$TEMP_DIR/$repo_name"

        echo "  Cloning repository..."
        if $DRY_RUN; then
            echo "  [DRY RUN] Would clone: $repo_path to $local_path"
        else
            if git clone "$repo_path" "$local_path" &>/dev/null; then
                echo -e "  ${GREEN}✓${NC} Cloned successfully"
            else
                echo -e "  ${RED}✗${NC} Failed to clone repository"
                failed_repos=$((failed_repos + 1))
                continue
            fi
        fi
    else
        # It's a local path
        local_path="$repo_path"

        if [[ ! -d "$local_path" ]]; then
            echo -e "  ${RED}✗${NC} Directory not found: $local_path"
            failed_repos=$((failed_repos + 1))
            continue
        fi

        if [[ ! -d "$local_path/.git" ]]; then
            echo -e "  ${YELLOW}⚠${NC}  Not a git repository: $local_path"
            skipped_repos=$((skipped_repos + 1))
            continue
        fi
    fi

    # Create .claude/commands directory
    claude_dir="$local_path/.claude/commands"
    target_file="$claude_dir/review-docs.md"

    echo "  Creating .claude/commands directory..."
    if $DRY_RUN; then
        echo "  [DRY RUN] Would create: $claude_dir"
    else
        mkdir -p "$claude_dir"
        echo -e "  ${GREEN}✓${NC} Directory ready"
    fi

    # Copy the prompt file
    echo "  Copying review-docs.md..."
    if $DRY_RUN; then
        echo "  [DRY RUN] Would copy: $PROMPT_SOURCE -> $target_file"
    else
        cp "$PROMPT_SOURCE" "$target_file"
        echo -e "  ${GREEN}✓${NC} File copied"
    fi

    # Git operations
    if $DO_COMMIT; then
        cd "$local_path"

        # Check if there are changes
        if git diff --quiet "$target_file" 2>/dev/null && git diff --cached --quiet "$target_file" 2>/dev/null; then
            echo -e "  ${YELLOW}⚠${NC}  No changes to commit (file already exists)"
        else
            echo "  Committing changes..."
            if $DRY_RUN; then
                echo "  [DRY RUN] Would commit changes"
            else
                git add "$target_file"
                git commit -m "Add API documentation review command

Add /review-docs slash command for consistent API documentation review
across Ballerina connectors for low-code editor compatibility.

Co-Authored-By: Claude <noreply@anthropic.com>" || true
                echo -e "  ${GREEN}✓${NC} Changes committed"
            fi

            if $DO_PUSH; then
                echo "  Pushing changes..."
                if $DRY_RUN; then
                    echo "  [DRY RUN] Would push to remote"
                else
                    if git push; then
                        echo -e "  ${GREEN}✓${NC} Changes pushed"
                    else
                        echo -e "  ${RED}✗${NC} Failed to push changes"
                    fi
                fi
            fi
        fi

        cd - > /dev/null
    fi

    echo -e "  ${GREEN}✓${NC} Repository processed successfully"
    successful_repos=$((successful_repos + 1))

done < "$REPO_LIST_FILE"

# Summary
echo ""
echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}Deployment Summary${NC}"
echo -e "${BLUE}======================================${NC}"
echo "  Total repositories: $total_repos"
echo -e "  ${GREEN}Successful: $successful_repos${NC}"
if [[ $failed_repos -gt 0 ]]; then
    echo -e "  ${RED}Failed: $failed_repos${NC}"
fi
if [[ $skipped_repos -gt 0 ]]; then
    echo -e "  ${YELLOW}Skipped: $skipped_repos${NC}"
fi
echo ""

if $DRY_RUN; then
    echo -e "${YELLOW}This was a dry run. No changes were made.${NC}"
    echo "Run without --dry-run to apply changes."
    echo ""
fi

if [[ $failed_repos -gt 0 ]]; then
    exit 1
fi

echo -e "${GREEN}Deployment completed successfully!${NC}"
echo ""
echo "Next steps:"
echo "  1. Test the command in one repository: /review-docs"
echo "  2. If issues found, update the prompt and re-run this script"
echo "  3. Create PRs for the changes if needed"
