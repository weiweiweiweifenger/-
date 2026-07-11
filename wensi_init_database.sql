-- =============================================================================
-- Wensi 数据库一键初始化（依据 wensi_data_base.md）
-- 用法（示例）:
--   mysql -u root -p < wensi_init_database.sql
-- 或在 mysql 客户端中: SOURCE /path/to/wensi_init_database.sql;
-- =============================================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

DROP DATABASE IF EXISTS `wensi`;
CREATE DATABASE `wensi` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `wensi`;

-- -----------------------------------------------------------------------------
-- users（用户）
-- -----------------------------------------------------------------------------
CREATE TABLE `users` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `username` VARCHAR(50) NOT NULL,
  `password` VARCHAR(255) NOT NULL COMMENT '加密存储',
  `path` VARCHAR(500) DEFAULT NULL COMMENT '用户文件夹绝对路径',
  `created_time` DATETIME DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------------------------
-- admins（管理员）
-- -----------------------------------------------------------------------------
CREATE TABLE `admins` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `username` VARCHAR(50) NOT NULL,
  `password` VARCHAR(255) NOT NULL COMMENT '加密存储',
  `role` VARCHAR(20) NOT NULL DEFAULT 'admin' COMMENT 'admin 或 super_admin',
  `created_time` DATETIME NOT NULL,
  `created_by` BIGINT DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_admins_username` (`username`),
  KEY `idx_admins_created_by` (`created_by`),
  CONSTRAINT `fk_admins_created_by` FOREIGN KEY (`created_by`) REFERENCES `admins` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `admins` (`username`, `password`, `role`, `created_time`, `created_by`)
VALUES ('admin', 'admin', 'super_admin', NOW(), NULL);

-- -----------------------------------------------------------------------------
-- projects（项目）
-- -----------------------------------------------------------------------------
CREATE TABLE `projects` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `user_id` BIGINT NOT NULL,
  `name` VARCHAR(100) NOT NULL,
  `path` VARCHAR(500) DEFAULT NULL,
  `created_time` DATETIME DEFAULT NULL,
  `updated_time` DATETIME DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_projects_user_id` (`user_id`),
  CONSTRAINT `fk_projects_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------------------------
-- chapters（文件索引）
-- -----------------------------------------------------------------------------
CREATE TABLE `chapters` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `project_id` BIGINT NOT NULL,
  `name` VARCHAR(100) NOT NULL,
  `content_path` VARCHAR(500) DEFAULT NULL,
  `note_path` VARCHAR(500) DEFAULT NULL,
  `summary_path` VARCHAR(500) DEFAULT NULL,
  `word_count` INT DEFAULT NULL,
  `modified_time` DATETIME DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_chapters_project_id` (`project_id`),
  CONSTRAINT `fk_chapters_project` FOREIGN KEY (`project_id`) REFERENCES `projects` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------------------------
-- knowledge_base（知识库）
-- -----------------------------------------------------------------------------
CREATE TABLE `knowledge_base` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `user_id` BIGINT NOT NULL,
  `name` VARCHAR(100) NOT NULL,
  `path` VARCHAR(500) DEFAULT NULL,
  `created_time` DATETIME DEFAULT NULL,
  `updated_time` DATETIME DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_knowledge_base_user_id` (`user_id`),
  CONSTRAINT `fk_knowledge_base_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------------------------
-- knowledge（知识）
-- -----------------------------------------------------------------------------
CREATE TABLE `knowledge` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `knowledge_base_id` BIGINT NOT NULL,
  `name` VARCHAR(100) NOT NULL,
  `content_path` VARCHAR(500) DEFAULT NULL,
  `brief_introduction_path` VARCHAR(500) DEFAULT NULL,
  `other_name_path` VARCHAR(500) DEFAULT NULL,
  `word_count` INT DEFAULT NULL,
  `modified_time` DATETIME DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_knowledge_kb_id` (`knowledge_base_id`),
  CONSTRAINT `fk_knowledge_kb` FOREIGN KEY (`knowledge_base_id`) REFERENCES `knowledge_base` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------------------------
-- links_project（项目链接知识库）
-- -----------------------------------------------------------------------------
CREATE TABLE `links_project` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `knowledge_base_id` BIGINT NOT NULL,
  `project_id` BIGINT NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_links_project_kb_proj` (`knowledge_base_id`, `project_id`),
  KEY `idx_links_project_project_id` (`project_id`),
  CONSTRAINT `fk_links_project_kb` FOREIGN KEY (`knowledge_base_id`) REFERENCES `knowledge_base` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_links_project_project` FOREIGN KEY (`project_id`) REFERENCES `projects` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------------------------
-- links_chapter（文章链接知识）
-- -----------------------------------------------------------------------------
CREATE TABLE `links_chapter` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `knowledge_id` BIGINT NOT NULL,
  `chapter_id` BIGINT NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_links_chapter_knowledge_chapter` (`knowledge_id`, `chapter_id`),
  KEY `idx_links_chapter_chapter_id` (`chapter_id`),
  CONSTRAINT `fk_links_chapter_knowledge` FOREIGN KEY (`knowledge_id`) REFERENCES `knowledge` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_links_chapter_chapter` FOREIGN KEY (`chapter_id`) REFERENCES `chapters` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------------------------
-- settings（用户配置）
-- -----------------------------------------------------------------------------
CREATE TABLE `settings` (
  `user_id` BIGINT NOT NULL,
  `theme` VARCHAR(20) DEFAULT NULL,
  PRIMARY KEY (`user_id`),
  CONSTRAINT `fk_settings_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------------------------
