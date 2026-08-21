-- ============================================================================
-- THE CUSTOM U.P.S. LOGISTICS CRAFTING TAB SETUP
-- ============================================================================
data:extend({
  {
    type = "item-group",
    name = "ups-silo-group",
    order = "f-b",
    icon = "__UPS-silos__/graphics/silo-icon.png",
    icon_size = 256
  },
  {
    type = "item-subgroup",
    name = "ups-silo-chassis",
    group = "ups-silo-group",
    order = "a"
  },
  {
    -- Separate subgroup so vertical chassis items lay out on their own row
    -- below the horizontal ones, same as how belts / underground belts /
    -- splitters split into their own rows within one item group.
    type = "item-subgroup",
    name = "ups-silo-chassis-vertical",
    group = "ups-silo-group",
    order = "b"
  }
})

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

-- ============================================================================
-- INITIALIZE THE 27 AUTOMATED ITEMS & RECIPES
-- ============================================================================
for i = 1, 27 do
  local chest_cost = i
  local inserter_cost = (i - 1) * 2
  local green_circuit_cost = i * i

  local ingredient_table = {
    {type = "item", name = "steel-chest", amount = chest_cost},
    {type = "item", name = "electronic-circuit", amount = green_circuit_cost}
  }
  if inserter_cost > 0 then
    table.insert(ingredient_table, {type = "item", name = "fast-inserter", amount = inserter_cost})
  end

  data:extend({
    -- Horizontal and vertical are just two independent, honestly-different
    -- items - no rotation illusion, no shared identity. Each has its own
    -- real recipe and place_results directly into its own entity, so
    -- pipette, mining, blueprints/copies, and bot ghost-filling all work
    -- natively with zero extra scripting.
    {
      type = "item",
      name = "ups-silo-item-" .. i,
      -- Size 1 places the plain steel-chest-styled shared entity (see
      -- data.lua), not a wide-chest slice - its icon should match that.
      icons = build_size_icons((i == 1) and "__base__/graphics/icons/steel-chest.png"
        or "__UPS-silos__/graphics/entity/wide-chest-icon.png", i),
      icon_size = 64,
      localised_name = (i == 1) and {"ups-silo.name-1x1"} or {"ups-silo.name-horizontal", tostring(i)},
      -- Size 1 gets its own description key with a subtle fish-sink hint -
      -- see locale.cfg. The other 26 share the plain stack-info template.
      localised_description = {(i == 1) and "ups-silo.stack-info-1x1" or "ups-silo.stack-info", tostring(4 * i)},
      group = "ups-silo-group",
      subgroup = "ups-silo-chassis",
      order = "b[" .. string.format("%02d", i) .. "]",
      stack_size = 10,
      place_result = "ups-silo-" .. i .. "x1"
    },

    {
      type = "recipe",
      name = "ups-silo-recipe-" .. i,
      localised_name = (i == 1) and {"ups-silo.name-1x1"} or {"ups-silo.name-horizontal", tostring(i)},
      enabled = false,
      energy_required = 0.5,
      ingredients = ingredient_table,
      results = {{type = "item", name = "ups-silo-item-" .. i, amount = 1}}
    }
  })

  -- At size 1, both orientations place_result into the same shared entity
  -- (ups-silo-1x1) - a second item/recipe would just be a pointless exact
  -- duplicate of the one above, so skip it.
  if i > 1 then
    data:extend({
      {
        type = "item",
        name = "ups-silo-item-v-" .. i,
        icons = build_size_icons("__UPS-silos__/graphics/entity/high-chest-icon.png", i),
        icon_size = 64,
        localised_name = {"ups-silo.name-vertical", tostring(i)},
        localised_description = {"ups-silo.stack-info", tostring(4 * i)},
        group = "ups-silo-group",
        subgroup = "ups-silo-chassis-vertical",
        order = "b[" .. string.format("%02d", i) .. "]",
        stack_size = 10,
        place_result = "ups-silo-1x" .. i
      },
      {
        type = "recipe",
        name = "ups-silo-recipe-v-" .. i,
        localised_name = {"ups-silo.name-vertical", tostring(i)},
        enabled = false,
        energy_required = 0.5,
        ingredients = ingredient_table,
        results = {{type = "item", name = "ups-silo-item-v-" .. i, amount = 1}}
      }
    })
  end
end
