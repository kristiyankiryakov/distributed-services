# Understanding the Logger in Distributed Services

## Introduction
The logger in the `distributed-services` project, located in the `internal/log` directory, is a critical component designed for persistent, segmented logging. It is tailored for a distributed system environment where logs need to be stored efficiently, accessed quickly, and managed over time as data grows. This document aims to explain the logger's functionality, its components, and why it is built this way, using practical scenarios and examples.

## Core Components

### 1. Log Structure
The `Log` struct (defined in `log.go`) is the main entity that manages multiple log segments. It handles the high-level operations like appending records, reading records, and managing the lifecycle of log segments.

- **Key Fields**:
    - `mu`: A read-write mutex for thread-safe operations.
    - `Dir`: Directory path where log segments are stored.
    - `Config`: Configuration settings for segment sizes and initial offsets.
    - `activeSegment`: The currently active segment where new records are appended.
    - `segments`: A slice of all segments managed by this log.

### 2. Segment Structure
The `segment` struct (defined in `segment.go`) represents a single segment of the log, which is a pair of files: a store file for the actual log data and an index file for quick access to log entries.

- **Key Fields**:
    - `store`: Handles the actual data storage.
    - `index`: Manages offsets for quick lookup of records.
    - `baseOffset` and `nextOffset`: Define the range of offsets this segment covers.
    - `config`: Configuration for segment limits.

### 3. Configuration
The `Config` struct (defined in `config.go`) specifies limits and initial settings for log segments:
- `MaxStoreBytes`: Maximum size in bytes for the store file.
- `MaxIndexBytes`: Maximum size in bytes for the index file.
- `InitialOffset`: Starting offset for the first segment.

## Key Functionalities

### Initialization
When a new `Log` is created (`NewLog` function), it sets up the log directory and initializes segments based on existing files or creates a new segment if none exist. It reads the directory to find existing segment files, sorts them by their base offset, and loads them into memory.

### Appending Records
The `Append` method adds a new record to the active segment. If the active segment reaches its size limit (either store or index file), a new segment is created with the next offset. This ensures logs are split into manageable chunks.

### Reading Records
The `Read` method retrieves a record by its offset. It iterates through segments to find the correct one based on the offset range and then reads the record from the store file using the index for quick access.

### Segment Management
- **Creating New Segments**: When a segment is full, a new one is created (`newSegment` method) with a base offset starting after the last record of the previous segment.
- **Truncation**: The `Truncate` method removes segments with offsets below a specified value, useful for cleaning up old logs.
- **Reset and Removal**: Methods like `Reset` and `Remove` allow for clearing the log data entirely.

### Thread Safety
The logger uses a `sync.RWMutex` to ensure thread-safe operations, allowing multiple readers or a single writer at a time, which is crucial in a distributed environment with concurrent access.

## Why Segmented Logging?
Segmented logging is used for several reasons:
- **Performance**: Smaller files are faster to read and write compared to a single large file.
- **Scalability**: As log data grows, segments keep individual file sizes manageable.
- **Maintenance**: Old data can be easily removed by deleting older segments without affecting newer logs.
- **Recovery**: If a file gets corrupted, only one segment is affected, not the entire log.

## Practical Scenarios and Examples

### Scenario 1: Logging User Actions in a Distributed System
Imagine a distributed web application where multiple servers handle user requests. Each server logs user actions (like login, logout, purchases) to ensure traceability.

- **Implementation**:
  ```go
  // Initialize logger
  config := Config{}
  config.Segment.MaxStoreBytes = 1024 * 1024 // 1MB per segment
  config.Segment.MaxIndexBytes = 1024 * 100  // 100KB for index
  config.Segment.InitialOffset = 0
  logger, err := NewLog("/path/to/logs", config)
  if err != nil {
      panic(err)
  }

  // Log a user action
  record := &api.Record{
      Value:  []byte("User logged in: user123"),
      Offset: 0, // Will be set by Append
  }
  offset, err := logger.Append(record)
  if err != nil {
      panic(err)
  }
  fmt.Printf("Logged action at offset: %d\n", offset)
  ```

- **Explanation**: Here, each user action is appended to the log. If the current segment fills up (exceeds 1MB in store or 100KB in index), a new segment is automatically created.

### Scenario 2: Reading Logs for Debugging
A developer needs to debug an issue by reading logs around a specific offset where an error was reported.

- **Implementation**:
  ```go
  // Read a specific log entry
  offset := uint64(5) // Example offset where error occurred
  record, err := logger.Read(offset)
  if err != nil {
      panic(err)
  }
  fmt.Printf("Log at offset %d: %s\n", offset, string(record.Value))
  ```

- **Explanation**: The `Read` method finds the segment containing offset 5 and retrieves the exact record, allowing the developer to see the logged action or error message.

### Scenario 3: Cleaning Up Old Logs
To save disk space, a system administrator wants to remove logs older than a certain offset.

- **Implementation**:
  ```go
  // Truncate logs below offset 100
  err := logger.Truncate(100)
  if err != nil {
      panic(err)
  }
  fmt.Println("Old logs truncated successfully")
  ```

- **Explanation**: This removes all segments with records below offset 101, freeing up space while keeping newer logs intact.

## Conclusion
The logger in `distributed-services` is a robust, segmented logging system designed for distributed environments. It ensures efficient storage, quick access, and easy management of log data through its segmented approach. By understanding its components (`Log`, `segment`, `store`, `index`) and functionalities (append, read, truncate), developers can effectively use it for logging in various scenarios, from simple user action tracking to complex distributed system debugging.