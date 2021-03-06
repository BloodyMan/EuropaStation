var/list/organ_cache = list()

/obj/item/organ
	name = "organ"
	icon = 'icons/obj/surgery.dmi'
	germ_level = 0

	// Strings.
	var/b_type
	var/organ_tag = "organ"           // Unique identifier.
	var/parent_organ = BP_CHEST       // Organ holding this object.
	var/initial_gender = NEUTER

	// Status tracking.
	var/status = 0                    // Various status flags (such as robotic)
	var/vital                         // Lose a vital limb, die immediately.
	var/damage = 0                    // Current damage to the organ
	var/robotic = 0

	// Reference data.
	var/mob/living/carbon/human/owner // Current mob owning the organ.
	var/list/autopsy_data = list()    // Trauma data for forensics.
	var/list/trace_chemicals = list() // Traces of chemicals in the organ.
	var/datum/species/species         // Original species.

	// Damage vars.
	var/min_bruised_damage = 10       // Damage before considered bruised
	var/min_broken_damage = 30        // Damage before becoming broken
	var/max_damage                    // Damage cap
	var/rejecting                     // Is this organ already being rejected?
	var/emp_hardening = 0             // Amount to reduce incoming EMP damage by.

/obj/item/organ/Destroy()
	if(owner)           owner = null
	if(autopsy_data)    autopsy_data.Cut()
	if(trace_chemicals) trace_chemicals.Cut()
	species = null
	. = ..()

/obj/item/organ/proc/update_health()
	return

/obj/item/organ/New(var/mob/living/carbon/holder, var/internal)
	..(holder)
	create_reagents(5)
	if(!max_damage)
		max_damage = min_broken_damage * 2
	if(istype(holder))
		b_type = holder.b_type
		src.owner = holder
		src.w_class = max(src.w_class + mob_size_difference(holder.mob_size, MOB_MEDIUM), 1) //smaller mobs have smaller organs.
		species = all_species[DEFAULT_SPECIES]
		if(istype(owner))
			species = owner.species
			initial_gender = owner.gender
			if(internal)
				var/obj/item/organ/external/E = owner.get_organ(parent_organ)
				if(E)
					if(E.internal_organs == null)
						E.internal_organs = list()
					E.internal_organs |= src
			if(!blood_DNA)
				blood_DNA = list()
			blood_DNA[owner.get_dna_hash()] = owner.b_type
		if(internal)
			holder.internal_organs |= src
	update_icon()

/obj/item/organ/proc/set_dna(var/mob/living/carbon/donor)
	if(istype(donor))
		blood_DNA = list()
		blood_DNA[donor.get_dna_hash()] = donor.b_type
		species = all_species[donor.get_species()]

/obj/item/organ/proc/die()
	if(robotic >= ORGAN_ROBOT)
		return
	damage = max_damage
	status |= ORGAN_DEAD
	processing_objects -= src
	if(owner && vital)
		owner.death()

/obj/item/organ/process()

	if(loc != owner)
		owner = null

	//dead already, no need for more processing
	if(status & ORGAN_DEAD)
		return
	// Don't process if we're in a freezer, an MMI or a stasis bag.or a freezer or something I dunno
	if(istype(loc,/obj/item/mmi))
		return
	if(istype(loc,/obj/structure/closet/body_bag/cryobag) || istype(loc,/obj/structure/closet/crate/freezer) || istype(loc,/obj/item/storage/box/freezer))
		return
	//Process infections
	if ((robotic >= ORGAN_ROBOT) || (owner && owner.species && (owner.species.flags & IS_PLANT)))
		germ_level = 0
		return

	if(!owner && reagents)
		var/datum/reagent/blood/B = locate(/datum/reagent/blood) in reagents.reagent_list
		if(B && prob(40))
			reagents.remove_reagent("blood",0.1)
			blood_splatter(src,B,1)
		if(config.organs_decay) damage += rand(1,3)
		if(damage >= max_damage)
			damage = max_damage
		germ_level += rand(2,6)
		if(germ_level >= INFECTION_LEVEL_TWO)
			germ_level += rand(2,6)
		if(germ_level >= INFECTION_LEVEL_THREE)
			die()

	else if(owner && owner.bodytemperature >= 170)	//cryo stops germs from moving and doing their bad stuffs
		//** Handle antibiotics and curing infections
		handle_antibiotics()
		handle_rejection()
		handle_germ_effects()

	//check if we've hit max_damage
	if(damage >= max_damage)
		die()

/obj/item/organ/examine(mob/user)
	..(user)
	if(status & ORGAN_DEAD)
		user << "<span class='notice'>The decay has set in.</span>"

