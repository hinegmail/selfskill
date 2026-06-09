# 在宥丝巾 AI 营销方案生成辅助系统 - 需求文档

## 项目概述

### 产品定位
THE ZaiYou AI Promoter 系统 SHALL 是一个内部使用的 AI 营销内容生成与知识管理工具，专为在宥品牌营销、销售、产品和管理人员设计。

### 核心价值
WHERE 企业营销人员面临知识资产分散、文案产出效率低、品牌调性不稳定等挑战，THE ZaiYou AI Promoter 系统 SHALL 通过整合自有知识库、标准产品数据、品牌调性、目标客群和竞品资料，结合本地 Ollama 大模型能力，快速生成符合"在宥"品牌特质的营销文案。

### 适用场景
THE ZaiYou AI Promoter 系统 SHALL 支持以下营销场景：
- 社交媒体种草文案（如小红书、微信朋友圈）
- 电商平台详情页文案
- 直播讲解词与话术
- 礼赠方案与活动推广
- 竞品分析与对标方案

### 责任边界
- AI 生成的内容仅作为内部创作参考，所有对外发布内容必须经人工确认
- 系统不提供一键发布至外部平台的功能
- 所有敏感数据（品牌文案、产品资料）必须本地私有化部署

---

## 术语表（Glossary）

| 术语 | 定义 |
|------|------|
| **ZaiYou_AI_Promoter** | 在宥丝巾AI营销方案生成辅助系统 |
| **Marketing_Staff** | 普通营销或销售人员（员工角色） |
| **Marketing_Manager** | 营销主管或产品经理（管理层角色） |
| **Administrator** | 系统管理员 |
| **RBAC** | 基于角色的访问控制（Role-Based Access Control） |
| **RLS** | 行级安全性（Row-Level Security） |
| **JSONB_Permission_Scope** | 存储权限标签的JSON结构化字段 |
| **Knowledge_Document** | 上传至系统的知识库文档（.docx/.pdf/.md/.txt/.xlsx） |
| **Knowledge_Chunk** | 从Knowledge_Document切分出的知识单元 |
| **Metadata_Cache** | 冗余存储在Knowledge_Chunk表中的权限和文档元数据 |
| **Product_Master_Data** | 标准产品主表，包含产品基本属性 |
| **Prompt_Template** | AI生成配置模板，包含系统提示词、少样本示例、平替规则 |
| **RAG** | 检索增强生成（Retrieval Augmented Generation） |
| **RRF_Algorithm** | 倒排融合排序算法（Reciprocal Rank Fusion） |
| **SSE** | 服务端事件推送（Server-Sent Events），用于流式输出 |
| **XML_Tags_Isolation** | 使用XML标签在Prompt中隔离自有事实与竞品风格 |
| **Thesaurus_Rules** | 字词平替规则集合，用于质量控制 |
| **Competitor_Document** | 竞品参考资料 |
| **Generation_Task** | 单次AI生成任务 |
| **Generation_Output** | 单次生成任务的输出结果 |
| **Output_Version_Chain** | 基于parent_output_id形成的生成结果版本链条 |
| **GUC_Environment_Variable** | PostgreSQL会话级配置参数，用于O(1)级RLS过滤 |
| **HNSW_Index** | 层级可导航小世界索引（用于向量检索） |
| **GIN_Index** | 广义倒排索引（用于全文检索） |
| **Publishing_Workflow** | 知识文档发布审核流程：草稿→待审→已发布/驳回→归档 |

---

## 核心用户角色与权限

### 需求 1：用户角色与RBAC权限体系

**用户故事**：作为系统管理员，我想要对用户进行角色分配，以便根据职责划分系统操作权限。

#### 验收标准

1. THE ZaiYou_AI_Promoter 系统 SHALL 定义三类用户角色：
   - Marketing_Staff（普通营销/销售人员）
   - Marketing_Manager（营销主管/产品经理）
   - Administrator（系统管理员）

2. WHEN 用户登录系统，THE ZaiYou_AI_Promoter 系统 SHALL 根据其用户表中的 `role` 字段自动加载对应权限集

3. IF Marketing_Staff 用户尝试访问"管理员后台"或"用户权限管理"功能，THEN THE ZaiYou_AI_Promoter 系统 SHALL 返回403权限不足错误

4. WHEN Marketing_Manager 用户上传知识库文档，THE ZaiYou_AI_Promoter 系统 SHALL 允许其审核和发布，但普通Marketing_Staff 用户 SHALL NOT 拥有审核权限

5. WHILE Administrator 用户在系统中操作，THE ZaiYou_AI_Promoter 系统 SHALL 绕过所有行级安全过滤，允许查看全量数据

6. THE ZaiYou_AI_Promoter 系统 SHALL 记录每个角色的标准操作权限清单于后台配置表，并支持管理员查看权限定义

---

### 需求 2：行级安全性（RLS）与权限标签隔离

**用户故事**：作为营销主管，我想要上传部门内部的营销方案资料，并控制其他部门无法访问，以保护商业敏感信息。

#### 验收标准

1. THE ZaiYou_AI_Promoter 系统 SHALL 为每个Knowledge_Document 和知识切片（Knowledge_Chunk）冗余存储 `permission_scope` JSONB字段，包含以下结构化信息：
   ```json
   {
     "visibility": "custom",
     "roles": ["marketing_staff", "marketing_manager"],
     "projects": ["project_id_1", "project_id_2"],
     "users": ["1001", "1002"],
     "departments": ["10", "20"]
   }
   ```

2. WHEN 后端建立数据库连接并初始化会话，THE ZaiYou_AI_Promoter 系统 SHALL 执行一次GUC环境变量注入：
   ```sql
   SET LOCAL app.current_user_id = 'user_id';
   SET LOCAL app.current_user_role = 'role_type';
   SET LOCAL app.current_user_department = 'dept_id';
   ```

3. THE ZaiYou_AI_Promoter 系统 SHALL 在RLS策略中使用 `current_setting()` 函数完成O(1)级常数时间权限校验，严禁在RLS USING子句中编写 JOIN 多表查询

4. IF Knowledge_Document 的 `visibility` 字段值为 'all'，THEN THE ZaiYou_AI_Promoter 系统 SHALL 允许所有已认证用户访问（前提是文档状态为 published）

5. IF Knowledge_Document 的 `visibility` 字段值为 'private'，THEN THE ZaiYou_AI_Promoter 系统 SHALL 仅允许创建人和Administrator 角色用户访问

6. IF Knowledge_Document 的 `visibility` 字段值为 'custom'，THEN THE ZaiYou_AI_Promoter 系统 SHALL 判定当前用户的role、user_id 或 department_id 是否在permission_scope的对应数组中，任一匹配即允许访问

7. WHERE 用户修改Knowledge_Document的permission_scope后，THE ZaiYou_AI_Promoter 系统 SHALL 异步触发同步机制，更新该文档下所有Knowledge_Chunk记录的metadata_cache中的permission_scope字段

