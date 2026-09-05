# Step 5 Defensive Combat Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:subagent-driven-development (recommended) or
> superpowers:executing-plans to implement this plan task-by-task. Steps use
> checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add one server-authoritative defensive combat package containing
Stamina, directional shield blocking, opening-window parries, forward-roll
dodging with i-frames, Guard Break, prototype defensive feedback/HUD, and a
Training Marauder for manual testing.

**Architecture:** `CombatService` remains the authoritative player-state owner.
`StaminaService` owns Stamina values and regeneration. `DefenseService` owns
incoming-hit defensive resolution and never performs normal health damage.
`DamageService` remains the generic HP mutation boundary. Client code sends
only block/dodge intent and presents replicated state.

**Tech Stack:** Roblox Studio, Luau, Rojo 7.7.0-rc.1, RemoteEvent,
CollectionService, Humanoid, LinearVelocity, Workspace ray/overlap queries,
server Script tests.

**Spec:** `docs/superpowers/specs/2026-09-03-step5-defensive-combat-design.md`

## Global Constraints

- Left Click basic three-hit combo remains free.
- Right Mouse starts block; first 0.18 seconds are the parry window.
- Holding block costs no Stamina but completely pauses Stamina regeneration.
- Block cone is 120 degrees frontal.
- Valid ordinary physical block prevents 100% HP damage.
- Blocked attacks consume source-provided Stamina damage.
- Stamina maximum is 100.
- Dodge costs 25 Stamina.
- Normal Stamina regeneration delay is 1.0 second.
- Stamina regeneration is 25 per second.
- Guard Break lasts 0.8 seconds.
- Guard Break regeneration delay is 1.5 seconds.
- Successful prototype parry costs 0 Stamina.
- Successful parry reports 1.0 second attacker stagger.
- Left Shift is forward-roll Dodge.
- Left Ctrl is View/Screen Lock.
- Dodge direction locks to character facing at dodge start.
- Dodge distance is 9 studs.
- Dodge state lasts about 0.55 seconds.
- Dodge i-frames last about 0.22 seconds from server dodge start.
- Clients never authorize Stamina, defensive success, Guard Break, stagger,
  enemy targets, or HP damage.
- Existing sword attack timings, damage, cleave, and server melee pipeline
  remain intact.
- The final user-facing delivery is one installation package.

---

## File Structure

### New files

- `src/ServerScriptService/Combat/StaminaService.luau`
  - Owns per-player Stamina, spending, regeneration, and replicated attributes.
- `src/ServerScriptService/Combat/DefenseService.luau`
  - Owns block/parry/dodge outcome resolution and defensive Stamina loss.
- `src/ServerScriptService/Combat/TrainingMarauderBuilder.server.luau`
  - Creates the deterministic prototype enemy.
- `src/ServerScriptService/Combat/TrainingMarauderController.server.luau`
  - Runs its slow telegraphed server attack.
- `src/ServerScriptService/Combat/Tests/StaminaServiceTest.server.luau`
- `src/ServerScriptService/Combat/Tests/DefenseServiceTest.server.luau`
- `src/ServerScriptService/Combat/Tests/DefensiveCombatIntegrationTest.server.luau`
- `src/ReplicatedStorage/Combat/Shared/DefenseAnimationFactory.luau`
  - Produces prototype block/roll/Guard-Break presentation definitions without
    introducing a new third-party runtime model.
- `src/StarterPlayerScripts/Combat/StaminaHud.client.luau`
  - Displays replicated Stamina only.

### Modified files

- `src/ReplicatedStorage/Combat/Shared/CombatConfig.luau`
- `src/ReplicatedStorage/Combat/Shared/CombatTypes.luau`
- `src/ReplicatedStorage/Combat/Shared/StateRules.luau`
- `src/ReplicatedStorage/Combat/Remotes.model.json`
- `src/ServerScriptService/Combat/CombatService.server.luau`
- `src/ServerScriptService/Combat/DamageService.luau`
  - Only if a generic incoming-damage helper is required; do not add defensive
    geometry or player-state logic here.
- `src/StarterPlayerScripts/Combat/InputController.client.luau`
- `src/StarterPlayerScripts/Combat/CameraController.client.luau`
- `src/StarterPlayerScripts/Combat/FeedbackController.client.luau`
- `src/ServerScriptService/Combat/PrototypeWeaponFactory.luau`
  - Add the temporary shield only if this remains the cleanest existing
    equipment boundary.

