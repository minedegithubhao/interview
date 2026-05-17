$ErrorActionPreference = 'Stop'
$OutputEncoding = [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$inputDir = Join-Path $root 'Ai大模型应用开发'
$outputFile = Join-Path $root 'Ai大模型应用开发-结构化岗位数据.json'

$salaryMap = @{
    '' = '0'
    '' = '1'
    '' = '2'
    '' = '3'
    '' = '4'
    '' = '5'
    '' = '6'
    '' = '7'
    '' = '8'
    '' = '9'
}

$skillKeywords = [ordered]@{
    'Python' = @('python', 'fastapi', 'flask', 'django')
    'Java' = @('java', 'spring boot', 'springai', 'spring ai', 'spring')
    'SpringCloud' = @('springcloud')
    'Spring Boot' = @('spring boot')
    'Spring' = @(' spring', 'spring ')
    'Go' = @(' golang', 'go语言', 'go ')
    'C++' = @('c++')
    'C' = @(' c语言', ' c ')
    'Rust' = @('rust')
    'JavaScript' = @('javascript', 'js')
    'TypeScript' = @('typescript', 'ts')
    'Vue' = @('vue')
    'React' = @('react')
    'LangChain' = @('langchain')
    'LlamaIndex' = @('llamaindex', 'llamaindex', 'llamalndex')
    'LangGraph' = @('langgraph')
    'Semantic Kernel' = @('semantic kernel')
    'Dify' = @('dify')
    'RagFlow' = @('ragflow')
    'RAG' = @('rag', '检索增强生成')
    'Agent' = @('agent', '智能体', 'multi-agent', '多智能体')
    'Prompt Engineering' = @('prompt engineering', 'prompt工程', '提示词工程', '提⽰词工程')
    'Function Calling' = @('function calling', 'tool use', '工具调用')
    'MCP' = @('mcp', 'model context protocol')
    'LoRA' = @('lora', 'qlora')
    'Fine-tuning' = @('fine-tuning', '微调', 'sft')
    'PyTorch' = @('pytorch')
    'TensorFlow' = @('tensorflow')
    'Transformer' = @('transformer')
    'DeepSpeed' = @('deepspeed')
    'vLLM' = @('vllm')
    'Ollama' = @('ollama')
    'Docker' = @('docker')
    'Kubernetes' = @('kubernetes', 'k8s')
    'Linux' = @('linux')
    'Git' = @('git')
    '分布式系统' = @('分布式')
    'Redis' = @('redis')
    'MySQL' = @('mysql')
    'PostgreSQL' = @('postgresql', 'postgres')
    'MongoDB' = @('mongodb', 'mongo')
    'Kafka' = @('kafka')
    'Elasticsearch' = @('elasticsearch')
    'Milvus' = @('milvus')
    'Chroma' = @('chroma')
    'Pinecone' = @('pinecone')
    'Qdrant' = @('qdrant')
    'Neo4j' = @('neo4j')
    'SQL' = @(' sql', 'sql ')
    'OpenAI API' = @('openai api', 'openai')
    'Claude' = @('claude')
    'Qwen' = @('qwen', '通义千问')
    'Llama' = @('llama')
    'ChatGLM' = @('chatglm')
    '文心一言' = @('文心一言')
    '向量数据库' = @('向量数据库')
    '知识图谱' = @('知识图谱', 'kg')
    'OCR' = @('ocr')
    'ASR' = @('asr')
    'NL2SQL' = @('nl2sql')
    '多模态' = @('多模态', 'multimodal')
}

$softSkillKeywords = [ordered]@{
    '沟通能力' = @('沟通能力', '沟通协作', '表达能力', '跨团队协作', '协同')
    '团队合作能力' = @('团队合作', '团队协作', '合作精神')
    '问题解决能力' = @('问题解决能力', '解决问题', '问题排查', '问题定位')
    '业务理解能力' = @('业务理解', '业务sense', '理解业务需求')
    '学习能力' = @('学习能力', '持续学习', '快速学习')
    '责任心' = @('责任心', '主人翁精神')
    '自驱力' = @('自驱力', '主动性', '主动推动')
    '创新能力' = @('创新能力', '技术创新', '创新意识')
    '文档能力' = @('文档编写', '技术文档', '文档撰写')
    '抗压能力' = @('抗压能力')
}

$domainRules = [ordered]@{
    '金融' = @('金融', '银行', '资管', '支付', '证券', '基金', '同业')
    '电商/零售' = @('电商', '零售', '本地生活', '供应链', '品牌运营', '商家')
    '医疗' = @('医疗', '健康', '医院', '医药')
    '农业' = @('农业', '种植', '作物', '病虫害', '农事', '植保')
    '交通' = @('交通', '路况', '高速', '智慧园区', '拥堵')
    '能源/工业' = @('油气', '炼化', '石油', '化工', '管道', '工业', '制造', '新能源', '电力')
    '政务' = @('政务', '政府', '城市大脑', '数字政府')
    '企业服务' = @('企业知识管理', '知识助手', '智能客服', '研发提效', '企业服务', 'oa系统')
    '搜索/推荐' = @('搜索', '推荐', '召回', '排序')
    '汽车' = @('汽车', '座舱')
}

function Remove-Noise([string]$text) {
    if ([string]::IsNullOrWhiteSpace($text)) { return '' }
    $text = $text -replace '!\[[^\]]*\]\([^\)]*\)', ''
    $text = $text -replace '\[([^\]]+)\]\([^\)]*\)', '$1'
    $text = $text -replace '来自BOSS直聘', ''
    $text = $text -replace 'BOSS直聘', ''
    $text = $text -replace 'kanzhun', ''
    $text = $text -replace 'boss', ''
    $text = $text -replace '直聘', ''
    $text = $text -replace '[-]', ''
    $text = $text -replace '\*\*+', ''
    $text = $text -replace '\s+', ' '
    return $text.Trim()
}

function Decode-SalaryText([string]$text) {
    if ([string]::IsNullOrWhiteSpace($text)) { return '' }
    foreach ($key in $salaryMap.Keys) {
        $text = $text.Replace($key, $salaryMap[$key])
    }
    return $text
}

function Get-TextLines([string]$raw) {
    return $raw -split "`r?`n"
}

function Get-JobId([string]$raw) {
    $matches = [regex]::Matches($raw, '\[查看更多信息\]\(/job_detail/([^\.]+)\.html')
    if ($matches.Count -gt 0) {
        return $matches[$matches.Count - 1].Groups[1].Value
    }
    return $null
}

function Find-ListingIndex([string[]]$lines, [string]$jobId) {
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match [regex]::Escape("/job_detail/$jobId.html")) {
            return $i
        }
    }
    return -1
}

