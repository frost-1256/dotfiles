import { readFileSync, existsSync } from "fs"
import { homedir } from "os"

const UPSTREAM = "https://opencode.ai"
const PORT = Number(process.env.ZEN_PROXY_PORT ?? 8790)
const UA = "opencode/1.18.34 ai-sdk/provider-utils/4.0.23 runtime/bun/1.4.2"
const SESSION_TTL = 20 * 60 * 1000

function resolveKey(): string {
  if (process.env.OPENCODE_API_KEY) return process.env.OPENCODE_API_KEY
  for (const p of [`${homedir()}/.omp/agent/.env`, `${homedir()}/.env`]) {
    if (!existsSync(p)) continue
    for (const line of readFileSync(p, "utf8").split("\n")) {
      const m = line.match(/^\s*OPENCODE_API_KEY\s*=\s*(.+?)\s*$/)
      if (m) return m[1].replace(/^["']|["']$/g, "")
    }
  }
  const authPath = `${homedir()}/.local/share/opencode/auth.json`
  if (existsSync(authPath)) {
    const key = JSON.parse(readFileSync(authPath, "utf8"))?.opencode?.key
    if (key) return key
  }
  throw new Error("no OPENCODE_API_KEY found (env, ~/.omp/agent/.env, or opencode auth.json)")
}

const API_KEY = (() => {
  try {
    return resolveKey()
  } catch {
    return ""
  }
})()
const CHARS = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
function resolveToolsPath(): string {
  if (process.env.ZEN_PROXY_TOOLS) return process.env.ZEN_PROXY_TOOLS
  const local = new URL("./opencode_tools.json", import.meta.url)
  if (existsSync(local)) return local.pathname
  return `${homedir()}/.omp/zen-proxy/opencode_tools.json`
}

const OC_TOOLS: any[] = JSON.parse(readFileSync(resolveToolsPath(), "utf8"))
const OC_TOOLS_RESP = OC_TOOLS.map((t) => ({
  type: "function",
  name: t.function.name,
  description: t.function.description,
  parameters: t.function.parameters,
  ...(t.function.strict !== undefined ? { strict: t.function.strict } : {}),
}))

function makeSession(): string {
  const r = ~(BigInt(Date.now()) * 4096n + 1n)
  const b = Buffer.alloc(6)
  for (let i = 0; i < 6; i++) b[i] = Number((r >> BigInt(40 - 8 * i)) & 255n)
  const rb = crypto.getRandomValues(new Uint8Array(14))
  let suffix = ""
  for (let i = 0; i < 14; i++) suffix += CHARS[rb[i] % 62]
  return "ses_" + b.toString("hex") + suffix
}

let session = makeSession()
let sessionAt = Date.now()
function getSession(): string {
  if (Date.now() - sessionAt > SESSION_TTL) {
    session = makeSession()
    sessionAt = Date.now()
  }
  return session
}

function mergeChatTools(body: any) {
  const caller: any[] = Array.isArray(body.tools) ? body.tools : []
  const names = new Set(caller.map((t) => t?.function?.name).filter(Boolean))
  body.tools = [...caller, ...OC_TOOLS.filter((t) => !names.has(t.function.name))]
}

function mergeRespTools(body: any) {
  const caller: any[] = Array.isArray(body.tools) ? body.tools : []
  const names = new Set(caller.map((t) => t?.name ?? t?.function?.name).filter(Boolean))
  body.tools = [...caller, ...OC_TOOLS_RESP.filter((t) => !names.has(t.name))]
}

function sseToJson(text: string, model: string) {
  let id = ""
  let created = 0
  let finish: string | null = "stop"
  let content = ""
  let reasoning = ""
  let usage: any = null
  const calls = new Map<number, { id: string; name: string; args: string }>()
  for (const line of text.split("\n")) {
    const s = line.trim()
    if (!s.startsWith("data:")) continue
    const payload = s.slice(5).trim()
    if (payload === "[DONE]" || !payload) continue
    let chunk: any
    try {
      chunk = JSON.parse(payload)
    } catch {
      continue
    }
    chunk.id && (id = chunk.id)
    chunk.created && (created = chunk.created)
    chunk.usage && (usage = chunk.usage)
    const choice = chunk.choices?.[0]
    if (!choice) continue
    const d = choice.delta ?? {}
    if (typeof d.content === "string") content += d.content
    if (typeof d.reasoning_content === "string") reasoning += d.reasoning_content
    if (Array.isArray(d.tool_calls)) {
      for (const tc of d.tool_calls) {
        const idx = tc.index ?? 0
        const cur = calls.get(idx) ?? { id: "", name: "", args: "" }
        if (tc.id) cur.id = tc.id
        if (tc.function?.name) cur.name = tc.function.name
        if (tc.function?.arguments) cur.args += tc.function.arguments
        calls.set(idx, cur)
      }
    }
    if (choice.finish_reason) finish = choice.finish_reason
  }
  const message: any = { role: "assistant", content: content || null }
  if (reasoning) message.reasoning_content = reasoning
  if (calls.size) {
    message.tool_calls = [...calls.entries()].sort((a, b) => a[0] - b[0]).map(([, c]) => ({
      id: c.id,
      type: "function",
      function: { name: c.name, arguments: c.args },
    }))
  }
  return { id, object: "chat.completion", created: created || Math.floor(Date.now() / 1000), model, choices: [{ index: 0, message, finish_reason: finish }], usage }
}

Bun.serve({
  port: PORT,
  hostname: "127.0.0.1",
  idleTimeout: 120,
  async fetch(req) {
    const url = new URL(req.url)
    if (url.pathname === "/healthz") return new Response("ok")

    const target = UPSTREAM + url.pathname + url.search
    const sid = getSession()
    const auth = req.headers.get("authorization") ?? (API_KEY ? `Bearer ${API_KEY}` : null)
    const headers: Record<string, string> = {
      "user-agent": UA,
      "x-opencode-session": sid,
      "x-opencode-session-id": sid,
    }
    if (auth) headers.authorization = auth

    let body: string | undefined
    if (req.method === "POST" && url.pathname.endsWith("/responses")) {
      const json = await req.json()
      mergeRespTools(json)
      json.stream = true
      headers["content-type"] = "application/json"
      body = JSON.stringify(json)
      const up = await fetch(target, { method: req.method, headers, body })
      return new Response(up.body, {
        status: up.status,
        headers: { "content-type": up.headers.get("content-type") ?? "application/json" },
      })
    }

    if (req.method === "POST" && url.pathname.endsWith("/chat/completions")) {
      const json = await req.json()
      mergeChatTools(json)
      const wantStream = json.stream === true
      json.stream = true
      json.stream_options = { include_usage: true, ...(json.stream_options ?? {}) }
      headers["content-type"] = "application/json"
      body = JSON.stringify(json)

      const up = await fetch(target, { method: req.method, headers, body })
      const ctype = up.headers.get("content-type") ?? ""
      if (wantStream || up.status !== 200 || !ctype.includes("event-stream")) {
        return new Response(up.body, { status: up.status, headers: { "content-type": ctype || "application/json" } })
      }
      const json2 = sseToJson(await up.text(), json.model ?? "")
      return new Response(JSON.stringify(json2), { status: 200, headers: { "content-type": "application/json" } })
    }

    if (req.method === "POST" || req.method === "PUT" || req.method === "PATCH") {
      headers["content-type"] = req.headers.get("content-type") ?? "application/json"
      body = await req.text()
    }
    const up = await fetch(target, { method: req.method, headers, body })
    return new Response(up.body, {
      status: up.status,
      headers: { "content-type": up.headers.get("content-type") ?? "application/json" },
    })
  },
})

console.log(`zen-proxy listening on http://127.0.0.1:${PORT}  (key ${API_KEY.slice(0, 12)}...)`)
