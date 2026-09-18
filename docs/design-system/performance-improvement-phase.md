# ⚡ Phase 2 Performance Improvement Specification

## 📌 Overview
High-confidence performance optimizations to accelerate multi-user concurrency and response latency.

---

## 🛠️ Step-by-Step Architecture
- **Step 0:** Baseline capture (RPS, P50/P95 latency, payload size).
- **Step 1:** Database B-Tree indexes on high-frequency filters (`current_stage`, `acid_number`, `is_active`).
- **Step 2:** In-memory RAM caching (`InMemoryCache`, 300s TTL, auto-invalidation on write).
  - *Strict Rule:* Never cache live financial calculations or exchange rates.
- **Step 3:** GZip response compression (`GZipMiddleware`, minimum 1000 bytes) reducing wire transfer by >= 85%.
- **Step 4:** Frontend Dio network tuning (`Accept-Encoding: gzip`).
- **Step 5:** Session identity map resolution (`db.get(User, user_id)`) + auth active-state cache.

---

## ✅ Definition of Done (Self-Verification Checklist)
- [ ] Measured concurrent throughput improves by >= 100% over baseline.
- [ ] Network payload sizes for master data decrease by >= 80%.
- [ ] Zero regression across test suite (853 tests passing).