---

## 登录与账号管理

### 需求 3：企业微信OAuth扫码登录（P0）

**用户故事**：作为营销员工，我想要使用企业微信扫码登录系统，以便安全快捷地访问系统。

#### 验收标准

1. WHEN 用户在登录页面点击"企业微信登录"并完成扫码，THE ZaiYou_AI_Promoter 系统 SHALL 通过企业微信OAuth接口获取用户的wecom_user_id

2. THE ZaiYou_AI_Promoter 系统 SHALL 检查 users 表是否存在该wecom_user_id的记录
   - IF 记录存在且status为'active'或'disabled'，THEN 允许直接登录
   - IF 记录不存在或status为'pending'，THEN 阻止登录并返回提示："您的账号待分配，请联系系统管理员"

3. WHEN 用户通过企业微信首次认证，THE ZaiYou_AI_Promoter 系统 SHALL 自动在users表中创建新用户记录，默认status为'pending'，role为NULL

4. THE ZaiYou_AI_Promoter 系统 SHALL 从企业微信OAuth响应中提取用户name、department_id、avatar_url等字段并保存至users表

5. WHERE 企业微信服务暂时不可用，THE ZaiYou_AI_Promoter 系统 SHALL 允许用户切换至本地账号密码登录作为备用通道

#### OAuth2.0 实现规范

本系统已注册企业微信 OAuth2.0 应用，应用详情如下：

| 配置项 | 值 |
|--------|-----|
| 应用名称 | AIPromoterClient |
| Client ID | 66d3bde2e3b149189f81acf3506999ce |
| Client Secret | 6ec7527d915d46ab9cfe2b942ec567b3 |
| 回调地址 | http://localhost:8080/oauth/callback |
| OAuth2.0 服务地址 | https://oa-test.hxhdt.com |

#### OAuth2.0 流程规范

**步骤1：构造授权链接**
- 后端动态生成授权链接，引导用户访问企业微信授权页面
- 链接格式：`GET https://oa-test.hxhdt.com/api/oauth/authorize?client_id=66d3bde2e3b149189f81acf3506999ce&redirect_uri=http://localhost:8080/oauth/callback&response_type=code`
- 参数说明：
  - `client_id`：应用注册时获取的 Client ID
  - `redirect_uri`：回调地址，必须与应用注册时一致
  - `response_type`：固定值 `code`

**步骤2：用户扫码授权**
- 用户在企业微信扫码页面确认授权
- 企业微信回调到华享汇服务端，再由华享汇回调到本系统的 `redirect_uri`
- 回调携带参数：`code`（授权码）和 `state`（防CSRF参数）

**步骤3：后端换取 Access Token**
- 后端接收回调请求，提取 `code` 参数
- 向企业微信 OAuth 服务端发送 POST 请求换取 access_token
- 请求地址：`POST https://oa-test.hxhdt.com/api/oauth/token`
- 请求头：`Content-Type: application/x-www-form-urlencoded`
- 请求体：
  ```
  client_id=66d3bde2e3b149189f81acf3506999ce
  &client_secret=6ec7527d915d46ab9cfe2b942ec567b3
  &grant_type=authorization_code
  &code={AUTHORIZATION_CODE}
  ```
- 响应示例：
  ```json
  {
    "access_token": "e1b2c3d4...",
    "expires_in": 7200
  }
  ```

**步骤4：获取用户信息**
- 后端使用 access_token 获取用户详细信息
- 请求地址：`GET https://oa-test.hxhdt.com/api/oauth/userinfo`
- 请求头：`Authorization: Bearer {ACCESS_TOKEN}`
- 响应示例：
  ```json
  {
    "userid": "fanglin",
    "name": "方林",
    "email": "fanglin@example.com",
    "avatar": "https://.../avatar.jpg"
  }
  ```
- THE ZaiYou_AI_Promoter 系统 SHALL 将响应中的 `userid` 字段映射至 `users.wecom_user_id`，`name` 映射至 `users.name`，`avatar` 映射至 `users.avatar_url`

#### Access Token 生命周期管理

THE ZaiYou_AI_Promoter 系统 SHALL 实现以下 token management 规范：

1. WHEN 获取到 access_token，THE 系统 SHALL 存储 token 和 expires_in 值，计算过期时间为 `current_time + expires_in（秒）`

2. WHEN 使用 access_token 调用用户信息接口前，THE 系统 SHALL 检查 token 是否过期
   - IF token 已过期，THEN 系统 SHALL 使用存储的 refresh_token 或 code 重新获取新的 access_token
   - IF token 未过期，THEN 直接使用现有 token

3. WHEN 首次登录成功后，THE 系统 SHALL 仅保存用户信息（userid, name, email, avatar）至 users 表，不长期存储 access_token（token 仅在单次会话中使用）

---

### 需求 4：本地账号密码登录（P0，备用通道）

**用户故事**：作为系统管理员，我想要为企业微信不可用的场景配置备用本地登录账号。

#### 验收标准

1. THE ZaiYou_AI_Promoter 系统 SHALL 提供管理员后台界面，允许Administrator角色用户创建和管理本地登录账号

2. WHEN Administrator 在后台创建本地账号时，THE ZaiYou_AI_Promoter 系统 SHALL 要求输入username和password，并自动计算password_hash存入users表（密码明文不可存储）

3. WHEN 用户使用本地账号登录，THE ZaiYou_AI_Promoter 系统 SHALL 验证username和password_hash是否匹配，匹配则允许登录

4. IF 输入的password错误超过3次，THEN THE ZaiYou_AI_Promoter 系统 SHALL 锁定该账号15分钟，并通知Administrator

5. THE ZaiYou_AI_Promoter 系统 SHALL 对所有本地登录尝试记录审计日志，包括timestamp、username、成功/失败状态、客户端IP

---

### 需求 5：用户账号生命周期管理（P0）

**用户故事**：作为系统管理员，我想要管理用户的启用/禁用/锁定状态，以控制用户系统访问权限。

#### 验收标准

1. THE ZaiYou_AI_Promoter 系统 SHALL 为用户定义以下状态转移：
   - pending（新用户，待分配） → active（正常使用）
   - active ↔ disabled（禁用）
   - active/disabled → locked（锁定，通常因安全事件）

2. WHEN Administrator 在后台将用户status改为'disabled'，THE ZaiYou_AI_Promoter 系统 SHALL 立即生效，该用户下次登录时返回"账号已被禁用"错误

3. WHEN 用户处于'locked'状态，THE ZaiYou_AI_Promoter 系统 SHALL 禁止其登录，并在后台显示锁定原因和自动解锁时间

4. WHEN Administrator 解除用户锁定或改为'active'状态，THE ZaiYou_AI_Promoter 系统 SHALL 生成审计记录并通知相关用户

