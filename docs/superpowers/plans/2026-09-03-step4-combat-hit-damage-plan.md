# Step 4 Combat Hit and Damage Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:subagent-driven-development (recommended) or
> superpowers:executing-plans to implement this plan task-by-task. Steps use
> checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add server-authoritative sword hit detection and NPC damage with
cleave, swept Active-window sampling, per-swing deduplication, wall blocking,
and a reusable target/damage pipeline that future projectiles and AoE effects
can share.

**Architecture:** `CombatService` continues to own attack state and timing.
When an attack enters Active, it calls `MeleeHitService`, which owns melee
target acquisition only. `CombatTargetRules` decides whether a candidate may
be damaged, and `DamageService` calculates/applies generic damage context.
Future `ProjectileService` and `AreaEffectService` will reuse
`CombatTargetRules` and `DamageService` without depending on melee geometry.

**Tech Stack:** Roblox Studio, Luau, Rojo 7.7.0-rc.1, Roblox
`Workspace:GetPartBoundsInBox`, `RaycastParams`, `OverlapParams`,
`CollectionService`, `Humanoid`, server Script tests.

**Spec:** `docs/superpowers/specs/2026-09-03-step4-combat-hit-damage-design.md`

## Global Constraints

- Client requests attack intent only; client never supplies hit target or
  damage amount.
- Combat state, Active window, target acquisition, validation, damage math,
  and health mutation are server-owned.
- Step 4 damages tagged NPC combat targets only.
- Player characters are rejected until PvP-area rules are designed later.
- One swing may cleave multiple valid NPCs.
- One target may be damaged at most once per swing.
- Solid level geometry blocks melee hits.
- Health storage is `Humanoid.Health`.
- Prototype sword damage is `10 * attack multiplier`.
- Existing Slash1, Slash2, and Finisher multipliers remain 1.00, 1.05, 1.35.
- Damage is not rounded internally.
- Existing combat/animation/weapon tests must remain green.
- Ranged and AoE delivery are not implemented in Step 4.
- `DamageService` and `CombatTargetRules` must remain independent of melee
  geometry so future projectile and area-effect systems can reuse them.

---

## File Structure

### New files

- `src/ServerScriptService/Combat/CombatTargetRules.luau`
  - Owns target legality only.
- `src/ServerScriptService/Combat/DamageService.luau`
  - Owns generic damage calculation and `Humanoid` health mutation.
- `src/ServerScriptService/Combat/MeleeHitService.luau`
  - Owns melee overlap sampling, arc/range filtering, obstruction checks,
    per-swing deduplication, and hand-off to `DamageService`.
- `src/ServerScriptService/Combat/TrainingDummyBuilder.server.luau`
  - Creates deterministic tagged NPC targets in the greybox arena.
- `src/ServerScriptService/Combat/Tests/CombatTargetRulesTest.server.luau`
- `src/ServerScriptService/Combat/Tests/DamageServiceTest.server.luau`
- `src/ServerScriptService/Combat/Tests/MeleeHitServiceTest.server.luau`

### Modified files

- `src/ReplicatedStorage/Combat/Shared/CombatConfig.luau`
  - Adds target tag, base sword damage, hit-volume data, and debug toggles.
- `src/ReplicatedStorage/Combat/Shared/CombatTypes.luau`
  - Adds shared damage-context type definitions where useful.
- `src/ServerScriptService/Combat/CombatService.server.luau`
  - Calls `MeleeHitService.begin_active_window(...)` exactly when the
    authoritative attack enters Active.
- `src/ServerScriptService/Combat/Tests/StateRulesTest.server.luau`
  - Only modified if shared config/type changes require an assertion update;
    combat timing rules themselves remain unchanged.

---

### Task 1: NPC Target Contract and `CombatTargetRules`

**Files:**
- Modify:
  `src/ReplicatedStorage/Combat/Shared/CombatConfig.luau`
- Create:
  `src/ServerScriptService/Combat/CombatTargetRules.luau`