---

### Task 1: Shared Defensive Contract

**Files:**
- Modify: `src/ReplicatedStorage/Combat/Shared/CombatConfig.luau`
- Modify: `src/ReplicatedStorage/Combat/Shared/CombatTypes.luau`
- Modify: `src/ReplicatedStorage/Combat/Shared/StateRules.luau`
- Modify: `src/ReplicatedStorage/Combat/Remotes.model.json`
- Test: `src/ServerScriptService/Combat/Tests/StateRulesTest.server.luau`
- Test: `src/ServerScriptService/Combat/Tests/DefensiveCombatIntegrationTest.server.luau`

**Interfaces:**
- Produces:
  - `CombatTypes.State.BLOCKING`
  - `CombatTypes.State.DODGING`
  - `CombatTypes.State.GUARD_BREAK`
  - `CombatConfig.STAMINA`
  - `CombatConfig.DEFENSE`
  - `CombatConfig.TRAINING_MARAUDER`
  - `CombatConfig.REMOTES.DEFENSE_REQUEST`
  - RemoteEvent `DefenseRequest`

- [ ] **Step 1: Add failing shared-contract assertions**

Add assertions equivalent to:

```lua
assert_true(
    CombatTypes.State.BLOCKING ~= nil,
    "Blocking state must exist."
)

assert_true(
    CombatTypes.State.DODGING ~= nil,
    "Dodging state must exist."
)

assert_true(
    CombatTypes.State.GUARD_BREAK ~= nil,
    "GuardBreak state must exist."
)

assert_true(
    CombatConfig.STAMINA.MAX == 100,
    "Maximum Stamina must be 100."
)

assert_true(
    CombatConfig.STAMINA.DODGE_COST == 25,
    "Dodge must cost 25 Stamina."
)

assert_true(
    CombatConfig.DEFENSE.BLOCK_ARC_DEGREES == 120,
    "Block cone must be 120 degrees."
)

assert_true(
    CombatConfig.DEFENSE.PARRY_WINDOW_SECONDS == 0.18,
    "Parry window must be 0.18 seconds."
)

assert_true(
    CombatConfig.DEFENSE.DODGE_IFRAME_SECONDS == 0.22,
    "Dodge i-frame duration must be 0.22 seconds."
)
```

- [ ] **Step 2: Run Studio and verify the new contract test fails**

Expected failure: one of the new state/config values is missing.

- [ ] **Step 3: Add the shared config**

Use these exact prototype values:

```lua
STAMINA = {
    MAX = 100,
    DODGE_COST = 25,
    REGEN_DELAY_SECONDS = 1.0,
    REGEN_PER_SECOND = 25,
    GUARD_BREAK_REGEN_DELAY_SECONDS = 1.5,
},

DEFENSE = {
    BLOCK_ARC_DEGREES = 120,
    PARRY_WINDOW_SECONDS = 0.18,
    GUARD_BREAK_SECONDS = 0.8,
    PARRY_ATTACKER_STAGGER_SECONDS = 1.0,
    DODGE_DISTANCE_STUDS = 9,
    DODGE_DURATION_SECONDS = 0.55,
    DODGE_IFRAME_SECONDS = 0.22,
},
```

Add:

```lua
TRAINING_MARAUDER = {
    MAX_HEALTH = 200,
    DETECTION_RANGE_STUDS = 12,
    ATTACK_REACH_STUDS = 5.5,
    ATTACK_ARC_DEGREES = 80,
    WIND_UP_SECONDS = 0.8,
    ATTACK_INTERVAL_SECONDS = 2.4,
    HEALTH_DAMAGE = 20,
    STAMINA_DAMAGE = 30,
},
```

- [ ] **Step 4: Add defensive states**

Preserve existing state names and add:

```lua
BLOCKING = "Blocking",
DODGING = "Dodging",
GUARD_BREAK = "GuardBreak",
```

Update `StateRules` so:

```text
Locomotion -> Blocking      allowed
Blocking   -> Locomotion    allowed
Locomotion -> Dodging       allowed
Dodging    -> Locomotion    allowed
Blocking   -> GuardBreak    allowed
Locomotion -> GuardBreak    allowed
GuardBreak -> Locomotion    allowed

WindUp/Active/Recovery -> Blocking     rejected
WindUp/Active/Recovery -> Dodging      rejected
Blocking/Dodging/GuardBreak -> WindUp  rejected
```

