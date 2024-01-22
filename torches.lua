
local active_particle_spawners = {}

local colour_list = {
	{"black", "Darkened",}, {"blue", "Blue",},
	{"cyan", "Cyan",}, {"green", "Green",},
	{"magenta", "Magenta",}, {"orange", "Orange",},
	{"purple", "Purple",}, {"red", "Red",},
	{"yellow", "Yellow",}, {"white", "Frosted",},
}

local enable_ceiling = true

local make_particle_generator = function(pos, node)
	local pos_hash = minetest.hash_node_position(pos)
	local spawner_id = active_particle_spawners[pos_hash]

	if spawner_id then
		return spawner_id
	end

	local color = node.name:split(":")[2]:split("_")[2]
	if color=="frosted" then
		color = "white"
	end
	local id = minetest.add_particlespawner({
			pos = { min = vector.add(pos, vector.new(-0.1, 0.45, -0.1)), max = vector.add(pos, vector.new(0.1, 0.5, 0.1)) },
			vel = { min = vector.new(0, 0, 0), max = vector.new( 0, 0.15, 0) },
			acc = { min = vector.new(0, 0.1, 0), max = vector.new(0, 0.3, 0) },
			time = 0, -- infinite time
			amount = 2, -- 2 per second
			exptime = 1,
			collisiondetection = true,
			collision_removal = true,
			glow = 14,
			texpool = {
				{ name = "abritorch_spark.png", alpha_tween = { 1, 0 }, scale = 0.3 },
				{ name = "abritorch_spark.png^[multiply:" .. color, alpha_tween = { 1, 0 }, scale = 0.5 },
			}
	})
	active_particle_spawners[pos_hash] = id
	return id
end

-- only return on_construct function if particles are supported
local torch_on_construct = function()
	if minetest.features.particlespawner_tweenable then
		return function(pos)
			local node = minetest.get_node(pos)
			make_particle_generator(pos, node)
		end
	else
		return nil
	end
end

local torch_on_destruct = function()
	if minetest.features.particlespawner_tweenable then
		return function(pos)
			local pos_hash = minetest.hash_node_position(pos)
			local spawner_id = active_particle_spawners[pos_hash]
			if spawner_id then
				minetest.delete_particlespawner(spawner_id)
				active_particle_spawners[pos_hash] = nil
			end
		end
	else
		return nil
	end
end


