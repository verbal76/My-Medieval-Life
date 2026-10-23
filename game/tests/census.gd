extends RefCounted
## Where every good in a world is held, by holder (a census): villagers, markets, household pantries,
## the granary, troughs, building sites and carried loads, the player (pack, chest, premises), loot, the
## manor's work and carts. One count for the economy simulation's ledger (economy_sim.gd) and the save
## conservation test (DVW-A6), so both see the same goods.
##   const Census := preload("res://tests/census.gd")
##
## X18 HOOK (Expansion 18, PROS-18): the walk itself now lives in SettlementHoldings
## (scripts/core/settlement/holdings.gd) so the settlement report can use it in the game; this file delegates.

const MARKET_ROLES := SettlementHoldings.MARKET_ROLES


static func holders(w: World) -> Dictionary:
	return SettlementHoldings.holders(w)


## Every good's total over all holders.
static func goods(w: World) -> Dictionary:
	return SettlementHoldings.goods(w)