- [ ] **Step 5: Add the remote**

Add one `DefenseRequest` RemoteEvent beside `AttackRequest`.

The client payload is only one action string:

```text
BlockStart
BlockEnd
Dodge
```

- [ ] **Step 6: Re-run Studio**

Expected: shared/state tests pass and all existing combat tests remain green.

- [ ] **Step 7: Checkpoint**

```powershell
git diff --check
```

Do not user-commit yet; the final Step 5 delivery is one package.

---

### Task 2: Server-Authoritative Stamina Service

**Files:**
- Create: `src/ServerScriptService/Combat/StaminaService.luau`
- Create: `src/ServerScriptService/Combat/Tests/StaminaServiceTest.server.luau`

**Interfaces:**
- Produces:

```lua
StaminaService.initialize_player(player: Player): ()
StaminaService.reset_player(player: Player): ()
StaminaService.remove_player(player: Player): ()
StaminaService.get(player: Player): number
StaminaService.try_spend(
    player: Player,
    amount: number,
    regen_delay_seconds: number?
): boolean
StaminaService.apply_loss(
    player: Player,
    amount: number,
    regen_delay_seconds: number?
): (number, boolean)
StaminaService.set_regen_paused(
    player: Player,
    paused: boolean
): ()
StaminaService.is_regen_paused(player: Player): boolean
```

Replicated Player attributes:

```text
CombatStamina
CombatMaxStamina
```

- [ ] **Step 1: Write failing Stamina tests**

Cover:

```lua
initialize_player -> 100
try_spend(player, 25) -> true, remaining 75
try_spend with only 20 -> false, remains 20
apply_loss from 20 by 30 -> remaining 0, exhausted true
set_regen_paused(true) -> no regeneration
after release + configured delay -> regeneration begins
regeneration never exceeds 100
```

Use test-only waiting no longer than needed for the real configured timings.

- [ ] **Step 2: Run Studio and verify Stamina tests fail because the module is missing**

- [ ] **Step 3: Implement records**

Internal shape:

```lua
type StaminaRecord = {
    current: number,
    last_spend_at: number,
    regen_delay_seconds: number,
    regen_paused: boolean,
}
```

Use one `RunService.Heartbeat` connection for all active player records.

- [ ] **Step 4: Implement replication**

Whenever current/max changes:

```lua
player:SetAttribute("CombatStamina", record.current)
player:SetAttribute(
    "CombatMaxStamina",
    CombatConfig.STAMINA.MAX
)
```

The client never writes these attributes.

- [ ] **Step 5: Verify GREEN**

Expected: Stamina tests pass and existing suites remain green.

---

### Task 3: Defense Resolution Service

**Files:**
- Create: `src/ServerScriptService/Combat/DefenseService.luau`
- Create: `src/ServerScriptService/Combat/Tests/DefenseServiceTest.server.luau`

**Interfaces:**
- Consumes:
  - `StaminaService.apply_loss`
  - `StaminaService.set_regen_paused`
  - `CombatConfig.DEFENSE`
- Produces:

```lua
export type DefenseContext = {
    attacker: Model?,
    target_player: Player,
    target_character: Model,
    source_kind: string,
    source_id: string,
    attack_position: Vector3?,
    stamina_damage: number,
    blockable: boolean,
    parryable: boolean,
}

export type DefenseResult = {
    outcome: string,
    stamina_spent: number,
    attacker_stagger_seconds: number,
}

DefenseService.begin_block(
    player: Player,
    character: Model,
    started_at: number
): ()

DefenseService.end_block(player: Player): ()

DefenseService.begin_dodge(
    player: Player,
    character: Model,
    started_at: number
): ()

DefenseService.end_dodge(player: Player): ()

DefenseService.clear(player: Player): ()

DefenseService.resolve(
    context: DefenseContext,
    now: number?
): DefenseResult

DefenseService.set_guard_break_handler(
    handler: (Player) -> ()
): ()
```

Outcome strings:

```text
Hit
Blocked
Parried
Dodged
GuardBroken
```

- [ ] **Step 1: Write failing outcome tests**

Construct a defender facing `-Z`.

Test:

```text
Dodging + now <= dodge_started + 0.22 -> Dodged
Blocking + frontal + first 0.18s -> Parried
Blocking + frontal + after 0.18s -> Blocked
Blocking + rear -> Hit
blockable false -> Hit
parryable false during opening window -> Blocked
block with 100 Stamina and stamina_damage 30 -> 70 Stamina
block with 20 Stamina and stamina_damage 30 -> GuardBroken, 0 Stamina
Parried -> 0 Stamina spent, 1.0 attacker stagger
```

