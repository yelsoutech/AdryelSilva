from fastapi import APIRouter

from app.api.v1.endpoints import collection_jobs, marketplace_accounts, members, organizations

api_router = APIRouter()
api_router.include_router(organizations.router, prefix="/organizations", tags=["organizations"])
api_router.include_router(marketplace_accounts.router, prefix="/marketplace-accounts", tags=["marketplace-accounts"])
api_router.include_router(collection_jobs.router, prefix="/collection-jobs", tags=["collection-jobs"])
api_router.include_router(members.router, prefix="/members", tags=["members"])
