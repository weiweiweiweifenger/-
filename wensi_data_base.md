**users 表（用户）**

- id：BIGINT PRIMARY KEY AUTO_INCREMENT
- username：VARCHAR(50) NOT NULL
- password：VARCHAR(255) NOT NULL（加密存储）
- path:VARCHAR(500)（服务器上用户文件夹的绝对路径//每次创建完用户文件夹都要在用户文件夹里初始化两个文件夹“knowledge_base”和“project”）
- created_time：DATETIME



**admins 表（管理员）**

- id：BIGINT PRIMARY KEY AUTO_INCREMENT（管理员唯一标识）
- username：VARCHAR(50) NOT NULL UNIQUE（登录用户名）
- password：VARCHAR(255) NOT NULL（加密存储的密码）
- role：VARCHAR(20) NOT NULL DEFAULT 'admin'（角色：'admin' 普通管理员，'super_admin' 高级管理员）
- created_time：DATETIME NOT NULL（创建时间）
- created_by：BIGINT NULL（创建者管理员id，关联本表的 id，高级管理员添加普通管理员时记录）
- FOREIGN KEY (created_by) REFERENCES admins(id) ON DELETE SET NULL（创建者被删除时置 NULL）

**说明**：
- 普通管理员（admin）：可以查看日志、添加 Agent。
- 高级管理员（super_admin）：拥有普通管理员的所有权限，还可以添加/删除/修改普通管理员的账号（不能修改自己的角色或删除自己）。
- 管理员登录使用独立的登录接口，验证 `admins` 表。
- 管理员操作日志（添加 Agent、添加/删除管理员等）可以单独建一张 `admin_operation_log` 表，也可以复用原有的 `user_activity_log`（扩展 `target_type` 为 `admin_action`），由您决定。

这样设计避免了与普通用户表的冗余字段，且权限管理更清晰。请确认。



**projects 表（项目）**

- id：BIGINT PRIMARY KEY AUTO_INCREMENT
- user_id：BIGINT NOT NULL
- name：VARCHAR(100) NOT NULL（项目名）
- path：VARCHAR(500)（服务器上项目文件夹该用户工作区文件夹/项目的相对路径）
- created_time：DATETIME
- updated_time：DATETIME
- FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE


**chapters 表（文件索引，存txt纯文本）**

- id：BIGINT PRIMARY KEY AUTO_INCREMENT
- project_id：BIGINT NOT NULL
- name：VARCHAR(100) NOT NULL（文件名）
- content_path：VARCHAR(500)（相对于项目根目录的context正文路径）
- note_path：VARCHAR(500)（相对于项目根目录的note路径）
- summary_path：VARCHAR(500)（相对于项目根目录的summary路径）
- word_count：INT
- modified_time：DATETIME（修改时间，每次改这个就同步修改projects 表的updated_time）
- FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE


**knowledge_base 表（知识库）**

- id：BIGINT PRIMARY KEY AUTO_INCREMENT
- user_id：BIGINT NOT NULL
- name：VARCHAR(100) NOT NULL（知识库名）
- path：VARCHAR(500)（服务器上项目文件夹该用户工作区文件夹/知识库的相对路径）
- created_time：DATETIME
- updated_time：DATETIME
- FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE


//
**knowledge 表（知识，存txt纯文本）**
- id：BIGINT PRIMARY KEY AUTO_INCREMENT
- knowledge_base_id：BIGINT NOT NULL
- name：VARCHAR(100) NOT NULL（知识名）
- content_path：VARCHAR(500)（相对于项目根目录的context正文路径）
- brief_introduction_path：VARCHAR(500)（相对于项目根目录的brief_introduction简介路径）
- other_name_path：VARCHAR(500)（相对于项目根目录的other_name别名路径）
- word_count：INT
- modified_time：DATETIME（修改时间，每次改这个就同步修改knowledge_base 表的updated_time）
- FOREIGN KEY (knowledge_base_id) REFERENCES knowledge_base(id) ON DELETE CASCADE


**links_project 表（引用关系）**
- id：BIGINT PRIMARY KEY AUTO_INCREMENT
- knowledge_base_id：BIGINT NOT NULL
- project_id：BIGINT NOT NULL
- FOREIGN KEY (knowledge_base_id) REFERENCES knowledge_base(id) ON DELETE CASCADE,
- FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,
- UNIQUE KEY (knowledge_base_id, project_id)
//项目链接知识库（每次打开项目都扫links表）


