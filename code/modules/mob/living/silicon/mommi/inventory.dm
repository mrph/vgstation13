//These procs handle putting stuff in your hand. It's probably best to use these rather than setting stuff manually
//as they handle all relevant stuff like adding it to the player's screen and such

//Returns the thing in our active hand (whatever is in our active module-slot, in this case)
/mob/living/silicon/robot/mommi/get_active_hand()
	return module_active

/mob/living/silicon/robot/mommi/get_all_slots()
	return list(tool_state, head_state)

/mob/living/silicon/robot/mommi/get_equipped_items()
	return head_state

/mob/living/silicon/robot/mommi/proc/is_in_modules(obj/item/W, var/permit_sheets=0)
	if(istype(W, src.module.emag.type))
		return src.module.emag
	// Exact matching for stacks (so we can load machines)
	if(istype(W, /obj/item/stack/sheet))
		for(var/obj/item/stack/sheet/S in src.module.modules)
			if(S.type==W.type)
				return permit_sheets ? 0 : S
	else
		return (W in src.module.modules)

#define MOMMI_LOW_POWER 100

/mob/living/silicon/robot/mommi/put_in_hands(var/obj/item/W)
	// Fixing NPEs caused by PDAs giving me NULLs to hold :V - N3X
	// And before you ask, this is how /mob handles NULLs, too.
	if(!W)
		return 0
	if(cell && cell.charge <= MOMMI_LOW_POWER)
		drop_item(W)
		return 0
	// Make sure we're not picking up something that's in our factory-supplied toolbox.
	//if(is_type_in_list(W,src.module.modules))
	//if(is_in_modules(W))
//		to_chat(src, "<span class='warning'>Picking up something that's built-in to you seems a bit silly.</span>")
		//return 0
	if(W.type == /obj/item/device/material_synth)
		drop_item(W)
		return 0
	if(tool_state)
		//var/obj/item/found = locate(tool_state) in src.module.modules
		var/obj/item/TS = tool_state
		if(!is_in_modules(tool_state))
			drop_item(TS)
		else
			TS.loc = src.module
		contents -= tool_state
		if (client)
			client.screen -= tool_state
	tool_state = W
	W.layer = 20
	W.forceMove(src)

	// Make crap we pick up active so there's less clicking and carpal. - N3X
	module_active=tool_state
	inv_tool.icon_state = "inv1 +a"
	//inv_sight.icon_state = "sight"

	update_items()
	return 1

//Attemps to remove an object on a mob.  Will not move it to another area or such, just removes from the mob.
/mob/living/silicon/robot/mommi/remove_from_mob(var/obj/O)
	src.u_equip(O,0)
	if (src.client)
		src.client.screen -= O
	O.layer = initial(O.layer)
	O.screen_loc = null
	return 1

/mob/living/silicon/robot/mommi/u_equip(W as obj)
	if (W == tool_state)
		if(module_active==tool_state)
			module_active=null
		unequip_tool()
	else if (W == head_state)
		unequip_head()


// Override the default /mob version since we only have one hand slot.
/mob/living/silicon/robot/mommi/put_in_active_hand(var/obj/item/W)
	// If we have anything active, deactivate it.
	if(!W)
		return 0
	if(get_active_hand())
		uneq_active()
	return put_in_hands(W)

/mob/living/silicon/robot/mommi/get_multitool(var/active_only=0)
	if(istype(get_active_hand(),/obj/item/device/multitool))
		return get_active_hand()
	if(active_only && istype(tool_state,/obj/item/device/multitool))
		return tool_state
	return null

/mob/living/silicon/robot/mommi/drop_item_v()		//this is dumb.
	if(stat == CONSCIOUS && isturf(loc))
		return drop_item()
	return 0