function Find-NearestCompany([string[]]$lines, [int]$index) {
    for ($offset = 1; $offset -le 15; $offset++) {
        foreach ($candidate in @(( $index - $offset ), ( $index + $offset ))) {
            if ($candidate -ge 0 -and $candidate -lt $lines.Count) {
                $line = $lines[$candidate]
                $match = [regex]::Match($line, '^\s*(?<company>.+?)\]\(/gongsi/[^)]*\)\s*(?<city>[^\s·]+)(?:·.*)?\s*$')
                if ($match.Success) {
                    return [pscustomobject]@{
                        Company = (Remove-Noise $match.Groups['company'].Value)
                        City = (Remove-Noise $match.Groups['city'].Value)
                    }
                }
            }
        }
    }
    return $null
}

function Parse-HeaderMeta([string[]]$lines) {
    $headerIndex = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i].Trim() -eq '提交') {
            $headerIndex = $i
            break
        }
    }
    $descIndex = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i].Trim() -eq '### 职位描述') {
            $descIndex = $i
            break
        }
    }
    if ($headerIndex -lt 0 -and $descIndex -lt 0) { return $null }

    $title = $null
    $salaryText = $null
    if ($headerIndex -ge 0) {
        for ($i = $headerIndex + 1; $i -lt [Math]::Min($headerIndex + 5, $lines.Count); $i++) {
            $line = Decode-SalaryText $lines[$i]
            $line = Remove-Noise $line
            if ($line -match '^(?<title>.+?)(?<salary>\d{2}-\d{2}K(?:·\d{2}薪)?)$') {
                $title = $matches['title'].Trim()
                $salaryText = $matches['salary'].Trim()
                break
            }
            if (-not [string]::IsNullOrWhiteSpace($line) -and -not $title) {
                $title = $line.Trim()
            }
        }
    }

    if ($descIndex -ge 0) {
        for ($i = [Math]::Max(0, $descIndex - 12); $i -lt $descIndex; $i++) {
            $line = Decode-SalaryText $lines[$i]
            $line = Remove-Noise $line
            if (-not $salaryText -and $line -match '^(?<title>.+?)(?<salary>\d{2}-\d{2}K(?:·\d{2}薪)?)$') {
                $title = $matches['title'].Trim()
                $salaryText = $matches['salary'].Trim()
            }
        }
    }

    $city = $null
    $experience = $null
    $education = $null
    $metaStart = if ($headerIndex -ge 0) { $headerIndex + 1 } elseif ($descIndex -ge 0) { [Math]::Max(0, $descIndex - 10) } else { 0 }
    $metaEnd = if ($descIndex -ge 0) { $descIndex } else { [Math]::Min($metaStart + 12, $lines.Count) }
    $invalidCityValues = @('提交', '本科', '大专', '硕士', '博士', '不限', '收藏立即沟通', '举报', '微信扫码分享')
    for ($i = $metaStart; $i -lt $metaEnd; $i++) {
        $line = Remove-Noise $lines[$i]
        $line = ($line -replace '^-+\s*', '').Trim()
        if (-not $city -and $line -match '^\[(.+)\]$') { $city = $matches[1].Trim() }
        elseif (-not $city -and $line -match '^[\p{IsCJKUnifiedIdeographs}]{2,}$' -and $invalidCityValues -notcontains $line) { $city = $line.Trim() }
        elseif (-not $experience -and $line -match '经验不限|在校/应届|应届|1-3年|3-5年|5-10年|10年以上') { $experience = $matches[0] }
        elseif (-not $education -and $line -match '不限|大专|本科|硕士|博士') { $education = $matches[0] }
    }

    return [pscustomobject]@{
        Title = $title
        SalaryText = $salaryText
        City = $city
        Experience = $experience
        Education = $education
    }
}

