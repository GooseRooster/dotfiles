------------------
---- MONITORS ----
------------------

-- NOTE: output = "" is a catch-all that works fine for a single-monitor setup.
-- If you ever want to target it explicitly, run: hyprctl monitors
-- and replace "" with the connector name (e.g. "DP-1", "HDMI-A-1").
--
-- HDR notes:
--   - cm = "hdr" enables always-on HDR desktop mode.
--   - sdrbrightness controls how bright SDR content renders in HDR mode (1.0 = reference).
--     Tune this value to taste for your paperwhite target (~0.8-1.0 is typical for 203 nits).
--   - vrr = 1 enables VRR always; set to 2 for fullscreen-only.
--

hl.monitor({
	output = "",
	mode = "3440x1440@165",
	position = "0x0",
	scale = 1,
	bitdepth = 10,
	cm = "hdr",
	supports_hdr = 1,
	vrr = 2,
	sdrbrightness = 1.0, -- adjust to taste; lower = dimmer SDR in HDR mode
	sdrsaturation = 1.0,
	min_luminance = 0,
	max_luminance = 1000,
})
----------------
---- RENDER ----
----------------

-- cm_auto_hdr: auto-switch the display to HDR when fullscreen HDR content is active.
-- 1 = always HDR, 2 = fullscreen HDR content only (recommended - keeps desktop SDR).
-- This is what makes mpv HDR work correctly without leaving the full desktop in HDR mode.
-- For mpv > v0.40.0 also add to mpv.conf: target-colorspace-hint-mode=source
hl.config({
	render = {
		cm_auto_hdr = 1,
	},
})
