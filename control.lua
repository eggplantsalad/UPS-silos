-- ============================================================================
-- GENERIC SILO REMOTE
-- ============================================================================
-- ups-silo-generic is a selection-tool - applicable locally or in 
-- remote view. Dragging a box with it fires on_player_selected_area; its
-- dimensions pick the size/orientation (1 tile tall = horizontal N, 1 tile
-- wide = vertical N, 1x1 = smallest).
--
-- grant_or_ghost() then hands over the real per-size item if
-- owned, else spends N generic remotes to manifest one, else places a
-- ghost - same fallback vanilla uses for anything unaffordable. None of
-- the 53 real ups-silo-item-* prototypes are ever crafted directly: the 27
-- horizontal ones have a recipe that exists only to appear "enabled" in
-- build UIs (see recipe.lua) and can never complete, and the rest have no
-- recipe at all - either way, they only come from this trade. The same
-- helper runs again from on_player_pipette, since Q's own placeable_by
-- resolution can hand back the remote itself, which has no place_result
-- and can't complete a build on its own.

local GENERIC_ITEM = "ups-silo-generic"

-- Parses "ups-silo-Nx1" / "ups-silo-1xN" / "ups-silo-1x1" entity names into
-- a (target_item, size) pair. Returns nil for anything else.
local function target_of_entity_name(entity_name)
  if entity_name == "ups-silo-1x1" then return "ups-silo-item-1", 1 end
  local n = entity_name:match("^ups%-silo%-(%d+)x1$")
  if n then return "ups-silo-item-" .. n, tonumber(n) end
  n = entity_name:match("^ups%-silo%-1x(%d+)$")
  if n then return "ups-silo-item-v-" .. n, tonumber(n) end
  return nil
end

-- Turns a drag's corners into a target item, build direction, and exact
-- placement position, or nil if the shape doesn't correspond to any
-- silo (not 1xN/Nx1, or over 27). Snaps each corner outward to the
-- nearest tile line (floor the top-left, ceil the bottom-right) rather
-- than rounding the raw width/height - a drag that falls short of a
-- clean tile boundary never shrinks the result, it only ever grows to
-- the nearest full tile.
local function resolve_target(area)
  local left = math.floor(area.left_top.x)
  local top = math.floor(area.left_top.y)
  local right = math.ceil(area.right_bottom.x)
  local bottom = math.ceil(area.right_bottom.y)
  local width = math.max(1, right - left)
  local height = math.max(1, bottom - top)
  local position = {x = (left + right) / 2, y = (top + bottom) / 2}

  if width == 1 and height == 1 then
    return "ups-silo-item-1", 1, defines.direction.north, position
  elseif height == 1 and width <= 27 then
    return "ups-silo-item-" .. width, width, defines.direction.north, position
  elseif width == 1 and height <= 27 then
    -- A "tall" drag resolves to the horizontal item, rotated east.
    -- The vertical items/entities still fully work for anything already
    -- placed, in a blueprint, or copy-pasted (see target_of_entity_name
    -- above), since none of that goes through here.
    return "ups-silo-item-" .. height, height, defines.direction.east, position
  end
  return nil
end

-- Owned real item > paid-for trade > free ghost, in order of
-- preference. Always succeeds at *something* landing in the cursor.
local function grant_or_ghost(player, target_item, size)
  -- No physical body present remotely to hold a real item in hand - remote
  -- view should only ever end up with a ghost-aim, same as it already
  -- does for pipetting an existing ghost. Skip the ownership/spend logic
  -- entirely rather than manifesting or consuming anything remotely.
  if player.controller_type == defines.controllers.remote then
    player.clear_cursor()
    player.cursor_ghost = {name = target_item}
    return
  end

  if player.get_item_count(target_item) >= 1 then
    player.remove_item{name = target_item, count = 1}
    player.cursor_stack.set_stack{name = target_item, count = 1}
    return
  end

  if player.get_item_count(GENERIC_ITEM) >= size then
    -- The cursor may currently be holding the generic stack itself (it's
    -- the selection-tool that triggered this, or pipette left it there).
    -- remove_item() pulls from the main inventory and leaves that cursor
    -- stack untouched, so blindly overwriting cursor_stack afterward would
    -- silently destroy whatever was still left of it. Spend from the
    -- cursor first and put any leftover back in the inventory instead.
    local remaining = size
    local cursor = player.cursor_stack
    if cursor and cursor.valid_for_read and cursor.name == GENERIC_ITEM then
      local take = math.min(remaining, cursor.count)
      local leftover = cursor.count - take
      remaining = remaining - take
      cursor.clear()
      if leftover > 0 then
        player.insert{name = GENERIC_ITEM, count = leftover}
      end
    end
    if remaining > 0 then
      player.remove_item{name = GENERIC_ITEM, count = remaining}
    end
    player.cursor_stack.set_stack{name = target_item, count = 1}
    return
  end

  -- cursor_ghost and cursor_stack are mutually exclusive - assigning the
  -- ghost while the cursor still physically holds something (e.g. the
  -- generic item that triggered this, now too few to afford the trade)
  -- silently drops the assignment, leaving whatever ghost was already
  -- showing (stale, from an earlier action) untouched. clear_cursor() is
  -- what vanilla uses for its own cursor-cancel handling - it
  -- returns the held stack to the inventory (spilling to the ground if
  -- full) rather than just deleting it.
  player.clear_cursor()
  player.cursor_ghost = {name = target_item}