**links_chapter 表（引用关系）**
- id：BIGINT PRIMARY KEY AUTO_INCREMENT
- knowledge_id：BIGINT NOT NULL
- chapter_id：BIGINT NOT NULL
- FOREIGN KEY (knowledge_id) REFERENCES knowledge(id) ON DELETE CASCADE,
- FOREIGN KEY (chapter_id) REFERENCES chapters(id) ON DELETE CASCADE,
- UNIQUE KEY (knowledge_id, chapter_id)
//文章链接知识（用于做双向引用）



**settings 表（用户配置）**
- user_id：BIGINT PRIMARY KEY
- theme：VARCHAR(20)（暗色/亮色）
- FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE




**short_term_memory 表（短期记忆，每个项目每个章节只保留最新一条概括）**

- id：BIGINT PRIMARY KEY AUTO_INCREMENT（短期记忆唯一标识）
- project_id：BIGINT NOT NULL（所属项目id，关联projects.id）
- chapter_id：BIGINT NOT NULL（所属章节id，关联chapters.id）
- summary_content：TEXT NOT NULL（章节的概括内容）
- updated_time：DATETIME NOT NULL（最后更新时间，每次覆盖更新时刷新）
- FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE（项目删除时级联删除）
- FOREIGN KEY (chapter_id) REFERENCES chapters(id) ON DELETE CASCADE（章节删除时级联删除）
- UNIQUE KEY uk_project_chapter (project_id, chapter_id)（确保每个项目下每个章节只有一条记录）



**long_term_memory 表（长期记忆，存储短期记忆的整合块）**

- id：BIGINT PRIMARY KEY AUTO_INCREMENT（长期记忆唯一标识）
- project_id：BIGINT NOT NULL（所属项目id，关联projects.id）
- short_term_ids：TEXT NOT NULL（整合的短期记忆ID数组，例如 "1,2,3"）
- content：TEXT NOT NULL（整合后的概括内容）
- created_time：DATETIME NOT NULL（创建时间）
- FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE（项目删除时级联删除）




**user_activity_log 表（用户活动日志，用于统计写作和知识库变更）**

- id：BIGINT PRIMARY KEY AUTO_INCREMENT（日志唯一标识）
- user_id：BIGINT NOT NULL（操作用户id，关联users.id）
- project_id：BIGINT NULL（关联项目id，当操作目标为章节时填写，否则为NULL）
- knowledge_base_id：BIGINT NULL（关联知识库id，当操作目标为知识条目时填写，否则为NULL）
- target_type：VARCHAR(20) NOT NULL（目标类型，取值“chapter”、“knowledge”、“project”、“knowledge_base”）
- chapter_id：BIGINT NULL（章节id，当target_type='chapter'时填写）
- knowledge_id：BIGINT NULL（知识条目id，当target_type='knowledge'时填写）
- action：VARCHAR(20) NOT NULL（操作类型，如“create”、“update”、“delete”）
- word_count_before：INT NULL（操作前的字数，仅对章节update操作有效）
- word_count_after：INT NULL（操作后的字数）
- word_count_increment：INT NULL（字数增量，即after - before）
- activity_time：DATETIME NOT NULL（操作发生的具体时间）
- session_date：DATE NOT NULL（操作发生的日期，冗余字段，用于按天统计）

**说明**：
- `target_id` 不设外键，业务表删除时不影响日志。
- `target_name` 在记录日志时从实际对象中获取并存储。



**ai_providers 表（用户配置的AI提供商）**

- id：BIGINT PRIMARY KEY AUTO_INCREMENT（提供商配置唯一标识）
- user_id：BIGINT NOT NULL（所属用户的id，关联users.id）
- provider_name：VARCHAR(50) NOT NULL（提供商名称，例如 deepseek、openai、gemini）
- api_key：VARCHAR(255) NOT NULL（加密存储的API密钥）
- api_base_url：VARCHAR(255)（可选的自定义API地址，若不填则使用官方默认地址）
- model：VARCHAR(100) NOT NULL（模型名称，如 deepseek-chat、gpt-3.5-turbo）
- is_active：BOOLEAN DEFAULT TRUE（该提供商是否启用，用户可暂时禁用）
- created_time：DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP（添加时间）
- FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE（外键：用户删除时级联删除其配置）
- UNIQUE KEY uk_user_provider (user_id, provider_name)（同一用户不能重复添加同名提供商）


