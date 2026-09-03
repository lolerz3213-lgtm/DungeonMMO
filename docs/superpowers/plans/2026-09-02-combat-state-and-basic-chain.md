# Combat State and Basic Chain Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:subagent-driven-development or superpowers:executing-plans.

**Goal:** Add the explicit Locomotion/WindUp/Active/Recovery combat state
foundation and the three-hit sword basic chain without adding hit detection.

**Architecture:** Pure shared rules define legal transitions and combo timing.
The server owns authoritative state, movement commitment and forward steps.
The client predicts presentation immediately, while server state remains visible
for diagnostics. Input and feedback stay separate from combat rules.

**Tech Stack:** Roblox Studio, Luau, Rojo 7.7.0, Git.

**Spec:** `docs/Combat_Design_Specification_v0_1.docx`

## Global Constraints

- Basic attacks use character facing, never a cursor-selected target.
- Slash timings and movement values come from Combat Specification v0.1.
- Client prediction cannot award damage, targets, health changes or rewards.
- No authoritative hit detection is added in this step.
- The prototype remains isolated from inventory, classes and dungeon systems.

---

### Task 1: Pure state and combo rules

**Files:**
- Create: `src/ReplicatedStorage/Combat/Shared/CombatTypes.luau`
- Create: `src/ReplicatedStorage/Combat/Shared/StateRules.luau`
- Modify: `src/ReplicatedStorage/Combat/Shared/CombatConfig.luau`
- Test: `src/ServerScriptService/Combat/Tests/StateRulesTest.server.luau`

**Produces:** Legal state transitions, movement scaling, combo order, late
recovery buffer and combo-reset rules.

- [x] Write the failing runtime test before production modules exist.
- [ ] Run Studio and verify the test reports `[Combat Tests] RED`.
- [ ] Add the minimal shared production modules and attack configuration.
- [ ] Run Studio and verify all StateRules assertions pass.

### Task 2: Authoritative server attack sequence

**Files:**
- Create: `src/ReplicatedStorage/Combat/Remotes.model.json`
- Create: `src/ServerScriptService/Combat/CombatService.server.luau`

**Produces:** A server-selected Slash1 -> Slash2 -> Finisher chain with
WindUp -> Active -> Recovery timing, movement scaling, late buffering, combo
reset and short collision-aware forward steps. The client supplies no attack id,
target or damage value.

- [ ] Source-control the RemoteEvents through a Rojo JSON model.
- [ ] Add per-player authoritative state reset on character spawn.
- [ ] Apply movement commitment and forward step from server state.
- [ ] Expose diagnostic character attributes and state events.

### Task 3: Immediate client prediction and feedback

**Files:**
- Create: `src/StarterPlayerScripts/Combat/ClientCombatController.luau`
- Create: `src/StarterPlayerScripts/Combat/InputController.client.luau`
- Create: `src/StarterPlayerScripts/Combat/FeedbackController.client.luau`

**Produces:** Left-click/controller basic attack input, immediate predicted
attack phases, a temporary local debug blade, active-frame-only trail and a HUD
showing local versus authoritative server state.

- [ ] Bind MouseButton1 and controller right trigger.
- [ ] Predict only presentation; send an argument-free attack request.
- [ ] Animate the disposable blade from the predicted state sequence.
- [ ] Display local and server state side by side for mismatch diagnosis.

### Task 4: Verification checkpoint

- [ ] Run `rojo build default.project.json -o backups/CombatStep3Validation.rbxl`.
- [ ] Run `git diff --check`.
- [ ] Verify Studio Output reports the StateRules test PASS.
- [ ] Verify single clicks, buffered clicks and delayed combo reset manually.
- [ ] Commit only after the runtime checks pass.
