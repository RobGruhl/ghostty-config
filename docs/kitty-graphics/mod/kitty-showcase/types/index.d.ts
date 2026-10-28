export type Mode = 'idle' | 'thinking' | 'tool'

export type Activity = { mode: Mode; tool: string | null }

declare module 'claude-code' {
  interface PluginState {
    'kitty-showcase': { activity: Activity; contextPercent: number | null }
  }
}
