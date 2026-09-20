import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict


class MarketplaceResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    name: str
    display_name: str
    api_base_url: str | None = None
    logo_url: str | None = None
    status: str
    created_at: datetime
    updated_at: datetime


class MarketplaceAccountBase(BaseModel):
    marketplace_id: uuid.UUID
    account_name: str
    account_id: str


class MarketplaceAccountCreate(MarketplaceAccountBase):
    pass


class MarketplaceAccountUpdate(BaseModel):
    account_name: str | None = None
    status: str | None = None


class MarketplaceAccountResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    organization_id: uuid.UUID
    marketplace_id: uuid.UUID
    account_name: str
    account_id: str
    status: str
    last_sync_at: datetime | None = None
    created_at: datetime
    updated_at: datetime