5. THE ZaiYou_AI_Promoter 系统 SHALL 记录每次用户状态变更的操作人、操作时间、变更原因至audit_logs表

---

## 产品主数据管理

### 需求 6：标准产品主表与基本属性（P0）

**用户故事**：作为营销人员，我想要从标准产品列表中选择产品，而不是手工输入，以确保数据准确性和统一性。

#### 验收标准

1. THE ZaiYou_AI_Promoter 系统 SHALL 维护 products 产品主表，包含以下核心字段：
   - product_code（款号/唯一编码）、name（标准名称）、category（品类）、size_spec（规格）、material（材质）、standard_price（标准零售价）、series_name（系列名称）、design_story（设计故事）、selling_points（卖点JSONB）、image_urls（图片URL数组）、is_giftable（是否适合礼赠）、target_audience_tags（目标人群标签）、status（启用/停用）

2. WHEN AI生成任务提交时，THE ZaiYou_AI_Promoter 系统 SHALL 要求用户通过下拉列表严格选择产品（product_id），不允许纯文本手工输入产品名称

3. THE ZaiYou_AI_Promoter 系统 SHALL 在生成任务、知识文档等数据表中添加product_id外键关联，确保数据血缘可追溯

4. THE ZaiYou_AI_Promoter 系统 SHALL 通过 `GET /api/v1/products?status=active` 接口返回所有启用的产品列表，格式包含product_id、product_code、name、series_name等

5. WHEN 产品列表被用户访问，THE ZaiYou_AI_Promoter 系统 SHALL 按name字段自动排序展示，支持模糊搜索product_code或name关键词

---

### 需求 7：产品生命周期与状态联动（P0）

**用户故事**：作为产品经理，当某款产品售罄或下线时，我想要自动停用相关营销文案和知识库资料，以避免AI继续引用过期数据。

#### 验收标准

1. THE products 表 SHALL 包含 status 字段，取值为 'active'（启用）或 'inactive'（停用）

2. WHEN Administrator 或 Marketing_Manager 将 products.status 从 'active' 改为 'inactive'，THE ZaiYou_AI_Promoter 系统 SHALL 立即触发异步任务完成以下操作：
   - 扫描 knowledge_documents 表，找到所有 product_id 匹配且 status='published' 的文档
   - 自动将这些文档的 status 改为 'archived'
   - 通过 metadata_cache 同步机制，更新对应 knowledge_chunks 的 metadata_cache.status

3. WHILE 产品状态为 'inactive'，THE ZaiYou_AI_Promoter 系统 SHALL 在 RAG 检索中自动过滤掉该产品相关的 knowledge_chunks（metadata_cache.status != 'published'）

4. WHEN AI生成任务提交时，IF 关联 of product_id 的 status='inactive'，THEN THE ZaiYou_AI_Promoter 系统 SHALL 返回HTTP 400错误，消息为："该产品已下线停用，无法发起新的生成任务"

5. THE ZaiYou_AI_Promoter 系统 SHALL 记录每次产品状态变更的时间、操作人、变更原因至audit_logs表

---

## 知识库管理

### 需求 8：多格式文档上传与解析（P0）

**用户故事**：作为营销主管，我想要上传各种格式的知识文档（如Word、PDF、Excel）到系统，以建立统一的知识库。

#### 验收标准

1. THE ZaiYou_AI_Promoter 系统 SHALL 支持以下文档格式上传：
   - .docx（Microsoft Word）
   - .pdf（PDF文档）
   - .md（Markdown）
   - .txt（纯文本）
   - .xlsx（Microsoft Excel）

2. WHEN 用户上传文档时，THE ZaiYou_AI_Promoter 系统 SHALL 验证文件类型和大小（建议单文件≤50MB），拒绝非允许格式的文件

3. THE ZaiYou_AI_Promoter 系统 SHALL 将上传的文档存储至安全的本地文件系统或对象存储，并在 knowledge_documents 表中记录file_name、file_type、file_path等元数据

4. FOR .xlsx 文档，THE ZaiYou_AI_Promoter 系统 SHALL 采用结构化切片机制：
   - 按Sheet读取表头（列名）
   - 将每行数据与列名结合转换为结构化JSON，例如：`{"产品":"微醺系列","渠道":"小红书","核心卖点":"桑蚕丝材质与东方纹样"}`
   - 在Knowledge_Chunk的metadata_cache中记录source_file_id、sheet_name、row_index、column_headers等追溯信息

5. FOR .docx/.pdf/.md/.txt 文档，THE ZaiYou_AI_Promoter 系统 SHALL 进行文本清洗和段落切分，设定窗口大小500~800字、重叠度80~150字，防止跨切片信息丢失

6. THE ZaiYou_AI_Promoter 系统 SHALL 在上传后自动创建 knowledge_documents 记录，初始status为'draft'（草稿），不参与RAG检索

---

### 需求 9：知识库双路索引构建与检索（P0）

**用户故事**：作为系统，我需要对知识库进行高效索引，支持语义和全文混合检索，以提升知识库查询准确率。

#### 验收标准

1. WHEN 文档上传并切分后，THE ZaiYou_AI_Promoter 系统 SHALL 为每个Knowledge_Chunk执行以下索引操作：

2. **语义路索引**：
   - THE ZaiYou_AI_Promoter 系统 SHALL 使用本地嵌入模型（如 gte-large-zh 或 bge-m3）将chunk内容转换为1024维向量
   - 向量存储在 knowledge_chunks.embedding 字段
   - 建立pgvector HNSW索引以支持快速向量相似度搜索

3. **全文路索引**：
   - THE ZaiYou_AI_Promoter 系统 SHALL 使用PostgreSQL中文分词器对chunk内容进行分词
   - 转换为tsvector格式存储
   - 建立GIN倒排索引以支持全文检索

4. WHEN AI生成任务执行RAG检索时，THE ZaiYou_AI_Promoter 系统 SHALL 并行执行：
   - 语义检索：余弦相似度Top-K1
   - 全文检索：ts_rank相关度Top-K2

5. THE ZaiYou_AI_Promoter 系统 SHALL 采用RRF倒排融合算法重排两路检索结果，计算公式为：
   $$RRF\_Score(d) = \sum_{m \in M} \frac{1}{60 + r_m(d)}$$
   其中k=60，抽取RRF_Score最高的Top-N个切片作为最终RAG上下文

6. WHERE 检索参数包含product_id过滤时，THE ZaiYou_AI_Promoter 系统 SHALL 额外添加 `metadata_cache.product_id = input_product_id` 的条件过滤

---

### 需求 10：元数据缓存同步机制（P0）

**用户故事**：作为系统架构，我需要在Knowledge_Chunk表中冗余存储权限和文档元数据，避免RAG检索时的多表JOIN导致性能问题。

#### 验收标准

