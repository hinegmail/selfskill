# 项目导航舵盘 (STEERING)

> [!NOTE]
> 本文件是项目的“骨架与路标”。用于在避免 Token 爆仓的前提下，为 AI 快速建立高维项目认知。
> AI 每次启动会话时，**仅需要读取本文件**与 `STATUS.md`、`NEXT.md`，严禁在审计阶段全量读取超长原始文档。

---

## 🎯 1. 项目核心宗旨与终极目标

* **项目名称**: 在宥丝巾 AI 营销方案生成辅助系统 (ZaiYou AI Promoter)
* **核心价值**: 专为在宥品牌内部营销、销售、产品人员设计的 AI 内容生成与知识管理工具。通过整合自有知识库、标准产品主数据、品牌调性约束、目标客群标签与竞品资料，结合本地私有化部署的 Ollama 离线大模型，一键流式生成符合“在宥”优雅静谧品牌特质的营销文案（如小红书、微信公众号、直播话术、礼赠方案等）。
* **技术选型骨架**: 前端 Web (Vue3/React) + 后端 FastAPI/Express + 数据库 PostgreSQL 14+ (pgvector 向量检索 + GIN 中文分词倒排全文检索 + 行级安全性 RLS) + 大模型 Ollama (向量模型 gte-large-zh + 生成模型 llama2-zh/Qwen) + 任务队列 Redis/内存队列。

---

## 🗺️ 2. 全局架构与核心模块

* **认证与权限模块**: 实现企业微信 OAuth2.0 扫码登录与本地密码登录，在后端连接数据库建立会话时执行 GUC 注入会话级环境变量，在不使用多表 JOIN 联查的前提下通过 RLS 策略实现 O(1) 级的行级安全数据隔离。
* **RAG 混合检索模块**: 并行执行语义向量相似度搜索与全文搜索，结合 permission_scope 和 product_id 过滤。应用 RRF 倒排融合算法对双路结果进行重排，获取 Top-N 知识切片。
* **AI 生成与合规控制**: 负责 Prompt 模板管理与 XML 标签竞品事实隔离（物理隔离自有 facts 和竞品参考风格）。集成了 Thesaurus 字词平替三阶段清洗机制，包括禁用词自动替换、竞品词污染强制拦截及高风险违规词安全评级。
* **流式推送与任务调度**: 基于服务端事件推送 (SSE) 实现流式输出与思考步骤可视化展示。使用任务排队队列支持最多 10 个生成任务的并发控制。支持 SSE 断线重连与 parent_output_id 版本链式演进。
* **数据与文件管理**: 标准产品主数据 products 的 CRUD 关联。支持 .docx/.pdf/.md/.txt 以及结构化 .xlsx 文件的分 Sheet 解析、语义切分与元数据缓存同步更新。

---

## 🏁 3. 核心里程碑与当前阶段

* [~] **Milestone 1**: 基础设施与数据库 (Week 1-1.5) · Task 1 - Task 6
* [ ] **Milestone 2**: 核心认证与权限体系 (Week 1.5-2.5) · Task 7 - Task 12
* [ ] **Milestone 3**: 知识库系统 (Week 2.5-3.5) · Task 13 - Task 20
* [ ] **Milestone 4**: RAG与生成核心 (Week 3.5-4.5) · Task 21 - Task 24
* [ ] **Milestone 5**: SSE流式与版本管理 (Week 4.5-5.5) · Task 25 - Task 27
* [ ] **Milestone 6**: 前端UI与交互 (Week 5.5-6.5) · Task 28 - Task 32
* [ ] **Milestone 7**: 集成测试与质量 (Week 6.5-7.5) · Task 33 - Task 34
* [ ] **Milestone 8**: 部署与上线 (Week 7.5-8)

---

## 🧭 4. 原始文档路标索引 (INDEX)

当需要查阅非常具体的业务细节或接口定义时，AI 应当根据以下索引，**精准定位**并读取原始超长文档的特定章节或行范围，**禁止全量读取**。

| 原始大文件 | 章节/模块名称 | 行范围 (Line Range) | 核心内容提要 |
| :--- | :--- | :--- | :--- |
| **[requirements.md](file:///d:/Users/Administrator/Documents/Projects/selfskill/templates/ai/requirements.md)** | 项目概述与术语定义 | L1 - L57 | 产品定位、适用场景以及核心术语说明表 |
| | 核心用户角色与行级安全性 | L58 - L118 | 三类角色 RBAC 定义、JSONB 权限标签结构与 GUC 注入 RLS 校验逻辑 |
| | 登录与账号状态转移管理 | L119 - L253 | 企业微信 OAuth2.0 接入流程规范、本地登录与账号锁定机制 |
| | 产品主数据管理 | L254 - L295 | products 产品主表核心字段定义与产品状态和知识库归档状态的联动 |
| | 知识库解析与混合检索 | L296 - L408 | Word/PDF/Excel 切分方案、语义 pgvector 与全文 GIN 双路索引、RRF 算法 |
| | 竞品资料与模板管理 | L409 - L484 | 竞品分类与 RLS 权限控制、Prompt 模板版本递增与 thesaurus_rules 规则 |
| | AI生成核心流程控制 | L485 - L734 | 生成参数、XML 隔离、SSE 推送、Aho-Corasick 拦截、版本演进 |
| | 历史结果与安全审计 | L735 - L800+ | 方案查询过滤、Markdown 与 DOCX 复制导出、操作审计日志规范 |
| **[DESIGN.md](file:///d:/Users/Administrator/Documents/Projects/selfskill/templates/ai/DESIGN.md)** | 系统架构设计 | L3 - L98 | 前后端、网关、应用服务、数据库与 Ollama 全局架构，核心选型合理性 |
| | 前端架构设计 | L100 - L405 | 页面清单、组件划分状态管理交互流、表单 JSON 格式、SSE 前端 JS 伪代码 |
| | 后端架构设计与伪代码 | L407 - L800+ | FastAPI 登录回调、hybrid_search 混合检索及 RLS 注入 GUC SQL 实现、RRF Python 实现、Prompt 拼接 XML 逻辑、FastAPI 服务端 SSE 推送事件生成器 |
| **[TASKS.md](file:///d:/Users/Administrator/Documents/Projects/selfskill/templates/ai/TASKS.md)** | 任务概览与阶段划分 | L3 - L42 | 预计开发周期、优先级分布、关键路径及一至八阶段划分说明 |
| | 第一阶段任务 (Task 1-6) | L46 - L142 | 后端与前端框架初始化（Task 1-2）、PostgreSQL 建表与索引（Task 3-4）、RLS 策略与元数据缓存同步（Task 5-6） |
| | 第二阶段至第八阶段任务 | L143 - L630 | 各阶段 Task 详细描述、前置依赖及验收标准大纲 (行范围 L143 - L630) |
| | 执行依赖、风险评估与验收 | L633 - L708 | 并行执行序列、风险缓解表、功能/性能/安全性验收总结指标与下一步建议 |