for i in ipairs(colour_list) do
	local colour = colour_list[i][1]
	local desc = colour_list[i][2]

	minetest.register_craftitem("abritorch:torch_"..colour, {
		description = desc.." Torch",
		inventory_image = "abritorch_torch_on_floor_"..colour..".png",
		wield_image = "abritorch_torch_on_floor_"..colour..".png",
		wield_scale = {x = 1, y = 1, z = 1 + 1/16},
		groups = { torch = 1 },
		liquids_pointable = false,
		use_texture_alpha = "clip",
		on_place = function(itemstack, placer, pointed_thing)
			local above = pointed_thing.above
			local under = pointed_thing.under
			local wdir = minetest.dir_to_wallmounted({x = under.x - above.x, y = under.y - above.y, z = under.z - above.z})
			if wdir < 1 and not enable_ceiling then
				return itemstack
			end
			local fakestack = itemstack
			local retval
			if wdir <= 1 then
				retval = fakestack:set_name("abritorch:floor_"..colour)
			else
				retval = fakestack:set_name("abritorch:wall_"..colour)
			end
			if not retval then
				return itemstack
			end
			itemstack = minetest.item_place(fakestack, placer, pointed_thing)
			itemstack:set_name("abritorch:torch_"..colour)

			return itemstack
		end
	})

	minetest.register_node("abritorch:floor_"..colour, {
		description = desc.." Torch",
		inventory_image = "abritorch_torch_on_floor_"..colour..".png",
		wield_image = "abritorch_torch_on_floor_"..colour..".png",
		wield_scale = {x = 1, y = 1, z = 1 + 1/16},
		drawtype = "mesh",
		mesh = "torch_floor.obj",
		use_texture_alpha = "clip",
		tiles = {
			{
				name = "abritorch_torch_on_floor_animated_"..colour..".png",
				animation = {type = "vertical_frames", aspect_w = 16, aspect_h = 16, length = 3.3}
			}
		},
		paramtype = "light",
		paramtype2 = "wallmounted",
		sunlight_propagates = true,
		walkable = false,
		light_source = 13,
		groups = {choppy=2, dig_immediate=3, flammable=1, not_in_creative_inventory=1, attached_node=1, torch=1, abritorch=1},
		drop = "abritorch:torch_"..colour,
		selection_box = {
			type = "wallmounted",
			wall_top = {-1/16, -2/16, -1/16, 1/16, 0.5, 1/16},
			wall_bottom = {-1/16, -0.5, -1/16, 1/16, 2/16, 1/16},
		},
		on_construct = torch_on_construct(),
		on_destruct = torch_on_destruct(),
	})

	minetest.register_node("abritorch:wall_"..colour, {
		inventory_image = "abritorch_torch_on_floor_"..colour..".png",
		wield_image = "abritorch_torch_on_floor_"..colour..".png",
		wield_scale = {x = 1, y = 1, z = 1 + 1/16},
		drawtype = "mesh",
		mesh = "torch_wall.obj",
		use_texture_alpha = "clip",
		tiles = {
			{
			    name = "abritorch_torch_on_floor_animated_"..colour..".png",
			    animation = {type = "vertical_frames", aspect_w = 16, aspect_h = 16, length = 3.3}
			}
		},
		paramtype = "light",
		paramtype2 = "wallmounted",
		sunlight_propagates = true,
		walkable = false,
		light_source = 13,
		groups = {choppy=2, dig_immediate=3, flammable=1, not_in_creative_inventory=1, attached_node=1, torch=1, abritorch=1},
		drop = "abritorch:torch_"..colour,
		selection_box = {
			type = "wallmounted",
			wall_top = {-0.1, -0.1, -0.1, 0.1, 0.5, 0.1},
			wall_bottom = {-0.1, -0.5, -0.1, 0.1, 0.1, 0.1},
			wall_side = {-0.5, -0.3, -0.1, -0.2, 0.3, 0.1},
		},
		on_construct = torch_on_construct(),
		on_destruct = torch_on_destruct(),
	})

	minetest.register_abm({
		nodenames = {"abritorch:torch_"..colour},
		interval = 1,
		chance = 1,
		action = function(pos)
			local n = minetest.get_node(pos)
			local def = minetest.registered_nodes[n.name]
			if n and def then
				local wdir = n.param2
				local node_name = "abritorch:wall_"..colour
				if wdir < 1 and not enable_ceiling then
					minetest.remove_node(pos)
					return
				elseif wdir <= 1 then
					node_name = "abritorch:floor_"..colour
				end
				minetest.set_node(pos, {name = node_name, param2 = wdir})
			end
		end
	})
end

-- this is needed because particle generators need to be re-created after server restart
if minetest.features.particlespawner_tweenable then
	minetest.register_lbm({
		label = "Make abritorch particles",
		name = "abritorch:add_particle_spawner",
		nodenames = { "group:abritorch" },
		run_at_every_load = true,
		action = function(pos, node, dtime_s)
			make_particle_generator(pos, node)
		end
	})
end


local CHECK_INTERVAL = 7.777
local last_check = 0
local clear_unloaded_particles = function(dtime)
	last_check = last_check + dtime
	if last_check < CHECK_INTERVAL then
		return
	else
		last_check = last_check - CHECK_INTERVAL
	end
	for pos_hash, spawner_id in pairs(active_particle_spawners) do
		local pos = minetest.get_position_from_hash(pos_hash)
		local node = minetest.get_node_or_nil(pos)
		if (not node) or node.name:find("^abritorch:") == nil then
			minetest.delete_particlespawner(spawner_id)
			active_particle_spawners[pos_hash] = nil
		end
	end
end

minetest.register_globalstep(clear_unloaded_particles)
