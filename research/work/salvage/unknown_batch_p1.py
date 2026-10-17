from common import *

# ---------------- C22 ----------------
led("C22", 12,
    "Riding on with the chapmen's Fellowship through the mountains, Ralph talks with his war-caught thrall Bull Shockhead, who defends his kindred's man-stealing craft. Bull reveals that his kinsman Bull Nosy recently took a fair, patient, strong woman wearing beads like Ralph's to the market at Cheaping Knowe; Ralph realises this is the damsel of his quest (Ursula) and Bull promises to help find her.",
    "Mountain-folk (kindred of the Bull) prey on all who pass 'these mountains' save kin and known friends; Cheaping Knowe holds a market where captives are taken down to be sold (implying the town lies below the mountains). No directions or distances.",
    ["Is the 'Lady of the Wildwood' the Lady of Abundance? (yes by the earlier story, but named only by epithet here)"])

ent("Bull Shockhead", "person", "mountain man of the kindred of the Bull; war-caught thrall of Ralph",
    "Mountain raider taken captive by Ralph; merry and talkative; defends man-stealing as gainful; promises to help find the damsel if Ralph frees him.",
    [r("C22-P002", "Ralph rode beside Bull, who was merry and blithe now he was full of meat and drink"),
     r("C23-P008", "to keep his war-caught thrall, Bull Shockhead, safe at home, lest he be taken from him")],
    aliases=["Bull"], kindred="the Bull", status="thrall of Ralph, promised freedom")
ent("Bull Nosy", "person", "mountain man of the kindred of the Bull; slave-taker",
    "Kinsman of Bull Shockhead who captured the damsel (Ursula), took her to Cheaping Knowe market and then to Whiteness and toward the Goldburg pass; called 'the longnosed man of the kindred of the Bull'.",
    [r("C22-P008", "such an one was taken by my kinsman Bull Nosy but a little while agone"),
     r("C24-P007", "the man's name was Bull Nosy, or the longnosed man of the kindred of the Bull")],
    aliases=["Nosy", "the longnosed man of the kindred of the Bull", "the wild man"])
ent("Kindred of the Bull", "group", "mountain clan / man-stealers",
    "Mountain folk who treat all who pass through the mountains as foemen save kin and known friends; they capture people and sell them as thralls. Men are named after the kindred ('Bull X'). They are no horsemen.",
    [r("C22-P003", "And are all men your foemen who pass through these mountains?"),
     r("C24-P007", "for in such wise are named the men of that unhappy folk"),
     r("C24-P007", "for the mountain-men be no horsemen")],
    aliases=["the mountain folk", "foemen of the mountains", "mountain-men"])
ent("Ursula (the damsel of the quest)", "person", "captive damsel sought by Ralph",
    "Fair woman 'as fair as a flower', strong ('could bear as much as a strong man'), patient and quiet in captivity, wearing a pair of beads like Ralph's. Ralph's dream named her Dorothea. Proud and stout at Cheaping Knowe market, refusing to be stripped.",
    [r("C22-P008", "For she was as fair as a flower; and yet so well built, that she could bear as much as a strong man"),
     r("C22-P010", "whom his dream of the night had called Dorothea"),
     r("C24-P007", "she was so proud and stout that men feared her")],
    aliases=["the damsel", "Dorothea (dream-name)"])
ent("Pair of beads (Ralph's)", "item", "necklace / pair of beads",
    "A pair of beads worn about Ralph's neck, gift of a dear friend (a woman); the damsel wore a pair 'as like to thine as if they had been the very same'.",
    [r("C22-P008", "The pair of beads about thy neck, whence came they?"),
     r("C22-P009", "this same woman had about her neck a pair of beads as like to thine")])
ent("Lady of the Wildwood", "person", "lady (Lady of Abundance) — dead",
    "Recalled by Ralph: led along to death before he delivered her, fled with him from the Water of the Oak, and was murdered in the desert.",
    [r("C22-P010", "the Lady of the Wildwood led along to death before he delivered her, and their flight together from the Water of the Oak")])
ent("Water of the Oak", "place", "place (earlier in the story)",
    "Place from which Ralph and the Lady fled together; mentioned in recollection.",
    [r("C22-P010", "their flight together from the Water of the Oak")])
ent("Chapmen (the merchants' Fellowship)", "group", "merchant caravan",
    "The chapmen with whom Ralph travels, with their hired sworders (sergeants) and chapman lads, led by Clement Chapman; they ride with banners displayed.",
    [r("C22-P002", "For as for these churls of chapmen, and the sworders whom they wage"),
     r("C22-P013", "the carle began jesting and talking with the chapman lads")],
    aliases=["the Fellowship", "the Companions", "the merchants"])
ent("Thrall (bought slave)", "custom", "chattel slavery",
    "Bought thralls; Bull claims they are often treated softly and have other thralls to work under their whips.",
    [r("C22-P005", "this life of a bought thrall is not such an exceeding evil life")])

rel("Bull Shockhead", "captive_of", "Ralph", "war-caught thrall; Ralph promises to make him free", [r("C22-P013", "besides making thee free")], when="BTWO-C22 onward")
rel("Bull Nosy", "kin_of", "Bull Shockhead", "kinsman", [r("C22-P008", "taken by my kinsman Bull Nosy but a little while agone")])
rel("Ursula (the damsel of the quest)", "captive_of", "Bull Nosy", "taken captive and brought to market", [r("C22-P008", "whom he took down to the market at Cheaping Knowe")], when="shortly before BTWO-C22")
rel("Bull Shockhead", "member_of", "Kindred of the Bull", "", [r("C24-P007", "the longnosed man of the kindred of the Bull")], conf="medium", cls="CANON-INFERRED")

