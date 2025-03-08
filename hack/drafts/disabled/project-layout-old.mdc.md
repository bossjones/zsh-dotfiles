---
description: Documentation of the Codegen Lab project structure, organization, and Greenfield development process
globs: ["**/*.md", "**/*.py", "**/*.mdc"]
---

# Codegen Lab Project Layout

@context {
    "type": "documentation",
    "purpose": "project_structure",
    "format_version": "1.0.0",
    "supported_content_types": [
        "prompts",
        "documentation",
        "implementations",
        "tests"
    ],
    "language": "python",
    "python_version": ">=3.8",
    "supported_models": [
        "claude",
        "gpt",
        "gemini"
    ],
    "recommended_tools": [
        "ruff",
        "mypy",
        "pytest",
        "black",
        "isort"
    ],
    "package_management": [
        "uv",
        "uv workspace"
    ]
}

@structure {
    "primary_components": [
        "src",
        "packages",
        "tests",
        "hack",
        "docs"
    ],
    "key_directories": {
        "src": {
            "description": "Python source code",
            "subdirectories": {
                "goob_ai": "Core application code"
            }
        },
        "packages": {
            "description": "UV workspace packages",
            "subdirectories": {
                "cursor-rules-mcp-server": "Cursor rules MCP server package"
            }
        },
        "tests": {
            "description": "Test suites and resources",
            "subdirectories": {
                "unittests": "Unit test modules",
                "integration": "Integration tests"
            }
        },
        "hack": {
            "description": "Development tooling and utilities",
            "subdirectories": {
                "drafts": "Work-in-progress resources including cursor rules"
            }
        },
        "docs": "Project documentation"
    }
}

# Project Overview

## Introduction

This repository implements the Greenfield development methodology for AI-augmented software development. It serves as a structured environment for building new Python projects using LLM-assisted workflows, following Harper Reed's approach. The focus is on enhancing developer productivity through a systematic three-step process: Idea Honing, Planning, and Execution.

## Core Features

- **Greenfield Development Workflow:** Structured process for LLM-assisted development
- **Documentation Standards:** Guidelines for maintaining spec.md, prompt_plan.md, and todo.md
- **Execution Best Practices:** Standards for implementing code with LLM assistance
- **Python Best Practices:** Type hints, comprehensive docstrings, and thorough testing
- **Cursor Rules Management:** System for organizing and implementing AI behavior rules
- **UV Workspace Management:** Package organization using UV workspace structure

## Current Directory Structure

```
.
├── .cursor/                     # Active cursor rules directory
│   └── rules/                   # Production cursor rules
├── Makefile                     # Build automation
├── README.md                    # Project overview and setup instructions
├── hack/                        # Development tooling
│   └── drafts/                  # Work-in-progress resources
│       └── cursor_rules/        # Staging area for cursor rules
├── packages/                    # UV workspace packages
│   └── cursor-rules-mcp-server/ # Cursor rules MCP server package
│       ├── pyproject.toml       # Package configuration
│       └── src/                 # Package source code
│           └── cursor_rules_mcp_server/ # Package code
├── src/                         # Python source code
│   └── goob_ai/                 # Core application modules
├── tests/                       # Test suites
│   ├── integration/             # Integration tests
│   └── unittests/               # Unit tests
└── docs/                        # Project documentation
```

## Component Overview

@components {
    "description": "Key components and their responsibilities",
    "organization": "Modular structure for maintainability and scalability"
}

### Source Code

<component name="src">
    <description>
        Core Python application code following best practices for type hints,
        docstrings, and modular organization.
    </description>
    <structure>
        - goob_ai/: Core application modules
    </structure>
</component>

### Workspace Packages

<component name="packages">
    <description>
        Modular packages organized in a UV workspace structure, allowing for independent
        versioning, development, and reuse.
    </description>
    <structure>
        - cursor-rules-mcp-server/: Cursor rules MCP server package
          - src/cursor_rules_mcp_server/: Package source code
          - pyproject.toml: Package configuration
    </structure>
</component>

### Tests

<component name="tests">
    <description>
        Comprehensive test suite using pytest for both unit and integration tests,
        with full type annotations and documentation.
    </description>
    <structure>
        - unittests/: Module-specific unit tests
        - integration/: Cross-component integration tests
    </structure>
</component>

### Cursor Rules

<component name="cursor_rules">
    <description>
        Cursor rule definitions that implement the Greenfield development workflow
        and related standards.
    </description>
    <structure>
        - hack/drafts/cursor_rules/: Development/staging area for cursor rules
        - .cursor/rules/: Production cursor rules (deployed via Makefile)
    </structure>
</component>

## Best Practices

