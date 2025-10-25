<div align="center">
   
# Simploid

### Created by @cheesyhuman2 — 2025  
*Licensed under the MIT License*

</div>

**Simploid** is a lightweight, high-performance alternative to Roblox's **Humanoid** system — designed for developers who need efficient, flexible, and scalable NPCs without unnecessary overhead.

<sub>Get the actual Roblox Asset Module here:  
<a href="https://create.roblox.com/store/asset/101790562193039/Simploid">https://create.roblox.com/store/asset/101790562193039/Simploid</a></sub>
---

## 🚀 Overview

Simploid focuses on performance and simplicity.  
It removes the physics-heavy, replication-intensive behavior of traditional humanoids — making it ideal for NPCs that don’t require full humanoid simulation.

---

## ⚙️ Requirements
Your NPC rigs should basically be the same way as if you would be using a normal humanoid.
Your NPC rigs must have a **HumanoidRootPart** set as their `PrimaryPart`.

---

## ✨ Features

1. **No Humanoid Required**  
   Simploid works without the default `Humanoid` object, freeing you from its performance cost.

2. **Minimal Physics Usage**  
   Physics are used *only* when falling — all other movement is handled through math and tweens.

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

<h3>🧩 Module Structure</h3>
<pre>
Simploid
├── Client
├── Config
├── GoodSignal
├── Janitor
├── ReplicatedTween
└── Server
</pre>

---

## 🛠️ Extending Simploid

If you wish to imitate specific humanoid features, you can easily **fork and modify**:
- `Server`
- `Client`
  
If you wish to modify and tweak behaviors of simploids, you can easily change some configurations in:
- `Config`

---

## 🧠 Example Usage

### Client-side:
```lua
-- LocalScript
require(game.ReplicatedStorage.Simploid)
```

### Server-side:
```lua
-- Script
local Simploid = require(game.ReplicatedStorage.Simploid)

local character = workspace.Dummy -- Your NPC rig

local npc = Simploid.new(character)
npc:PathfindTo(Vector3.new(10, 0, 10)) -- Moves NPC to position
```

## 🧾 License
This project is licensed under the MIT License —
you are free to use, modify, and distribute this software for any purpose, provided that the original copyright notice and license are included in all copies.

<div align="center">
🧩 Simploid — Lightweight NPCs for Roblox.
</div>