function Parse-SalaryRange([string]$salaryText) {
    $salaryText = Decode-SalaryText $salaryText
    if ($salaryText -match '(?<min>\d{2})-(?<max>\d{2})K') {
        return [pscustomobject]@{
            Min = [int]$matches['min'] * 1000
            Max = [int]$matches['max'] * 1000
        }
    }
    if ($salaryText -match '(?<min>\d{1,2})k-(?<max>\d{1,2})k') {
        return [pscustomobject]@{
            Min = [int]$matches['min'] * 1000
            Max = [int]$matches['max'] * 1000
        }
    }
    return [pscustomobject]@{
        Min = $null
        Max = $null
    }
}

function Extract-DescriptionBlock([string]$raw) {
    $match = [regex]::Match($raw, '(?ms)### 职位描述\s*(?<desc>.*?)(?=\r?\n## |\r?\n工作地址\r?\n|\r?\n求职工具\r?\n|\z)')
    if (-not $match.Success) { return $null }
    $lines = Get-TextLines $match.Groups['desc'].Value
    $kept = New-Object System.Collections.Generic.List[string]
    foreach ($line in $lines) {
        if ($line -match '^\s*!\[') { continue }
        if ($line.Trim() -eq '') { continue }
        if ($line.Trim() -eq '点击查看地图') { break }
        if ($line.Trim() -eq '工作地址') { break }
        if ($line.Trim() -eq '求职工具') { break }
        $kept.Add($line)
    }
    return ($kept -join "`n").Trim()
}

