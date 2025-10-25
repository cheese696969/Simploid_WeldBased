## 📘 API Reference

### 🧱 Class: `Simploid`

Simploid is a lightweight class that replicates the basic movement behavior of Roblox’s Humanoid system — without using physics or humanoid objects.

---

### ⚙️ Constructor
```lua
Simploid.new(character: Model, storage: Instance)
```

**Description:**  
Creates and initializes a new Simploid object for the given NPC character.  
This should be called **on the server**.

**Parameters:**
| Name | Type | Description |
|------|------|--------------|
| `character` | `Model` | The NPC model. Must have a `HumanoidRootPart` set as its PrimaryPart. |
| `storage` | `Instance` | The storage folder inside workspace where the Simploid stores internal data. |

**Returns:**  
→ `Simploid` — A new Simploid instance.

---

### 🧩 Methods

| Method | Returns | Description |
|--------|----------|-------------|
| `Simploid:MoveTo(position: Vector3)` | `nil` | Moves the NPC instantly to the target position. |
| `Simploid:PathfindTo(position: Vector3)` | `nil` | Makes the NPC walk or run toward the given position using Roblox’s PathfindingService. |
| `Simploid:Destroy()` | `nil` | Cleans up the Simploid and its connections. Should be called when the NPC is no longer needed. |
| `Simploid:ChangeMovement(state: string)` | `nil` | Changes the Simploid’s animation state (e.g., `"Walking"`, `"Running"`, `"Stopped"`). |
| `Simploid.GetSimploidFromCharacter(character: Model)` | `Simploid?` | Returns the Simploid instance associated with a given character, if one exists. |
| `Simploid.GetAllSimploids()` | `{ [Model]: Simploid }` | Returns a cloned table of all active Simploids. |

---

### 📦 Properties

| Property | Type | Description |
|-----------|------|-------------|
| `Simploid.Character` | `Model` | The NPC’s character model. |
| `Simploid.Type` | `string` | The type of Simploid based on the NPC’s configuration. |
| `Simploid.WalkSpeed` | `number` | The NPC’s walking speed. |
| `Simploid.RunSpeed` | `number` | The NPC’s running speed. |
| `Simploid.CanUpdate` | `boolean` | Whether the Simploid can currently perform updates. |
| `Simploid.Animations` | `table` | A dictionary of preloaded animations. |
| `Simploid.Janitor` | `Janitor` | Manages cleanup of events and instances. |

---

### 🧠 Example Usage

```lua
-- Client
require(game.ReplicatedStorage.Simploid)

-- Server
local Simploid = require(game.ReplicatedStorage.Simploid)
local character = workspace.Dummy
local storage = workspace.NpcFolder

local simploid = Simploid.new(character, storage)
simploid:PathfindTo(Vector3.new(10, 0, 10))
```

---

### ⚠️ Notes
- Only call `.new()` on the **server**.
- Simploid does **not** use a `Humanoid` object.
- Movement and animation updates are mostly client-driven for performance efficiency.
- For additional customization (e.g. humanoid-like behaviors), fork the module and extend the `Client` or `Server` helper scripts.
