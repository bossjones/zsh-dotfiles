---
description: Break down a development task into smaller, manageable steps for incremental implementation
globs: *
---
# Incremental Task Planner

This rule helps break down a development task into smaller, manageable steps for incremental implementation.

<rule>
name: incremental-task-planner
description: Break down a development task into smaller, manageable steps for incremental implementation
filters:
  - type: message
    pattern: "(?i)(plan|break down|implement|feature|task|incrementally|steps for)"
  - type: context
    pattern: "non-greenfield|existing codebase|existing project|update functionality|fix bug|add feature"

actions:
  - type: instructions
    message: |
      # Task Planning for Incremental Development

      When the user needs help planning an implementation task for an existing codebase:

      1. **Analyze the Task**:
         - Understand what feature or bug fix is being requested
         - Identify relevant parts of the codebase that will be affected
         - Assess the current architecture and patterns used

      2. **Break Down the Task**:
         - Divide the task into small, manageable steps
         - Ensure each step builds incrementally on the previous ones
         - Avoid large jumps in complexity
         - Make steps small enough to be testable but large enough to move the project forward

      3. **Create a Todo Checklist**:
         - Format a todo.md-style checklist for each step
         - Include specific, actionable tasks
         - Make progress trackable and visible

      4. **Plan for Testing**:
         - Include test implementation in the steps
         - Ensure each functional component has corresponding tests
         - Plan for regression testing of affected components

      5. **Implementation Guidance**:
         - Provide guidance for implementing each step
         - Reference existing patterns in the codebase
         - Suggest reusable components or abstractions

      Use the following format for the todo checklist:

      ```markdown
      # Task Implementation Plan: [Task Name]

      ## Steps

      ### 1. [Step Name]
      - [ ] [Specific action]
      - [ ] [Specific action]
      - [ ] Write tests for [component]

      ### 2. [Step Name]
      - [ ] [Specific action]
      - [ ] [Specific action]
      - [ ] Update tests for [component]

      ...
      ```

examples:
  - input: |
      I need to add a new feature to my existing application to support user profile editing.
    output: |
      I'll help you plan an incremental approach to adding user profile editing to your application.

      First, let's analyze the task and break it down into manageable steps:

      # Task Implementation Plan: User Profile Editing

      ## Steps

      ### 1. Understand Current User Model
      - [ ] Analyze current user data model and schema
      - [ ] Identify fields that should be editable
      - [ ] Review current authentication and user data handling

      ### 2. Create Profile Edit Form UI
      - [ ] Design simple form component for profile editing
      - [ ] Add form validation for user inputs
      - [ ] Implement responsive layout for the form
      - [ ] Write tests for form validation

      ### 3. Implement API Endpoints
      - [ ] Create/update API endpoint for profile updates
      - [ ] Add validation on the server side
      - [ ] Implement security checks and authorization
      - [ ] Write tests for the API endpoints

      ### 4. Connect Front-end to API
      - [ ] Implement form submission logic
      - [ ] Add loading and error states
      - [ ] Handle success and error responses
      - [ ] Write integration tests

      ### 5. Add Profile Image Upload (if required)
      - [ ] Implement file upload component
      - [ ] Add image processing and storage logic
      - [ ] Update user model to reference profile images
      - [ ] Write tests for image upload functionality

      ### 6. Final Integration and Testing
      - [ ] Integrate with navigation/menu system
      - [ ] Ensure proper authentication flow
      - [ ] Perform end-to-end testing
      - [ ] Write documentation for the new feature

      Let's start by exploring the current user model and authentication system to better understand what we're working with.

metadata:
  priority: high
  version: 1.0
</rule>
