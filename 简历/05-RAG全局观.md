# RAG全局观

## RAG是什么？有什么用？

RAG是`Retrieval-Augmented Generation`，即检索增强生成，它能解决：

- 大模型不知道企业私有数据 & 知识落后问题（导致大模型幻觉）
- 解决大模型有上下文窗口限制（即使大模型支持超长上下文）

## RAG的三种架构



## 知识库搭建

### 如何统一多源文档格式？

- 统一接口设计 ：所有文档解析器都继承自 BaseExtractor 基类，提供统一的 extract() 方法接口
- Word 文档解析 ：在 word_extractor.py 中实现提取文本内容、提取图片并保存到指定目录、处理超链接
- PDF 文档解析 ：在 pdf_extractor.py 中实现按页提取文本内容、保留页面元数据信息
- 统一处理流程 ：通过 extract_processor.py 根据文件扩展名自动选择对应的解析器，所有解析器返回统一格式的 Document 对象
- 扩展性设计 ：通过 unstructured 库作为备选解析方，快速提取内容喂给 LLM

参考dify源码：`https://github.com/langgenius/dify/blob/main/api/core/rag/extractor/word_extractor.py`

#### Word文件的解析逻辑

1. 文字一般采用 Python-docx 库直接解析

2. 图片保存到指定的 image_folder 目录中，并被映射到一个 image_map 字典中，键是图片的引用 ID，值是图片的 HTML 格式标签
   
3. 在处理文档内容时，当遇到图片引用时，会从 image_map 中获取对应的 HTML 标签并插入到内容中，直接处理图片的逻辑相同
   
4. 最终生成的文档内容会包含文本和图片的 HTML 表示

参考dify源码：https://github.com/langgenius/dify/blob/main/api/core/rag/extractor/word_extractor.py

### 跨页表格怎么自动对齐合并？

**核心挑战**

- 表头重复 ：每一页可能都包含相同的表头。
- 表头重复 ：每一页可能都包含相同的表头。
- 表头重复 ：每一页可能都包含相同的表头。中间存在叶眉页脚
- OCR 识别误差 ：尤其在扫描件中，文字识别错误影响结构恢复。

<img src="./05-RAG全局观.assets/image-20260607064907194.png" alt="image-20260607064907194" style="zoom:50%;" />

**解决思路**

- 步骤1：布局预测（Layout Predict）
- 步骤2：文档格式检测（MFD Predict）
- 步骤3：文档格式识别（MFR Predict）
- 步骤4：OCR处理：自动检测到使用CPU时切换为ch_lite语言模型
- 步骤5：表格预测（Table Predict）

> 可和dify配合使用

**解决办法**

MinerU：`https://opendatalab.github.io/MinerU/`

### 领域内术语总混淆，该如何解决？

**问题**：

同一个词在不同场景下有不同含义，导致系统检索错、理解错、回答错。

例如：

- 计算机硬件领域，CPU 表示：中央处理器
- 财务分析里，CPU 表示：每单位成本，Cost Per Unit

*如果没有术语词库，RAG 可能把“成本 CPU”错理解成电脑处理器，答案就跑偏了。*

**核心思想**

**术语词库**提高 RAG 在专业领域里的检索一致性，从而提高召回率和准确率，间接降低幻觉。

**使用方式**

```json
term_glossary = {
    "神经网络": {
        "synonyms": ["人工神经网络", "NN"],
        "definition": "模仿生物神经网络结构和功能的计算模型",
        "context_tags": ["人工智能", "深度学习"],
        "domain": "计算机科学",
        "stop_words": ["神经系统"]
    },
}
```

- 构建知识库

  ```python
  CNN 在图像识别中表现很好。 # 原始文档
  
  标准术语：卷积神经网络  # 术语词库
  别名：CNN、ConvNet、卷基神经网络
  
  卷积神经网络（CNN）在图像识别中表现很好。 # 最终入库文档
  ```

  无论用户问 CNN 还是 卷积神经网络，都更容易匹配到。**括号里不需要写所有别名，只放最常见的别名**。

- 文档切块时：给 chunk 增加 metadata

  ```json
  {
    "terms": ["卷积神经网络", "图像识别"],
    "domain": "人工智能",
    "context_tags": ["深度学习", "计算机视觉"]
  }
  ```

  检索时按 domain、terms 过滤或加权，**复杂 query 要做软匹配、多路召回和重排序，硬过滤只能作为高置信度场景下的补充。**

- 用户提问时：先识别和改写查询

  ```python
  CNN 是什么？ # 问题
  
  CNN -> 卷积神经网络  # 术语词表映射
  
  CNN 是什么？ # 查询扩展
  卷积神经网络 是什么？
  ConvNet 是什么？
  ```

  检索时召回率更高

- 检索时：辅助过滤和重排序

  ```python
  CPU 成本怎么计算？ # 用户问题
  
  中央处理器：计算机硬件  # 术语词库
  每单位成本：财务/业务分析
  ```

  优先检索财务领域文档

- 生成答案时：约束模型用标准术语

  ```text
  请优先使用术语词库中的标准术语。
  如果用户使用了别名，先解释别名对应的标准术语。
  不要混用未定义术语。
  ```
