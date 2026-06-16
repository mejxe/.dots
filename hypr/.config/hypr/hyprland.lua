local mainMod = "SUPER"

hl.monitor({
	output = "DP-1",
	mode = "1920x1080",
	position = "0x0",
	scale = 1,
	transform = 1,
})

hl.monitor({
	output = "HDMI-A-1",
	mode = "2560x1440@144",
	position = "1080x0",
	scale = 1,
	bitdepth = 10,
	cm = "dcip3",
	icc = "/home/mejxe/.config/hypr/aoc_Q27G3XMN.icm",
})
--hl.monitor({ output = "eDP-1", mode = "preferred", scale = 1 })

hl.env("QT_QPA_PLATFORMTHEME", "qt5ct")
hl.env("HYPRSHOT_DIR", "~/screenshots")
hl.env("HYPRCURSOR_THEME", "phinger-cursors-dark")
hl.env("HYPRCURSOR_SIZE", "24")

hl.on("hyprland.start", function()
	hl.exec_cmd("hyprpm reload -n")
	hl.exec_cmd("hypridle")
	hl.exec_cmd("hyprpaper")
	hl.exec_cmd("waybar")
	hl.exec_cmd("kanshi")
	hl.exec_cmd("fcitx5")
	hl.exec_cmd("easyeffects --gapplication-service")
	hl.exec_cmd("gsettings set org.gnome.desktop.interface cursor-theme 'Capitaine Cursors'")
	hl.exec_cmd("/usr/libexec/polkit-kde-authentication-agent-1")
	hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
	hl.exec_cmd("wl-clip-persist --clipboard regular")
end)

hl.config({
	render = {
		cm_auto_hdr = 1,
		cm_enabled = 1,
		cm_sdr_eotf = 2,
	},
	quirks = {
		prefer_hdr = 1,
	},
	input = {
		kb_layout = "pl",
		follow_mouse = 1,
		touchpad = {
			natural_scroll = false,
		},
		sensitivity = 0.7,
		kb_options = "caps:swapescape",
	},
	general = {
		border_size = 3,
		["col.active_border"] = "rgb(fe8019)",
		["col.inactive_border"] = {
			colors = { "rgb(24273A)", "rgb(24273A)", "rgb(24273A)", "rgb(27273A)" },
			angle = 45,
		},
		gaps_in = 2,
		gaps_out = 5,
	},
	decoration = {
		rounding = 10,
		active_opacity = 1.0,
		inactive_opacity = 0.9,
		shadow = {
			enabled = true,
			range = 4,
			render_power = 3,
			color = "rgba(1e2122ff)",
		},
		blur = {
			enabled = true,
			size = 3,
			passes = 1,
			vibrancy = 0.1696,
		},
	},
	dwindle = {
		preserve_split = true,
	},
	master = {
		new_status = "master",
	},
})
hl.curve("wind", { type = "bezier", points = { { 0.05, 0.85 }, { 0.03, 0.97 } } })

hl.animation({ leaf = "global", enabled = true, bezier = "wind", speed = 2.5 })

hl.curve("winIn", { type = "bezier", points = { { 0.07, 0.88 }, { 0.04, 0.99 } } })
hl.curve("winOut", { type = "bezier", points = { { 0.20, -0.15 }, { 0, 1 } } })
hl.curve("liner", { type = "bezier", points = { { 1, 1 }, { 1, 1 } } })
hl.curve("md3_standard", { type = "bezier", points = { { 0.12, 0 }, { 0, 1 } } })
hl.curve("md3_decel", { type = "bezier", points = { { 0.05, 0.80 }, { 0.10, 0.97 } } })
hl.curve("md3_accel", { type = "bezier", points = { { 0.20, 0 }, { 0.80, 0.08 } } })
hl.curve("overshot", { type = "bezier", points = { { 0.05, 0.85 }, { 0.07, 1.04 } } })
hl.curve("crazyshot", { type = "bezier", points = { { 0.1, 1.22 }, { 0.68, 0.98 } } })
hl.curve("hyprnostretch", { type = "bezier", points = { { 0.05, 0.82 }, { 0.03, 0.94 } } })
hl.curve("menu_decel", { type = "bezier", points = { { 0.05, 0.82 }, { 0, 1 } } })
hl.curve("menu_accel", { type = "bezier", points = { { 0.20, 0 }, { 0.82, 0.10 } } })
hl.curve("easeOutCirc", { type = "bezier", points = { { 0, 0.48 }, { 0.38, 1 } } })
hl.curve("easeOutExpo", { type = "bezier", points = { { 0.10, 0.94 }, { 0.23, 0.98 } } })
hl.curve("softAcDecel", { type = "bezier", points = { { 0.20, 0.20 }, { 0.15, 1 } } })
hl.curve("md2", { type = "bezier", points = { { 0.30, 0 }, { 0.15, 1 } } })
hl.curve("OutBack", { type = "bezier", points = { { 0.28, 1.40 }, { 0.58, 1 } } })
hl.curve("easeInOutCirc", { type = "bezier", points = { { 0.78, 0 }, { 0.15, 1 } } })

