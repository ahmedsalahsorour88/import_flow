# 🏷️ Metric Card Labeling, Bounding Box & Overlay Extension Specification

## 📌 Overview
Specifies label alias mapping, value preservation, and desktop side-docking for chat/support overlays.

---

## 📏 Core Rules
1. **Short Label Mapping:**
   - When container width < 660px or in Compact modes, labels must shorten gracefully (e.g. `Total Purchase Orders` -> `POs`).
2. **Value Preservation:**
   - Numerical values must never be clipped or truncated with ellipsis.
3. **Side Docking on Desktop (>=1200px):**
   - Chat and AI assistant panel docks into the main layout `Row` (`AiAssistantDockedPanel` 410px/560px), shifting the content area rather than floating over tables.
4. **Greeting Bubble Auto-Collapse:**
   - Bubble automatically collapses after 7 seconds or upon any table scroll.

---

## ✅ Definition of Done (Self-Verification Checklist)
- [ ] No metric label displays truncation dots (`...`).
- [ ] Chat panel docks cleanly on screens >= 1200px without obscuring tables.
- [ ] Greeting bubble collapses after 7 seconds or on scroll.