sp("Kindred of the Bull", "within", "the mountains (between Cheaping Knowe region and the Fellowship's earlier route)",
   [r("C22-P003", "And are all men your foemen who pass through these mountains?")], context="dialogue:Ralph/Bull", cert="flexible")
sp("Cheaping Knowe", "other", "the mountains of the Bull kindred", [r("C22-P008", "whom he took down to the market at Cheaping Knowe")],
   context="dialogue:Bull Shockhead", cert="constrained", cls="CANON-INFERRED", conf="medium",
   note="'took down' implies Cheaping Knowe lies lower than the mountain haunts of the Bull kindred")

fact("society", "Kindred of the Bull", "The mountain men count as foemen all who pass through their mountains except kindred and known friends.",
     [r("C22-P003", "but they be of the kindred or their known friends")], context="dialogue:Bull Shockhead")
fact("society", "Kindred of the Bull", "Their craft is ravishing men and women and selling them into thralldom; Bull calls it gainful.",
     [r("C22-P008", "be our craft good or evil, it is gainful")], context="dialogue:Bull Shockhead")
fact("law", "thralls", "A thrall who slew his master would be slain with bitter torments.",
     [r("C22-P007", "better to be slain with bitter torments (as thou shouldest be if thou slewest thy master)")], context="dialogue:Ralph")
fact("society", "thralls", "Bull compares slave-taking to the chapman's hold on his debtor and the lord of the manor's on his villein.",
     [r("C22-P005", "How much worse do we than the chapmen by his debtor, and the lord of the manor by his villein?")], context="dialogue:Bull Shockhead")
fact("society", "Kindred of the Bull", "Bull despises the chapmen and their sworders as kinless men who know not their ancestry; he values lineage.",
     [r("C22-P002", "they know not the name of their mother's mother")], context="dialogue:Bull Shockhead")
fact("trade", "Ursula (the damsel of the quest)", "Ralph hopes to 'cheapen' (buy) the damsel from Bull Nosy.",
     [r("C22-P011", "dost thou think that I may cheapen her of thy kinsman?")], context="dialogue:Ralph")

ev("Bull reveals the damsel's capture", "C22",
   "Bull Shockhead tells Ralph that his kinsman Bull Nosy captured a fair woman wearing beads like Ralph's and took her to market at Cheaping Knowe; Ralph resolves to find her.",
   [r("C22-P009", "did this woman give thee the beads?"), r("C22-P012", "I will do my best to find her for thee")],
   participants=["Ralph", "Bull Shockhead"], places=["Cheaping Knowe"], cons="Ralph's quest is redirected to finding the damsel via the slave markets.")
ev("Capture of the damsel by Bull Nosy", "C22", "Bull Nosy captured the damsel, who neither wept nor screeched but bore it patiently.",
   [r("C22-P008", "when she was taken, there was no weeping or screeching in her")], layer="backstory", time="a little while agone",
   participants=["Bull Nosy", "Ursula (the damsel of the quest)"])
ev("Recollection of the Lady's death", "C22", "Ralph recalls the Lady of the Wildwood's deliverance, their flight from the Water of the Oak, and her murder in the desert.",
   [r("C22-P010", "and that murder of her in the desert")], layer="backstory", participants=["Ralph", "Lady of the Wildwood"])

unr("identity", "Are the beads worn by the damsel the same make/source as Ralph's (both from the Lady of Abundance)? Bull only says they look 'the very same'.",
    [r("C22-P009", "as like to thine as if they had been the very same")])
opp("Kindred-named mountain clans ('Bull Nosy', 'Bull Shockhead') as a naming generator for highland raider NPCs", "npc",
    [r("C24-P007", "for in such wise are named the men of that unhappy folk")])
opp("Recruitable captive companion whose loyalty depends on being promised freedom", "companions",
    [r("C22-P013", "I in turn will do what more I may for thee besides making thee free")])

# ---------------- C23 ----------------
led("C23", 11,
    "The Fellowship camps in the plain among elms and next day reaches walled Cheaping Knowe, a stone town built around a castle-hill held by a cruel tyrant whose men wear a bloody-sword badge. They lodge at the Merchants' hostel, the Fleece; the chapmen take gifts to the lord and get Ralph a pass as a sergeant of their guard. Ralph sees the gibbets on the castle-hill, a small strange master-church, and lush gardens with lemons, oranges and pomegranates.",
    "Plain fields with tall elms lie before Cheaping Knowe (one camp-night out). Approach passes much fair country; land near the walls cleared of trees. Town wraps around a high castle hill; market place wide, with best houses; gardens with stone runnels; climate fair and hot, citrus grows.",
    ["How far is the plain camp from the mountains?"])

ent("Cheaping Knowe", "place", "walled market town with castle",
    "Walled stone town built about a castle on a high hill; strong tall walls; cleared ground near walls; many houses but poorly built save the castle; wide market place with the best houses; thrall-market; ruled by a cruel tyrant.",
    [r("C23-P005", "The walls were strong and tall, and a great castle stood high up on a hill, about which the town was builded"),
     r("C25-P006", "Cheaping Knowe was all builded of stone")],
    ruler="a tyrant lord who 'had gotten the castle in those days'", material="stone")
