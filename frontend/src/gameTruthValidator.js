export default class GameTruthValidator {
  constructor(scene, stateManager, eventBus) {
    this.scene = scene;
    this.stateManager = stateManager;
    this.eventBus = eventBus;
    this.errors = [];
    this.warnings = [];
    this.validationResults = null;

    this.eventBus.on('command:execution_finished', () => this.validate());
  }

  validate() {
    this.errors = [];
    this.warnings = [];

    const queueLength = this.stateManager.getQueueLength();
    const lines = this.stateManager.getLiveCodeLines();

    let executedCount = 0;
    let successCount = 0;
    let errorCount = 0;
    let invalidCommands = 0;
    let lockedCommandsExecuted = 0;

    lines.forEach((line, index) => {
      if (line.status === 'active' || line.status === 'success' || line.status === 'error') {
        executedCount += 1;
      }

      if (line.status === 'success') {
        successCount += 1;
      }

      if (line.status === 'error') {
        errorCount += 1;
      }

      if (!['GO', 'JUMP', 'FIX', 'TURN LEFT'].includes(line.commandRef)) {
        invalidCommands += 1;
        this.errors.push(`Invalid command at line ${index + 1}: ${line.commandRef}`);
      }
    });

    const playerX = this.scene.player.x;
    const targetX = this.scene.goal ? this.scene.goal.x : null;

    let levelComplete = false;
    if (targetX !== null && Math.abs(playerX - targetX) < 50) {
      levelComplete = true;
    }

    if (invalidCommands > 0) {
      this.errors.push(`${invalidCommands} invalid commands detected in execution`);
    }

    if (errorCount > 0 && !levelComplete) {
      this.warnings.push(`${errorCount} commands failed during execution`);
    }

    if (successCount === 0 && executedCount > 0) {
      this.warnings.push('No commands succeeded; check game rules validation');
    }

    const accuracyScore = executedCount > 0 ? (successCount / executedCount) * 100 : 0;

    this.validationResults = {
      levelComplete,
      playerX,
      targetX,
      executedCount,
      successCount,
      errorCount,
      invalidCommands,
      accuracyScore: accuracyScore.toFixed(2),
      errors: this.errors,
      warnings: this.warnings,
      timestamp: Date.now(),
    };

    console.log('[GameTruthValidator] Validation complete:', this.validationResults);
    this.eventBus.emit('validation:complete', this.validationResults);

    return this.validationResults;
  }

  getValidationResults() {
    return this.validationResults;
  }
}
