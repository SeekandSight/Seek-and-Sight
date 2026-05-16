export default class LevelGoalManager {
  constructor(scene, eventBus) {
    this.scene = scene;
    this.eventBus = eventBus;
    this.goal = null;
    this.goalReached = false;

    this.eventBus.on('command:execution_finished', () => this.evaluateGoal());
  }

  defineGoal(goal) {
    this.goal = {
      targetPosition: goal.targetPosition || { x: 500, y: 250 },
      requiredCommands: goal.requiredCommands || ['GO'],
      maxCommands: goal.maxCommands || 10,
      ...goal,
    };

    console.log('[LevelGoalManager] Goal defined:', this.goal);
  }

  evaluateGoal() {
    if (!this.goal) {
      console.warn('[LevelGoalManager] No goal defined, skipping evaluation');
      return;
    }

    const playerX = this.scene.player.x;
    const playerY = this.scene.player.y;
    const targetX = this.goal.targetPosition.x;
    const targetY = this.goal.targetPosition.y;

    const distanceToTarget = Math.sqrt(
      Math.pow(playerX - targetX, 2) + Math.pow(playerY - targetY, 2)
    );

    const isPositionReached = distanceToTarget < 60;

    const usedCommands = this.scene.commandState.getLiveCodeLines().map((line) => line.commandRef);
    const commandCount = usedCommands.length;

    let allRequiredCommandsUsed = true;
    if (this.goal.requiredCommands && this.goal.requiredCommands.length > 0) {
      allRequiredCommandsUsed = this.goal.requiredCommands.every((cmd) => usedCommands.includes(cmd));
    }

    const withinMaxCommands = commandCount <= this.goal.maxCommands;

    const levelComplete = isPositionReached && allRequiredCommandsUsed && withinMaxCommands;

    const evaluation = {
      goalReached: levelComplete,
      positionReached: isPositionReached,
      playerX,
      playerY,
      targetX,
      targetY,
      distanceToTarget: distanceToTarget.toFixed(2),
      commandsUsed: usedCommands,
      commandCount,
      maxCommands: this.goal.maxCommands,
      requiredCommands: this.goal.requiredCommands,
      allRequiredCommandsUsed,
      withinMaxCommands,
      timestamp: Date.now(),
    };

    console.log('[LevelGoalManager] Goal evaluation:', evaluation);

    if (levelComplete) {
      console.log('[LevelGoalManager] ✅ LEVEL COMPLETE');
      this.goalReached = true;
      this.eventBus.emit('level:complete', evaluation);
    } else {
      const failureReasons = [];
      if (!isPositionReached) {
        failureReasons.push(`Robot not close enough to target (distance: ${distanceToTarget.toFixed(2)}px)`);
      }
      if (!allRequiredCommandsUsed) {
        const missing = this.goal.requiredCommands.filter((cmd) => !usedCommands.includes(cmd));
        failureReasons.push(`Missing required commands: ${missing.join(', ')}`);
      }
      if (!withinMaxCommands) {
        failureReasons.push(`Used too many commands (${commandCount} > ${this.goal.maxCommands})`);
      }

      evaluation.failureReasons = failureReasons;
      console.log('[LevelGoalManager] ❌ LEVEL FAILED:', failureReasons);
      this.eventBus.emit('level:fail', evaluation);
    }

    return evaluation;
  }

  isGoalReached() {
    return this.goalReached;
  }
}
