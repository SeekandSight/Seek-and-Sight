export default class CommandExecutor {
  constructor(scene, apiCallback, gameRulesEngine) {
    this.scene = scene;
    this.apiCallback = apiCallback;
    this.gameRulesEngine = gameRulesEngine;
    this.executedCommandIds = new Set();
  }

  async executeCommand(line, index) {
    const commandId = line.id;
    const timestamp = Date.now();

    console.log(`[CommandExecutor] [${timestamp}] START command id=${commandId} index=${index} command=${line.commandRef}`);

    if (this.executedCommandIds.has(commandId)) {
      console.error(`[CommandExecutor] [${timestamp}] DUPLICATE execution detected for id=${commandId}`);
      return {
        success: false,
        reason: 'duplicate_execution',
        commandId,
        apiResult: null,
      };
    }

    try {
      const validationResult = this.gameRulesEngine.validate(line, {});
      if (!validationResult.allowed) {
        console.warn(`[CommandExecutor] [${timestamp}] VALIDATION FAILED id=${commandId} reason=${validationResult.reason}`);
        this.scene.eventBus.emit('command:validation_failed', {
          commandId,
          reason: validationResult.reason,
        });
        return {
          success: false,
          reason: 'validation_failed',
          commandId,
          validationResult,
          apiResult: null,
        };
      }

      console.log(`[CommandExecutor] [${timestamp}] VALIDATION PASSED id=${commandId}`);

      const apiResult = await this.apiCallback(line);
      console.log(`[CommandExecutor] [${timestamp}] API CALL COMPLETE id=${commandId} success=${apiResult.success}`);

      this.scene.currentCommandLabel = line.commandRef;
      await this.scene.playCommandAnimation(line.commandRef, index);
      const collisionResult = this.scene.checkCollisions(index);
      this.scene.currentCommandLabel = null;
      console.log(`[CommandExecutor] [${timestamp}] ANIMATION COMPLETE id=${commandId}`);

      if (collisionResult === 'stop') {
        this.executedCommandIds.add(commandId);
        console.log(`[CommandExecutor] [${timestamp}] COLLISION STOP id=${commandId}`);
        return { success: false, reason: 'collision', commandId, apiResult };
      }

      this.executedCommandIds.add(commandId);
      console.log(`[CommandExecutor] [${timestamp}] EXECUTION SUCCESS id=${commandId}`);
      return {
        success: apiResult.success,
        reason: apiResult.success ? 'success' : 'api_error',
        commandId,
        apiResult,
      };
    } catch (error) {
      console.error(`[CommandExecutor] [${timestamp}] EXECUTION CRASHED id=${commandId}`, error);
      this.scene.eventBus.emit('command:executor_crash', {
        commandId,
        error: error.message,
      });
      return {
        success: false,
        reason: 'executor_crash',
        commandId,
        error: error.message,
        apiResult: null,
      };
    }
  }

  clearExecutionHistory() {
    this.executedCommandIds.clear();
  }
}
