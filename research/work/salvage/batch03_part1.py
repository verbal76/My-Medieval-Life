"""Part 1 of batch_03 builder: helpers, ledger, entities."""

def R(p, q):
    return {"p": p, "q": q}

C = lambda n: f"BONE-C{n}"

chapters = ["BONE-C19", "BONE-C20", "BONE-C21", "BONE-C22", "BONE-C23", "BONE-C24", "BTWO-C1", "BTWO-C2"]

ledger = [
    {"chapter": "BONE-C19", "paragraphs_total": 2, "all_paragraphs_read": True,
     "summary": "In the Castle of Abundance Ralph reads through the short night in a pictured book. It tells of a woman found in the wildwood by a king's son, the wars she caused, her thralldom to a sorceress, her rescue by a Well-seeker, and her finding and drinking of the Well, after which she serves the Well by entangling seekers in love. Ralph recognises her picture as the lady of the want-ways and is love-sick.",
     "geography_notes": "Castle has a hall with windows and a pleasaunce; the sun rises over the wood (wood lies on the sunrise side of the castle, inferred). Legend locations (the lone place in the wildwood, the king's kingdom, the Well) are given no position.",
     "open_questions": ["Where is the lone place in the wildwood of the legend?", "Is the woman of the book the Lady of Abundance (Ralph assumes so)?"]},
    {"chapter": "BONE-C20", "paragraphs_total": 21, "all_paragraphs_read": True,
     "summary": "Ralph walks out armed, crosses the river by a ford with stepping stones below his bathing pool, and is fed milk and bread at a cottar's house by an old woman and her niece; the old woman hints that other men have waited at the castle and describes the Lady bathing in the pool. In the wood south-east of the castle he meets the Vicar of the Little Plain, appointed by the Fathers of the Thorn, who praises the Lady as a holy woman, weeps, and parts from him near the ford by his church. Ralph returns to the castle at sunset.",
     "geography_notes": "River by the castle with a pool (Lady's summer bathing pool, up the water) and a wide ford with stepping stones below it; a cot a little way across the river, nearer the wood; wood lies south and east as well as west and north of the castle; church of the Little Plain with the vicar's cell hard by, near the ford; chapel of St Anthony in the wood.",
     "open_questions": ["Which bank of the river is the castle on relative to the cot and church?", "Where exactly is the chapel of St Anthony and the house of the Thorn?"]},
    {"chapter": "BONE-C21", "paragraphs_total": 18, "all_paragraphs_read": True,
     "summary": "Ralph rereads the book and notes what it does not say (the Lady's origin, the lone place, the road to the Well). Over three restless days he walks into the wood further south but runs back in panic, then spends a day with the haymakers, then a day alone in the castle while the carline visits her brother, a brother of the Thorn. She returns after dark and urges him to go to the wood next day.",
     "geography_notes": "Wood entered more to the south of the castle; hay meadows of the Plain of Abundance worked by carles and queens; the Thorn is 'over yonder', within a day's return errand of the castle.",
     "open_questions": ["Distance from the castle to the Thorn (carline goes and returns the same day)."]},
    {"chapter": "BONE-C22", "paragraphs_total": 26, "all_paragraphs_read": True,
     "summary": "Walking due south from the castle all day, Ralph reaches a great pinewood edging a long lake and finds the Knight of the Sun fighting a black-clad knight before the Lady at three oaks at the east end of the water. The Sun-knight strikes the black knight down, then defeats Ralph; the Lady saves Ralph's life and, threatening to flee on Silverfax to the Dry Tree past the Gliding River, bargains her return to Sunhome with the knight in exchange for Ralph's life and company.",
     "geography_notes": "Due south of the castle, a day's walk: woods of changing character, then a great pine-wood with a green strand and a little lake (later called the Water of the Oak). At the east head of the water a bank rises to the pine-wood, with three great oaks on a sward. From here the ways to the Dry Tree are open, and beyond the Gliding River are Roger of the Ropewalk's men. Sunhome is the Knight's house.",
     "open_questions": ["Direction and distance from the lake to the Dry Tree, the Gliding River and Sunhome.", "The Lady says she was taken 'five days ago', but C19 put the want-ways rescue four days before a point several days earlier."]},
    {"chapter": "BONE-C23", "paragraphs_total": 19, "all_paragraphs_read": True,
     "summary": "The Lady tends Ralph and reveals she was the cloaked lad at the Flower de Luce and in the escape from the Burg. The Knight disarms Ralph as his prisoner and sends him for the horses; they find the black knight, Walter the Black, still alive, and the Lady dresses his wound, saying only her hand can heal him. They have food from Walter's saddle-bags and make him a bracken bed.",
     "geography_notes": "Horses tethered a hundred yards inside the thick wood in a straight line from the oak. Sunway (the Knight's house) is reached through the 'blind woodland'. Lake water is at hand.",
     "open_questions": ["How far is Sunway from the lake?"]},
    {"chapter": "BONE-C24", "paragraphs_total": 26, "all_paragraphs_read": True,
     "summary": "At supper the Lady makes a finger-circle and murmurs; soon after sunset a Blackfriar hermit comes down the water by boat, saying the thornbushes spoke to him in a drowse and bade him help. He takes charge of Walter, plans to move him to his hermitage at the end of the water and later to Sunway. The Knight returns Ralph's arms and urges him to leave; Ralph refuses. They sleep in the 'woodland hall', Ralph by the horses.",
     "geography_notes": "Hermitage lies 'no great way' off, in the thicket at the end of the water; a boat can carry the wounded man there. Sunway is the Knight's home. Deer and fowl about the water.",
     "open_questions": ["Is the hermitage at the far (west) end of the lake? The boat comes 'down the water' yet the hermit says he went 'up the water'."]},
    {"chapter": "BTWO-C1", "paragraphs_total": 29, "all_paragraphs_read": True,
     "summary": "Before dawn the Lady wakes Ralph, has him arm, and leads him through the dark pinewood, across a waste and into thick wood to a stone-strewn clearing behind a hazel copse, about three hours after sunrise. She tells him the Knight of the Sun is her husband who drove her out on the Black Knight's slander, that his brother is the Captain of the Dry Tree, and that she was waylaid near the Water of the Oak. They become lovers.",
     "geography_notes": "From the oak camp: over half an hour through pinewood to a grassy wood-lawn with maples and thorns at the wood's edge (dawn); then a waste with few trees; then thick wood; then a hazel copse enclosing a clearing of great grey stones like a broken doom-ring. The Dry Tree riders had gone north against the Burg. The lake is named the Water of the Oak.",
     "open_questions": ["Direction of travel from the lake is not given in this chapter.", "Who is the 'other man' with the Knight: Walter (implied)."]},
    {"chapter": "BTWO-C2", "paragraphs_total": 12, "all_paragraphs_read": True,
     "summary": "Near noon the pair set off again; the Lady says she whispered to Silverfax to lead her husband a little astray, and that her woodcraft is not sorcery but upbringing. She is taking Ralph not to the Castle of Abundance but toward Hampton under Scaur and the Fellowship of Champions on the rock, two days afoot. In the heat, past two hours after noon, she leads him north to a brook, gathers strawberries, and begins her tale.",
     "geography_notes": "Route from the hazel clearing leads toward Hampton under Scaur (more than two days afoot) and is not the way to the Castle of Abundance. A brook with a green ridge lies a little north of the straightest way, nigh two hours from the hazel lawn.",
     "open_questions": ["Compass direction to Hampton under Scaur.", "Time inconsistency: 'hard on noon' at setting out, then 'past two hours after noon' and 'nigh two hours since we left'."]},
]