hl.animation({ leaf = "border", enabled = true, speed = 1.6, bezier = "liner" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 82, bezier = "liner", style = "loop" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 3.2, bezier = "winIn", style = "slide" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 2.8, bezier = "easeOutCirc" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 3.0, bezier = "wind", style = "slide" })
hl.animation({ leaf = "fade", enabled = true, speed = 1.8, bezier = "md3_decel" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 1.8, bezier = "menu_decel", style = "slide" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 1.5, bezier = "menu_accel" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 1.6, bezier = "menu_decel" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.8, bezier = "menu_accel" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 4.0, bezier = "menu_decel", style = "slide" })
hl.animation({
	leaf = "specialWorkspace",
	enabled = true,
	speed = 2.3,
	bezier = "md3_decel",
	style = "slidefadevert 15%",
})
-- RULES --

-- special workspace
hl.workspace_rule({ workspace = "special:scratch", on_created_empty = "[float; center] kitty" })
hl.window_rule({ match = { workspace = "scratch" }, float = true })
hl.window_rule({ match = { workspace = "sctrach" }, center = true })

-- nautilus
hl.window_rule({ match = { class = "^(org.gnome.Nautilus)$" }, float = true })
hl.window_rule({ match = { class = "^(org.gnome.Nautilus)$" }, size = "1400 1000" })
hl.window_rule({ match = { class = "^(org.gnome.Nautilus)$" }, center = true })
-- disable maximize
hl.window_rule({ match = { class = ".*" }, suppress_event = "maximize" })
-- bind workspaces
hl.workspace_rule({ workspace = "2", monitor = "HDMI-A-1", default = true })
hl.workspace_rule({ workspace = "3", monitor = "DP-1", default = true })
----------------

-- BINDS ---
hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd("kitty"))
hl.bind(mainMod .. " + F7", hl.dsp.exec_cmd("hyprctl switchxkblayout at-translated-set-2-keyboard next"))
hl.bind(mainMod .. " + D", hl.dsp.window.close())
hl.bind(mainMod .. " + e", hl.dsp.exec_cmd("emacsclient -c"))
hl.bind(mainMod .. " + SHIFT + f", hl.dsp.exec_cmd("kitty -e yazi"))
hl.bind(mainMod .. " + f", hl.dsp.exec_cmd("nautilus"))
hl.bind(mainMod .. " + SHIFT + P", hl.dsp.exit())
hl.bind(mainMod .. " + SHIFT + SPACE", hl.dsp.window.float())
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.exec_cmd("playerctl next"), { repeating = true })
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd("playerctl play-pause"))
hl.bind(mainMod .. " + SHIFT + left", hl.dsp.exec_cmd("playerctl previous"), { repeating = true })
hl.bind("PRINT", hl.dsp.exec_cmd("grim - | wl-copy --type image/png"), { repeating = true })
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd("~/.config/rofi/launchers/type-1/launcher.sh rofi"))
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("pactl set-sink-mute @DEFAULT_SINK@ toggle"))
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("pactl -- set-sink-volume @DEFAULT_SINK@ +5%"), { repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("pactl -- set-sink-volume @DEFAULT_SINK@ -5%"), { repeating = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set +5%"), { repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"), { repeating = true })
hl.bind(mainMod .. " + l", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + h", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + k", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + j", hl.dsp.focus({ direction = "down" }))

hl.bind(mainMod .. " + 1", hl.dsp.focus({ workspace = "1", on_current_monitor = true }))
hl.bind(mainMod .. " + 2", hl.dsp.focus({ workspace = "2", on_current_monitor = true }))
hl.bind(mainMod .. " + 3", hl.dsp.focus({ workspace = "3", on_current_monitor = true }))
hl.bind(mainMod .. " + 4", hl.dsp.focus({ workspace = "4", on_current_monitor = true }))
hl.bind(mainMod .. " + 5", hl.dsp.focus({ workspace = "5", on_current_monitor = true }))
hl.bind(mainMod .. " + 6", hl.dsp.focus({ workspace = "6", on_current_monitor = true }))
hl.bind(mainMod .. " + 7", hl.dsp.exec_cmd("~/.config/waybar/scripts/rofi-sound-menu.sh rofi"))
hl.bind(mainMod .. " + 8", hl.dsp.exec_cmd("~/.config/waybar/scripts/rofi-bluetooth.sh rofi"))
hl.bind(mainMod .. " + 9", hl.dsp.exec_cmd("~/.config/waybar/scripts/rofi-wifi-menu.sh rofi"))

hl.bind(mainMod .. " + s", hl.dsp.workspace.toggle_special("scratch"))

hl.bind(mainMod .. " + SHIFT + 1", hl.dsp.window.move({ workspace = 1, follow = false }))
hl.bind(mainMod .. " + SHIFT + 2", hl.dsp.window.move({ workspace = 2, follow = false }))
hl.bind(mainMod .. " + SHIFT + 3", hl.dsp.window.move({ workspace = 3, follow = false }))
hl.bind(mainMod .. " + SHIFT + 4", hl.dsp.window.move({ workspace = 4, follow = false }))
hl.bind(mainMod .. " + SHIFT + 5", hl.dsp.window.move({ workspace = 5, follow = false }))
hl.bind(mainMod .. " + SHIFT + 6", hl.dsp.window.move({ workspace = 6, follow = false }))
hl.bind(mainMod .. " + SHIFT + 7", hl.dsp.window.move({ workspace = 7, follow = false }))

hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"))

hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

hl.bind(mainMod .. " + SHIFT + s", hl.dsp.exec_cmd("hyprshot -m region --clipboard-only"))
hl.bind("PRINT", hl.dsp.exec_cmd("hyprshot -m output --clipboard-only"))
hl.bind("SHIFT + PRINT", hl.dsp.exec_cmd("hyprshot -m region"))
--------------
