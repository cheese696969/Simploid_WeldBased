<div align="center">

<img width="420" height="120" alt="Simploid Logo" src="https://github.com/user-attachments/assets/YOUR_IMAGE_ID_HERE" />

# Simploid

### Created by @YourNameHere — 2025  
*Licensed under the MIT License*

</div>

**Simploid** is a lightweight, high-performance alternative to Roblox's **Humanoid** system — designed for developers who need efficient, flexible, and scalable NPCs without unnecessary overhead.

---

## 🚀 Overview

Simploid focuses on performance and simplicity.  
It removes the physics-heavy, replication-intensive behavior of traditional humanoids — making it ideal for NPCs that don’t require full humanoid simulation.

---

## ⚙️ Requirements

Your NPC rigs must have a **HumanoidRootPart** set as their `PrimaryPart`.

---

## ✨ Features

1. **No Humanoid Required**  
   Simploid works without the default `Humanoid` object, freeing you from its performance cost.

2. **Minimal Physics Usage**  
   Physics are used *only* when falling — all other movement is handled efficiently.

3. **Client-Side Smooth Movement**  
   Movement is replicated efficiently and smoothed only on the client for optimal performance.

4. **Raycast-Based Collision System**  
   Uses raycasting to simulate collisions instead of physical constraints.

5. **Built-In Pathfinding**  
   Integrated with `PathfindingService` for easy navigation.

6. **Flexible Server Updates**  
   You can choose when to synchronize server-side NPC positions for tighter control.

---

## ⚠️ Drawbacks

- Only the **basic** humanoid methods are replicated.  
- NPCs **may pass through walls** under some conditions.  
- **No humanoid events, properties, or advanced features** are implemented by default.  
- For advanced behavior, fork and customize the included helper modules.

---

## 🧩 Module Structure

Simploid
├── Client
├── Config
├── GoodSignal
├── Janitor
├── ReplicatedTween
└── Server

yaml
Copy code

---

## 🛠️ Extending Simploid

If you wish to add specific humanoid features (like animations or damage detection),  
you can easily **fork and modify**:
- `ServerHelper`
- `ClientHelper`

---

## 🧠 Example Usage

### Client-side:
```lua
-- LocalScript
require(game.ReplicatedStorage.Simploid)
Server-side:
lua
Copy code
-- Script
local Simploid = require(game.ReplicatedStorage.Simploid)

local character = workspace.Dummy -- Your NPC rig
local storage = workspace.NpcFolder -- Folder for active NPCs

local npc = Simploid.new(character, storage)
npc:PathfindTo(Vector3.new(10, 0, 10)) -- Moves NPC to position
📚 Notes
Ensure NpcFolder exists as a descendant of workspace, but not of a BasePart.

Simploid’s efficiency comes from reduced replication and physics dependence.

🧾 License
This project is licensed under the GNU GPLv3 License —
you are free to use, modify, and distribute it, provided that all copies remain open-source under the same license.

<div align="center">
🧩 Simploid — Lightweight NPCs for Roblox Developers.

</div> ```
