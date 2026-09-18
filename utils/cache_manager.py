"""
Sorour Logistics ERP — Thread-Safe In-Memory Response Cache Manager
===================================================================
Provides high-performance, low-latency in-memory caching for read-heavy,
rarely-changing master data (transport locations, HS codes, Incoterms).

Strict Guardrails:
- Does NOT cache financial calculations, live exchange rates, or approval states.
- Supports proactive invalidation on write (create, update, delete, excel import).
"""
import time
import threading
from typing import Any, Optional, Dict, Tuple


class InMemoryCache:
    def __init__(self):
        self._store: Dict[str, Tuple[Any, float]] = {}
        self._lock = threading.Lock()

    def get(self, key: str) -> Optional[Any]:
        with self._lock:
            if key not in self._store:
                return None
            val, exp = self._store[key]
            if time.time() > exp:
                del self._store[key]
                return None
            return val

    def set(self, key: str, value: Any, ttl_seconds: int = 300) -> None:
        with self._lock:
            self._store[key] = (value, time.time() + ttl_seconds)

    def delete(self, key: str) -> bool:
        with self._lock:
            if key in self._store:
                del self._store[key]
                return True
            return False

    def clear_prefix(self, prefix: str) -> int:
        """Invalidates all cached keys starting with the given prefix."""
        with self._lock:
            keys_to_del = [k for k in self._store.keys() if k.startswith(prefix)]
            for k in keys_to_del:
                del self._store[k]
            return len(keys_to_del)

    def clear_all(self) -> None:
        with self._lock:
            self._store.clear()

    def size(self) -> int:
        with self._lock:
            return len(self._store)


# Global singleton instance
memory_cache = InMemoryCache()
