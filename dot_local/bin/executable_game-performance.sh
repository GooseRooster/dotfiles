#!/usr/bin/env bash
#
# game-performance.sh — switch to a "performance" power profile via
# tuned-ppd while a Steam game runs, then restore whatever was active
# before. Fedora 41+ default backend, driven through tuned-adm.
# Also disables GNOME Night Light for the duration and restores it.
#
# Steam: Properties -> General -> Launch Options:
#   /home/cam/.local/bin/game-performance.sh %command%

set -uo pipefail

notify() {
  command -v notify-send &>/dev/null &&
    notify-send -a "game-performance" -i "$1" -t 4000 "$2" "$3" 2>/dev/null
}

if ! active_line="$(tuned-adm active 2>/dev/null)"; then
  echo "game-performance.sh: tuned-adm unavailable, launching unmodified" >&2
  exec "$@"
fi

prev_profile="${active_line#Current active profile: }"

# PPD's "performance" name maps to a real tuned profile via
# /etc/tuned/ppd.conf; fall back to tuned's documented default mapping.
perf_profile="$(awk -F= '/^[[:space:]]*performance[[:space:]]*=/{gsub(/[[:space:]]/,"",$2); print $2}' /etc/tuned/ppd.conf 2>/dev/null)"
perf_profile="${perf_profile:-throughput-performance}"

# --- Night Light state -------------------------------------------------
NIGHT_LIGHT_SCHEMA="org.gnome.settings-daemon.plugins.color"
NIGHT_LIGHT_KEY="night-light-enabled"
night_light_prev=""
if command -v gsettings &>/dev/null; then
  night_light_prev="$(gsettings get "$NIGHT_LIGHT_SCHEMA" "$NIGHT_LIGHT_KEY" 2>/dev/null)"
fi

restore_profile() {
  if tuned-adm profile $prev_profile 2>/dev/null; then
    notify "power-profile-balanced-symbolic" "Power profile restored" "$prev_profile"
  fi

  if [[ -n "$night_light_prev" ]]; then
    gsettings set "$NIGHT_LIGHT_SCHEMA" "$NIGHT_LIGHT_KEY" "$night_light_prev" 2>/dev/null
  fi
}
trap restore_profile EXIT INT TERM

if [[ "$prev_profile" != "$perf_profile" ]]; then
  if tuned-adm profile "$perf_profile" 2>/dev/null; then
    notify "power-profile-performance-symbolic" "Performance mode" "$perf_profile for this game"
  else
    echo "game-performance.sh: couldn't switch to '$perf_profile' profile" >&2
  fi
fi

if [[ "$night_light_prev" == "true" ]]; then
  gsettings set "$NIGHT_LIGHT_SCHEMA" "$NIGHT_LIGHT_KEY" false 2>/dev/null
fi

"$@"
exit_code=$?
exit "$exit_code"
