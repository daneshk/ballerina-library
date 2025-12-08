// API Documentation Review Tool
//
// This tool uses Claude API to review and improve Ballerina connector API documentation.
// It supports both full and incremental review modes.
//
// Usage:
//   bal run -- full <repo-path> <prompt-file> [dry-run]
//   bal run -- incremental <repo-path> <prompt-file> <commit-sha> [dry-run]

import ballerina/file;
import ballerina/http;
import ballerina/io;
import ballerina/os;

const string ANTHROPIC_API_URL = "https://api.anthropic.com/v1/messages";
const string CLAUDE_MODEL = "claude-sonnet-4-5-20250929";
const int MAX_TOKENS = 16000;
const string ANTHROPIC_VERSION = "2023-06-01";

// File patterns to search for
final string[] FILE_PATTERNS = ["client.bal", "types.bal", "records.bal", "constants.bal", "enums.bal", "utils.bal"];

type MessageRequest record {
    string model;
    int max_tokens;
    Message[] messages;
};

type Message record {
    string role;
    string content;
};

type MessageResponse record {
    string id;
    string 'type;
    string role;
    Content[] content;
    string model;
    string stop_reason?;
    map<json> usage?;
};

type Content record {
    string 'type;
    string text;
};

// Read the review prompt from file
function readReviewPrompt(string promptFile) returns string|error {
    return io:fileReadString(promptFile);
}

// Read file content
function readFileContent(string filePath) returns string|error {
    return io:fileReadString(filePath);
}

// Write content to file
function writeFileContent(string filePath, string content) returns error? {
    check io:fileWriteString(filePath, content);
}

// Find Ballerina files to review
function findBallerinaFiles(string repoPath) returns string[]|error {
    string ballerinaDir = repoPath + "/ballerina";

    // Check if ballerina directory exists
    if !check file:test(ballerinaDir, file:EXISTS) {
        return [];
    }

    string[] filesToReview = [];

    // Search for each pattern
    foreach string pattern in FILE_PATTERNS {
        string[] matches = check findFilesRecursive(ballerinaDir, pattern);
        filesToReview.push(...matches);
    }

    return filesToReview;
}

// Recursively find files matching a pattern
function findFilesRecursive(string directory, string pattern) returns string[]|error {
    string[] matchedFiles = [];

    file:MetaData[] entries = check file:readDir(directory);

    foreach file:MetaData entry in entries {
        if entry.dir {
            // Recursively search subdirectories
            string[] subMatches = check findFilesRecursive(entry.absPath, pattern);
            matchedFiles.push(...subMatches);
        } else {
            // Check if file name matches pattern
            string fileName = getFileName(entry.absPath);
            if fileName == pattern {
                matchedFiles.push(entry.absPath);
            }
        }
    }

    return matchedFiles;
}

// Extract file name from path
function getFileName(string path) returns string {
    int? lastSlashIndex = path.lastIndexOf("/");
    if lastSlashIndex is int {
        return path.substring(lastSlashIndex + 1);
    }
    return path;
}