1. THE knowledge_chunks 表 SHALL 包含 metadata_cache JSONB字段，冗余存储以下信息：
   - status（文档发布状态）
   - permission_scope（权限标签）
   - product_id、product_code（产品信息）
   - source_file_id、sheet_name、row_index、column_headers（文档追溯信息）

2. WHEN Knowledge_Document 的status从任何值变更为'published'，THE ZaiYou_AI_Promoter 系统 SHALL 同步更新该文档下所有chunks的 metadata_cache.status='published'

3. WHEN Knowledge_Document 的status变更为'archived'或'rejected'，THE ZaiYou_AI_Promoter 系统 SHALL 同步更新对应chunks的metadata_cache.status

4. WHEN Knowledge_Document 的permission_scope被修改，THE ZaiYou_AI_Promoter 系统 SHALL 异步触发更新任务（或通过数据库触发器），刷新该文档所有chunks的metadata_cache.permission_scope

5. WHEN Knowledge_Document 被物理删除，THE ZaiYou_AI_Promoter 系统 的数据库级级联删除策略 SHALL 自动清除相关的knowledge_chunks记录（ON DELETE CASCADE）

6. THE ZaiYou_AI_Promoter 系统 SHALL 在RAG检索的WHERE条件中直接使用metadata_cache字段进行过滤，避免JOIN操作

---

### 需求 11：知识库发布审核工作流（P0）

**用户故事**：作为营销主管，我想要审核和发布营销人员上传的知识文档，确保内容质量和品牌一致性。

#### 验收标准

1. THE knowledge_documents 表 SHALL 包含status字段，支持以下状态转移：
   - draft（草稿，仅创建人可编辑）
   - pending（待审，提交审核）
   - published（已发布，参与RAG检索）
   - rejected（已驳回，含审核批注）
   - archived（已归档，不参与检索）

2. WHEN Marketing_Staff 上传知识文档，THE ZaiYou_AI_Promoter 系统 SHALL 将其初始状态设为'draft'

3. WHEN 创建人点击"提交审核"，THE ZaiYou_AI_Promoter 系统 SHALL 将文档status改为'pending'，并通知所有Marketing_Manager角色用户

4. WHEN Marketing_Manager 打开审核页面，THE ZaiYou_AI_Promoter 系统 SHALL 展示pending状态的文档列表，支持预览、批注、批准或驳回

5. WHEN Marketing_Manager 点击"批准"，THE ZaiYou_AI_Promoter 系统 SHALL 将文档status改为'published'，记录reviewed_by和published_at，并通知上传人

6. WHEN Marketing_Manager 点击"驳回"，THE ZaiYou_AI_Promoter 系统 SHALL 将文档status改为'rejected'，保存review_comment，并通知上传人修改

7. WHILE 文档status为'pending'或'rejected'或'draft'，THE ZaiYou_AI_Promoter 系统 SHALL 禁止该文档参与RAG检索

8. THE ZaiYou_AI_Promoter 系统 SHALL 记录每次状态转移的时间、操作人、原因至审计日志

---

## 竞品资料管理

### 需求 12：竞品资料上传与分类（P0）

**用户故事**：作为营销主管，我想要上传竞品参考资料并分类管理，以便AI在生成时可有选择地参考竞品风格。

#### 验收标准

1. THE ZaiYou_AI_Promoter 系统 SHALL 维护competitor_documents表，支持竞品资料的手动输入或文件上传

2. WHEN 用户上传竞品资料，THE ZaiYou_AI_Promoter 系统 SHALL 要求填写以下字段：
   - competitor_name（竞品名称）
   - source_type（来源：官网、社交媒体、app等）
   - compliance_note（合规说明，如"仅限文学风格参考"）
   - status（草稿/待审/已发布）

3. WHEN Marketing_Manager 审核竞品资料后状态改为'published'，THE ZaiYou_AI_Promoter 系统 SHALL 在AI生成任务的"参考竞品"选项中展示该资料

4. WHERE 用户开启"参考竞品"选项，THE ZaiYou_AI_Promoter 系统 SHALL 在生成表单中列出所有已发布的竞品资料供用户多选

5. WHILE 竞品资料status为'draft'或'pending'，THE ZaiYou_AI_Promoter 系统 SHALL 隐藏该资料，不允许在AI生成任务中选择

6. THE ZaiYou_AI_Promoter 系统 SHALL 为competitor_documents表应用同等的RLS权限控制，确保敏感竞品分析资料只对授权用户可见

---

## Prompt模板管理

### 需求 13：Prompt模板配置与字段管理（P0）

**用户故事**：作为系统管理员，我想要定义和管理Prompt模板，包括系统提示词、少样本示例和字词平替规则，以控制AI生成的风格 and 质量。

#### 验收标准

1. THE prompt_templates 表 SHALL 包含以下核心字段：
   - name（模板名称）
   - system_prompt（系统提示词，定义AI角色和基本约束）
   - few_shot_examples（JSONB，包含高质量少样本示例）
   - thesaurus_rules（JSONB，包含字词平替规则字典）
   - applicable_channels（适用渠道：xiaohongshu/wechat/e_commerce/all）
   - applicable_scenarios（适用场景标签）
   - version（模板版本号）
   - is_current（是否当前启用版本）
   - status（启用/停用）

2. WHEN Administrator 创建Prompt模板时，THE ZaiYou_AI_Promoter 系统 SHALL 允许填写system_prompt，其中应包含以下关键约束：
   - AI角色定位（如"你是在宥丝巾品牌官方AI内容专家"）
   - 事实来源约束（必须基于<zaiyou_brand_facts>标签的数据）
   - 竞品隔离约束（<competitor_reference_style>仅用于修辞风格参考）
   - 输出格式约束

3. THE few_shot_examples 字段 SHALL 存储JSONB数组，每个示例包含：
   - input（用户输入示例）
   - output（对应的高质量生成输出）
   - scenario（适用场景）
   - metadata（如渠道、语调标记）

4. THE thesaurus_rules 字段 SHALL 存储JSONB对象，定义词组替换字典，例如：
   ```json
   {
     "禁用词": ["闭眼入", "爆款", "家人们谁懂啊"],
     "替换词": ["静谧之选", "臻品", "亲爱的朋友"],
     "竞品品牌词": ["竞品A", "竞品B"]
   }
   ```

5. WHEN Administrator 或 Marketing_Manager 修改现有模板，THE ZaiYou_AI_Promoter 系统 SHALL 不执行UPDATE，而是自动创建新版本记录，新记录的version = 旧版本.version + 1

6. WHEN 新版本创建，THE ZaiYou_AI_Promoter 系统 SHALL 自动将旧版本的is_current改为FALSE，新版本的is_current改为TRUE

7. THE ZaiYou_AI_Promoter 系统 SHALL 记录模板的change_log（变更说明）和approved_by（审核人）信息

8. WHEN 创建生成任务时，THE ZaiYou_AI_Promoter 系统 SHALL 通过prompt_template_id严格指定使用的模板版本，不允许动态修改

