import { expect, test } from 'claude-code/testing'

const PANE = {
  plugin: 'kitty-showcase',
  component: 'Pane',
  requestId: 'kitty-showcase',
  props: {
    title: 'Kitty showcase',
    isFocused: false,
    bodyColumns: 60,
    placement: 'dock',
    scroll: { offset: 0, bodyRows: 14 },
    view: {},
  },
} as const

function engine(on: Parameters<Parameters<typeof test>[1]>[1]) {
  on('command.register', () => ({ value: { command: 'kitty-showcase' } }))
  on('ui.open', () => ({ value: { isPlaced: true } }))
  on('session.start', (_, e) => ({ cwd: e.cwd }))
  on('session.usage', () => ({ value: { startedAt: 0, context: { window: 200000, percent: 37.4 }, rateLimits: [] } }))
  on('clock.every', () => ({ value: { cancel: () => undefined } }))
  on('tool.call', () => ({ result: {} }))
}

test('the terminal pane draws the orb and the ring as Images, captioned', async ($, on) => {
  engine(on)
  await $.session.start({ cwd: '/', surface: 'terminal', isInteractive: true })
  await $.command.run({ command: 'kitty-showcase', args: '' })

  const ui = await $.ui.mount({ ...PANE, surface: 'terminal' })
  expect(await ui.find({ type: 'Image', key: 'orb' })).toBeTruthy()
  expect((await ui.find({ type: 'Text', text: /^context/ }))?.text).toBe('context 37%')
  expect((await ui.find({ type: 'Text', text: /Idle/ }))?.text).toBe('Idle')
  await ui.unmount()
})

test('other surfaces get the text fallback', async ($, on) => {
  engine(on)
  await $.session.start({ cwd: '/', surface: 'desktop', isInteractive: true })

  const ui = await $.ui.mount({ ...PANE, surface: 'desktop' })
  expect(await ui.find({ type: 'Image' })).toBeFalsy()
  expect((await ui.find({ type: 'Text', text: /Idle/ }))?.text).toBe('Idle')
  await ui.unmount()
})