- [ ] **Step 2: Run Studio and verify module-missing RED**

- [ ] **Step 3: Implement frontal cone math**

Use planar defender facing and source direction:

```lua
local half_arc =
    CombatConfig.DEFENSE.BLOCK_ARC_DEGREES / 2

local dot = math.clamp(
    defender_forward:Dot(direction_to_attacker),
    -1,
    1
)

local angle = math.deg(math.acos(dot))
local inside_block_cone = angle <= half_arc
```

If `attack_position` is absent, block/parry cannot be directionally proven and
the result is `Hit`.

- [ ] **Step 4: Implement priority order**

Exactly:

```text
1. Dodge i-frame
2. Parry
3. Block / Guard Break
4. Hit
```

A single call returns exactly one outcome.

- [ ] **Step 5: Implement Guard Break callback**

When `apply_loss` reports exhaustion:

```lua
guard_break_handler(player)
```

Return:

```lua
{
    outcome = "GuardBroken",
    stamina_spent = spent,
    attacker_stagger_seconds = 0,
}
```

The triggering attack is still fully negated.

- [ ] **Step 6: Verify GREEN**

Expected: all Defense tests pass.

---

### Task 4: Integrate Defensive States Into CombatService

**Files:**
- Modify: `src/ServerScriptService/Combat/CombatService.server.luau`
- Test: `src/ServerScriptService/Combat/Tests/DefensiveCombatIntegrationTest.server.luau`

**Interfaces:**
- Consumes:
  - `StaminaService`
  - `DefenseService`
  - `DefenseRequest`
- Produces authoritative state transitions and dodge movement.

- [ ] **Step 1: Add integration assertions**

Test the static/behavioral contract:

```text
DefenseRequest exists
CombatService requires StaminaService
CombatService requires DefenseService
Dodge cost remains 25
basic attack config contains no Stamina cost
```

Manual integration tests later verify actual server state.

- [ ] **Step 2: Initialize/reset Stamina on player/character lifecycle**

At player setup:

```lua
StaminaService.initialize_player(player)
```

On new character:

```lua
StaminaService.reset_player(player)
DefenseService.clear(player)
```

On player removal:

```lua
DefenseService.clear(player)
StaminaService.remove_player(player)
```

- [ ] **Step 3: Implement `BlockStart`**

Accept only from `State.LOCOMOTION`.

On accepted start:

```lua
set_state(player, record, State.BLOCKING)
StaminaService.set_regen_paused(player, true)
DefenseService.begin_block(
    player,
    character,
    record.state_started_at
)
```

- [ ] **Step 4: Implement `BlockEnd`**

Only lower guard if currently blocking.

```lua
DefenseService.end_block(player)
StaminaService.set_regen_paused(player, false)
set_state(player, record, State.LOCOMOTION)
```

A release during other states must not force Locomotion.

- [ ] **Step 5: Implement dodge request**

Require:

```text
record.state_name == Locomotion
StaminaService.try_spend(player, 25) == true
character and HumanoidRootPart exist
```

Capture facing once:

```lua
local forward = Vector3.new(
    root.CFrame.LookVector.X,
    0,
    root.CFrame.LookVector.Z
).Unit
```

Set `State.DODGING`, call `DefenseService.begin_dodge`, and move only along
that captured vector.

- [ ] **Step 6: Implement collision-safe 9-stud roll movement**

Raycast forward excluding the character.

Allowed distance:

```lua
local allowed_distance = math.min(
    CombatConfig.DEFENSE.DODGE_DISTANCE_STUDS,
    math.max(0, obstacle_distance - 1.25)
)
```

Use short-lived planar `LinearVelocity` with fixed world direction. Do not
re-read camera or movement direction after dodge start.

- [ ] **Step 7: End dodge**

After `DODGE_DURATION_SECONDS`:

```lua
DefenseService.end_dodge(player)
set_state(player, record, State.LOCOMOTION)
```

Only do so if the same dodge sequence is still current.

- [ ] **Step 8: Wire Guard Break handler**

At CombatService startup:

```lua
DefenseService.set_guard_break_handler(
    function(player: Player)
        -- validate player record
        -- end block
        -- pause/extend regen using Guard Break delay
        -- enter State.GUARD_BREAK
        -- schedule Locomotion after 0.8s
    end
)
```

