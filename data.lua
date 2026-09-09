-- ============================================================================
-- SIZE MATRIX (Looping 1 to 27)
-- ============================================================================
-- The item-group/item-subgroup prototypes live in recipe.lua, alongside the
-- items that actually use them.

local icon_helpers = require("icon-helpers")

-- Applied to body layers only (not shadows - multiplying near-black pixels
-- does nothing useful). tint multiplies the sprite's existing colors, so
-- this warms the already-light ribbed-metal areas toward amber rather than
-- recoloring the whole chest outright.
local SILO_TINT = icon_helpers.ICON_TINT

for i = 1, 27 do
    -- ========================================================================
    -- HORIZONTAL BUFFER Graphics (1xN Layout - Using Wide Chest Slices)
    -- ========================================================================
    local horiz_layers = {}

    -- Positions ported from the WideChests mod's own tested calibration for
    -- this same art (wide-chest.png / wide-chest-shadow.png are the same
    -- files that mod ships). Each piece sits at its tile-grid center, plus a
    -- tiny fixed nudge (-0.0078125, -0.015625) that WideChests' own
    -- formula resolves to for this exact 64x80 crop.
    local function horiz_tile_center(tile)
        return -(i * 0.5) + (tile - 0.5)
    end

    -- 1. Base Entity Texture Slicing (64x80 canvas slices).
    table.insert(horiz_layers, {
        filename = "__UPS-silos__/graphics/entity/wide-chest.png",
        priority = "extra-high",
        width = 64, height = 80, x = 0, y = 0, scale = 0.5,
        shift = {horiz_tile_center(1) - 0.0078125, -0.015625}, -- Snaps exactly to the left edge tile
        tint = SILO_TINT
    })

    -- Repeating Middle Segments (Fills inner body space back-to-back)
    for tile = 2, (i - 1) do
        table.insert(horiz_layers, {
            filename = "__UPS-silos__/graphics/entity/wide-chest.png",
            width = 64, height = 80, x = 32, y = 0, scale = 0.5, -- Grabs mid segment
            shift = {horiz_tile_center(tile) - 0.0078125, -0.015625},
            tint = SILO_TINT
        })
    end

    -- Right End Cap Piece
    table.insert(horiz_layers, {
        filename = "__UPS-silos__/graphics/entity/wide-chest.png",
        width = 64, height = 80, x = 64, y = 0, scale = 0.5,
        shift = {horiz_tile_center(i) - 0.0078125, -0.015625}, -- Snaps exactly to the right edge tile
        tint = SILO_TINT
    })

    -- 2. Shadow Layer Integration - drawn once per entity, anchored past the
    -- right edge, not repeated per tile: the shadow art is a single uniform
    -- blob with no left/middle/right structure, so there's no tile-sized
    -- unit to repeat in the first place.
    table.insert(horiz_layers, {
        filename = "__UPS-silos__/graphics/entity/wide-chest-shadow.png",
        priority = "extra-high",
        width = 50, height = 46,
        x = 60, y = 0,
        scale = 0.5,
        draw_as_shadow = true,
        shift = {(i * 0.5) + 0.3515625, 0.25}
    })

    -- ========================================================================
    -- B. VERTICAL BUFFERS (Nx1 Layout - Using High Chest Slices)
    -- ========================================================================
    local vert_layers = {}

    -- Positions ported from the WideChests mod's own tested calibration for
    -- this same art (high-chest.png / high-chest-shadow.png are the same
    -- files that mod ships). Unlike the horizontal pieces, the vertical cap
    -- art is genuinely a different height than the middle (54/90px vs
    -- 64px) - each piece is anchored to its own tile-grid position plus 
    -- WideChests' own per-piece fine-tuning nudge.
    table.insert(vert_layers, {
        filename = "__UPS-silos__/graphics/entity/high-chest.png",
        priority = "extra-high",
        width = 64, height = 54, x = 0, y = 0, scale = 0.5,
        shift = {-0.0078125, -(i * 0.5) + 0.28125},
        tint = SILO_TINT
    })

    -- Repeating Middle Segments (y = 22, height = 64)
    for tile = 2, (i - 1) do
        table.insert(vert_layers, {
            filename = "__UPS-silos__/graphics/entity/high-chest.png",
            width = 64, height = 64, x = 0, y = 22, scale = 0.5,
            shift = {-0.0078125, -(i * 0.5) + tile - 0.796875},
            tint = SILO_TINT
        })
    end

    -- Bottom End Cap Piece (y = 54, height = 90)
    table.insert(vert_layers, {
        filename = "__UPS-silos__/graphics/entity/high-chest.png",
        width = 64, height = 90, x = 0, y = 54, scale = 0.5,
        shift = {-0.0078125, (i * 0.5) - 0.59375},
        tint = SILO_TINT
    })

    -- 3. Vertical Shadow Layers Alignment - a repeating 3-piece column (top
    -- cap / repeated middle / bottom cap), same structure as the body,
    -- unlike the horizontal shadow which is a single non-repeating blob.
    for tile = 1, i do
        local shadow_y, crop_y, crop_h
        if tile == 1 then
            shadow_y, crop_y, crop_h = -(i * 0.5) + 0.8203125, 0, 55
        elseif tile == i then
            shadow_y, crop_y, crop_h = (i * 0.5) - 0.3828125, 45, 55
        else
            shadow_y, crop_y, crop_h = -(i * 0.5) + tile - 0.3125, 18, 64
        end
        table.insert(vert_layers, {
            filename = "__UPS-silos__/graphics/entity/high-chest-shadow.png",
            priority = "extra-high",
            width = 110, height = crop_h, x = 0, y = crop_y,
            scale = 0.5, draw_as_shadow = true,
            shift = {0.3828125, shadow_y}
        })
    end

    -- Fewer slots than a steel chest, each holding proportionally more per
    -- stack. Slot count stays fixed across all widths (that's what UPS cost scales
    -- with); the multiplier grows with width since a wider silo stands in for more
    -- merged chest+inserter stations and should hold proportionally more.
    local silo_inventory_size = 10
    local silo_stack_multiplier = 4 * i

    if i == 1 then
        -- "ups-silo-" .. i .. "x1" and "ups-silo-1x" .. i are the SAME
        -- string at i=1, so the horizontal/vertical blocks below would
        -- collide on one name. Orientation is meaningless for a 1-tile
        -- chest anyway, so there's just one shared entity here, styled like
        -- a plain vanilla chest instead of a wide/high-chest slice (which
        -- only looks right at 2+ tiles) - recipe.lua skips a separate
        -- vertical item at size 1 for the same reason.
        data:extend({
            {
                type = "container",
                name = "ups-silo-1x1",
                icons = icon_helpers.build_size_icons("__base__/graphics/icons/steel-chest.png", 1),
                icon_size = 64,
                localised_name = {"ups-silo.name-1x1"},
                localised_description = {"ups-silo.stack-info-entity-1x1", tostring(silo_stack_multiplier), tostring(i)},
                -- Deliberately NOT hidden - this entity is the real,
                -- permanent thing worth documenting. The reference item that
                -- place_results into it IS hidden (see recipe.lua), since
                -- that item is accidental plumbing a player should never go
                -- looking up on its own.
                flags = {"placeable-neutral", "player-creation"},
                max_health = 500,

                inventory_size = silo_inventory_size,
                inventory_type = "with_custom_stack_size",
                inventory_properties = {
                    stack_size_multiplier = silo_stack_multiplier,
                    -- Gag/gift: fish is the one vanilla item nobody wants but
                    -- nobody wants to throw away either. Only the plain,
                    -- vanilla-looking 1x1 gets this - the surprise lands
                    -- better on the one silo that looks like nothing special,
                    -- not diluted across all 27 obviously-massive sizes.
                    stack_size_override = { ["raw-fish"] = 1000000000 },
                    with_bar = true
                },

                -- Same squeeze-through margin as the multi-tile variants, applied
                -- symmetrically since there's no "row direction" for a single tile.
                collision_box = {{-0.25, -0.25}, {0.25, 0.25}},
                selection_box = {{-0.5, -0.5}, {0.5, 0.5}},
                -- Deconstruction collapses back down to the generic remote,
                -- not the reference-only ups-silo-item-1 - same resource in,
                -- same resource out. Count matches placeable_by below, so
                -- build cost and refund stay symmetric.
                minable = { mining_time = 0.2, result = "ups-silo-generic", count = 1 },
                -- Two independent ways to satisfy a ghost of this entity.
                -- Real item listed first - placeable_by order is what bots
                -- and pipette (see control.lua) both use to pick between
                -- alternatives - though it's never actually stocked in a
                -- logistics network, so bots fall through to the generic
                -- remote in practice; a player who's traded for the real
                -- item can still build it by hand directly, since unlike
                -- the remote it's a genuinely placeable item.
                placeable_by = {
                    { item = "ups-silo-item-1", count = 1 },
                    { item = "ups-silo-generic", count = 1 }
                },
                circuit_connector = circuit_connector_definitions["chest"],
                circuit_wire_max_distance = 3,
                picture = {
                    layers = {
                        {
                            filename = "__base__/graphics/entity/steel-chest/steel-chest.png",
                            priority = "extra-high",
                            width = 64, height = 80,
                            scale = 0.5,
                            shift = {-0.015625, -0.015625},
                            tint = SILO_TINT
                        },
                        {
                            filename = "__base__/graphics/entity/steel-chest/steel-chest-shadow.png",
                            priority = "extra-high",
                            width = 110, height = 46,
                            scale = 0.5,
                            draw_as_shadow = true,
                            shift = {0.328125, 0.1875}
                        }
                    }
                }
            }
        })
    else
        -- C. HORIZONTAL CONTAINER SPECIFICATIONS (1xN Layout)
        data:extend({
            {
                type = "container",
                name = "ups-silo-" .. i .. "x1",
                icons = icon_helpers.build_size_icons("__UPS-silos__/graphics/entity/wide-chest-icon.png", i),
                icon_size = 64,
                localised_name = {"ups-silo.name-horizontal", tostring(i)},
                localised_description = {"ups-silo.stack-info-entity", tostring(silo_stack_multiplier), tostring(i)},
                flags = {"placeable-neutral", "player-creation"},
                max_health = 500,

                inventory_size = silo_inventory_size,
                inventory_type = "with_custom_stack_size",
                inventory_properties = { stack_size_multiplier = silo_stack_multiplier, with_bar = true },

                -- +-0.25 on every side (both the long-axis ends and the
                -- perpendicular sides) leaves a 0.5-tile gap between two
                -- directly-adjacent silos in any direction - the vanilla
                -- player character's own collision_box is only 0.4 tile wide
                -- ({-0.2,-0.2},{0.2,0.2}), so that's comfortably enough to
                -- walk through, from any side.
                collision_box = {{-((i * 0.5) - 0.25), -0.25}, {((i * 0.5) - 0.25), 0.25}},
                selection_box = {{-((i * 0.5)), -0.5}, {((i * 0.5)), 0.5}},
                -- Deconstruction collapses back down to the generic remote,
                -- scaled the same as the build cost below - build N, get N
                -- back.
                minable = { mining_time = 0.2, result = "ups-silo-generic", count = i },
                -- Same reasoning as the 1x1's placeable_by above - generic
                -- remote cost scales linearly with size here.
                placeable_by = {
                    { item = "ups-silo-item-" .. i, count = 1 },
                    { item = "ups-silo-generic", count = i }
                },
                circuit_connector = circuit_connector_definitions["chest"],
                circuit_wire_max_distance = i + 2,
                picture = { layers = horiz_layers }
            }
        })

        -- D. VERTICAL CONTAINER SPECIFICATIONS (Nx1 Layout)
        data:extend({
            {
                type = "container",
                name = "ups-silo-1x" .. i,
                icons = icon_helpers.build_size_icons("__UPS-silos__/graphics/entity/high-chest-icon.png", i),
                icon_size = 64,
                localised_name = {"ups-silo.name-vertical", tostring(i)},
                localised_description = {"ups-silo.stack-info-entity", tostring(silo_stack_multiplier), tostring(i)},
                flags = {"placeable-neutral", "player-creation"},
                max_health = 500,

                inventory_size = silo_inventory_size,
                inventory_type = "with_custom_stack_size",
                inventory_properties = { stack_size_multiplier = silo_stack_multiplier, with_bar = true },

                -- Same reasoning as the horizontal variant's collision_box - see there.
                collision_box = {{-0.25, -((i * 0.5) - 0.25)}, {0.25, ((i * 0.5) - 0.25)}},
                selection_box = {{-0.5, -((i * 0.5))}, {0.5, ((i * 0.5))}},
                -- Deconstruction collapses back down to the generic remote,
                -- scaled the same as the build cost below - build N, get N
                -- back.
                minable = { mining_time = 0.2, result = "ups-silo-generic", count = i },
                -- Same reasoning as the 1x1's placeable_by above.
                placeable_by = {
                    { item = "ups-silo-item-v-" .. i, count = 1 },
                    { item = "ups-silo-generic", count = i }
                },
                circuit_connector = circuit_connector_definitions["chest"],
                circuit_wire_max_distance = i + 2,
                picture = { layers = vert_layers }
            }
        })
    end
end

require("recipe")
require("technology")
