const http = require('http');
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

loadEnv();

const port = Number(process.env.PORT || 3001);
const state = {
  messages: [],
  requests: [],
  rooms: [],
  logs: [],
};

function loadEnv() {
  const envPath = path.join(__dirname, '.env');
  if (!fs.existsSync(envPath)) return;
  for (const line of fs.readFileSync(envPath, 'utf8').split(/\r?\n/)) {
    if (!line || line.trim().startsWith('#')) continue;
    const idx = line.indexOf('=');
    if (idx === -1) continue;
    const key = line.slice(0, idx).trim();
    const value = line.slice(idx + 1).trim();
    process.env[key] = process.env[key] || value;
  }
}

function json(res, status, data) {
  res.writeHead(status, {
    'content-type': 'application/json',
    'access-control-allow-origin': '*',
    'access-control-allow-methods': 'GET,POST,OPTIONS',
    'access-control-allow-headers': 'content-type',
  });
  res.end(JSON.stringify(data));
}

function readBody(req) {
  return new Promise((resolve) => {
    let body = '';
    req.on('data', (chunk) => (body += chunk));
    req.on('end', () => {
      try {
        resolve(body ? JSON.parse(body) : {});
      } catch (_) {
        resolve({});
      }
    });
  });
}

function upsert(list, item) {
  const idx = list.findIndex((x) => x.id === item.id);
  if (idx === -1) list.push(item);
  else list[idx] = { ...list[idx], ...item };
  return idx === -1 ? item : list[idx];
}

function roomForRequest(request) {
  let room = state.rooms.find((x) => x.callRequestId === request.id);
  if (!room) {
    room = {
      id: crypto.randomUUID(),
      callRequestId: request.id,
      hmsRoomId: `wtf_room_${request.id.slice(0, 8)}`,
      hmsRoleMember: 'member',
      hmsRoleTrainer: 'trainer',
    };
    state.rooms.push(room);
  }
  return room;
}

function base64url(value) {
  return Buffer.from(JSON.stringify(value)).toString('base64url');
}

function signToken({ userId, role, roomId }) {
  const key = process.env.HMS_APP_ACCESS_KEY;
  const secret = process.env.HMS_APP_SECRET;
  if (!key || !secret) {
    return `mock_token_${userId}_${role}_${Date.now()}`;
  }

  const now = Math.floor(Date.now() / 1000);
  const header = { alg: 'HS256', typ: 'JWT' };
  const payload = {
    access_key: key,
    room_id: roomId || process.env.HMS_ROOM_ID || 'demo-room',
    user_id: userId,
    role,
    type: 'app',
    version: 2,
    iat: now,
    exp: now + 3600,
    jti: crypto.randomUUID(),
  };
  const unsigned = `${base64url(header)}.${base64url(payload)}`;
  const sig = crypto.createHmac('sha256', secret).update(unsigned).digest('base64url');
  return `${unsigned}.${sig}`;
}

const server = http.createServer(async (req, res) => {
  if (req.method === 'OPTIONS') return json(res, 200, {});

  const url = new URL(req.url, `http://${req.headers.host}`);
  const body = req.method === 'POST' ? await readBody(req) : {};

  if (url.pathname === '/health') return json(res, 200, { ok: true });

  if (url.pathname === '/token') {
    return json(res, 200, {
      token: signToken({
        userId: url.searchParams.get('userId') || 'dev-user',
        role: url.searchParams.get('role') || 'member',
        roomId: url.searchParams.get('roomId') || process.env.HMS_ROOM_ID,
      }),
    });
  }

  if (url.pathname === '/messages' && req.method === 'GET') {
    return json(res, 200, state.messages);
  }
  if (url.pathname === '/messages' && req.method === 'POST') {
    const saved = upsert(state.messages, body);
    return json(res, 200, saved);
  }
  if (url.pathname === '/messages/read' && req.method === 'POST') {
    for (const msg of state.messages) {
      if (msg.chatId === body.chatId && msg.receiverId === body.userId) {
        msg.status = 'read';
      }
    }
    return json(res, 200, { ok: true });
  }

  if (url.pathname === '/requests' && req.method === 'GET') {
    return json(res, 200, state.requests);
  }
  if (url.pathname === '/requests' && req.method === 'POST') {
    const saved = upsert(state.requests, body);
    return json(res, 200, saved);
  }
  if (url.pathname === '/requests/approve' && req.method === 'POST') {
    const reqItem = state.requests.find((x) => x.id === body.id);
    if (!reqItem) return json(res, 404, { error: 'Request not found' });
    reqItem.status = 'approved';
    const room = roomForRequest(reqItem);
    return json(res, 200, { request: reqItem, room });
  }
  if (url.pathname === '/requests/decline' && req.method === 'POST') {
    const reqItem = state.requests.find((x) => x.id === body.id);
    if (!reqItem) return json(res, 404, { error: 'Request not found' });
    reqItem.status = 'declined';
    reqItem.declineReason = body.reason || 'No reason provided';
    return json(res, 200, { request: reqItem });
  }
  if (url.pathname === '/rooms') {
    return json(res, 200, state.rooms);
  }

  if (url.pathname === '/logs' && req.method === 'GET') {
    return json(res, 200, state.logs);
  }
  if (url.pathname === '/logs' && req.method === 'POST') {
    const saved = upsert(state.logs, body);
    return json(res, 200, saved);
  }
  if (
    (url.pathname === '/logs/member-notes' || url.pathname === '/logs/trainer-notes') &&
    req.method === 'POST'
  ) {
    const saved = upsert(state.logs, body);
    return json(res, 200, saved);
  }

  return json(res, 404, { error: 'Not found' });
});

server.listen(port, () => {
  console.log(`[TOKEN] local server running on http://localhost:${port}`);
});