E = []
def ent(name, type_, subtype, summary, refs, aliases=None, unnamed=False, attributes=None):
    E.append({"name": name, "aliases": aliases or [], "type": type_, "subtype": subtype,
              "unnamed": unnamed, "summary": summary, "attributes": attributes or {}, "refs": refs})

# ---------- people ----------
ent("Ralph", "person", "young man of Upmeads seeking adventures (parentage given in earlier chapters)",
    "Young man of Upmeads waiting at the Castle of Abundance for the Lady; goes armed but afoot; fights the Knight of the Sun and loses; becomes the Lady's lover.",
    [R("BONE-C22-P019", 'Said the Knight: "Where dost thou come from, where is thine home?"  Said Ralph, "Upmeads."'),
     R("BONE-C24-P027", "he was a young man, and a sturdy, used to lying abroad in the fields or the woods"),
     R("BTWO-C1-P003", "hide thy curly hair with the helm, gird thy sword to thee")],
    aliases=["imp of Upmeads", "Swain of Upmeads", "young man of Upmeads", "the youngling"],
    attributes={"home": "Upmeads", "appearance": "curly hair", "status_C22_C24": "prisoner of the Knight of the Sun by conquest, arms returned in C24"})
ent("The carline of the Castle of Abundance", "person", "old woman keeping the castle",
    "Old woman who serves Ralph at the castle, fetches his war-gear, will tell nothing of import about the Lady, tells tales of the folk and the Fathers of the Thorn; her brother is a brother of the Thorn.",
    [R("BONE-C21-P009", "whatever he asked her about the lady, she would not tell aught of any import"),
     R("BONE-C21-P012", "For I have an errand to my brother in the flesh, who is one of the brethren of the Thorn over yonder."),
     R("BONE-C21-P017", "she fairly threw her arms about him and kissed and clipped him, as though she had been his very mother")],
    aliases=["the carline", "mother"])
