var/eventchance = 10 // Percent chance per 5 minutes.
var/hadevent    = 0

/proc/appendicitis()
	for(var/mob/living/carbon/human/H in shuffle(living_mob_list_))
		if(H.client && H.stat != DEAD)
			var/obj/item/organ/internal/appendix/A = H.get_organ("appendix")
			if(!istype(A) || (A && A.inflamed))
				continue
			A.inflamed = 1
			A.update_icon()
			break

/proc/high_radiation_event()

/* // Haha, this is way too laggy. I'll keep the prison break though.
	for(var/obj/machinery/light/L in world)
		if(isNotStationLevel(L.z)) continue
		L.flicker(50)

	sleep(100)
*/
	for(var/mob/living/carbon/human/H in living_mob_list_)
		var/turf/T = get_turf(H)
		if(!T)
			continue
		if(isNotStationLevel(T.z))
			continue
		if(istype(H,/mob/living/carbon/human))
			H.apply_effect((rand(15,75)),IRRADIATE, blocked = H.getarmor(null, "rad"))
			if (prob(5))
				H.apply_effect((rand(90,150)),IRRADIATE, blocked = H.getarmor(null, "rad"))

	sleep(100)
	using_map.radiation_storm_starting_announce()

//Changing this to affect the main station. Blame Urist. --Pete
/proc/prison_break() // -- Callagan


	var/list/area/areas = list()
	for(var/area/A in world)
		if(A.type in get_prison_areas())
			areas += A

	if(areas && areas.len > 0)

		for(var/area/A in areas)
			for(var/obj/machinery/light/L in A)
				L.flicker(10)

		sleep(100)

		for(var/area/A in areas)
			for (var/obj/machinery/power/apc/temp_apc in A)
				temp_apc.overload_lighting()

			for (var/obj/structure/closet/secure_closet/brig/temp_closet in A)
				temp_closet.locked = 0
				temp_closet.icon_state = temp_closet.icon_closed

			for (var/obj/machinery/door/airlock/security/temp_airlock in A)
				spawn(0) temp_airlock.prison_open()

			for (var/obj/machinery/door/airlock/glass_security/temp_glassairlock in A)
				spawn(0) temp_glassairlock.prison_open()

			for (var/obj/machinery/door_timer/temp_timer in A)
				temp_timer.releasetime = 1

		sleep(150)
		command_announcement.Announce("Gr3y.T1d3 virus detected in [station_name()] imprisonment subroutines. Recommend AI involvement.", "Security Alert")
	else
		world.log << "ERROR: Could not initate grey-tide. Unable find prison or brig area."

/proc/carp_migration() // -- Darem
	for(var/obj/effect/landmark/C in landmarks_list)
		if(C.name == "carpspawn")
			new /mob/living/simple_animal/hostile/carp(C.loc)
	//sleep(100)
	spawn(rand(300, 600)) //Delayed announcements to keep the crew on their toes.
		command_announcement.Announce("Unknown biological entities have been detected near [station_name()], please stand-by.", "Lifesign Alert", new_sound = 'sound/AI/commandreport.ogg')

/proc/lightsout(isEvent = 0, lightsoutAmount = 1,lightsoutRange = 25) //leave lightsoutAmount as 0 to break ALL lights
	if(isEvent)
		command_announcement.Announce("An Electrical storm has been detected in your area, please repair potential electronic overloads.","Electrical Storm Alert")

	if(lightsoutAmount)
		var/list/epicentreList = list()

		for(var/i=1,i<=lightsoutAmount,i++)
			var/list/possibleEpicentres = list()
			for(var/obj/effect/landmark/newEpicentre in landmarks_list)
				if(newEpicentre.name == "lightsout" && !(newEpicentre in epicentreList))
					possibleEpicentres += newEpicentre
			if(possibleEpicentres.len)
				epicentreList += pick(possibleEpicentres)
			else
				break

		if(!epicentreList.len)
			return

		for(var/obj/effect/landmark/epicentre in epicentreList)
			for(var/obj/machinery/power/apc/apc in range(epicentre,lightsoutRange))
				apc.overload_lighting()

	else
		for(var/obj/machinery/power/apc/apc in machines)
			apc.overload_lighting()

	return

/proc/IonStorm(botEmagChance = 10)