**ai_agent_definitions 表（系统定义的AI Agent类型，只有管理员可以改）**

- agent_code：VARCHAR(50) PRIMARY KEY（Agent唯一代码，如 summary、memory、chat、tab_completion、image_gen、image_caption、suggestion、rag_qa、ppt_generator）
- display_name：VARCHAR(50) NOT NULL（展示名称，如“章节概括、记忆管理、聊天”）
- description：TEXT（Agent功能描述）
- default_system_prompt：TEXT（系统默认提示词，用户不可覆盖，但可追加自定义内容）
- default_min_output_tokens：INT（默认最小输出字数）
- default_max_output_tokens：INT（默认最大输出字数）
- default_enabled：BOOLEAN DEFAULT FALSE（是否默认启用该Agent）
- allows_custom_prompt：BOOLEAN DEFAULT TRUE（是否允许用户追加自定义提示词）
- allows_output_length：BOOLEAN DEFAULT TRUE（是否允许用户自定义输出字数范围）
- allows_memory：BOOLEAN DEFAULT FALSE（是否允许读取ai_memory表）
- allows_chapter_history：BOOLEAN DEFAULT FALSE（是否允许读取历史章节正文）
- allows_knowledge_base：BOOLEAN DEFAULT FALSE（是否允许读取知识库内容）
- allows_rag：BOOLEAN DEFAULT FALSE（是否允许使用 RAG 检索增强生成）


**种子数据（预定义的9个Agent）**：

| agent_code | display_name | default_system_prompt | default_min | default_max | default_enabled | allows_rag | 说明 |
|------------|--------------|----------------------|-------------|-------------|----------------|------------|------|
| summary | 章节概括 | 请概括以下文本的主要内容，提取关键信息。 | 0 | 500 | true | false | 允许自定义提示词、输出长度、记忆、章节历史、知识库 |
| memory | 记忆管理 | 将以下信息整合到项目记忆中。 | 50 | 200 | true | false | 不允许自定义提示词但允许输出长度；不允许读ai_memory表、历史章节、知识库、RAG |
| chat | AI聊天 | （空） | 0 | 2000 | true | true | 允许自定义提示词、历史章节、知识库、记忆、RAG，不允许自定义输出字数 |
| tab_completion | Tab补全 | 根据上下文续写。 | 10 | 150 | true | true | 允许自定义提示词、输出长度、记忆、历史章节、知识库、RAG |
| image_gen | 生成图片 | 你要根据以下描述生成图片： | 0 | 0 | false | false | 允许自定义提示词、历史章节、知识库 |
| image_caption | 图片描述 | 分析图片内容。 | 50 | 200 | false | false | 允许自定义提示词、输出长度 |
| suggestion | 改进建议 | 请分析以下文本的不足并提出改进建议。 | 100 | 800 | true | true | 允许自定义提示词、输出长度、记忆、历史章节、知识库、RAG |
| rag_qa | RAG问答 | 基于知识库检索增强的问答。 | 50 | 1000 | true | true | 专门用于 RAG 检索问答，不可自定义提示词、输出长度；强制读知识库和 RAG |
| ppt_generator | 杂志风PPT生成 | 你是杂志风网页PPT生成专家（遵循6问清单、布局与主题约束，只改main#deck）。 | 800 | 4000 | false | true | 允许自定义提示词、输出长度、记忆、历史章节、知识库、RAG，用于输出单文件HTML PPT |



**ai_agent_configs 表（用户对每个Agent的具体配置）**