ent("The Lady of Abundance", "person", "woman of great beauty, healer, leader of the Dry Tree folk (implied)",
    "The woman Ralph rescued at the want-ways; was the cloaked lad at the Flower de Luce; wife of the Knight of the Sun who drove her out; healer whose hands heal; knows the woodland ways; bred in woods 'though not in these woods'. Called saint and guardian of poor folk by men, feared or hated by women.",
    [R("BONE-C22-P004", "it was the Lady whom he had delivered at the want-ways"),
     R("BTWO-C1-P018", 'She laughed and said:  "Fair creature, he is my husband."'),
     R("BONE-C24-P020", "the Lady of Abundance was here for his helping; for from her hands goeth all healing"),
     R("BTWO-C2-P005", "for in the woods, though not in these woods, was I bred; and here also I am at home")],
    aliases=["Lady of the Forest", "the Lady", "my Queen", "Holy Lady", "saint of the Forest Land"],
    attributes={"appearance": "grey eyes; ruddy hair worn as a garland; 'strong as a knight'", "husband": "Knight of the Sun (Baron of Sunway)", "horse": "Silverfax"})
ent("Knight of the Sun", "person", "baron; lord of Sunway (Sunhome)",
    "Very big knight in a blue surcoat with a great golden sun; husband of the Lady, who cursed and drove her out before they were bedded; brother of the Captain of the Dry Tree; strikes down his sworn friend Walter in jealousy, defeats Ralph, then spares him.",
    [R("BONE-C22-P003", "a very big man with a blue surcoat whereon was beaten a great golden sun"),
     R("BONE-C24-P024", "thou, Baron of Sunway, lie thou betwixt me and the wood"),
     R("BTWO-C1-P022", "for his brother is the Captain of the Dry Tree; the tall man whom thou hast seen with me")],
    aliases=["Baron of Sunway", "the Sun-Knight", "the big knight"],
    attributes={"horse": "bay, strong but heavy", "home": "Sunway / Sunhome", "arms": "blue surcoat with golden sun; sword; anlace"})
ent("Walter the Black", "person", "knight; sworn friend (brother-in-arms) of the Knight of the Sun",
    "Young, goodly, dark-haired knight clad in black over his armour; struck down by the Knight of the Sun and thought dead, but alive with a great wound in the side; once loved the Lady and betrayed her by slandering her as an enchantress.",
    [R("BONE-C23-P011", "this my friend Walter the Black is alive still"),
     R("BONE-C23-P012", "he was a young man, and very goodly to look on, dark haired and straight of feature, fair of face"),
     R("BTWO-C1-P027", "he made a tale of me of true and false mingled, that I was a wise-wife and an enchantress")],
    aliases=["the Black Knight", "Walter"], attributes={"horse": "black horse with saddle-bags"})
ent("Captain of the Dry Tree", "person", "war-captain",
    "Tall/big man seen with the Lady; brother of the Knight of the Sun; Ralph has come across him four times; desires the Lady 'as others have' but would slay no man for her.",
    [R("BTWO-C1-P022", "for his brother is the Captain of the Dry Tree; the tall man whom thou hast seen with me"),
     R("BTWO-C1-P023", "the big captain that I have come across these four times, doth he desire thee also?")],
    aliases=["the big captain", "captain of war (probably)"])
