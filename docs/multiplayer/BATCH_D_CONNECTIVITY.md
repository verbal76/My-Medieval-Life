# Multiplayer Batch D: connectivity design (MP-MASTER Batch D, MP-INET, MP-D5, MP-D6)

Worker C, 2026-10-30, branch `wip/mp-batchd` (from Build 24 `4611d86`). Owner sources: MP-D5 and MP-D6
(`docs/directives/2026-10-24_owner_multiplayer_decisions.md`), the master multiplayer directive section 4
(`docs/directives/2026-10-24_master_multiplayer_directive.md`), X20-RESUME section 7
(`docs/directives/2026-10-30_master_development_resumption.md`). Hard limits from the owner: no paid or hosted service, no new
third-party dependency, no Steam integration, and an invite code must never pretend to connect what the network cannot.

## 1. What the game had before Batch D

ENet (UDP) on port 47810, LAN discovery on 47811, join by a typed IPv4 address or host name, a 20-second join timeout in the
join window, no reconnection (a lost connection sent the guest to the title), no duplicate protection beyond ENet's own reliable
channel, Android permissions INTERNET, ACCESS_NETWORK_STATE, ACCESS_WIFI_STATE, CHANGE_WIFI_MULTICAST_STATE already in the preset.

## 2. The facts that decide internet play

A guest can reach a host only if a packet sent to some address of the host arrives at the game. Three things stop it:

1. **The home router (NAT).** A home network shares one public IPv4 address. Unsolicited packets from outside are dropped unless the
   router is told to forward a port to the host's device, by hand (port forwarding) or by the game (UPnP-IGD automatic mapping).
2. **Carrier-grade NAT (CGNAT).** Most mobile data networks, and a growing share of home broadband (fibre and fixed-wireless
   providers especially), put the customer behind a second NAT owned by the provider. The router's "public" address is then itself
   private (100.64.0.0/10, or 10/172.16/192.168). No setting in the customer's hands opens a port; UPnP on the home router maps a
   port on an address nobody outside can reach.
3. **Firewalls.** Windows Firewall asks on first hosting; IPv6 home routers usually block unsolicited inbound IPv6 by default; some
   mobile carriers block inbound IPv6 too, others allow it.

## 3. The options, honestly

