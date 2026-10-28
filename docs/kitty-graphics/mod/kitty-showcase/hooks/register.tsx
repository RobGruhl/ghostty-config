import { atom, read, update } from 'claude-code'
import type { EngineInterface, Register } from 'claude-code'

import type { Activity, Mode } from '../types'

// A pane drawn with Kitty graphics (Ghostty, kitty). The orb's frames are
// rendered here once per mode and swapped with $.ui.blit, one small command
// each; the ring is redrawn when the context window's fill changes.

declare global {
  // The environment has it (as the API's own examples use); TypeScript 5.9's lib does not yet.
  interface Uint8Array {
    toBase64(): string
  }
}

const PANE = 'kitty-showcase'
const ORB = 64
const RING = 64
const FRAMES = 24
const TICK_MS = 66
const MISSES_BEFORE_SLEEP = 30 // ~2s of denied blits: the pane is closed

const activity = atom({ plugin: 'kitty-showcase', key: 'activity' } as const, {
  mode: 'idle',
  tool: null,
} as Activity)
const contextPercent = atom({ plugin: 'kitty-showcase', key: 'contextPercent' } as const, null as number | null)

// Rose Pine, the palette this terminal and Claude Code theme already use.
type Rgb = [number, number, number]
const PALETTE = {
  overlay: [0x26, 0x23, 0x3a],
  muted: [0x6e, 0x6a, 0x86],
  iris: [0xc4, 0xa7, 0xe7],
  gold: [0xf6, 0xc1, 0x77],
  rose: [0xeb, 0xbc, 0xba],
  foam: [0x9c, 0xcf, 0xd8],
  love: [0xeb, 0x6f, 0x92],
} satisfies Record<string, Rgb>

const LOOK: Record<Mode, { body: Rgb; glow: Rgb; stride: number; label: string }> = {
  idle: { body: PALETTE.muted, glow: PALETTE.muted, stride: 3, label: 'Idle' },
  thinking: { body: PALETTE.iris, glow: PALETTE.iris, stride: 1, label: 'Thinking…' },
  tool: { body: PALETTE.gold, glow: PALETTE.rose, stride: 1, label: 'Running' },
}

const TAU = Math.PI * 2
const mix = (a: Rgb, b: Rgb, t: number): Rgb => [
  a[0] + (b[0] - a[0]) * t,
  a[1] + (b[1] - a[1]) * t,
  a[2] + (b[2] - a[2]) * t,
]
const smoothstep = (e0: number, e1: number, x: number) => {
  const t = Math.max(0, Math.min(1, (x - e0) / (e1 - e0)))
  return t * t * (3 - 2 * t)
}

function paint(size: number, shade: (u: number, v: number) => [number, number, number, number]): string {
  const px = new Uint8Array(size * size * 4)
  for (let y = 0; y < size; y++) {
    for (let x = 0; x < size; x++) {
      const [r, g, b, a] = shade(((x + 0.5) / size) * 2 - 1, ((y + 0.5) / size) * 2 - 1)
      const i = (y * size + x) * 4
      px[i] = r
      px[i + 1] = g
      px[i + 2] = b
      px[i + 3] = Math.max(0, Math.min(1, a)) * 255
    }
  }
  return px.toBase64()
}

/** A lit sphere with a light circling it and a breathing halo (same as orb.py). */
function orbFrame(t: number, body: Rgb, glow: Rgb): string {
  const radius = 0.52
  const theta = t * TAU
  const raw = [Math.cos(theta) * 0.75, Math.sin(theta) * 0.45 - 0.25, 0.6]
  const len = Math.hypot(raw[0]!, raw[1]!, raw[2]!)
  const [lx, ly, lz] = raw.map(c => c / len) as Rgb
  const breathe = 0.5 + 0.5 * Math.sin(theta * 2)

  return paint(ORB, (u, v) => {
    const d = Math.hypot(u, v)
    const halo = Math.exp(-Math.max(0, d - radius) / (0.1 + 0.05 * breathe)) * (0.35 + 0.35 * breathe)
    if (d >= radius) {
      return [...glow, halo * (1 - smoothstep(0.9, 1, d))]
    }
    const nz = Math.sqrt(Math.max(0, 1 - (d / radius) ** 2))
    const diffuse = Math.max(0, (u / radius) * lx + (v / radius) * ly + nz * lz)
    const spec = Math.max(0, 2 * diffuse * nz - lz) ** 24
    const lit = mix(mix(PALETTE.overlay, body, 0.25 + 0.75 * diffuse), PALETTE.gold, spec * 0.8)
    const edge = smoothstep(radius, radius - 0.03, d)
    return [...lit, edge + (1 - edge) * halo]
  })
}

/** A ring gauge, filled clockwise from 12 o'clock, foam → gold → love (same as gauge.py). */
function ringImage(pct: number): string {
  const fillTo = (pct / 100) * TAU
  const color = pct <= 60 ? mix(PALETTE.foam, PALETTE.gold, pct / 60) : mix(PALETTE.gold, PALETTE.love, (pct - 60) / 40)
  return paint(RING, (u, v) => {
    const d = Math.hypot(u, v)
    const band = smoothstep(0.62, 0.66, d) * (1 - smoothstep(0.9, 0.94, d))
    const ang = (Math.atan2(u, -v) + TAU) % TAU
    return [...(pct > 0 && ang <= fillTo ? color : PALETTE.overlay), band]
  })
}

