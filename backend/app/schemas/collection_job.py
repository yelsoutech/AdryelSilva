import uuid
from datetime import datetime
from typing import Any

from pydantic import BaseModel, ConfigDict


class CollectionJobBase(BaseModel):
    job_type: str
    marketplace_account_id: uuid.UUID | None = None
    priority: int = 0
    payload: dict[str, Any] = {}


class CollectionJobCreate(CollectionJobBase):
    pass


class CollectionJobResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    organization_id: uuid.UUID
    marketplace_account_id: uuid.UUID | None = None
    job_type: str
    status: str
    priority: int
    payload: dict[str, Any] | None = None
    result: dict[str, Any] | None = None
    error_message: str | None = None
    started_at: datetime | None = None
    completed_at: datetime | None = None
    created_at: datetime
    updated_at: datetime
