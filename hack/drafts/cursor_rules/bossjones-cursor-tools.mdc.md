---
description: Global Rule
globs:
alwaysApply: false
---
<bossjones-cursor-tools Integration>
# Instructions
Use the following commands to get AI assistance:

**Web Search:**
`uv run llm -m sonar-pro "<your question>"` - Get answers from the web using Perplexity AI (e.g., `uv run llm -m sonar-pro "latest weather in London"`)
when using web for complex queries suggest writing the output to a file somewhere like local-research/<query summary>.md.

**Time:**
`uv run python -c "from datetime import datetime; import tzlocal; print(datetime.now(tzlocal.get_localzone()).strftime('%Y-%m-%d %H:%M:%S %Z'))"` - Get the current time to use in prompts, logs, and other places.

**Tool Recommendations:**
- `uv run llm -m sonar-pro` is best for general web information not specific to the repository.
- `uv run python -c "from datetime import datetime; import tzlocal; print(datetime.now(tzlocal.get_localzone()).strftime('%Y-%m-%d %H:%M:%S %Z'))"` is best to populate any prompt templates that require a datetime.

**Additional Notes:**
- **Remember:** You're part of a team of superhuman expert AIs. Work together to solve complex problems.
<!-- bossjones-cursor-tools-version: 0.1.0 -->
</bossjones-cursor-tools Integration>
