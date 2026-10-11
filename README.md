# Bài 4: Tự động triển khai ứng dụng Spring Boot (Container) lên VPS từ xa qua SSH

## Mục tiêu
- Thiết lập luồng Continuous Deployment (CD) hoàn chỉnh từ mã nguồn GitHub trực tiếp lên máy chủ VPS từ xa (Ubuntu Server).
- Sử dụng action `appleboy/ssh-action@v1.0.3` để thực thi các lệnh SSH an toàn qua khóa SSH Key (Asymmetric Keypair).
- Tự động hóa quá trình kéo image mới, khởi chạy container, ánh xạ cổng và kiểm tra endpoint `/health`.

---

## 1. Cấu trúc Dự án
```text
ss12/b4/
├── .github/
│   └── workflows/
│       └── deploy-vps.yml      # Pipeline CD tự động deploy qua SSH
├── gradle/wrapper/
├── src/
│   └── main/java/com/example/demo/DemoApplication.java
├── Dockerfile                  # Đóng gói JRE 17 và HEALTHCHECK
├── build.gradle
├── settings.gradle
├── gradlew
└── README.md
```

---

## 2. Hướng dẫn Cấu hình Bảo mật SSH & Secrets

### Bước 1: Tạo SSH Keypair trên máy cá nhân / VPS
```bash
ssh-keygen -t ed25519 -C "github-actions-deploy" -f deploy_key -N ""
```
- Khóa công khai (`deploy_key.pub`): Thêm vào tệp `~/.ssh/authorized_keys` trên VPS của người dùng triển khai.
- Khóa bí mật (`deploy_key`): Dùng làm giá trị cho Secret `VPS_SSH_KEY`.

### Bước 2: Thiết lập GitHub Repository Secrets
Truy cập **Settings** -> **Secrets and variables** -> **Actions** và tạo các secrets:
- `VPS_HOST`: Địa chỉ IP công khai hoặc tên miền của máy chủ VPS (ví dụ `103.x.x.x`).
- `VPS_USERNAME`: Tên tài khoản Linux (ví dụ `ubuntu`, `deployer`).
- `VPS_SSH_KEY`: Nội dung tệp Private Key (`deploy_key`).
- `VPS_PORT`: Cổng SSH (mặc định `22`).

---

## 3. Kịch bản Triển khai Tự động trên VPS
Trong pipeline CD, khi SSH kết nối thành công vào VPS, các lệnh sau sẽ được thực thi tuần tự:
```bash
# 1. Kéo image mới
docker pull ghcr.io/<owner>/spring-boot-app:latest

# 2. Dọn dẹp container cũ
docker stop spring-boot-prod || true
docker rm spring-boot-prod || true

# 3. Chạy container mới
docker run -d --name spring-boot-prod --restart unless-stopped -p 8080:8080 ghcr.io/<owner>/spring-boot-app:latest

# 4. Kiểm tra sức khỏe ứng dụng
sleep 8
curl -f http://localhost:8080/health || exit 1
```

---

## 4. Kết luận
Giải pháp này hiện thực hóa quy trình GitOps & CD tự động hoàn toàn: Ngay khi mã nguồn được merge vào nhánh `main`, hệ thống tự động build, kiểm thử, đóng gói container và phát hành trực tiếp lên hạ tầng cloud VPS mà không cần can thiệp thủ công.