- Create:
  `src/ServerScriptService/Combat/Tests/CombatTargetRulesTest.server.luau`

**Interfaces:**
- Consumes:
  - `Player:GetPlayerFromCharacter(Model)`
  - `CollectionService:HasTag(Model, CombatConfig.TARGETS.NPC_TAG)`
- Produces:
  - `CombatTargetRules.is_damageable(attacker_character, target_model)`
    returning `(boolean, string)`.
  - `CombatConfig.TARGETS.NPC_TAG = "CombatTarget"`.

- [ ] **Step 1: Add the failing target-rules test**

Create deterministic test Models with `Humanoid` children and verify:

```lua
local valid, reason =
    CombatTargetRules.is_damageable(
        attacker,
        tagged_npc
    )

assert_true(valid, reason)
```

The RED test must cover:

```lua
tagged living NPC       -> true
untagged NPC             -> false
dead tagged NPC          -> false
attacker model           -> false
player character         -> false
nil target               -> false
model without Humanoid   -> false
```

Before implementation, the test must fail because
`CombatTargetRules` does not exist.

- [ ] **Step 2: Run Studio Play and verify RED**

Run:

```powershell
rojo build `
    ".\default.project.json" `
    -o ".\backups\Step4TargetRulesRed.rbxl"
```

Then press Play in Studio.

Expected failure contains:

```text
CombatTargetRules
```

Existing test suites must still run independently.

- [ ] **Step 3: Implement `CombatTargetRules`**

Core interface:

```lua
function CombatTargetRules.is_damageable(
    attacker_character: Model?,
    target_model: Model?
): (boolean, string)
```

Validation order:

```lua
if not target_model then
    return false, "MissingTarget"
end

if target_model == attacker_character then
    return false, "Self"
end

if Players:GetPlayerFromCharacter(target_model) then
    return false, "PlayerTargetDisabled"
end

if not CollectionService:HasTag(
    target_model,
    CombatConfig.TARGETS.NPC_TAG
) then
    return false, "NotCombatTarget"
end

local humanoid = target_model:FindFirstChildOfClass(
    "Humanoid"
)

if not humanoid then
    return false, "MissingHumanoid"
end

if humanoid.Health <= 0 then
    return false, "Dead"
end

return true, "Accepted"
```

Keep this module independent from sword hitboxes, overlap queries, rays, and
damage formulas.

- [ ] **Step 4: Run Studio Play and verify GREEN**

Expected:

```text
[Combat Target Rules Tests] PASS: ...
```

And all pre-existing test suites remain green.

- [ ] **Step 5: Commit Task 1**

```powershell
git add `
    ".\src\ReplicatedStorage\Combat\Shared\CombatConfig.luau" `
    ".\src\ServerScriptService\Combat\CombatTargetRules.luau" `
    ".\src\ServerScriptService\Combat\Tests\CombatTargetRulesTest.server.luau"

git diff --cached --check

git commit -m "feat: add combat target validation"
```

---

### Task 2: Generic `DamageService`

**Files:**
- Modify:
  `src/ReplicatedStorage/Combat/Shared/CombatConfig.luau`
- Modify:
  `src/ReplicatedStorage/Combat/Shared/CombatTypes.luau`
- Create:
  `src/ServerScriptService/Combat/DamageService.luau`
- Create:
  `src/ServerScriptService/Combat/Tests/DamageServiceTest.server.luau`

**Interfaces:**
- Consumes:
  - already validated target Model;
  - generic damage context.
- Produces:
  - `DamageService.calculate_damage(base_damage, multiplier): number`
  - `DamageService.apply_damage(context): number`

Use this initial context shape:

```lua
export type DamageContext = {
    attacker: Player?,
    attacker_character: Model?,
    target: Model,
    source_kind: string,
    source_id: string,
    attack_id: string?,
    base_damage: number,
    multiplier: number,
}
```

- [ ] **Step 1: Write the failing damage tests**

Test:

```lua
assert_equal(
    DamageService.calculate_damage(10, 1.00),
    10
)

assert_equal(
    DamageService.calculate_damage(10, 1.05),
    10.5
)

