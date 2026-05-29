-- ~/.config/hypr/hyprland.lua
-- Hyprland config - drop-in starting point, tweak from here.
-- Refer to the wiki: https://wiki.hypr.land/Configuring/Start/

-------------------
---- AUTOSTART ----
-------------------

hl.on("hyprland.start", function()
	-- Noctalia shell (bar, notifications, control center, launcher).
	-- If installed manually into ~/.config/quickshell/, use: qs -c noctalia-shell
	--hl.exec_cmd("uwsm app -- qs -c noctalia-shell")
	hl.exec_cmd("uwsm app -- noctalia")
	hl.exec_cmd("uwsm app -- udiskie")
end)

-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------
-- NOTE: When launching via UWSM (recommended), put env vars in:
--   ~/.config/uwsm/env          (all graphical sessions)
--   ~/.config/uwsm/env-hyprland (Hyprland-exclusive: HYPR*, AQ_* vars)
-- Format: export KEY=VALUE
-- These cursor vars are compositor-specific and fine to keep here.

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

--------------------------------
----- MODULES ------------------
--------------------------------
---add more modules below
require("modules.display")
require("modules.input")
require("modules.windows")

-- For Noctalia Color templates
require("noctalia")