ent("Castle of Cheaping Knowe", "building", "hill castle / citadel",
    "Great castle high on a hill within the town, so that if the town were taken there would be 'another town within it'; has a bailey beyond which visitors were not let pass.",
    [r("C23-P005", "so that if the town were taken there would yet be another town within it to be taken also"),
     r("C23-P010", "the guard would not suffer them to pass further than the bailey of the Castle")])
ent("Castle-hill of Cheaping Knowe", "feature", "hill slope with gibbets",
    "Slopes of the castle hill bearing gibbets and stakes with men, women and babes hanging or impaled — the lord's 'cruel justice'.",
    [r("C23-P010", "on the slopes of the Castle-hill, tokens of the cruel justice of the said lord")])
ent("Lord of Cheaping Knowe", "person", "tyrant of the town",
    "Lord who 'had gotten the castle in those days' and was tyrant of the town, with many men-at-arms; robs, maims or slays townsfolk at pleasure, but leaves chapmen alone for the sake of trade; receives gifts from the chapmen and issues them passes; takes tribute from the lord of Whiteness.",
    [r("C23-P006", "this was the token of the lord who had gotten the castle in those days, and was tyrant of the town"),
     r("C25-P007", "he paid tribute to him of Cheaping Knowe")], aliases=["the tyrant of Cheaping Knowe", "him of Cheaping Knowe"],
    badge="a sword reddened with blood")
ent("Bloody-sword token", "item", "livery badge",
    "Token on the sleeves of the warriors of Cheaping Knowe: a sword reddened with blood, the token of the tyrant lord.",
    [r("C23-P006", "most of these bore a token on their sleeves, to wit, a sword reddened with blood")])
ent("Men-at-arms of the lord of Cheaping Knowe", "group", "tyrant's soldiery",
    "Many warriors in the town wearing the bloody-sword token, ready to do the lord's bidding.",
    [r("C23-P006", "he had so many men-at-arms ready to do his bidding that none in the town was safe from him")])
ent("The Fleece", "building", "merchants' hostel / inn",
    "The hostel of the Merchants in Cheaping Knowe, on the market place; a big house and goodly enough; the Fellowship lodges there.",
    [r("C23-P007", "came to the hostel of the Merchants, called the Fleece, which was a big house, and goodly enough")],
    aliases=["hostel of the Fleece", "Fleece"])
ent("Market place of Cheaping Knowe", "feature", "market square",
    "Wide and great market place where the best houses of the town stand; in a corner is the thrall-cheaping beside a stone.",
    [r("C23-P007", "the market place, which was wide and great, and the best houses of the town were therein")])
ent("Master-church of Cheaping Knowe", "building", "principal church",
    "Not great, nor much fairer than great, strange and uncouth of fashion.",
    [r("C23-P011", "found the master-church, and deemed it not much fairer than it was great")])
ent("Gardens of Cheaping Knowe", "feature", "town gardens",
    "Great gardens within the town with trees, flowers and fruits new to Ralph — lemons, oranges, pomegranates — watered by runnels of ashlar.",
    [r("C23-P012", "had trees and flowers and fruits in them which Ralph had not seen hitherto, as lemons, and oranges, and pomegranates")])
ent("Thrall-merchant of Cheaping Knowe", "person", "slave-dealer, master of the thrall-market",
    "Tall, goodly, black-bearded man clad in scarlet, sober of aspect and slow of speech; master of the thrall-market; gains on every sale; courteous to Ralph.",
    [r("C24-P004", "saw a tall man, goodly of presence, black bearded, clad in scarlet; and this was the merchant"),
     r("C23-P003", "knew the master of that market")], aliases=["the merchant", "master of that market"])
ent("Clement Chapman", "person", "merchant, leader of the chapmen",
    "Leader of the chapmen's Fellowship; does not deal in thralls but knows the thrall-market master; guides and advises Ralph.",
    [r("C23-P003", "though he dealt not in such wares, he had often seen them sold")], aliases=["Clement", "master Clement"])
ent("Pass of the lord of Cheaping Knowe", "item", "parchment safe-conduct",
    "Parchment from the lord bidding all men help and let pass Ralph of Upmeads as a sergeant of the chapmen's guard.",
    [r("C23-P009", "a parchment from the lord, which bade all men help and let pass Ralph of Upmeads, as a sergeant of the chapmen's guard")])
ent("Sergeants of the chapmen's guard", "occupation", "hired guard",
    "Hired sworders guarding the chapmen; Ralph is enrolled as one.",
    [r("C23-P009", "as a sergeant of the chapmen's guard")])
ent("Lemons, oranges and pomegranates", "commodity", "fruit",
    "Fruits growing in the Cheaping Knowe gardens, unknown to Ralph before.",
    [r("C23-P012", "as lemons, and oranges, and pomegranates")])
ent("(unnamed) elm-grown plain fields before Cheaping Knowe", "feature", "campsite in plain",
    "Plain fields amidst tall elm trees where the Fellowship camped the night before reaching Cheaping Knowe.",
    [r("C23-P002", "they pitched their camp down in the plain fields amidst tall elmtrees")], unnamed=True)

