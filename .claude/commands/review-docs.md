# Ballerina Connector API Documentation Review

Please review and improve the API documentation in this Ballerina connector repository to ensure it's optimized for the low-code editor view in Ballerina Integrator (BI).

## Documentation Guidelines

### 1. **Simplify Function Descriptions**
- Make function descriptions simpler and more descriptive
- Avoid using complex/long code snippets in descriptions
- **Keep:** Brief 1-2 line code snippets that demonstrate function usage
- Focus on what the function does and when to use it
- **Keep:** Valid business context, cost implications, performance notes

**Example:**
```ballerina
# Before:
# Creates a table. The CreateTable operation adds a new table to your account. In an AWS account, table names must be
# unique within each Region. That is, you can have two tables with same name if you create the tables in different Regions.

# After:
# Creates a new table in your AWS account. Table names must be unique within each region.
```

### 2. **Add Comprehensive Type Descriptions**
- Add clear descriptions for enum TYPES (not individual values)
- The description can span multiple lines
- Explain what the enum is used for and provide context
- **IMPORTANT:** Do NOT add doc comments to individual enum values/fields - this causes build warnings when enum members are duplicated across different enums

**Example:**
```ballerina
# Before:
public enum ReturnValues {
    NONE, ALL_OLD, UPDATED_OLD, ALL_NEW, UPDATED_NEW
}

# After:
# Which item attributes to return in write operation responses.
# NONE - Return no attributes
# ALL_OLD - All attributes before the operation
# UPDATED_OLD - Only updated attributes before the operation
# ALL_NEW - All attributes after the operation
# UPDATED_NEW - Only updated attributes after the operation
public enum ReturnValues {
    NONE, ALL_OLD, UPDATED_OLD, ALL_NEW, UPDATED_NEW
}
```

**For Record Types:**
```ballerina
# Configuration for connecting to the service.
public type ConnectionConfig record {|
    # Service endpoint URL
    string endpoint;
    # Authentication credentials
    Credentials credentials;
|};
```

### 3. **Avoid Pro-Code Terminology**
- Remove references to "legacy parameter" - instead use: "Alternative method (use X for newer implementations)"
- Don't mention internal code constructs in user-facing descriptions
- Simplify technical jargon where possible

**Example:**
```ballerina
# Before:
# This is a legacy parameter. Use ProjectionExpression instead

# After:
# Specific attributes to retrieve (consider using `ProjectionExpression` for newer implementations)
```

### 4. **Improve Client/Object Descriptions**
- Make the main client class description comprehensive
- Describe the purpose and main capabilities
- Remove "Represents" prefix

**Example:**
```ballerina
# Before:
# Represents the Ballerina connector for ServiceName.
# This connector allows you to...

# After:
# Client for ServiceName, enabling [list main capabilities].
# Supports [key operations] and [additional features].
```

### 5. **Make Record Field Descriptions More Descriptive**
- Remove "Represents" prefix from record descriptions
- Be direct and descriptive
- **Keep:** "Valid Values:" listings
- **Keep:** Important details about costs, limits, behavior

**Example:**
```ballerina
# Before:
# Represents the AWS credentials.
public type AwsCredentials record {
    # AWS access key
    string accessKeyId;
};

# After:
# AWS credentials for authentication.
public type AwsCredentials record {
    # AWS access key ID
    string accessKeyId;
};
```

### 6. **Remove Redundant "Represents" Prefix**
- Don't start record/type descriptions with "Represents"
- Be direct: describe what it IS, not that it "represents" something

**Example:**
```ballerina
# Before:
# Represents the response after `WriteBatchItem` operation.

# After:
# Response from a batch write operation containing consumption metrics and unprocessed items.
```

### 7. **Handle Operation Name References**
- **Remove backticks** around operation names when describing them naturally
- **Keep backticks** for:
  - Field names (`TableName`, `LastEvaluatedKey`)
  - Return types
  - Specific attribute names that users need to recognize
  - Enum values when listing options