---

## AI生成核心流程

### 需求 14：生成任务表单与参数录入（P0）

**用户故事**：作为营销人员，我想要通过简洁的表单启动一次AI生成任务，选择产品、渠道、场景等参数。

#### 验收标准

1. THE ZaiYou_AI_Promoter 系统 SHALL 在前端提供生成任务表单，包含以下必填字段：
   - product_id（产品选择，下拉单选，来自/api/v1/products接口）
   - channel（渠道选择，下拉单选：xiaohongshu/wechat/e_commerce/live/gift）
   - scenario（使用场景，文本输入，最大50字，如"七夕大促种草"）

2. THE ZaiYou_AI_Promoter 系统 SHALL 提供以下选填字段：
   - target_audience（目标人群，下拉单选或多选）
   - tone_style（语气调性，下拉单选，默认"优雅静谧"，可选"东方古典"、"知性大方"）
   - prompt_template_id（Prompt模板，下拉单选，根据channel和scenario推荐）
   - is_competitor_referenced（开启竞品参考，开关切换）
   - competitor_document_ids（竞品资料多选，仅在开启参考竞品时显示）
   - extra_requirements（额外要求，文本域，最大200字）

3. WHEN 用户未选择prompt_template_id，THE ZaiYou_AI_Promoter 系统 SHALL 根据channel和scenario自动推荐合适的模板并预选

4. WHEN 用户点击"生成"按钮，THE ZaiYou_AI_Promoter 系统 SHALL 执行前置校验：
   - 必填字段是否完整
   - product_id是否指向active状态产品
   - 若开启竞品参考，competitor_document_ids是否为published状态

5. IF 任何前置校验失败，THEN THE ZaiYou_AI_Promoter 系统 SHALL 在表单上方展示错误提示，阻止任务提交

6. WHEN 校验通过，THE ZaiYou_AI_Promoter 系统 SHALL 向后端POST `/api/v1/generator/tasks` 接口，传递表单数据

---

### 需求 15：RAG混合检索与RRF融合排序（P0）

**用户故事**：作为系统，我需要在生成任务提交后，执行高效的混合检索，召回最相关的知识库内容作为AI生成的上下文。

#### 验收标准

1. WHEN 生成任务提交后，THE ZaiYou_AI_Promoter 系统 的后端 SHALL 立即建立数据库连接并注入会话级GUC环境变量

2. THE ZaiYou_AI_Promoter 系统 SHALL 从 scenario 和 extra_requirements 拼接用户查询文本

3. THE ZaiYou_AI_Promoter 系统 SHALL 并行执行以下检索操作（基于生成任务的product_id）：

   **语义检索路径**：
   - 使用嵌入模型计算查询文本的向量表示
   - 通过pgvector HNSW索引查询余弦相似度最高的K1个知识块（建议K1=20）
   - 过滤条件：`metadata_cache.status='published' AND metadata_cache.product_id=? OR metadata_cache.product_id IS NULL`
   - 应用RLS过滤：metadata_cache.permission_scope与current_setting()匹配

   **全文检索路径**：
   - 使用PostgreSQL中文分词器对查询文本进行分词
   - 通过tsvector GIN索引查询ts_rank最高的K2个知识块（建议K2=20）
   - 同等的status、product_id和RLS过滤条件

4. WHEN 两路检索都完成后，THE ZaiYou_AI_Promoter 系统 SHALL 使用RRF算法融合排序：
   - 对每个Knowledge_Chunk计算RRF_Score = 1/(60+r_semantic) + 1/(60+r_fulltext)
   - 按RRF_Score降序排列
   - 抽取Top-N个块（建议N=5~10）作为最终上下文

5. THE ZaiYou_AI_Promoter 系统 SHALL 返回最终上下文集合及其来源信息（文档ID、块ID、权限标记）

---

### 需求 16：XML标签竞品事实隔离机制（P0）

**用户故事**：作为系统，我需要在Prompt中明确隔离自有事实与竞品风格参考，防止AI混淆或直接复制竞品信息。

#### 验收标准

1. WHEN 用户选择"开启竞品参考"并指定competitor_document_ids，THE ZaiYou_AI_Promoter 系统 SHALL 执行竞品资料检索

2. THE ZaiYou_AI_Promoter 系统 SHALL 使用XML标签在最终Prompt中刚性隔离两类内容：
   ```xml
   <zaiyou_brand_facts>
   [从RAG检索获得的在宥自有知识内容]
   </zaiyou_brand_facts>
   
   <competitor_reference_style>
   [从竞品资料中提取的参考内容]
   </competitor_reference_style>
   ```

3. THE system_prompt 字段 SHALL 包含以下强制约束条款：
   - "所有事实陈述必须且只能基于<zaiyou_brand_facts>数据"
   - "<competitor_reference_style>仅用于修辞手法、排版结构参考，严禁复制品牌词、参数、价格等事实"
   - "严禁在最终输出中包含任何'<'或'>'符号"

4. WHERE 用户未选择竞品参考，THE ZaiYou_AI_Promoter 系统 SHALL 仅拼装<zaiyou_brand_facts>标签，不输出<competitor_reference_style>

5. THE ZaiYou_AI_Promoter 系统 SHALL 记录本次Prompt的完整快照（含XML标签、few-shot示例、thesaurus规则）至generation_tasks.prompt_snapshot字段

---

### 需求 17：SSE流式输出与思考步骤提示（P0）

**用户故事**：作为营销人员，我想要看到AI实时生成的文案，以及系统正在执行的步骤（如检索中、生成中），避免长时间等待的焦虑。

#### 验收标准

1. WHEN 生成任务提交，THE ZaiYou_AI_Promoter 系统 的后端 SHALL 立即返回HTTP 200 OK，建立SSE（Server-Sent Events）流式连接

2. BEFORE 开始AI推理，THE ZaiYou_AI_Promoter 系统 SHALL 通过SSE发送多个"stage"事件，展示以下处理步骤（每步耗时≤500ms）：
   ```
   event: stage
   data: {"step": "retrieving", "message": "正在执行RRF混合检索自有事实资料...", "elapsed_ms": 450}
   
   event: stage
   data: {"step": "isolating", "message": "已应用XML Tags隔离竞品事实，组装Prompt快照...", "elapsed_ms": 820}
   
   event: stage
   data: {"step": "injecting", "message": "正在载入Few-Shot示例并应用Thesaurus调性平替...", "elapsed_ms": 1200}
   
   event: stage
   data: {"step": "generating", "message": "东方美学调性已就绪，AI开始流式生成方案正文：", "elapsed_ms": 1500}
   ```

3. WHEN AI模型开始生成输出，THE ZaiYou_AI_Promoter 系统 SHALL 通过SSE逐字符或按短词元组实时推送"chunk"事件

