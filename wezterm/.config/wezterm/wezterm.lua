local wezterm = require("wezterm")

-- Helper function to adjust opacity
local function adjust_opacity(window, delta)
	local overrides = window:get_config_overrides() or {}
	local current_opacity = overrides.window_background_opacity or 0.95
	local new_opacity = math.max(0.1, math.min(1.0, current_opacity + delta))
	overrides.window_background_opacity = new_opacity
	window:set_config_overrides(overrides)
end

local config = {
	-- Opacity control keybindings
	keys = {
		{
			key = "UpArrow",
			mods = "SHIFT|SUPER",
			action = wezterm.action_callback(function(window, _pane)
				adjust_opacity(window, 0.1)
			end),
		},
		{
			key = "DownArrow",
			mods = "SHIFT|SUPER",
			action = wezterm.action_callback(function(window, _pane)
				adjust_opacity(window, -0.1)
			end),
		},
		{
			key = "r",
			mods = "SHIFT|SUPER",
			action = wezterm.action_callback(function(window, _pane)
				local overrides = window:get_config_overrides() or {}
				overrides.window_background_opacity = 0.95
				window:set_config_overrides(overrides)
			end),
		},
	},

	-- Increase scrollback buffer
	scrollback_lines = 50000,

	-- Enable bracketed paste (helps with large pastes in tmux)
	enable_kitty_keyboard = false,

	-- Color scheme settings
	color_scheme = "Gruvbox Dark (Gogh)",
	colors = {
		background = "#282828",
		foreground = "#ebdbb2",
		cursor_bg = "#ebdbb2",
		cursor_fg = "#282828",
		cursor_border = "#ebdbb2",
		selection_bg = "#504945",
		selection_fg = "#ebdbb2",
		split = "#3c3836",
		tab_bar = {
			background = "#1d2021",
			active_tab = {
				bg_color = "#3c3836",
				fg_color = "#ebdbb2",
				intensity = "Normal",
				underline = "None",
				italic = false,
				strikethrough = false,
			},
			inactive_tab = {
				bg_color = "#282828",
				fg_color = "#a89984",
			},
			new_tab = {
				bg_color = "#282828",
				fg_color = "#a89984",
			},
		},
	},

	-- Font settings
	font = wezterm.font("Hasklug Nerd Font"),
	font_size = 16.0,
	harfbuzz_features = { "calt=1", "clig=1", "liga=1" },

	-- Window appearance
	window_background_opacity = 0.95,
	window_padding = {
		left = 5,
		right = 5,
		top = 5,
		bottom = 5,
	},

	-- Environment variables setup
	set_environment_variables = {
		SHELL = "/opt/homebrew/bin/bash",
		TERM = "xterm-256color",
	},

	-- Tab bar settings
	enable_tab_bar = true,
	hide_tab_bar_if_only_one_tab = true,
	tab_bar_at_bottom = true,
	use_fancy_tab_bar = false,
	tab_max_width = 25,

	-- Cursor configuration
	default_cursor_style = "SteadyBlock",
	cursor_blink_ease_in = "Linear",
	cursor_blink_ease_out = "Linear",
	cursor_blink_rate = 0,
	force_reverse_video_cursor = true,
}

return config