rel("Lord of Cheaping Knowe", "ruler_of", "Cheaping Knowe", "tyrant who seized the castle", [r("C23-P006", "was tyrant of the town")], when="BTWO-C23 (in those days)")
rel("Thrall-merchant of Cheaping Knowe", "trades_in", "Thrall (bought slave)", "", [r("C23-P003", "as he lives by selling thralls")])
rel("Clement Chapman", "other", "Thrall-merchant of Cheaping Knowe", "acquainted; knows the master of the market", [r("C23-P003", "knew the master of that market")])
rel("Ralph", "serves", "Chapmen (the merchants' Fellowship)", "enrolled as a sergeant of the chapmen's guard", [r("C23-P009", "as a sergeant of the chapmen's guard")])

sp("(unnamed) elm-grown plain fields before Cheaping Knowe", "route_next", "Cheaping Knowe",
   [r("C23-P002", "they pitched their camp down in the plain fields amidst tall elmtrees"), r("C23-P005", "They came to the gates a little before sunset")],
   time="left mid-morning, reached the gates a little before sunset", terrain="plain fields with tall elms; much fair country", note="camp one night out from Cheaping Knowe")
sp("Castle of Cheaping Knowe", "within", "Cheaping Knowe", [r("C23-P005", "a great castle stood high up on a hill, about which the town was builded")], terrain="castle on a high hill; town built around it")
sp("Cheaping Knowe", "surrounds", "Castle-hill of Cheaping Knowe", [r("C23-P005", "a great castle stood high up on a hill, about which the town was builded")])
sp("(unnamed) cleared ground around Cheaping Knowe walls", "surrounds", "Cheaping Knowe", [r("C23-P005", "nigh to the walls it was bare of trees and thickets")], terrain="bare of trees and thickets near the walls")
sp("The Fleece", "within", "Market place of Cheaping Knowe", [r("C23-P007", "Thus they rode through the streets into the market place")], cert="constrained", cls="CANON-INFERRED", conf="medium", note="they rode into the market place 'and so came to' the Fleece")
sp("Gardens of Cheaping Knowe", "within", "Cheaping Knowe", [r("C23-P012", "Then they came to great gardens within the town")])
sp("Master-church of Cheaping Knowe", "within", "Cheaping Knowe", [r("C23-P011", "found the master-church")])
sp("Castle-hill of Cheaping Knowe", "visible_from", "bailey of the Castle of Cheaping Knowe", [r("C23-P010", "they saw thence, on the slopes of the Castle-hill")])

tr(["Ralph", "Clement Chapman", "Chapmen (the merchants' Fellowship)", "Bull Shockhead"], "(unnamed) elm-grown plain fields before Cheaping Knowe", "Cheaping Knowe",
   [r("C23-P002", "they gat not to the road before mid-morning"), r("C23-P005", "They came to the gates a little before sunset, after they had passed through much fair country")],
   "C23", mode="horse", start="mid-morning", end="a little before sunset", terrain="much fair country; bare land near walls")

fact("military", "Cheaping Knowe", "Trees and thickets near the walls were cut down so they could not shelter strong-thieves or assailants.",
     [r("C23-P005", "they had been cut down lest they should serve as cover to strong-thieves or folk assailing the town")], context="dialogue:Clement")
fact("architecture", "Cheaping Knowe", "Apart from the castle, the town is scarce so fairly built as the worst of the towns Ralph had seen before, though it has many houses.",
     [r("C23-P005", "was scarce so fairly builded as the worst of the towns which Ralph had seen erst")])
fact("society", "Cheaping Knowe", "Many townsfolk are fair and well clad but many wear 'foul clouts' and seem needy and hunger-pinched.",
     [r("C23-P006", "many had but foul clouts to cover their nakedness, and seemed needy and hunger-pinched")])
fact("politics", "Lord of Cheaping Knowe", "None in the town is safe from the tyrant, who robs, maims, torments or slays at pleasure; but he does not meddle with chapmen lest trade end.",
     [r("C23-P006", "with us chapmen,\" said Clement, \"he will not meddle, lest there be an end of chaffer in the town")], context="dialogue:Clement")
fact("trade", "Cheaping Knowe", "The market is good, per Clement.", [r("C23-P006", "and verily the market is good")], context="dialogue:Clement")
fact("custom", "Chapmen (the merchants' Fellowship)", "The chapmen ride with banners displayed and keep them flying over their tents to warn comers of what they are.",
     [r("C23-P002", "had their banners still flying over the tents to warn all comers of what they were")])
fact("custom", "Chapmen (the merchants' Fellowship)", "On arrival the chapmen go up to the castle bearing gifts from their wares for the lord.",
     [r("C23-P008", "bearing with them gifts out of their wares for the lord")])
fact("law", "Cheaping Knowe", "A war-caught thrall could be taken from his owner in the town; Ralph was told to keep Bull at home, dress him as a chapman lad and dock his hair.",
     [r("C23-P008", "to clothe him in the guise of the chapman lads, and to dock his hair")], cls="CANON-INFERRED", conf="medium", note="the risk of seizure is implied by Clement's caution")
fact("law", "Cheaping Knowe", "The lord's justice: men, women and babes hanged on gibbets and impaled on sharp pales on the castle-hill slopes; folk would not say why.",
     [r("C23-P010", "hanging on gibbets and thrust through with sharp pales")])