4. THE ZaiYou_AI_Promoter 系统 的首字输出延迟 SHALL ≤ 5秒（从任务提交到首个文字chunk返回）

5. WHEN 生成完成（通常10~30秒），THE ZaiYou_AI_Promoter 系统 SHALL 发送"result"事件，包含完整output_content、task_id、output_id、version_code、risk_level等

6. IF SSE连接在生成过程中断开，THE ZaiYou_AI_Promoter 系统 SHALL 保持任务在后端继续执行，用户重新连接时可恢复状态

---

### 需求 18：Thesaurus字词平替与拦截机制（P0）

**用户故事**：作为系统，我需要在生成后自动检测和修正低俗网感词、广告法违规词，以及竞品词漏出，确保输出内容符合品牌调性。

#### 验收标准

1. THE Thesaurus 清洗机制 SHALL 分为三个阶段：

   **第一阶段（生成前注入）**：
   - WHEN 组装Prompt时，THE ZaiYou_AI_Promoter 系统 SHALL 从prompt_template的thesaurus_rules中提取禁用词和替换词字典
   - 动态注入Prompt中的系统指令，如："避免使用以下词汇：[禁用词列表]，如使用请用[替换词列表]替代"

   **第二阶段（生成中）**：
   - 该阶段依赖本地大模型的instruction-following能力，系统不干预

   **第三阶段（生成后扫描）**：
   - WHEN AI完成生成，THE ZaiYou_AI_Promoter 系统 在内存中对output_content执行以下扫描操作
   - 构建禁用词关键词树（Aho-Corasick或双数组Trie），快速全匹配扫描
   - 检测广告法绝对化用语（"最"、"永不"等）和虚假功效词
   - **关键检测**：扫描本次检索所参考的所有竞品品牌词是否出现在输出中

2. IF 检测到**低风险调性词**（如"闭眼入"、"爆款"、"家人们"），THEN THE ZaiYou_AI_Promoter 系统 SHALL：
   - 在内存中查询thesaurus_rules中的替换词
   - 自动执行文本替换，例如"闭眼入" → "静谧之选"
   - 将替换后的output_content保存至数据库
   - 在generation_outputs的risk_level字段标记为"low"或"medium"
   - SSE继续流式渲染修正后的文本给前端

3. IF 检测到**竞品品牌词污染**（如输出中出现"某竞品名称" 或其商标词），THEN THE ZaiYou_AI_Promoter 系统 SHALL：
   - 立即触发强拦截机制
   - 停止SSE流式推送
   - 将generation_task的status标记为'failed'
   - 在generation_outputs表不创建任何记录
   - 在audit_logs中记录"竞品词污染"事件
   - 向前端返回SSE错误事件，通知用户"输出内容检测到合规风险，已自动中止"

4. IF 检测到**中高风险合规词**（广告法违规、虚假功效），THEN THE ZaiYou_AI_Promoter 系统 SHALL：
   - 仍然保存输出结果
   - 在generation_outputs的risk_level字段标记为"high"
   - 在risk_notes字段记录具体检测到的问题和修改建议
   - 在前端展示独立的"风险提示区块"，突出显示问题词语和建议改法

5. THE ZaiYou_AI_Promoter 系统 SHALL 定期更新和优化禁用词和竞品词库，支持Administrator动态修改

---

### 需求 19：SSE断线重连与任务恢复（P0）

**用户故事**：作为营销人员，如果我的网络连接中断或浏览器意外刷新，我希望系统能恢复任务状态，而不是丢失已生成的内容。

#### 验收标准

1. WHEN AI生成任务创建，THE ZaiYou_AI_Promoter 系统 的后端 SHALL 立即生成唯一的task_id并持久化至generation_tasks表

2. THE generation_tasks 表 SHALL 包含以下状态追踪字段：
   - status（queued/processing/completed/failed）
   - started_at（任务开始时间）
   - completed_at（任务完成时间）
   - error_message（错误消息，若失败）

3. WHEN SSE连接建立时，THE ZaiYou_AI_Promoter 系统 SHALL 返回task_id给前端，以便用户存储和后续恢复

4. IF SSE连接异常断开，THE ZaiYou_AI_Promoter 系统 的后端 SHALL 继续处理任务，不因连接断开而中止

5. WHEN 用户的前端SSE连接断开后重新连接，THE ZaiYou_AI_Promoter 系统 SHALL 提供恢复接口：
   ```
   GET /api/v1/generator/tasks/{task_id}/stream?resume=true
   ```

6. THE 恢复接口 SHALL 返回以下信息：
   ```json
   {
     "task_id": 8802,
     "status": "processing",
     "already_generated_content": "已生成的部分文案...",
     "remaining_output": "剩余生成的部分...",
     "completed": false,
     "resume_expire_seconds": 300
   }
   ```

7. WHERE 任务已完成（status='completed'），THE 恢复接口 SHALL 返回完整的generation_output记录及其元数据

8. IF 用户在任务完成后刷新页面，THE ZaiYou_AI_Promoter 系统 的历史列表页 SHALL 显示该任务及其完整结果

9. WHERE 任务status为'failed'，THE 恢复接口 SHALL 返回failure原因，允许用户查看错误信息并选择重新提交

---

### 需求 20：生成任务版本演进与"再优化"流程（P0）

**用户故事**：作为营销人员，我想要基于一个已生成的文案方案进行二次优化或修改，系统应该自动跟踪版本关系。

#### 验收标准

1. THE generation_outputs 表 SHALL 包含以下版本管理字段：
   - output_id（输出唯一ID，主键）
   - task_id（关联的generation_task）
   - parent_output_id（父版本output_id，允许NULL表示初始版本）
   - version_code（版本序号：1, 2, 3...）
   - output_content（生成的文案内容）

2. WHEN 用户在历史记录中打开某个已生成的方案并点击"再优化"，THE ZaiYou_AI_Promoter 系统 SHALL：
   - 弹出优化指令输入框（最大200字）
   - 读取原任务（parent_task）的所有入参（product_id、channel、scenario、prompt_template_id等）

3. WHEN 用户输入优化指令并提交，THE ZaiYou_AI_Promoter 系统 SHALL 创建新的generation_task，其中：
   - 继承原task的product_id、channel、prompt_template_id等基础参数
   - 将extra_requirements字段追加用户的优化指令
   - 新task的parent_output_id指向原output_id

4. WHEN 新task的生成完成，THE ZaiYou_AI_Promoter 系统 SHALL 创建generation_outputs记录，其中：
   - parent_output_id指向原output_id（形成版本链）
   - version_code = 原版本code + 1

5. WHERE 用户在历史列表中查看版本演进，THE ZaiYou_AI_Promoter 系统 SHALL 展示版本链的可视化树状结构（P1增强），一期可用列表和版本号标记

6. WHEN 用户对比两个版本，THE ZaiYou_AI_Promoter 系统 SHALL 支持横向展示两个output_content并高亮差异部分