// Module state: a reload starts it over, the atoms below outlive it.
const frames = new Map<Mode, string[]>()
function framesFor(mode: Mode) {
  let list = frames.get(mode)
  if (!list) {
    const look = LOOK[mode]
    list = Array.from({ length: FRAMES }, (_, i) => orbFrame(i / FRAMES, look.body, look.glow))
    frames.set(mode, list)
  }
  return list
}

let mode: Mode = 'idle'
let tick = 0
let misses = 0
let timer: { cancel: () => void } | null = null
let running = 0 // tool calls in flight

function frameNow() {
  const list = framesFor(mode)
  return list[Math.floor(tick / LOOK[mode].stride) % list.length]!
}

function animate($: EngineInterface) {
  misses = 0
  if (timer) {
    return
  }
  timer = $.clock.every(TICK_MS, () => {
    tick += 1
    if (LOOK[mode].stride > 1 && tick % LOOK[mode].stride !== 0) {
      return
    }
    void $.ui.blit({ requestId: PANE, key: 'orb', source: { rgba: frameNow(), width: ORB, height: ORB } }).then(r => {
      misses = r.deny ? misses + 1 : 0
      if (misses >= MISSES_BEFORE_SLEEP) {
        timer?.cancel()
        timer = null
      }
    })
  })
}

async function setActivity($: EngineInterface, next: Activity) {
  mode = next.mode
  await update($, activity, () => next)
}

async function refreshContext($: EngineInterface) {
  const { context } = await $.session.usage()
  const pct = context.percent === undefined ? null : Math.round(context.percent)
  await update($, contextPercent, () => pct)
}

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    await $.command.register({
      name: 'kitty-showcase',
      description: 'Open a pane drawn with Kitty graphics: live activity orb and context ring',
    })
    animate($) // a pane left open across a reload picks up again; otherwise it sleeps after ~2s
    return next(e)
  })

  on('command.run', { command: 'kitty-showcase' }, async $ => {
    const opened = await $.ui.open({ id: PANE, title: 'Kitty showcase' })
    await refreshContext($)
    animate($)
    return { text: opened.isPlaced ? 'Kitty showcase pane opened.' : 'Kitty showcase pane is waiting for room.' }
  })

  // The orb is decoration: a failed state write never holds up a prompt or a tool.
  on('prompt.submit', async ($, e, next) => {
    await setActivity($, { mode: 'thinking', tool: null }).catch(() => undefined)
    return next(e)
  })

  on('tool.call', async ($, e, next) => {
    running += 1
    await setActivity($, { mode: 'tool', tool: e.tool }).catch(() => undefined)
    try {
      return await next(e)
    } finally {
      running -= 1
      if (running === 0) {
        await setActivity($, { mode: 'thinking', tool: null }).catch(() => undefined)
      }
      await refreshContext($).catch(() => undefined)
    }
  })

  on('turn.complete', async ($, e, next) => {
    const done = await next(e)
    running = 0
    await setActivity($, { mode: 'idle', tool: null })
    await refreshContext($)
    return done
  })

  on('ui.render', { component: 'Pane', requestId: PANE }, async ($, e) => {
    const now = await read($, activity)
    const pct = await read($, contextPercent)
    mode = now.mode
    const caption = now.mode === 'tool' && now.tool ? `${LOOK.tool.label} ${now.tool}` : LOOK[now.mode].label

    if (e.surface !== 'terminal') {
      const { Box, Text } = $.ui.resolve(e)
      return (
        <Box flexDirection="column">
          <Text bold>{caption}</Text>
          <Text dimColor>context {pct === null ? '–' : `${pct}%`} · images need a terminal with Kitty graphics</Text>
        </Box>
      )
    }

    const { Box, Text, Image } = $.ui.resolve(e)
    return (
      <Box flexDirection="column" paddingX={1}>
        <Box flexDirection="row">
          <Image key="orb" source={{ rgba: frameNow(), width: ORB, height: ORB }} columns={10} rows={5} alt={caption} />
          <Box flexDirection="column" marginLeft={2} marginTop={1}>
            <Text bold>{caption}</Text>
            <Text dimColor>frames swapped by $.ui.blit, ~15 fps</Text>
          </Box>
        </Box>
        <Box flexDirection="row" marginTop={1}>
          <Box marginLeft={1}>
            <Image
              source={{ rgba: ringImage(pct ?? 0), width: RING, height: RING }}
              columns={8}
              rows={4}
              alt={`context ${pct ?? '–'}%`}
            />
          </Box>
          <Box flexDirection="column" marginLeft={3} marginTop={1}>
            <Text bold>context {pct === null ? '–' : `${pct}%`}</Text>
            <Text dimColor>redrawn when the window's fill changes</Text>
          </Box>
        </Box>
      </Box>
    )
  })
}