/mob/living/silicon/robot/mommi/drop_item(var/obj/item/to_drop, var/atom/Target)
	if(tool_state)
		//var/obj/item/found = locate(tool_state) in src.module.modules
		if(is_in_modules(tool_state))
			if((tool_state in contents) && (tool_state in src.module.modules))
				to_chat(src, "<span class='warning'>This item cannot be dropped.</span>")
				return 0
		if(client)
			client.screen -= tool_state
		contents -= tool_state
		var/obj/item/TS = tool_state
		if(!Target)
			Target = get_turf(src)

		TS.layer=initial(TS.layer)
		TS.loc = Target

		if(istype(Target, /turf))
			var/turf/T = Target
			T.Entered(tool_state)
		TS.dropped(src)
		tool_state = null
		module_active=null
		inv_tool.icon_state="inv1"
		update_items()
		return 1
	return 0


/*-------TODOOOOOOOOOO--------*/
// Called by store button
/mob/living/silicon/robot/mommi/uneq_active()
	var/obj/item/TS
	if(isnull(module_active))
		return
	if((module_active in src.contents) && !(module_active in src.module.modules) && (module_active != src.module.emag) && candrop)
		TS = tool_state
		drop_item(TS)
	if(tool_state == module_active)
		//var/obj/item/found = locate(tool_state) in src.module.modules
		TS = tool_state
		if(!is_in_modules(TS))
			drop_item()
		if (client)
			client.screen -= tool_state
		contents -= tool_state
		module_active = null
		tool_state = null
		inv_tool.icon_state = "inv1"
	if(is_in_modules(TS))
		TS.forceMove(src.module)
	hud_used.update_robot_modules_display()

/mob/living/silicon/robot/mommi/uneq_all()
	module_active = null

	unequip_sight()
	unequip_tool()
	unequip_head()

// Unequips an object from the MoMMI's head
/mob/living/silicon/robot/mommi/proc/unequip_head()
	// If there is a hat on the MoMMI's head
	if(head_state)
		// Select the MoMMI's claw
		select_module(INV_SLOT_TOOL)

		// Put the hat in the MoMMI's claw
		put_in_active_hand(head_state)

		// Remove the head_state icon from the client's screen
		if (client)
			client.screen -= head_state

		// Delete the hat from the head
		head_state = null

		// Update the MoMMI's head inventory icons
		update_inv_head()

/mob/living/silicon/robot/mommi/proc/unequip_tool()
	if(tool_state)
		var/obj/item/TS=tool_state
		if(!is_in_modules(TS))
			drop_item()
		if (client)
			client.screen -= tool_state
		contents -= tool_state
		tool_state = null
		inv_tool.icon_state = "inv1"
		if(is_in_modules(TS))
			TS.forceMove(src.module)
		hud_used.update_robot_modules_display()


/mob/living/silicon/robot/mommi/activated(obj/item/O)
	if(tool_state == O) // Sight
		return 1
	else
		return 0


//Helper procs for cyborg modules on the UI.
//These are hackish but they help clean up code elsewhere.

//module_selected(module) - Checks whether the module slot specified by "module" is currently selected.
/mob/living/silicon/robot/mommi/module_selected(var/module) //Module is 1-3
	return module == get_selected_module()

//module_active(module) - Checks whether there is a module active in the slot specified by "module".
/mob/living/silicon/robot/mommi/module_active(var/module)
	if(!(module in INV_SLOT_TOOL))
		return

	if(INV_SLOT_TOOL)
		if(tool_state)
			return 1
	return 0

//get_selected_module() - Returns the slot number of the currently selected module.  Returns 0 if no modules are selected.
/mob/living/silicon/robot/mommi/get_selected_module()
	if(tool_state && module_active == tool_state)
		return INV_SLOT_TOOL
	return 0

//select_module(module) - Selects the module slot specified by "module"
/mob/living/silicon/robot/mommi/select_module(var/module)
	if(!(module in INV_SLOT_TOOL))
		return
	if(!module_active(module)) return

	if(INV_SLOT_TOOL)
		if(module_active != tool_state)
			inv_tool.icon_state = "inv1 +a"
			module_active = tool_state
			return

