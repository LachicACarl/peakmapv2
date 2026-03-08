from datetime import datetime
from threading import Lock
from typing import Optional


_presence_lock = Lock()
_driver_presence: dict[int, dict[str, object]] = {}


def set_driver_online_state(driver_id: int, is_online: bool, source: str = "manual") -> None:
    """Set in-memory online/offline state for a driver."""
    with _presence_lock:
        _driver_presence[driver_id] = {
            "is_online": bool(is_online),
            "updated_at": datetime.utcnow(),
            "source": source,
        }


def mark_driver_online(driver_id: int, source: str = "heartbeat") -> None:
    set_driver_online_state(driver_id, True, source)


def mark_driver_offline(driver_id: int, source: str = "manual") -> None:
    set_driver_online_state(driver_id, False, source)


def get_driver_online_state(driver_id: int) -> Optional[bool]:
    """Return driver online state if known in this process, else None."""
    with _presence_lock:
        state = _driver_presence.get(driver_id)
        if state is None:
            return None
        return bool(state.get("is_online", False))
