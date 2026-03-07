from datetime import datetime
from typing import Any, Optional

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, field_validator

from app.supabase_client import get_supabase_client, is_supabase_available

router = APIRouter(prefix="/rfid", tags=["RFID"])


class RFIDCardRegisterPayload(BaseModel):
    user_identifier: str  # email or users.id
    card_uid: str
    alias: Optional[str] = None

    @field_validator("user_identifier")
    @classmethod
    def validate_user_identifier(cls, value: str) -> str:
        normalized = value.strip()
        if not normalized:
            raise ValueError("user_identifier is required")
        return normalized

    @field_validator("card_uid")
    @classmethod
    def validate_card_uid(cls, value: str) -> str:
        normalized = value.strip().upper()
        if not normalized:
            raise ValueError("card_uid is required")
        return normalized


class RFIDEntryExitPayload(BaseModel):
    card_uid: str
    mode: str  # entry | exit
    user_identifier: Optional[str] = None
    source: str = "admin_dashboard"
    status: str = "SUCCESS"

    @field_validator("card_uid")
    @classmethod
    def validate_card_uid(cls, value: str) -> str:
        normalized = value.strip().upper()
        if not normalized:
            raise ValueError("card_uid is required")
        return normalized

    @field_validator("mode")
    @classmethod
    def validate_mode(cls, value: str) -> str:
        normalized = value.strip().lower()
        if normalized not in {"entry", "exit"}:
            raise ValueError("mode must be 'entry' or 'exit'")
        return normalized


def _response_data(response: Any) -> list[dict]:
    if response is None:
        return []

    data = getattr(response, "data", None)
    if isinstance(data, list):
        return data

    if isinstance(response, dict):
        maybe_data = response.get("data")
        if isinstance(maybe_data, list):
            return maybe_data

    return []


def _response_count(response: Any) -> int:
    count = getattr(response, "count", None)
    if isinstance(count, int):
        return count
    if isinstance(response, dict) and isinstance(response.get("count"), int):
        return response["count"]
    return 0


def _require_supabase():
    if not is_supabase_available():
        raise HTTPException(status_code=503, detail="Supabase is not configured in backend environment")

    try:
        return get_supabase_client()
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"Supabase client initialization failed: {exc}") from exc


def _table_missing_error(exc: Exception) -> HTTPException:
    message = str(exc)
    if (
        "does not exist" in message
        or "relation" in message
        or "Could not find the table" in message
        or "PGRST205" in message
    ):
        return HTTPException(
            status_code=500,
            detail=(
                "RFID Supabase tables are missing. Run supabase_tables.sql and include "
                "rfid_cards + rfid_entry_exit_logs definitions, then retry."
            ),
        )
    return HTTPException(status_code=500, detail=f"Supabase operation failed: {message}")


def _resolve_user_row(supabase, user_identifier: str) -> Optional[dict]:
    identifier = (user_identifier or "").strip()
    if not identifier:
        return None

    try:
        if identifier.isdigit():
            result = (
                supabase.table("users")
                .select("id,email,name")
                .eq("id", int(identifier))
                .limit(1)
                .execute()
            )
        else:
            result = (
                supabase.table("users")
                .select("id,email,name")
                .eq("email", identifier.lower())
                .limit(1)
                .execute()
            )

        rows = _response_data(result)
        return rows[0] if rows else None
    except Exception:
        return None


@router.post("/cards/register")
def register_card(payload: RFIDCardRegisterPayload):
    supabase = _require_supabase()

    try:
        user_row = _resolve_user_row(supabase, payload.user_identifier)
        if not user_row:
            raise HTTPException(status_code=404, detail="User not found in Supabase users table")

        card_uid = payload.card_uid
        existing = (
            supabase.table("rfid_cards")
            .select("id,card_uid,user_id,alias,status,registered_at")
            .eq("card_uid", card_uid)
            .limit(1)
            .execute()
        )
        existing_rows = _response_data(existing)

        user_id = user_row.get("id")
        alias = (payload.alias or "").strip() or f"Card {card_uid[:4]}"
        now_iso = datetime.utcnow().isoformat()

        if existing_rows:
            existing_row = existing_rows[0]
            existing_user_id = str(existing_row.get("user_id")) if existing_row.get("user_id") is not None else ""
            requested_user_id = str(user_id) if user_id is not None else ""
            if existing_user_id and existing_user_id != requested_user_id:
                raise HTTPException(
                    status_code=409,
                    detail=f"Card is already assigned to user_id={existing_row.get('user_id')}",
                )

            updated = (
                supabase.table("rfid_cards")
                .update({
                    "user_id": user_id,
                    "alias": alias,
                    "status": "active",
                    "updated_at": now_iso,
                })
                .eq("id", existing_row.get("id"))
                .execute()
            )
            saved_rows = _response_data(updated)
            saved = saved_rows[0] if saved_rows else {
                "id": existing_row.get("id"),
                "card_uid": card_uid,
                "user_id": user_id,
                "alias": alias,
                "status": "active",
                "registered_at": existing_row.get("registered_at"),
                "updated_at": now_iso,
            }
        else:
            inserted = (
                supabase.table("rfid_cards")
                .insert({
                    "card_uid": card_uid,
                    "user_id": user_id,
                    "alias": alias,
                    "status": "active",
                    "registered_at": now_iso,
                    "updated_at": now_iso,
                })
                .execute()
            )
            inserted_rows = _response_data(inserted)
            if not inserted_rows:
                raise HTTPException(status_code=500, detail="Card registration failed: no row returned")
            saved = inserted_rows[0]

        return {
            "success": True,
            "message": "Card registered in Supabase",
            "card": {
                "id": saved.get("id"),
                "card_uid": saved.get("card_uid", card_uid),
                "user_id": saved.get("user_id", user_id),
                "user_email": user_row.get("email"),
                "user_name": user_row.get("name"),
                "alias": saved.get("alias", alias),
                "status": saved.get("status", "active"),
                "registered_at": saved.get("registered_at"),
                "updated_at": saved.get("updated_at"),
            },
        }
    except HTTPException:
        raise
    except Exception as exc:
        raise _table_missing_error(exc) from exc


