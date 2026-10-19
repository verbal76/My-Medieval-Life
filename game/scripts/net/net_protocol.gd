class_name NetProtocol
extends RefCounted
## MP-01 player-hosted multiplayer: the shared protocol facts (docs/MULTIPLAYER.md).
## The host runs the only simulation; guests send requests, the host decides and sends results.
## Ports: the game itself over ENet (UDP) on GAME_PORT, LAN discovery as small UDP datagrams on
## DISCOVERY_PORT. A guest's lasting identity is a random key kept on their own device
## (user://identity.cfg); the host keeps only its SHA-256 hash, so the key itself is never stored
## in a world save or shown to anyone.

const VERSION := "mml-net/1"          # bump on any protocol change: a host and a guest must match exactly
const GAME_PORT := 47810
const DISCOVERY_PORT := 47811
const DISCOVER := "MML_DISCOVER/1"    # a guest's broadcast query
const MAX_PLAYERS := 4                # the host and up to three guests (owner: 2-4 players at first)
const PLAYERS_HZ := 10.0              # player positions to every guest, per second
const NPCS_HZ := 4.0                  # villagers near each guest, per second
const MOVE_HZ := 15.0                 # a guest's position requests, per second
const NPC_RANGE := 24.0               # tiles: villagers farther from a guest are not sent to them
const IDENTITY_PATH := "user://identity.cfg"


## The full version a host and guest compare: the protocol and the save format must both match.
static func full_version() -> String:
	return "%s save-%d" % [VERSION, World.SAVE_VERSION]


## This device's lasting player key (made once, then kept). `path` lets tests use their own.
static func identity_key(path := IDENTITY_PATH) -> String:
	var cfg := ConfigFile.new()
	if cfg.load(path) == OK and str(cfg.get_value("player", "key", "")).length() == 32:
		return str(cfg.get_value("player", "key"))
	var c := Crypto.new()
	var key := c.generate_random_bytes(16).hex_encode()
	cfg.set_value("player", "key", key)
	cfg.save(path)
	return key


## What the host keeps of a key: its hash, never the key.
static func key_hash(key: String) -> String:
	return key.sha256_text()


## A session password is sent hashed with the host's per-session salt, never in clear.
static func password_hash(password: String, salt: String) -> String:
	return (salt + ":" + password).sha256_text() if password != "" else ""
