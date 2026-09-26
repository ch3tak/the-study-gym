"""Question-type registry. Importing this package registers every type.

To add a type: create a module with a `@register`ed QuestionType subclass and
import it below. Subjects opt in via `question_types_allowed` in their syllabus.
"""

from . import assertion_reason, case_based, expression, mcq, numeric  # noqa: F401
from .base import GENERIC_MISCONCEPTIONS, REGISTRY, Context, QuestionType, register

__all__ = ["GENERIC_MISCONCEPTIONS", "REGISTRY", "Context", "QuestionType", "register"]