assert_equal(
    DamageService.calculate_damage(10, 1.35),
    13.5
)
```

Also create a Model with a Humanoid at 100 health and verify
`apply_damage(...)` lowers it by the exact decimal amount.

The RED test must fail because `DamageService` does not exist.

- [ ] **Step 2: Run Studio Play and verify RED**

Expected failure contains:

```text
DamageService
```

- [ ] **Step 3: Implement the minimal generic service**

`calculate_damage`:

```lua
function DamageService.calculate_damage(
    base_damage: number,
    multiplier: number
): number
    return math.max(
        0,
        base_damage * multiplier
    )
end
```

`apply_damage`:

```lua
function DamageService.apply_damage(
    context: CombatTypes.DamageContext
): number
    local humanoid =
        context.target:FindFirstChildOfClass("Humanoid")

    if not humanoid or humanoid.Health <= 0 then
        return 0
    end

    local damage =
        DamageService.calculate_damage(
            context.base_damage,
            context.multiplier
        )

    humanoid:TakeDamage(damage)

    return damage
end
```

`DamageService` must not perform target search or call
`CombatTargetRules`; delivery systems are responsible for supplying already
validated targets.

Add:

```lua
CombatConfig.PROTOTYPE_WEAPON.BASE_DAMAGE = 10
```

to the existing prototype-weapon configuration rather than creating a
second sword-damage constant elsewhere.

- [ ] **Step 4: Run Studio Play and verify GREEN**

Expected:

```text
[Damage Service Tests] PASS: ...
```

- [ ] **Step 5: Commit Task 2**

```powershell
git add `
    ".\src\ReplicatedStorage\Combat\Shared\CombatConfig.luau" `
    ".\src\ReplicatedStorage\Combat\Shared\CombatTypes.luau" `
    ".\src\ServerScriptService\Combat\DamageService.luau" `
    ".\src\ServerScriptService\Combat\Tests\DamageServiceTest.server.luau"

git diff --cached --check

git commit -m "feat: add generic combat damage service"
```

---

### Task 3: Melee Geometry, Cleave, Deduplication, and Obstruction

**Files:**
- Modify:
  `src/ReplicatedStorage/Combat/Shared/CombatConfig.luau`
- Create:
  `src/ServerScriptService/Combat/MeleeHitService.luau`
- Create:
  `src/ServerScriptService/Combat/Tests/MeleeHitServiceTest.server.luau`

**Interfaces:**
- Consumes:
  - authoritative attacker character;
  - attack id;
  - attack definition from `CombatConfig`;
  - `CombatTargetRules`;
  - `DamageService`.
- Produces:
  - `MeleeHitService.collect_targets(context, already_hit): {Model}`
  - `MeleeHitService.begin_active_window(context): ()`

Initial context:

```lua
export type MeleeSwingContext = {
    attacker: Player,
    character: Model,
    attack_id: string,
    attack_definition: any,
    base_damage: number,
}
```

Add per-attack hitbox configuration:

```lua
HITBOX = {
    SIZE = Vector3.new(width, 5, depth),
    FORWARD_OFFSET = depth / 2,
    SAMPLE_COUNT = 4,
}
```

Keep existing `REACH` and `ARC_DEGREES`; use them as a second-stage planar
range/angle filter after broad-phase overlap.

- [ ] **Step 1: Write deterministic RED tests**

Create a temporary test arena far from the normal greybox and construct:

```text
attacker at origin facing -Z
front NPC
out-of-range NPC
behind NPC
edge-of-arc NPC
second valid NPC for cleave
wall-blocked NPC
```

All NPCs use the `"CombatTarget"` tag.

Call only synchronous:

```lua
local targets =
    MeleeHitService.collect_targets(
        context,
        already_hit
    )
