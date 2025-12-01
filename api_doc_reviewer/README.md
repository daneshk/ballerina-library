# API Documentation Reviewer

A Ballerina package for automatically reviewing and improving API documentation in Ballerina connector repositories using Claude AI.

## 📋 Overview

This package contains Ballerina scripts that use the Claude API to review API documentation and suggest improvements based on predefined guidelines. It's designed to work with Ballerina connector projects and can be integrated into CI/CD workflows.

## 📁 Package Contents

- **`main.bal`** - Main entry point with full and incremental review modes
- **`review-state.bal`** - State management utilities for incremental reviews
- **`repos-example.txt`** - Example repository list for batch processing
- **`Ballerina.toml`** - Package configuration

## 🚀 Prerequisites

- **Ballerina** - Latest version ([Install Ballerina](https://ballerina.io/downloads/))
- **Claude API Key** - Set as environment variable `ANTHROPIC_API_KEY`
- **Review Guidelines** - A markdown file containing documentation review guidelines

## 📖 Usage

### Full Review

Review all documentation files in a repository:

```bash
export ANTHROPIC_API_KEY="your-api-key"

bal run -- full \
  /path/to/target-repo \
  /path/to/review-guidelines.md
```

**With dry-run:**
```bash
bal run -- full \
  /path/to/target-repo \
  /path/to/review-guidelines.md \
  --dry-run
```

### Incremental Review

Review only files that have changed since the last review:

```bash
bal run -- incremental \
  /path/to/target-repo \
  /path/to/review-guidelines.md \
  --commit-sha <git-commit-sha>
```

The incremental mode:
- Tracks which files have been reviewed using checksums
- Stores state in `.api-docs-review-state.json` in the target repository
- Only processes files that have changed since the last review
- Automatically updates the state file after each review

### Dry Run Mode

Both modes support `--dry-run` to preview which files would be reviewed without making changes:

```bash
bal run -- full \
  /path/to/repo \
  /path/to/guidelines.md \
  --dry-run
```

## 🎯 What Gets Reviewed

The scripts automatically find and review these Ballerina files:
- `client.bal`
- `types.bal`
- `records.bal`
- `constants.bal`
- `enums.bal`
- `utils.bal`

Files are searched recursively in the `ballerina/` directory of the target repository.

## 🔄 GitHub Actions Integration

This package is designed to work with GitHub Actions workflows. See the workflows in `.github/workflows/`:

### Manual Review Workflow (`review-api-docs-workflow.yml`)
Trigger a manual review of any Ballerina connector repository:
- Supports specifying target repository and branch
- Automatically creates a PR with improvements
- Can optionally add automated review workflow to target repo

### Automated Review on Merge (`review-api-docs-on-merge-workflow.yml`)
Automatically reviews documentation when changes are merged:
- Triggers on merge to main branch
- Only reviews changed files (incremental)
- Creates PR with improvements if needed

## 📝 Review Guidelines

The review scripts require a guidelines file (typically `.claude/commands/review-docs.md`) that defines:
- Documentation style requirements
- Best practices for API docs
- Specific improvements to apply
- Examples of good vs. bad documentation

The scripts send these guidelines along with the file content to Claude for analysis.

## 🛠️ Deployment Script

The deployment script is located at `.github/scripts/deploy-docs-review-command.sh` and can be used to:
- Deploy review configurations to multiple repositories
- Set up automated workflows
- Batch process multiple connectors

## 📊 Example Output

```
Reading review prompt...
Finding Ballerina files to review...
Found 5 files to review

  Reviewing /path/to/repo/ballerina/client.bal...
  ✓ Updated /path/to/repo/ballerina/client.bal
  Reviewing /path/to/repo/ballerina/types.bal...
  ✓ Updated /path/to/repo/ballerina/types.bal
  ...

Review complete! Modified 5 files.
```

## 🔧 Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `ANTHROPIC_API_KEY` | Yes | Your Claude API key for making API requests |

## 📋 State File Format

The incremental review script creates `.api-docs-review-state.json`:

```json
{
  "lastReviewedCommit": "abc123...",
  "lastReviewTimestamp": "2024-01-01T12:00:00Z",
  "reviewedFiles": {
    "ballerina/client.bal": {
      "checksum": "sha256-hash",
      "lastReviewed": "2024-01-01T12:00:00Z"
    }
  }
}
```

## 🎓 Use Cases

### Scenario 1: One-time Review of a Repository
```bash
# Review all documentation in a connector
bal run -- full \
  ~/projects/module-ballerinax-aws.s3 \
  .claude/commands/review-docs.md
```

### Scenario 2: Incremental Review After Changes
```bash
# Only review files changed in latest commit
bal run -- incremental \
  ~/projects/module-ballerinax-aws.s3 \
  .claude/commands/review-docs.md \
  --commit-sha $(cd ~/projects/module-ballerinax-aws.s3 && git rev-parse HEAD)
```

### Scenario 3: CI/CD Integration
Use the GitHub Actions workflows to automatically review documentation on every merge or trigger manual reviews via workflow dispatch.

## 🐛 Troubleshooting

### "ANTHROPIC_API_KEY not set"
Set the environment variable before running:
```bash
export ANTHROPIC_API_KEY="your-api-key"
```

### "No Ballerina files found to review"
- Ensure the repository has a `ballerina/` directory
- Check that it contains files matching the expected patterns
- Verify you're pointing to the correct repository path

### "Prompt file not found"
- Verify the path to your review guidelines file
- Ensure the file exists and is readable

### API Rate Limits
If you hit Claude API rate limits:
- Process fewer files at a time
- Add delays between requests
- Use incremental mode to process only changed files

## 🤝 Contributing

To improve the documentation review process:
1. Update the review guidelines in your guidelines file
2. Test with a sample repository
3. Run in dry-run mode first to preview changes
4. Submit improvements via PR

## 📞 Support

For issues or questions:
- Check the troubleshooting section above
- Review script output for error messages
- Test with `--dry-run` first
- Verify API key and permissions

## 🔗 Related Resources

- [Ballerina Documentation](https://ballerina.io/learn/)
- [Claude API Documentation](https://docs.anthropic.com/)
- [Ballerina Connectors](https://central.ballerina.io/)
