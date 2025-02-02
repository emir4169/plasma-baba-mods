function movecommand(ox,oy,dir_,playerid_,dir_2,no3d_)
	--[[ 
		@mods(turning text) - Override reason - handle multiple directional text cases and added additional calls to code() to handle turning text resolution
		
		@mods(text splicing) - Override reason - update mod global to allow text stacking per movement phase ("you" phase, "move" phase, etc)
	 ]]

	statusblock(nil,nil,true)
	movelist = {}
	local debug_moves = 0
	
	local take = 1
	local takecount = 8
	local finaltake = false
	local no3d = no3d_ or false
	local playerid = playerid_ or 1
	local still_moving = {}
	
	local levelpush = -1
	local levelpull = -1
	local levelmovedir = dir_
	
	local levelmove = {}
	local levelmove2 = {}
	
	arrow_prop_mod_globals.group_arrow_properties = false
	if (playerid == 1) then
		levelmove = findfeature("level","is","you")
	elseif (playerid == 2) then
		levelmove = findfeature("level","is","you2")
		
		if (levelmove == nil) then
			levelmove = findfeature("level","is","you")
		end
	elseif (playerid == 3) then
		levelmove = findfeature("level","is","you") or {}
		levelmove2 = findfeature("level","is","you2")
		
		if (#levelmove > 0) and (dir_ ~= nil) then
			levelmovedir = dir_
		elseif (levelmove2 ~= nil) and (dir_ ~= nil) then
			levelmovedir = dir_
		elseif (dir_2 ~= nil) then
			levelmovedir = dir_2
		end
		
		if (levelmove2 ~= nil) then
			for i,v in ipairs(levelmove2) do
				table.insert(levelmove, v)
			end
		end
		
		if (#levelmove == 0) then
			levelmove = nil
		end
	end
	arrow_prop_mod_globals.group_arrow_properties = true

	-- @Turning Text(YOU) ----------------------------------------
	if levelmove == nil then
		levelmove = do_directional_you_level(dir_, dir_2, playerid)
	end
	----------------------------------------------------
	
	if (levelmove ~= nil) then
		local valid = false
		
		for i,v in ipairs(levelmove) do
			if (valid == false) and testcond(v[2],1) then
				valid = true
			end
		end
		
		if (featureindex["reverse"] ~= nil) then
			levelmovedir = reversecheck(1,levelmovedir)
		end
		
		if cantmove("level",1,levelmovedir) then
			valid = false
		end
		
		if valid then
			local ndrs = ndirs[levelmovedir + 1]
			local ox,oy = ndrs[1],ndrs[2]
			
			if (isstill(1,nil,nil,levelmovedir) == false) then
				addundo({"levelupdate",Xoffset,Yoffset,Xoffset + ox * tilesize,Yoffset + oy * tilesize,mapdir,levelmovedir})
				MF_scrollroom(ox * tilesize,oy * tilesize)
			else
				addundo({"levelupdate",Xoffset,Yoffset,Xoffset,Yoffset,mapdir,levelmovedir})
			end
			
			if (levelmovedir ~= 4) then
				mapdir = levelmovedir
			end
			updateundo = true
		end
	end
	
	while (take <= takecount) or finaltake do
		local moving_units = {}
		local been_seen = {}
		local skiptake = false
		
		reset_splice_mod_vars_per_take()
		
		if (finaltake == false) then
			if (take == 1) then
				local players = {}
				local players2 = {}
				local players3 = {}
				local empty = {}
				local empty2 = {}
				local empty3 = {}
				
				arrow_prop_mod_globals.group_arrow_properties = false
				if (playerid == 1) then
					players,empty = findallfeature(nil,"is","you")

					local players_tt,empty_tt = do_directional_you(dir_)
					for i,v in ipairs(players_tt) do
						table.insert(players, v)
					end
					for i,v in ipairs(empty_tt) do
						table.insert(empty, v)
					end

				elseif (playerid == 2) then
					players,empty = findallfeature(nil,"is","you2")

					local players_tt,empty_tt = do_directional_you2(dir_)
					for i,v in ipairs(players_tt) do
						table.insert(players, v)
					end
					for i,v in ipairs(empty_tt) do
						table.insert(empty, v)
					end
					
					if (#players == 0) then
						players,empty = findallfeature(nil,"is","you")

						players_tt,empty_tt = do_directional_you(dir_)
						for i,v in ipairs(players_tt) do
							table.insert(players, v)
						end
						for i,v in ipairs(empty_tt) do
							table.insert(empty, v)
						end
					end
				elseif (playerid == 3) then
					players,empty = findallfeature(nil,"is","you")
					players2,empty2 = findallfeature(nil,"is","you2")
					
					local playersdir = {}
					local emptydir = {}
					local players2dir = {}
					local empty2dir = {}
					playersdir, emptydir, players2dir, empty2dir = do_directional_you_auto(dir_, dir_2)
					for i,v in ipairs(playersdir) do
						table.insert(players, v)
					end
					for i,v in ipairs(emptydir) do
						table.insert(empty, v)
					end
					for i,v in ipairs(players2dir) do
						table.insert(players2, v)
					end
					for i,v in ipairs(empty2dir) do
						table.insert(empty2, v)
					end
					
					for i,v in ipairs(players2) do
						table.insert(players, v)
					end
					
					for i,v in ipairs(empty2) do
						table.insert(empty, v)
					end
				end
				arrow_prop_mod_globals.group_arrow_properties = true
				
				
				if (featureindex["3d"] ~= nil) then
					players3,empty3 = findallfeature(nil,"is","3d")
				end
				
				local fdir = 4
				
				for i,v in ipairs(players) do
					local sleeping = false
					
					fdir = dir_
					
					if (playerid == 3) then
						if (i > #players - #players2) then
							fdir = dir_2
						end
					end
					
					if (v ~= 2) then
						local unit = mmf.newObject(v)
						
						local unitname = getname(unit)
						local sleep = hasfeature(unitname,"is","sleep",v)
						local still = cantmove(unitname,v,fdir)
						
						if (sleep ~= nil) then
							sleeping = true
						elseif still then
							sleeping = true
							
							if (fdir ~= 4) then
								updatedir(v, fdir)
							end
						else
							
							if (fdir ~= 4) then
								updatedir(v, fdir)
							end
						end
					else
						local thisempty = empty[i]
						
						for a,b in pairs(thisempty) do
							local x = a % roomsizex
							local y = math.floor(a / roomsizex)
							
							local sleep = hasfeature("empty","is","sleep",2,x,y)
							local still = cantmove("empty",2,fdir,x,y)
							
							if (sleep ~= nil) or still then
								thisempty[a] = nil
							end
						end
					end
					
					if (sleeping == false) and (fdir ~= 4) then
						if (been_seen[v] == nil) then
							local x,y = -1,-1
							if (v ~= 2) then
								local unit = mmf.newObject(v)
								x,y = unit.values[XPOS],unit.values[YPOS]
								
								table.insert(moving_units, {unitid = v, reason = "you", state = 0, moves = 1, dir = fdir, xpos = x, ypos = y})
								been_seen[v] = #moving_units
							else
								local thisempty = empty[i]
								
								for a,b in pairs(thisempty) do
									x = a % roomsizex
									y = math.floor(a / roomsizex)
								
									table.insert(moving_units, {unitid = 2, reason = "you", state = 0, moves = 1, dir = fdir, xpos = x, ypos = y})
									been_seen[v] = #moving_units
								end
							end
						else
							local id = been_seen[v]
							local this = moving_units[id]
							--this.moves = this.moves + 1
						end
					end
				end
				
				fdir = 4
				
				if (featureindex["3d"] ~= nil) and (spritedata.values[CAMTARGET] ~= 0) and (spritedata.values[CAMTARGET] ~= 0.5) and (no3d == false) then
					local sleeping = false
					local domove = false
					local turndir = 0
					local ox,oy = 0,0
					
					local v = MF_getfixed(spritedata.values[CAMTARGET]) or 0
					
					if (v ~= 2) and (v ~= 0) then
						local unit = mmf.newObject(v)
						
						local udir = unit.values[DIR]
						local ndrs = ndirs[udir + 1]
						ox,oy = ndrs[1],ndrs[2]
						
						if (dir_ == 1) then
							domove = true
						elseif (dir_ == 0) then
							turndir = -1
						elseif (dir_ == 2) then
							turndir = 1
						end
			
						fdir = (udir + turndir + 4) % 4
						
						local unitname = getname(unit)
						local sleep = hasfeature(unitname,"is","sleep",v)
						local still = cantmove(unitname,v,fdir)
						
						if (sleep ~= nil) then
							sleeping = true
						elseif still then
							sleeping = true
							
							if (fdir ~= 4) then
								updatedir(v, fdir)
							end
						else
							if (fdir ~= 4) then
								updatedir(v, fdir)
							end
						end
					
						if (sleeping == false) and (fdir ~= 4) and domove then
							if (been_seen[v] == nil) then
								local x,y = -1,-1
								if (v ~= 2) then
									local unit = mmf.newObject(v)
									x,y = unit.values[XPOS],unit.values[YPOS]
									
									table.insert(moving_units, {unitid = v, reason = "you", state = 0, moves = 1, dir = fdir, xpos = x, ypos = y})
									been_seen[v] = #moving_units
								end
							else
								local id = been_seen[v]
								local this = moving_units[id]
								--this.moves = this.moves + 1
							end
						end
					end
				end
			end
			
			if (take == 2) then
				local movers,mempty = findallfeature(nil,"is","move")
				moving_units,been_seen = add_moving_units("move",movers,moving_units,been_seen,mempty)
				
				local amovers,aempty = findallfeature(nil,"is","auto")
				moving_units,been_seen = add_moving_units("auto",amovers,moving_units,been_seen,aempty)
				
				local chillers,cempty = findallfeature(nil,"is","chill")
				moving_units,been_seen = add_moving_units("chill",chillers,moving_units,been_seen,cempty)
			elseif (take == 3) then
				local nudges1,nempty1 = findallfeature(nil,"is","nudgeright")
				moving_units,been_seen = add_moving_units("nudgeright",nudges1,moving_units,been_seen,nempty1)
				
				if (#moving_units == 0) then
					skiptake = true
				end
			elseif (take == 4) then
				local nudges2,nempty2 = findallfeature(nil,"is","nudgeup")
				moving_units,been_seen = add_moving_units("nudgeup",nudges2,moving_units,been_seen,nempty2)
				
				if (#moving_units == 0) then
					skiptake = true
				end
			elseif (take == 5) then
				local nudges3,nempty3 = findallfeature(nil,"is","nudgeleft")
				moving_units,been_seen = add_moving_units("nudgeleft",nudges3,moving_units,been_seen,nempty3)
				
				if (#moving_units == 0) then
					skiptake = true
				end
			elseif (take == 6) then
				local nudges4,nempty4 = findallfeature(nil,"is","nudgedown")
				moving_units,been_seen = add_moving_units("nudgedown",nudges4,moving_units,been_seen,nempty4)
				
				if (#moving_units == 0) then
					skiptake = true
				end
			elseif (take == 7) then
				local fears = getunitverbtargets("fear")
				
				for i,v in ipairs(fears) do
					local fearname = v[1]
					local fearlist = v[2]
					
					for a,b in ipairs(fearlist) do
						local sleeping = false
						local uid = b[1]
						local feartargets = b[2]
						local valid,feardir = false,4
						local amount = #feartargets
						
						if (fearname ~= "empty") then
							valid,feardir,amount = findfears(uid,feartargets)
						else
							local x = math.floor(uid % roomsizex)
							local y = math.floor(uid / roomsizex)
							valid,feardir = findfears(2,feartargets,x,y)
						end
						
						if valid and (amount > 0) then
							if (fearname ~= "empty") then
								local unit = mmf.newObject(uid)
							
								local unitname = getname(unit)
								local sleep = hasfeature(unitname,"is","sleep",uid)
								local still = cantmove(unitname,uid,feardir)
								
								if (sleep ~= nil) then
									sleeping = true
								elseif still then
									sleeping = true
									updatedir(uid,feardir)
								else
									updatedir(uid,feardir)
								end
							else
								local x = uid % roomsizex
								local y = math.floor(uid / roomsizex)
								
								local sleep = hasfeature("empty","is","sleep",2,x,y)
								local still = cantmove("empty",2,feardir,x,y)
								
								if (sleep ~= nil) or still then
									sleeping = true
								end
							end
							
							local bsid = uid
							if (fearname == "empty") then
								bsid = uid + 200
							end
							
							if (sleeping == false) then
								if (been_seen[bsid] == nil) then
									local x,y = -1,-1
									if (fearname ~= "empty") then
										local unit = mmf.newObject(uid)
										x,y = unit.values[XPOS],unit.values[YPOS]
										
										table.insert(moving_units, {unitid = uid, reason = "fear", state = 0, moves = amount, dir = feardir, xpos = x, ypos = y})
										been_seen[bsid] = #moving_units
									else
										x = uid % roomsizex
										y = math.floor(uid / roomsizex)
									
										table.insert(moving_units, {unitid = 2, reason = "fear", state = 0, moves = amount, dir = feardir, xpos = x, ypos = y})
										been_seen[bsid] = #moving_units
									end
								else
									local id = been_seen[bsid]
									local this = moving_units[id]
									this.moves = this.moves + 1
								end
							end
						end
					end
				end
			elseif (take == 8) then
				if enable_directional_shift then
					--@Turning Text(shift)
					do_directional_shift_parsing(moving_units, been_seen, roomsizex)
				else
					local shifts = findallfeature(nil,"is","shift",true)
					
					for i,v in ipairs(shifts) do
						if (v ~= 2) then
							local affected = {}
							local unit = mmf.newObject(v)
							
							local x,y = unit.values[XPOS],unit.values[YPOS]
							local tileid = x + y * roomsizex
							
							if (unitmap[tileid] ~= nil) then
								if (#unitmap[tileid] > 1) then
									for a,b in ipairs(unitmap[tileid]) do
										if (b ~= v) and floating(b,v,x,y) then
										
											--updatedir(b, unit.values[DIR])
											
											if (isstill_or_locked(b,x,y,unit.values[DIR]) == false) then
												if (been_seen[b] == nil) then
													table.insert(moving_units, {unitid = b, reason = "shift", state = 0, moves = 1, dir = unit.values[DIR], xpos = x, ypos = y})
													been_seen[b] = #moving_units
												else
													local id = been_seen[b]
													local this = moving_units[id]
													this.moves = this.moves + 1
												end
											end
										end
									end
								end
							end
						end
					end
				end
				
				if enable_directional_shift then
					do_directional_shift_level_parsing(moving_units, been_seen, mapdir)
				else
					local levelshift = findfeature("level","is","shift")
					
					if (levelshift ~= nil) then
						local leveldir = mapdir
						local valid = false
						
						for a,b in ipairs(levelshift) do
							if (valid == false) and testcond(b[2],1) then
								valid = true
							end
						end
						
						if valid then
							for a,unit in ipairs(units) do
								local x,y = unit.values[XPOS],unit.values[YPOS]
								
								if floating_level(unit.fixed) then
									updatedir(unit.fixed, leveldir)
									
									if (isstill_or_locked(unit.fixed,x,y,leveldir) == false) and (issleep(unit.fixed,x,y) == false) then
										table.insert(moving_units, {unitid = unit.fixed, reason = "shift", state = 0, moves = 1, dir = unit.values[DIR], xpos = x, ypos = y})
									end
								end
							end
						end
					end
				end
			end
		else
			for i,data in ipairs(still_moving) do
				if (data.unitid ~= 2) then
					local unit = mmf.newObject(data.unitid)
					
					if enable_directional_shift and data.reason == "shift" then
						--@Turning Text(shift)
						table.insert(moving_units, {
							unitid = data.unitid, 
							reason = data.reason, 
							state = data.state, 
							moves = data.moves, 
							dir = data.dir, 
							xpos = unit.values[XPOS], 
							ypos = unit.values[YPOS],

							horsdir = data.horsdir,
							vertdir = data.vertdir,
							horsmove = data.horsmove,
							vertmove = data.vertmove,
							dirshiftstate = data.dirshiftstate
						})
					else
						table.insert(moving_units, {unitid = data.unitid, reason = data.reason, state = data.state, moves = data.moves, dir = unit.values[DIR], xpos = unit.values[XPOS], ypos = unit.values[YPOS]})
					end
				else
					-- MF_alert("Still moving: " .. tostring(data.xpos) .. ", " .. tostring(data.ypos) .. ", " .. tostring(data.moves))
					table.insert(moving_units, {unitid = data.unitid, reason = data.reason, state = data.state, moves = data.moves, dir = data.dir, xpos = data.xpos, ypos = data.ypos})
				end
			end
			
			still_moving = {}
		end

		add_moving_units_to_exclude_from_cut_blocking(moving_units)
		
		local unitcount = #moving_units
		local done = false
		local state = 0
		
		if skiptake then
			done = true
		end

		if enable_directional_shift and (finaltake == false) and (take == 8) then
			--@Turning Text(shift)
			moving_units = do_directional_shift_resolve_stacked_shifts(moving_units)
		end
		
		while (done == false) and (skiptake == false) and (debug_moves < movelimit) do
			local smallest_state = 99
			local delete_moving_units = {}
			
			for i,data in ipairs(moving_units) do
				local solved = false
				local skipthis = false
				smallest_state = math.min(smallest_state,data.state)
				
				if (data.unitid == 0) then
					solved = true
				end
				
				if (data.state == state) and (data.moves > 0) and (data.unitid ~= 0) then
					local unit = {}
					local dir,name = 4,""
					local x,y = data.xpos,data.ypos
					local holder = 0
					
					if (data.unitid ~= 2) then
						unit = mmf.newObject(data.unitid)
						dir = unit.values[DIR]
						name = getname(unit)
						x,y = unit.values[XPOS],unit.values[YPOS]
						holder = unit.holder or 0
					else
						dir = data.dir
						name = "empty"
					end
					
					debug_moves = debug_moves + 1
					
					--MF_alert(name .. " (" .. tostring(data.unitid) .. ") doing " .. data.reason .. ", take " .. tostring(take) .. ", state " .. tostring(state) .. ", moves " .. tostring(data.moves) .. ", dir " .. tostring(dir))
					
					if (x ~= -1) and (y ~= -1) and (holder == 0) then
						local result = -1
						solved = false
						
						if (state == 0) then
							if (data.unitid == 2) and (((data.reason == "move") and (dir == 4)) or (data.reason == "chill")) then
								data.dir = fixedrandom(0,3)
								dir = data.dir
								
								if cantmove(name,data.unitid,dir,x,y) then
									skipthis = true
								end
							end
						elseif (state == 3) then
							if ((data.reason == "move") or (data.reason == "chill")) then
								local newdir_ = rotate(dir)
								
								if (cantmove(name,data.unitid,newdir_,x,y) == false) then
									dir = newdir_
								end
								
								if (data.unitid ~= 2) and (unit.flags[DEAD] == false) then
									updatedir(data.unitid, newdir_)
									--unit.values[DIR] = dir
									
									if cantmove(name,data.unitid,newdir_,x,y) then
										skipthis = true
									end
								end
							end
						end

						--@Turning Text(shift)
						if enable_directional_shift and data.reason == "shift" and data.unitid ~= 2 then
							-- if data.state == 0 then
							do_directional_shift_update_shift_state(data, false)
							-- end
							dir = data.dir
						end

						if (state == 0) and (data.reason == "shift") and (data.unitid ~= 2) then
							updatedir(data.unitid, data.dir)
							dir = data.dir
						end
						
						if (dir == 4) then
							dir = fixedrandom(0,3)
						end
						
						local olddir = dir
						local returnolddir = false
						
						if (data.reason == "nudgeright") then
							dir = 0
							returnolddir = true
						elseif (data.reason == "nudgeup") then
							dir = 1
							returnolddir = true
						elseif (data.reason == "nudgeleft") then
							dir = 2
							returnolddir = true
						elseif (data.reason == "nudgedown") then
							dir = 3
							returnolddir = true
						end
						
						if (featureindex["reverse"] ~= nil) then
							local revdir = reversecheck(data.unitid,dir,x,y)
							if (revdir ~= dir) then
								dir = revdir
								returnolddir = true
							end
						end
						
						--MF_alert(data.reason)
						
						local newdir = dir
						
						local ndrs = ndirs[dir + 1]
						
						if (ndrs == nil) then
							MF_alert("dir is invalid: " .. tostring(dir) .. ", " .. tostring(name))
						end
						
						local ox,oy = ndrs[1],ndrs[2]
						local pushobslist = {}
						
						splice_mod_globals.record_packed_text = true
						local obslist,allobs,specials = check(data.unitid,x,y,dir,false,data.reason)
						splice_mod_globals.record_packed_text = false
						local pullobs,pullallobs,pullspecials = check(data.unitid,x,y,dir,true,data.reason)
						
						if returnolddir then
							dir = olddir
						end
						
						arrow_prop_mod_globals.group_arrow_properties = false
						local swap = hasfeature(name,"is","swap",data.unitid,x,y)
						local still = cantmove(name,data.unitid,newdir,x,y)
						arrow_prop_mod_globals.group_arrow_properties = true

						--@Turning Text(SWAP)
						if not swap then
							swap = do_directional_swap_hasfeature(dir, name, data.unitid, x, y)
						end
						------------------------------------
						
						if returnolddir then
							dir = newdir
							
							--MF_alert(tostring(olddir) .. ", " .. tostring(newdir))
						end
						
						for c,obs in pairs(obslist) do
							if (solved == false) then
								if (obs == 0) then
									if (state == 0) then
										result = math.max(result, 0)
									else
										result = math.max(result, 0)
									end
								elseif (obs == -1) then
									result = math.max(result, 2)
									
									arrow_prop_mod_globals.group_arrow_properties = false
									local levelpush_ = findfeature("level","is","push")
									arrow_prop_mod_globals.group_arrow_properties = true
									
									if (levelpush_ ~= nil) then
										for e,f in ipairs(levelpush_) do
											if testcond(f[2],1) then
												levelpush = dir
											end
										end
									end
									
									--@Turning Text(PUSH)
									if levelpush < 0 then
										levelpush = do_directional_level_pushpull(dir, false)
									end
									-----------------
								else
									if (swap == nil) or still then
										if (#allobs == 0) then
											obs = 0
										end
										
										if (obs == 1) then
											local thisobs = allobs[c]
											local solid = true
											
											for f,g in pairs(specials) do
												if (g[1] == thisobs) and (g[2] == "weak") then
													solid = false
													obs = 0
													result = math.max(result, 0)
												end
											end
											
											if solid then
												if (state < 2) then
													data.state = math.max(data.state, 2)
													result = math.max(result, 2)
												else
													result = math.max(result, 2)
												end
											end
										else
											if (state < 1) then
												data.state = math.max(data.state, 1)
												result = math.max(result, 1)
											else
												table.insert(pushobslist, obs)
												result = math.max(result, 1)
											end
										end
									else
										result = math.max(result, 0)
									end
								end
							end
						end
						
						if (skipthis == false) then
							local result_check = false
							
							while (result_check == false) and (solved == false) do
								if (result == 0) then
									if (state > 0) then
										for j,jdata in pairs(moving_units) do
											if (jdata.state >= 2) and (jdata.state ~= 10) then
												jdata.state = 0
											end
										end
									end
									
									table.insert(movelist, {data.unitid,ox,oy,olddir,specials,x,y})
									if (data.unitid == 2) and (data.moves > 1) then
										data.xpos = x + ox
										data.ypos = y + oy
										data.dir = dir
									end
									--move(data.unitid,ox,oy,dir,specials)
									
									local swapped = {}
									
									if (swap ~= nil) and (still == false) then
										for a,b in ipairs(allobs) do
											if (b ~= -1) and (b ~= 2) and (b ~= 0) then
												local swapunit = mmf.newObject(b)
												local swapname = getname(swapunit)
												
												local obsstill = hasfeature(swapname,"is","still",b,x+ox,y+oy)
												
												if (obsstill == nil) then
													addaction(b,{"update",x,y,nil})
													swapped[b] = 1
												end
											end
										end
									end
									
									arrow_prop_mod_globals.group_arrow_properties = false
									local swaps = findfeatureat(nil,"is","swap",x+ox,y+oy,{"still"})
									arrow_prop_mod_globals.group_arrow_properties = true
									
									-- @Turning Text(SWAP) ---------------------------------
									local arrow_swap_units = do_directional_swap_findfeatureat(dir, swaps, x, y, ox, oy)
									if #arrow_swap_units > 0 then
										if swaps == nil then
											swaps = arrow_swap_units
										else
											for i,unit in ipairs(arrow_swap_units) do
												table.insert(swaps, unit)
											end
										end
									end
									-------------------------------------------------
									
									if (swaps ~= nil) then
										for a,b in ipairs(swaps) do
											if (swapped[b] == nil) and (b ~= 2) then
												addaction(b,{"update",x,y,nil})
											end
										end
									end
									
									local finalpullobs = {}
									
									for c,pobs in ipairs(pullobs) do
										if (pobs < -1) or (pobs > 1) then
											local paobs = pullallobs[c]
											local hm = 0
											
											if (paobs ~= 2) then
												hm = trypush(paobs,ox,oy,dir,true,x,y,data.reason,data.unitid)
											else
												hm = trypush(paobs,ox,oy,dir,true,x-ox,y-oy,data.reason,data.unitid)
											end
											
											if (hm == 0) then
												table.insert(finalpullobs, paobs)
											end
										elseif (pobs == -1) then
											arrow_prop_mod_globals.group_arrow_properties = false
											local levelpull_ = findfeature("level","is","pull")
											arrow_prop_mod_globals.group_arrow_properties = true
										
											if (levelpull_ ~= nil) then
												for e,f in ipairs(levelpull_) do
													if testcond(f[2],1) then
														levelpull = dir
													end
												end
											end

											-- @Turning Text(PULL)
											if levelpull < 0 then
												levelpull = do_directional_level_pushpull(dir, true)
											end
											------------------------------
										end
									end
									
									for c,pobs in ipairs(finalpullobs) do
										pushedunits = {}
										
										if (pobs ~= 2) then
											dopush(pobs,ox,oy,dir,true,x,y,data.reason,data.unitid)
										else
											dopush(pobs,ox,oy,dir,true,x-ox,y-oy,data.reason,data.unitid)
										end
									end
									
									solved = true
								elseif (result == 1) then
									if (state < 1) then
										data.state = math.max(data.state, 1)
										result_check = true
									else
										local finalpushobs = {}
										
										for c,pushobs in ipairs(pushobslist) do
											local hm = 0
											if (pushobs ~= 2) then
												hm = trypush(pushobs,ox,oy,dir,false,x,y,data.reason)
											else
												hm = trypush(pushobs,ox,oy,dir,false,x+ox,y+oy,data.reason)
											end
											
											if (hm == 0) then
												table.insert(finalpushobs, pushobs)
											elseif (hm == 1) or (hm == -1) then
												result = math.max(result, 2)
											else
												MF_alert("HOO HAH")
												return
											end
										end
										
										if (result == 1) then
											for c,pushobs in ipairs(finalpushobs) do
												pushedunits = {}
												
												if (pushobs ~= 2) then
													dopush(pushobs,ox,oy,dir,false,x,y,data.reason)
												else
													dopush(pushobs,ox,oy,dir,false,x+ox,y+oy,data.reason)
												end
											end
											result = 0
										end
									end
								elseif (result == 2) then
									if (state < 2) then
										data.state = math.max(data.state, 2)
										result_check = true
									else
										if (state < 3) then
											data.state = math.max(data.state, 3)
											result_check = true
										else
											if ((data.reason == "move") or (data.reason == "chill")) and (state < 4) then
												data.state = math.max(data.state, 4)
												result_check = true
											else
												local weak = hasfeature(name,"is","weak",data.unitid,x,y)
												
												if (weak ~= nil) and (issafe(data.unitid,x,y) == false) then
													delete(data.unitid,x,y)
													generaldata.values[SHAKE] = 3
													
													local pmult,sound = checkeffecthistory("weak")
													MF_particles("destroy",x,y,5 * pmult,0,3,1,1)
													setsoundname("removal",1,sound)
													data.moves = 1
												end
												solved = true
											end
										end
									end
								else
									result_check = true
								end
							end
						else
							solved = true
						end
					else
						solved = true
					end
				end

				if solved then
					data.moves = data.moves - 1

					if enable_directional_shift and data.reason == "shift" and data.unitid ~= 2 then
						do_directional_shift_update_shift_state(data, true)
					end
					
					if (state > 0) then
						data.state = 10
					end
					
					-- MF_alert("(" .. tostring(data.unitid) .. ") solved, " .. data.reason .. ", t " .. tostring(take) .. ", s " .. tostring(data.state) .. ", m " .. tostring(data.moves) .. ", " .. tostring(data.xpos) .. ", " .. tostring(data.ypos))
					
					if (data.moves == 0) then
						--MF_alert(tunit.strings[UNITNAME] .. " - removed from queue")
						table.insert(delete_moving_units, i)
					else
						if enable_directional_shift then
							--@Turning Text(shift)
							table.insert(still_moving, {
								unitid = data.unitid, 
								reason = data.reason, 
								state = data.state, 
								moves = data.moves, 
								dir = data.dir, 
								xpos = data.xpos, 
								ypos = data.ypos,

								horsdir = data.horsdir,
								vertdir = data.vertdir,
								horsmove = data.horsmove,
								vertmove = data.vertmove,
								dirshiftstate = data.dirshiftstate
							})
						else
							table.insert(still_moving, {unitid = data.unitid, reason = data.reason, state = data.state, moves = data.moves, dir = data.dir, xpos = data.xpos, ypos = data.ypos})
						end
						
						--MF_alert(tunit.strings[UNITNAME] .. " - removed from queue")
						table.insert(delete_moving_units, i)
					end
				end
			end
			
			local deloffset = 0
			for i,v in ipairs(delete_moving_units) do
				local todel = v - deloffset
				table.remove(moving_units, todel)
				deloffset = deloffset + 1
			end
			
			if (#movelist > 0) then
				for i,data in ipairs(movelist) do
					move(data[1],data[2],data[3],data[4],data[5],nil,nil,data[6],data[7])
				end
			end
			
			movelist = {}
			
			if (smallest_state > state) then
				state = state + 1
			else
				state = smallest_state
			end
			
			if (#moving_units == 0) then
				doupdate()
				done = true
			else
				movemap = {}
			end
		end
		
		if (debug_moves >= movelimit) then
			HACK_INFINITY = 200
			destroylevel("toocomplex")
			return
		end

		if (#still_moving > 0) then
			finaltake = true
			moving_units = {}
		else
			finaltake = false
		end
		
		if (finaltake == false) then
			take = take + 1
		end
	end
	
	if (levelpush >= 0) then
		local ndrs = ndirs[levelpush + 1]
		local ox,oy = ndrs[1],ndrs[2]
		
		addundo({"levelupdate",Xoffset,Yoffset,Xoffset + ox * tilesize,Yoffset + oy * tilesize,mapdir,levelpush})
		
		mapdir = levelpush
		
		MF_scrollroom(ox * tilesize,oy * tilesize)
		updateundo = true
	end
	
	if (levelpull >= 0) then
		local ndrs = ndirs[levelpull + 1]
		local ox,oy = ndrs[1],ndrs[2]
		
		addundo({"levelupdate",Xoffset,Yoffset,Xoffset + ox * tilesize,Yoffset + oy * tilesize,mapdir,levelpull})
		
		mapdir = levelpull
		
		MF_scrollroom(ox * tilesize,oy * tilesize)
		updateundo = true
	end
	
	if (HACK_MOVES >= 10000) then
		HACK_MOVES = 0
		HACK_INFINITY = 200
		destroylevel("infinity")
		return
	end
	
	doupdate()
	code()
	conversion()
	doupdate()
	code()
	moveblock()
	
	-- @ Turning text
	code()
	turning_text_mod_globals.tt_executing_code = true
	final_turning_unit_dir = {}
	finalize_turning_text_dir()
	code()
	final_turning_unit_dir = {}
	turning_text_mod_globals.tt_executing_code = false
	-- @ Turning text
	
	if (dir_ ~= nil) then
		mapcursor_move(ox,oy,dir_)
	end
	
	if (#units > 0) and (no3d == false) then
		local vistest,vt2 = findallfeature(nil,"is","3d",true)
		if (#vistest > 0) or (#vt2 > 0) then
			local target = vistest[1] or vt[1]
			visionmode(1)
		elseif (spritedata.values[VISION] == 1) then
			local vistest2 = findfeature(nil,"is","3d")
			if (vistest2 == nil) then
				visionmode(0)
			end
		end
	end

end

function move(unitid,ox,oy,dir,specials_,instant_,simulate_,x_,y_)
	--[[ 
		@mods(text splicing) - Override reason - handle actually cutting text into letterunits
	 ]]
	local instant = instant_ or false
	local simulate = simulate_ or false
	
	local x,y = 0,0
	local unit = {}
	
	if (unitid ~= 2) then
		unit = mmf.newObject(unitid)
		x,y = unit.values[XPOS],unit.values[YPOS]
	else
		x = x_
		y = y_
	end
	
	local specials = {}
	if (specials_ ~= nil) then
		specials = specials_
	end
	
	local gone = false
	for i,v in pairs(specials) do
		if (gone == false) then
			local b = v[1]
			local reason = v[2]
			local dodge = false

			local bx,by = 0,0
			if (b ~= 2) and (deleted[b] ~= nil) then
				MF_alert("Already gone")
				dodge = true
			elseif (b ~= 2) and (reason ~= "weak") then
				local bunit = mmf.newObject(b)
				bx,by = bunit.values[XPOS],bunit.values[YPOS]
				
				if (bx ~= x+ox) or (by ~= y+oy) then
					dodge = true
				else
					for c,d in ipairs(movelist) do
						if (d[1] == b) then
							local nx,ny = d[2],d[3]
							
							--print(tostring(nx) .. "," .. tostring(ny) .. " --> " .. tostring(x+ox) .. "," .. tostring(y+oy) .. " (" .. tostring(bx) .. "," .. tostring(by) .. ")")
							if (nx ~= x+ox) or (ny ~= y+oy) then
								dodge = true
							end
						end
					end
				end
			else
				bx,by = x+ox,y+oy
			end

			if (dodge == false) then
				if (reason == "lock") then
					local unlocked = false
					local valid = true
					local soundshort = ""
					
					if (b ~= 2) then
						local bunit = mmf.newObject(b)
						
						if bunit.flags[DEAD] then
							valid = false
						end
					end
					
					if (unitid ~= 2) and unit.flags[DEAD] then
						valid = false
					end
					
					if valid then
						local pmult = 1.0
						local effect1 = false
						local effect2 = false
						
						if (issafe(b,bx,by) == false) then
							delete(b,bx,by)
							unlocked = true
							effect1 = true
						end
						
						if (issafe(unitid,x,y) == false) then
							delete(unitid,x,y)
							unlocked = true
							gone = true
							effect2 = true
						end
						
						if effect1 or effect2 then
							local pmult,sound = checkeffecthistory("unlock")
							soundshort = sound
						end
						
						if effect1 then
							MF_particles("unlock",bx,by,15 * pmult,2,4,1,1)
							generaldata.values[SHAKE] = 8
						end
						
						if effect2 then
							MF_particles("unlock",x,y,15 * pmult,2,4,1,1)
							generaldata.values[SHAKE] = 8
						end
					end
					
					if unlocked then
						setsoundname("turn",7,soundshort)
					end
				elseif (reason == "eat") then
					local pmult,sound = checkeffecthistory("eat")
					MF_particles("eat",bx,by,10 * pmult,0,3,1,1)
					generaldata.values[SHAKE] = 3
					delete(b,bx,by)
					
					setsoundname("removal",1,sound)
				elseif (reason == "weak") then
					if (b == 2) and (unitid ~= 2) then
						local pmult,sound = checkeffecthistory("weak")
						MF_particles("destroy",bx,by,5 * pmult,0,3,1,1)
						generaldata.values[SHAKE] = 3
						delete(b,bx,by)
						
						setsoundname("removal",1,sound)
					end
				elseif reason == "cut" then
					if b == 2 then
						handle_text_cutting(v[3], dir)
					else
						handle_text_cutting(v[3], dir)
					end
				elseif reason == "pack" then
					handle_text_packing(b, dir, v[3])
				end
			end

			--@mods(guard) - if "keke guard rock is weak" and baba pushes rock into a wall, baba should not walk into the rock's space 
			-- if the rock gets guarded by keke.
			if is_unit_saved_by_guard(b, x, y) then
				gone = true
			end
		end
	end
	
	if (gone == false) and (simulate == false) and (unitid ~= 2) then
		if instant then
			update(unitid,x+ox,y+oy,dir)
			MF_alert("Instant movement on " .. tostring(unitid))
		else
			addaction(unitid,{"update",x+ox,y+oy,dir})
		end
		
		if unit.visible and (#movelist < 700) and (spritedata.values[VISION] == 0) then
			if (generaldata.values[DISABLEPARTICLES] == 0) and (generaldata5.values[LEVEL_DISABLEPARTICLES] == 0) then
				local effectid = MF_effectcreate("effect_bling")
				local effect = mmf.newObject(effectid)
				
				local midxdelta = spritedata.values[XMIDTILE] - roomsizex * 0.5
				local midydelta = spritedata.values[YMIDTILE] - roomsizey * 0.5
				local midx = roomsizex * 0.5 + midxdelta * generaldata2.values[ZOOM]
				local midy = roomsizey * 0.5 + midydelta * generaldata2.values[ZOOM]
				local mx = x - midx
				local my = y - midy
				
				local c1,c2 = 0,0
				
				if (unit.colour ~= nil) and (unit.colour[1] ~= nil) and (unit.colour[2] ~= nil) then
					c1 = unit.colour[1]
					c2 = unit.colour[2]
				else
					if (unit.active == false) then
						c1,c2 = getcolour(unitid)
					else
						c1,c2 = getcolour(unitid,"active")
					end
				end
				-- c1 = 0
				-- c2 = 3
				MF_setcolour(effectid,c1,c2)
				
				local xvel,yvel = 0,0
				
				if (ox ~= 0) then
					xvel = 0 - ox / math.abs(ox)
				end
				
				if (oy ~= 0) then
					yvel = 0 - oy / math.abs(oy)
				end
				
				local dx = mx + 0.5
				local dy = my + 0.75
				local dxvel = xvel
				local dyvel = yvel
				
				if (generaldata2.values[ROOMROTATION] == 90) then
					dx = my + 0.75
					dy = 0 - mx - 0.5
					dxvel = yvel
					dyvel = 0 - xvel
				elseif (generaldata2.values[ROOMROTATION] == 180) then
					dx = 0 - mx - 0.5
					dy = 0 - my - 0.75
					dxvel = 0 - xvel
					dyvel = 0 - yvel
				elseif (generaldata2.values[ROOMROTATION] == 270) then
					dx = 0 - my - 0.75
					dy = mx + 0.5
					dxvel = 0 - yvel
					dyvel = xvel
				end
				
				effect.values[ONLINE] = 3
				effect.values[XPOS] = Xoffset + (midx + (dx) * generaldata2.values[ZOOM]) * tilesize * spritedata.values[TILEMULT]
				effect.values[YPOS] = Yoffset + (midy + (dy) * generaldata2.values[ZOOM]) * tilesize * spritedata.values[TILEMULT]
				effect.scaleX = generaldata2.values[ZOOM] * spritedata.values[TILEMULT]
				effect.scaleY = generaldata2.values[ZOOM] * spritedata.values[TILEMULT]
				
				effect.values[XVEL] = dxvel * math.random(10,30) * 0.1 * spritedata.values[TILEMULT] * generaldata2.values[ZOOM]
				effect.values[YVEL] = dyvel * math.random(10,30) * 0.1 * spritedata.values[TILEMULT] * generaldata2.values[ZOOM]
			end
			
			if (unit.values[TILING] == 2) then
				unit.values[VISUALDIR] = ((unit.values[VISUALDIR] + 1) + 4) % 4
			end
		end
	end
	
	return gone
end

function check(unitid,x,y,dir,pulling_,reason)
	--[[ 
		@mods(turning text) - Override reason: directional push/pull/swap/stop
		@mods(text splicing) - Override reason - add collision check for "cut"
	 ]]
	local pulling = false
	if (pulling_ ~= nil) then
		pulling = pulling_
	end
	
	local dirfeaturevalue = dir
	local dir_ = dir
	if pulling then
		dir_ = rotate(dir)
	end
	
	local ndrs = ndirs[dir_ + 1]
	local ox,oy = ndrs[1],ndrs[2]
	
	local result = {}
	local results = {}
	local specials = {}
	local unit = {}
	local name = ""
	
	if (unitid ~= 2) then
		unit = mmf.newObject(unitid)
		name = getname(unit)
	else
		name = "empty"
	end
	
	local lockpartner = ""
	local open = hasfeature(name,"is","open",unitid,x,y)
	local shut = hasfeature(name,"is","shut",unitid,x,y)
	local eat = hasfeature(name,"eat",nil,unitid,x,y)
	local phantom = hasfeature(name,"is","phantom",unitid,x,y)
	local cut = hasfeature(name,"is","cut",unitid,x,y)
	local pack = hasfeature(name,"is","pack",unitid,x,y)
	
	if pulling then
		phantom = nil
	end
	
	if (open ~= nil) then
		lockpartner = "shut"
	elseif (shut ~= nil) then
		lockpartner = "open"
	end
	
	local obs = findobstacle(x+ox,y+oy)
	local queued_pack_specials = {}
	
	if (#obs > 0) and (phantom == nil) then
		for i,id in ipairs(obs) do
			if (id == -1) then
				table.insert(result, -1)
				table.insert(results, -1)

				if reason ~= "pack" then
					if hasfeature("level","is","pack", 1) then
						local data = check_text_packing(-1, unitid, rotate(dir), pulling, true)
						if data then
							table.insert(specials, {-1, "pack", data})
							result = {0}
							results = {0}
						end
					end
				end
			else
				local obsunit = mmf.newObject(id)
				local obsname = getname(obsunit)
				
				local alreadymoving = findupdate(id,"update")
				local valid = true
				
				local localresult = 0
				
				if (#alreadymoving > 0) then
					for a,b in ipairs(alreadymoving) do
						local nx,ny = b[3],b[4]
						
						if ((nx ~= x) and (ny ~= y)) and ((reason == "shift") and (pulling == false)) then
							valid = false
						end
						
						if ((nx == x) and (ny == y + oy * 2)) or ((ny == y) and (nx == x + ox * 2)) then
							valid = false
						end
					end
				end
				
				if (lockpartner ~= "") and (pulling == false) then
					local partner = hasfeature(obsname,"is",lockpartner,id,x+ox,y+oy)
					
					if (partner ~= nil) and ((issafe(id,x+ox,y+oy) == false) or (issafe(unitid,x,y) == false)) and floating(id,unitid,x+ox,y+oy) then
						valid = false
						table.insert(specials, {id, "lock"})
					end
				end
				
				if (eat ~= nil) and (pulling == false) then
					local eats = hasfeature(name,"eat",obsname,unitid,x+ox,y+oy)
					
					if (eats ~= nil) and (issafe(id,x+ox,y+oy) == false) and floating(id,unitid,x+ox,y+oy) then
						valid = false
						table.insert(specials, {id, "eat"})
					end
				end
				
				local weak = hasfeature(obsname,"is","weak",id,x+ox,y+oy)
				if (weak ~= nil) and (pulling == false) then
					if (issafe(id,x+ox,y+oy) == false) and floating(id,unitid,x+ox,y+oy) then
						--valid = false
						table.insert(specials, {id, "weak"})
					end
				end

				local cutdata = nil
				if cut ~= nil then
					cutdata = check_text_cutting(unitid, id, pulling) 
					if cutdata then
						valid = false
						table.insert(specials, {id, "cut", cutdata})
					end
				end
				if not cutdata then
					local obscut = hasfeature(obsname,"is","cut",id,x+ox,y+oy)
					if obscut ~= nil then
						cutdata = check_text_cutting(id, unitid, pulling, true)
						if cutdata then
							valid = false
							table.insert(specials, {id, "cut", cutdata})
						end
					end
				end
				if reason ~= "pack" then
					local data = nil
					if pack ~= nil then
						data = check_text_packing(unitid, id, dir, pulling, false, x, y)
						if data then
							valid = false
							table.insert(queued_pack_specials, {id, "pack", data})
						end
					end
					local obspack = hasfeature(obsname,"is","pack",id,x+ox,y+oy)
					if obspack ~= nil then
						local data = check_text_packing(id, unitid, rotate(dir), pulling, true, x, y)
						if data then
							valid = false
							table.insert(queued_pack_specials, {id, "pack", data})
						end
					end
				end
				
				local added = false
				
				if valid then
					--MF_alert("checking for solidity for " .. obsname .. " by " .. name .. " at " .. tostring(x) .. ", " .. tostring(y))
					arrow_prop_mod_globals.group_arrow_properties = false
					local isstop = hasfeature(obsname,"is","stop",id,x+ox,y+oy)
					local ispush = hasfeature(obsname,"is","push",id,x+ox,y+oy)
					local ispull = hasfeature(obsname,"is","pull",id,x+ox,y+oy)
					local isswap = hasfeature(obsname,"is","swap",id,x+ox,y+oy)
					local isstill = cantmove(obsname,id,dir,x+ox,y+oy)
					arrow_prop_mod_globals.group_arrow_properties = true
					
					-- @Turning Text(Push/pull/stop/swap)
					isstop, ispush, ispull = do_directional_collision(dirfeaturevalue, obsname, id, isstop, ispush, ispull, x,y,ox,oy, pulling, reason)
					if dirfeaturevalue ~= nil and dirfeaturevalue >= 0 and dirfeaturevalue <= 3 then
						local dirfeaturerotate = dirfeaturemap[rotate(dirfeaturevalue) + 1]
						if not isswap then
							isswap = hasfeature(obsname,"is","swap"..dirfeaturerotate,id,x+ox,y+oy)
						end
					end
					------------------------------------
					
					--MF_alert(obsname .. " -- stop: " .. tostring(isstop) .. ", push: " .. tostring(ispush))
					
					if (ispush ~= nil) and isstill then
						ispush = nil
						isstop = true
					end
					
					if (ispull ~= nil) and isstill then
						ispull = nil
						isstop = true
					end
					
					if (isswap ~= nil) and isstill then
						isswap = nil
					end
					
					if (isstop ~= nil) and (obsname == "level") and (obsunit.visible == false) then
						isstop = nil
					end
					
					if (((isstop ~= nil) and (ispush == nil) and ((ispull == nil) or ((ispull ~= nil) and (pulling == false)))) or ((ispull ~= nil) and (pulling == false) and (ispush == nil))) and (isswap == nil) then
						if (weak == nil) or ((weak ~= nil) and (floating(id,unitid,x+ox,y+oy) == false)) then
							table.insert(result, 1)
							table.insert(results, id)
							localresult = 1
							added = true
						end
					end
					
					if (localresult ~= 1) and (localresult ~= -1) then
						if (ispush ~= nil) and (pulling == false) and (isswap == nil) then
							--MF_alert(obsname .. " added to push list")
							table.insert(result, id)
							table.insert(results, id)
							added = true
						end
						
						if (ispull ~= nil) and pulling then
							table.insert(result, id)
							table.insert(results, id)
							added = true
						end
					end
				end
				
				if (added == false) then
					table.insert(result, 0)
					table.insert(results, id)
				end
			end
		end
	elseif (phantom == nil) then
		arrow_prop_mod_globals.group_arrow_properties = false
		local emptystop = hasfeature("empty","is","stop",2,x+ox,y+oy)
		local emptypush = hasfeature("empty","is","push",2,x+ox,y+oy)
		local emptypull = hasfeature("empty","is","pull",2,x+ox,y+oy)
		local emptyswap = hasfeature("empty","is","swap",2,x+ox,y+oy)
		local emptystill = cantmove("empty",2,dir_,x+ox,y+oy)
		arrow_prop_mod_globals.group_arrow_properties = true
		
		-- @Turning Text(Push/pull/stop/swap)
		emptystop, emptypush, emptypull = do_directional_collision(dirfeaturevalue, "empty", 2, emptystop, emptypush, emptypull, x,y,ox,oy, pulling, reason)
		if dirfeaturevalue ~= nil and dirfeaturevalue >= 0 and dirfeaturevalue <= 3 then
			local dirfeaturerotate = dirfeaturemap[rotate(dirfeaturevalue) + 1]
			if not emptyswap then
				emptyswap = hasfeature("empty","is","swap"..dirfeaturerotate,id,x+ox,y+oy)
			end
		end
		
		local localresult = 0
		local valid = true
		local bname = "empty"
		
		if (eat ~= nil) and (pulling == false) then
			local eats = hasfeature(name,"eat","empty",unitid,x+ox,y+oy)
			
			if (eats ~= nil) and (issafe(2,x+ox,y+oy) == false) and floating(unitid,2,x+ox,y+oy) then
				valid = false
				table.insert(specials, {2, "eat"})
			end
		end
		
		if (lockpartner ~= "") and (pulling == false) then
			local partner = hasfeature("empty","is",lockpartner,2,x+ox,y+oy)
			
			if (partner ~= nil) and ((issafe(2,x+ox,y+oy) == false) or (issafe(unitid,x,y) == false)) and floating(unitid,2,x+ox,y+oy) then
				valid = false
				table.insert(specials, {2, "lock"})
			end
		end
		
		local weak = hasfeature("empty","is","weak",2,x+ox,y+oy)
		if (weak ~= nil) and (pulling == false) then
			if (issafe(2,x+ox,y+oy) == false) and floating(unitid,2,x+ox,y+oy) then
				valid = false
				table.insert(specials, {2, "weak"})
			end
		end

		local cut = hasfeature("empty","is","cut",2,x+ox,y+oy)
		if (cut ~= nil) then 
			local data = check_text_cutting(2, unitid, pulling, true, x+ox,y+oy)
			-- @Note: if "text is cut" and you push a regular text onto a lettertext, the regular text doesn't do the cutting since the lettertext cannot be cut. 
			-- But in blocks.lua, the lettertext will cut the regular text. Making valid true here and not interting into specials prevents this from happening.
			-- Does it make sense intuitively to make valid = true in this specific cornercase?
			if data then
				valid = false
				table.insert(specials, {2, "cut", data})
			end
		end
		if reason ~= "pack" then
			local pack = hasfeature("empty","is","pack",2,x+ox,y+oy)
			if pack then
				local data = check_text_packing(2, unitid, rotate(dir), pulling, true, x+ox, y+oy)
				if data then
					valid = false
					table.insert(queued_pack_specials, {2, "pack", data})
				end
			end
		end
		
		local added = false
		
		if valid then
			local estop = 0
			
			if (emptyswap ~= nil) and emptystill then
				emptyswap = nil
			end
			
			if (emptypush == nil) and (emptyswap == nil) then
				if (emptypull ~= nil) and (pulling == false) then
					estop = 1
				elseif (emptypull ~= nil) and pulling and emptystill then
					estop = 1
				elseif (emptypull == nil) and (emptystop ~= nil) then
					estop = 1
				end
			elseif emptystill then
				estop = 1
			end
			
			if (estop == 1) then
				localresult = 1
				table.insert(result, 1)
				table.insert(results, 2)
				added = true
			end
			
			if (localresult ~= 1) then
				if (emptypush ~= nil) and (pulling == false) and (emptyswap == nil) then
					table.insert(result, 2)
					table.insert(results, 2)
					added = true
				end
				
				if (emptypull ~= nil) and pulling then
					table.insert(result, 2)
					table.insert(results, 2)
					added = true
				end
			end
		end
		
		if (added == false) then
			table.insert(result, 0)
			table.insert(results, 2)
		end
	end
	
	if (#results == 0) then
		result = {0}
		results = {0}
	end

	--[[ 
		(1/11/21) Its been a while and this code was from 8 months ago when I started prototyping cut/pack. By the commit message, this might be garbage code,
		since we dont support passive packing. The commented line below was what it was originally. I'm not sure if this is correct. Look into this.
	 ]]
	-- if #queued_pack_specials > 0 and #specials == 0 then
	if #queued_pack_specials > 0 then
		-- This section has two purposes:
		-- 1) Ensure that all other collision-based interactions take priority over pack
		-- 2) In the event of a pack, do not move any nearby units.
		--		This covers if a push object is on a wall and "wall is pack" and other text is packing against the wall, 
		--      the push object will be moved.
		for _, special in ipairs(queued_pack_specials) do
			table.insert(specials, special)
		end
		result = {0}
		-- results = {0}
	end
	
	return result,results,specials
end

function dopush(unitid,ox,oy,dir,pulling_,x_,y_,reason,pusherid)
	--[[ 
		@mods(turning text) - Override Reason - handle directional swap
		@mods(text splicing) - Override Reason - use of globals to give more context for check_text_packing() and therefore check() (see global definitions in ts_text_splicing.lua)
				- calling_push_check_on_pull
				- record_packed_text
			- Note: is there a way to not rely on these globals? These can be passed as parameters
					to check() but we risk Hempuli deciding to change the function definition and
					us having to refactor. 
	 ]]
	local pid2 = tostring(ox + oy * roomsizex) .. tostring(unitid)
	pushedunits[pid2] = 1
	
	local x,y = 0,0
	local unit = {}
	local name = ""
	local pushsound = false
	
	if (unitid ~= 2) then
		unit = mmf.newObject(unitid)
		x,y = unit.values[XPOS],unit.values[YPOS]
		name = getname(unit)
	else
		x = x_
		y = y_
		name = "empty"
	end
	
	local pulling = false
	if (pulling_ ~= nil) then
		pulling = pulling_
	end
	
	arrow_prop_mod_globals.group_arrow_properties = false
	local swaps = findfeatureat(nil,"is","swap",x+ox,y+oy,{"still"})
	arrow_prop_mod_globals.group_arrow_properties = true
	
	--@Turning Text(SWAP) ------------------------
	local arrow_swap_units = do_directional_swap_findfeatureat(dir, swaps, x, y, ox, oy)
	if #arrow_swap_units > 0 then
		if swaps == nil then
			swaps = arrow_swap_units
		else
			for i,unit in ipairs(arrow_swap_units) do
				table.insert(swaps, unit)
			end
		end
	end
	------------------------------

	if (swaps ~= nil) and ((unitid ~= 2) or ((unitid == 2) and (pulling == false))) then
		for a,b in ipairs(swaps) do
			if (pulling == false) or (pulling and (b ~= pusherid)) then
				local alreadymoving = findupdate(b,"update")
				local valid = true
				
				if (#alreadymoving > 0) then
					valid = false
				end
				
				if valid then
					addaction(b,{"update",x,y,nil})
				end
			end
		end
	end
	
	if pulling then
		arrow_prop_mod_globals.group_arrow_properties = false
		local swap = hasfeature(name,"is","swap",unitid,x,y,{"still"})
		arrow_prop_mod_globals.group_arrow_properties = true
		
		--@Turning Text(SWAP) ------------------------
		if not swap then
			swap = do_directional_swap_hasfeature(dir, name, unitid, x, y)
		end
		------------------------------
		
		if swap then
			local swapthese = findallhere(x+ox,y+oy)
			
			for a,b in ipairs(swapthese) do
				if (b ~= pusherid) then
					local alreadymoving = findupdate(b,"update")
					local valid = true
					
					if (#alreadymoving > 0) then
						valid = false
					end
					
					if valid and (b ~= 2) then
						addaction(b,{"update",x,y,nil})
						pushsound = true
					end
				end
			end
		end
	end
	
	local hm = 0
	local tileid = x + y * roomsizex
	local moveid = tostring(tileid) .. name .. tostring(dir)
	
	if (movemap[moveid] == nil) then
		movemap[moveid] = {}
	end
	
	if (movemap[moveid]["push"] == nil) then
		movemap[moveid]["push"] = 0
		movemap[moveid]["pull"] = 0
		movemap[moveid]["result"] = 0
	end
	
	local movedata = movemap[moveid]
	
	if (HACK_MOVES < 10000) then
		if pulling then
			splice_mod_globals.calling_push_check_on_pull = true
		end
		splice_mod_globals.record_packed_text = true
		local hmlist,hms,specials = check(unitid,x,y,dir,false,reason)
		splice_mod_globals.record_packed_text = false
		
		if pulling then
			splice_mod_globals.calling_push_check_on_pull = false
		end
		local pullhmlist,pullhms,pullspecials = check(unitid,x,y,dir,true,reason)
		local result = 0
		
		local weak = hasfeature(name,"is","weak",unitid,x_,y_)
		
		if (movedata.result == 0) then
			for i,obs in pairs(hmlist) do
				local done = false
				while (done == false) do
					if (obs == 0) then
						result = math.max(0, result)
						done = true
					elseif (obs == 1) or (obs == -1) then
						if (pulling == false) or (pulling and (hms[i] ~= pusherid)) then
							result = math.max(2, result)
							done = true
						else
							result = math.max(0, result)
							done = true
						end
					else
						if (pulling == false) or (pulling and (hms[i] ~= pusherid)) then
							result = math.max(1, result)
							done = true
						else
							result = math.max(0, result)
							done = true
						end
					end
				end
			end
			
			movedata.result = result + 1
		else
			result = movedata.result - 1
			done = true
		end
		
		local finaldone = false
		
		while (finaldone == false) and (HACK_MOVES < 10000) do
			if (result == 0) then
				table.insert(movelist, {unitid,ox,oy,dir,specials,x,y})
				--move(unitid,ox,oy,dir,specials)
				pushsound = true
				finaldone = true
				hm = 0
				
				if (pulling == false) and (movedata.pull == 0) then
					for i,obs in ipairs(pullhmlist) do
						if (obs < -1) or (obs > 1) and (obs ~= pusherid) then
							if (obs ~= 2) then
								table.insert(movelist, {obs,ox,oy,dir,pullspecials,x,y})
								pushsound = true
								--move(obs,ox,oy,dir,specials)
							end
							
							local pid = tostring(x-ox + (y-oy) * roomsizex) .. tostring(obs)
							
							if (pushedunits[pid] == nil) then
								pushedunits[pid] = 1
								
								hm = dopush(obs,ox,oy,dir,true,x-ox,y-oy,reason,unitid)
							end
							
							movedata.pull = 1
						end
					end
				end
			elseif (result == 1) then
				if (movedata.push == 0) then
					for i,v in ipairs(hmlist) do
						if (v ~= -1) and (v ~= 0) and (v ~= 1) then
							local pid = tostring(x+ox + (y+oy) * roomsizex) .. tostring(v)
							
							if (pulling == false) or (pulling and (hms[i] ~= pusherid)) and (pushedunits[pid] == nil) then
								pushedunits[pid] = 1
								hm = dopush(v,ox,oy,dir,false,x+ox,y+oy,reason,unitid)
							end
						end
					end
				else
					hm = movedata.push - 1
				end
				
				movedata.push = hm + 1
				
				if (hm == 0) then
					result = 0
				else
					result = 2
				end
			elseif (result == 2) then
				hm = 1
				
				if (weak ~= nil) then
					delete(unitid,x,y)
					
					local pmult,sound = checkeffecthistory("weak")
					setsoundname("removal",1,sound)
					generaldata.values[SHAKE] = 3
					MF_particles("destroy",x,y,5 * pmult,0,3,1,1)
					result = 0
					hm = 0
				end
				
				finaldone = true
			end
		end
		
		if pulling and (HACK_MOVES < 10000) then
				hmlist,hms,specials = check(unitid,x,y,dir,pulling,reason)
				hm = 0
			
				for i,obs in pairs(hmlist) do
					if (obs < -1) or (obs > 1) then
					local pid = tostring(x - ox + (y - oy) * roomsizex) .. tostring(obs)
					
					if (obs ~= 2) and (pushedunits[pid] == nil) then
							table.insert(movelist, {obs,ox,oy,dir,specials,x,y})
							pushsound = true
						end
						
						if (pushedunits[pid] == nil) then
							pushedunits[pid] = 1
							hm = dopush(obs,ox,oy,dir,pulling,x-ox,y-oy,reason,unitid)
						end
					end
				end
				
			if (movedata.pull == 0) then
				movedata.pull = hm + 1
			else
				hm = movedata.pull - 1
			end
		end
		
		if pushsound and (generaldata2.strings[TURNSOUND] == "") then
			setsoundname("turn",5)
		end
	end
	
	HACK_MOVES = HACK_MOVES + 1
	
	return hm
end