ent("Roger of the Ropewalk", "person", "man of the Dry Tree; leader of men",
    "The Lady says that beyond the Gliding River she would come on Roger and his men; she bade Roger lead Ralph to the Castle of Abundance.",
    [R("BONE-C22-P020", "beyond the Gliding River I shall come on Roger of the Ropewalk and his men"),
     R("BTWO-C1-P024", "have I not told thee that I bade Roger lead thee thither?")], aliases=["Roger"])
ent("Dame Katherine", "person", "Ralph's gossip (godmother)",
    "Gave Ralph a collar like the one the Lady wears; Ralph dreams that his gossip, 'a fair woman, but not a young woman', kissed him.",
    [R("BONE-C22-P004", "on her neck was a collar that seemed to him like to that which Dame Katherine had given him"),
     R("BONE-C23-P006", "me-dreamed that my gossip came to me and kissed me kindly")])
ent("(unnamed) old woman of the cot across the river", "person", "cottar woman, spinner",
    "Old woman spinning at the door of a cot across the river; lecherous and scornful; has had several lovers; with her niece and two other women holds a silken cloth while the Lady bathes; mocks the Lady as 'saint of the Forest Land'.",
    [R("BONE-C20-P002", "A little way across the river, but nigher to the wood, was a house or cot of that country-folk, and an old woman sat spinning in the door."),
     R("BONE-C20-P008", "she hath me and my niece and two other women to hold up the silken cloth betwixt her body and the world")],
    unnamed=True, aliases=["the goody", "the dame", "the carline (of the cot)"])
ent("(unnamed) maiden of the cot, niece of the old woman", "person", "country maiden",
    "Daughter of the old woman's brother; one of the maidens Ralph met fishing; brings him milk and bread; has a sweetheart ('batchelor') but eyes Ralph; holds the Lady's bathing cloth.",
    [R("BONE-C20-P002", "there came forth one of the maidens whom Ralph had met fishing that other day"),
     R("BONE-C20-P006", "she is not my daughter, but my brother's,) there is a man, and a brisk lad too, whom she calleth her batchelor")],
    unnamed=True, aliases=["the damsel"])
ent("(unnamed) batchelor of the niece", "person", "young man of the Little Land",
    "Brisk lad whom the niece calls her batchelor (sweetheart).",
    [R("BONE-C20-P006", "there is a man, and a brisk lad too, whom she calleth her batchelor")], unnamed=True)
ent("(unnamed) Vicar of the Little Plain", "person", "priest; vicar",
    "Clerk riding a hackney with a horse-bell, saddle bags and a book in a bag; appointed by the Fathers of the Thorn to serve the church of the Little Plain and the chapel of St Anthony; has a cell by his church; praises the Lady as holy, weeps, distrusts women.",
    [R("BONE-C20-P012", "came upon a man of religion, a clerk, riding on a hackney, to whose neck hung a horse-bell"),
     R("BONE-C20-P013", "I am the Vicar appointed by the fathers of the Thorn to serve the church of the Little Plain, and the chapel of St. Anthony yonder in the wood")],
    unnamed=True, aliases=["the priest"])
ent("(unnamed) brother of the castle carline", "person", "one of the brethren of the Thorn",
    "The carline's brother in the flesh, a brother of the Thorn 'over yonder'.",
    [R("BONE-C21-P012", "my brother in the flesh, who is one of the brethren of the Thorn over yonder")], unnamed=True)
ent("(unnamed) brother of the cot woman", "person", "father of the niece",
    "The old woman of the cot's brother, father of the maiden.",
    [R("BONE-C20-P006", "she is not my daughter, but my brother's,)")], unnamed=True)
ent("(unnamed) hermit friar of the Water of the Oak", "person", "hermit in the habit of the Blackfriars; leech",
    "Holy man who comes by boat at sunset, somewhat of a leech; keeps goats; his hermitage is in the thicket at the end of the water; says thornbushes spoke to him in a drowse bidding him go to help a man in need.",
    [R("BONE-C24-P008", "it was a holy man, a hermit in the habit of the Blackfriars"),
     R("BONE-C24-P010", "for I am somewhat of a leech"),
     R("BONE-C24-P012", "my hermitage is no great way hence, in the thicket at the end of this water")],
    unnamed=True, aliases=["the Friar", "father"])
ent("(unnamed) butcher slain at the want-ways", "person", "Burg man-at-arms",
    "One of the two men leading the Lady by a halter, slain by Ralph; she rode away on his horse.",
    [R("BTWO-C1-P024", "after I had ridden away on the horse of that butcher whom thou slayedst"),
     R("BONE-C22-P017", "two of their men-at-arms were leading me along by a halter, as a calf is led to the butcher")], unnamed=True)
