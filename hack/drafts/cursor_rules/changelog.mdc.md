---
description: Changelog Management Guidelines for Codegen Lab
globs: docs/changelog.md,*.md
alwaysApply: false
---
# Changelog Management Guidelines

Standards and workflows for maintaining the project changelog, including automation for generating entries from Git history.

<rule>
name: changelog_management
description: Standards for maintaining and updating the project changelog
filters:
  # Match changelog file
  - type: file_path
    pattern: "docs/changelog\\.md$"
  # Match commits and PR templates
  - type: file_path
    pattern: "\\.github/PULL_REQUEST_TEMPLATE\\.md$"
  - type: file_path
    pattern: "\\.github/COMMIT_TEMPLATE\\.md$"

actions:
  - type: suggest
    message: |
      # Changelog Management Best Practices

      This project follows the [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) format and [Semantic Versioning](https://semver.org/spec/v2.0.0.html) principles.

      ## Structure Guidelines

      1. **Core Structure**:
         - Always keep the `[Unreleased]` section at the top
         - Group changes by type: Added, Changed, Deprecated, Removed, Fixed, Security
         - Include version number and release date for released versions
         - Maintain link references at the bottom for comparing versions

      2. **Entry Format**:
         - Use bullet points for each change
         - Begin with a verb in present tense (Add, Fix, Update, Remove)
         - Be concise but descriptive
         - Reference issue/PR numbers when applicable

      3. **Release Process**:
         - When releasing, rename `[Unreleased]` to the new version number and date
         - Create a new empty `[Unreleased]` section at the top
         - Update the version comparison links at the bottom

      ## Automatic Update Workflow

      ### Generating Changes from Git History

      Use this tool to automatically generate changelog entries based on Git commits:

      ```bash
      # Generate changelog entries from commits between main and your branch
      make changelog-update BRANCH=feature-branch
      # Or manually with:
      uv run python scripts/update_changelog.py --branch=feature-branch
      ```

      This will:
      1. Compare the commits between main and your feature branch
      2. Parse commit messages that follow conventional commits format
      3. Group them by change type (feat→Added, fix→Fixed, etc.)
      4. Insert them into the `[Unreleased]` section

      ### Commit Message Format for Automatic Changelog Updates

      Use conventional commits format for automatic changelog generation:

      ```
      <type>(<scope>): <description>

      [optional body]

      [optional footer(s)]
      ```

      Where `<type>` is one of:
      - `feat`: (Added) - New feature
      - `fix`: (Fixed) - Bug fix
      - `docs`: (Changed) - Documentation changes
      - `style`: (Changed) - Formatting changes
      - `refactor`: (Changed) - Code refactoring
      - `perf`: (Changed) - Performance improvements
      - `test`: (Changed) - Test additions/changes
      - `chore`: (Changed) - Build process or tool changes
      - `deprecate`: (Deprecated) - Mark features for removal
      - `remove`: (Removed) - Remove features or files
      - `security`: (Security) - Security fixes

      Add `BREAKING CHANGE:` in the commit body for breaking changes.

examples:
  - input: |
      # Bad: Missing change type category
      ## [Unreleased]
      - Fixed a bug in the authentication flow.
      - Added new logging feature.

      # Good: Proper change type categories
      ## [Unreleased]

      ### Added
      - New logging feature for debugging.

      ### Fixed
      - Bug in the authentication flow that caused session timeouts.
    output: "Properly structured changelog with change type categories"

  - input: |
      # Bad: Vague entry
      ### Fixed
      - Fixed a bug.

      # Good: Descriptive entry with issue reference
      ### Fixed
      - Fix authentication timeout when API requests exceed 10 seconds (#123).
    output: "Descriptive changelog entry with issue reference"

  - input: |
      # Bad: Missing link references
      ## [1.0.0] - 2023-12-01
      ### Added
      - Initial release.

      # Good: Complete with link references
      ## [1.0.0] - 2023-12-01
      ### Added
      - Initial release.

      [1.0.0]: https://github.com/bossjones/codegen-lab/releases/tag/v1.0.0
    output: "Changelog with proper version link references"

metadata:
  priority: high
  version: 1.0
  tags:
    - documentation
    - changelog
    - git
</rule>

## Changelog Automation

The project includes tooling to automate changelog updates from Git history. This helps maintain a consistent changelog without manual effort.

### How the Automation Works

The `update_changelog.py` script performs these steps:

1. Fetches all commits between the specified branch and main
2. Parses commit messages using conventional commits syntax
3. Groups changes by type based on commit prefixes
4. Inserts new entries into the appropriate sections of the Unreleased area
5. Preserves existing entries that aren't duplicates
6. Maintains formatting consistent with Keep a Changelog

### Configuration Options

The script supports these configuration options:

```yaml
# .changelog-config.yml example
version_prefix: 'v'  # Prefix for version tags, e.g., v1.0.0
repo_url: 'https://github.com/bossjones/codegen-lab'  # Repository URL for links
commit_types:  # Mapping of commit types to changelog sections
  feat: 'Added'
  fix: 'Fixed'
  perf: 'Changed'
  refactor: 'Changed'
  # Add custom mappings here
exclude_types:  # Commit types to exclude from changelog
  - 'test'
  - 'chore'
  - 'ci'
```

### Example: Generating Changelog from Git History

To generate changes for all commits from your feature branch not in main:

```bash
# Basic usage
uv run python scripts/update_changelog.py --branch=feature-branch

# Specify a date range
uv run python scripts/update_changelog.py --since=2023-01-01 --until=2023-12-31

# Generate only specific change types
uv run python scripts/update_changelog.py --types=feat,fix,security
```

## Release Process

When preparing a new release, follow these steps:

1. **Run the changelog updater to ensure all changes are included**:
   ```bash
   uv run python scripts/update_changelog.py --finalize --version=1.0.0
   ```

2. **The script will automatically**:
   - Move `[Unreleased]` entries to a new version section
   - Add the current date to the new version
   - Create a new empty `[Unreleased]` section
   - Update the version comparison links

3. **Review and clean up**:
   - Check for duplicate entries
   - Ensure entries are in the appropriate categories
   - Verify descriptions are clear and concise
   - Make sure all links are correct

4. **Commit the updated changelog**:
   ```bash
   git add docs/changelog.md
   git commit -m "chore: update changelog for v1.0.0 release"
   ```

## Pull Request Integration

The changelog automation can be integrated with Pull Requests to pre-populate changelog entries:

1. **In PR template**:
   ```markdown
   ## Changelog
   <!-- Please describe the changes in this PR in the conventional commit format -->
   <!-- Example: feat(api): add new authentication method -->
   <!-- Any lines starting with "changelog: " will be automatically added -->

   changelog: feat(utils): add new string formatting helpers
   changelog: fix(api): resolve timeout issue when processing large requests
   ```

2. **When merging the PR**:
   The CI pipeline can extract these entries and add them to the changelog automatically.

## Common Issues and Solutions

### Missing or Incomplete Entries

If commits don't appear in the generated changelog:

1. Check that commit messages follow the conventional commits format
2. Verify that the commit type is not in the excluded list
3. Confirm that the commit exists in your branch but not in main

### Duplicate Entries

If you see duplicate entries in the changelog:

1. The deduplication is based on the exact text of the entry
2. Minor variations in wording can cause duplicates
3. Edit the changelog manually to remove duplicates

### Manual Additions

Some changes might not be reflected well in commits. In such cases:

1. Add entries manually to the appropriate section
2. Follow the same format as auto-generated entries
3. Consider adding a note about why this change is significant

## Semantic Versioning Guidelines

When determining the next version number:

- **MAJOR version** (x.0.0): Incompatible API changes, breaking changes
- **MINOR version** (0.x.0): New functionality in a backward compatible manner
- **PATCH version** (0.0.x): Backward compatible bug fixes

The changelog automation can suggest the next version based on:
- Presence of commits with "BREAKING CHANGE" in the message (MAJOR)
- Presence of commits with "feat" type (MINOR)
- Presence of commits with "fix" type (PATCH)