// Review a file using Claude API
function reviewFileWithClaude(http:Client claudeClient, string apiKey, string filePath, string reviewPrompt) returns string|error {

    string fileContent = check readFileContent(filePath);

    string prompt = string `${reviewPrompt}

## File to Review

Please review and improve the following Ballerina file according to the guidelines above.

File: ${filePath}

${"```"}ballerina
${fileContent}
${"```"}

Please provide the complete improved file content with all the documentation improvements applied.
Return ONLY the improved file content, without any explanations or markdown code blocks.`;

    io:println("  Reviewing " + filePath + "...");

    MessageRequest request = {
        model: CLAUDE_MODEL,
        max_tokens: MAX_TOKENS,
        messages: [
            {
                role: "user",
                content: prompt
            }
        ]
    };

    map<string> headers = {
        "x-api-key": apiKey,
        "anthropic-version": ANTHROPIC_VERSION,
        "content-type": "application/json"
    };

    MessageResponse response = check claudeClient->post("/messages", request, headers);

    if response.content.length() > 0 {
        return response.content[0].text;
    }

    return error("No response content from Claude API");
}

// Run full review mode
function runFullReview(string repoPath, string promptFile, boolean dryRun, string apiKey) returns error? {
    io:println("=== Full Review Mode ===");
    io:println();

    // Initialize Claude client
    http:Client claudeClient = check new (ANTHROPIC_API_URL, {
        httpVersion: http:HTTP_1_1,
        timeout: 300
    });

    // Read review prompt
    io:println("Reading review prompt...");
    string reviewPrompt = check readReviewPrompt(promptFile);

    // Find Ballerina files to review
    io:println("Finding Ballerina files to review...");
    string[] filesToReview = check findBallerinaFiles(repoPath);

    if filesToReview.length() == 0 {
        io:println("No Ballerina files found to review");
        return;
    }

    io:println("Found " + filesToReview.length().toString() + " files to review");
    io:println();

    // Review each file
    int filesModified = 0;
    foreach string filePath in filesToReview {
        do {
            if dryRun {
                io:println("  [DRY RUN] Would review: " + filePath);
            } else {
                string improvedContent = check reviewFileWithClaude(claudeClient, apiKey, filePath, reviewPrompt);

                // Write improved content back
                check writeFileContent(filePath, improvedContent);
                io:println("  ✓ Updated " + filePath);
                filesModified += 1;
            }
        } on fail error e {
            io:println("  ✗ Error reviewing " + filePath + ": " + e.message());
            continue;
        }
    }

    io:println();
    io:println("Review complete! Modified " + filesModified.toString() + " files.");

    if dryRun {
        io:println("[DRY RUN] No files were actually modified.");
    }
}

// Run incremental review mode
function runIncrementalReview(string repoPath, string promptFile, string commitSha, boolean dryRun, string apiKey) returns error? {
    io:println("=== Incremental Review Mode ===");
    io:println("Commit SHA: " + commitSha);
    io:println();

    // Initialize Claude client
    http:Client claudeClient = check new (ANTHROPIC_API_URL, {
        httpVersion: http:HTTP_1_1,
        timeout: 300
    });

    // Read review prompt
    io:println("Reading review prompt...");
    string reviewPrompt = check readReviewPrompt(promptFile);

    // Read current review state
    io:println("Reading review state...");
    ReviewState state = check readReviewState(repoPath);

    // Find Ballerina files to review
    io:println("Finding Ballerina files to review...");
    string[] allFiles = check findBallerinaFiles(repoPath);

    if allFiles.length() == 0 {
        io:println("No Ballerina files found to review");
        return;
    }

    // Filter to only changed files
    string[] filesToReview = [];
    foreach string filePath in allFiles {
        boolean changed = check hasFileChanged(filePath, state);
        if changed {
            filesToReview.push(filePath);
        }
    }

    io:println("Found " + allFiles.length().toString() + " total files, " +
               filesToReview.length().toString() + " changed since last review");
    io:println();

    if filesToReview.length() == 0 {
        io:println("No changed files to review");
        return;
    }

    // Review each changed file
    int filesModified = 0;
    foreach string filePath in filesToReview {
        do {
            if dryRun {
                io:println("  [DRY RUN] Would review: " + filePath);
            } else {
                string improvedContent = check reviewFileWithClaude(claudeClient, apiKey, filePath, reviewPrompt);

                // Write improved content back
                check writeFileContent(filePath, improvedContent);
                io:println("  ✓ Updated " + filePath);

                // Update state
                state = check markFileReviewed(state, filePath);
                filesModified += 1;
            }
        } on fail error e {
            io:println("  ✗ Error reviewing " + filePath + ": " + e.message());
            continue;
        }
    }

    // Update state file with commit info
    if !dryRun && filesModified > 0 {
        state.lastReviewedCommit = commitSha;
        state.lastReviewTimestamp = getCurrentTimestamp();
        check writeReviewState(repoPath, state);
        io:println("  ✓ Updated review state");
    }

    io:println();
    io:println("Review complete! Modified " + filesModified.toString() + " files.");

    if dryRun {
        io:println("[DRY RUN] No files were actually modified.");
    }
}

// Print usage information
function printUsage() {
    io:println("Usage:");
    io:println("  Full review:");
    io:println("    bal run -- full <repo-path> <prompt-file> [dry-run]");
    io:println();
    io:println("  Incremental review:");
    io:println("    bal run -- incremental <repo-path> <prompt-file> <commit-sha> [dry-run]");
    io:println();
    io:println("Options:");
    io:println("  dry-run      Preview what would be reviewed without making changes");
    io:println("  <commit-sha> Git commit SHA for incremental review tracking (required for incremental mode)");
}

// Main function
public function main(string... args) returns error? {
    // Check minimum arguments
    if args.length() < 3 {
        printUsage();
        return error("Insufficient arguments");
    }

    string mode = args[0];
    string repoPath = args[1];
    string promptFile = args[2];

    // Check for API key
    string apiKey = os:getEnv("ANTHROPIC_API_KEY");
    if apiKey == "" {
        io:println("Error: ANTHROPIC_API_KEY environment variable not set");
        return error("ANTHROPIC_API_KEY not set");
    }

    // Validate inputs
    if !check file:test(repoPath, file:IS_DIR) {
        io:println("Error: Repository path not found: " + repoPath);
        return error("Repository path not found");
    }

    if !check file:test(promptFile, file:EXISTS) {
        io:println("Error: Prompt file not found: " + promptFile);
        return error("Prompt file not found");
    }

    // Route to appropriate mode
    if mode == "full" {
        // Parse optional dry-run flag for full mode
        boolean dryRun = args.length() > 3 && args[3] == "dry-run";
        check runFullReview(repoPath, promptFile, dryRun, apiKey);
    } else if mode == "incremental" {
        // For incremental mode, commit-sha is required as 4th argument
        if args.length() < 4 {
            io:println("Error: commit-sha is required for incremental mode");
            printUsage();
            return error("Missing commit-sha");
        }
        string commitSha = args[3];
        // Parse optional dry-run flag for incremental mode
        boolean dryRun = args.length() > 4 && args[4] == "dry-run";
        check runIncrementalReview(repoPath, promptFile, commitSha, dryRun, apiKey);
    } else {
        io:println("Error: Invalid mode '" + mode + "'. Must be 'full' or 'incremental'");
        printUsage();
        return error("Invalid mode");
    }
}
