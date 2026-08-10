# 植忆后端

## 环境

- Java 21、Maven 3.9+、MySQL 8
- Spring Boot 3.5、Flyway、Spring Security JWT
- 服务默认仅监听 `127.0.0.1:8080`，Swagger：`http://localhost:8080/swagger-ui.html`

## 首次启动

1. 在 MySQL 客户端以管理员身份执行 `scripts/create-local-db.sql`，并把脚本中的示例密码替换成自己的强密码。
2. 在 PowerShell 设置本机开发环境变量（每次新终端都需要设置）：

```powershell
$env:ZHIYI_DB_URL='jdbc:mysql://127.0.0.1:3306/zhiyi?useUnicode=true&characterEncoding=utf8&serverTimezone=Asia/Shanghai'
$env:ZHIYI_DB_USERNAME='zhiyi_app'
$env:ZHIYI_DB_PASSWORD='你的数据库密码'
$env:ZHIYI_JWT_SECRET='至少32位的随机字符串，请不要使用示例值'
mvn spring-boot:run
```

Flyway 会自动建表。项目不会自动创建用户、密码或邀请码；请通过客户端或注册接口创建测试账号。

若暂时没有 MySQL 账号，可先启动不影响 MySQL 配置的本机演示数据库：

```powershell
$env:ZHIYI_JWT_SECRET='至少32位的随机字符串，请不要使用示例值'
mvn spring-boot:run "-Dspring-boot.run.profiles=demo"
```

`demo` profile 使用本地 H2 数据库，仅用于当前电脑的真机联调；后续配置好 MySQL 后不带该 profile 启动即可切回 MySQL。

## 真机联调

1. 手机和电脑连接同一可信专用网络；在 PowerShell 运行 `ipconfig`，找到电脑 IPv4。
2. 显式设置 `$env:ZHIYI_SERVER_ADDRESS='0.0.0.0'`，只在联调期间开放监听。
3. 在应用的服务器设置页面输入联调地址，不要把具体主机地址提交到源码。
4. 允许 Windows 防火墙的专用网络访问 TCP 8080；重新编译并安装鸿蒙 App。
5. 注册临时测试账号进行验证，联调完成后关闭服务并清理测试数据。

## 验证

```powershell
mvn test
```

测试使用独立的 H2 内存库，覆盖注册冲突、JWT 保护、邀请码加入、树洞成员隔离与共同一天查询。生产/演示服务实际使用 MySQL 迁移。

## 接口摘要

- `POST /api/auth/register`、`POST /api/auth/login`、`GET /api<REDACTED_LOCAL_PATH>`
- `GET/POST /api/memories`、`GET/PATCH/DELETE /api/memories/{id}`
- `POST /api/files/images`（Bearer + multipart 的 `file`）
- `POST/GET /api/tree-holes`、`POST /api/tree-holes/join`
- `GET /api/tree-holes/{id}/members`、`DELETE /api/tree-holes/{id}/members/{userId}`
- `GET /api/tree-holes/{id}/memories`、`GET /api/tree-holes/{id}/common-day?date=YYYY-MM-DD`
