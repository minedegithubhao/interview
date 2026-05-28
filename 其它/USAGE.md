# PlotPilot 使用说明

更新日期：2026-04-21

本文记录本仓库在 macOS 本机开发环境下的实际启动方式、关键配置和本次验证结果。项目默认使用本地 SQLite 文件，不需要 PostgreSQL、MySQL、Redis 等外部服务；如果本机 Colima 中已有数据库或 Redis，默认不会被 PlotPilot 连接或修改。

如果你要按 PlotPilot 的创作流程审设定、大纲、章节、知识库和伏笔，见 [CREATIVE_REVIEW_MANUAL.md](CREATIVE_REVIEW_MANUAL.md)。

## 1. 运行环境

必需：

- Python 3.9+，本次验证使用 Python 3.12.7。
- Node.js 18+，本次验证使用 Node.js 25.8.1 / npm 11.12.1。
- 后端依赖：`requirements.txt`。
- 前端依赖：`frontend/package.json`。

可选：

- 本地向量模型依赖：`requirements-local.txt`，仅当启用本地 FAISS 向量检索或本地 embedding 时需要，体积较大。
- Windows 一键启动器：`tools/aitext.bat`，适合 Windows 桌面使用。
- Tauri 桌面构建：`frontend/src-tauri`，适合打包安装版。

## 2. 快速启动

### macOS 双击启动

仓库根目录提供 `PlotPilot.command`，在 Finder 中双击即可启动。它会：

- 检查 `python3`、`node`、`npm`、`curl`、`lsof`。
- 自动创建 `.venv` 并安装 `requirements.txt`。
- 自动安装前端依赖。
- 启动后端和前端，并打开浏览器。
- 默认启用自动驾驶守护进程。
- 复用已运行的 PlotPilot 服务；如果端口被其它服务占用，或已有后端是禁用守护进程的测试进程，则自动选择后续空闲端口。

首次使用如遇到权限问题，执行：

```bash
chmod +x PlotPilot.command scripts/start-mac.sh
```

可选环境变量：

| 配置 | 默认值 | 说明 |
| --- | --- | --- |
| `PLOTPILOT_BACKEND_PORT` | `8005` | macOS 启动器优先尝试的后端端口。 |
| `PLOTPILOT_FRONTEND_PORT` | `3000` | macOS 启动器优先尝试的前端端口。 |
| `PLOTPILOT_OPEN_BROWSER` | `1` | 设为 `0` 时不自动打开浏览器。 |
| `PLOTPILOT_HOST` | `127.0.0.1` | 本机监听地址。 |
| `DISABLE_AUTO_DAEMON` | `0` | 设为 `1` 时启动器也会禁用自动驾驶守护进程，仅建议冒烟测试使用。 |

### 后端

首次安装：

```bash
python3 -m venv .venv
.venv/bin/python -m pip install --upgrade pip
.venv/bin/pip install -r requirements.txt
```

开发启动：

```bash
DISABLE_AUTO_DAEMON=1 VECTOR_STORE_ENABLED=false \
  .venv/bin/python -m uvicorn interfaces.main:app --host 127.0.0.1 --port 8005
```

常用地址：

- API 根路径：`http://127.0.0.1:8005/`
- 健康检查：`http://127.0.0.1:8005/health`
- Swagger 文档：`http://127.0.0.1:8005/docs`

说明：

- 本地调试建议使用 `python -m uvicorn interfaces.main:app ...`，而不是 `python -m PlotPilot serve` 或 `cli.py serve`。`cli.py` 在端口占用时会尝试释放占用进程；如果本机 Colima 或其它服务占用了端口，直接 uvicorn 更可控。
- `DISABLE_AUTO_DAEMON=1` 会禁止启动时自动拉起自动驾驶守护进程，适合先做 API 冒烟验证。
- `VECTOR_STORE_ENABLED=false` 会关闭向量索引初始化，适合没有安装 `requirements-local.txt` 时启动。

### 前端

首次安装：

```bash
cd frontend
npm install --ignore-scripts --no-audit --no-fund
```

开发启动：

```bash
cd frontend
npm run dev -- --host 127.0.0.1 --port 3000
```

常用地址：

- 前端页面：`http://127.0.0.1:3000/`
- Vite 代理：`/api` 会转发到 `http://127.0.0.1:8005`

前端默认 API 基址是 `/api/v1`，由 `frontend/src/api/config.ts` 定义；Vite 代理由 `frontend/vite.config.ts` 定义。

## 3. 数据与存储

默认本地开发数据路径：

- SQLite 数据库：`data/aitext.db`
- 日志：`logs/aitext.log`
- 向量索引：`data/chromadb`
- 原型报告：`scripts/data/prototype_results/`

桌面生产构建可通过 `AITEXT_PROD_DATA_DIR` 改写数据根目录。设置后，数据库会变为：

```text
$AITEXT_PROD_DATA_DIR/aitext.db
```

