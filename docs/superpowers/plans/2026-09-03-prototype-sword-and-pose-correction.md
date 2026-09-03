# Prototype Sword and Attack Pose Correction

**Goal:** Replace the floating debug blade with a real Roblox Tool and
improve temporary sword attack readability without changing combat rules.

**Architecture:** The server creates and equips a Tool with one invisible
Handle and visible welded sword geometry. Roblox Tool.Grip owns the hand
attachment. The existing Animator pipeline continues to own character
animation, now using six-keyframe temporary attack clips.

**Validation:**
- Existing StateRules tests remain green.
- Animation factory tests remain green with six keyframes per attack.
- Weapon factory tests prove a valid Tool/Handle/weld structure.
- Prototype sword equips automatically.
- Sword stays attached to the right hand throughout attack playback.
- Left-click remains owned by the combat input system.

