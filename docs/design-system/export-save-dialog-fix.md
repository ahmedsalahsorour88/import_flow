# 💾 Native "Save As" File Location Dialog Specification

## 📌 Overview
Prohibits silent/automatic downloads to default temp or downloads folders. Enforces native modal Save As file dialogs.

---

## 🖥️ Platform Implementation Rules
1. **Windows Desktop:**
   - Must use `FilePicker.saveFile` with `lockParentWindow: true` to prevent background window desync.
2. **Web Browser (Chromium):**
   - Must use File System Access API (`window.showSaveFilePicker`).
   - Must gracefully catch `AbortError` on user cancel without throwing errors or fallback auto-download.
3. **Browser Fallback:**
   - Fall back to `<a download>` only if `showSaveFilePicker` is unsupported, with an informative toast notice.
4. **Standard File Naming:**
   - Format: `[Stage Name] - [Import File Code or Name].[ext]`
5. **Interactive Completion Toast:**
   - Shows SnackBar on desktop with 'Open Folder' button (`explorer.exe /select, <path>`).

---

## ✅ Definition of Done (Self-Verification Checklist)
- [ ] Exporting PDF/Excel opens native Windows Save As dialog.
- [ ] Canceling dialog halts export quietly with 0 errors.
- [ ] Saving file triggers SnackBar with functioning 'Open Folder' button.