```

The test must cover:

```text
front target                 -> returned
beyond reach                 -> absent
behind attacker              -> absent
edge target inside arc       -> returned
two valid NPCs               -> both returned
already_hit[target] = true   -> absent
wall between attacker/NPC    -> absent
```

The RED test must fail because `MeleeHitService` does not exist.

- [ ] **Step 2: Run Studio Play and verify RED**

Expected failure contains:

```text
MeleeHitService
```

- [ ] **Step 3: Implement broad-phase overlap**

Build the query transform from the server root:

```lua
local hitbox_cf =
    root.CFrame
    * CFrame.new(
        0,
        0,
        -hitbox.FORWARD_OFFSET
    )

local parts = Workspace:GetPartBoundsInBox(
    hitbox_cf,
    hitbox.SIZE,
    overlap_params
)
```

`OverlapParams` must exclude the attacker's character.

Resolve a part to its nearest ancestor Model containing a Humanoid.

Do not apply damage in `collect_targets`; return newly accepted Models.

- [ ] **Step 4: Implement range and arc filtering**

Use planar vectors:

```lua
local offset =
    Vector3.new(
        target_pos.X - attacker_pos.X,
        0,
        target_pos.Z - attacker_pos.Z
    )

local forward =
    Vector3.new(
        root.CFrame.LookVector.X,
        0,
        root.CFrame.LookVector.Z
    ).Unit
```

Reject when:

```lua
offset.Magnitude > attack_definition.REACH
```

Angle:

```lua
local direction = offset.Unit
local dot = math.clamp(
    forward:Dot(direction),
    -1,
    1
)
local angle = math.deg(math.acos(dot))
```

Reject when:

```lua
angle > attack_definition.ARC_DEGREES / 2
```

Handle near-zero offsets without dividing by zero.

- [ ] **Step 5: Implement per-swing deduplication**

Before accepting:

```lua
if already_hit[target_model] then
    continue
end
```

After all validation succeeds:

```lua
already_hit[target_model] = true
table.insert(targets, target_model)
```

Deduplication is per `begin_active_window` invocation, never global.

- [ ] **Step 6: Implement geometry obstruction**

Raycast from attacker root position toward the target root/primary part.

The obstruction ray must ignore:

```text
attacker character
all tagged CombatTarget Models
all current player character Models
```

This ensures other characters do not act as dungeon walls.

Use server `RaycastParams` with an Exclude filter.

If the ray hits solid level geometry before the target point, reject the
candidate.

- [ ] **Step 7: Run Studio Play and verify geometry tests GREEN**

Expected:

```text
[Melee Hit Service Tests] PASS: ...
```

- [ ] **Step 8: Commit Task 3**

```powershell
git add `
    ".\src\ReplicatedStorage\Combat\Shared\CombatConfig.luau" `
    ".\src\ServerScriptService\Combat\MeleeHitService.luau" `
    ".\src\ServerScriptService\Combat\Tests\MeleeHitServiceTest.server.luau"

git diff --cached --check

git commit -m "feat: add server melee hit acquisition"
```

---

### Task 4: Swept Active-Window Damage

**Files:**
- Modify:
  `src/ServerScriptService/Combat/MeleeHitService.luau`
- Modify:
  `src/ServerScriptService/Combat/Tests/MeleeHitServiceTest.server.luau`

**Interfaces:**
- Produces:
  - `MeleeHitService.begin_active_window(context)`

- [ ] **Step 1: Add a RED test for repeated samples**

Use a test target that remains inside the hit volume and invoke the internal
sample path four times with one shared `already_hit` table.

Verify the target appears only once across the swing.

Also verify two different NPCs can both be accepted.

- [ ] **Step 2: Implement Active-window sampling**

For:

```lua
local sample_count =
    attack_definition.HITBOX.SAMPLE_COUNT
local active_seconds =
    attack_definition.ACTIVE_SECONDS
```

Use:

```lua
local sample_interval =
    active_seconds / sample_count
```

Sample 1 immediately and schedule the remainder at:

```lua
(sample_index - 1) * sample_interval
```

This keeps every sample inside the Active window rather than placing the last
sample exactly at recovery start.

Each scheduled sample shares one local:

```lua
local already_hit: {[Model]: boolean} = {}
```