| Method | Cost and dependency | Works when | Fails when |
|---|---|---|---|
| **LAN** (discovery or LAN address) | free, built in | same Wi-Fi or home network | different networks; "client isolation" Wi-Fi (hotels, some campus networks); phone hotspots usually work |
| **Direct address + manual port forward** | free; the host configures their router | the host's router has a real public IPv4 address | CGNAT (most mobile data, some broadband); routers the host cannot administer; needs router knowledge (fails the "normal player" bar) |
| **UPnP automatic port mapping** (Godot's built-in `UPNP` class, miniupnpc, already in the official export templates: no new dependency) | free, no account, no server | home broadband with UPnP enabled on the router and a real public IPv4 | UPnP disabled (common default on ISP routers in some countries, often disabled for security); CGNAT or double NAT (the game detects this: the router reports a private or 100.64/10 external address); never on mobile data (no gateway answers) |
| **IPv6 global address** | free, built in (Godot's ENet is dual-stack where the OS has IPv6) | both players have IPv6 and the host's router/carrier lets inbound UDP in | either side IPv4-only; most home routers' default IPv6 firewall; **could not be tested in this container (it has no IPv6)** |
| **UDP hole punching** | needs a **rendezvous** to exchange each side's public address: a hosted introduction server (our own: a small server and its upkeep), or public STUN servers (third-party, free, unpaid; they see both players' addresses) plus a second code typed back from guest to host | both NATs are "cone" (endpoint-independent) types: most home routers | symmetric NAT (common on mobile carriers and some business networks); a punched mapping can expire while idle; the guest-to-host back-code doubles the joining steps |
| **Relay** (all traffic through a server both reach) | a hosted server: our own (a small VPS, bandwidth-billed) or a commercial relay service (accounts, SDKs, usage fees above free tiers) | every network, mobile data hosting included | the relay is down; adds latency; the operator sees the traffic metadata |
| **Virtual LAN app** (Tailscale, ZeroTier, Radmin VPN and similar), the documented workaround the owner allows | free personal tiers today; each player installs it and has that service's account | almost any network, including most CGNAT (they bring their own relays) | the owner ruled it insufficient alone (MP-D5); third-party accounts and privacy terms |
| Steam networking (relay and NAT traversal) | Steam account and SDK | everywhere on Steam | not available on Android; **forbidden now** (no Steam integration) |

## 4. What Batch D implements (all free, no new dependency, no hosted service)

- **Invite code** (`game/scripts/net/net_invite.gd`): the host's window makes a code such as `MML-4V0X2-...` holding the port, a world
  tag and the addresses that can actually work: the host's LAN addresses always; its public IPv4 address **only when the router
  accepted an automatic port mapping and reports a real public address**; a global IPv6 address when the device has one (marked as
  "may work"). A checksum catches typing mistakes. The guest pastes the code (or types an address) in the one field of Join a game;
  the game tries the addresses in order (network first, then IPv6, then the internet address), each with its own timeout, and says
  which kinds were tried when none answered. The window tells the host plainly, before sharing, who the code can reach:
  "your network" or "your network and the internet (your router opened the port)", or why not (no router answer, router refused,
  your provider shares one address: carrier-grade NAT, mobile data).
- **UPnP mapping** (`game/scripts/net/net_upnp.gd`): runs on a background thread when the host opens the world from the window (a
  router search takes up to about six seconds and must not stall the frame); the mapping is removed when hosting stops. Lease 0
  (until removed), the form every IGD version accepts.
- **Direct address** (advanced) stays: IPv4, IPv4:port, host names, and now `[IPv6]:port`.
- **Mobile data told apart:** addresses on a phone's mobile-data interfaces (`rmnet`, `ccmni`, `pdp`, `wwan`, `clat`, by name from
  `IP.get_local_interfaces`) are the carrier's private ones even when they look like a home network's (10.x); they are never put in a
  code as "your network", and the window says nobody outside can reach a phone on mobile data. Interface names vary by phone maker:
  **to be checked on the owner's Pixel**.
- **Connection robustness** (section 5).

What this reaches, plainly: friends on the same network always; friends elsewhere when the host is on home broadband whose router
allows UPnP and has a real public address, or when the host forwards the port by hand; IPv6-to-IPv6 where firewalls allow.
**It does not reach a host on mobile data or behind CGNAT, or a router with UPnP off, without the host's own port forward** (and
CGNAT cannot be forwarded at all). For those, the documented fallback remains a virtual LAN app, which the owner has ruled
insufficient on its own. An honest estimate: well under "most players" for cross-network play; precise shares vary by country and
provider and are not claimed here.

## 5. Interruptions, reconnection and message safety (MP-D1, MP-D6)