function Extract-DetailCompanyAndLocation([string[]]$lines) {
    $company = $null
    $workLocation = $null

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = Remove-Noise $lines[$i]

        if (-not $company -and $line -match '^##\s+.+活跃$') {
            for ($j = $i + 1; $j -lt [Math]::Min($i + 6, $lines.Count); $j++) {
                $candidate = Remove-Noise $lines[$j]
                if ([string]::IsNullOrWhiteSpace($candidate)) { continue }
                if ($candidate -match '^(?<company>.+?)\s*·\s*.+$') {
                    $company = $matches['company'].Trim()
                    break
                }
            }
        }

        if ($line -eq '工作地址') {
            for ($j = $i + 1; $j -lt [Math]::Min($i + 5, $lines.Count); $j++) {
                $candidate = Remove-Noise $lines[$j]
                if ([string]::IsNullOrWhiteSpace($candidate)) { continue }
                if ($candidate -eq '点击查看地图') { continue }
                if ($candidate -match '^!\[') { continue }
                $workLocation = $candidate
                break
            }
        }

        if ($company -and $workLocation) { break }
    }

    return [pscustomobject]@{
        Company = $company
        WorkLocation = $workLocation
    }
}

function Infer-CityFromLocation([string]$location) {
    if ([string]::IsNullOrWhiteSpace($location)) { return $null }
    $location = Remove-Noise $location

    $directCityMatch = [regex]::Match($location, '^(?<city>北京|上海|天津|重庆)')
    if ($directCityMatch.Success) {
        return $directCityMatch.Groups['city'].Value
    }

    $match = [regex]::Match($location, '^(?<city>[^市区县旗镇乡村]{2,4})市')
    if ($match.Success) {
        return $match.Groups['city'].Value
    }

    $match = [regex]::Match($location, '^(?<city>[^市区县旗镇乡村]{2,4})(?=区|县|旗)')
    if ($match.Success) {
        return $match.Groups['city'].Value
    }

    $match = [regex]::Match($location, '^(?<city>[^市区县旗镇乡村]{2,4})')
    if ($match.Success) {
        return $match.Groups['city'].Value
    }

    return $null
}

function Extract-TaggedSkills([string]$descBlock) {
    $skills = New-Object System.Collections.Generic.List[string]
    $lines = Get-TextLines $descBlock
    foreach ($line in $lines) {
        $trimmed = $line.Trim()
        if ($trimmed -match '^-   ') {
            $value = Remove-Noise ($trimmed -replace '^-+\s*', '')
            if (
                $value -and
                $value.Length -le 40 -and
                $value -notmatch '居家|办公|经验|福利|学历|待遇|招聘|方向|岗位|优先|广告'
            ) {
                $skills.Add($value)
            }
            continue
        }
        break
    }
    return $skills
}

function Collect-KeywordMatches([string]$text, [hashtable]$dictionary) {
    $normalized = (Remove-Noise $text).ToLowerInvariant()
    $results = New-Object System.Collections.Generic.List[string]
    foreach ($key in $dictionary.Keys) {
        foreach ($needle in $dictionary[$key]) {
            if ($normalized.Contains($needle.ToLowerInvariant())) {
                $results.Add($key)
                break
            }
        }
    }
    return ($results | Select-Object -Unique)
}

function Infer-BusinessDomain([string]$text) {
    $normalized = (Remove-Noise $text).ToLowerInvariant()
    foreach ($key in $domainRules.Keys) {
        foreach ($needle in $domainRules[$key]) {
            if ($normalized.Contains($needle.ToLowerInvariant())) {
                return $key
            }
        }
    }
    return '通用企业应用'
}

$records = New-Object System.Collections.Generic.List[object]

