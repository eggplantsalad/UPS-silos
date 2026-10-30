-- The generic remote's recipe, plus all 27 horizontal reference-only items'
-- recipes (see recipe.lua) - those can never actually be crafted (hidden
-- from player crafting, locked to a category nothing supports), but still
-- need unlocking so they count as "enabled" and show up in the remote-view
-- build panel.
local tech_effects = {
  {
    type = "unlock-recipe",
    recipe = "ups-silo-generic"
  }
}

-- Horizontal only - the vertical ups-silo-item-v-* items have no recipe
-- to unlock any more (see recipe.lua).
for i = 1, 27 do
  table.insert(tech_effects, {type = "unlock-recipe", recipe = "ups-silo-item-" .. i})
end

data:extend({
  {
    type = "technology",
    name = "ups-silo-tech",
    icon = "__UPS-silos__/graphics/silo-icon.png",
    icon_size = 256,
    scale = 0.5,
    
    effects = tech_effects, 
    
    prerequisites = {
      "circuit-network",  -- Constant-time buffer memory routing data buses
      "fast-inserter",    -- Cross-tile platform reach extraction clearance mechanics
      "steel-processing"  -- Solid metallurgical framework components
    },
    
    unit = {
      count = 150,
      ingredients = {
        {"automation-science-pack", 1}, -- Red Science Packs
        {"logistic-science-pack", 1}    -- Green Science Packs
      },
      time = 30 -- 30 seconds per research cycle in the labs
    },
    
    order = "c-g-c" -- Centers it perfectly right below early automated switching yards
  }
})