fact("agriculture", "Cheaping Knowe", "Citrus and pomegranates grow in the town gardens, watered by stone runnels; weather fair and hot.",
     [r("C23-P012", "the waters were running through them in runnels of ashlar; and the weather was fair and hot")])
fact("climate", "Cheaping Knowe", "The weather was fair and hot during the visit.", [r("C23-P012", "and the weather was fair and hot")])
fact("politics", "Cheaping Knowe", "Visitors were permitted to curfew: Ralph had to be back at the Fleece by nightfall.",
     [r("C23-P009", "so that he were back at the hostel of the Fleece by nightfall")])

ev("Arrival at Cheaping Knowe", "C23", "The Fellowship enters Cheaping Knowe with banners, watched by a crowd, and lodges at the Fleece.",
   [r("C23-P006", "Much people was gathered about the gate to see the merchants enter with banners displayed")], time="a little before sunset",
   participants=["Ralph", "Clement Chapman"], places=["Cheaping Knowe", "The Fleece"])
ev("Chapmen visit the lord's castle", "C23", "The chapmen bring gifts to the lord and return at noon with a pass for Ralph.",
   [r("C23-P009", "About noon the chapmen came back again well pleased")], time="next morning to noon", places=["Castle of Cheaping Knowe"])
ev("Ralph tours Cheaping Knowe", "C23", "Ralph sees the castle bailey and gibbets, the master-church and gardens, resting in the gardens till evening.",
   [r("C23-P012", "so they rested in those gardens till it was evening")], places=["Cheaping Knowe"])

opp("Bailey checkpoint: guards block access to castle beyond bailey; a pass item opens city streets", "exploration",
    [r("C23-P010", "the guard would not suffer them to pass further than the bailey of the Castle")])
opp("Tyrant town where faction badge (bloody sword) marks hostile guards; merchants have immunity", "factions",
    [r("C23-P006", "a sword reddened with blood")])
opp("Southern-climate garden district with exotic fruits as a forage/trade resource", "economy",
    [r("C23-P012", "lemons, and oranges, and pomegranates")])

# ---------------- C24 ----------------
led("C24", 10,
    "Ralph idles in Cheaping Knowe's gardens, then Clement takes him to the thrall-cheaping in a corner of the market, where captives are sold off a stone. The black-bearded thrall-merchant says Bull Nosy brought the damsel but she was too proud to be sold; Nosy likely went to Whiteness to give or sell her to the dread Lord of Utterbol. Clement says the Lord of Utterbol is deemed the worst and perhaps mightiest tyrant of these lands.",
    "Thrall-market in a corner of the market place by a leaping-on stone; merchant's booth and house. Whiteness is the Fellowship's next stop and the place to meet the Lord of Utterbol. Mid-Mountain House named as where Ralph found a piece of her gown.",
    ["Where is Utterbol? Only its lord is mentioned."])

ent("Thrall-stone of Cheaping Knowe", "feature", "auction stone",
    "A stone like a leaping-on stone in a corner of the market place on which thralls stand to be cheapened.",
    [r("C24-P004", "beside a stone like a leaping-on stone"), r("C25-P003", "those whom we saw standing on the Stone in the market of Cheaping Knowe")],
    aliases=["the Stone"])
ent("Lord of Utterbol", "person", "tyrant lord",
    "Lord who buys women and such wares; feared by all men and women; money is nothing to him beside the doing of his will; deemed the worst of the tyrants of these lands and maybe the mightiest.",
    [r("C24-P008", "he will be minded to meet there the Lord of Utterbol, who is for such like wares"),
     r("C24-P010", "he is deemed by all men as the worst of the tyrants who vex these lands, and, maybe, the mightiest")],
    aliases=["my lord", "lord of Utterbol"])
ent("Utterbol", "place", "lordship (location not given)", "Domain of the Lord of Utterbol; named only through its lord in this chapter.",
    [r("C24-P009", "what is this lord of Utterbol that all folk, men and women, fear him so?")])
ent("Mid-Mountain House", "building", "house in the mountains (earlier in story)",
    "Place by which Ralph came upon a piece of the damsel's gown.",
    [r("C24-P006", "that piece of her gown which he had come on by the Mid-Mountain House")])
ent("Piece of the damsel's gown", "item", "torn cloth", "Scrap of the damsel's gown Ralph found by the Mid-Mountain House, shown to the merchant.",
    [r("C24-P006", "he drew forth that piece of her gown")])
ent("Hansel", "custom", "sale payment / earnest", "Hansel paid at the conclusion of the thrall sale.",
    [r("C24-P005", "hansel paid, and the thralls led off by their new masters")])
ent("Vavassors and yeomen", "group", "free landholding classes of Ralph's homeland",
    "Ralph came from a land with no thralls, only vavassors and good yeomen.",
    [r("C24-P005", "he came from a land where were no thralls, none but vavassors and good yeomen")])
ent("Knaves of the thrall-merchant", "group", "servants", "Two knaves of the thrall-merchant attending the sale.",
    [r("C24-P004", "by him were two of his knaves and certain weaponed men who had brought their wares")])