/obj/item/organ/proc/handle_germ_effects()
	//** Handle the effects of infections
	var/antibiotics = owner.reagents.get_reagent_amount("antibiotic")

	if (germ_level > 0 && germ_level < INFECTION_LEVEL_ONE/2 && prob(30))
		germ_level--

	if (germ_level >= INFECTION_LEVEL_ONE/2)
		//aiming for germ level to go from ambient to INFECTION_LEVEL_TWO in an average of 15 minutes
		if(antibiotics < 5 && prob(round(germ_level/6)))
			germ_level++

	if(germ_level >= INFECTION_LEVEL_ONE)
		var/fever_temperature = (owner.species.heat_level_1 - owner.species.body_temperature - 5)* min(germ_level/INFECTION_LEVEL_TWO, 1) + owner.species.body_temperature
		owner.bodytemperature += between(0, (fever_temperature - T20C)/BODYTEMP_COLD_DIVISOR + 1, fever_temperature - owner.bodytemperature)

	if (germ_level >= INFECTION_LEVEL_TWO)
		var/obj/item/organ/external/parent = owner.get_organ(parent_organ)
		//spread germs
		if (antibiotics < 5 && parent.germ_level < germ_level && ( parent.germ_level < INFECTION_LEVEL_ONE*2 || prob(30) ))
			parent.germ_level++

		if (prob(3))	//about once every 30 seconds
			take_damage(1,silent=prob(30))

/obj/item/organ/proc/handle_rejection()
	// Process unsuitable transplants. TODO: consider some kind of
	// immunosuppressant that changes transplant data to make it match.
	if(!rejecting)
		if(blood_incompatible(b_type, owner.b_type, species, owner.species))
			rejecting = 1
	else
		rejecting++ //Rejection severity increases over time.
		if(rejecting % 10 == 0) //Only fire every ten rejection ticks.
			switch(rejecting)
				if(1 to 50)
					germ_level++
				if(51 to 200)
					germ_level += rand(1,2)
				if(201 to 500)
					germ_level += rand(2,3)
				if(501 to INFINITY)
					germ_level += rand(3,5)
					owner.reagents.add_reagent("toxin", rand(1,2))

/obj/item/organ/proc/receive_chem(chemical as obj)
	return 0

/obj/item/organ/proc/remove_rejuv()
	qdel(src)

/obj/item/organ/proc/rejuvenate(var/ignore_prosthetic_prefs)
	damage = 0
	status = 0

/obj/item/organ/proc/is_damaged()
	return damage > 0

/obj/item/organ/proc/is_bruised()
	return damage >= min_bruised_damage

/obj/item/organ/proc/is_broken()
	return (damage >= min_broken_damage || (status & ORGAN_CUT_AWAY) || (status & ORGAN_BROKEN))

//Germs
/obj/item/organ/proc/handle_antibiotics()
	var/antibiotics = 0
	if(owner)
		antibiotics = owner.reagents.get_reagent_amount("antibiotic")

	if (!germ_level || antibiotics < 5)
		return

	if (germ_level < INFECTION_LEVEL_ONE)
		germ_level = 0	//cure instantly
	else if (germ_level < INFECTION_LEVEL_TWO)
		germ_level -= 6	//at germ_level == 500, this should cure the infection in a minute
	else
		germ_level -= 2 //at germ_level == 1000, this will cure the infection in 5 minutes

//Adds autopsy data for used_weapon.
/obj/item/organ/proc/add_autopsy_data(var/used_weapon, var/damage)
	var/datum/autopsy_data/W = autopsy_data[used_weapon]
	if(!W)
		W = new()
		W.weapon = used_weapon
		autopsy_data[used_weapon] = W

	W.hits += 1
	W.damage += damage
	W.time_inflicted = world.time

//Note: external organs have their own version of this proc
/obj/item/organ/proc/take_damage(amount, var/silent=0)
	amount = round(amount, 0.1)

	if(src.robotic >= ORGAN_ROBOT)
		src.damage = between(0, src.damage + (amount * 0.8), max_damage)
	else
		src.damage = between(0, src.damage + amount, max_damage)

		//only show this if the organ is not robotic
		if(owner && parent_organ && amount > 0)
			var/obj/item/organ/external/parent = owner.get_organ(parent_organ)
			if(parent && !silent)
				owner.custom_pain("Something inside your [parent.name] hurts a lot.", 1)

/obj/item/organ/proc/bruise()
	damage = max(damage, min_bruised_damage)

/obj/item/organ/proc/robotize() //Being used to make robutt hearts, etc
	robotic = ORGAN_ROBOT
	status = 0

/obj/item/organ/proc/mechassist() //Used to add things like pacemakers, etc
	status = 0
	robotic = ORGAN_ASSISTED
	min_bruised_damage = 15
	min_broken_damage = 35