---

## 生成结果管理与导出

### 需求 21：生成结果保存与查询（P0）

**用户故事**：作为营销人员，我想要查看我的所有历史生成记录，搜索特定产品或渠道的方案。

#### 验收标准

1. THE ZaiYou_AI_Promoter 系统 SHALL 完整保存每次生成任务的结果至generation_outputs表，包含以下字段：
   - output_id、task_id、output_content、risk_level、risk_notes、created_at

2. WHEN 用户打开"历史方案"页面，THE ZaiYou_AI_Promoter 系统 SHALL 根据RLS权限规则过滤可见的任务：
   - IF 用户是Administrator，THEN 显示全量任务
   - IF 用户是Marketing_Manager，THEN 显示本部门成员的任务（基于department_id过滤）
   - IF 用户是Marketing_Staff，THEN 仅显示本人的任务

3. THE ZaiYou_AI_Promoter 系统 的历史列表页 SHALL 支持以下过滤和搜索功能：
   - 按product_id过滤
   - 按channel过滤
   - 按created_at时间范围过滤
   - 按关键词搜索output_content（全文搜索）
   - 按risk_level过滤（全部/low/medium/high）

4. WHEN 用户点击某条历史记录，THE ZaiYou_AI_Promoter 系统 SHALL 展示以下详情：
   - 原始输入参数（product、channel、scenario、tone_style等）
   - 完整输出文案（output_content）
   - 生成时间、所用模板、风险等级
   - 版本演进关系（若有parent_output_id）

5. THE ZaiYou_AI_Promoter 系统 的历史列表 SHALL 按created_at降序排列，最新优先

---

### 需求 22：复制与导出功能（P0）

**用户故事**：作为营销人员，我想要快速复制生成的文案或导出为文件，以便在其他系统中使用。

#### 验收标准

1. WHEN 用户在结果详情页点击"复制"按钮，THE ZaiYou_AI_Promoter 系统 SHALL 将output_content内容复制至系统剪贴板

2. WHEN 复制操作完成，THE ZaiYou_AI_Promoter 系统 SHALL 在audit_logs中记录该操作，包含：
   - operation_type: "copy"
   - user_id、timestamp、ip_address、user_agent
   - output_id（复制的内容ID）

3. WHEN 用户点击"导出为Markdown"，THE ZaiYou_AI_Promoter 系统 SHALL 生成.md文件，包含：
   - 文件头部：产品名、渠道、场景、生成时间等元数据
   - 主体：output_content
   - 页脚：免责声明"本内容由AI生成，使用前需人工审核"

4. WHEN Markdown文件生成，THE ZaiYou_AI_Promoter 系统 SHALL 允许用户下载该文件

5. WHEN 导出操作完成，THE ZaiYou_AI_Promoter 系统 SHALL 在audit_logs中记录，operation_type: "export"，记录导出格式（markdown）

6. THE ZaiYou_AI_Promoter 系统 的导出功能 SHALL 支持以下文件格式（P0: Markdown，P1: DOCX）

---

## 安全审计与日志

### 需求 23：核心操作审计日志（P0）

**用户故事**：作为系统管理员，我想要追踪所有敏感操作（复制、导出、上传），以便进行安全审计。

#### 验收标准

1. THE ZaiYou_AI_Promoter 系统 SHALL 为以下操作创建审计日志记录至audit_logs表：
   - 复制生成文案（operation_type: "copy"）
   - 导出文件（operation_type: "export"）
   - 上传知识文档（operation_type: "upload"）
   - 删除文档（operation_type: "delete"）
   - 修改用户权限（operation_type: "permission_change"）
   - 产品状态变更（operation_type: "product_status_change"）
   - 文档发布/驳回（operation_type: "document_review"）

2. THE audit_logs 表 SHALL 记录以下信息：
   - log_id（唯一ID）
   - user_id（操作人）
   - operation_type（操作类型）
   - target_entity_id（目标实体ID，如output_id、document_id）
   - ip_address（操作者IP地址）
   - user_agent（浏览器/客户端标识）
   - timestamp（操作时间）
   - description（操作描述）

3. WHEN 用户执行复制或导出操作，THE ZaiYou_AI_Promoter 系统 的后端 SHALL 从请求头中提取X-Forwarded-For或REMOTE_ADDR获取真实IP

4. THE ZaiYou_AI_Promoter 系统 的后端 SHALL 从User-Agent请求头提取用户浏览器/客户端信息

5. WHERE Administrator 打开审计日志查询页面，THE ZaiYou_AI_Promoter 系统 SHALL 支持按时间范围、操作类型、用户、目标实体等维度过滤和搜索

6. THE ZaiYou_AI_Promoter 系统 SHALL 保留审计日志至少90天不可删除，仅允许归档

---

## 非功能需求

### 需求 24：性能与响应时间（NFR-Performance）

**用户故事**：作为系统用户，我想要获得快速响应，首字输出≤5秒，不会因为长时间等待而放弃使用。

#### 验收标准

1. WHEN 生成任务提交后，THE ZaiYou_AI_Promoter 系统 的首字输出延迟 SHALL ≤ 5秒

2. WHEN 用户打开历史列表页面，THE ZaiYou_AI_Promoter 系统 的页面加载时间 SHALL ≤ 2秒（包含首屏数据）

3. THE ZaiYou_AI_Promoter 系统 的知识库RAG检索耗时 SHALL ≤ 1秒（包括语义检索、全文检索、RRF融合）

4. WHILE RAG检索在处理，THE ZaiYou_AI_Promoter 系统 的思考步骤提示 SHALL 每步耗时 ≤ 500ms

5. THE ZaiYou_AI_Promoter 系统 的每次Thesaurus扫描（生成后）耗时 SHALL ≤ 200ms

---

### 需求 25：并发能力与排队管理（NFR-Concurrency）

**用户故事**：作为系统，我需要支持多个用户同时生成，当并发超过限制时应进入排队，而不是直接拒绝。

#### 验收标准

1. THE ZaiYou_AI_Promoter 系统 的本地Ollama大模型 SHALL 支持最多10个并发生成任务（基于本地硬件能力调整）

2. WHEN 当前生成任务数达到10时，新提交的任务 SHALL 自动进入排队队列（status: 'queued'）

3. WHEN 任务处于'queued'状态，THE ZaiYou_AI_Promoter 系统 的前端 SHALL 通过SSE展示排队位置和预估等待时间，例如"您前面有3个任务等待，预计等待约2分钟"

4. WHEN 某个generation_task完成，THE ZaiYou_AI_Promoter 系统 SHALL 自动将排队队列中的下一个任务转为'processing'状态

5. WHILE 任务处于'queued'状态超过1小时，THE ZaiYou_AI_Promoter 系统 SHALL 自动取消该任务，设置status: 'failed'，error_message: '排队超时，请重新提交'

---