- [ ] **Step 3: Apply damage once per newly accepted target**

For every Model returned from `collect_targets`, create:

```lua
local damage_context = {
    attacker = context.attacker,
    attacker_character = context.character,
    target = target,
    source_kind = "Melee",
    source_id = CombatConfig.PROTOTYPE_WEAPON.TOOL_NAME,
    attack_id = context.attack_id,
    base_damage = context.base_damage,
    multiplier = context.attack_definition.DAMAGE_MULTIPLIER,
}
```

Then:

```lua
DamageService.apply_damage(damage_context)
```

- [ ] **Step 4: Run Studio Play and verify GREEN**

Expected:

```text
[Melee Hit Service Tests] PASS: ...
[Damage Service Tests] PASS: ...
```

- [ ] **Step 5: Commit Task 4**

```powershell
git add `
    ".\src\ServerScriptService\Combat\MeleeHitService.luau" `
    ".\src\ServerScriptService\Combat\Tests\MeleeHitServiceTest.server.luau"

git diff --cached --check

git commit -m "feat: add swept melee active windows"
```

---

### Task 5: Training Dummy and Combat Diagnostics

**Files:**
- Modify:
  `src/ReplicatedStorage/Combat/Shared/CombatConfig.luau`
- Create:
  `src/ServerScriptService/Combat/TrainingDummyBuilder.server.luau`
- Modify:
  `src/ServerScriptService/Combat/MeleeHitService.luau`
- Modify:
  `src/ServerScriptService/Combat/DamageService.luau`

**Interfaces:**
- Produces tagged stationary NPC Models with Humanoids.
- Produces optional hitbox and damage diagnostics.

- [ ] **Step 1: Add debug configuration**

Add under the existing debug config:

```lua
SHOW_MELEE_HITBOX = true,
PRINT_MELEE_HITS = true,
PRINT_DAMAGE = true,
```

These are development defaults for Step 4 and can be changed without code
deletion.

- [ ] **Step 2: Build a stationary Training Dummy**

Create a Model named:

```text
TrainingDummy
```

with:

```lua
Humanoid.MaxHealth = 200
Humanoid.Health = 200
```

Give it at least:

```text
HumanoidRootPart
Body
Head
```

Anchor its root/body so it remains stationary.

Tag the Model:

```lua
CollectionService:AddTag(
    dummy,
    CombatConfig.TARGETS.NPC_TAG
)
```

Place the main dummy directly in front of the reset spawn at a distance that
Slash1 can reach when the player walks up to it.

For debug testing, add a second dummy offset sideways enough that the player
can deliberately test cleave.

- [ ] **Step 3: Visualize sampled melee volumes**

When `SHOW_MELEE_HITBOX` is true, create a temporary non-collidable,
non-queryable Part matching each sample's box CFrame/size and remove it after
approximately `0.08` seconds with `Debris`.

Debug parts must never participate in overlap queries.

- [ ] **Step 4: Add optional diagnostics**

When enabled:

```text
[MeleeHit] Slash1 sample 2/4
[MeleeHit] TrainingDummy accepted
[Damage] TrainingDummy -10.0 HP
```

Do not print every rejection by default; that will become noisy when dungeons
contain many targets.

- [ ] **Step 5: Manual Studio test**

Verify:

```text
Slash1       -> 10 damage
Slash2       -> 10.5 damage
Finisher     -> 13.5 damage
full combo   -> 34 total damage
```

Verify two dummies can both lose health from one swing.

- [ ] **Step 6: Commit Task 5**

```powershell
git add `
    ".\src\ReplicatedStorage\Combat\Shared\CombatConfig.luau" `
    ".\src\ServerScriptService\Combat\TrainingDummyBuilder.server.luau" `
    ".\src\ServerScriptService\Combat\MeleeHitService.luau" `
    ".\src\ServerScriptService\Combat\DamageService.luau"

git diff --cached --check

git commit -m "feat: add training targets and melee diagnostics"
```

---

### Task 6: Integrate with Authoritative `CombatService`

