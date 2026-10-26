class_name WikiChests
extends RefCounted
## PL2-002: the wiki's pages for chests, locks and lockpicking. Numbers come from balance.json so the
## text cannot drift from the rules (Chests in chests.gd).


static func add_pages(w: Wiki) -> void:
	var fine := int(GameData.b("theft_fine"))
	var radius := int(GameData.b("witness_radius"))
	w.add_page("sys:chests", "Chests, locks and lockpicking", "systems", [
		Wiki.p("Chests, crates and barrels keep goods for their owners. Your own family chest, and any crate or chest in a house you hold, is yours: store and take what you like, in any quantity. A padlock (forged at the anvil, or bought from the smith) can be fitted to your own chest; you open it with your key. Another household's chest holds their pantry, and the tavern's and the stalls' hold their stock: you may not store in them, and taking from them is theft."),
		Wiki.p("Some owners lock their chests. Picking a lock needs a lockpick and is a game of timing. The lock opens in a cutaway: one chamber for each pin, each with its spring, a steel pin over a brass one and a gold line across them all. The pick lifts one pin at a time to the line, where it wobbles; catch it with that pin's own input before it drops: tap or click its column, press its key (1 to 6) or its pad button (A, B, X, Y, then LB and RB), shown under it. A set pin can slip and wobble again: catch it again. When every pin is set the lock turns and the chest opens. Pins that drop are lifted again later, but the pick bears only so many drops: one more and the try has failed. Pressing a pin that is not ready does nothing."),
		Wiki.p("The lock decides how many pins there are: 4 for the easiest (about seven catches open it), 5 and 6 for harder ones, with two pins wobbling at once. Your Stealth against the lock decides how slowly the pins rise and how long each wobbles before it drops: the better your hand, the longer you have. The pins are never smaller on a harder lock. The game does not stop the world. Stop it at any time (the Stop button, Esc or the pad's Menu button) and nothing has happened: the lock is as it was and nothing is on your record. A failed try may snap the lockpick (%d%%). A picked lock stays open for the rest of the day and is locked again at dawn." % [
			roundi(float(GameData.b("lockpick_break")) * 100.0)]),
		Wiki.p("Anyone in the room sees what you do. A quiet success is seen only within %d tiles; a failure or a snapped pick is noisy and is seen within %d tiles. Being seen is a crime on your record, and a guard who sees it fines you %d coins, as for theft (a theft of goods costs more: see Theft). Chests in the manor and in buildings nobody holds are only for show: they hold nothing." % [
			roundi(radius * float(GameData.b("lockpick_quiet"))), radius, fine]),
		Wiki.links(["item:lockpick", "item:padlock", "recipe:forge_lockpicks", "recipe:forge_padlock", "skill:stealth", "sys:theft", "guide:chests"])])
	w.add_page("guide:chests", "Store things and pick locks", "guides", [
		Wiki.p("Step up to a chest or crate and press Use to open it. In your own, pick an item, set how many with the plus and minus buttons, and store or take it; Store All and Take All move whole lists. To lock your own chest, fit a padlock from its window. To open someone else's locked chest, carry a lockpick, open its window and choose Pick the lock. Do it when nobody is in the room."),
		Wiki.links(["sys:chests", "sys:theft", "guide:theft"])], "", "lockpicking lock pick chest storage")
