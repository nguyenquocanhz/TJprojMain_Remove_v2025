
---

# ✅ **CHANGELOG.md**

```markdown
# Changelog
Dự án tuân theo tiêu chuẩn **Semantic Versioning (SemVer 2.0.0)**.  
Mỗi bản cập nhật được ghi lại theo cấu trúc: *Added – Changed – Fixed – Removed*.

---

## [2025.1.0] – 2025-12-01
### 🔥 Added
- Cơ chế **Smart Kill** dùng .NET CIM Instance để định danh tiến trình độc hại.
- Hệ thống **Registry Cleaner** cho HKLM/HKCU Startup.
- Chức năng **Attribute Restore** (remove Hidden/System/Read-only).
- Hệ thống **Multi-Drive Scan** hỗ trợ quét từ A–Z.
- Tự động yêu cầu quyền **Administrator** (UAC Elevation).
- Log chi tiết quá trình quét và xử lý.
- Bổ sung xử lý LiteralPath để tăng độ an toàn khi thao tác file.

### 🔄 Changed
- Cải thiện hiệu suất quét 30% so với phiên bản cũ.
- Tối ưu thuật toán phát hiện đường dẫn tiến trình.
- Chuẩn hóa thông báo giao diện console.

### 🐞 Fixed
- Khắc phục lỗi không xóa được file đang khóa.
- Sửa lỗi nhầm lẫn file hệ thống thật trong System32.
- Fix trường hợp hiển thị sai encoding trong PowerShell 7.

### ❌ Removed
- Loại bỏ module cũ không còn tương thích với Windows 11.
- Xóa cơ chế Kill Process cũ dùng WMI (thay bằng CIM hiện đại).

---

## [2024.12] – 2024
*Bản phát triển nội bộ – chưa phát hành công khai.*

---

## [2023.5] – 2023
*Phiên bản nền tảng – thu thập hành vi malware Jeefo và TJprojMain.*

