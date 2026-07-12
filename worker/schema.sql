-- R-CHAT schema for Cloudflare D1

DROP TABLE IF EXISTS messages;
DROP TABLE IF EXISTS members;
DROP TABLE IF EXISTS channels;
DROP TABLE IF EXISTS servers;

CREATE TABLE servers (
  id   TEXT PRIMARY KEY,
  code TEXT NOT NULL,
  name TEXT NOT NULL,
  path TEXT NOT NULL
);

CREATE TABLE channels (
  id          TEXT PRIMARY KEY,
  server_id   TEXT NOT NULL,
  type        TEXT NOT NULL DEFAULT 'text', -- 'text' | 'voice'
  name        TEXT NOT NULL,
  description TEXT DEFAULT '',
  FOREIGN KEY (server_id) REFERENCES servers(id)
);

CREATE TABLE members (
  id        TEXT PRIMARY KEY,
  server_id TEXT NOT NULL,
  name      TEXT NOT NULL,
  role      TEXT DEFAULT '',
  status    TEXT DEFAULT 'offline', -- 'online' | 'idle' | 'dnd' | 'offline'
  FOREIGN KEY (server_id) REFERENCES servers(id)
);

CREATE TABLE messages (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  channel_id TEXT NOT NULL,
  user_name  TEXT NOT NULL,
  text       TEXT NOT NULL,
  created_at INTEGER NOT NULL, -- unix ms
  FOREIGN KEY (channel_id) REFERENCES channels(id)
);

CREATE INDEX idx_messages_channel_time ON messages (channel_id, created_at);
CREATE INDEX idx_channels_server ON channels (server_id);
CREATE INDEX idx_members_server ON members (server_id);

-- ===================== SEED DATA =====================

INSERT INTO servers (id, code, name, path) VALUES
 ('s1','R','general-hub','~/servers/general-hub'),
 ('s2','D','dev-team','~/servers/dev-team'),
 ('s3','G','gaming','~/servers/gaming'),
 ('s4','M','music-lab','~/servers/music-lab');

INSERT INTO channels (id, server_id, type, name, description) VALUES
 ('c1','s1','text','general','общий канал сервера'),
 ('c2','s1','text','random','обо всём и ни о чём'),
 ('c3','s1','text','announcements','важные объявления'),
 ('v1','s1','voice','lounge',''),
 ('v2','s1','voice','meeting-room',''),

 ('c4','s2','text','backend','серверная часть'),
 ('c5','s2','text','frontend','клиентская часть'),
 ('c6','s2','text','deploys','логи и релизы'),
 ('v3','s2','voice','standup',''),

 ('c7','s3','text','lobby','сбор группы'),
 ('c8','s3','text','clips','лучшие моменты'),
 ('v4','s3','voice','squad-1',''),
 ('v5','s3','voice','squad-2',''),

 ('c9','s4','text','tracks','делимся треками'),
 ('v6','s4','voice','listening-room','');

INSERT INTO members (id, server_id, name, role, status) VALUES
 ('m1','s1','root_admin','ADMIN','online'),
 ('m2','s1','kernel_dev','MOD','online'),
 ('m3','s1','null_ptr','','idle'),
 ('m4','s1','stack_overflow','','dnd'),
 ('m5','s1','ghost_proc','','offline'),
 ('m6','s1','byte_runner','','offline'),

 ('m7','s2','root_admin','ADMIN','online'),
 ('m8','s2','compiler_err','','idle'),
 ('m9','s2','segfault','','offline'),

 ('m10','s3','frag_master','','online'),
 ('m11','s3','afk_check','','idle'),
 ('m12','s3','respawn','','offline'),

 ('m13','s4','dj_static','','online'),
 ('m14','s4','lofi_beats','','offline');

INSERT INTO messages (channel_id, user_name, text, created_at) VALUES
 ('c1','root_admin','запустил новый канал для тестов, всем добро пожаловать', 1750000000000),
 ('c1','kernel_dev','принято, конфиг подтянул', 1750000100000),
 ('c1','null_ptr','кто-нибудь смотрел логи с ночного деплоя?', 1750000200000),
 ('c1','kernel_dev','да, всё чисто, 0 ошибок', 1750000300000),
 ('c2','ghost_proc','кофе кончился, это критическая ошибка', 1750000400000),
 ('c2','byte_runner','сочувствую, у меня то же самое', 1750000500000),
 ('c3','root_admin','плановые работы на сервере сегодня в 23:00', 1750000600000),
 ('c4','root_admin','мёрджим ветку feature/auth в main', 1750000700000),
 ('c4','compiler_err','ревью отправил, два комментария', 1750000800000),
 ('c6','root_admin','деплой v1.4.2 завершён успешно', 1750000900000),
 ('c7','frag_master','го катка через 10 минут', 1750001000000),
 ('c9','dj_static','новый трек в закрепе, послушайте', 1750001100000);
