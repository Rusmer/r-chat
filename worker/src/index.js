/**
 * R-CHAT API — Cloudflare Worker + D1
 *
 * Routes:
 *   GET  /api/servers
 *   GET  /api/servers/:serverId/channels
 *   GET  /api/servers/:serverId/members
 *   GET  /api/channels/:channelId/messages?after=<unix_ms>
 *   POST /api/channels/:channelId/messages   { user, text }
 */

function json(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

function withCors(resp, origin) {
  resp.headers.set("Access-Control-Allow-Origin", origin || "*");
  resp.headers.set("Access-Control-Allow-Methods", "GET,POST,OPTIONS");
  resp.headers.set("Access-Control-Allow-Headers", "Content-Type");
  return resp;
}

async function getServers(env) {
  const { results } = await env.DB.prepare(
    "SELECT id, code, name, path FROM servers ORDER BY rowid"
  ).all();
  return json(results);
}

async function getChannels(env, serverId) {
  const { results } = await env.DB.prepare(
    "SELECT id, type, name, description FROM channels WHERE server_id = ? ORDER BY type, rowid"
  )
    .bind(serverId)
    .all();
  return json({
    text: results.filter((c) => c.type === "text"),
    voice: results.filter((c) => c.type === "voice"),
  });
}

async function getMembers(env, serverId) {
  const { results } = await env.DB.prepare(
    `SELECT id, name, role, status FROM members WHERE server_id = ?
     ORDER BY CASE status WHEN 'online' THEN 0 WHEN 'dnd' THEN 1 WHEN 'idle' THEN 2 ELSE 3 END, name`
  )
    .bind(serverId)
    .all();
  return json(results);
}

async function getMessages(env, channelId, url) {
  const after = Number(url.searchParams.get("after") || 0);
  const { results } = await env.DB.prepare(
    `SELECT id, user_name as user, text, created_at as time
     FROM messages WHERE channel_id = ? AND created_at > ?
     ORDER BY created_at ASC LIMIT 200`
  )
    .bind(channelId, after)
    .all();
  return json(results);
}

async function postMessage(env, channelId, request) {
  const body = await request.json().catch(() => ({}));
  const user = String(body.user || "anon").slice(0, 32);
  const text = String(body.text || "").slice(0, 2000).trim();
  if (!text) return json({ error: "empty message" }, 400);

  const createdAt = Date.now();
  const res = await env.DB.prepare(
    "INSERT INTO messages (channel_id, user_name, text, created_at) VALUES (?, ?, ?, ?)"
  )
    .bind(channelId, user, text, createdAt)
    .run();

  return json({ id: res.meta.last_row_id, user, text, time: createdAt });
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const { pathname } = url;
    const origin = request.headers.get("Origin") || "*";

    if (request.method === "OPTIONS") {
      return withCors(new Response(null, { status: 204 }), origin);
    }

    try {
      if (pathname === "/api/servers" && request.method === "GET") {
        return withCors(await getServers(env), origin);
      }

      const channelsMatch = pathname.match(/^\/api\/servers\/([^/]+)\/channels$/);
      if (channelsMatch && request.method === "GET") {
        return withCors(await getChannels(env, channelsMatch[1]), origin);
      }

      const membersMatch = pathname.match(/^\/api\/servers\/([^/]+)\/members$/);
      if (membersMatch && request.method === "GET") {
        return withCors(await getMembers(env, membersMatch[1]), origin);
      }

      const messagesMatch = pathname.match(/^\/api\/channels\/([^/]+)\/messages$/);
      if (messagesMatch && request.method === "GET") {
        return withCors(await getMessages(env, messagesMatch[1], url), origin);
      }
      if (messagesMatch && request.method === "POST") {
        return withCors(await postMessage(env, messagesMatch[1], request), origin);
      }

      return withCors(json({ error: "not found" }, 404), origin);
    } catch (err) {
      return withCors(json({ error: err.message || String(err) }, 500), origin);
    }
  },
};
