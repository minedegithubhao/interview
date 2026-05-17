$ErrorActionPreference = 'Stop'
$OutputEncoding = [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$jsonPath = Join-Path $root 'Ai大模型应用开发-结构化岗位数据.json'
$outPath = Join-Path $root 'Ai大模型应用开发-招聘分析报告.md'

$data = Get-Content -Raw -Encoding utf8 $jsonPath | ConvertFrom-Json

function MidSalary($item) {
    return ($item.salary_min + $item.salary_max) / 2
}

function Add-Line($list, [string]$text) {
    [void]$list.Add($text)
}

function Add-Table($list, $rows, $headers, $cols) {
    Add-Line $list ('| ' + ($headers -join ' | ') + ' |')
    Add-Line $list ('| ' + (($headers | ForEach-Object { '---' }) -join ' | ') + ' |')
    foreach ($row in $rows) {
        $vals = foreach ($c in $cols) { [string]$row.$c }
        Add-Line $list ('| ' + ($vals -join ' | ') + ' |')
    }
}

$totalCount = $data.Count
$salaryItems = @($data | Where-Object { $_.salary_min -and $_.salary_max })
$avgMid = [math]::Round((($salaryItems | ForEach-Object { MidSalary $_ } | Measure-Object -Average).Average), 0)
$midValues = @($salaryItems | ForEach-Object { [int](MidSalary $_) } | Sort-Object)
$medianMid = if ($midValues.Count % 2 -eq 1) { $midValues[[int]($midValues.Count / 2)] } else { [int](($midValues[$midValues.Count / 2 - 1] + $midValues[$midValues.Count / 2]) / 2) }
$threshold = $midValues[[math]::Floor($midValues.Count * 0.75)]

$domainStats = @(
    $data |
    Group-Object business_domain |
    Sort-Object Count -Descending |
    ForEach-Object {
        [pscustomobject]@{
            domain = $_.Name
            count = $_.Count
            ratio = ('{0:P0}' -f ($_.Count / $totalCount))
        }
    }
)

$topSkills = @(
    $data |
    ForEach-Object { $_.skills } |
    Where-Object { $_ } |
    Group-Object |
    Sort-Object Count -Descending |
    Select-Object -First 15 |
    ForEach-Object {
        [pscustomobject]@{
            skill = $_.Name
            count = $_.Count
            ratio = ('{0:P0}' -f ($_.Count / $totalCount))
        }
    }
)

$softSkills = @(
    $data |
    ForEach-Object { $_.soft_skills } |
    Where-Object { $_ } |
    Group-Object |
    Sort-Object Count -Descending |
    Select-Object -First 10 |
    ForEach-Object {
        [pscustomobject]@{
            skill = $_.Name
            count = $_.Count
            ratio = ('{0:P0}' -f ($_.Count / $totalCount))
        }
    }
)

$abilityRules = @(
    @{ name = 'Agent/工作流'; pattern = 'Agent|智能体|工作流|多智能体' }
    @{ name = '性能优化'; pattern = '优化|加速|高并发|延迟|throughput|latency' }
    @{ name = 'RAG/知识库'; pattern = 'RAG|知识库|检索增强生成|向量数据库|检索' }
    @{ name = '应用落地'; pattern = '落地|实施|业务场景' }
    @{ name = '后端/API集成'; pattern = 'API|接口|后端|FastAPI|Flask|Django|Spring' }
    @{ name = '部署运维'; pattern = '部署|运维|监控|日志' }
    @{ name = 'Prompt工程'; pattern = 'Prompt|提示词|提⽰词' }
    @{ name = '模型训练/微调'; pattern = '微调|SFT|LoRA|QLoRA|训练' }
    @{ name = '评测/Eval'; pattern = '评测|评估|评价体系|Evals' }
    @{ name = '领域知识'; pattern = '金融|农业|交通|医疗|能源|工业|政务' }
)

$abilityStats = @(
    foreach ($rule in $abilityRules) {
        $count = @($data | Where-Object { $_.description -match $rule.pattern }).Count
        [pscustomobject]@{
            ability = $rule.name
            count = $count
            ratio = ('{0:P0}' -f ($count / $totalCount))
        }
    }
)

$premiumRows = @(
    foreach ($skill in ($data | ForEach-Object { $_.skills } | Where-Object { $_ } | Group-Object | Select-Object -ExpandProperty Name)) {
        $matched = @($data | Where-Object { $_.skills -contains $skill })
        if ($matched.Count -ge 5) {
            $avg = (($matched | ForEach-Object { MidSalary $_ } | Measure-Object -Average).Average)
            [pscustomobject]@{
                skill = $skill
                count = $matched.Count
                avg_mid = [math]::Round($avg, 0)
                premium = [math]::Round($avg - $avgMid, 0)
            }
        }
    }
)
$topPremium = @($premiumRows | Sort-Object premium -Descending | Select-Object -First 15)

$highSalarySkills = @(
    $salaryItems |
    Where-Object { (MidSalary $_) -ge $threshold } |
    ForEach-Object { $_.skills } |
    Where-Object { $_ } |
    Group-Object |
    Sort-Object Count -Descending |
    Select-Object -First 15 |
    ForEach-Object {
        [pscustomobject]@{
            skill = $_.Name
            count = $_.Count
        }
    }
)

$experienceStats = @(
    $data |
    Group-Object experience |
    Sort-Object Count -Descending |
    ForEach-Object {
        [pscustomobject]@{
            experience = if ($_.Name) { $_.Name } else { '缺失' }
            count = $_.Count
            ratio = ('{0:P0}' -f ($_.Count / $totalCount))
        }
    }
)

$educationStats = @(
    $data |
    Group-Object education |
    Sort-Object Count -Descending |
    ForEach-Object {
        [pscustomobject]@{
            education = if ($_.Name) { $_.Name } else { '缺失' }
            count = $_.Count
            ratio = ('{0:P0}' -f ($_.Count / $totalCount))
        }
    }
)

$lines = New-Object System.Collections.Generic.List[string]

Add-Line $lines '# AI大模型应用开发招聘分析报告'
Add-Line $lines ''
Add-Line $lines '## 1. 报告说明'
Add-Line $lines ''
Add-Line $lines '本报告基于本地文件 [Ai大模型应用开发-结构化岗位数据.json](</C:/Users/82473/Desktop/AI就业分析/Ai大模型应用开发-结构化岗位数据.json>) 的 81 条真实岗位样本统计，并结合公开资料对市场趋势进行交叉校验。'
Add-Line $lines ''
Add-Line $lines '本地样本回答的是“这批企业在招什么”，外部资料回答的是“更广泛市场是否也这样演化”。二者结合，结论更稳。'
Add-Line $lines ''
Add-Line $lines '### 样本概览'
Add-Line $lines ''
Add-Line $lines ('- 岗位总数：' + $totalCount)
Add-Line $lines ('- 有效薪资样本：' + $salaryItems.Count)
Add-Line $lines ('- 平均月薪中位值：' + $avgMid + ' 元')
Add-Line $lines ('- 中位月薪中位值：' + $medianMid + ' 元')
Add-Line $lines ('- 高薪样本阈值：' + $threshold + ' 元（按 75 分位）')
Add-Line $lines ''
Add-Line $lines '## 2. 企业招聘什么能力最重要'
Add-Line $lines ''
Add-Line $lines '如果只看岗位描述里被反复要求的能力，企业最看重的不是单点模型知识，而是从“模型能力”到“工程系统”再到“业务落地”的完整闭环。'
Add-Line $lines ''
Add-Table $lines $abilityStats @('能力方向', '出现次数', '覆盖比例') @('ability', 'count', 'ratio')
Add-Line $lines ''
Add-Line $lines '### 解释'
Add-Line $lines ''
Add-Line $lines '- `Agent/工作流`、`RAG/知识库` 和 `应用落地` 同时高频，说明企业已经不满足于做聊天 Demo，而是要做能执行任务的业务系统。'
Add-Line $lines '- `性能优化` 和 `部署运维` 高频，说明企业并不只关心“做出来”，更关心成本、延迟、稳定性和可运维性。'
Add-Line $lines '- `后端/API集成` 出现很多，表明企业想要的是能把 AI 接进现有系统的人，而不是孤立做原型的人。'
Add-Line $lines '- `评测/Eval` 已经出现 30 次，说明这类岗位开始进入“效果可量化”的阶段。'
Add-Line $lines ''
Add-Line $lines '### 结论'
Add-Line $lines ''
Add-Line $lines '企业最看重的能力链路可以概括为：'
Add-Line $lines ''
Add-Line $lines '`Python/后端能力 -> RAG/知识库 -> Agent/工作流 -> 部署与性能优化 -> 业务落地与评测`'
Add-Line $lines ''
Add-Line $lines '## 3. 什么能力最值钱'
Add-Line $lines ''
Add-Line $lines ('这里的“值钱”采用的是溢价口径：提到某技能的岗位，其平均薪资中位值相对全样本平均值 ' + $avgMid + ' 元高出多少。')
Add-Line $lines ''
Add-Table $lines $topPremium @('技能', '样本数', '平均月薪中位值', '相对溢价') @('skill', 'count', 'avg_mid', 'premium')
Add-Line $lines ''
Add-Line $lines '### 解释'
Add-Line $lines ''
Add-Line $lines '- 高溢价技能主要集中在 `vLLM`、`Transformer`、`C++`、`多模态`、`LoRA`、`PyTorch/TensorFlow` 这类偏底层和系统层能力。'
Add-Line $lines '- 这说明高薪岗位往往不是简单调用 API，而是更接近 `推理部署`、`训练微调`、`多模态系统`、`底层优化`。'
Add-Line $lines '- `RAG`、`Agent` 虽然出现频率极高，但更像“入场券”；真正拉高薪资上限的，是能把系统做到更深层、更高性能、更复杂场景。'
Add-Line $lines ''
Add-Line $lines '## 4. 技术栈提及最多的前 15 个'
Add-Line $lines ''
Add-Table $lines $topSkills @('技术栈', '出现次数', '覆盖比例') @('skill', 'count', 'ratio')
Add-Line $lines ''
Add-Line $lines '### 解读'
Add-Line $lines ''
Add-Line $lines '- `Python` 仍然是大模型应用岗位的绝对主语言。'
Add-Line $lines '- `Agent`、`RAG`、`LangChain` 构成了这批岗位最主流的应用开发三件套。'
Add-Line $lines '- `Fine-tuning`、`Prompt Engineering`、`Llama`、`向量数据库` 说明岗位要求已经从“只会调模型”升级为“会做完整应用管线”。'
Add-Line $lines '- `Java` 的高频出现，说明很多企业是在现有企业级系统中接入 AI，而不是完全重建技术栈。'
Add-Line $lines ''
Add-Line $lines '## 5. 高薪技能特征'
Add-Line $lines ''
Add-Line $lines ('把月薪中位值大于等于 ' + $threshold + ' 元的岗位视为高薪样本，高薪样本里最常出现的技能如下：')
Add-Line $lines ''
Add-Table $lines $highSalarySkills @('高薪技能', '出现次数') @('skill', 'count')
Add-Line $lines ''
Add-Line $lines '### 解读'
Add-Line $lines ''
Add-Line $lines '- 高薪岗位中，`Python`、`Agent`、`RAG` 仍然是基础盘。'
Add-Line $lines '- 真正和高薪更绑定的是：`Transformer`、`多模态`、`PyTorch`、`LoRA`、`vLLM`、`C++`。'
Add-Line $lines '- 这说明高薪岗位普遍要求候选人既能做应用层落地，也能深入模型与系统优化层。'
Add-Line $lines ''
Add-Line $lines '## 6. 软技能与岗位门槛'
Add-Line $lines ''
Add-Line $lines '### 软技能 Top 10'
Add-Line $lines ''
Add-Table $lines $softSkills @('软技能', '出现次数', '覆盖比例') @('skill', 'count', 'ratio')
Add-Line $lines ''
Add-Line $lines '### 经验要求'
Add-Line $lines ''
Add-Table $lines $experienceStats @('经验要求', '数量', '比例') @('experience', 'count', 'ratio')
Add-Line $lines ''
Add-Line $lines '### 学历要求'
Add-Line $lines ''
Add-Table $lines $educationStats @('学历要求', '数量', '比例') @('education', 'count', 'ratio')
Add-Line $lines ''
Add-Line $lines '### 结论'
Add-Line $lines ''
Add-Line $lines '- 这批岗位以 `1-3年` 和 `3-5年` 为主，说明企业明显在招“能独立做事的中初级骨干”。'
Add-Line $lines '- 学历门槛极集中在 `本科`。'
Add-Line $lines '- 软技能里最重要的是 `沟通能力`、`团队合作能力`、`问题解决能力`，说明企业希望候选人能跨团队把 AI 项目推进下去。'
Add-Line $lines ''
Add-Line $lines '## 7. 行业分布'
Add-Line $lines ''
Add-Table $lines $domainStats @('业务领域', '岗位数量', '比例') @('domain', 'count', 'ratio')
Add-Line $lines ''
Add-Line $lines '解读：当前样本以通用企业应用、能源/工业、搜索/推荐、金融为主，说明 AI 应用招聘需求已经明显进入产业场景。'
Add-Line $lines ''
Add-Line $lines '## 8. 外部趋势校验'
Add-Line $lines ''
Add-Line $lines '以下公开资料与本地样本趋势基本一致：'
Add-Line $lines ''
Add-Line $lines '- [Stanford AI Index 2025](https://hai.stanford.edu/ai-index/2025-ai-index-report)：2024 年有 78% 的组织报告已在使用 AI，说明企业关注点正在从“会不会用”转向“怎么稳定落地”。'
Add-Line $lines '- [GitHub Octoverse 2024](https://github.blog/news-insights/octoverse/octoverse-2024/)：Python 已超过 JavaScript 成为 GitHub 最常用语言，这与本地样本中 Python 的压倒性优势一致。'
Add-Line $lines '- [LangChain State of AI Agents](https://www.langchain.com/stateofaiagents) 与 [State of Agent Engineering](https://www.langchain.com/state-of-agent-engineering)：行业正在从 retrieval workflow 向 agentic workflow 演进。'
Add-Line $lines '- [OpenAI Evaluation Best Practices](https://developers.openai.com/api/docs/guides/evaluation-best-practices)：生产级 AI 系统需要系统化评测，而不是只做主观体验判断。'
Add-Line $lines '- [Anthropic Prompt Engineering Overview](https://docs.anthropic.com/en/docs/build-with-claude/prompt-engineering/overview)：Prompt 工程仍然重要，但必须和上下文管理、工具调用、评测一起使用。'
Add-Line $lines ''
Add-Line $lines '## 9. 面试准备怎么做'
Add-Line $lines ''
Add-Line $lines '### 总策略'
Add-Line $lines ''
Add-Line $lines '不要按零碎知识点准备，要按企业买单的完整链路准备：'
Add-Line $lines ''
Add-Line $lines '`业务问题 -> 数据与知识库 -> RAG -> Agent -> 系统集成 -> 部署优化 -> 评测闭环`'
Add-Line $lines ''
Add-Line $lines '### 必备准备模块'
Add-Line $lines ''
Add-Line $lines '1. 做一个可演示的完整项目'
Add-Line $lines '- 至少包含：API 服务、知识库/RAG、Agent 或工具调用、日志/监控、简单前端或控制台。'
Add-Line $lines '- 能够讲清为什么这样设计，而不是只展示效果。'
Add-Line $lines ''
Add-Line $lines '2. 把 RAG 讲到工程层'
Add-Line $lines '- 文档解析、chunk、embedding、检索、重排、混合检索、幻觉控制、评测。'
Add-Line $lines ''
Add-Line $lines '3. 把 Agent 讲到可控性'
Add-Line $lines '- 工具调用、任务拆解、失败重试、降级、Memory 管理、trace 和观测。'
Add-Line $lines ''
Add-Line $lines '4. 把系统能力补上'
Add-Line $lines '- FastAPI / Flask / Django / Spring Boot 至少熟一个。'
Add-Line $lines '- 会 Docker 部署，知道基本 Linux 运维，能解释并发、缓存、限流和接口设计。'
Add-Line $lines ''
Add-Line $lines '5. 如果目标是高薪岗，要补一个溢价方向'
Add-Line $lines '- 方向 A：vLLM / LoRA / 推理优化 / 微调'
Add-Line $lines '- 方向 B：多模态 / PyTorch / C++ / 视觉与端侧'
Add-Line $lines '- 方向 C：行业项目落地 + 企业级系统集成'
Add-Line $lines ''
Add-Line $lines '### 典型面试题'
Add-Line $lines ''
Add-Line $lines '- 为什么这个场景适合 RAG，而不是长上下文硬塞？'
Add-Line $lines '- RAG 的 chunk、embedding、rerank 如何设计？'
Add-Line $lines '- Agent 为什么需要工具调用？什么时候不该上 Agent？'
Add-Line $lines '- 如何评估一个 RAG/Agent 系统是否真的变好？'
Add-Line $lines '- 如何控制模型调用成本与响应延迟？'
Add-Line $lines '- 如果线上出现幻觉、超时、召回不准，如何定位问题？'
Add-Line $lines '- 为什么选 Python/Java？如何与现有业务系统集成？'
Add-Line $lines ''
Add-Line $lines '## 10. 30 天准备路线'
Add-Line $lines ''
Add-Line $lines '### 第 1 周'
Add-Line $lines '- 选一个真实业务场景，用 Python + FastAPI 做一个最小可用服务。'
Add-Line $lines '- 接入基础模型、向量库和简单 RAG。'
Add-Line $lines ''
Add-Line $lines '### 第 2 周'
Add-Line $lines '- 加入 Agent 或工具调用。'
Add-Line $lines '- 做日志、缓存、重试、降级。'
Add-Line $lines '- 准备一小套评测集。'
Add-Line $lines ''
Add-Line $lines '### 第 3 周'
Add-Line $lines '- 优化 chunk、召回、重排。'
Add-Line $lines '- 测试延迟、吞吐、成本。'
Add-Line $lines '- 输出系统设计文档。'
Add-Line $lines ''
Add-Line $lines '### 第 4 周'
Add-Line $lines '- 二选一：补 vLLM/LoRA，或补 多模态/PyTorch。'
Add-Line $lines '- 把项目写进简历，形成 STAR 式表达。'
Add-Line $lines '- 模拟面试，重点练设计取舍。'
Add-Line $lines ''
Add-Line $lines '## 11. 最终建议'
Add-Line $lines ''
Add-Line $lines '如果目标是尽快拿到面试机会，最值得优先投入的路线是：'
Add-Line $lines ''
Add-Line $lines '`Python + RAG + Agent + FastAPI + Docker + Eval`'
Add-Line $lines ''
Add-Line $lines '如果目标是冲更高薪资，最应该追加的能力是：'
Add-Line $lines ''
Add-Line $lines '`推理优化 / 微调 / 多模态 / 底层工程能力`'
Add-Line $lines ''
Add-Line $lines '对于这批岗位来说，企业真正买单的不是“懂大模型概念”，而是“能把大模型做成稳定、可评估、可优化、能落地的生产系统”。'

[System.IO.File]::WriteAllText($outPath, ($lines -join "`n"), [System.Text.UTF8Encoding]::new($false))
Write-Output ('OUTPUT=' + $outPath)

