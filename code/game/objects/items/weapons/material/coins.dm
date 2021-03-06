/obj/item/material/coin
	name = "coin"
	icon = 'icons/obj/coin.dmi'
	icon_state = "coin1"
	applies_material_colour = TRUE
	randpixel = 8
	force = 1
	throwforce = 1
	w_class = 1
	slot_flags = SLOT_EARS
	var/string_attached

/obj/item/material/coin/New()
	icon_state = "coin[rand(1,10)]"
	..()

/obj/item/material/coin/attackby(var/obj/item/W, var/mob/user)
	if(W.iscoil() && !string_attached)
		var/obj/item/stack/cable_coil/CC = W
		if(CC.use(1))
			var/image/I = image(icon = icon, icon_state = "coin_string_overlay")
			I.appearance_flags |= RESET_COLOR
			I.color = CC.color
			add_overlay(I)
			string_attached = TRUE
			to_chat(user, "<span class='notice'>You attach a string to the coin.</span>")
			return
	else if(W.iswirecutter() && string_attached)
		var/obj/item/stack/cable_coil/CC = new(get_turf(user))
		CC.amount = 1
		CC.update_icon()
		cut_overlays()
		string_attached = null
		to_chat(user, "<span class='notice'>You detach the string from the coin.</span>")
	else ..()

/obj/item/material/coin/attack_self(var/mob/user)
	user.visible_message("<span class='notice'>\The [user] has thrown \the [src]. It lands on [rand(1, 2) == 1 ? "tails" : "heads"]!</span>")

// Subtypes.
/obj/item/material/coin/gold
	default_material = "gold"

/obj/item/material/coin/silver
	default_material = "silver"

/obj/item/material/coin/diamond
	default_material = "diamond"

/obj/item/material/coin/iron
	default_material = "iron"

/obj/item/material/coin/uranium
	default_material = "uranium"

/obj/item/material/coin/platinum
	default_material = "platinum"