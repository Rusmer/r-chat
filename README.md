# R-CHAT

Мессенджер в терминальном стиле. Фронтенд — статика для Cloudflare Pages,
бэкенд — Cloudflare Worker + база данных D1.

```
r-chat/
├── public/
│   └── index.html      ← фронтенд (деплой на Cloudflare Pages)
└── worker/
    ├── src/index.js     ← API (деплой как Cloudflare Worker)
    ├── schema.sql        ← схема + seed-данные для D1
    └── wrangler.toml
```

## 1. Установка Wrangler

```bash
npm install -g wrangler
wrangler login
```

## 2. База данных (D1)

```bash
cd worker
wrangler d1 create r_chat_db
```

Команда выведет `database_id` — вставьте его в `wrangler.toml`:

```toml
[[d1_databases]]
binding = "DB"
database_name = "r_chat_db"
database_id = "ВАШ_ID_СЮДА"
```

Залейте схему и тестовые данные:

```bash
wrangler d1 execute r_chat_db --file=./schema.sql --remote
```

## 3. Деплой Worker (API)

```bash
cd worker
wrangler deploy
```

В выводе будет URL вида `https://r-chat-api.<ваш-субдомен>.workers.dev` — это адрес вашего API.

## 4. Подключение фронтенда к API

Откройте `public/index.html`, найдите строку:

```js
const API_BASE = "";
```

и впишите туда адрес воркера:

```js
const API_BASE = "https://r-chat-api.<ваш-субдомен>.workers.dev";
```

Если оставить пустым — сайт сам переключится в demo-режим на локальных
тестовых данных (это сделано специально, чтобы фронтенд можно было
открыть и посмотреть без бэкенда).

## 5. Деплой фронтенда (Pages)

Из корня проекта:

```bash
wrangler pages deploy public --project-name=r-chat
```

Либо через дашборд Cloudflare: Pages → Create project → Direct upload →
загрузить папку `public/`.

## 6. CORS

Воркер по умолчанию отвечает `Access-Control-Allow-Origin` под запросивший
`Origin`, так что достаточно задеплоить как есть. Если хотите ограничить
доступ конкретно вашим доменом Pages — замените в `worker/src/index.js`:

```js
resp.headers.set("Access-Control-Allow-Origin", origin || "*");
```

на жёстко заданный домен, например `"https://r-chat.pages.dev"`.

## API

| Метод | Путь                                   | Описание                          |
|-------|-----------------------------------------|------------------------------------|
| GET   | `/api/servers`                          | список серверов                    |
| GET   | `/api/servers/:id/channels`             | каналы сервера (`{text, voice}`)   |
| GET   | `/api/servers/:id/members`              | участники сервера                  |
| GET   | `/api/channels/:id/messages?after=<ms>` | сообщения канала после метки времени |
| POST  | `/api/channels/:id/messages`            | отправить сообщение `{user, text}` |

## Что дальше

Сейчас новые сообщения подтягиваются поллингом раз в 3 секунды —
этого достаточно для чата на несколько человек. Если нужен настоящий
realtime (мгновенная доставка, "печатает...", голосовые каналы) —
следующий шаг — завести Durable Object на канал и перейти на WebSocket.
Могу собрать и это, если понадобится.
