---
title: Chính sách quyền riêng tư — MotoNote
permalink: /privacy-policy
---

# Chính sách quyền riêng tư — MotoNote

*Cập nhật lần cuối: 02/09/2026*

[English version]({{ site.baseurl }}/privacy-policy-en)

## Tóm tắt trong một câu

MotoNote không có máy chủ, không có tài khoản MotoNote, và không thu thập bất
cứ điều gì về bạn — toàn bộ dữ liệu nằm trên máy của bạn, và bản sao lưu (chỉ
khi bạn chủ động bật) nằm trong Google Drive của chính bạn, không phải của
người phát triển ứng dụng.

## 1. Không có tài khoản, không có máy chủ

MotoNote không yêu cầu tạo tài khoản. Không có email đăng ký riêng cho app,
không có mật khẩu, và không có máy chủ nào của MotoNote lưu trữ dữ liệu của
bạn. Người phát triển ứng dụng không nhận được bất kỳ dữ liệu nào từ máy của
bạn — không có kênh nào để dữ liệu đó đi tới người phát triển.

## 2. Dữ liệu của bạn nằm trong một file duy nhất, trên máy của bạn

Mọi thứ bạn ghi trong MotoNote — xe (tên, biển số, hãng, đời xe), hạng mục
bảo dưỡng, lịch sử bảo dưỡng (bao gồm chi phí và tên cửa hàng nếu bạn nhập),
số km, ghi chú và cài đặt — được lưu trong một file JSON duy nhất trên bộ nhớ
trong của điện thoại. Ứng dụng đọc và ghi file này ngay khi bạn sử dụng;
không màn hình nào chờ kết nối mạng để hiển thị dữ liệu của bạn.

## 3. Hai thông tin phụ mà file này còn lưu

Ngoài dữ liệu bảo dưỡng, file trên còn lưu hai thông tin mà có thể bạn không
ngờ tới — cả hai đều không rời khỏi máy của bạn hoặc tài khoản Google của
chính bạn:

- **Tên model điện thoại** (ví dụ "Redmi Note 12") — chỉ để đặt nhãn cho một
  bản sao lưu, giúp bạn phân biệt hai máy khác nhau nếu bạn từng đổi điện
  thoại.
- **Địa chỉ email của tài khoản Google bạn đăng nhập** (chỉ khi bạn bật sao
  lưu Google Drive) — chỉ để màn hình Cài đặt hiển thị bản sao lưu đang đi
  vào tài khoản nào.

## 4. Sao lưu Google Drive — tắt theo mặc định

Tính năng sao lưu lên Google Drive **tắt theo mặc định**. Nếu bạn chủ động
bật, một bản sao của file dữ liệu (mục 2) được ghi vào một khu vực riêng tư
trong Google Drive của chính bạn — khu vực `appDataFolder`, nơi chỉ MotoNote
có thể nhìn thấy. MotoNote không đọc hay chạm vào bất kỳ file nào khác trong
Drive của bạn, và bạn cũng không thể tự mình xem file sao lưu này trong giao
diện Drive thông thường — đây là đánh đổi có chủ đích để MotoNote chỉ xin
đúng phạm vi hẹp nhất có thể (`drive.appdata`, không phải `drive` hay
`drive.readonly`).

Ba điều luôn đúng với việc đăng nhập Google trong MotoNote:

1. Không có tài khoản MotoNote.
2. Có đăng nhập Google, và chỉ khi bạn bật sao lưu.
3. App chỉ thấy đúng file của nó.

## 5. Ảnh không bao giờ được sao lưu lên Drive

Nếu bạn đính kèm ảnh hoá đơn vào lịch sử bảo dưỡng, hoặc ảnh cho xe của bạn,
ảnh đó chỉ được lưu trên bộ nhớ trong của điện thoại — đường dẫn tới ảnh
được ghi vào file dữ liệu, nhưng bản thân ảnh không bao giờ được tải lên
Google Drive. "⚠ Ảnh hoá đơn không khôi phục được" là dòng cảnh báo bạn sẽ
thấy trên màn hình khôi phục, chính vì lý do này.

## 6. Thông báo nhắc nhở được tạo ngay trên máy

MotoNote nhắc bạn khi đến hạn bảo dưỡng bằng thông báo cục bộ (local
notification) do chính điện thoại lên lịch và hiển thị. Không có dịch vụ đẩy
(push) nào ở giữa, và không có máy chủ nào biết bạn được nhắc lúc nào hay
nội dung nhắc là gì.

## 7. Không phân tích hành vi, không quảng cáo, không bán dữ liệu

MotoNote không tích hợp bất kỳ công cụ phân tích (analytics) hay quảng cáo
nào. Không có dữ liệu nào của bạn được bán hoặc chia sẻ cho bên thứ ba — đơn
giản là không có nơi nào để dữ liệu đó rời khỏi máy bạn, ngoài Google Drive
của chính bạn khi bạn chủ động bật sao lưu (mục 4).

## 8. Xoá toàn bộ dữ liệu

Trong Cài đặt → Vùng nguy hiểm, nút "Xoá tất cả dữ liệu" xoá toàn bộ file dữ
liệu trên máy, mọi ảnh hoá đơn, mọi thông báo đã lên lịch, và đăng xuất tài
khoản Google của bạn khỏi app. Bản sao lưu trên Google Drive **chỉ bị xoá
nếu bạn chủ động tick vào ô riêng** "Đồng thời xoá bản sao lưu trên Google
Drive" trong hộp thoại xác nhận — ô này **để trống theo mặc định**, vì đây
là nơi duy nhất bạn có thể khôi phục lại nếu lỡ xoá nhầm dữ liệu trên máy.

## 9. Liên hệ

Có câu hỏi về chính sách này hoặc về dữ liệu của bạn? Liên hệ:
nguyenvantrungjieu@gmail.com

## 10. Thay đổi đối với chính sách này

Nếu MotoNote thay đổi cách xử lý dữ liệu trong tương lai, chính sách này sẽ
được cập nhật trước khi thay đổi đó có hiệu lực, và ngày "Cập nhật lần cuối"
ở đầu trang sẽ phản ánh điều đó. Việc lưu trữ chỉ trên máy và trên Google
Drive của chính bạn là ràng buộc cho những gì app được phép làm, không phải
ngược lại — nếu một thay đổi trong tương lai khiến câu trên không còn đúng,
đó là một thay đổi sai.

---

*MotoNote — App ghi chú + nhắc bảo trì xe máy · Không tài khoản · Lưu máy ·
Backup Google Drive.*