-- short_term_memory（短期记忆）
-- -----------------------------------------------------------------------------
CREATE TABLE `short_term_memory` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `project_id` BIGINT NOT NULL,
  `chapter_id` BIGINT NOT NULL,
  `summary_content` TEXT NOT NULL,
  `updated_time` DATETIME NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_project_chapter` (`project_id`, `chapter_id`),
  KEY `idx_stm_chapter_id` (`chapter_id`),
  CONSTRAINT `fk_stm_project` FOREIGN KEY (`project_id`) REFERENCES `projects` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_stm_chapter` FOREIGN KEY (`chapter_id`) REFERENCES `chapters` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------------------------
-- long_term_memory（长期记忆）
-- -----------------------------------------------------------------------------
CREATE TABLE `long_term_memory` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `project_id` BIGINT NOT NULL,
  `short_term_ids` TEXT NOT NULL,
  `content` TEXT NOT NULL,
  `created_time` DATETIME NOT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_ltm_project_id` (`project_id`),
  CONSTRAINT `fk_ltm_project` FOREIGN KEY (`project_id`) REFERENCES `projects` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------------------------
-- user_activity_log（用户活动日志）
-- -----------------------------------------------------------------------------
CREATE TABLE `user_activity_log` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `user_id` BIGINT NOT NULL,
  `project_id` BIGINT DEFAULT NULL,
  `knowledge_base_id` BIGINT DEFAULT NULL,
  `target_type` VARCHAR(20) NOT NULL,
  `chapter_id` BIGINT DEFAULT NULL,
  `knowledge_id` BIGINT DEFAULT NULL,
  `action` VARCHAR(20) NOT NULL,
  `word_count_before` INT DEFAULT NULL,
  `word_count_after` INT DEFAULT NULL,
  `word_count_increment` INT DEFAULT NULL,
  `activity_time` DATETIME NOT NULL,
  `session_date` DATE NOT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_user_activity_user_id` (`user_id`),
  KEY `idx_user_activity_project_id` (`project_id`),
  KEY `idx_user_activity_knowledge_base_id` (`knowledge_base_id`),
  KEY `idx_user_activity_chapter_id` (`chapter_id`),
  KEY `idx_user_activity_knowledge_id` (`knowledge_id`),
  KEY `idx_user_activity_session_date` (`session_date`),
  CONSTRAINT `fk_user_activity_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_user_activity_project` FOREIGN KEY (`project_id`) REFERENCES `projects` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_user_activity_kb` FOREIGN KEY (`knowledge_base_id`) REFERENCES `knowledge_base` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_user_activity_chapter` FOREIGN KEY (`chapter_id`) REFERENCES `chapters` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_user_activity_knowledge` FOREIGN KEY (`knowledge_id`) REFERENCES `knowledge` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------------------------
-- ai_providers（用户配置的AI提供商）
-- -----------------------------------------------------------------------------
CREATE TABLE `ai_providers` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `user_id` BIGINT NOT NULL,
  `provider_name` VARCHAR(50) NOT NULL,
  `api_key` VARCHAR(255) NOT NULL,
  `api_base_url` VARCHAR(255) DEFAULT NULL,
  `model` VARCHAR(100) NOT NULL,
  `is_active` BOOLEAN DEFAULT TRUE,
  `created_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_user_provider` (`user_id`, `provider_name`),
  CONSTRAINT `fk_ai_providers_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------------------------
