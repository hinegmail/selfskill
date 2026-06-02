# Technical Design Document

## 技术栈

### 后端
- 语言：{e.g., Python 3.12}
- 框架：{e.g., FastAPI}
- 数据库：{e.g., PostgreSQL 16}
- ORM：{e.g., SQLAlchemy}

### 前端
- 框架：{e.g., React 19 + TypeScript}
- 构建工具：{e.g., Vite}
- UI 库：{e.g., Ant Design}

### 基础设施
- 部署：{e.g., Docker + Nginx}
- CI/CD：{e.g., GitHub Actions}

---

## 系统架构

### 架构图
```
{用 ASCII 或 Mermaid 画架构图}
```

### 模块划分

| 模块 | 职责 | 主要文件 |
|------|------|---------|
| {模块1} | {职责} | {路径} |
| {模块2} | {职责} | {路径} |

---

## 数据模型

### {模型名称}

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | UUID | PK | 主键 |
| {field} | {type} | {constraint} | {description} |

---

## API 设计

### {API 组名}

| Method | Path | Description | Auth |
|--------|------|-------------|------|
| POST | /api/v1/{resource} | {描述} | {是/否} |
| GET | /api/v1/{resource} | {描述} | {是/否} |

---

## 目录结构

```
{project_root}/
├── src/
│   ├── {module_1}/
│   └── {module_2}/
├── tests/
├── docs/
└── ...
```

---

## 依赖约束

### 必须遵守的接口约定
- {约定 1}
- {约定 2}

### 第三方依赖
| 依赖 | 版本 | 用途 |
|------|------|------|
| {dep} | {ver} | {purpose} |

---

## 安全设计

- 认证方式：{e.g., JWT}
- 密码存储：{e.g., bcrypt}
- API 鉴权：{e.g., middleware}

---

## 测试策略

- 单元测试框架：{e.g., pytest / vitest}
- 集成测试：{策略}
- 测试命令：`{e.g., npm test / pytest}`
