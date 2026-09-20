"""Supabase JWT verification.

The frontend sends the Supabase access token in the Authorization header.
We verify it against the Supabase JWKS to authenticate the user, then resolve
their active organization and permissions via the database.
"""

import time
from typing import Any

import httpx
import jwt
from jwt import PyJWKClient

from app.core.config import settings
from app.core.logging import logger

_jwks_client: PyJWKClient | None = None
_jwks_fetched_at: float = 0
_JWKS_TTL = 3600  # refresh JWKS every hour


def _get_jwks_url() -> str:
    if not settings.SUPABASE_URL:
        raise RuntimeError("SUPABASE_URL is not configured")
    return f"{settings.SUPABASE_URL}/auth/v1/.well-known/jwks.json"


def _get_signing_key():
    global _jwks_client, _jwks_fetched_at
    now = time.time()
    if _jwks_client is None or (now - _jwks_fetched_at) > _JWKS_TTL:
        _jwks_client = PyJWKClient(_get_jwks_url())
        _jwks_fetched_at = now
        logger.info("jwks_fetched", url=_get_jwks_url())
    return _jwks_client


def verify_token(token: str) -> dict[str, Any]:
    """Verify a Supabase JWT and return the decoded payload.

    Raises jwt.InvalidTokenError on any failure.
    """
    jwks = _get_signing_key()
    signing_key = jwks.get_signing_key_from_jwt(token)
    payload = jwt.decode(
        token,
        signing_key.key,
        algorithms=["HS256", "RS256"],
        audience="authenticated",
        options={"verify_aud": True},
    )
    return payload


async def verify_supabase_token(token: str) -> dict[str, Any]:
    """Async wrapper that also falls back to Supabase user API for validation."""
    try:
        return verify_token(token)
    except jwt.InvalidTokenError:
        # Fallback: call Supabase auth getUser endpoint
        async with httpx.AsyncClient() as client:
            resp = await client.get(
                f"{settings.SUPABASE_URL}/auth/v1/user",
                headers={
                    "Authorization": f"Bearer {token}",
                    "apikey": settings.SUPABASE_ANON_KEY,
                },
            )
            if resp.status_code != 200:
                raise jwt.InvalidTokenError("Supabase user API rejected token")
            user_data = resp.json()
            return {
                "sub": user_data["id"],
                "email": user_data.get("email"),
                "role": user_data.get("role", "authenticated"),
            }