Colima 兼容说明：

- 当前项目默认不连接 Colima 内的数据库、Redis 或其它容器服务。
- 默认数据库是 SQLite 文件，不监听网络端口。
- 默认后端端口是 `8005`，默认前端端口是 `3000`；如果这些端口被 Colima 转发或其它本机服务占用，换端口启动即可。
- 不要使用会自动杀端口进程的启动入口来处理 Colima 端口冲突，建议直接换端口，例如 `--port 8015`。

## 4. 关键配置参数

### 服务启动

| 配置 | 默认值 | 说明 |
| --- | --- | --- |
| `--host` | `127.0.0.1` | 后端或前端监听地址。 |
| `--port` | 后端 `8005` / 前端 `3000` | 本机开发端口。 |
| `DISABLE_AUTO_DAEMON` | 空 | 设为 `1` / `true` / `yes` 时，后端启动不自动拉起自动驾驶守护进程。 |
| `CORS_ORIGINS` | `*` | 后端 CORS 白名单，多个域名用逗号分隔。 |
| `LOG_LEVEL` | `INFO` | 日志级别：`DEBUG`、`INFO`、`WARNING`、`ERROR`、`CRITICAL`。 |
| `LOG_FILE` | `logs/aitext.log` | 后端日志文件。 |
| `DISABLE_SSL_VERIFY` | `false` | 设为 `true` 会清空部分请求的 CA bundle，仅用于代理 TLS 问题排查。 |

### LLM

LLM 配置有两条路径：

- `.env` / 系统环境变量：启动时读取。
- 前端工作台配置：写入 SQLite 的 `llm_profiles` / `llm_config_meta`，运行时优先用于控制面板。

常用环境变量：

| 配置 | 说明 |
| --- | --- |
| `LLM_PROVIDER` | 可选：`openai` / `anthropic` / `gemini`，用于指定优先使用的 provider。 |
| `OPENAI_API_KEY` | OpenAI 或 OpenAI-compatible 网关密钥。 |
| `OPENAI_BASE_URL` | OpenAI-compatible 网关地址。 |
| `OPENAI_MODEL` | 工作台默认 OpenAI 模型 ID。 |
| `ANTHROPIC_API_KEY` / `ANTHROPIC_AUTH_TOKEN` | Anthropic 或兼容网关密钥。 |
| `ANTHROPIC_BASE_URL` | Anthropic-compatible 网关地址。 |
| `ANTHROPIC_MODEL` | 工作台默认 Anthropic 模型 ID。 |
| `GEMINI_API_KEY` | Gemini 密钥。 |
| `GEMINI_BASE_URL` | Gemini API 地址，默认预设是 `https://generativelanguage.googleapis.com/v1beta`。 |
| `GEMINI_MODEL` | Gemini 模型 ID。 |
| `ARK_API_KEY` | 火山方舟 Ark 密钥。 |
| `ARK_BASE_URL` | 方舟地址，`.env.example` 中为 `https://ark.cn-beijing.volces.com/api/v3/chat/completions`。 |
| `ARK_MODEL` | 方舟模型或 Endpoint ID。 |
| `ARK_TIMEOUT` | 方舟请求超时，`.env.example` 中为 `120`。 |
| `ARK_REASONING_EFFORT` | 方舟推理强度，`.env.example` 中为 `medium`。 |
| `WRITING_MODEL` | 部分旧服务读取的写作模型 ID。 |
| `SYSTEM_MODEL` | 场记、审阅、宏观诊断等系统类任务模型 ID。 |

没有有效 LLM 配置时，部分工作流会退回 `MockProvider`；真实创作、真实原型和 AI 生成接口需要有效密钥和模型 ID。

### Embedding 与向量索引

| 配置 | 默认值 | 说明 |
| --- | --- | --- |
| `VECTOR_STORE_ENABLED` | `true` | 是否启用向量存储。未安装本地向量依赖时，调试可设为 `false`。 |
| `VECTOR_STORE_PATH` | `./data/chromadb` | 向量索引持久化目录。 |
| `EMBEDDING_SERVICE` | `openai` | `openai` 或 `local`。实际运行优先读取 SQLite 的 embedding 配置。 |
| `EMBEDDING_API_KEY` | 空 | 云端 embedding 密钥；未填时会尝试使用 `OPENAI_API_KEY`。 |
| `EMBEDDING_BASE_URL` | 空 | OpenAI-compatible embedding 地址。 |
| `EMBEDDING_MODEL` | 空 / 示例 `text-embedding-3-small` | 云端 embedding 模型 ID。 |
| `EMBEDDING_MODEL_PATH` | 示例 `./.models/bge-small-zh-v1.5` | 本地 embedding 模型路径。 |
| `LOCAL_EMBEDDING_MODEL_PATH` | 空 | SQLite 默认 embedding 配置读取的本地模型路径。 |
| `EMBEDDING_USE_GPU` | `true` | 本地 embedding 是否启用 GPU。 |