**Example:**
```ballerina
# Before:
# The response after `BatchWriteItem` operation

# After:
# Response from a batch write operation

# But KEEP backticks for field references:
# Use the value from `LastEvaluatedKey` in the next request
```

### 8. **Preserve Valuable Context**
- **DO KEEP:**
  - "Valid Values:" enumerations
  - Cost implications (e.g., "AWS KMS charges apply")
  - Performance notes (e.g., "More efficient than scan")
  - Business logic explanations
  - Multi-line detailed descriptions
  - Limits and quotas (e.g., "Maximum of 20 indexes")
  - Security implications

**Example:**
```ballerina
# GOOD - Keep this detail:
# Whether server-side encryption is enabled. If enabled (true), server-side encryption type is set to KMS
# and an AWS managed CMK is used (AWS KMS charges apply). If disabled (false) or not specified,
# server-side encryption is set to AWS owned CMK
```

### 9. **Keep Brief Usage Code Snippets**
- **DO KEEP:** Short 1-2 line code snippets that demonstrate function usage
- These brief examples help users understand how to call the function
- **DO REMOVE:** Complex multi-line code examples that belong in separate documentation
- **DO REMOVE:** Long code blocks showing complete implementations

**Example:**
```ballerina
# GOOD - Keep this brief usage example:
# Retrieves an item from the table.
# ```ballerina
# Item item = check dynamoDb->getItem("Users", {"id": "123"});
# ```

# BAD - Remove complex examples:
# (Multi-line code showing error handling, multiple operations, etc.)
```

## Reference Examples

Review these PRs for examples of correct documentation style:
- https://github.com/ballerina-platform/module-ballerinax-postgresql/pull/1241
- https://github.com/ballerina-platform/module-ballerina-crypto/pull/607

## Files to Review

Typically review these files in order:
1. **Client file** (e.g., `client.bal`, `caller.bal`)
   - Main client class description
   - All remote function descriptions

2. **Records file** (e.g., `records.bal`, `types.bal`)
   - All public record types
   - All record field descriptions
   - Remove "Represents" prefixes

3. **Constants/Enums file** (e.g., `constants.bal`, `enums.bal`)
   - All public enum types
   - Add descriptions for every enum value
   - Remove "Represents" prefixes

4. **Other API files** (e.g., `utils.bal`, `stream.bal`)
   - Public functions and types

## Critical Issues to Check

1. ❌ **Wrong service description** - Verify the client description matches the actual service (not copied from another connector)
2. ❌ **Doc comments on enum values** - Remove individual enum value doc comments (causes build warnings with duplicate members)
3. ❌ **Missing enum type descriptions** - Every enum type should have a clear description with value explanations
4. ❌ **"Represents" prefix** - Remove from all record and enum descriptions
5. ❌ **"Legacy parameter"** - Replace with friendlier alternative guidance
6. ❌ **Complex code snippets in descriptions** - Remove long/complex code examples (but keep brief 1-2 line usage snippets)
7. ❌ **Missing "Valid Values"** - Ensure enum fields in records reference valid enum values

## Task Checklist

- [ ] Fix main client/service class description
- [ ] Improve all remote function descriptions
- [ ] Remove all "Represents" prefixes from records and enums
- [ ] Add enum TYPE descriptions (explain values in the type comment, not individual value comments)
- [ ] Remove doc comments from individual enum values/fields
- [ ] Replace "legacy parameter" references with helpful alternatives
- [ ] Remove backticks from operation names (keep for field names)
- [ ] Verify "Valid Values:" listings are present for enum fields in records
- [ ] Fix any typos found during review
- [ ] Ensure multi-line helpful context is preserved

## Output Format

When complete, provide a summary of:
1. **Critical issues found** (especially wrong service descriptions)
2. **Statistics** (number of records fixed, enums improved, etc.)
3. **Key improvements made** with examples
4. **Files modified** with brief description of changes
