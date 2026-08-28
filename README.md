# MotoNote

App ghi chú + nhắc bảo trì xe máy. Không tài khoản, dữ liệu lưu trên máy, backup lên Google Drive.

- **Framework:** Flutter
- **Backend:** không có
- **Lưu trữ:** một file JSON trong thư mục app (`appdata.json`)
- **Đồng bộ:** backup/khôi phục toàn bộ file lên Google Drive `appDataFolder`
- **Thông báo:** `flutter_local_notifications` (không push)

## Tài liệu

Kiến trúc & kế hoạch đầy đủ: [`motonote-v3-flutter.md`](motonote-v3-flutter.md) (v3.0)

## Quy trình phát triển

Dự án dùng [GSD Core](https://github.com/open-gsd/gsd-core) — spec-driven development cho Claude Code.

Cài đặt cho máy của bạn (mỗi dev tự chạy, cấu hình hook chứa đường dẫn tuyệt đối nên không commit):

```bash
npx @opengsd/gsd-core@latest --claude --local
```

Sau đó mở project trong Claude Code và chạy `/gsd-new-project`.

## Yêu cầu

- Flutter SDK (stable)
- Node.js (cho GSD tooling)
