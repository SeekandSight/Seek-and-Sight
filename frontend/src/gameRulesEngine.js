// ============================================================
// GameRulesEngine — Grid-based command validation
//
// RULE: All validation uses scene.playerGridX and scene.goalGridX
//       ONLY. Never read scene.player.x or any rect.x pixel values.
//       Pixel positions change during animation; grid integers are
//       the single source of truth for game state.
// ============================================================
export default class GameRulesEngine {
  constructor(scene) {
    this.scene = scene;
  }

  validate(command, currentState) {
    const commandLabel = (command.commandUsed || command.commandRef || '').toUpperCase();

    switch (commandLabel) {
      case 'GO':         return this.validateGO();
      case 'JUMP':       return this.validateJUMP();
      case 'FIX':        return this.validateFIX();
      case 'TURN LEFT':  return this.validateTURNLEFT();
      default:
        return {
          allowed: false,
          reason: `Unknown command: ${commandLabel}`,
          correctedState: null,
        };
    }
  }

  // ----------------------------------------------------------
  // GO: allowed unless already at or past the goal
  // ----------------------------------------------------------
  validateGO() {
    const nextGridX = this.scene.playerGridX + 1;

    if (nextGridX > this.scene.goalGridX) {
      return {
        allowed: false,
        reason: 'You are already at the goal. Stop running commands.',
        correctedState: null,
      };
    }

    return {
      allowed: true,
      reason: 'Moving forward.',
      correctedState: { playerGridX: nextGridX },
    };
  }

  // ----------------------------------------------------------
  // JUMP: always allowed (grid collision handled post-animation)
  // ----------------------------------------------------------
  validateJUMP() {
    return {
      allowed: true,
      reason: 'Jumping forward.',
      correctedState: { playerGridX: this.scene.playerGridX + 1, jumped: true },
    };
  }

  // ----------------------------------------------------------
  // FIX: allowed only when standing on the cracked tile
  // ----------------------------------------------------------
  validateFIX() {
    const gx = this.scene.playerGridX;
    const crackedZone = this.scene.pathZones.find((z) => z.type === 'cracked');

    if (!crackedZone) {
      return {
        allowed: false,
        reason: 'No cracked tile found on this level.',
        correctedState: null,
      };
    }

    if (gx !== crackedZone.gridX) {
      return {
        allowed: false,
        reason: 'Move onto the cracked tile before using FIX.',
        correctedState: null,
      };
    }

    return {
      allowed: true,
      reason: crackedZone.fixed ? 'Cracked tile already repaired.' : 'Fixing the cracked tile!',
      correctedState: { playerGridX: gx, fixed: true },
    };
  }

  // ----------------------------------------------------------
  // TURN LEFT: always allowed (no position change)
  // ----------------------------------------------------------
  validateTURNLEFT() {
    return {
      allowed: true,
      reason: 'Turning left in place.',
      correctedState: { rotated: true },
    };
  }
}