rel("Lord of Utterbol", "ruler_of", "Utterbol", "", [r("C24-P009", "what is this lord of Utterbol")], conf="medium", cls="CANON-INFERRED")
rel("Lord of Utterbol", "trades_in", "Thrall (bought slave)", "buys women and 'such like wares'", [r("C24-P008", "the Lord of Utterbol, who is for such like wares")], context="" if False else "") if False else rel("Lord of Utterbol", "trades_in", "Thrall (bought slave)", "buys women and 'such like wares' (merchant's words)", [r("C24-P008", "the Lord of Utterbol, who is for such like wares")])
rel("Clement Chapman", "enemy_of", "Lord of Utterbol", "fears him; would never meet him save where he were many and he few", [r("C24-P010", "God forbid that I should ever meet him, save where I were many and he few")], conf="medium")

sp("Thrall-stone of Cheaping Knowe", "within", "Market place of Cheaping Knowe", [r("C24-P004", "brought him to a corner of the market-place, where was a throng looking on at the cheaping")])
sp("Cheaping Knowe", "route_next", "Whiteness", [r("C24-P008", "he will have gone first of all to the town of Whiteness, whither thy Fellowship will betake them ere long")], context="dialogue:thrall-merchant")
sp("Utterbol", "other", "Whiteness", [r("C24-P008", "he will be minded to meet there the Lord of Utterbol")], context="dialogue:thrall-merchant", cert="flexible",
   cls="CANON-INFERRED", conf="low", note="The Lord of Utterbol is expected to visit Whiteness, implying Utterbol is reachable from there; no direction given")

tr(["Bull Nosy", "Ursula (the damsel of the quest)"], "Cheaping Knowe", "Whiteness (probable)", [r("C24-P007", "led her away, she riding on a horse and he going afoot beside her")], "C24",
   mode="she on horse, he afoot")

fact("trade", "Thrall-market of Cheaping Knowe", "Thralls (here thirteen) stand one after another on the stone; buyers examine them like horses and often take them into the merchant's booth to strip them before bidding, especially women.",
     [r("C24-P004", "There was a half score and three of these chattels to be sold"), r("C24-P004", "like as if they had been cheapening a horse")])
fact("trade", "Thrall-market of Cheaping Knowe", "Captives are brought to market by weaponed men, some arrayed like the mountain foemen.",
     [r("C24-P004", "some of these were arrayed like those foemen of the mountains")])
fact("custom", "Cheaping Knowe", "Lawfully wedded women, damsels in kin's care and concubine-slaves dare not even look on a man; other fair women of the place befriended the men-at-arms.",
     [r("C24-P002", "had not dared so much as to look on a man")])
fact("custom", "Clement Chapman", "Clement gives the merchant 'the sele of the day' as greeting.", [r("C24-P005", "to whom he gave the sele of the day")])
fact("food", "Thrall-merchant of Cheaping Knowe", "The merchant entertains guests with wine and spices.", [r("C24-P006", "set wine and spices before them")])
fact("society", "Kindred of the Bull", "The mountain-men are no horsemen.", [r("C24-P007", "for the mountain-men be no horsemen")], context="dialogue:thrall-merchant")
fact("trade", "Thrall-market of Cheaping Knowe", "The merchant proposed 'quelling' an unruly captive with pains that would spoil her little before bringing her back to market.",
     [r("C24-P007", "quell her with such pains as would spoil her but little")], context="dialogue:thrall-merchant")
fact("politics", "Lord of Utterbol", "Money and goods are nothing to him beside the doing of his will; to get the damsel back from him would be more than hard.",
     [r("C24-P008", "for money and goods are naught to him beside the doing of his will")], context="dialogue:thrall-merchant")
fact("politics", "the lands beyond the mountains", "Several tyrants vex these lands; the Lord of Utterbol is the worst and maybe mightiest.",
     [r("C24-P010", "the worst of the tyrants who vex these lands")], context="dialogue:Clement")
fact("society", "Upmeads", "Ralph's homeland has no thralls, only vavassors and yeomen.", [r("C24-P005", "none but vavassors and good yeomen")])

ev("The thrall-cheaping", "C24", "Ralph witnesses thirteen captives sold off the stone; none is the damsel.",
   [r("C24-P004", "Of women four of them were young and goodly"), r("C24-P005", "yet he abode till all was done")], time="the fourth day", places=["Market place of Cheaping Knowe"])
ev("The merchant's tidings", "C24", "The merchant tells Ralph Bull Nosy brought the damsel but could not sell her and led her away, probably to Whiteness to the Lord of Utterbol.",
   [r("C24-P007", "hither was she brought to be sold by a man of the mountain folk not very many days ago")], participants=["Ralph", "Clement Chapman", "Thrall-merchant of Cheaping Knowe"])
ev("Damsel refuses to be stripped at market", "C24", "At Cheaping Knowe the damsel denied being viewed naked, threatening mischief, so the merchant could not sell her.",
   [r("C24-P007", "she denied it utterly, saying that she would do a mischief to whomsoever tried it")], layer="backstory", participants=["Ursula (the damsel of the quest)", "Bull Nosy"])

unr("location", "Where is Utterbol, and how does it relate to Whiteness and Goldburg?", [r("C24-P008", "he will be minded to meet there the Lord of Utterbol")])
opp("Slave-market information broker: pay/visit dealer for rumours of a captive's route", "quests", [r("C24-P002", "") if False else r("C23-P002", "if such a fair image as that we were speaking of hath passed through his hands within these three months, he will remember it")])

