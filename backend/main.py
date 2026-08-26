import os
from typing import Any

import httpx
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

PLAID_BASE_URL = os.getenv("PLAID_BASE_URL", "https://sandbox.plaid.com")
PLAID_CLIENT_ID = os.getenv("PLAID_CLIENT_ID", "")
PLAID_SECRET = os.getenv("PLAID_SECRET", "")

app = FastAPI(title="Pennywise API")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Replace this with encrypted database storage before supporting real users.
access_tokens_by_user: dict[str, str] = {}


class LinkTokenRequest(BaseModel):
    user_id: str


class PublicTokenRequest(BaseModel):
    user_id: str
    public_token: str


def plaid_credentials() -> dict[str, str]:
    if not PLAID_CLIENT_ID or not PLAID_SECRET:
        raise HTTPException(
            status_code=500,
            detail="PLAID_CLIENT_ID and PLAID_SECRET are not configured",
        )
    return {"client_id": PLAID_CLIENT_ID, "secret": PLAID_SECRET}


async def plaid_post(path: str, payload: dict[str, Any]) -> dict[str, Any]:
    try:
        async with httpx.AsyncClient(timeout=15) as client:
            response = await client.post(f"{PLAID_BASE_URL}{path}", json=payload)
    except httpx.HTTPError as error:
        raise HTTPException(status_code=502, detail="Plaid is unavailable") from error

    if response.is_error:
        detail = response.json().get("error_message", "Plaid request failed")
        raise HTTPException(status_code=502, detail=detail)
    return response.json()


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.post("/api/plaid/link-token")
async def create_link_token(request: LinkTokenRequest) -> dict[str, str]:
    payload = {
        **plaid_credentials(),
        "client_name": "Pennywise",
        "country_codes": ["US"],
        "language": "en",
        "user": {"client_user_id": request.user_id},
        "products": ["auth", "transactions"],
    }
    result = await plaid_post("/link/token/create", payload)
    return {"link_token": result["link_token"]}


@app.post("/api/plaid/exchange-public-token")
async def exchange_public_token(request: PublicTokenRequest) -> dict[str, str]:
    result = await plaid_post(
        "/item/public_token/exchange",
        {**plaid_credentials(), "public_token": request.public_token},
    )
    access_tokens_by_user[request.user_id] = result["access_token"]
    return {"item_id": result["item_id"]}