- **Timeouts.** ENet peers time out after 4 to 10 seconds without acknowledgement (from ENet's 5 to 30 s defaults). A join tries
  each address with its own limit (LAN 4 s, IPv6 6 s, internet 8 s, a typed address 12 s) and the window's overall limit covers the
  sum.
- **Guest connection drop.** The guest keeps its view (frozen, inputs stopped) and reconnects by itself, with backoff, for up to
  60 seconds (5 minutes when the host said it was paused). On the host, the old connection's character goes out of play as before
  (MP-D1) and returns in play when the guest reconnects, with the same identity. A resume token, given by the host at the welcome and
  never saved, lets the returning connection take over its character even before the host has noticed the old one is dead; without
  the token the existing "already playing" refusal still holds (no duplicate characters, no impersonation by a second copy of the
  identity file).
- **Host gone.** A host that stops hosting says so first (the guest goes to the title, no retries). A host that vanished (killed,
  network lost) is retried for the reconnection window; a restarted host (same world from its save, same port) is joined again
  automatically. Time stops when the host leaves: guests never simulate.
- **Android suspension.** The host's pause (app to background, screen lock) saves the world (as before), tells the guests the host is
  paused (their window widens to five minutes), and on return does not jump the clock by the time spent away (the hosted world's
  first frame back is not simulated as a long step). A guest's pause longer than the ENet timeout reconnects at once on return.
  No claim of background hosting: when Android stops or kills the process, the save made on pause is the recovery point (MP-D6).
- **Duplicated, delayed, reordered requests.** Every guest request carries a number; the guest tells the host its next number when it
  joins. The host applies each number once, in number order (a later one waits up to two seconds for a missing earlier one), answers a
  repeated number from its record of answers without applying it again, and drops a number from before the connection. So a
  repeated purchase, gift, offer answer or crafting request never moves coins or goods twice. Requests that were sent but never
  answered when a connection dropped are not re-sent after reconnecting: the host's world, sent whole at the rejoin, is the truth.
- **Save integrity.** The host saves (atomically, `SaveStore`) when a guest leaves or drops and when it is paused; a guest never
  saves. Coin and goods censuses before and after each fault are compared in the tests.

## 5a. Defects found on the way (fixed on `wip/mp-batchd`)

- A guest beside a chest, table or stall sent the host a request every frame (`container_pick`, a query Batch C mirrored as a verb):
  measured 41 requests in a 3-second walk. Now answered from the guest's copy (`NetSession.LOCAL_QUERIES`).
- Godot's `ENetMultiplayerPeer.disconnect_peer(id, true)` (forced) removes a peer without the disconnect signal, leaving a ghost peer
  in the multiplayer layer that made every broadcast fail ("Invalid target peer"). The superseded connection is now ended gracefully.
- A hello read after its connection was already reported gone could admit a guest on a dead connection; it is now ignored, and the
  host sweeps any guest whose connection the network layer no longer has.

## 6. Decision package for the owner (MP-INET: "a practical connectivity proposal before declaring internet support complete")

**Question.** Real cross-network joining for most players (mobile data, CGNAT broadband, UPnP-off routers) is not reachable by any
free method that needs no server. Which path should be taken?

| Option | What it gives | Cost and dependency | Privacy | Reliability |
|---|---|---|---|---|
| **A. Free methods only (implemented now)** | LAN; UPnP and IPv6 internet where networks allow; manual forward; virtual-LAN fallback documented | none | the invite code holds the host's public address (as a typed address does) | good on LAN; internet unreliable across providers; no mobile-data hosting |
| **B. Hole punching via public STUN, two-way codes** | adds most home-to-home cases without router setup | no paid service, but a third-party free STUN server (unpaid, no SLA) and a second code the guest sends back | the STUN operator sees both players' IPs | fails on symmetric NAT (much of mobile data); medium build effort, real-network testing |
| **C. Our own small rendezvous + relay server** | covers every network, mobile hosting included; invite codes become short (a room code) | one small cloud server and bandwidth: a recurring cost, roughly a few US dollars to low tens a month at this player count (prices to be checked at decision time, not assumed); our upkeep and security | traffic passes our server (encrypt payloads; keep no logs) | high if maintained; single point of failure |
| **D. A commercial relay/NAT service** | as C without running a server | developer account, SDK (new dependency), player accounts on some services; free tiers with caps, then usage fees | the provider's terms | high; vendor lock-in |
| E. Steam networking | everywhere on Steam | — | — | not Android; forbidden now |

**Recommendation:** keep A as the shipped default now, and approve **C** (a minimal self-hosted rendezvous with relay fallback,
spending cap set by the owner) as the path to "internet multiplayer works for a normal player", because it is the only option that
covers mobile data and CGNAT on all three platforms without Steam or a vendor SDK. B is a reasonable intermediate if the owner
wants no recurring cost at all, accepting that much of mobile data still fails. **Default until the owner decides: A** (no server,
no third party, nothing paid). Internet support is **not** declared complete under A.

## 7. What still needs real devices and networks

See `docs/expansion20/MP_TEST_MATRIX.md`, "Batch D cross-platform verification matrix": every host/guest platform pair, LAN and
internet, UPnP on a real router, CGNAT and mobile data refusal messages, IPv6, Android background/lock/network change, Steam Deck.
None of these is verified by the loopback and fault-injection tests here.