# ---------------- C25 ----------------
led("C25", 7,
    "After two more days the chapmen leave Cheaping Knowe, keeping wares for Goldburg, and ride about fifty miles in three days through tilled land worked by thralls to Whiteness, a white-walled timber town on a long ridge at a valley's end under the great mountains. Whiteness's lord pays tribute to Cheaping Knowe but rules free men well. The Deacon of the Chapmen tells Ralph the Lord of Utterbol has not been there for six months and that the wild man led the damsel toward the Goldburg pass.",
    "Cheaping Knowe to Whiteness ~50 miles, 3 days' ride; land of tillage and pasture with castles and slave-barracks; confused hills before the great mountains on the last day; Whiteness on a long ridge at the end of a valley, close under the mountains, the door of the passes to Goldburg; nothing green behind it; long ride up the valley.",
    [])

ent("Whiteness", "place", "town on a ridge; gateway to the passes",
    "Town close underneath the mountains, 'the door of the passes' to Goldburg; on a long ridge at the end of a valley; walls and towers not high because the hill is steep; no great castle; long and straggling along the ridge-top; timber houses pargeted and whitened; more cheerful than Cheaping Knowe.",
    [r("C25-P003", "which lay close underneath the mountains, and was, as it were, the door of the passes whereby men rode to Goldburg"),
     r("C25-P006", "the houses here were of timber for the most part, done over with pargeting and whitened well")])
ent("Lord of Whiteness", "person", "lord", "Pays tribute to the lord of Cheaping Knowe for love of peace rather than fear; no ill lord, under whom free men live well.",
    [r("C25-P007", "for he was no ill lord, and free men lived well under him")])
ent("Deacon of the Chapmen of Whiteness", "person", "head of the town's merchant guild",
    "Gives Ralph tidings of the Lord of Utterbol and the damsel.", [r("C25-P008", "Ralph got speech of the Deacon of the Chapmen of the Town")], aliases=["the Deacon"])
ent("Deacon of the Chapmen", "office", "merchant guild office", "Office of head of the chapmen of a town.", [r("C25-P008", "the Deacon of the Chapmen of the Town")])
ent("Goldburg", "place", "city beyond the mountains", "Destination of the chapmen, for which they keep wares; reached by the mountain passes from Whiteness.",
    [r("C25-P002", "they must needs keep some of their wares for other places, and especially for Goldburg")])
ent("(unnamed) thrall-worked tillage between Cheaping Knowe and Whiteness", "place", "agricultural land",
    "Fair land of tillage and pasture with much cattle, worked by bought thralls under the whip; castles and strong-houses; rows of ugly hovels and long foul houses (thrall stables); no yeomen's or vavassors' houses.",
    [r("C25-P003", "The land which they passed through was fair, both of tillage and pasture, with much cattle therein")], unnamed=True)
ent("Thrall-stables", "building", "slave barracks", "Long rows of ugly hovels and big, tall, long, foul houses in which field-thralls are harboured.",
    [r("C25-P003", "they are the stables wherein this kind of cattle is harboured")])
ent("(unnamed) confused hills before the great mountains", "feature", "foothills",
    "Confused hills lying before the great mountains, crossed on the last day of riding to Whiteness; they often hid the mountains.",
    [r("C25-P006", "they came amongst the confused hills that lay before the great mountains")], unnamed=True)
ent("The great mountains (beyond Whiteness)", "feature", "mountain range",
    "Very great and terrible, dark, bare and stony mountains with great cliffs and crags rising behind Whiteness.",
    [r("C25-P006", "they seemed very great and terrible; dark and bare and stony")])
ent("(unnamed) valley of Whiteness", "feature", "valley", "Valley at whose end Whiteness lies on a long ridge; a long ride from its hither end to the town.",
    [r("C25-P006", "it lay on a long ridge at the end of a valley")], unnamed=True)
ent("Pass to Goldburg", "feature", "mountain pass", "The mountain pass from Whiteness that goes to Goldburg.",
    [r("C25-P008", "toward the mountain pass that goeth to Goldburg")])
ent("House-thralls", "occupation", "household slaves", "Goodly thralls kept to adorn great men's houses; sometimes sent to the fields as punishment.",
    [r("C25-P004", "such goodly wares are kept for the adornment of great men's houses")])

rel("Lord of Whiteness", "vassal_of", "Lord of Cheaping Knowe", "pays tribute for love of peace rather than fear", [r("C25-P007", "he paid tribute to him of Cheaping Knowe, rather for love of peace than for fear of him")], context="") if False else rel("Lord of Whiteness", "vassal_of", "Lord of Cheaping Knowe", "pays tribute for love of peace rather than fear (per Clement)", [r("C25-P007", "he paid tribute to him of Cheaping Knowe, rather for love of peace than for fear of him")])
rel("Lord of Whiteness", "ruler_of", "Whiteness", "", [r("C25-P007", "Of the lord of Whiteness")])

