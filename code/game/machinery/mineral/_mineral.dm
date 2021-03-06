/obj/machinery/mineral
	icon = 'icons/obj/machines/mining_machines.dmi'
	density =  TRUE
	anchored = TRUE

	var/turf/input_turf =  WEST
	var/turf/output_turf = EAST
	var/obj/machinery/computer/mining/console

/obj/machinery/mineral/Destroy()
	input_turf = null
	output_turf = null
	console = null
	. = ..()

/obj/machinery/mineral/initialize()
	set_input(input_turf)
	set_output(output_turf)
	if(ispath(console))
		for(var/c in cardinal)
			var/turf/T = get_step(loc, c)
			if(T)
				console = locate(console) in T
				if(console) break
	. = ..()

/obj/machinery/mineral/proc/set_input(var/_dir)
	input_turf = _dir ? get_step(loc, _dir) : null

/obj/machinery/mineral/proc/set_output(var/_dir)
	output_turf = _dir ? get_step(loc, _dir) : null

/obj/machinery/mineral/proc/get_console_data()
	return list("=== <a href='?src=\ref[src];configure_input_output=1'>\[Configure Input/Output\]</a>")

/obj/machinery/mineral/proc/can_use(var/mob/user)
	return (user && (istype(usr, /mob/living/silicon) || usr.Adjacent(src) || (console && usr.Adjacent(console))))

/obj/machinery/mineral/Topic(href, href_list)
	. = ..()
	if(can_use(usr))
		if(href_list["configure_input_output"])
			interact(usr)
			. = TRUE
		if(console && usr.Adjacent(console))
			usr.set_machine(console)
			console.add_fingerprint(usr)

/obj/machinery/mineral/attack_ai(var/mob/user)
	interact(user)

/obj/machinery/mineral/attack_hand(var/mob/user)
	add_fingerprint(user)
	interact(user)

/obj/machinery/mineral/proc/can_configure(var/mob/user)
	if(user.incapacitated())
		return FALSE
	if(istype(user, /mob/living/silicon))
		return TRUE
	return (Adjacent(user) || (console && console.Adjacent(user)))

/obj/machinery/mineral/interact(var/mob/user)

	if(!can_configure(user)) return

	var/choice = input("Do you wish to change the input direction, or the output direction?") as null|anything in list("Input", "Output")
	if(isnull(choice) || !can_configure(user)) return

	var/list/_dirs = list("North" = NORTH, "South" = SOUTH, "East" = EAST, "West" = WEST, "Clear" = 0)
	var/dchoice = input("Do you wish to change the input direction, or the output direction?") as null|anything in _dirs
	if(isnull(dchoice) || !can_configure(user)) return

	if(choice == "Input")
		set_input(dchoice ? _dirs[dchoice] : null)
		to_chat(user, "<span class='notice'>You [input_turf ? "configure" : "disable"] \the [src]'s input system.</span>")
	else
		set_output(dchoice ? _dirs[dchoice] : null)
		to_chat(user, "<span class='notice'>You [output_turf ? "configure" : "disable"] \the [src]'s output system.</span>")