When Guard Break starts:

```lua
DefenseService.end_block(player)
StaminaService.set_regen_paused(player, false)
```

The Stamina loss has already set the 1.5s regeneration delay.

- [ ] **Step 9: Confirm attack requests remain free and are rejected outside neutral state**

Do not call `StaminaService.try_spend` from `handle_attack_request`.

Existing state checks must naturally reject attack requests while Blocking,
Dodging, or GuardBreak.

- [ ] **Step 10: Verify Studio**

Expected:
- attack tests remain green;
- defensive integration tests pass;
- no new server errors.

---

### Task 5: Client Controls, View Lock, and Stamina HUD

**Files:**
- Modify: `src/StarterPlayerScripts/Combat/InputController.client.luau`
- Modify: `src/StarterPlayerScripts/Combat/CameraController.client.luau`
- Create: `src/StarterPlayerScripts/Combat/StaminaHud.client.luau`
- Test: `src/ServerScriptService/Combat/Tests/DefensiveCombatIntegrationTest.server.luau`

**Interfaces:**
- Consumes `DefenseRequest`.
- Reads Player attributes `CombatStamina` and `CombatMaxStamina`.

- [ ] **Step 1: Change View Lock key**

`CameraController` must use:

```lua
Enum.KeyCode.LeftControl
```

and no longer bind `LeftShift` for camera lock.

- [ ] **Step 2: Add dodge input**

On `LeftShift` begin:

```lua
defense_request:FireServer("Dodge")
```

Do not send direction, distance, Stamina, or i-frame data.

- [ ] **Step 3: Add block input**

On RMB begin:

```lua
defense_request:FireServer("BlockStart")
```

On RMB end:

```lua
defense_request:FireServer("BlockEnd")
```

Do not send parry timing; the server derives it from receipt/state time.

- [ ] **Step 4: Add simple Stamina HUD**

Create `CombatStaminaGui` with one background bar and one fill frame.

Update fill ratio from:

```lua
local current =
    player:GetAttribute("CombatStamina") or 0
local maximum =
    player:GetAttribute("CombatMaxStamina") or 100

fill.Size = UDim2.fromScale(
    math.clamp(current / maximum, 0, 1),
    1
)
```

Connect `GetAttributeChangedSignal` for both attributes.

- [ ] **Step 5: Verify manually**

Expected:
- Ctrl toggles View Lock;
- Shift no longer toggles View Lock;
- Shift requests dodge;
- RMB press/release requests guard;
- Stamina bar shows 100 at spawn.

---

### Task 6: Prototype Shield and Defensive Presentation

**Files:**
- Create: `src/ReplicatedStorage/Combat/Shared/DefenseAnimationFactory.luau`
- Modify: `src/StarterPlayerScripts/Combat/FeedbackController.client.luau`
- Modify: `src/ServerScriptService/Combat/PrototypeWeaponFactory.luau`
- Test: `src/ServerScriptService/Combat/Tests/DefensiveCombatIntegrationTest.server.luau`

**Interfaces:**
- Consumes authoritative combat-state changes/attributes.
- Produces prototype shield visibility and defensive poses only.

- [ ] **Step 1: Add a prototype shield**

Build a simple shield Part/Mesh-free assembly suitable for R15:

```text
PrototypeShield
- Handle
- ShieldBody
```

Attach to the left hand with the same temporary-equipment pattern already used
by the prototype sword.

Do not place any third-party asset in the `.rbxl`.

- [ ] **Step 2: Add defensive presentation definitions**

`DefenseAnimationFactory` produces normalized progress definitions for:

```text
Blocking
Dodging
GuardBreak
ParryFlash
```

The client presentation uses them without determining combat results.

- [ ] **Step 3: Block pose**

While authoritative state is Blocking:

```text
left arm raises shield across torso/front
upper torso turns slightly into guard
right sword arm remains readable
```

Block presentation remains active after the 0.18s parry window; only the
server knows whether an incoming strike is parried.

- [ ] **Step 4: Forward-roll presentation**

During the 0.55s Dodging state:

```text
0.00 -> crouch/commit
0.10 -> torso pitches forward
0.25 -> inverted/rolling midpoint
0.42 -> feet recover under body
0.55 -> upright
```

Use local R15 motor presentation only. Server movement remains the authority
for translation and i-frames.