Get-ChildItem -Path $inputDir -Filter '*.md' | Sort-Object Name | ForEach-Object {
    $raw = Get-Content -Path $_.FullName -Raw -Encoding utf8
    if ($raw -notmatch '### 职位描述') { return }

    $lines = Get-TextLines $raw
    $jobId = Get-JobId $raw
    $listingIndex = if ($jobId) { Find-ListingIndex $lines $jobId } else { -1 }
    $listingLine = if ($listingIndex -ge 0) { Decode-SalaryText $lines[$listingIndex] } else { '' }

    $header = Parse-HeaderMeta $lines
    $companyBlock = if ($listingIndex -ge 0) { Find-NearestCompany $lines $listingIndex } else { $null }
    $detailMeta = Extract-DetailCompanyAndLocation $lines
    $descriptionBlock = Extract-DescriptionBlock $raw
    if (-not $descriptionBlock) { return }

    $cleanDescription = Remove-Noise $descriptionBlock
    $salaryText = $null
    if ($header -and $header.SalaryText) {
        $salaryText = $header.SalaryText
    } elseif ($listingLine -match '(?<salary>\d{2}-\d{2}K(?:·\d{2}薪)?)') {
        $salaryText = $matches['salary']
    }
    $salaryRange = Parse-SalaryRange $salaryText

    $title = $null
    if ($listingLine -match '\[(?<title>[^\]]+)\]\(/job_detail/') {
        $title = Remove-Noise $matches['title']
    }
    if (-not $title -and $header -and $header.Title) {
        $title = Remove-Noise ($header.Title -replace '\d{2}-\d{2}K(?:·\d{2}薪)?$', '')
    }
    if (-not $title) { $title = $_.BaseName }

    $city = $null
    if ($detailMeta -and $detailMeta.WorkLocation) {
        $city = Infer-CityFromLocation $detailMeta.WorkLocation
    }
    if ($header -and $header.City) {
        $headerCity = Remove-Noise $header.City
        if ($city -and $city.StartsWith($headerCity)) {
            $city = $headerCity
        }
    }
    if ($companyBlock -and $companyBlock.City) {
        $listCity = Remove-Noise $companyBlock.City
        if ($city -and $city.StartsWith($listCity)) {
            $city = $listCity
        }
    }
    if (-not $city -and $companyBlock -and $companyBlock.City) {
        $city = $companyBlock.City
    }
    if (-not $city -and $header -and $header.City) {
        $city = Remove-Noise $header.City
    }

    $experience = if ($header) { $header.Experience } else { $null }
    $education = if ($header) { $header.Education } else { $null }

    $taggedSkills = Extract-TaggedSkills $descriptionBlock
    $skills = @((Collect-KeywordMatches (($taggedSkills -join ' ') + ' ' + $descriptionBlock) $skillKeywords)) | Select-Object -Unique
    $softSkills = Collect-KeywordMatches $descriptionBlock $softSkillKeywords
    $businessDomain = Infer-BusinessDomain ($title + ' ' + $cleanDescription)

    $records.Add([pscustomobject]@{
        title = $title
        company = if ($detailMeta -and $detailMeta.Company) { $detailMeta.Company } elseif ($companyBlock) { $companyBlock.Company } else { $null }
        city = $city
        work_location = if ($detailMeta) { $detailMeta.WorkLocation } else { $null }
        salary_min = $salaryRange.Min
        salary_max = $salaryRange.Max
        experience = $experience
        education = $education
        description = $cleanDescription
        skills = @($skills)
        soft_skills = @($softSkills)
        business_domain = $businessDomain
        source_file = $_.Name
        job_id = $jobId
    })
}

$json = $records | ConvertTo-Json -Depth 6
[System.IO.File]::WriteAllText($outputFile, $json, [System.Text.UTF8Encoding]::new($false))
Write-Output "OUTPUT=$outputFile"
Write-Output "COUNT=$($records.Count)"