**Files:**
- Modify:
  `src/ServerScriptService/Combat/CombatService.server.luau`
- Modify:
  `src/ServerScriptService/Combat/Tests/MeleeHitServiceTest.server.luau`
  only if an integration-facing assertion is useful.

**Interfaces:**
- Consumes:
  - `MeleeHitService.begin_active_window(context)`

- [ ] **Step 1: Add the integration failure check**

Before integration, manually Play and confirm clicking attacks animates but
does not reduce the Training Dummy's health.

This is the integration RED state.

- [ ] **Step 2: Require `MeleeHitService` in `CombatService`**

Add server-side require near the other combat modules:

```lua
local MeleeHitService = require(
    script.Parent:WaitForChild("MeleeHitService")
)
```

Do not expose a new client RemoteEvent for hit targets.

- [ ] **Step 3: Call it exactly once on authoritative Active entry**

Inside the existing server function that transitions an accepted attack into
`State.ACTIVE`, after the transition is valid and before recovery begins:

```lua
MeleeHitService.begin_active_window({
    attacker = player,
    character = character,
    attack_id = attack_id,
    attack_definition = attack_definition,
    base_damage =
        CombatConfig.PROTOTYPE_WEAPON.BASE_DAMAGE,
})
```

The existing short forward attack step remains independent from hit
detection.

Do not call `MeleeHitService` from client-predicted state.

- [ ] **Step 4: Run complete Studio verification**

Expected all test groups green, including:

```text
[Combat Tests] PASS: 16 StateRules assertions.
[Combat Animation Tests] PASS: 27 assertions.
[Combat Weapon Tests] PASS: ...
[One-Handed Sword Tests] PASS: ...
[Sword Carry/Grip Tests] PASS: ...
[Combat Target Rules Tests] PASS: ...
[Damage Service Tests] PASS: ...
[Melee Hit Service Tests] PASS: ...
```

Manual test:

```text
attack inside range         -> dummy loses health
attack outside range        -> no damage
attack facing away          -> no damage
two targets in arc          -> both take damage
one target across samples   -> one damage event
pillar between player/NPC   -> no damage
another player in volume    -> no PvP damage
```

- [ ] **Step 5: Security sanity check**

Search the client code:

```powershell
Get-ChildItem `
    ".\src\StarterPlayerScripts" `
    -Recurse `
    -Filter "*.luau" |
    Select-String `
        -Pattern "TakeDamage|Health\s*=|DamageService|target"
```

Review matches and confirm no client path can directly authorize NPC damage.

- [ ] **Step 6: Rojo and Git verification**

```powershell
rojo build `
    ".\default.project.json" `
    -o ".\backups\Step4FinalValidation.rbxl"

git diff --check
git status --short
```

- [ ] **Step 7: Commit integration**

```powershell
git add .

git diff --cached --check

git commit -m "feat: add server-authoritative melee hits and damage"
```

Do not push until the final manual Studio acceptance test is complete.

---

## Final Acceptance Checklist

- [ ] Server owns all target acquisition.
- [ ] Client never sends target/damage data.
- [ ] Slash1 deals exactly 10 damage.
- [ ] Slash2 deals exactly 10.5 damage.
- [ ] Finisher deals exactly 13.5 damage.
- [ ] Full uninterrupted combo deals exactly 34 damage to one target.
- [ ] Cleave damages multiple NPCs.
- [ ] One swing cannot damage the same NPC twice.
- [ ] Out-of-range and behind-player targets are rejected.
- [ ] Geometry blocks hits.
- [ ] Dead NPCs are rejected.
- [ ] Player characters are rejected.
- [ ] Training Dummy uses `Humanoid.Health`.
- [ ] Damage service contains no melee geometry dependency.
- [ ] Target rules contain no melee geometry dependency.
- [ ] Future projectile/AoE delivery can call the same shared pipeline.
- [ ] Existing combat feel and sword animation remain unchanged.
- [ ] All Studio tests are green.
- [ ] `rojo build` succeeds.
- [ ] `git diff --check` succeeds.
