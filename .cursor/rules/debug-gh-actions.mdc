---
description: GitHub Actions Workflow Debugging Guide
globs: .github/workflows/*.yml
alwaysApply: false
---
# GitHub Actions Workflow Debugging

This rule provides guidance for debugging and troubleshooting GitHub Actions workflow issues using the GitHub CLI.

<rule>
name: debug-gh-actions
description: A systematic approach to debug GitHub Actions workflow issues using GitHub CLI
filters:
  - type: file_path
    pattern: "\.github/workflows/.*\.yml$"
  - type: message
    pattern: "(?i)(github actions|workflow|action|gh actions|pipeline|ci/cd|workflow failing|workflow error)"
  - type: context
    pattern: "(?i)(workflow|action|failed|error|ci|cd|github actions)"

actions:
  - type: suggest
    message: |
      # GitHub Actions Debugging Guide

      This guide provides a systematic approach to debug GitHub Actions workflow issues using the GitHub CLI.

      ## Important: Prevent Interactive Pagers in GitHub CLI

      When using GitHub CLI in scripts or CI/CD environments, always set the `GH_PAGER` environment variable to `cat` to prevent interactive pagers:

      ```bash
      # Set GH_PAGER to cat to ensure non-interactive output
      export GH_PAGER=cat

      # Or run commands with GH_PAGER set inline
      GH_PAGER=cat gh run list
      ```

      This ensures commands don't hang waiting for user input and output is fully displayed in logs.

      ## Phase 1: Identify the Failing Workflow

      1. **List Recent Workflow Runs**:
         ```bash
         # List recent workflow runs (with non-interactive output)
         GH_PAGER=cat gh run list --limit 10

         # List recent runs for a specific workflow
         GH_PAGER=cat gh run list --workflow=workflow-name.yml --limit 5
         ```

      2. **Check Workflow Run Details**:
         ```bash
         # View details of a specific run (get ID from gh run list)
         GH_PAGER=cat gh run view RUN_ID

         # View details with logs
         GH_PAGER=cat gh run view RUN_ID --log

         # View details with log failures only
         GH_PAGER=cat gh run view RUN_ID --log-failed
         ```

      3. **Download Run Logs for Detailed Analysis**:
         ```bash
         # Download logs for a specific run
         GH_PAGER=cat gh run download RUN_ID
         ```

      ## Phase 2: Validate Workflow Configuration

      1. **Check Workflow Syntax**:
         ```bash
         # Install actionlint for local validation
         gh extension install github/gh-actionlint

         # Validate workflow files
         gh actionlint
         ```

      2. **Compare with Examples & Documentation**:
         - Review the [GitHub Actions documentation](https://docs.github.com/en/actions)
         - Check syntax against [Workflow syntax reference](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions)
         - Validate expressions using [GitHub's expression syntax](https://docs.github.com/en/actions/learn-github-actions/expressions)

      3. **Verify Action Versions**:
         - Check that all action versions are specified correctly (e.g., `uses: actions/checkout@v3`)
         - Confirm that action versions are not deprecated
         - Consider updating to the latest versions when appropriate

      ## Phase 3: Diagnose Common Issues

      1. **Environment & Secret Access**:
         - Verify secrets are configured correctly in repository settings
         - Check environment configuration when using environment-specific secrets
         - Confirm environment variables are properly referenced `${{ env.VAR_NAME }}`

      2. **Runner & Resource Issues**:
         - Check if jobs are failing due to timeouts or resource constraints
         - Verify the runner OS version is compatible with your workflow
         - Consider workflow optimization to reduce runtime

      3. **Permissions & Access Control**:
         - Verify the workflow has proper permissions defined:
           ```yaml
           permissions:
             contents: read
             issues: write
             # Add other permissions as needed
           ```
         - Check token scopes if using custom tokens

      ## Phase 4: Interactive Debug & Testing

      1. **Re-run Failed Jobs**:
         ```bash
         # Re-run a failed workflow
         GH_PAGER=cat gh run rerun RUN_ID

         # Re-run only failed jobs
         GH_PAGER=cat gh run rerun RUN_ID --failed
         ```

      2. **Debug Mode & Enhanced Logging**:
         - Enable debug logging by setting repository secrets:
           - `ACTIONS_RUNNER_DEBUG` to `true`
           - `ACTIONS_STEP_DEBUG` to `true`
         - Use the `--debug` flag with the CLI for more verbose output

      3. **Test Workflow Changes**:
         ```bash
         # Trigger workflow run manually (workflow_dispatch)
         GH_PAGER=cat gh workflow run workflow-name.yml

         # Trigger with inputs if workflow accepts them
         GH_PAGER=cat gh workflow run workflow-name.yml -f param=value -f another=value
         ```

      ## Phase 5: Implement and Verify Fixes

      1. **Make Incremental Changes**:
         - Modify workflows with small, targeted changes
         - Test each change individually before making additional changes
         - Comment workflows thoroughly to document intent

      2. **Verify the Solution**:
         - Run the workflow to confirm the fix
         - Check that the fix doesn't introduce new issues
         - Validate across different operating systems if applicable

      3. **Document Findings and Solutions**:
         - Update README or documentation with learnings
         - Consider adding workflow status badges to README
         - Share knowledge with the team

examples:
  - input: |
      My GitHub Actions workflow is failing with permission errors when trying to push to the repo.
    output: |
      I'll help you debug this GitHub Actions permission issue. Looking at the workflow failure related to pushing to the repository, this is likely a permissions configuration problem.

      First, let's check the recent workflow runs to identify the specific failure:
      ```bash
      GH_PAGER=cat gh run list --limit 5
      ```

      Once we identify the failing run ID, let's examine its logs:
      ```bash
      GH_PAGER=cat gh run view RUN_ID --log-failed
      ```

      Based on the permission error when pushing, we need to make sure your workflow has the proper permissions. In your workflow file, you need to add or update the permissions section:

      ```yaml
      permissions:
        contents: write  # This allows writing to the repository
      ```

      Let's also verify that the workflow is using the correct token for authentication:
      ```yaml
      - name: Some step that pushes
        run: |
          # Using the default GITHUB_TOKEN
          git config --global user.name "GitHub Actions"
          git config --global user.email "actions@github.com"
          # Your git commands here
      ```

      Would you like me to check your specific workflow file to pinpoint the exact permission issue?

  - input: |
      How can I test my GitHub Actions workflow locally before pushing?
    output: |
      To test GitHub Actions workflows locally before pushing, you have several options:

      1. First, install the GitHub CLI and actionlint extension for syntax validation:
      ```bash
      # Install actionlint extension
      gh extension install github/gh-actionlint

      # Validate workflow syntax
      gh actionlint
      ```

      2. For more comprehensive local testing, you can use act, which runs actions locally using Docker:
      ```bash
      # Install act
      brew install act  # On macOS

      # Run all workflows
      act

      # Run a specific workflow
      act -W .github/workflows/specific-workflow.yml

      # Run a specific event
      act push
      ```

      3. Test individual shell commands from your workflow steps in your local terminal to verify they work as expected

      4. Create a branch for workflow changes and test through actual GitHub Actions by pushing to that branch

      Would you like me to help you set up any of these local testing methods for your specific workflows?

metadata:
  priority: high
  version: 1.0
  tags:
    - debugging
    - github-actions
    - ci-cd
    - github-cli
</rule>

## Additional GitHub Actions Debugging Resources

### Understanding GitHub Actions Logs

GitHub Actions logs contain several key sections to examine when debugging:

1. **Workflow Summary**: High-level view of all jobs and their status
2. **Job Logs**: Detailed logs for each job, including:
   - Setup tasks (runner setup, checkout)
   - Each step with timing information
   - Step outputs and error messages
   - Environment details

### Common GitHub Actions Issues and Solutions

#### Environment and Context Issues

1. **Secret Access Problems**:
   - Secrets are only available to workflows in the repository where they're defined
   - Environment-specific secrets require the environment to be specified in the job
   - Secret names are case-sensitive

2. **Context Limitations**:
   - Different contexts are available at different points in the workflow
   - Some contexts (`github`, `env`) are available everywhere
   - Others (`needs`, `matrix`) are only available in specific places

#### Workflow Syntax Issues

1. **YAML Indentation Errors**:
   - YAML is sensitive to indentation
   - Use spaces, not tabs
   - Maintain consistent indentation (2 spaces recommended)

2. **Expression Syntax**:
   - Expressions must use the correct syntax: `${{ expression }}`
   - Strings with special characters might need quotes: `'${{ toJSON(github) }}'`
   - Logical operations need specific syntax: `${{ success() && steps.test.outputs.result == 'pass' }}`

#### Action Version Problems

1. **Version Pinning**:
   - Use specific versions (e.g., `@v3`) instead of `@main` or `@master`
   - Major version updates might break your workflow
   - Consider using SHA pinning for critical workflows: `@a5484e9d927c30e0d7d152767eb7527a199c8d49`

### Advanced GitHub CLI Commands for Workflow Debugging

```bash
# Set GH_PAGER to prevent interactive pagers in all commands below
export GH_PAGER=cat

# List available workflows
gh workflow list

# View workflow usage
gh workflow view workflow-name.yml

# Enable/disable a workflow
gh workflow enable workflow-name.yml
gh workflow disable workflow-name.yml

# Export workflow logs to file
gh run view RUN_ID --log > workflow-logs.txt

# Create workflow visualization
gh workflow view workflow-name.yml --viz | dot -Tpng > workflow.png
```

### Setting GH_PAGER in GitHub Actions Workflows

When running GitHub CLI commands in a workflow, set GH_PAGER to ensure proper output:

```yaml
- name: Debug workflow run
  env:
    GH_PAGER: cat
  run: |
    gh run list --limit 5
    gh workflow view current-workflow.yml
```

Alternatively, set it for the entire job or workflow:

```yaml
jobs:
  debug:
    runs-on: ubuntu-latest
    env:
      GH_PAGER: cat
    steps:
      - name: Debug workflow
        run: gh run list --limit 5
```

### Using GitHub Actions API for Deeper Debugging

For more complex debugging scenarios, you can interact directly with the GitHub API:

```bash
# Get detailed workflow run information
GH_PAGER=cat gh api repos/{owner}/{repo}/actions/runs/{run_id}

# List jobs for a workflow run
GH_PAGER=cat gh api repos/{owner}/{repo}/actions/runs/{run_id}/jobs

# Get timing metrics for workflow runs
GH_PAGER=cat gh api repos/{owner}/{repo}/actions/workflows/{workflow_id}/timing
```

Remember that thorough documentation of both the issue and the solution will help prevent similar problems in the future and assist team members who might encounter similar issues.