@best_practices {
    "organization": {
        "documentation": [
            "Keep READMEs up to date in each directory",
            "Use clear, descriptive file names",
            "Follow consistent documentation format",
            "Include examples where appropriate"
        ],
        "python": [
            "Follow PEP 8 style guidelines",
            "Use comprehensive type hints",
            "Write descriptive docstrings (PEP 257)",
            "Organize code into logical modules",
            "Implement thorough pytest test cases"
        ],
        "code": [
            "Follow Python type hinting",
            "Include comprehensive docstrings",
            "Write unit tests",
            "Use consistent code style"
        ],
        "workspace": [
            "Organize related components into packages",
            "Use UV workspace for dependency management",
            "Maintain separate pyproject.toml for each package",
            "Follow consistent package structure"
        ]
    }
}

## Implementation Guidelines

@implementation_rules {
    "python": {
        "structure": {
            "format": "Modular package design",
            "required_sections": [
                "imports",
                "type definitions",
                "class/function definitions",
                "main execution"
            ],
            "annotations": "Type hints for all functions and classes"
        },
        "documentation": {
            "style": "PEP 257 docstrings",
            "examples": "Include practical examples",
            "metadata": "Include version and author information"
        }
    },
    "cursor_rules": {
        "structure": {
            "format": "MDC (Markdown Configuration)",
            "location": {
                "development": "hack/drafts/cursor_rules/*.mdc.md",
                "production": ".cursor/rules/*.mdc"
            },
            "deployment": "Use 'make update-cursor-rules' to deploy"
        }
    },
    "workspace_packages": {
        "structure": {
            "format": "UV workspace with src layout",
            "location": "packages/<package-name>/",
            "required_files": [
                "pyproject.toml",
                "src/<package_name>/__init__.py"
            ],
            "management": "Use Makefile targets for workspace operations"
        }
    }
}

## Validation Rules

@validation {
    "requirements": [
        "All Python code must have type hints",
        "Each function and class must have PEP 257 docstrings",
        "All code must have corresponding tests",
        "Tests must have type annotations",
        "Each major directory must have a README.md",
        "Cursor rules must follow proper MDC format",
        "Workspace packages must follow src layout"
    ],
    "code_quality": {
        "linters": "Use ruff for comprehensive linting",
        "type_checking": "Use mypy with strict mode",
        "formatting": "Use black and isort for consistent code style"
    },
    "tools": {
        "linting": {
            "ruff": "Primary linter for Python code",
            "mypy": "Static type checking with strict mode"
        },
        "testing": {
            "pytest": "Test framework for Python components",
            "coverage": "Track test coverage metrics"
        },
        "package_management": {
            "uv": "Fast Python package installer and environment manager",
            "uv_workspace": "Manage multiple packages in a single repository"
        }
    }
}

## Development Workflow

@workflow {
    "guidelines": {
        "greenfield_development": {
            "steps": [
                "1. Idea Honing - Create spec.md",
                "2. Planning - Create prompt_plan.md and todo.md",
                "3. Execution - Implement plan with testing"
            ],
            "documentation": [
                "Maintain spec.md for requirements",
                "Update prompt_plan.md as implementation progresses",
                "Use todo.md to track completion status"
            ],
            "execution": [
                "Break implementation into small, manageable steps",
                "Test thoroughly at each step",
                "Document decisions and progress"
            ]
        },
        "version_control": {
            "branching": "Feature branches from main",
            "commits": "Clear, descriptive commit messages",
            "pull_requests": "Required for all changes"
        },
        "cursor_rules": {
            "development": "Create and refine in hack/drafts/cursor_rules/",
            "deployment": "Use 'make update-cursor-rules' to deploy to .cursor/rules/"
        },
        "workspace_management": {
            "new_packages": "Use 'make uv-workspace-init-package name=<package-name>' to create",
            "dependencies": "Use 'make uv-workspace-add-dep package=<package-name>' to add dependencies",
            "updates": "Use 'make uv-workspace-lock' to update lockfile"
        }
    }
}

## Project Standards

@standards {
    "python": {
        "code_style": {
            "style_guide": "PEP 8",
            "type_hints": "Required",
            "docstrings": "PEP 257 format",
            "max_line_length": 88
        },
        "testing": {
            "framework": "pytest",
            "fixtures": "Properly typed pytest fixtures",
            "parameterization": "Use pytest.mark.parametrize for test cases",
            "coverage": {
                "minimum": "80%",
                "target": "90%"
            }
        }
    },
    "cursor_rules": {
        "format": {
            "style": "MDC (Markdown Configuration)",
            "required_sections": [
                "frontmatter",
                "rule definition",
                "examples",
                "metadata"
            ]
        }
    },
    "workspace_packages": {
        "format": {
            "style": "src layout with pyproject.toml",
            "required_sections": [
                "name",
                "version",
                "dependencies",
                "development dependencies"
            ]
        },
        "management": {
            "tools": "UV workspace commands via Makefile",
            "dependency_resolution": "Central requirements.lock",
            "version_control": "Individual package versioning"
        }
    }
}

