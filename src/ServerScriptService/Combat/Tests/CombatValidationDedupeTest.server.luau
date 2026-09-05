local DedupeRules = require(
    script.Parent.Parent:WaitForChild("CombatValidationDedupeRules")
)

local tracker = DedupeRules.new_tracker()

assert(
    DedupeRules.should_publish(tracker, "HIT", "REJECT", "Slash1 Marauder Arc", 1),
    "first rejection in a sequence must be visible"
)
assert(
    not DedupeRules.should_publish(tracker, "HIT", "REJECT", "Slash1 Marauder Arc", 1),
    "identical rejection in the same sequence must be collapsed"
)
assert(
    DedupeRules.should_publish(tracker, "HIT", "REJECT", "Slash1 Marauder Range", 1),
    "different rejection detail must remain visible"
)
assert(
    DedupeRules.should_publish(tracker, "HIT", "REJECT", "Slash1 Marauder Arc", 2),
    "same rejection in a new attack sequence must be visible again"
)
assert(
    DedupeRules.should_publish(tracker, "LIFECYCLE", "RESPAWN", "Locomotion", 0),
    "lifecycle events must remain visible and reset the tracked sequence"
)
assert(
    DedupeRules.should_publish(tracker, "HIT", "REJECT", "Slash1 Marauder Arc", 2),
    "same numeric sequence after lifecycle reset must be visible again"
)
assert(
    DedupeRules.should_publish(tracker, "ATTACK", "REJECT", "State=WindUp", 2),
    "non-hit rejects must not be collapsed"
)
assert(
    DedupeRules.should_publish(tracker, "ATTACK", "REJECT", "State=WindUp", 2),
    "repeated non-hit rejects must remain diagnostic"
)

print("[Combat Validation Dedupe Tests] PASS")
