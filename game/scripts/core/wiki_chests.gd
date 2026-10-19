class_name WikiChests
extends RefCounted
## PL2-002: the wiki's pages for chests, locks and lockpicking. Numbers come from balance.json so the
## text cannot drift from the rules (Chests in chests.gd).


static func add_pages(w: Wiki) -> void:
	var fine := int(GameData.b("theft_fine"))
	var radius := int(GameData.b("witness_radius"))
	w.add_page("sys:chests", "Chests, locks and lockpicking", "systems", [
		Wiki.p("Chests, crates and barrels keep goods for their owners. Your own family chest, and any crate or chest in a house you hold, is yours: store and take what you like, in any quantity. A padlock (forged at the anvil, or bought from the smith) can be fitted to your own chest; you open it with your key. Another household's chest holds their pantry, and the tavern's and the stalls' hold their stock: you may not store in them, and taking from them is theft."),
		Wiki.p("Some owners lock their chests. Picking a lock needs a lockpick and uses Stealth: the chance is about %d%% at Stealth 1 against the easiest lock, up %d points per Stealth level and down %d points per lock level. Harder locks take longer (%d game minutes per lock level). A failed try may snap the lockpick (%d%%). A picked lock stays open for the rest of the day and is locked again at dawn." % [
			roundi(float(GameData.b("lockpick_base")) * 100.0), roundi(float(GameData.b("lockpick_per_skill")) * 100.0),
			roundi(float(GameData.b("lockpick_per_lock")) * 100.0), int(GameData.b("lockpick_minutes")), roundi(float(GameData.b("lockpick_break")) * 100.0)]),
		Wiki.p("Anyone in the room sees what you do. A quiet success is seen only within %d tiles; a failure or a snapped pick is noisy and is seen within %d tiles. Being seen is a crime on your record, and a guard who sees it fines you %d coins, as for theft (a theft of goods costs more: see Theft). Chests in the manor and in buildings nobody holds are only for show: they hold nothing." % [
			roundi(radius * float(GameData.b("lockpick_quiet"))), radius, fine]),
		Wiki.links(["item:lockpick", "item:padlock", "recipe:forge_lockpicks", "recipe:forge_padlock", "skill:stealth", "sys:theft", "guide:chests"])])
	w.add_page("guide:chests", "Store things and pick locks", "guides", [
		Wiki.p("Step up to a chest or crate and press Use to open it. In your own, pick an item, set how many with the plus and minus buttons, and store or take it; Store All and Take All move whole lists. To lock your own chest, fit a padlock from its window. To open someone else's locked chest, carry a lockpick, open its window and choose Pick the lock. Do it when nobody is in the room."),
		Wiki.links(["sys:chests", "sys:theft", "guide:theft"])], "", "lockpicking lock pick chest storage")
