---
description: Efficiently gather code context from the codebase for LLM consumption
globs: *
alwaysApply: false
---

# Code Context Gatherer

This rule helps efficiently gather code context from the codebase for LLM consumption.

<rule>
name: code-context-gatherer
description: Efficiently gather code context from the codebase for LLM consumption
filters:
  - type: message
    pattern: "(?i)(context|understand|code base|codebase|gather|collect|relevant files|get context)"
  - type: context
    pattern: "existing code|understand the code|how does this work|existing functionality"

actions:
  - type: instructions
    message: |
      # Code Context Gathering for LLM Consumption

      When the user needs to gather code context for understanding or modifying an existing codebase:

      1. **Identify Relevant Components**:
         - Determine which parts of the codebase are relevant to the task
         - Focus on core modules and their dependencies
         - Include both implementation and test files when appropriate

      2. **Efficient Context Collection**:
         - Use semantic search to find relevant files and code sections
         - Prioritize files with high relevance to the current task
         - Include sufficient context for understanding component relationships

      3. **Context Organization**:
         - Group related files together
         - Start with high-level components, then drill down to implementation details
         - Include comment blocks that explain architecture and design decisions

      4. **Optimize Context Size**:
         - Remove irrelevant boilerplate or repetitive code
         - Include only the most relevant parts of large files
         - Focus on interfaces and core logic over implementation details when appropriate

      5. **Context Summarization**:
         - Provide a summary of the collected context
         - Highlight key patterns, dependencies, and architectural decisions
         - Identify potential areas for modification

      Follow this process:

      1. Search for relevant files using semantic search
      2. Read and analyze key files
      3. Create a context summary
      4. Highlight the most important code sections
      5. Identify potential improvement areas

examples:
  - input: |
      I need to understand how the user authentication system works in this codebase.
    output: |
      I'll help you gather context about the user authentication system. Let me search for and analyze the relevant code.

      First, let's identify the core authentication components:

      1. **Authentication Controllers/Handlers**:
         ```python
         # User login controller
         @app.route('/login', methods=['POST'])
         def login():
             email = request.json.get('email')
             password = request.json.get('password')

             user = User.query.filter_by(email=email).first()
             if user and check_password_hash(user.password, password):
                 token = create_access_token(identity=user.id)
                 return jsonify(token=token)

             return jsonify({"error": "Invalid credentials"}), 401
         ```

      2. **User Model**:
         ```python
         class User(db.Model):
             id = db.Column(db.Integer, primary_key=True)
             email = db.Column(db.String(100), unique=True, nullable=False)
             password = db.Column(db.String(200), nullable=False)
             name = db.Column(db.String(100))
             created_at = db.Column(db.DateTime, default=datetime.utcnow)

             def __init__(self, email, password, name=None):
                 self.email = email
                 self.password = generate_password_hash(password)
                 self.name = name
         ```

      3. **Authentication Middleware**:
         ```python
         @jwt.user_identity_loader
         def user_identity_lookup(user_id):
             return user_id

         @jwt.user_lookup_loader
         def user_lookup_callback(_jwt_header, jwt_data):
             identity = jwt_data["sub"]
             return User.query.filter_by(id=identity).one_or_none()

         def auth_required(fn):
             @wraps(fn)
             def wrapper(*args, **kwargs):
                 verify_jwt_in_request()
                 return fn(*args, **kwargs)
             return wrapper
         ```

      **Summary of Authentication Flow**:
      - User credentials (email/password) are submitted to the `/login` endpoint
      - The system verifies the credentials against the database
      - If valid, a JWT token is generated and returned to the client
      - Protected routes use the `auth_required` decorator to verify the token
      - The middleware extracts the user ID from the token and loads the corresponding user

      **Key Areas for Potential Modification**:
      - Token generation and validation in the JWT setup
      - Password hashing and verification logic
      - User model fields and validation
      - Authentication middleware and decorators

      Would you like me to explore any specific part of the authentication system in more detail?

metadata:
  priority: high
  version: 1.0
</rule>