## XML Tag Guidelines

@anthropic_xml_guidelines {
    "purpose": "Enhance prompt documentation with XML tags for better model comprehension",
    "tag_types": {
        "context": {
            "tag": "<context>",
            "usage": "Provide context about the prompt or feature",
            "example": "<context>This prompt helps generate unit tests</context>"
        },
        "thinking": {
            "tag": "<thinking>",
            "usage": "Show step-by-step reasoning process",
            "example": "<thinking>1. Analyze requirements\n2. Generate structure\n3. Add implementation details</thinking>"
        },
        "quotes": {
            "tag": "<quotes>",
            "usage": "Highlight important information or direct quotes",
            "example": "<quotes>Key insight from documentation</quotes>"
        },
        "reasoning": {
            "tag": "<reasoning>",
            "usage": "Explain logical steps and decisions",
            "example": "<reasoning>This approach was chosen because...</reasoning>"
        },
        "plan": {
            "tag": "<plan>",
            "usage": "Outline implementation approach",
            "example": "<plan>1. Setup environment\n2. Implement core functions\n3. Add tests</plan>"
        }
    }
}

## Cursor Rules Configuration

@cursor_rules {
    "types": {
        "project": {
            "location": ".cursor/rules/*.mdc",
            "scope": "Project-specific",
            "purpose": "Control AI behavior in different parts of the project",
            "staging": "hack/drafts/cursor_rules/*.mdc.md",
            "deployment": "Use 'make update-cursor-rules' to deploy"
        }
    },
    "current_rules": {
        "greenfield_workflow": {
            "file": "greenfield.mdc.md",
            "purpose": "Defines the three-step Greenfield development process"
        },
        "documentation_standards": {
            "file": "greenfield-documentation.mdc.md",
            "purpose": "Standards for maintaining spec.md, prompt_plan.md, and todo.md"
        },
        "execution_best_practices": {
            "file": "greenfield-execution.mdc.md",
            "purpose": "Best practices for implementing code with LLM assistance"
        },
        "index": {
            "file": "greenfield-index.mdc.md",
            "purpose": "Entry point and overview of all Greenfield rules"
        },
        "uv_workspace": {
            "file": "uv-workspace.mdc.md",
            "purpose": "Guidelines for managing UV workspace packages"
        }
    }
}

<implementation>

@version "1.1.0"
@last_updated "2024-08-16"

</implementation>

@rule_examples {
    "greenfield_rules": {
        "file": ".cursor/rules/greenfield.mdc",
        "description": "Describes the three-step process for LLM-assisted development"
    },
    "python_rules": {
        "file": ".cursor/rules/python.mdc",
        "content": """
---
description: Python development rules and standards
globs: ["**/*.py"]
---

@context {
    "type": "development_rules",
    "language": "python",
    "version": ">=3.8"
}

@standards {
    "style": "PEP 8",
    "typing": "Required for all functions",
    "docstrings": "Google style required",
    "testing": "pytest with type annotations"
}
"""
    },
    "uv_workspace_rules": {
        "file": ".cursor/rules/uv-workspace.mdc",
        "content": """
---
description: UV workspace management guidelines
globs: ["pyproject.toml", "packages/**/pyproject.toml"]
---

@context {
    "type": "workspace_management",
    "tool": "uv",
    "version": ">=0.1.0"
}

@standards {
    "structure": "src layout",
    "package_naming": "Hyphenated (e.g., my-package)",
    "module_naming": "Underscore (e.g., my_package)",
    "dependency_management": "Central requirements.lock"
}
"""
    }
}

@migration_guide {
    "rule_deployment": [
        "Develop and refine cursor rules in hack/drafts/cursor_rules/",
        "Test rules with actual development tasks",
        "Run 'make update-cursor-rules' to deploy to .cursor/rules/",
        "Verify rules are working as expected in production"
    ],
    "benefits": [
        "Separation of development and production rules",
        "Easy deployment with Makefile",
        "Ability to refine rules before deployment",
        "Consistent rule format and structure",
        "Support for Greenfield development workflow"
    ],
    "workspace_migration": [
        "Move standalone packages to packages/ directory",
        "Create package-specific pyproject.toml",
        "Update workspace root pyproject.toml to include package",
        "Run 'make uv-workspace-lock' to update lockfile",
        "Run 'make uv-workspace-sync' to install dependencies"
    ]
}