@router.get("/cards")
def list_cards(limit: int = 200):
    supabase = _require_supabase()
    bounded_limit = max(1, min(limit, 500))

    try:
        result = (
            supabase.table("rfid_cards")
            .select("id,card_uid,user_id,alias,status,registered_at,updated_at")
            .order("registered_at", desc=True)
            .limit(bounded_limit)
            .execute()
        )
        cards = _response_data(result)

        user_ids = sorted({int(c["user_id"]) for c in cards if c.get("user_id") is not None})
        user_map: dict[str, dict] = {}
        if user_ids:
            user_rows = _response_data(
                supabase.table("users")
                .select("id,email,name")
                .in_("id", user_ids)
                .execute()
            )
            user_map = {str(row.get("id")): row for row in user_rows}

        enriched_cards = []
        for card in cards:
            user = user_map.get(str(card.get("user_id")), {})
            enriched_cards.append(
                {
                    "id": card.get("id"),
                    "card_uid": card.get("card_uid"),
                    "user_id": card.get("user_id"),
                    "user_email": user.get("email"),
                    "user_name": user.get("name"),
                    "alias": card.get("alias"),
                    "status": card.get("status", "active"),
                    "registered_at": card.get("registered_at"),
                    "updated_at": card.get("updated_at"),
                }
            )

        return {"success": True, "count": len(enriched_cards), "cards": enriched_cards}
    except Exception as exc:
        raise _table_missing_error(exc) from exc


@router.get("/cards/{card_uid}")
def get_card(card_uid: str):
    supabase = _require_supabase()
    normalized_uid = card_uid.strip().upper()

    try:
        result = (
            supabase.table("rfid_cards")
            .select("id,card_uid,user_id,alias,status,registered_at,updated_at")
            .eq("card_uid", normalized_uid)
            .limit(1)
            .execute()
        )
        rows = _response_data(result)
        if not rows:
            return {"success": False, "message": "Card not found", "card": None}

        card = rows[0]
        user = None
        if card.get("user_id") is not None:
            user_rows = _response_data(
                supabase.table("users")
                .select("id,email,name")
                .eq("id", card.get("user_id"))
                .limit(1)
                .execute()
            )
            user = user_rows[0] if user_rows else None

        return {
            "success": True,
            "card": {
                "id": card.get("id"),
                "card_uid": card.get("card_uid"),
                "user_id": card.get("user_id"),
                "user_email": user.get("email") if user else None,
                "user_name": user.get("name") if user else None,
                "alias": card.get("alias"),
                "status": card.get("status", "active"),
                "registered_at": card.get("registered_at"),
                "updated_at": card.get("updated_at"),
            },
        }
    except Exception as exc:
        raise _table_missing_error(exc) from exc


@router.delete("/cards/{card_uid}")
def delete_card(card_uid: str):
    supabase = _require_supabase()
    normalized_uid = card_uid.strip().upper()

    try:
        existing = (
            supabase.table("rfid_cards")
            .select("id")
            .eq("card_uid", normalized_uid)
            .limit(1)
            .execute()
        )
        rows = _response_data(existing)
        if not rows:
            return {"success": False, "message": "Card not found", "card_uid": normalized_uid}

        (
            supabase.table("rfid_cards")
            .delete()
            .eq("card_uid", normalized_uid)
            .execute()
        )

        return {"success": True, "message": "Card deleted", "card_uid": normalized_uid}
    except Exception as exc:
        raise _table_missing_error(exc) from exc


