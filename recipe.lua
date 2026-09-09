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

local icon_helpers = require("icon-helpers")
local ICON_TINT = icon_helpers.ICON_TINT
local build_size_icons = icon_helpers.build_size_icons

-- ============================================================================
-- GENERIC "PICK A SIZE" REMOTE
-- ============================================================================
-- See control.lua for how dragging a box with this resolves to a
-- size/orientation and trades for the real item (or a free ghost) via
-- grant_or_ghost().
data:extend({
  {
    type = "selection-tool",
    name = "ups-silo-generic",
    -- Plain tinted chest, no digit overlay - this item never shows a
    -- concrete size to the player, that's the whole point of it.
    icons = {
      {
        icon = "__base__/graphics/icons/steel-chest.png",
        icon_size = 64,
        tint = ICON_TINT
      }
    },
    icon_size = 64,
    localised_name = {"ups-silo.name-generic"},
    localised_description = {"ups-silo.stack-info-generic"},
    group = "ups-silo-group",
    subgroup = "ups-silo-chassis",
    order = "a",
    -- Matches steel chest (50) - has to be at least 27 to cover the largest
    -- silo's build cost (see data.lua's placeable_by / control.lua).
    stack_size = 50,
    -- We only care about the selected area's shape, not what's under it -
    -- "nothing" skips entity highlighting/selection entirely. select/
    -- alt_select (not the flat selection_mode/selection_color/etc used in
    -- older API versions) is the current nested schema.
    select = {
      mode = {"nothing"},
      border_color = {r = 1, g = 0.65, b = 0.3},
      cursor_box_type = "copy"
    },
    alt_select = {
      mode = {"nothing"},
      border_color = {r = 1, g = 0.65, b = 0.3},
      cursor_box_type = "copy"
    }
  },
  {
    type = "recipe",
    -- Named to exactly match its result item (ups-silo-generic), not
    -- given its own distinct name - Factoriopedia auto-merges a
    -- recipe into its item's page when the two share a name.
    name = "ups-silo-generic",
    localised_name = {"ups-silo.name-generic"},
    enabled = false,
    energy_required = 0.5,
    ingredients = {
      {type = "item", name = "steel-chest", amount = 1},
      {type = "item", name = "electronic-circuit", amount = 1},
      {type = "item", name = "fast-inserter", amount = 2}
    },
    results = {{type = "item", name = "ups-silo-generic", amount = 1}}
  }
})

-- ============================================================================
-- ORIENTATION SWAP ("ROTATE")
-- ============================================================================
-- Horizontal and vertical silos are independent entities/items, not one
-- rotatable entity with direction variants (see data.lua) - so vanilla's
-- own rotate-while-aiming does nothing for them. This custom input is
-- linked to the player's actual "rotate" control (whatever it's bound to,
-- fires alongside vanilla's own handling of it rather than replacing it)
-- so control.lua can swap the cursor's item/ghost for its same-size
-- opposite-orientation counterpart instead.
data:extend({
  {
    type = "custom-input",
    name = "ups-silo-rotate",
    key_sequence = "",
    linked_game_control = "rotate"
  }
})

-- ============================================================================
-- INITIALIZE THE 27 REFERENCE-ONLY ITEMS
-- ============================================================================
-- These 53 items are never crafted and never sit in a player's inventory -
-- deliberately no recipe. They exist purely as place_result targets: the
-- generic remote's confirm step points player.cursor_ghost at one of these
-- by name, which is how the engine resolves which entity the resulting
-- ghost represents. Construction of that ghost is satisfied by the generic
-- remote itself (see placeable_by on each entity in data.lua), never by
-- these items - so pipette, mining, blueprints etc. never need to touch
-- them either.
for i = 1, 27 do
  data:extend({
    -- Horizontal and vertical are just two independent, honestly-different
    -- items - no rotation illusion, no shared identity.
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
      localised_description = {(i == 1) and "ups-silo.stack-info-1x1" or "ups-silo.stack-info", tostring(4 * i), tostring(i)},
      group = "ups-silo-group",
      subgroup = "ups-silo-chassis",
      order = "b[" .. string.format("%02d", i) .. "]",
      stack_size = 10,
      place_result = "ups-silo-" .. i .. "x1",
      -- These 53 items are accidental/exceptional plumbing - they should
      -- never rest anywhere real (see the reclaim logic in control.lua) and
      -- a player should never need to go looking one up on its own. The
      -- entity itself is the real, permanent thing worth documenting - see
      -- data.lua, which is deliberately NOT hidden.
      hidden_in_factoriopedia = true
    }
  })

  -- At size 1, both orientations place_result into the same shared entity
  -- (ups-silo-1x1) - a second item would just be a pointless exact
  -- duplicate of the one above, so skip it.
  if i > 1 then
    data:extend({
      {
        type = "item",
        name = "ups-silo-item-v-" .. i,
        icons = build_size_icons("__UPS-silos__/graphics/entity/high-chest-icon.png", i),
        icon_size = 64,
        localised_name = {"ups-silo.name-vertical", tostring(i)},
        localised_description = {"ups-silo.stack-info", tostring(4 * i), tostring(i)},
        group = "ups-silo-group",
        subgroup = "ups-silo-chassis-vertical",
        order = "b[" .. string.format("%02d", i) .. "]",
        stack_size = 10,
        place_result = "ups-silo-1x" .. i,
        hidden_in_factoriopedia = true
      }
    })
  end
end