- id：BIGINT PRIMARY KEY AUTO_INCREMENT（配置记录唯一标识）
- user_id：BIGINT NOT NULL（所属用户的id，关联users.id）
- agent_code：VARCHAR(50) NOT NULL（Agent代码，关联ai_agent_definitions.agent_code）
- provider_id：BIGINT NULL（用户为该Agent选择的提供商id，关联ai_providers.id；为NULL表示未配置，该Agent不可用）
- is_enabled：BOOLEAN DEFAULT FALSE（用户是否启用该Agent）
- custom_prompt：TEXT（用户追加的自定义提示词，拼接在系统默认提示词之后，不叫就是NULL，此时使用纯默认提示词）
- min_output_tokens：INT（用户自定义的最小输出字数，若为NULL则使用系统默认值）
- max_output_tokens：INT（用户自定义的最大输出字数，若为NULL则使用系统默认值）
- use_memory：BOOLEAN DEFAULT FALSE（是否启用记忆检索，仅对允许记忆的Agent有效）
- use_chapter_history：BOOLEAN DEFAULT FALSE（是否启用历史章节正文检索）
- use_knowledge_base：BOOLEAN DEFAULT FALSE（是否启用知识库检索）
- use_rag：BOOLEAN DEFAULT FALSE（是否启用 RAG 检索增强生成，仅对 allows_rag 为 true 的 Agent 有效）
- chapter_history_count：INT DEFAULT 0（当use_chapter_history为true时，指定往前读多少章正文）
- config_json：TEXT（JSON 格式，存储当前 Agent 特有的配置参数，不同 Agent 使用不同的键值对）（例如tab_agent使用的tab_length：INT（用户按Tab键时AI补全生成的最大字数，默认值由系统决定、记忆agent使用的short_term_batch_size：短期记忆自动整合的批量大小。merge_min_words、merge_max_words：手动整合长期记忆时的字数范围。enable_auto_integration：是否启用自动整合（可开关）；rag_agent 使用的 top_k：INT，检索相似知识块数量，默认3）
- FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE（外键：用户删除时级联删除配置）
- FOREIGN KEY (agent_code) REFERENCES ai_agent_definitions(agent_code) ON DELETE CASCADE（外键：Agent定义删除时级联删除）
- FOREIGN KEY (provider_id) REFERENCES ai_providers(id) ON DELETE SET NULL（外键：提供商被删除时该字段置为NULL）
- UNIQUE KEY uk_user_agent (user_id, agent_code)（每个用户对每个Agent只能有一条配置）



`config_json` 是用来存储每个 Agent 特有参数的（例如 `tab_agent` 的 `tab_length`，记忆 Agent 的 `short_term_batch_size` 等）。当管理员通过后台添加一个新的 Agent 时，需要能够定义这个 Agent 应该有哪些特殊的配置项，以及每个配置项的类型、默认值、取值范围等。否则，前端不知道应该渲染什么控件，后端也不知道如何解析和使用这些配置。

## 解决方案：增加 Agent 配置字段定义表（`ai_agent_config_fields`）

让管理员在添加 Agent 时，同时通过这个表定义该 Agent 支持的 `config_json` 中的字段。这样，前端可以动态生成表单，后端可以按约定读写。

### 新增表结构

**ai_agent_config_fields 表（Agent 特殊配置字段定义）**

- id：BIGINT PRIMARY KEY AUTO_INCREMENT（字段定义唯一标识）
- agent_code：VARCHAR(50) NOT NULL（关联 ai_agent_definitions.agent_code）
- field_name：VARCHAR(50) NOT NULL（config_json 中的键名，例如 "tab_length"）
- display_name：VARCHAR(100) NOT NULL（前端显示名称，例如 "Tab 补全长度"）
- field_type：VARCHAR(20) NOT NULL（字段类型，例如 "int", "string", "boolean"）
- default_value：VARCHAR(255)（JSON 字符串或直接存默认值，如 "10"）
- min_value：INT NULL（仅对 int 类型有效，最小值）
- max_value：INT NULL（仅对 int 类型有效，最大值）
- description：TEXT（帮助文本）
- is_required：BOOLEAN DEFAULT TRUE（是否为必填）
- sort_order：INT DEFAULT 0（显示顺序）
- FOREIGN KEY (agent_code) REFERENCES ai_agent_definitions(agent_code) ON DELETE CASCADE
- UNIQUE KEY uk_agent_field (agent_code, field_name)

### 管理员操作流程

1. 管理员在后台点击「添加 Agent」。
2. 填写 `ai_agent_definitions` 的基本信息（agent_code、display_name、默认 prompt、是否允许记忆/知识库/RAG 等）。
3. 在同一个表单中，可以动态添加「特殊配置项」：点击按钮，填写字段名、显示名称、类型、默认值等。每添加一项，系统就向 `ai_agent_config_fields` 插入一条记录。
4. 提交后，创建 Agent 成功。