注意：`infrastructure/ai/chromadb_vector_store.py` 名称保留 ChromaDB 兼容性，实际实现是本地 FAISS。启用本地向量存储前需要安装：

```bash
.venv/bin/pip install -r requirements-local.txt
```

### 前端

| 配置 | 默认值 | 说明 |
| --- | --- | --- |
| `VITE_API_BASE_URL` | `/api/v1` | 浏览器模式 API 基址。Tauri 模式会根据后端端口动态改写。 |
| Vite dev `server.port` | `3000` | 见 `frontend/vite.config.ts`。 |
| Vite dev proxy `/api` | `http://127.0.0.1:8005` | 前端开发代理目标。 |

### 导出

| 配置 | 说明 |
| --- | --- |
| `PLOTPILOT_EXPORT_CJK_FONT` | 导出 PDF/DOCX 等涉及中文字体时可指定 CJK 字体路径。 |

## 5. 数据库迁移

后端启动时会自动创建/更新 SQLite schema，并应用 `infrastructure/persistence/database/migrations/*.sql`。

如果已有数据库出现缺表或缺列，也可以手动运行：

```bash
.venv/bin/python scripts/run_migrations.py
```

本次启动观察到 `add_macro_diagnosis_context_patch.sql` 在 `macro_diagnosis_results` 表创建前执行时会打印一次 warning，随后 `add_macro_diagnosis_results.sql` 被应用，后端仍可正常启动。若旧库反复出现相关错误，再运行上面的迁移脚本检查。

## 6. 原型验证脚本

模拟版，不调用真实 LLM：

```bash
.venv/bin/python scripts/prototypes/prototype_mock.py
```

真实版，会调用真实 LLM，预计 30-60 分钟并产生 API 费用：

```bash
.venv/bin/python scripts/prototypes/prototype_continuous_planning.py
```

真实版至少需要：

```bash
ANTHROPIC_API_KEY=...
# 可选
ANTHROPIC_BASE_URL=...
```

本次已验证模拟版：

- 运行命令：`.venv/bin/python scripts/prototypes/prototype_mock.py`
- 结果：30 章，75,000 字。
- 伏笔：总埋设 5，已回收 5，待回收 0，回收率 100.0%。
- 报告：`scripts/data/prototype_results/mock_prototype_report_20260421_084420.json`

## 7. 本次实际验证结果

验证时间：2026-04-21 08:44 CST。

通过：

- 后端依赖安装成功：`.venv/bin/pip install -r requirements.txt`
- 后端启动成功：`DISABLE_AUTO_DAEMON=1 VECTOR_STORE_ENABLED=false .venv/bin/python -m uvicorn interfaces.main:app --host 127.0.0.1 --port 8005`
- 健康检查通过：`GET /health` 返回 `status=healthy`，版本 `1.0.2`，守护进程未启动。
- 前端依赖安装成功：`npm install --ignore-scripts --no-audit --no-fund`
- 前端开发服务启动成功：`npm run dev -- --host 127.0.0.1 --port 3000`
- 前端页面可访问：`GET http://127.0.0.1:3000/` 返回 200。
- 前端代理可访问后端：`GET http://127.0.0.1:3000/api/v1/novels/` 返回 `[]`。
- 模拟原型验证通过。

当前发现的问题：

- `npm run build` 失败：TypeScript 找不到 `echarts`、`echarts/core`、`echarts/charts`、`echarts/components`、`echarts/renderers` 的声明文件。开发服务仍可启动。
- `pytest tests/unit/interfaces/api/test_dependencies.py -q` 失败 5 个 Qdrant 兼容测试：测试引用 `infrastructure.ai.qdrant_vector_store.QdrantVectorStore`，当前仓库中没有该模块，实际向量实现为 `infrastructure.ai.chromadb_vector_store.ChromaDBVectorStore`。

## 8. 常用排查

端口占用：

```bash
lsof -nP -iTCP:8005 -sTCP:LISTEN
lsof -nP -iTCP:3000 -sTCP:LISTEN
```

换端口启动后端：

```bash
DISABLE_AUTO_DAEMON=1 VECTOR_STORE_ENABLED=false \
  .venv/bin/python -m uvicorn interfaces.main:app --host 127.0.0.1 --port 8015
```

换端口启动前端：

```bash
cd frontend
npm run dev -- --host 127.0.0.1 --port 3010
```

如果前端端口变了但后端仍是 8005，不需要改配置；如果后端端口变了，需要同步修改 `frontend/vite.config.ts` 的代理目标，或设置合适的 API 基址后再启动前端。

查看后端日志：

```bash
tail -f logs/aitext.log
```

清理本地开发数据前先确认不需要保留小说内容。相关脚本在 `scripts/utils/wipe_local_data.py`，不要直接删除 Colima 数据卷；PlotPilot 默认数据不在 Colima 中。
