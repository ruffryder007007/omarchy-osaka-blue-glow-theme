-- Osaka Blue Glow: Azure Glow borders with a restrained blue outer halo.
local active_border_color = "rgb(00aaff)"
local inactive_border_color = "rgba(595959aa)"

hl.config({
  general = {
    border_size = 2,
    col = {
      active_border = active_border_color,
      inactive_border = inactive_border_color,
    },
  },
  group = {
    col = {
      border_active = active_border_color,
      border_inactive = inactive_border_color,
    },
  },
  decoration = {
    shadow = {
      enabled = true,
      range = 12,
      render_power = 3,
      color = "rgba(00aaff40)",
      color_inactive = "rgba(00aaff1a)",
    },
  },
})
