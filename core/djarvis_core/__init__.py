"""Djarvis local core service."""

# Single source of truth for the package version. The build reads it statically
# (tool.setuptools.dynamic), so the installed metadata always matches it, and it
# stays available when the package runs without distribution metadata.
__version__ = "0.1.0"

__all__ = ["__version__"]