### 前端使用方式

当普通用户在 AI 设置页面编辑某个 Agent 的配置时，前端先调用接口获取该 Agent 的 `config_json` 当前值（从 `ai_agent_configs` 表）以及该 Agent 支持的配置字段定义（从 `ai_agent_config_fields` 表）。根据字段定义动态渲染输入控件（例如 int 类型用数字输入框，boolean 用开关），用户修改后保存为 JSON 对象存入 `ai_agent_configs.config_json`。

### 后端使用方式

在调用具体 Agent 的逻辑中（例如 Tab 补全），从 `ai_agent_configs` 读取 `config_json`，转换为 Map，取出 `tab_length` 等参数。如果用户没有设置，则使用字段定义中的 `default_value` 或者系统硬编码默认值。

### 示例数据

对于 `tab_completion` Agent，可以插入以下配置字段定义：

| agent_code | field_name | display_name | field_type | default_value | min_value | max_value |
|------------|------------|--------------|------------|---------------|-----------|-----------|
| tab_completion | tab_length | Tab 补全字数 | int | 150 | 10 | 500 |

对于 `memory` Agent：

| agent_code | field_name | display_name | field_type | default_value | min_value | max_value |
|------------|------------|--------------|------------|---------------|-----------|-----------|
| memory | short_term_batch_size | 短期记忆自动整合条数 | int | 10 | 2 | 50 |
| memory | merge_min_words | 手动整合最小字数 | int | 100 | 50 | 1000 |
| memory | merge_max_words | 手动整合最大字数 | int | 300 | 100 | 2000 |
| memory | enable_auto_integration | 启用自动整合 | boolean | true | null | null |

对于 `ppt_generator` Agent：

| agent_code | field_name | display_name | field_type | default_value | min_value | max_value |
|------------|------------|--------------|------------|---------------|-----------|-----------|
| ppt_generator | theme_name | 主题名称 | string | 墨水经典 | null | null |
| ppt_generator | estimated_minutes | 演讲时长(分钟) | int | 15 | 5 | 90 |
| ppt_generator | target_slide_count | 目标页数 | int | 12 | 6 | 40 |
| ppt_generator | include_image_placeholders | 包含图片占位 | boolean | true | null | null |
| ppt_generator | language | 输出语言 | string | zh-CN | null | null |

## 总结

- **不需要修改原有 `ai_agent_definitions` 和 `ai_agent_configs` 的结构**。
- 增加一张 **配置字段定义表**，由管理员在添加 Agent 时动态定义特殊配置项。
- 前端和后端根据这个元数据表动态生成和解析表单，完全满足扩展性。
- 已有的 Agent 可以迁移现有特殊配置（如果有）到这张表中，或者保留硬编码，但新增 Agent 必须走这个流程。

这样，管理员添加新 Agent 时就能很方便地定义其特殊配置项，用户也能在界面上看到并修改这些配置。





**chat_sessions 表（聊天会话，用于聊天 Agent 的独立记忆区）**

- id：BIGINT PRIMARY KEY AUTO_INCREMENT（会话唯一标识）
- project_id：BIGINT NOT NULL（所属项目id，关联projects.id）
- session_name：VARCHAR(100) NOT NULL（会话名称，如“剧情讨论”，用户可自定义）
- created_time：DATETIME NOT NULL（创建时间）
- updated_time：DATETIME NOT NULL（最后更新时间）
- FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE（项目删除时级联删除所有会话）


**chat_messages 表（聊天消息）**

- id：BIGINT PRIMARY KEY AUTO_INCREMENT（消息唯一标识）
- session_id：BIGINT NOT NULL（所属会话id，关联chat_sessions.id）
- role：VARCHAR(10) NOT NULL（发送者角色，“user”或“assistant”）
- content：TEXT NOT NULL（消息内容）
- created_time：DATETIME NOT NULL（发送时间）
- FOREIGN KEY (session_id) REFERENCES chat_sessions(id) ON DELETE CASCADE（会话删除时级联删除所有消息）



硅基流动平台提供多个免费 Embedding 模型，推荐使用 **BAAI/bge-m3**（免费，1024 维），或者 **BAAI/bge-large-zh-v1.5**（免费，1024 维）。