ent("(unnamed) four faithful friends of the Lady", "group", "her people, rescued from the Burg",
    "Four of the Lady's people who would have been tormented to death by the Burgers; she entered the Burg with her captain of war to deliver them.",
    [R("BONE-C22-P017", "in delivering four of our people, who would else have been tormented to death by the Burgers"),
     R("BONE-C23-P004", "to deliver four faithful friends of mine who were else doomed to an evil death")], unnamed=True)
ent("(unnamed) woman of the book", "person", "legendary woman (identified by Ralph with the Lady)",
    "Woman whom no man could see without loving; dwelt lonely in the wildwood, wedded a king's son, caused long war, became thrall of a sorceress, was borne off by a Well-seeker, found and drank of the Well, and lives yet as servant of the Well.",
    [R("BONE-C19-P002", "much it told of a certain woman whom no man that saw her could forbear to love"),
     R("BONE-C19-P002", "is become the servant of the Well to entangle the seekers in her love and keep them from drinking thereof")], unnamed=True)
ent("(unnamed) king's son of the book", "person", "legendary prince",
    "Found the woman in the wildwood, wedded her against others' will, and was put out of his kingdom for love of her.",
    [R("BONE-C19-P002", "how a king's son found her there and brought her to his father's kingdom and wedded her")], unnamed=True)
ent("(unnamed) sorceress of the wildwood (book)", "supernatural", "witch / sorceress of legend",
    "Woman sorceress in the lone place of the wildwood who made the woman her thrall and tormented her with toil and stripes.",
    [R("BONE-C19-P002", "she found there another woman a sorceress, who made her her thrall; and tormented her grievously with toil and stripes"),
     R("BONE-C21-P002", "why she had yielded herself to the witch of that place")], unnamed=True, aliases=["the witch of that place"])
ent("(unnamed) knight seeking the Well (book)", "person", "legendary knight",
    "Knight seeking the Well at the World's End who bore the woman away from the sorceress and was slain on the way.",
    [R("BONE-C19-P002", "there came a knight to that place who was seeking the Well at the World's End, and bore her away with him")], unnamed=True)
ent("(unnamed) tyrants and robbers of the folk (book)", "group", "legendary captors",
    "Took the woman after the knight was slain, fought among themselves for love of her, and she escaped.",
    [R("BONE-C19-P002", "she was taken by tyrants and robbers of the folk: but these being entangled in her love fought amongst themselves")], unnamed=True)
ent("(unnamed) other kings and lords / warring barons (book)", "group", "legendary rivals",
    "Kings and lords who hankered after the woman, causing long and grievous war.",
    [R("BONE-C19-P002", "because other kings and lords hankered after her; whereof befel long and grievous war"),
     R("BONE-C21-P002", "whereas she might have wedded one of those warring barons who sorely desired her")], unnamed=True)
ent("(unnamed) carle at the ferry", "person", "figure of a folk tale",
    "The carle of the riddle-tale of the fox, the goat and the cabbage at the ferry, cited by the Knight.",
    [R("BONE-C23-P015", "this is much like to the tale of the carle at the ferry with the fox, and the goat, and the cabbage")], unnamed=True)
ent("St. Anthony", "supernatural", "saint",
    "Saint of the chapel in the wood; called the Lady's 'friend'.",
    [R("BONE-C20-P018", "wending this woodland toward the chapel of her friend St. Anthony by night and cloud")])
ent("Saints Agnes, Katherine and Dorothy", "supernatural", "saints named as exemplars",
    "The priest compares the Lady's chastity, wisdom and meekness to these saints.",
    [R("BONE-C20-P018", "yet is she as chaste as Agnes, as wise as Katherine, and as humble and meek as Dorothy")])
ent("Venus", "supernatural", "heathen goddess (comparison)",
    "The priest says the Lady is as fair as Venus.",
    [R("BONE-C20-P018", "she is verily as fair as Venus (God save us)")])
ent("St. Nicholas", "supernatural", "saint (oath)", "Ralph swears by St. Nicholas.",
    [R("BTWO-C2-P010", "Yea, by St. Nicholas, true it is")])
