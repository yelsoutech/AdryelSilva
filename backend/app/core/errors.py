"""Standardized error responses for the API."""

from typing import Any

from fastapi import Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from sqlalchemy.exc import IntegrityError

from app.core.logging import logger


class AppError(Exception):
    """Base application error with a code, message, and optional details."""

    def __init__(
        self,
        code: str,
        message: str,
        status_code: int = 400,
        details: dict[str, Any] | None = None,
    ):
        self.code = code
        self.message = message
        self.status_code = status_code
        self.details = details or {}
        super().__init__(message)


class NotFoundError(AppError):
    def __init__(self, resource: str, resource_id: str | None = None):
        msg = f"{resource} not found" if not resource_id else f"{resource} '{resource_id}' not found"
        super().__init__(code="not_found", message=msg, status_code=404)


class ForbiddenError(AppError):
    def __init__(self, message: str = "You do not have permission to perform this action"):
        super().__init__(code="forbidden", message=message, status_code=403)


class UnauthorizedError(AppError):
    def __init__(self, message: str = "Authentication required"):
        super().__init__(code="unauthorized", message=message, status_code=401)


class ConflictError(AppError):
    def __init__(self, message: str, details: dict[str, Any] | None = None):
        super().__init__(code="conflict", message=message, status_code=409, details=details)


class ValidationFailedError(AppError):
    def __init__(self, details: dict[str, Any]):
        super().__init__(
            code="validation_failed",
            message="Request validation failed",
            status_code=422,
            details=details,
        )


def _error_response(code: str, message: str, status_code: int, details: Any = None) -> JSONResponse:
    body: dict[str, Any] = {"code": code, "message": message}
    if details:
        body["details"] = details
    return JSONResponse(status_code=status_code, content=body)


async def app_error_handler(request: Request, exc: AppError) -> JSONResponse:
    logger.warning(
        "app_error",
        code=exc.code,
        message=exc.message,
        status_code=exc.status_code,
        path=request.url.path,
    )
    return _error_response(exc.code, exc.message, exc.status_code, exc.details or None)


async def validation_error_handler(request: Request, exc: RequestValidationError) -> JSONResponse:
    logger.warning("validation_error", path=request.url.path, errors=exc.errors())
    return _error_response(
        "validation_failed",
        "Request validation failed",
        422,
        exc.errors(),
    )


async def integrity_error_handler(request: Request, exc: IntegrityError) -> JSONResponse:
    logger.warning("integrity_error", path=request.url.path, detail=str(exc.orig))
    return _error_response(
        "conflict",
        "A database constraint was violated",
        409,
    )


async def unhandled_exception_handler(request: Request, exc: Exception) -> JSONResponse:
    logger.error("unhandled_exception", path=request.url.path, error=str(exc), exc_info=True)
    return _error_response(
        "internal_error",
        "An unexpected error occurred",
        500,
    )
