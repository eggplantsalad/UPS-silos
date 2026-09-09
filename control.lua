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
-- ghost - same fallback vanilla uses for anything unaffordable. The
-- 53 real ups-silo-item-* prototypes deliberately have no recipe; nothing
-- ever crafts them directly, they only come from this trade. The same
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

-- Turns a selected area's tile dimensions into a target item, or nil if
-- the shape doesn't correspond to any silo (not 1xN/Nx1, or over 27).
local function resolve_target(width, height)
  width = math.max(1, math.floor(width + 0.5))
  height = math.max(1, math.floor(height + 0.5))

  if width == 1 and height == 1 then
    return "ups-silo-item-1", 1
  elseif height == 1 and width <= 27 then
    return "ups-silo-item-" .. width, width
  elseif width == 1 and height <= 27 then
    return "ups-silo-item-v-" .. height, height
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

  local area = event.area
  local width = area.right_bottom.x - area.left_top.x
  local height = area.right_bottom.y - area.left_top.y

  local target_item, size = resolve_target(width, height)
  if not target_item then
    player.play_sound{path = "utility/cannot_build"}
    return
  end

  grant_or_ghost(player, target_item, size)
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
-- deliberately-recipe-less items stranded there. Whenever the main
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
-- ORIENTATION SWAP ("ROTATE")
-- ============================================================================
-- Horizontal/vertical are separate items of the same size (see recipe.lua),
-- not direction variants of one entity, so there's nothing for vanilla's
-- own rotate-while-aiming to do here. ups-silo-rotate (see recipe.lua) is
-- linked to the player's actual rotate control and fires alongside it, so
-- this just swaps whatever's in the cursor - real item or ghost-aim - for
-- its same-size opposite-orientation counterpart. The 1x1 has no
-- orientation and is left alone.
local function orientation_swap(name)
  local n = name:match("^ups%-silo%-item%-(%d+)$")
  if n then return "ups-silo-item-v-" .. n end
  n = name:match("^ups%-silo%-item%-v%-(%d+)$")
  if n then return "ups-silo-item-" .. n end
  return nil
end

script.on_event("ups-silo-rotate", function(event)
  local player = game.get_player(event.player_index)
  if not player then return end

  local cursor = player.cursor_stack
  if cursor and cursor.valid_for_read then
    local swapped = orientation_swap(cursor.name)
    if swapped then
      cursor.set_stack{name = swapped, count = cursor.count}
    end
    return
  end

  local ghost = player.cursor_ghost
  -- Unlike cursor_stack, cursor_ghost's read shape hands back rich
  -- prototype objects rather than plain strings - ghost.name is a
  -- LuaItemPrototype here, not the item's name itself.
  if ghost and ghost.name then
    local swapped = orientation_swap(ghost.name.name)
    if swapped then
      player.cursor_ghost = {name = swapped}
    end
  end
end)

-- ============================================================================
-- RECIPE-ENABLED MIGRATION
-- ============================================================================
-- "Recipe unlocked" is a per-save flag keyed by prototype name, applied
-- once when the technology finishes researching - if a future rename ever
-- leaves a save with the tech researched but its current recipe name not
-- enabled, this catches it back up. Runs on every load, not just once,
-- since it's cheap and idempotent - simpler than tracking whether it's
-- already been done.
script.on_configuration_changed(function()
  for _, force in pairs(game.forces) do
    local tech = force.technologies["ups-silo-tech"]
    local recipe = force.recipes["ups-silo-generic"]
    if tech and tech.researched and recipe and not recipe.enabled then
      recipe.enabled = true
    end
  end
end)
