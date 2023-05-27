local wezterm = require 'wezterm'

-- Allow working with both the current release and the nightly
local config = {}
if wezterm.config_builder then
  config = wezterm.config_builder()
end

config.default_prog = { 'nu', '-l' }
config.font = wezterm.font { family = 'JetBrainsMono Nerd Font' }
config.font_size = 16.0
config.initial_cols = 120
config.initial_rows = 120
config.skip_close_confirmation_for_processes_named = {
  'bash',
  'sh',
  'zsh',
  'fish',
  'tmux',
  'nu',
}
config.scrollback_lines = 10000
config.keys = {
  {
    key = 'Enter',
    mods = 'ALT',
    action = wezterm.action.DisableDefaultAssignment,
  },
}
config.mouse_wheel_scrolls_tabs = false
config.quick_select_patterns = {
  "[0-9A-F]{64}",
  -- "┃ +([A-Za-z0-9\-_]+)? +┃",
  -- "┃\s+?([^┃\s]+)\s+?┃"
  -- '\|?\s*(?P<value>[^|\n]+)\s*\|?'
  -- '┃\s*(?P<value>[^┃\n]+)\s*┃'
  -- '/[\w\s\.]+(?=\s*\|)/g'
}
-- config.debug_key_events = true     
config.keys = {
  {
    key = 'w',
    mods = 'CMD',
    action = wezterm.action.CloseCurrentPane { confirm = true },
  },
}

return config
