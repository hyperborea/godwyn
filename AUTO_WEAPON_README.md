# Auto Weapon System

This system adds an automatic weapon that orbits around the player and automatically shoots nearby enemies.

## Components

### 1. AutoWeapon (entities/player/auto_weapon.gd)
- **Location**: Orbits around the player at a configurable distance
- **Function**: Automatically detects and shoots at nearby enemies
- **Behavior**: 
  - Continuously orbits around the player
  - Scans for enemies within detection radius
  - Automatically fires bullets at the closest enemy
  - Has configurable fire rate, bullet speed, and damage

### 2. Bullet (entities/player/bullet.gd)
- **Type**: Area2D projectile
- **Function**: Travels in a straight line and damages enemies on contact
- **Features**:
  - Configurable speed, damage, and lifetime
  - Automatically destroyed on enemy hit or timeout
  - Rotates to face movement direction

### 3. Scene Files
- `auto_weapon.tscn`: The weapon scene with visual representation
- `bullet.tscn`: The bullet projectile scene

## Configuration

The auto weapon can be configured through these exported variables:

- **fire_rate**: Time between shots (default: 1.0 seconds)
- **bullet_speed**: How fast bullets travel (default: 600.0)
- **bullet_damage**: Damage per bullet (default: 1)
- **detection_radius**: How far it can detect enemies (default: 300.0)
- **orbit_speed**: How fast it orbits around player (default: 90.0 degrees/sec)
- **orbit_distance**: Distance from player center (default: 60.0)

## How It Works

1. **Setup**: The auto weapon is automatically attached to the player in the player scene
2. **Detection**: Every frame, it scans for enemies in the "enemies" group within detection range
3. **Targeting**: When ready to fire, it targets the closest enemy
4. **Firing**: Creates a bullet instance, sets its direction toward the enemy, and adds it to the scene
5. **Orbiting**: Continuously moves in a circular path around the player

## Integration

The system is already integrated into the player scene and will work automatically. Enemies are automatically added to the "enemies" group by the enemy spawner, so no additional setup is required.

## Visual Feedback

- The weapon briefly flashes white when firing
- Bullets are small yellow circles
- The weapon itself is a cyan circle that orbits around the player