- [ ] **Step 5: Guard Break presentation**

During GuardBreak:

```text
shield arm knocked outward
upper torso recoils
brief disabled/staggered posture
```

- [ ] **Step 6: Parry feedback**

When the Training Marauder reports a successful parry, show a brief local
flash/sound/debug cue. The cue does not determine the parry result.

- [ ] **Step 7: Verify existing sword attacks still animate correctly**

Check:
- normal carry;
- Slash1;
- Slash2;
- Finisher;
- block transitions back to normal carry;
- roll returns to normal carry.

---

### Task 7: Training Marauder and Incoming Damage Flow

**Files:**
- Create: `src/ServerScriptService/Combat/TrainingMarauderBuilder.server.luau`
- Create: `src/ServerScriptService/Combat/TrainingMarauderController.server.luau`
- Modify: `src/ServerScriptService/Combat/DamageService.luau` only if needed
  for a generic final apply call; no defensive logic may be added there.
- Test: `src/ServerScriptService/Combat/Tests/DefensiveCombatIntegrationTest.server.luau`

**Interfaces:**
- Consumes:
  - `DefenseService.resolve(context)`
  - `DamageService.apply_damage(context)`
  - `CombatConfig.TRAINING_MARAUDER`

- [ ] **Step 1: Build deterministic Marauder**

Create:

```text
TrainingMarauder
- HumanoidRootPart
- Body
- Head
- Humanoid (200 HP)
```

Place it near but separate from the two existing Training Dummies.

Tag it as a combat NPC target so the player's sword can damage it.

- [ ] **Step 2: Add target selection**

At a low-frequency loop, choose the nearest living player inside:

```lua
CombatConfig.TRAINING_MARAUDER
    .DETECTION_RANGE_STUDS
```

The Marauder is stationary and only rotates to face the chosen player.

- [ ] **Step 3: Add readable telegraph**

When ready:

```text
face target
start 0.8s wind-up
show obvious telegraph
lock attack facing near the end
```

Do not continuously home the impact after the attack is committed.

- [ ] **Step 4: Resolve server melee reach/arc**

At impact, require:

```text
target still alive
planar distance <= 5.5 studs
target lies within 80-degree attack arc
solid geometry does not block the strike
```

- [ ] **Step 5: Call DefenseService first**

Use:

```lua
local result = DefenseService.resolve({
    attacker = marauder,
    target_player = player,
    target_character = character,
    source_kind = "EnemyMelee",
    source_id = "TrainingMarauderStrike",
    attack_position = marauder_root.Position,
    stamina_damage = 30,
    blockable = true,
    parryable = true,
})
```

- [ ] **Step 6: Apply result**

```text
Dodged      -> no HP damage
Parried     -> no HP damage; stagger Marauder for returned duration
Blocked     -> no HP damage
GuardBroken -> no HP damage on triggering strike
Hit          -> DamageService applies exactly 20 HP damage
```

For the undefended hit:

```lua
DamageService.apply_damage({
    attacker = nil,
    attacker_character = marauder,
    target = character,
    source_kind = "EnemyMelee",
    source_id = "TrainingMarauderStrike",
    attack_id = nil,
    base_damage = 20,
    multiplier = 1,
})
```

`DamageService` must support a player character Model as an already-authorized
target; target legality for this enemy-owned hit is established before the
generic apply call.

- [ ] **Step 7: Respect parry stagger**

Store:

```lua
staggered_until = os.clock()
    + result.attacker_stagger_seconds
```

Do not begin a new attack until that timestamp expires.

- [ ] **Step 8: Verify manual scenarios**

Run all:

```text
No defence:
    20 HP lost.

Hold frontal block:
    0 HP lost.
    30 Stamina lost.
    Regen paused while holding.

Press block just before impact:
    Parry.
    0 HP / 0 Stamina lost.
    Marauder pauses about 1 second.

Block until low Stamina:
    Triggering hit gives Guard Break.
    0 HP on break-causing hit.
    Player staggered about 0.8 seconds.

Shift during impact:
    Forward roll.
    25 Stamina spent.
    Impact during first 0.22s gives Dodged.

Stand with Marauder behind player while blocking:
    20 HP lost.

Put wall between them:
    no hit.
```

---

### Task 8: Security, Regression, and One-Package Delivery

**Files:**
- All Step 5 files
- Create delivery archive outside repo:
  `DungeonMMO_Step5_Defensive_Combat.zip`