//deselect_module(module) - Deselects the module slot specified by "module"
/mob/living/silicon/robot/mommi/deselect_module(var/module)
	if(!(module in INV_SLOT_TOOL))
		return

	if(INV_SLOT_TOOL)
		if(module_active == tool_state)
			inv_tool.icon_state = "inv1"
			module_active = null
			return

//toggle_module(module) - Toggles the selection of the module slot specified by "module".
/mob/living/silicon/robot/mommi/toggle_module(var/module)
	if(!(module in INV_SLOT_TOOL))
		return
	if(module_selected(module))
		deselect_module(module)
	else
		if(module_active(module))
			select_module(module)
		else
			deselect_module(get_selected_module()) //If we can't do select anything, at least deselect the current module.
	return

//cycle_modules() - Cycles through the list of selected modules.
/mob/living/silicon/robot/mommi/cycle_modules()
	return

// Equip an item to the MoMMI. Currently the only thing you can equip is hats
// Returns a 0 or 1 based on whether or not the equipping worked
/mob/living/silicon/robot/mommi/equip_to_slot(obj/item/W as obj, slot, redraw_mob = 1)
	// If the parameters were given incorrectly, return an error
	if(!slot) return 0
	if(!istype(W)) return 0

	// If this item does not equip to this slot type, return
	if( !(W.slot_flags & SLOT_HEAD) )
		return 0

	// If the item is in the MoMMI's claw, handle removing the item from the MoMMI's claw
	if(W == tool_state)
		// Don't allow the MoMMI to equip tools to their head. I mean, they cant anyways, but stop them here
		if(is_in_modules(tool_state))
			to_chat(src, "<span class='warning'>You cannot equip a module to your head.</span>")
			return 0
		// Remove the item in the MoMMI's claw from their HuD
		if (client)
			client.screen -= tool_state
		// Delete the item from their claw and de-activate the claw
		tool_state = null
		deselect_module(INV_SLOT_TOOL)
		inv_tool.icon_state = "inv1"
		module_active = null

	// For each equipment slot that the MoMMI can equip to
	switch(slot)
		// If equipping to the head
		if(slot_head)
			// Grab whatever the MoMMI might already be wearing and cast it
			var/obj/item/wearing = head_state
			// If the MoMMI is already wearing a hat, put the active hat back in their claw
			if(wearing)
				// Put it in their hand
				put_in_active_hand(wearing)
				tool_state = wearing
				// Activate their hand
				select_module(INV_SLOT_TOOL)

			// Put the item on the MoMMI's head
			src.head_state = W
			W.equipped(src, slot)
			// Add the item to the MoMMI's hud
			if (client)
				client.screen += head_state
		else
			to_chat(src, "<span class='warning'>You are trying to equip this item to an unsupported inventory slot. How the heck did you manage that? Stop it...</span>")
			return 0
	// Set the item layer and update the MoMMI's icons
	W.layer = 20
	update_inv_head()
	return 1

/mob/living/silicon/robot/mommi/attack_ui(slot)
	var/obj/item/W = tool_state
	if(istype(W))
		if(equip_to_slot(W, slot))
			update_items()
		else
			to_chat(src, "<span class='warning'>You are unable to equip that.</span>")

// Quickly equip a hat by pressing "e"
/mob/living/silicon/robot/mommi/verb/quick_equip()
	set name = "quick-equip"
	set hidden = 1

	// Only allow equipping if the tool slot is activated
	if(!module_selected(INV_SLOT_TOOL))
		return

	// If yes we are a MoMMI
	if(isMoMMI(src))
		// Typecast ourselves as a MOMMI
		var/mob/living/silicon/robot/mommi/M = src
		// Check to see if we are holding something
		var/obj/item/I = M.tool_state
		if(!I)
			to_chat(M, "<span class='notice'>You are not holding anything to equip.</span>")
			return
		// Attempt to equip it and, if it succedes, update our icon
		if(M.equip_to_slot(I, slot_head))
			update_items()
		else
			to_chat(M, "<span class='warning'>You are unable to equip that.</span>")