-- ai_agent_definitions（系统定义的AI Agent类型）
-- -----------------------------------------------------------------------------
CREATE TABLE `ai_agent_definitions` (
  `agent_code` VARCHAR(50) NOT NULL,
  `display_name` VARCHAR(50) NOT NULL,
  `description` TEXT,
  `default_system_prompt` TEXT,
  `default_min_output_tokens` INT DEFAULT NULL,
  `default_max_output_tokens` INT DEFAULT NULL,
  `default_enabled` BOOLEAN DEFAULT FALSE,
  `allows_custom_prompt` BOOLEAN DEFAULT TRUE,
  `allows_output_length` BOOLEAN DEFAULT TRUE,
  `allows_memory` BOOLEAN DEFAULT FALSE,
  `allows_chapter_history` BOOLEAN DEFAULT FALSE,
  `allows_knowledge_base` BOOLEAN DEFAULT FALSE,
  `allows_rag` BOOLEAN DEFAULT FALSE,
  PRIMARY KEY (`agent_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------------------------
-- ai_agent_configs（用户对每个Agent的具体配置）
-- -----------------------------------------------------------------------------
CREATE TABLE `ai_agent_configs` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `user_id` BIGINT NOT NULL,
  `agent_code` VARCHAR(50) NOT NULL,
  `provider_id` BIGINT DEFAULT NULL,
  `is_enabled` BOOLEAN DEFAULT FALSE,
  `custom_prompt` TEXT,
  `min_output_tokens` INT DEFAULT NULL,
  `max_output_tokens` INT DEFAULT NULL,
  `use_memory` BOOLEAN DEFAULT FALSE,
  `use_chapter_history` BOOLEAN DEFAULT FALSE,
  `use_knowledge_base` BOOLEAN DEFAULT FALSE,
  `use_rag` BOOLEAN DEFAULT FALSE,
  `chapter_history_count` INT DEFAULT 0,
  `config_json` TEXT,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_user_agent` (`user_id`, `agent_code`),
  KEY `idx_ai_agent_configs_provider_id` (`provider_id`),
  CONSTRAINT `fk_ai_agent_configs_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_ai_agent_configs_agent` FOREIGN KEY (`agent_code`) REFERENCES `ai_agent_definitions` (`agent_code`) ON DELETE CASCADE,
  CONSTRAINT `fk_ai_agent_configs_provider` FOREIGN KEY (`provider_id`) REFERENCES `ai_providers` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------------------------
-- ai_agent_config_fields（Agent 特殊配置字段定义）
-- -----------------------------------------------------------------------------
CREATE TABLE `ai_agent_config_fields` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `agent_code` VARCHAR(50) NOT NULL,
  `field_name` VARCHAR(50) NOT NULL,
  `display_name` VARCHAR(100) NOT NULL,
  `field_type` VARCHAR(20) NOT NULL,
  `default_value` VARCHAR(255) DEFAULT NULL,
  `min_value` INT DEFAULT NULL,
  `max_value` INT DEFAULT NULL,
  `description` TEXT,
  `is_required` BOOLEAN DEFAULT TRUE,
  `sort_order` INT DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_agent_field` (`agent_code`, `field_name`),
  CONSTRAINT `fk_ai_agent_config_fields_agent` FOREIGN KEY (`agent_code`) REFERENCES `ai_agent_definitions` (`agent_code`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------------------------
-- chat_sessions（聊天会话）
-- -----------------------------------------------------------------------------
CREATE TABLE `chat_sessions` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `project_id` BIGINT NOT NULL,
  `session_name` VARCHAR(100) NOT NULL,
  `created_time` DATETIME NOT NULL,
  `updated_time` DATETIME NOT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_chat_sessions_project_id` (`project_id`),
  CONSTRAINT `fk_chat_sessions_project` FOREIGN KEY (`project_id`) REFERENCES `projects` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------------------------
-- chat_messages（聊天消息）
-- -----------------------------------------------------------------------------
CREATE TABLE `chat_messages` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `session_id` BIGINT NOT NULL,
  `role` VARCHAR(10) NOT NULL,
  `content` TEXT NOT NULL,
  `created_time` DATETIME NOT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_chat_messages_session_id` (`session_id`),
  CONSTRAINT `fk_chat_messages_session` FOREIGN KEY (`session_id`) REFERENCES `chat_sessions` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------------------------
-- ai_agent_definitions 种子数据（预定义 9 个 Agent）
-- -----------------------------------------------------------------------------
INSERT INTO `ai_agent_definitions` (
  `agent_code`, `display_name`, `description`, `default_system_prompt`,
  `default_min_output_tokens`, `default_max_output_tokens`, `default_enabled`,
  `allows_custom_prompt`, `allows_output_length`, `allows_memory`,
  `allows_chapter_history`, `allows_knowledge_base`, `allows_rag`
) VALUES
  ('summary', '章节概括', '章节概括 Agent', '请概括以下文本的主要内容，提取关键信息。', 0, 500, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, FALSE),
  ('memory', '记忆管理', '记忆管理 Agent', '将以下信息整合到项目记忆中。', 50, 200, TRUE, FALSE, TRUE, FALSE, FALSE, FALSE, FALSE),
  ('chat', 'AI聊天', '通用聊天 Agent', NULL, 0, 2000, TRUE, TRUE, FALSE, TRUE, TRUE, TRUE, TRUE),
  ('tab_completion', 'Tab补全', 'Tab 补全 Agent', '根据上下文续写。', 10, 150, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE),
  ('image_gen', '生成图片', '图像生成 Agent', '你要根据以下描述生成图片：', 0, 0, FALSE, TRUE, TRUE, FALSE, TRUE, TRUE, FALSE),
  ('image_caption', '图片描述', '图片理解 Agent', '分析图片内容。', 50, 200, FALSE, TRUE, TRUE, FALSE, FALSE, FALSE, FALSE),
  ('suggestion', '改进建议', '文本改进建议 Agent', '请分析以下文本的不足并提出改进建议。', 100, 800, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE),
  ('rag_qa', 'RAG问答', 'RAG 检索问答 Agent', '基于知识库检索增强的问答。', 50, 1000, TRUE, FALSE, FALSE, FALSE, FALSE, TRUE, TRUE),
  ('ppt_generator', '杂志风PPT生成', '基于项目章节内容生成杂志风单文件HTML横向翻页PPT', '你是杂志风网页PPT生成专家。必须遵循：先明确受众/时长/素材/图片/主题/硬约束；只使用模板既有样式与布局类；仅修改main#deck内section；主题色使用预设并保持单一；图片比例遵循16:9/16:10/4:3/3:2/1:1；保证hero与light/dark节奏；输出可直接浏览器打开的完整HTML。', 800, 4000, FALSE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE);

-- -----------------------------------------------------------------------------
-- ai_agent_config_fields 种子数据（示例）
-- -----------------------------------------------------------------------------
INSERT INTO `ai_agent_config_fields` (
  `agent_code`, `field_name`, `display_name`, `field_type`,
  `default_value`, `min_value`, `max_value`, `description`, `is_required`, `sort_order`
) VALUES
  ('tab_completion', 'tab_length', 'Tab 补全字数', 'int', '150', 10, 500, '用户按 Tab 键时 AI 补全生成的最大字数', TRUE, 1),
  ('memory', 'short_term_batch_size', '短期记忆自动整合条数', 'int', '10', 2, 50, '自动整合时一次处理的短期记忆条数', TRUE, 1),
  ('memory', 'merge_min_words', '手动整合最小字数', 'int', '100', 50, 1000, '手动整合长期记忆时最小字数', TRUE, 2),
  ('memory', 'merge_max_words', '手动整合最大字数', 'int', '300', 100, 2000, '手动整合长期记忆时最大字数', TRUE, 3),
  ('memory', 'enable_auto_integration', '启用自动整合', 'boolean', 'true', NULL, NULL, '是否启用短期记忆自动整合', TRUE, 4),
  ('ppt_generator', 'theme_name', '主题名称', 'string', '墨水经典', NULL, NULL, '推荐主题名称（墨水经典/靛蓝瓷/森林墨/牛皮纸/沙丘）', TRUE, 1),
  ('ppt_generator', 'estimated_minutes', '演讲时长(分钟)', 'int', '15', 5, 90, '用于估算信息密度和节奏', TRUE, 2),
  ('ppt_generator', 'target_slide_count', '目标页数', 'int', '12', 6, 40, '生成PPT目标页数', TRUE, 3),
  ('ppt_generator', 'include_image_placeholders', '包含图片占位', 'boolean', 'true', NULL, NULL, '是否在图文页输出图片占位与比例提示', TRUE, 4),
  ('ppt_generator', 'language', '输出语言', 'string', 'zh-CN', NULL, NULL, '输出文本语言，例如 zh-CN / en-US', TRUE, 5);

SET FOREIGN_KEY_CHECKS = 1;