@router.post("/entry-exit")
def create_entry_exit_log(payload: RFIDEntryExitPayload):
    supabase = _require_supabase()

    try:
        card_result = (
            supabase.table("rfid_cards")
            .select("card_uid,user_id,alias")
            .eq("card_uid", payload.card_uid)
            .limit(1)
            .execute()
        )
        card_rows = _response_data(card_result)
        card_row = card_rows[0] if card_rows else None

        resolved_user_id = card_row.get("user_id") if card_row else None
        resolved_identifier = (payload.user_identifier or "").strip() or None

        if resolved_user_id is None and resolved_identifier:
            user_row = _resolve_user_row(supabase, resolved_identifier)
            if user_row:
                resolved_user_id = user_row.get("id")
                if not resolved_identifier:
                    resolved_identifier = user_row.get("email")

        if resolved_identifier is None and resolved_user_id is not None:
            resolved_identifier = str(resolved_user_id)

        insert_result = (
            supabase.table("rfid_entry_exit_logs")
            .insert(
                {
                    "card_uid": payload.card_uid,
                    "user_id": resolved_user_id,
                    "user_identifier": resolved_identifier,
                    "mode": payload.mode,
                    "source": payload.source,
                    "status": payload.status,
                    "created_at": datetime.utcnow().isoformat(),
                }
            )
            .execute()
        )
        rows = _response_data(insert_result)
        inserted = rows[0] if rows else {}

        # Update last tap timestamp for registered card.
        (
            supabase.table("rfid_cards")
            .update({"last_tapped_at": datetime.utcnow().isoformat(), "updated_at": datetime.utcnow().isoformat()})
            .eq("card_uid", payload.card_uid)
            .execute()
        )

        return {
            "success": True,
            "message": "Entry/exit event stored in Supabase",
            "entry": {
                "id": inserted.get("id"),
                "card_uid": inserted.get("card_uid", payload.card_uid),
                "user_id": inserted.get("user_id", resolved_user_id),
                "user_identifier": inserted.get("user_identifier", resolved_identifier),
                "mode": inserted.get("mode", payload.mode),
                "status": inserted.get("status", payload.status),
                "source": inserted.get("source", payload.source),
                "created_at": inserted.get("created_at"),
            },
        }
    except Exception as exc:
        raise _table_missing_error(exc) from exc


@router.get("/entry-exit")
def list_entry_exit_logs(limit: int = 100):
    supabase = _require_supabase()
    bounded_limit = max(1, min(limit, 500))

    try:
        logs_result = (
            supabase.table("rfid_entry_exit_logs")
            .select("id,card_uid,user_id,user_identifier,mode,status,source,created_at")
            .order("created_at", desc=True)
            .limit(bounded_limit)
            .execute()
        )
        logs = _response_data(logs_result)

        user_ids = sorted({int(log["user_id"]) for log in logs if log.get("user_id") is not None})
        user_map: dict[str, dict] = {}
        if user_ids:
            user_rows = _response_data(
                supabase.table("users")
                .select("id,email,name")
                .in_("id", user_ids)
                .execute()
            )
            user_map = {str(row.get("id")): row for row in user_rows}

        entry_count_result = (
            supabase.table("rfid_entry_exit_logs")
            .select("id", count="exact")
            .eq("mode", "entry")
            .limit(1)
            .execute()
        )
        exit_count_result = (
            supabase.table("rfid_entry_exit_logs")
            .select("id", count="exact")
            .eq("mode", "exit")
            .limit(1)
            .execute()
        )

        entry_count = _response_count(entry_count_result)
        exit_count = _response_count(exit_count_result)

        enriched_logs = []
        for log in logs:
            user = user_map.get(str(log.get("user_id")), {})
            enriched_logs.append(
                {
                    "id": log.get("id"),
                    "card_uid": log.get("card_uid"),
                    "user_id": log.get("user_id"),
                    "user_identifier": log.get("user_identifier"),
                    "user_email": user.get("email"),
                    "user_name": user.get("name"),
                    "mode": log.get("mode"),
                    "status": log.get("status"),
                    "source": log.get("source"),
                    "created_at": log.get("created_at"),
                }
            )

        return {
            "success": True,
            "count": len(enriched_logs),
            "entry_count": entry_count,
            "exit_count": exit_count,
            "logs": enriched_logs,
        }
    except Exception as exc:
        raise _table_missing_error(exc) from exc


@router.delete("/entry-exit")
def clear_entry_exit_logs():
    supabase = _require_supabase()

    try:
        (
            supabase.table("rfid_entry_exit_logs")
            .delete()
            .gt("id", 0)
            .execute()
        )
        return {"success": True, "message": "Entry/exit logs cleared"}
    except Exception as exc:
        raise _table_missing_error(exc) from exc
