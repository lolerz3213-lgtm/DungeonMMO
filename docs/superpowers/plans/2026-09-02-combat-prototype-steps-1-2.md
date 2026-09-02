# Combat Prototype Steps 1-2 Implementation Plan

**Goal:** Build the first playable combat test room and directional
View Lock foundation.

**Architecture:** The server creates disposable greybox test geometry.
Shared configuration owns prototype tuning values. A client camera
controller owns optional View Lock and character-facing behaviour.

**Tech Stack:** Roblox Studio, Luau, Rojo 7.7.0.

**Spec:** docs/Combat_Design_Specification_v0_1.docx

## Task 1 - Greybox arena

Create an 80 x 80 stud floor, two pillars, visible distance markers,
and a prototype spawn/reset point from server-owned code.

Validation:
- Arena appears when Play starts.
- Floor measures 80 x 80 studs.
- Exactly two test pillars appear.
- Distance markings appear every 10 studs.
- Character spawns on the reset pad.

## Task 2 - View Lock

Disable Roblox's built-in mouse-lock option and provide our own
Left Shift View Lock.

Free mode:
- Camera can orbit independently.
- Humanoid AutoRotate remains enabled.
- Character normally faces meaningful movement input.

View Lock:
- Mouse locks to screen centre.
- Camera becomes slightly over-the-shoulder.
- Camera yaw controls character yaw.
- A and D strafe instead of rotating the character away.
- Left Shift toggles back to free mode.

Validation:
- Toggle repeatedly without errors.
- Free camera remains usable when View Lock is disabled.
- View Lock rotates the character with horizontal camera movement.
- Character position is not changed by facing updates.
