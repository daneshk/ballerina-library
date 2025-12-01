// State management for incremental API doc reviews
//
// This module handles tracking which files have been reviewed and when,
// enabling incremental reviews that only process changed files.

import ballerina/file;
import ballerina/io;
import ballerina/time;
import ballerina/crypto;

const string STATE_FILE_NAME = ".api-docs-review-state.json";

// Review state structure
public type ReviewState record {
    string lastReviewedCommit;
    string lastReviewTimestamp;
    map<FileReviewInfo> reviewedFiles;
};

public type FileReviewInfo record {
    string checksum;
    string lastReviewed;
};

// Read the current review state from the state file
public function readReviewState(string repoPath) returns ReviewState|error {
    string stateFilePath = repoPath + "/" + STATE_FILE_NAME;

    if !check file:test(stateFilePath, file:EXISTS) {
        // No state file exists, return empty state
        return {
            lastReviewedCommit: "",
            lastReviewTimestamp: "",
            reviewedFiles: {}
        };
    }

    json stateJson = check io:fileReadJson(stateFilePath);
    ReviewState state = check stateJson.cloneWithType();
    return state;
}

// Write the review state to the state file
public function writeReviewState(string repoPath, ReviewState state) returns error? {
    string stateFilePath = repoPath + "/" + STATE_FILE_NAME;
    check io:fileWriteJson(stateFilePath, state.toJson());
}

// Calculate SHA256 checksum of a file
public function calculateFileChecksum(string filePath) returns string|error {
    byte[] fileContent = check io:fileReadBytes(filePath);
    byte[] hash = crypto:hashSha256(fileContent);
    return hash.toBase16();
}

// Get the current git commit SHA
public function getCurrentCommitSha(string repoPath) returns string|error {
    // This will be called via bash in the main script
    return "";
}

// Check if a file has changed since last review
public function hasFileChanged(string filePath, ReviewState state) returns boolean|error {
    // Calculate current checksum
    string currentChecksum = check calculateFileChecksum(filePath);

    // Check if file was reviewed before
    if !state.reviewedFiles.hasKey(filePath) {
        return true; // New file, needs review
    }

    FileReviewInfo previousReview = state.reviewedFiles.get(filePath);
    return currentChecksum != previousReview.checksum;
}

// Update state after reviewing a file
public function markFileReviewed(ReviewState state, string filePath) returns ReviewState|error {
    string checksum = check calculateFileChecksum(filePath);
    string timestamp = time:utcNow()[0].toString();

    state.reviewedFiles[filePath] = {
        checksum: checksum,
        lastReviewed: timestamp
    };

    return state;
}

// Get current timestamp
public function getCurrentTimestamp() returns string {
    return time:utcNow()[0].toString();
}