**Interfaces:**
- Produces one PowerShell installer for the user.

- [ ] **Step 1: Run all Studio test suites**

Required green groups include existing:

```text
Combat Tests
Combat Animation Tests
Combat Weapon Tests
One-Handed Sword Tests
Sword Carry/Grip Tests
Combat Target Rules Tests
Damage Service Tests
Melee Hit Service Tests
Swept Melee Damage Tests
Training Dummy Tests
Finisher Hit Shape Tests
```

and new:

```text
Stamina Service Tests
Defense Service Tests
Defensive Combat Integration Tests
```

- [ ] **Step 2: Run client security scan**

Search client Luau:

```powershell
Get-ChildItem `
    ".\src\StarterPlayerScripts" `
    -Recurse `
    -Filter "*.luau" |
    Select-String `
        -Pattern "TakeDamage|Health\s*=|CombatStamina\s*=|GuardBreak|Parried"
```

Review each match.

Allowed:
- presentation names;
- reading replicated attributes;
- sending `BlockStart`, `BlockEnd`, `Dodge`.

Not allowed:
- client health mutation;
- client Stamina mutation;
- client decision that an attack was blocked/parried/dodged.

- [ ] **Step 3: Verify no basic-attack Stamina spend**

Search server code:

```powershell
Select-String `
    -Path ".\src\ServerScriptService\Combat\CombatService.server.luau" `
    -Pattern "try_spend|DODGE_COST|handle_attack_request" `
    -Context 2,4
```

Confirm `try_spend` occurs only in defensive action handling, not the basic
attack path.

- [ ] **Step 4: Run Rojo build**

```powershell
rojo build `
    ".\default.project.json" `
    -o ".\backups\Step5FinalValidation.rbxl"

if ($LASTEXITCODE -ne 0) {
    throw "Step 5 Rojo build failed."
}
```

- [ ] **Step 5: Run whitespace verification**

```powershell
git diff --check

if ($LASTEXITCODE -ne 0) {
    throw "Step 5 diff check failed."
}
```

- [ ] **Step 6: Build one guarded installer**

The installer must:

1. Require project root:
   `C:\Users\Remko\Documents\Roblox\DungeonMMO`.
2. Back up every modified source file under `.\backups`.
3. Refuse to patch if expected current source anchors are absent.
4. Copy all new Step 5 modules/tests/client files.
5. Modify existing source only from source snapshots inspected immediately
   before package creation.
6. Run `rojo build`.
7. Run `git diff --check`.
8. Tell the user to Play in Studio and perform the manual acceptance sequence.
9. Not stage, commit, push, or modify `DungeonMMO.rbxl`.

- [ ] **Step 7: Final manual acceptance**

Required:

```text
Ctrl toggles View Lock
Shift performs forward roll
Dodge spends 25 Stamina
RMB blocks
Block pauses regen
Frontal block spends 30 Stamina and 0 HP
Opening-window parry spends 0 Stamina and staggers Marauder
Rear attack bypasses block
Guard Break occurs at zero
Dodge i-frames avoid correctly timed strike
Player sword still hits Marauder/dummies
Slash1 = 10
Slash2 = 10.5
Finisher = 13.5
Finisher remains narrow/forward-focused
```

- [ ] **Step 8: Commit only after acceptance**

After the user confirms manual feel:

```powershell
git add -A ".\src" ".\docs"

git diff --cached --check

git commit -m "feat: add defensive combat prototype"
```

Keep `DungeonMMO.rbxl` unstaged until the third-party animation-source
dependency has been deliberately cleaned up.

---

## Plan Self-Review

### Spec coverage

Covered:

- Stamina ownership, cost, pause, delay, and regeneration.
- Free basic attacks.
- RMB block and 0.18s parry window.
- 120-degree frontal shield cone.
- Full ordinary physical block.
- Guard Break timing and triggering-hit behavior.
- Shift forward roll, fixed facing direction, distance, i-frames, and collision.
- Ctrl View Lock.
- Prototype shield.
- Defensive feedback and Stamina HUD.
- Modular `StaminaService` and `DefenseService`.
- Training Marauder.
- Server-owned incoming hit resolution.
- Client-security rules.
- Regression coverage.
- One-package delivery.

### Placeholder scan

No `TBD`, `TODO`, or unspecified implementation steps remain.

### Type consistency

The service names and signatures used by later tasks match the interfaces
defined by Tasks 2 and 3.
