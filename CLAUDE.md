# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Godot 4.4 2D game project featuring a side-scrolling action game with player movement, enemy AI, and health mechanics. The game uses a mobile rendering method and is configured for 2560x1600 viewport.

## Architecture

### Core Components
- **World** (`world.gd`): Main scene controller (minimal implementation)
- **Player** (`entities/player/player.gd`): Main character with movement, dashing, health, and animation states
- **Enemy** (`entities/enemy/enemy.gd`): AI-controlled enemies that chase and damage the player
- **Health Bar UI** (`ui/health_bar.gd`): Player health display system

### Entity System
The project follows a class-based entity structure:
- Player extends CharacterBody2D with state machine (IDLE, RUNNING, DASHING, DEAD)
- Enemy extends CharacterBody2D with basic AI and collision detection
- Both entities use AnimatedSprite2D for animations with extensive sprite sheets

### Physics Layers
1. Player
2. Enemies  
3. Obstacles

### Input System
- Arrow keys for movement (move_left, move_right, move_up, move_down)
- Spacebar for dash ability
- All inputs configured in project.godot

### Animation System
Both player and enemy have comprehensive animation sets stored in `entities/[entity]/animations/`:
- Player: idle, running, dashing, jumping, combat moves, dying
- Enemy: idle, walking, attacking, dying, hurt states

## Key Gameplay Mechanics

### Player Systems
- **Movement**: 8-directional movement with 400 units/sec speed
- **Dash**: Short-range dash at 1000 units/sec for 0.25 seconds
- **Health**: 10 HP with invincibility frames (0.5 sec) after damage
- **Animation Blinking**: Random idle blinking every 3-8 seconds
- **State Machine**: Clean state transitions with proper animation handling

### Enemy AI
- Follows player when distance > 50 units
- Stops moving when close to player
- Damages player (1 HP) while overlapping hitbox
- Faces player direction while moving

### Signal System
- Player emits `health_changed(new_health)` and `player_died` signals
- Health bar automatically updates via signal connections

## Development Notes

This is a Godot project using GDScript. The codebase is well-structured with clear separation of concerns between player mechanics, enemy AI, and UI systems. The animation system is comprehensive with detailed sprite sheets for all character states.