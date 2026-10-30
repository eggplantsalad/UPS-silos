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
  },
  {
    -- No machine or character ever declares support for this category, so
    -- a recipe placed in it can never actually be crafted anywhere - belt
    -- and suspenders alongside hide_from_player_crafting below, since the
    -- 53 reference items must never actually be produced, only exist as
    -- enabled-recipe plumbing so they appear in build/ghost-placement UIs.
    type = "recipe-category",
    name = "ups-silo-reference-only"
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
-- INITIALIZE THE 53 REFERENCE-ONLY ITEMS (27 SIZES h/v, 1x1 once)
-- ============================================================================
-- These 53 items are never crafted and never sit in a player's inventory.
-- They exist purely as place_result targets: the generic remote's confirm
-- step points player.cursor_ghost at one of these by name, which is how the
-- engine resolves which entity the resulting ghost represents. Construction
-- of that ghost is satisfied by the generic remote itself (see placeable_by
-- on each entity in data.lua), never by these items - so pipette, mining,
-- blueprints etc. never need to touch them either.
--
-- Only the 27 horizontal items get a recipe (unlocked by ups-silo-tech,
-- see technology.lua), purely so the item counts as "enabled" - that's
-- what Factorio's remote-view build panel (the normal "E" inventory/
-- crafting screen) actually keys off to decide what to list, independent
-- of the "Show all items in selection lists" setting. The recipe can never
-- actually complete though: hide_from_player_crafting keeps it off the
-- player's own crafting list, and its category (ups-silo-reference-only)
-- is one no character or machine declares support for. The 26 vertical
-- items (below, i > 1) have no recipe at all - they're back-compat-only,
-- never freshly granted (see control.lua's resolve_target).
for i = 1, 27 do
  data:extend({
    {
      type = "item",
      name = "ups-silo-item-" .. i,
      -- Size 1 places the plain steel-chest-styled shared entity (see
      -- data.lua), not a wide-chest slice - its icon should match that.
      icons = build_size_icons((i == 1) and "__base__/graphics/icons/steel-chest.png"
        or "__UPS-silos__/graphics/entity/wide-chest-icon.png", i),
      icon_size = 64,
      localised_name = (i == 1) and {"ups-silo.name-1x1"} or {"ups-silo.name-sized", tostring(i)},
      -- No localised_description here any more - Factoriopedia merges
      -- this item's page with its recipe and entity (both below), and
      -- the entity's own description (see data.lua) already covers it;
      -- a separate item-side description would just duplicate that.
      group = "ups-silo-group",
      subgroup = "ups-silo-chassis",
      order = "b[" .. string.format("%02d", i) .. "]",
      stack_size = 10,
      place_result = "ups-silo-" .. i .. "x1",
      -- These 53 items are accidental/exceptional plumbing - they should
      -- never rest anywhere real (see the reclaim logic in control.lua) and
      -- a player should never need to go looking one up on its own. Not
      -- hidden from Factoriopedia though (unlike the legacy vertical
      -- items, see further down): the entity's hidden instead (see
      -- data.lua), so this item is the only non-hidden prototype in its
      -- family, anchoring the merged Factoriopedia row - same as how a
      -- vanilla item/entity pair anchors theirs - instead of that row
      -- falling back to the recipe and showing a "(Recipe)" hover-label
      -- mismatch against every vanilla entry.
      hidden_in_factoriopedia = false
    },
    {
      type = "recipe",
      name = "ups-silo-item-" .. i,
      enabled = false,
      hide_from_player_crafting = true,
      categories = {"ups-silo-reference-only"},
      -- Reflects the real cost of the drag/pipette trade (see
      -- control.lua's grant_or_ghost) rather than being left empty -
      -- an empty ingredients list showed as a misleading "None" on the
      -- Factoriopedia page merged in from this recipe. Still can never
      -- actually be crafted either way (hide_from_player_crafting, plus
      -- a category no machine/character supports).
      ingredients = {{type = "item", name = "ups-silo-generic", amount = i}},
      results = {{type = "item", name = "ups-silo-item-" .. i, amount = 1}}
    }
  })

  -- At size 1, both orientations place_result into the same shared entity
  -- (ups-silo-1x1) - a second item would just be a pointless exact
  -- duplicate of the one above, so skip it.
  if i > 1 then
    -- Item only, deliberately no recipe any more: a fresh drag/pipette
    -- never grants this (see control.lua's resolve_target - vertical
    -- drags resolve to the horizontal item, rotated, instead), and
    -- without an enabled recipe it won't show up in the remote-view
    -- build panel either. Still exists, fully functional, purely for
    -- back-compat with anything already placed, blueprinted, or
    -- copy-pasted from before this version. Deconstruction/mining is
    -- unaffected either way - minable.result in data.lua already
    -- always points at the generic item, independent of recipes.
    data:extend({
      {
        type = "item",
        name = "ups-silo-item-v-" .. i,
        icons = build_size_icons("__UPS-silos__/graphics/entity/high-chest-icon.png", i),
        icon_size = 64,
        localised_name = {"ups-silo.name-sized", tostring(i)},
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