### 需求 26：知识库检索准确率（NFR-Retrieval-Accuracy）

**用户故事**：作为系统，我需要确保RAG检索能准确召回相关知识库内容，尤其是对专有名词（如"山海经系列"）的支持。

#### 验收标准

1. THE ZaiYou_AI_Promoter 系统 的RAG混合检索 SHALL 对通用关键词达到≥95%的召回率（基于测试集评估）

2. WHERE 用户在scenario中输入"山海经系列"等产品系列名称，THE ZaiYou_AI_Promoter 系统 的全文索引路 SHALL能准确匹配包含该关键词的所有知识块

3. WHERE 知识库存在多个版本相似内容（如新旧文案版本），THE ZaiYou_AI_Promoter 系统 的RRF融合 SHALL能合理排序，优先返回最新或最相关的版本

---

### 需求 27：系统可用性（NFR-Availability）

**用户故事**：作为用户，我希望系统在工作时间内保持高可用，不会因为维护或故障而长时间不可用。

#### 验收标准

1. THE ZaiYou_AI_Promoter 系统 的目标可用性 SHALL ≥ 99%（年度目标）

2. WHEN 系统发生故障，THE ZaiYou_AI_Promoter 系统 SHALL 有自动故障转移机制或快速恢复流程，确保恢复时间RTO ≤ 15分钟

3. WHERE 进行计划维护，THE ZaiYou_AI_Promoter 系统 的维护时间 SHALL 安排在非工作时间（如每周日23:00-01:00），并提前5天通知用户

4. THE ZaiYou_AI_Promoter 系统 的本地Ollama模型 SHALL 有health check机制，若模型无响应，系统 SHALL 返回友好错误提示，而不是长时间挂起

---

### 需求 28：数据安全与本地部署（NFR-Security）

**用户故事**：作为公司，我需要确保所有品牌文案、产品资料和内部方案都在本地私有化部署，不向任何外部服务传输敏感数据。

#### 验收标准

1. THE ZaiYou_AI_Promoter 系统 的所有数据存储 SHALL 位于公司内网或私有服务器，不上传至任何云平台或第三方服务

2. THE ZaiYou_AI_Promoter 系统 的API请求 SHALL 仅调用本地Ollama服务，不向OpenAI、Claude等外部AI服务发送任何用户数据

3. WHEN 知识库文档上传，THE ZaiYou_AI_Promoter 系统 的文件存储位置 SHALL 设置访问权限，仅系统进程和授权管理员可访问

4. THE ZaiYou_AI_Promoter 系统 的数据库连接 SHALL 启用TLS加密（若跨网络通信），避免明文传输

5. WHERE 用户复制或导出生成的文案，THE ZaiYou_AI_Promoter 系统 在浏览器侧 SHALL 仅通过本地操作完成，不通过服务器中转

---

## 验收清单

### P0功能完整性验收

| 模块 | 功能项 | 验收标准 |
|------|--------|---------|
| **登录与权限** | 企业微信OAuth登录 | 支持扫码登录，新用户自动创建pending状态账号 |
| | 本地账号登录 | 管理员可创建本地账号，支持密码认证 |
| | RBAC权限体系 | 支持marketing_staff、marketing_manager、administrator三类角色 |
| | RLS行级过滤 | 基于permission_scope JSONB和GUC环境变量实现O(1)级过滤，无JOIN操作 |
| **产品主数据** | 标准产品主表 | 包含product_code、name、category等15个字段，支持启用/停用状态 |
| | 产品生命周期联动 | 产品inactive时自动归档相关知识文档，新生成任务被拦截 |
| **知识库** | 多格式上传 | 支持.docx/.pdf/.md/.txt/.xlsx格式 |
| | 结构化切片 | Excel按行转JSON，文本类按500~800字切片 |
| | 双路索引 | pgvector语义索引+tsvector全文索引 |
| | metadata_cache | knowledge_chunks冗余权限 and 文档元数据 |
| | 发布审核工作流 | draft→pending→published/rejected→archived状态转移 |
| **竞品资料** | 上传与分类 | 支持竞品资料上传，分类和发布审核 |
| **Prompt模板** | 模板配置 | 支持system_prompt、few_shot_examples、thesaurus_rules JSONB配置 |
| **生成任务** | 表单录入 | 产品下拉、渠道选择、场景输入、模板选择 |
| | RAG混合检索 | 语义+全文混合，RRF融合排序 |
| | XML隔离 | 自有事实与竞品内容刚性隔离 |
| | SSE流式输出 | 实时推送chunk数据，思考步骤提示≤500ms |
| | Thesaurus清洗 | 生成后扫描禁用词和竞品词，自动平替或强拦截 |
| | 任务恢复 | SSE断线重连，任务状态持久化恢复 |
| **版本管理** | 再优化流程 | parent_output_id版本链，支持版本演进 |
| **导出** | 复制文案 | 支持一键复制 |
| | Markdown导出 | 导出.md格式文件 |
| **审计** | 核心操作日志 | 记录复制、导出、上传等敏感操作的IP和UA |

---

## 附录：API契约简览

### 创建生成任务接口 (SSE流式)

```
POST /api/v1/generator/tasks
Headers: Accept: text/event-stream

Request Body:
{
  "product_id": 201,
  "prompt_template_id": 10,
  "channel": "xiaohongshu",
  "scenario": "七夕礼赠新品推广",
  "tone_style": "elegant",
  "is_competitor_referenced": true,
  "competitor_document_ids": [501, 502],
  "extra_requirements": "侧重东方神话美感"
}

Response (SSE Stream):
event: stage
data: {"step": "retrieving", "message": "正在执行RRF混合检索...", "elapsed_ms": 450}

event: chunk
data: {"chunk_content": "在", "index": 1}

event: result
data: {
  "task_id": 8802,
  "output_id": 9901,
  "output_content": "在漫漫岁月中...",
  "risk_level": "low"
}
```

### 恢复生成任务接口

```
GET /api/v1/generator/tasks/{task_id}/stream?resume=true

Response:
{
  "task_id": 8802,
  "status": "completed",
  "output_content": "完整输出内容...",
  "completed": true
}
```

### 产品列表接口

```
GET /api/v1/products?status=active&page=1&limit=50

Response:
{
  "code": 200,
  "data": {
    "list": [{
      "id": 201,
      "product_code": "ZY-SHJ-090",
      "name": "山海经系列真丝方巾",
      "series_name": "山海经",
      "category": "方巾"
    }],
    "total": 12
  }
}
```

---

## 文档变更历史

| 版本 | 日期 | 作者 | 变更说明 |
|------|------|------|---------|
| 1.0 | 2026-01-15 | 系统生成 | 初版需求文档，基于 requirements V2.3 生成，覆盖P0核心功能 |

---

**文档结束**

本需求文档遵循EARS句式规范和INCOSE质量标准，确保每项需求具体可测、责任明确、验收标准量化。