ent("Diana, the Wood-wife of yore", "supernatural", "heathen goddess",
    "The Lady likens herself to the Wood-wife and Goddess of yore; names Diana, the Wood-wife of yore agone.",
    [R("BTWO-C2-P005", "I am both well-knit and light-foot as the Wood-wife and Goddess of yore agone"),
     R("BTWO-C2-P011", "even Diana, the Wood-wife of yore agone, might have fainted somewhat")], aliases=["the Wood-wife"])
ent("Woodwives of the ancient heathen", "supernatural", "heathen wood-spirits",
    "The priest compares the barefoot Lady to the woodwives of the ancient heathen.",
    [R("BONE-C20-P018", "Yea, as fair as the woodwives of the ancient heathen.")])
ent("Ancient devils, the gods of the Gentiles", "supernatural", "demonic race in outward woman's semblance",
    "Ralph asks whether the Lady is one of those with a woman's semblance who are of the race of the ancient devils; the priest is shocked.",
    [R("BONE-C20-P015", "is she of those who outwardly have a woman's semblance, but within are of the race of the ancient devils, the gods of the Gentiles?")])
ent("Wood-wights", "supernatural", "wood spirits",
    "The Lady asks the Knight to lie between her and the wood to ward her from wild deer and wood-wights.",
    [R("BONE-C24-P024", "to ward me from the wild deer and the wood-wights")])
ent("Talking thornbushes", "supernatural", "voices heard in a drowse",
    "The hermit heard the thornbushes speak like men, bidding him take his boat to help a man in need.",
    [R("BONE-C24-P021", "drowsing I heard the thornbushes speaking to me like men, and they bade me take my boat and go up the water to help a man who was in need")])
ent("(unnamed) haymaking folk of the Plain of Abundance", "group", "carles and queens (country men and women)",
    "Haymakers among whom Ralph eats his dinner.",
    [R("BONE-C21-P010", "he went amongst the haymaking folk in the morning and ate his dinner with them"),
     R("BONE-C21-P010", "belike the carles and queens thought him merry company")], unnamed=True)
ent("Fathers of the Thorn", "group", "religious brotherhood",
    "Religious fathers who appoint the vicar of the Little Plain; brethren include the carline's brother; the carline tells tales of them.",
    [R("BONE-C20-P013", "I am the Vicar appointed by the fathers of the Thorn"),
     R("BONE-C21-P009", "tales concerning the folk of the land, and the Fathers of the Thorn")], aliases=["brethren of the Thorn"])
ent("Blackfriars", "group", "order of friars",
    "The hermit wears the habit of the Blackfriars.",
    [R("BONE-C24-P008", "a hermit in the habit of the Blackfriars")])
ent("Burgers / them of the Burg", "group", "people and men-at-arms of the Burg of the Four Friths",
    "Took the Lady five days before C22 and would have tormented her four people to death; the Dry Tree riders have gone north against them.",
    [R("BONE-C22-P017", "five days ago I was taken by them of the Burg"),
     R("BTWO-C1-P025", "since our riders had gone to the north against them of the Burg")])
ent("Riders of the Dry Tree", "group", "mounted war-band ('our riders')",
    "The Lady's riders, who had gone north against the Burg when she set out alone.",
    [R("BTWO-C1-P025", "since our riders had gone to the north against them of the Burg")], aliases=["our riders"])
ent("Fellowship of Champions", "group", "fellowship dwelling on the rock at Hampton under Scaur",
    "Fellowship who dwell on the rock; the Lady's road leads to them.",
    [R("BTWO-C2-P006", "that is that which leadeth to Hampton under Scaur, and the Fellowship of Champions who dwell on the rock")], aliases=["Champions"])
ent("Folk of the Little Land", "group", "inhabitants of the Little Plain / Land of Abundance",
    "Praised by the vicar, save the women; men speak well of the Lady, women fear or hate her.",
    [R("BONE-C20-P021", "the Little Land and the dwellers therein and the conditions of them, and he praised them much, save the women"),
     R("BONE-C21-P003", "whereas all the men-folk spoke well of her and worshipped her, the women-folk feared her or hated her")])
ent("Ralph's brethren and kindred", "group", "family of Upmeads",
    "The Lady asks Ralph about his home in Upmeads and his brethren and kindred.",
    [R("BONE-C24-P005", "she was chiefly asking Ralph of his home in Upmeads, and his brethren and kindred")])
