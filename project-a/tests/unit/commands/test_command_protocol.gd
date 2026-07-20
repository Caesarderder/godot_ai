extends GutTest

const CommandClassRegistry := preload(
	"res://game/scripts/commands/command_class_registry.gd"
)
const CommandFingerprint := preload("res://game/scripts/commands/command_fingerprint.gd")


func test_registry_seals_every_supported_command_family() -> void:
	var expected: Dictionary = {
		"recruit_hero": CommandClassRegistry.DURABLE_VALUE,
		"train_hero": CommandClassRegistry.DURABLE_VALUE,
		"enhance_item": CommandClassRegistry.DURABLE_VALUE,
		"upgrade_facility": CommandClassRegistry.DURABLE_VALUE,
		"claim_reward": CommandClassRegistry.DURABLE_VALUE,
		"settle_battle_result": CommandClassRegistry.DURABLE_VALUE,
		"settle_offline": CommandClassRegistry.DURABLE_VALUE,
		"reserve_battle_attempt": CommandClassRegistry.DURABLE_VALUE,
		"__lifecycle_pause_anchor": CommandClassRegistry.INTERNAL_DURABLE,
		"__lifecycle_heartbeat_anchor": CommandClassRegistry.INTERNAL_DURABLE,
		"__lifecycle_resume_settle": CommandClassRegistry.INTERNAL_DURABLE,
		"set_formation": CommandClassRegistry.REVERSIBLE_META,
		"equip_item": CommandClassRegistry.REVERSIBLE_META,
		"unequip_item": CommandClassRegistry.REVERSIBLE_META,
		"set_roster_filter": CommandClassRegistry.REVERSIBLE_META,
		"rename_hero": CommandClassRegistry.REVERSIBLE_META,
		"navigate_screen": CommandClassRegistry.EPHEMERAL,
		"open_detail": CommandClassRegistry.EPHEMERAL,
		"battle_tick": CommandClassRegistry.EPHEMERAL,
		"play_vfx": CommandClassRegistry.EPHEMERAL,
		"sort_preview": CommandClassRegistry.EPHEMERAL,
	}
	for command_type: String in expected:
		assert_eq(
			CommandClassRegistry.classify(StringName(command_type)),
			expected[command_type],
			command_type
		)


func test_registry_rejects_unknown_types_and_identifies_only_internal_types() -> void:
	assert_eq(CommandClassRegistry.classify(&"not_registered"), CommandClassRegistry.UNKNOWN)
	assert_true(CommandClassRegistry.is_internal(&"__lifecycle_pause_anchor"))
	assert_false(CommandClassRegistry.is_internal(&"settle_offline"))
	assert_false(CommandClassRegistry.is_internal(&"not_registered"))


func test_caller_class_field_cannot_override_registry_classification() -> void:
	var caller_envelope := {
		"type": "claim_reward",
		"command_class": CommandClassRegistry.EPHEMERAL,
	}
	assert_eq(
		CommandClassRegistry.classify(StringName(caller_envelope["type"])),
		CommandClassRegistry.DURABLE_VALUE
	)


func test_canonical_json_sorts_dictionary_keys_by_utf8_bytes() -> void:
	var result: Dictionary = CommandFingerprint.canonical_json({"中": 3, "ä": 2, "z": 1})
	assert_true(result["ok"])
	assert_eq(result["value"], "{\"z\":1,\"ä\":2,\"中\":3}")


func test_canonical_json_encodes_nested_arrays_and_dictionaries_without_whitespace() -> void:
	var result: Dictionary = CommandFingerprint.canonical_json(
		{"outer": [null, true, false, {"b": "line\n\"quoted\"", "a": -7}]}
	)
	assert_true(result["ok"])
	assert_eq(
		result["value"],
		"{\"outer\":[null,true,false,{\"a\":-7,\"b\":\"line\\n\\\"quoted\\\"\"}]}"
	)


func test_canonical_json_rejects_float_object_resource_and_non_string_keys() -> void:
	var node := Node.new()
	var resource := Resource.new()
	assert_false(CommandFingerprint.canonical_json({"value": 1.0})["ok"])
	assert_false(CommandFingerprint.canonical_json([node])["ok"])
	assert_false(CommandFingerprint.canonical_json({"resource": resource})["ok"])
	assert_false(CommandFingerprint.canonical_json({1: "not a string key"})["ok"])
	node.free()


func test_calculate_rejects_an_invalid_payload() -> void:
	var result: Dictionary = CommandFingerprint.calculate(
		"claim_reward", {"amount": 1.5}, "daily:1"
	)
	assert_false(result["ok"])
	assert_eq(result["error"], "INVALID_PAYLOAD")


func test_fingerprint_matches_independently_assembled_length_prefixed_sha256() -> void:
	var command_type := "claim_reward"
	var payload := {"reward_id": "每日", "step": 4}
	var business_key := "quest:每日:4"
	var canonical_payload := "{\"reward_id\":\"每日\",\"step\":4}"
	var bytes := PackedByteArray()
	for segment: String in [command_type, canonical_payload, business_key]:
		var encoded := segment.to_utf8_buffer()
		var length := encoded.size()
		bytes.append((length >> 24) & 0xff)
		bytes.append((length >> 16) & 0xff)
		bytes.append((length >> 8) & 0xff)
		bytes.append(length & 0xff)
		bytes.append_array(encoded)
	var hashing := HashingContext.new()
	assert_eq(hashing.start(HashingContext.HASH_SHA256), OK)
	assert_eq(hashing.update(bytes), OK)
	var expected: String = hashing.finish().hex_encode()
	var result: Dictionary = CommandFingerprint.calculate(command_type, payload, business_key)
	assert_true(result["ok"])
	assert_eq(result["canonical_payload"], canonical_payload)
	assert_eq(result["fingerprint"], expected)