end

script.on_event(defines.events.on_player_selected_area, function(event)
  if event.item ~= GENERIC_ITEM then return end

  local player = game.get_player(event.player_index)
  if not player then return end

  local target_item, size, direction, position = resolve_target(event.area)
  if not target_item then
    player.play_sound{path = "utility/cannot_build"}
    return
  end

  grant_or_ghost(player, target_item, size)
  player.build_from_cursor{position = position, direction = direction}
end)

-- We deliberately don't trust event.item here: Q resolves strictly by
-- placeable_by array order (real item always first, see data.lua), not by
-- what's actually owned - so vanilla's own default pipette ghost-aims the
-- unowned real item even while holding plenty of generic remotes.
-- player.selected still reflects the actual target regardless, so we read
-- from there and just redo the trade - covering both an existing ghost
-- (ghost_name) and an already-built silo (name) the same way.
script.on_event(defines.events.on_player_pipette, function(event)
  local player = game.get_player(event.player_index)
  if not player then return end

  local selected = player.selected
  if not (selected and selected.valid) then return end

  local entity_name
  if selected.type == "entity-ghost" then
    entity_name = selected.ghost_name
  else
    entity_name = selected.name
  end

  local target_item, size = target_of_entity_name(entity_name)
  if not target_item then return end

  grant_or_ghost(player, target_item, size)
end)

-- ============================================================================
-- STRAY REAL-ITEM RECLAIM
-- ============================================================================
-- The 53 real ups-silo-item-* prototypes are meant to exist only
-- momentarily, in the cursor, mid-placement - never at rest in the actual
-- inventory. Canceling a placement (e.g. right-click to cancel, or picking
-- up something else) hands whatever's in the cursor back to the main
-- inventory as-is though, which would otherwise leave one of these
-- items stranded there. Whenever the main
-- inventory changes, silently convert any of them back into their N
-- generics instead - cursor contents aren't part of the main inventory, so
-- an item genuinely being held for placement is never touched by this.
local function reclaim_stray_specifics(player)
  local inv = player.get_main_inventory()
  if not inv then return end

  local function reclaim(name, size)
    local count = inv.get_item_count(name)
    if count > 0 then
      inv.remove{name = name, count = count}
      local total = count * size
      local inserted = player.insert{name = GENERIC_ITEM, count = total}
      if inserted < total then
        player.surface.spill_item_stack{
          position = player.position,
          stack = {name = GENERIC_ITEM, count = total - inserted},
          enable_looted = true,
          force = player.force
        }
      end
    end
  end

  for i = 1, 27 do
    reclaim("ups-silo-item-" .. i, i)
    if i > 1 then
      reclaim("ups-silo-item-v-" .. i, i)
    end
  end
end

script.on_event(defines.events.on_player_main_inventory_changed, function(event)
  local player = game.get_player(event.player_index)
  if not player then return end
  reclaim_stray_specifics(player)
end)

-- ============================================================================
-- RECIPE-ENABLED MIGRATION
-- ============================================================================
-- "Recipe unlocked" is a per-save flag keyed by prototype name, applied
-- once when the technology finishes researching - if a future rename ever
-- leaves a save with the tech researched but its current recipe name not
-- enabled, this catches it back up. Also covers the 27 horizontal items'
-- recipes added in 1.0.0: on a save where ups-silo-tech was researched
-- before those recipes existed, the unlock-recipe effect never fires again
-- on its own, so without this they'd stay permanently disabled and the
-- items would never appear in the remote-view build panel. Runs on every
-- load, not just once, since it's cheap and idempotent - simpler than
-- tracking whether it's already been done.
local function recipe_names_to_check()
  local names = {"ups-silo-generic"}
  for i = 1, 27 do
    table.insert(names, "ups-silo-item-" .. i)
  end
  return names
end

script.on_configuration_changed(function()
  for _, force in pairs(game.forces) do
    local tech = force.technologies["ups-silo-tech"]
    if tech and tech.researched then
      for _, name in pairs(recipe_names_to_check()) do
        local recipe = force.recipes[name]
        if recipe and not recipe.enabled then
          recipe.enabled = true
        end
      end
    end
  end
end)
