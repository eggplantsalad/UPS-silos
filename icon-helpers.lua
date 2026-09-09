-- Shared between recipe.lua (items) and data.lua (entities) so both sides
-- of the same size/orientation get identical icons - see whichever of
-- those two files required this for context on why it matters.

-- Same warm tint as the entity graphics, applied to the base chest icon
-- layer only - the digit overlay stays plain white/grey so it still reads
-- clearly against the tinted background.
local ICON_TINT = {r = 1, g = 0.65, b = 0.3, a = 1}

-- Base tinted chest (a square-fitted crop of the actual wide/high entity
-- art, so horizontal and vertical read as visually different shapes, not
-- just different subgroups) + one or two digit-signal icons (vanilla ships
-- signal_0..signal_9 for exactly this kind of overlay) showing the size.
-- Digits sit top-right - bottom-right is where Factorio draws its own
-- stack-count/quantity overlays, and the two were colliding there.
local function build_size_icons(base_icon, size)
  local icons = {
    {
      icon = base_icon,
      icon_size = 64,
      tint = ICON_TINT
    }
  }

  local digits = tostring(size)
  if #digits == 1 then
    table.insert(icons, {
      icon = "__base__/graphics/icons/signal/signal_" .. digits .. ".png",
      icon_size = 64,
      scale = 0.32,
      shift = {14, -14},
      -- Signal digits render plain white by default, same as Factorio's own
      -- stack-count text - tinting them ties them visually to the chest
      -- instead of looking like a second, unrelated UI overlay.
      tint = ICON_TINT
    })
  else
    table.insert(icons, {
      icon = "__base__/graphics/icons/signal/signal_" .. digits:sub(1, 1) .. ".png",
      icon_size = 64,
      scale = 0.32,
      shift = {8, -14},
      tint = ICON_TINT
    })
    table.insert(icons, {
      icon = "__base__/graphics/icons/signal/signal_" .. digits:sub(2, 2) .. ".png",
      icon_size = 64,
      scale = 0.32,
      shift = {20, -14},
      tint = ICON_TINT
    })
  end

  return icons
end

return {
  ICON_TINT = ICON_TINT,
  build_size_icons = build_size_icons
}