/obj/item/organ/emp_act(severity)
	if(robotic >= ORGAN_ROBOT)
		severity += emp_hardening
		if(severity <= 3)
			if(severity == 1)
				take_damage(9)
			else if(severity == 2)
				take_damage(3)
			else if(severity == 3)
				take_damage(1)

//disconnected the organ from it's owner but does not remove it, instead it becomes an implant that can be removed with implant surgery
//TODO move this to organ/internal once the FPB port comes through
/obj/item/organ/proc/cut_away(var/mob/living/user)
	var/obj/item/organ/external/parent = owner.get_organ(parent_organ)
	if(istype(parent)) //TODO ensure that we don't have to check this.
		removed(user, 0)
		parent.implants += src

//TODO move cut_away() to the internal organ subtype and get rid of this
/obj/item/organ/external/cut_away(var/mob/living/user)
	removed(user)

/obj/item/organ/proc/removed(var/mob/living/user, var/drop_organ=1)

	if(!istype(owner))
		return

	owner.internal_organs_by_name[organ_tag] = null
	owner.internal_organs_by_name -= organ_tag
	owner.internal_organs_by_name -= null
	owner.internal_organs -= src

	var/obj/item/organ/external/affected = owner.get_organ(parent_organ)
	if(affected)
		affected.internal_organs -= src
		status |= ORGAN_CUT_AWAY

	if(drop_organ)
		dropInto(owner.loc)

	processing_objects |= src
	rejecting = null
	if(robotic < ORGAN_ROBOT)
		var/datum/reagent/blood/organ_blood = locate(/datum/reagent/blood) in reagents.reagent_list //TODO fix this and all other occurences of locate(/datum/reagent/blood) horror
		if(!organ_blood || !organ_blood.data["blood_DNA"])
			owner.vessel.trans_to(src, 5, 1, 1)

	if(owner && owner.stat != DEAD && vital)
		if(user)
			user.attack_log += "\[[time_stamp()]\]<font color='red'> removed a vital organ ([src]) from [owner.name] ([owner.ckey]) (INTENT: [uppertext(user.a_intent)])</font>"
			owner.attack_log += "\[[time_stamp()]\]<font color='orange'> had a vital organ ([src]) removed by [user.name] ([user.ckey]) (INTENT: [uppertext(user.a_intent)])</font>"
			msg_admin_attack("[user.name] ([user.ckey]) removed a vital organ ([src]) from [owner.name] ([owner.ckey]) (INTENT: [uppertext(user.a_intent)]) (<A HREF='?_src_=holder;adminplayerobservecoodjump=1;X=[user.x];Y=[user.y];Z=[user.z]'>JMP</a>)")
		owner.death()

	owner = null

/obj/item/organ/proc/replaced(var/mob/living/carbon/human/target,var/obj/item/organ/external/affected)

	if(!istype(target))
		return 0

	if(status & ORGAN_CUT_AWAY)
		return 0 //organs don't work very well in the body when they aren't properly attached

	// robotic organs emulate behavior of the equivalent flesh organ of the species
	if(robotic >= ORGAN_ROBOT || !species)
		species = target.species

	owner = target
	forceMove(owner) //just in case
	processing_objects -= src
	target.internal_organs |= src
	affected.internal_organs |= src
	target.internal_organs_by_name[organ_tag] = src
	return 1

/obj/item/organ/proc/bitten(mob/user)

	if(robotic >= ORGAN_ROBOT)
		return

	user << "<span class='notice'>You take an experimental bite out of \the [src].</span>"
	var/datum/reagent/blood/B = locate(/datum/reagent/blood) in reagents.reagent_list
	blood_splatter(src,B,1)

	user.drop_from_inventory(src)
	var/obj/item/reagent_containers/food/snacks/organ/O = new(get_turf(src))
	O.name = name
	O.icon = icon
	O.icon_state = icon_state

	// Pass over the blood.
	reagents.trans_to(O, reagents.total_volume)

	if(fingerprints) O.fingerprints = fingerprints.Copy()
	if(fingerprintshidden) O.fingerprintshidden = fingerprintshidden.Copy()
	if(fingerprintslast) O.fingerprintslast = fingerprintslast

	user.put_in_active_hand(O)
	qdel(src)

/obj/item/organ/attack_self(var/mob/user)

	// Convert it to an edible form, yum yum.
	if(!robotic && user.a_intent == I_HELP && user.zone_sel.selecting == BP_MOUTH)
		bitten(user)
		return

/obj/item/organ/proc/can_feel_pain()
	return (robotic < ORGAN_ROBOT && !(species.flags & NO_PAIN))