sp("Whiteness", "distance_from", "Cheaping Knowe", [r("C25-P003", "It was some fifty miles thence to Whiteness")], dist="some fifty miles", time="arrived the third day at sunset", mode="horse")
sp("Whiteness", "at_foot_of", "The great mountains (beyond Whiteness)", [r("C25-P003", "which lay close underneath the mountains")])
sp("Whiteness", "leads_to", "Goldburg", [r("C25-P003", "the door of the passes whereby men rode to Goldburg")], terrain="mountain passes")
sp("(unnamed) confused hills before the great mountains", "between", "Cheaping Knowe and The great mountains (beyond Whiteness)", [r("C25-P006", "the confused hills that lay before the great mountains")], cert="constrained")
sp("Whiteness", "within", "(unnamed) valley of Whiteness", [r("C25-P006", "it lay on a long ridge at the end of a valley")], terrain="long ridge at the end of a valley; steep hill")
sp("The great mountains (beyond Whiteness)", "beyond", "Whiteness", [r("C25-P006", "so long was the ridge, that behind it was nothing green; naught but the huge and bare mountains")], cert="fixed",
   note="mountain cliffs 'yet a good way off' from the town")
sp("Whiteness", "visible_from", "(unnamed) valley of Whiteness", [r("C25-P006", "they saw it a long way off")], dist="a long way off", note="White walls catch the westering sun")
sp("(unnamed) thrall-worked tillage between Cheaping Knowe and Whiteness", "between", "Cheaping Knowe and Whiteness", [r("C25-P003", "The land which they passed through was fair")])
sp("Pass to Goldburg", "leads_to", "Goldburg", [r("C25-P008", "the mountain pass that goeth to Goldburg")], context="dialogue:Deacon")
sp("Cheaping Knowe", "route_next", "(unnamed) confused hills before the great mountains", [r("C25-P006", "on the last day of their riding they came amongst the confused hills")], time="last of three days")

tr(["Ralph", "Clement Chapman", "Chapmen (the merchants' Fellowship)", "Bull Shockhead"], "Cheaping Knowe", "Whiteness",
   [r("C25-P002", "rode out a-gates of a mid-morning with banners displayed"), r("C25-P006", "It was not till the third day at sunset that they came to Whiteness")],
   "C25", via=["(unnamed) thrall-worked tillage between Cheaping Knowe and Whiteness", "(unnamed) confused hills before the great mountains", "(unnamed) valley of Whiteness"],
   mode="horse", duration="till the third day at sunset (some fifty miles)", start="mid-morning", end="sunset", terrain="tillage and pasture, then confused hills, then a long valley")
tr(["Bull Nosy", "Ursula (the damsel of the quest)"], "Whiteness", "toward Goldburg (mountain pass)", [r("C25-P008", "the wild man led her away toward the mountain pass that goeth to Goldburg")],
   "C25", via=["Pass to Goldburg"], mode="she on a little horse, hands unbound")

fact("society", "(unnamed) thrall-worked tillage between Cheaping Knowe and Whiteness", "No freemen or villeins work the fields; all field-workers are bought thralls or born of them, worked under the whip.",
     [r("C25-P003", "here be no freemen who work afield, nay, nor villeins either")], context="dialogue:Clement")
fact("agriculture", "(unnamed) thrall-worked tillage between Cheaping Knowe and Whiteness", "Fair tillage and pasture with much cattle; castles and strong-houses dot the land.",
     [r("C25-P003", "Here and there was a castle or strong-house")])
fact("society", "House-thralls", "House-thralls are sometimes sent to the fields as punishment, but it is more profitable to chastise them at home.",
     [r("C25-P004", "whiles the house-thralls be sent into the fields for their punishment")], context="dialogue:Clement")
fact("architecture", "Whiteness", "Walls and towers are not high or strong because the hill is so steep; houses mostly timber, pargeted and whitened; Cheaping Knowe by contrast is all stone.",
     [r("C25-P006", "the walls and towers were not very high or strong, for so steep was the hill whereon the town stood")])
fact("politics", "Whiteness", "Free men live well under the lord of Whiteness.", [r("C25-P007", "free men lived well under him")], context="dialogue:Clement")
fact("trade", "Chapmen (the merchants' Fellowship)", "The chapmen lodge in the market-place at Whiteness.", [r("C25-P008", "So the chapmen lodged in the market-place")])
fact("politics", "Lord of Utterbol", "The Lord of Utterbol had not been in Whiteness these six months.", [r("C25-P008", "the lord of Utterbol had not been in Whiteness these six months")], context="dialogue:Deacon")
fact("trade", "Lord of Utterbol", "The Deacon thinks Utterbol's lord would pay the better penny for the damsel believing he could bend her to his will.",
     [r("C25-P008", "would give him the better penny for her")], context="dialogue:Deacon")

ev("Departure from Cheaping Knowe", "C25", "Chapmen leave Cheaping Knowe with banners, keeping wares for Goldburg.", [r("C25-P002", "rode out a-gates of a mid-morning with banners displayed")])
ev("Arrival at Whiteness", "C25", "Fellowship reaches Whiteness at sunset on the third day.", [r("C25-P006", "It was not till the third day at sunset that they came to Whiteness")], places=["Whiteness"])
ev("Deacon's tidings", "C25", "The Deacon tells Ralph the damsel was brought to Whiteness but not sold, and was led toward the Goldburg pass.",
   [r("C25-P008", "he had turned away thence suddenly with her, without bringing her to the stone")], participants=["Ralph", "Deacon of the Chapmen of Whiteness"])

opp("Plantation lands with thrall barracks as a dark moral backdrop and liberation questline", "quests", [r("C25-P003", "they work not save under the whip")])
opp("Gateway town 'door of the passes' as a hub for mountain-route expeditions", "world map", [r("C25-P003", "the door of the passes whereby men rode to Goldburg")])
