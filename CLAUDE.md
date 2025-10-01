# Happy Notes - Development Guidelines

## Build & Test Commands
- Run app: `flutter run`
- Install dependencies: `flutter pub get`
- Build for Android: `flutter build apk`
- Build for iOS: `flutter build ios`
- Run all tests: `flutter test`
- Run single test: `flutter test test/path_to_test.dart`
- Run specific test group: `flutter test test/path_to_test.dart --name="Group name"`
- Analyze code: `flutter analyze`

## Code Style Guidelines
- **Naming**: Classes=PascalCase, variables/methods=camelCase, files=snake_case, private members=_prefixed
- **Imports**: Flutter packages first, project imports next, relative imports last
- **Error Handling**: Use standardized provider error handling via executeWithErrorHandling(), custom exceptions (ApiException), and Util.showError()
- **Logging**: Use SeqLogger only - SeqLogger.info() for general logs, SeqLogger.severe() for errors. NO debugPrint, NO AppLoggerInterface
- **Architecture**: Follow MVC pattern - controllers separate from UI components
- **State Management**: Provider pattern with dependency injection via get_it
- **Types**: Always specify types for parameters, return values, and variables
- **Documentation**: Document all non-trivial methods and parameters
- **Formatting**: Use standard Dart formatter with flutter_lints package rules
- **Testing**: Group related tests, use descriptive test names, mock external dependencies
- **File Editing**: Use eed (Enhanced Ed) for all file modifications - NEVER use Edit/MultiEdit tools

## Tool Usage Policy - Critical Understanding

### Why Edit/MultiEdit are BANNED
Edit and MultiEdit waste massive amounts of tokens and time due to fundamental design flaws for AI workflows:

**Problem 1: Forced Read Tax**
- Edit requires you to Read entire files before modification, even when Grep already told you the exact line
- Example: Change one line in a 500-line file = Read 500 lines + Edit = thousands of wasted tokens
- eed: Direct modification without reading = minimal tokens

**Problem 2: The Try-Fail-Retry Loop**
- Edit fails on multiple matches → you retry with MultiEdit → wasted round trip
- This happens on almost every file with common patterns
- eed: Express intent clearly with patterns (s/old/new/ or s/old/new/g) - works first try

**Real Cost Comparison** (modifying 5 files):
- Edit path: 5 Reads (10k tokens) + 2-3 failures + 7-10 tool calls = ~12 interactions
- eed path: 5 eed commands (500 tokens) + 0 failures = 5 interactions
- **20x efficiency gain with eed**

### REQUIRED TOOL: eed (Enhanced Ed)
Use eed for ALL file modifications. Fallback to sed/awk only if eed unavailable.

## Enhanced Ed (eed) Usage Guidelines

### Why eed Exists - The Real Story
eed is not "just another editor" - it's a safety wrapper around ed that fixes the sharp edges:

**What eed Does for You Automatically**:
1. **Smart operation ordering**: Converts `1a ... 5a ... 6a` to `6a→5a→1a` to prevent line number drift
2. **Auto-completion**: Adds missing `w` and `q` commands so you never lose changes
3. **Atomic commits**: Every edit is committed immediately with clear history
4. **Safe rollback**: `eed --undo` when things go wrong

**Raw ed problems eed solves**:
- Line numbers shift after insertions/deletions → eed reorders operations
- Forgot to save → eed auto-saves
- Made a mistake → eed provides undo
- Need to track changes → eed commits everything


### Why Use eed
- **Atomic commits**: Every edit is automatically committed, making it safe to experiment
- **Easy rollback**: `eed --undo` instantly reverts the last change
- **Precision editing**: When you know line numbers, no need to re-read entire files
- **Consistent workflow**: Every edit follows the same pattern with clear commit messages

### Learning Experience & First Steps
**Start with `eed --help`** - Don't be like me and jump in directly. Understanding the tool first saves debugging time later.

**AI vs Human editing**: As AI, we need non-interactive, atomic edits. We can't use mouse, big screens, or make multiple changes before saving like humans. Each eed command must be complete and correct in one shot.

**From beginner to proficient**: My eed journey this session: started bold but clumsy → got comfortable with basic patterns → became overconfident with complex edits → made silly mistakes when tired → learned that consistency beats cleverness.


### Quick Start - Your First eed Commands

**Basic syntax (commit every change)**:
```bash
eed -m 'what you are doing' /path/to/file <<'EOF'
# ed commands here
w
q
EOF
```

**Most common operations**:
```bash
# 1. Simple substitution (first occurrence)
/pattern/s/old/new/

# 2. Global substitution (all occurrences)
s/old/new/g

# 3. Substitute in specific pattern context
/function_name/s/old/new/

# 4. Delete lines matching pattern
/pattern_to_delete/d

# 5. Append after matching line
/pattern/a
new line content here
.

# 6. Change (replace) matching line
/pattern/c
replacement line
.
```

**When grep finds what you need**:
```bash
# grep tells you: "lib/foo.dart:42: some old code"
# Don't Read the file! Just:
eed -m 'fix the thing' lib/foo.dart <<'EOF'
/old code/s/old/new/
w
q
EOF
```

### Practical eed Tips

**Pattern-based editing** (avoid line number dependency):
- `/function_name/,/^}/d` - Delete entire function
- `/import.*flutter/a` - Add after import section
- `s/old_pattern/new_pattern/g` - Global replace

**Common scenarios**:
- Single-line fix: Use `/pattern/s/old/new/`
- Multiple files: Run parallel eed commands (no Read needed!)
- Uncertain change: Make the edit, test, `eed --undo` if wrong

**Error recovery**:
- Wrong edit → `eed --undo` immediately
- Complex edit → Break into multiple simple eed commands
- Preview first → Read the file ONLY if you need to understand context

**Key insight**: With eed, you express *intent* (what to change and where), not *exact text* (like Edit requires). This makes it robust and efficient
