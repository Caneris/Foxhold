# Foxhold

A 2D tower defense strategy game built with Godot 4.5.

## Genre

Tower defense with real-time strategy and resource management elements.

## Overview

Protect your central Heart structure from waves of invading slime enemies. Build houses to spawn foxling defenders, construct walls for protection, and manage your gold economy to survive increasingly difficult waves.

## Core Mechanics

### The Heart

The Heart is the central structure you must protect. If it falls, the game is over. You can heal the Heart by spending gold.

### Buildings

**Houses** – Spawn points for your foxling units. Each house can hold up to 5 foxlings and can be upgraded to increase capacity.

**Walls** – Defensive barriers that block enemy movement. Enemies must destroy walls before reaching the Heart. Walls can be repaired or destroyed (for a partial refund based on remaining health).

**Towers** – (Planned) Ranged defensive structures.

### Foxlings

Units spawned from houses that defend your base:

- **Knight Foxlings** – Combat units that patrol and engage enemies
- **Collector Foxlings** – Gather gold dropped by defeated enemies and return it to the Heart

### Enemies

Slime creatures that spawn in waves and march toward the Heart. They attack walls and the Heart directly. Defeating enemies drops gold coins.

### Economy

Gold is the single resource. Earn it by collecting coins from defeated enemies. Spend it on:

- Building structures (Houses, Walls, Towers)
- Recruiting foxlings
- Upgrading buildings
- Healing the Heart
- Repairing walls

### Wave-Based Cost Inflation

Costs increase with each wave (15% per wave by default). This incentivizes early investment over hoarding resources.

**Base Costs:**
| Item | Cost |
|------|------|
| House | 50 |
| Wall | 75 |
| Tower | 100 |
| Heal | 30 |
| Knight Foxling | 120 |
| Collector Foxling | 90 |
| House Upgrade | 80 |
| Wall Upgrade | 60 |
| Wall Repair | 40 |

### Refund System

Destroying a wall refunds gold based on the original cost paid and current health percentage. This prevents exploitation while rewarding careful resource management.

## Controls

- **A/D or Arrow Keys** – Cycle focus between structures
- **Left Click** – Select structures, click enemies to damage them, drag coins
- **Right Click** – Cancel building placement

## Technical Details

- **Engine:** Godot 4.5
- **Resolution:** 640×360 (pixel art viewport)
- **Rendering:** Forward Plus

### Physics Layers

1. Floor
2. Heart
3. Enemy
4. Item (coins)
5. House
6. Wall
7. Foxling

## Project Structure

```
foxhold/
├── assets/          # Sprites and visual assets
├── scenes/          # .tscn scene files
├── scripts/         # GDScript files
└── shaders/         # Visual effect shaders
```

## Development Status

Work in progress. Core gameplay loop is functional with building placement, foxling AI, enemy pathfinding, and economic mechanics implemented.