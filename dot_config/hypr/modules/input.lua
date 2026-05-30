---------------------
---- MY PROGRAMS ----
---------------------

local terminal = "kitty"
local fileManager = "kitty -e yazi"
local menu = "fuzzel"
local browser = "zen-browser"
local steam = "steam"
local music = "flatpak run io.github.lullabyX.sone"
---------------
---- INPUT ----
---------------

hl.config({
	input = {
		kb_layout = "us",
		kb_variant = "",
		kb_model = "",
		kb_options = "",
		kb_rules = "",

		follow_mouse = 1,
		sensitivity = 0, -- -1.0 to 1.0, 0 = no modification

		touchpad = {
			natural_scroll = false,
		},
	},
})

hl.gesture({
	fingers = 3,
	direction = "horizontal",
	action = "workspace",
})

---------------------
---- KEYBINDINGS ----
---------------------

local mainMod = "SUPER"

-- APP LAUNCHERS -----
--
hl.bind(mainMod .. " + Home", hl.dsp.exec_cmd(terminal)) -- Terminal
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager)) -- File manager (yazi)
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(browser))
hl.bind(mainMod .. " + I", hl.dsp.exec_cmd(terminal .. " -e yazi ~/.config")) -- Config folder (replaces KDE settings)
--hl.bind(mainMod .. " + Space", hl.dsp.exec_cmd(menu)) -- App launchers
hl.bind(mainMod .. " + G", hl.dsp.exec_cmd(steam)) -- steam
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd(music)) -- sone
-- WINDOW MANAGEMENT -----
--
hl.bind(mainMod .. " + Q", function()
	local w = hl.get_active_window()
	if w ~= nil and w.class == "gamescope" then
		return -- swallow the bind, do nothing
	end
	hl.dispatch(hl.dsp.window.close())
end)
hl.bind(mainMod .. " + F", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))

-- Focus with arrow keys
hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "down" }))

-- Switch / move to workspaces
for i = 1, 10 do
	local key = i % 10 -- 10 maps to key 0
	hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
	hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Scratchpad
hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll workspaces with mouse wheel
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Scroll workspaces with arrow keys
hl.bind(mainMod .. " + CTRL + right", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + CTRL + left", hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mouse
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Resize: mainMod + Shift + arrows
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.resize({ x = 20, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + left", hl.dsp.window.resize({ x = -20, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + up", hl.dsp.window.resize({ x = 0, y = -20, relative = true }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + down", hl.dsp.window.resize({ x = 0, y = 20, relative = true }), { repeating = true })

-- Move: mainMod + Alt + arrows
hl.bind(mainMod .. " + ALT + right", hl.dsp.window.move({ direction = "right" }), { repeating = true })
hl.bind(mainMod .. " + ALT + left", hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + ALT + up", hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + ALT + down", hl.dsp.window.move({ direction = "down" }))

---- SCREENSHOTS ----

-- Region select → clipboard + save
hl.bind("Print", hl.dsp.exec_cmd("grimblast --notify copysave area ~/Pictures/Screenshots/$(date +%Y%m%d_%H%M%S).png"))

-- Full screen (current monitor)
hl.bind(
	mainMod .. " + Print",
	hl.dsp.exec_cmd("grimblast --notify copysave screen ~/Pictures/Screenshots/$(date +%Y%m%d_%H%M%S).png")
)

-- Active window
hl.bind(
	mainMod .. " + SHIFT + Print",
	hl.dsp.exec_cmd("grimblast --notify copysave active ~/Pictures/Screenshots/$(date +%Y%m%d_%H%M%S).png")
)

---- SCREEN RECORDING ----

-- Start recording current monitor (10-bit HEVC for HDR)
hl.bind(
	mainMod .. " + F9",
	hl.dsp.exec_cmd(
		"bash -c 'wl-screenrec --codec hevc --encode-pixfmt p010 --audio -f ~/Videos/Recordings/$(date +%Y%m%d_%H%M%S).mp4 &'"
	)
)

-- Stop recording
hl.bind(mainMod .. " + F10", hl.dsp.exec_cmd("pkill -INT wl-screenrec"))

---- NOCTALIA IPC ----

local ipc = "noctalia msg"

-- Control center (panel/quick settings)
hl.bind(mainMod .. " + comma", hl.dsp.exec_cmd(ipc .. " panel-toggle control-center"))

-- Session menu (logout / reboot / shutdown)
hl.bind(mainMod .. " + Delete", hl.dsp.exec_cmd(ipc .. " panel-toggle session"))

-- Lock screen
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd(ipc .. " screen-lock"))

-- Lock and suspend (no v5 IPC equivalent yet — manual chain)
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.exec_cmd(ipc .. " screen-lock && systemctl suspend"))

-- Calendar
hl.bind(mainMod .. " + F1", hl.dsp.exec_cmd(ipc .. " panel-toggle control-center calendar"))

-- Settings
hl.bind(mainMod .. " + End", hl.dsp.exec_cmd(ipc .. " settings-toggle"))

-- System monitor
hl.bind(mainMod .. " + F2", hl.dsp.exec_cmd(ipc .. " panel-toggle control-center system"))

-- clipoboard
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd(ipc .. " panel-toggle clipboard"))

--launcher
hl.bind(mainMod .. " + Space", hl.dsp.exec_cmd(ipc .. " panel-toggle launcher"))

-- Media / volume keys (via Noctalia IPC)
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(ipc .. " volume-up"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd(ipc .. " volume-down"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd(ipc .. " volume-mute"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd(ipc .. " mic-mute"), { locked = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd(ipc .. " brightness-up"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(ipc .. " brightness-down"), { locked = true, repeating = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd(ipc .. " media next"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd(ipc .. " media toggle"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd(ipc .. " media previous"), { locked = true })
