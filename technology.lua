-- Only the generic remote has a recipe - the 53 sized items are
-- reference-only prototypes (see recipe.lua) with no recipe to unlock.
local tech_effects = {
  {
    type = "unlock-recipe",
    recipe = "ups-silo-generic"
  }
}

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
