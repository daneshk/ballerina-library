# Quick Start Guide

Get started with the API Documentation Reviewer in 3 easy steps.

## Step 1: Set Up Environment

Set your Claude API key:
```bash
export ANTHROPIC_API_KEY="your-claude-api-key"
```

## Step 2: Run a Review

### Option A: Full Review
Review all documentation files in a repository:

```bash
cd api_doc_reviewer

# Preview what would be reviewed
bal run -- full \
  /path/to/target-repo \
  /path/to/review-guidelines.md \
  --dry-run

# Run the actual review
bal run -- full \
  /path/to/target-repo \
  /path/to/review-guidelines.md
```

### Option B: Incremental Review
Review only changed files (faster for large repos):

```bash
bal run -- incremental \
  /path/to/target-repo \
  /path/to/review-guidelines.md \
  --commit-sha $(cd /path/to/target-repo && git rev-parse HEAD)
```

## Step 3: Review the Changes

The scripts will update the documentation files in place. Review the changes:

```bash
cd /path/to/target-repo
git diff
```

If satisfied with the changes:
```bash
git add .
git commit -m "Improve API documentation"
```

## That's It! 🎉

Your API documentation has been reviewed and improved according to the guidelines.

---

## 🚀 Using GitHub Actions

For automated reviews, use the provided workflows:

### Manual Review (workflow_dispatch)
1. Go to Actions tab in your repository
2. Select "Review API Documentation" workflow
3. Click "Run workflow"
4. Enter target repository name
5. Click "Run workflow" button

The workflow will:
- Review all documentation
- Create a PR with improvements
- Optionally add automated workflow to target repo

### Automated Reviews (on merge)
Once set up, the automated workflow will:
- Trigger on every merge to main
- Review only changed files
- Create PR if improvements needed

---

## 📋 Common Commands

| Task | Command |
|------|---------|
| Preview review (dry-run) | `bal run -- full /path/to/repo guidelines.md --dry-run` |
| Full review | `bal run -- full /path/to/repo guidelines.md` |
| Incremental review | `bal run -- incremental /path/to/repo guidelines.md --commit-sha <sha>` |

---

## 🎯 Example: Review a Ballerina Connector

```bash
# Set API key
export ANTHROPIC_API_KEY="sk-ant-..."

# Review the AWS S3 connector
bal run -- full \
  ~/projects/module-ballerinax-aws.s3 \
  ~/.claude/commands/review-docs.md

# Check what changed
cd ~/projects/module-ballerinax-aws.s3
git diff ballerina/
```

---

## 📂 What Files Get Reviewed?

The scripts automatically find and review:
- `ballerina/client.bal`
- `ballerina/types.bal`
- `ballerina/records.bal`
- `ballerina/constants.bal`
- `ballerina/enums.bal`
- `ballerina/utils.bal`

Files are searched recursively in the `ballerina/` directory.

---

## 🛠️ Troubleshooting

### Can't find files to review?
Make sure your target repository has a `ballerina/` directory with `.bal` files.

### API key not working?
```bash
# Check if it's set
echo $ANTHROPIC_API_KEY

# Set it again
export ANTHROPIC_API_KEY="your-key"
```

### Want to see what changed?
```bash
cd /path/to/target-repo
git diff ballerina/
```

---

## 📚 Need More Help?

See [README.md](README.md) for:
- Detailed usage instructions
- GitHub Actions integration
- State file format
- Complete troubleshooting guide