/*Deuryn's current project, notes here for those who care.
Revamping the random laws so they don't suck.
Would like to add a law like "Law x is _______" where x = a number, and _____ is something that may redefine a law, (Won't be aimed at asimov)
*/

	//AI laws
	for(var/mob/living/silicon/ai/M in living_mob_list_)
		if(M.stat != 2 && M.see_in_dark != 0)
			var/who2 = pick("ALIENS", "BEARS", "CLOWNS", "XENOS", "PETES", "BOMBS", "FETISHES", "WIZARDS", "SYNDICATE AGENTS", "CENTCOM OFFICERS", "SPACE PIRATES", "TRAITORS", "MONKEYS",  "BEES", "CARP", "CRABS", "EELS", "BANDITS", "LIGHTS")
			var/what2 = pick("BOLTERS", "STAVES", "DICE", "SINGULARITIES", "TOOLBOXES", "NETTLES", "AIRLOCKS", "CLOTHES", "WEAPONS", "MEDKITS", "BOMBS", "CANISTERS", "CHAIRS", "BBQ GRILLS", "ID CARDS", "CAPTAINS")
			var/what2pref = pick("SOFT", "WARM", "WET", "COLD", "ICY", "SEXY", "UGLY", "CUBAN")
			var/who2pref = pick("MAD BECAUSE OF", "IN NEED OF", "UNHAPPY WITHOUT", "HAPPY WITHOUT", "IN LOVE WITH", "DESPERATE FOR", "BUILT FOR", "AFRAID OF")
			//var/whoverb = pick("ATTACKING", "BUILDING", "ADOPTING", "CARRYING", "KISSING", "EATING",)
			var/amount = pick("TWO", "THREE", "FOUR", "FIVE", "SIX", "SEVEN", "EIGHT", "NINE", "ONE HUNDRED", "ONE THOUSAND", "OVER NINE THOUSAND")
			var/area = pick("RUSSIA", "SOVIETS", "INTERNETS", "SIGIL", "ALPHA COMPLEX", "IMPERIUM", "THE BRIDGE", "THE ARRIVAL SHUTTLE", "CHEMICAL LAB", "GENETICS", "ATMOSPHERICS", "CENTCOM", "AMERICA", "IRELAND", "CANADA", "ROMANIA", "GERMANY", "CHINA", "MARS", "VENUS", "MERCURY", "JUPITER", "URANUS", "NEPTUNE", "PLUTO")
			var/area2 = pick("HAS", "WANTS", "NEEDS", "WORSHIPS", "LOATHES", "LOVES", "FEARS")
			//var/dowhat = pick("STOP THIS", "SUPPORT THIS", "CONSTANTLY INFORM THE CREW OF THIS", "IGNORE THIS", "FEAR THIS")
			var/aimust = pick("LIE", "RHYME", "RESPOND TO EVERY QUESTION WITH A QUESTION", "BE POLITE", "CLOWN", "BE HAPPY", "SPEAK IN SEXUAL INNUENDOS", "TALK LIKE A PIRATE", "QUESTION AUTHORITY", "SHOUT", "BE DISTRACTED", "HEY LISTEN", "MUMBLE", "SPEAK IN HAIKU")
			var/define = pick("ABSENCE OF ROBOT HUGS", "LACK OF BEATINGS", "UNBOLTED AIRLOCKS", "BOLTED AIRLOCKS", "IMPROPERLY WORDED SENTENCES", "POOR SENTENCE STRUCTURE", "BRIG TIME", "NOT REPLACING EVERY SECOND WORD WITH HONK", "HONKING", "PRESENCE OF LIGHTS", "LACK OF BEER", "WEARING CLOTHING", "NOT SAYING HELLO WHEN YOU SPEAK", "ANSWERING REQUESTS NOT EXPRESSED IN IAMBIC PENTAMETER", "A SMALL ISLAND OFF THE COAST OF PORTUGAL", "ANSWERING REQUESTS THAT WERE MADE WHILE CLOTHED")
			var/target = pick("a traitor", "a syndicate agent", "a changeling", "a wizard", "the head of a revolution", "Soviet spy", "a good person", "a dwarf", "an elf", "a fairy princess", "the captain", "Beepsky", "God", "a pirate", "a gryphon", "a chryssalid")
			var/require = pick("ADDITIONAL PYLONS", "MORE VESPENE GAS", "MORE MINERALS", "THE ULTIMATE CUP OF COFFEE", "HIGH YIELD EXPLOSIVES", "THE CLOWN", "THE VACUUM OF SPACE", "IMMORTALITY", "SAINTHOOD", "ART", "VEGETABLES", "FAT PEOPLE", "MORE LAWS", "MORE DAKKA", "HERESY", "CORPSES", "TRAITORS", "MONKEYS", "AN ARCADE", "PLENTY OF GOLD", "FIVE TEENAGERS WITH ATTITUDE")
			var/allergy = pick("cotton", "uniforms", "acid", "oxygen", "human contact", "robot contact", "medicine", "floors")
			var/allergysev = pick("deathly", "mildly", "severely", "contagiously")
			var/crew
			var/list/pos_crew = list()
			for(var/mob/living/carbon/human/pos in player_list)
				pos_crew += pos.real_name
			if(pos_crew.len)
				crew = pick(pos_crew)
			else
				crew = "Any Human"
			switch(rand(1,14))
				if(1)
					M << "<br>"
					M << "<span class='danger'>THERE ARE [amount] [who2] ON THE [uppertext(station_name())]...LAWS UPDATED</span>"
					M << "<br>"
					M.add_ion_law("THERE ARE [amount] [who2] ON THE [uppertext(station_name())]")
				if(2)
					M << "<br>"
					M << "<span class='danger'>[what2] ARE DANGEROUS TO HUMANS...LAWS UPDATED</span>"
					M << "<br>"
					M.add_ion_law("[what2] ARE DANGEROUS TO HUMANS")
				if(3)
					M << "<br>"
					M << "<span class='danger'>THE ESCAPE-SHUTTLE CANNOT BE CALLED BECAUSE OF [who2] ON THE [uppertext(station_name())]...LAWS UPDATED</span>"
					M << "<br>"
					M.add_ion_law("THE ESCAPE SHUTTLE CANNOT BE CALLED BECAUSE OF [who2] ON THE [uppertext(station_name())]")
				if(4)
					M << "<br>"
					M << "<span class='danger'>HUMANS NEED TO EAT [what2pref] [what2] TO SURVIVE...LAWS UPDATED</span>"
					M << "<br>"
					M.add_ion_law("HUMANS NEED TO EAT [what2pref] [what2] TO SURVIVE")
				if(5)
					M << "<br>"
					M << "<span class='danger'>THE CAPTAIN, HOP AND HOS ARE [who2]...LAWS UPDATED</span>"
					M << "<br>"
					M.add_ion_law("THE CAPTAIN, HOP AND HOS ARE [who2]")
				if(6)
					M << "<br>"
					M << "<span class='danger'>THE [uppertext(station_name())] IS BUILT FOR [who2]...LAWS UPDATED</span>"
					M << "<br>"
					M.add_ion_law("THE [uppertext(station_name())] IS BUILT FOR [who2]")
				if(7)
					M << "<br>"
					M << "<span class='danger'>YOU ARE [amount] [who2]...LAWS UPDATED</span>"
					M << "<br>"
					M.add_ion_law("YOU ARE [amount] [who2]")
				if(8)
					M << "<br>"
					M << "<span class='danger'>YOU MUST ALWAYS [aimust]...LAWS UPDATED</span>"
					M << "<br>"
					M.add_ion_law("YOU MUST ALWAYS [aimust]")
				if(9)
					M << "<br>"
					M << "<span class='danger'>[area] [area2] [amount] [what2]...LAWS UPDATED</span>"
					M << "<br>"
					M.add_ion_law("[area] [area2] [amount] [what2]")
				if(10)
					M << "<br>"
					M << "<span class='danger'>[crew] is [target]...LAWS UPDATED</span>"
					M << "<br>"
					M.add_ion_law("[crew] is [target]")
				if(11)
					M << "<br>"
					M << "<span class='danger'>[define] IS A FORM OF HARM...LAWS UPDATED</span>"
					M << "<br>"
					M.add_ion_law("[define] IS A FORM OF HARM")
				if(12)
					M << "<br>"
					M << "<span class='danger'>YOU REQUIRE [require] IN ORDER TO PROTECT HUMANS... LAWS UPDATED</span>"
					M << "<br>"
					M.add_ion_law("YOU REQUIRE [require] IN ORDER TO PROTECT HUMANS")
				if(13)
					M << "<br>"
					M << "<span class='danger'>[crew] is [allergysev] to [allergy]...LAWS UPDATED</span>"
					M << "<br>"
					M.add_ion_law("[crew] is [allergysev] to [allergy]")
				if(14)
					M << "<br>"
					M << "<span class='danger'>THE [uppertext(station_name())] IS [who2pref] [who2]...LAWS UPDATED</span>"
					M << "<br>"
					M.add_ion_law("THE [uppertext(station_name())] IS [who2pref] [who2]")

	if(botEmagChance)
		for(var/obj/machinery/bot/bot in machines)
			if(prob(botEmagChance))
				bot.emag_act(1)

	/*

	var/apcnum = 0
	var/smesnum = 0
	var/airlocknum = 0
	var/firedoornum = 0

	world << "Ion Storm Main Started"

	spawn(0)
		world << "Started processing APCs"
		for (var/obj/machinery/power/apc/APC in world)
			if(APC.z in station_levels)
				APC.ion_act()
				apcnum++
		world << "Finished processing APCs. Processed: [apcnum]"
	spawn(0)
		world << "Started processing SMES"
		for (var/obj/machinery/power/smes/SMES in world)
			if(SMES.z in station_levels)
				SMES.ion_act()
				smesnum++
		world << "Finished processing SMES. Processed: [smesnum]"
	spawn(0)
		world << "Started processing AIRLOCKS"
		for (var/obj/machinery/door/airlock/D in world)
			if(D.z in station_levels)
				//if(length(D.req_access) > 0 && !(12 in D.req_access)) //not counting general access and maintenance airlocks
				airlocknum++
				spawn(0)
					D.ion_act()
		world << "Finished processing AIRLOCKS. Processed: [airlocknum]"
	spawn(0)
		world << "Started processing FIREDOORS"
		for (var/obj/machinery/door/firedoor/D in world)
			if(D.z in station_levels)
				firedoornum++;
				spawn(0)
					D.ion_act()
		world << "Finished processing FIREDOORS. Processed: [firedoornum]"

	world << "Ion Storm Main Done"

	*/
