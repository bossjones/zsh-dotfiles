---
description: Greenfield Development Workflow
globs: *.py, *.js, *.ts, *.jsx, *.tsx, *.rs, *.go, *.cpp, *.java
alwaysApply: false
---
# Greenfield Development Workflow

Rules for implementing new software projects using a structured LLM-assisted workflow, based on Harper Reed's approach.

<rule>
name: greenfield-development-workflow
description: Standards for LLM-assisted greenfield software development from idea to implementation
filters:
  # Match files that might contain development plans or specs
  - type: file_extension
    pattern: "\\.(md|py|js|ts|jsx|tsx|rs|go|cpp|java)$"
  # Match project initialization events
  - type: event
    pattern: "file_create"

actions:
  - type: suggest
    message: |
      # Greenfield Development Workflow

      Follow this three-step workflow for building new software with LLM assistance:

      ## Step 1: Idea Honing (15 minutes)

      Use a conversational LLM (like GPT-4o or Claude 3) to refine your idea:

      ```prompt
      Ask me one question at a time so we can develop a thorough, step-by-step spec for this idea. Each question should build on my previous answers, and our end goal is to have a detailed specification I can hand off to a developer. Let's do this iteratively and dig into every relevant detail. Remember, only one question at a time.

      Here's the idea:

      <IDEA>
      ```

      When the brainstorming concludes, request a comprehensive spec:

      ```prompt
      Now that we've wrapped up the brainstorming process, can you compile our findings into a comprehensive, developer-ready specification? Include all relevant requirements, architecture choices, data handling details, error handling strategies, and a testing plan so a developer can immediately begin implementation.
      ```

      Save this as `spec.md` in your repository for reference.

      ## Step 2: Planning (15-30 minutes)

      Pass your spec to a reasoning model (Claude 3 Opus, GPT-4) to create a detailed implementation plan:

      For TDD-based development:
      ```prompt
      Draft a detailed, step-by-step blueprint for building this project. Then, once you have a solid plan, break it down into small, iterative chunks that build on each other. Look at these chunks and then go another round to break it into small steps. Review the results and make sure that the steps are small enough to be implemented safely with strong testing, but big enough to move the project forward. Iterate until you feel that the steps are right sized for this project.

      From here you should have the foundation to provide a series of prompts for a code-generation LLM that will implement each step in a test-driven manner. Prioritize best practices, incremental progress, and early testing, ensuring no big jumps in complexity at any stage. Make sure that each prompt builds on the previous prompts, and ends with wiring things together. There should be no hanging or orphaned code that isn't integrated into a previous step.

      Make sure and separate each prompt section. Use markdown. Each prompt should be tagged as text using code tags. The goal is to output prompts, but context, etc is important as well.

      <SPEC>
      ```

      For non-TDD development:
      ```prompt
      Draft a detailed, step-by-step blueprint for building this project. Then, once you have a solid plan, break it down into small, iterative chunks that build on each other. Look at these chunks and then go another round to break it into small steps. review the results and make sure that the steps are small enough to be implemented safely, but big enough to move the project forward. Iterate until you feel that the steps are right sized for this project.

      From here you should have the foundation to provide a series of prompts for a code-generation LLM that will implement each step. Prioritize best practices, and incremental progress, ensuring no big jumps in complexity at any stage. Make sure that each prompt builds on the previous prompts, and ends with wiring things together. There should be no hanging or orphaned code that isn't integrated into a previous step.

      Make sure and separate each prompt section. Use markdown. Each prompt should be tagged as text using code tags. The goal is to output prompts, but context, etc is important as well.

      <SPEC>
      ```

      Save this plan as `prompt_plan.md` in your repository.

      Then generate a todo checklist for tracking progress:

      ```prompt
      Can you make a `todo.md` that I can use as a checklist? Be thorough.
      ```

      Save this as `todo.md` in your repository.

      ## Step 3: Execution

      Choose an appropriate codegen tool (Cursor, Aider, Claude) to implement your plan:

      ### Option A: Pair Programming with Claude or Similar LLM

      1. Set up initial project structure and boilerplate
      2. Iteratively feed each prompt from your plan to the LLM
      3. Implement the generated code in your IDE/editor
      4. Test and verify each implementation step
      5. Debug with LLM assistance when needed
      6. Check off items in your `todo.md` as you progress

      ### Option B: Using Aider or Similar Assisted Coding Tool

      1. Set up initial project structure and boilerplate
      2. Start your coding assistant tool
      3. Feed prompts from your plan to the tool
      4. Let the assistant implement each step
      5. Review, test, and verify the implementation
      6. Use Q&A with the tool to fix any issues
      7. Check off items in your `todo.md` as you progress

      ### Testing & Quality Control

      - Implement proper testing for each component
      - Review code for best practices and standards
      - Regularly run tests to catch issues early
      - Document important design decisions

      ### Progress Tracking

      - Use `todo.md` to track progress
      - Avoid getting "over your skis" by following the plan
      - Take breaks if implementation becomes confusing
      - Regularly review the spec and plan to stay on track

examples:
  - input: |
      # Bad: Jumping right into coding without a plan
      Let's build a Twitter clone with React and Node.

      # Good: Following the three-step Greenfield process
      Step 1: Create detailed spec.md through idea refinement
      Step 2: Develop prompt_plan.md and todo.md for implementation
      Step 3: Execute plan iteratively with testing at each step
    output: "Properly structured greenfield development process"

  - input: |
      # Bad: Trying to implement everything at once
      Build a complete e-commerce platform with user accounts, product catalog, cart, and checkout.

      # Good: Breaking down implementation into small steps
      1. Set up project structure and dependencies
      2. Implement basic product model and display
      3. Add user authentication system
      4. Implement shopping cart functionality
      5. Create checkout process
      6. Add payment processing integration
    output: "Incremental implementation approach"

metadata:
  priority: high
  version: 1.0
  tags:
    - development-workflow
    - llm-assisted-coding
    - greenfield
    - planning
</rule>
