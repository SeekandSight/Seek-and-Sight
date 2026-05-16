export default class CommandFlowController {
  constructor({ scene, stateManager, uiRenderer, executor, eventBus, lock }) {
    this.scene = scene;
    this.stateManager = stateManager;
    this.uiRenderer = uiRenderer;
    this.executor = executor;
    this.eventBus = eventBus;
    this.lock = lock;
    this.currentExecutingLineId = null;
  }

  init() {
    const timestamp = Date.now();
    console.log(`[CommandFlowController] [${timestamp}] INIT`);

    this.eventBus.on('command:added', (payload) => this.handleCommandAdded(payload));
    this.eventBus.on('command:executor_crash', (payload) => this.handleExecutorCrash(payload));
    this.eventBus.on('command:validation_failed', (payload) => this.handleValidationFailed(payload));
  }

  handleCommandAdded({ commandUsed, functionName, codeLine }) {
    const timestamp = Date.now();
    console.log(`[CommandFlowController] [${timestamp}] COMMAND:ADDED commandUsed=${commandUsed}`);

    if (this.lock.isLocked()) {
      console.warn(`[CommandFlowController] [${timestamp}] REJECTED: execution lock active`);
      return;
    }

    const entry = this.stateManager.addCommand(commandUsed, functionName, codeLine);
    if (!entry) {
      console.error(`[CommandFlowController] [${timestamp}] FAILED to add command to state`);
      return;
    }

    console.log(`[CommandFlowController] [${timestamp}] COMMAND:ADDED:COMPLETE entry.id=${entry.id}`);
    this.uiRenderer.render(this.stateManager.getLiveCodeLines());
    this.eventBus.emit('command:added:complete', { entry });
  }

  async handleExecutionStart() {
    const timestamp = Date.now();
    console.log(`[CommandFlowController] [${timestamp}] EXECUTION:START`);

    if (this.lock.isLocked()) {
      console.warn(`[CommandFlowController] [${timestamp}] EXECUTION:REJECTED lock already held`);
      return { success: false, reason: 'locked' };
    }

    if (this.stateManager.isEmpty()) {
      console.warn(`[CommandFlowController] [${timestamp}] EXECUTION:REJECTED empty queue`);
      return { success: false, reason: 'empty_queue' };
    }

    this.lock.lock();
    console.log(`[CommandFlowController] [${timestamp}] LOCK:ACQUIRED`);
    this.eventBus.emit('command:executing', { queueLength: this.stateManager.getQueueLength() });

    const queue = this.stateManager.getLiveCodeLines();
    for (let index = 0; index < queue.length; index += 1) {
      if (!this.lock.isLocked()) {
        console.log(`[CommandFlowController] [${timestamp}] EXECUTION:INTERRUPTED lock released`);
        break;
      }

      const line = queue[index];
      this.currentExecutingLineId = line.id;

      this.stateManager.updateStatusById(line.id, 'active');
      this.uiRenderer.render(this.stateManager.getLiveCodeLines());
      console.log(`[CommandFlowController] [${timestamp}] LINE:ACTIVE id=${line.id} index=${index}`);
      this.eventBus.emit('command:executing:line', { line, index });

      const result = await this.executor.executeCommand(line, index);

      if (result.reason === 'validation_failed' || result.reason === 'executor_crash') {
        this.handleExecutionError(line.id, index, result);
      } else if (result.success) {
        this.handleExecutionComplete(line.id, index, result);
      } else {
        this.handleExecutionError(line.id, index, result);
      }

      if (result.reason === 'collision' || result.reason === 'executor_crash') {
        break;
      }
    }

    this.currentExecutingLineId = null;
    this.lock.unlock();
    console.log(`[CommandFlowController] [${timestamp}] LOCK:RELEASED`);
    this.executor.clearExecutionHistory();
    this.eventBus.emit('command:execution_finished', { queueLength: this.stateManager.getQueueLength() });
    console.log(`[CommandFlowController] [${timestamp}] EXECUTION:FINISHED`);
    return { success: true };
  }

  handleExecutionComplete(lineId, index, result) {
    const timestamp = Date.now();
    console.log(`[CommandFlowController] [${timestamp}] COMMAND:COMPLETED id=${lineId} index=${index}`);

    this.stateManager.updateStatusById(lineId, 'success');
    this.uiRenderer.render(this.stateManager.getLiveCodeLines());
    this.eventBus.emit('command:completed', { lineId, index, result });
  }

  handleExecutionError(lineId, index, result) {
    const timestamp = Date.now();
    console.error(`[CommandFlowController] [${timestamp}] COMMAND:FAILED id=${lineId} index=${index} reason=${result.reason}`);

    this.stateManager.updateStatusById(lineId, 'error');
    this.uiRenderer.render(this.stateManager.getLiveCodeLines());
    this.eventBus.emit('command:failed', { lineId, index, result });
  }

  handleExecutorCrash(payload) {
    const timestamp = Date.now();
    console.error(`[CommandFlowController] [${timestamp}] EXECUTOR:CRASH id=${payload.commandId} error=${payload.error}`);

    if (this.currentExecutingLineId) {
      this.stateManager.updateStatusById(this.currentExecutingLineId, 'error');
      this.uiRenderer.render(this.stateManager.getLiveCodeLines());
    }

    if (this.lock.isLocked()) {
      this.lock.unlock();
      console.log(`[CommandFlowController] [${timestamp}] FAILSAFE:LOCK_RELEASED after crash`);
    }
  }

  handleValidationFailed(payload) {
    const timestamp = Date.now();
    console.warn(`[CommandFlowController] [${timestamp}] VALIDATION:FAILED id=${payload.commandId} reason=${payload.reason}`);
  }

  reset() {
    const timestamp = Date.now();
    console.log(`[CommandFlowController] [${timestamp}] SYSTEM:RESET`);

    if (this.lock.isLocked()) {
      this.lock.unlock();
      console.log(`[CommandFlowController] [${timestamp}] LOCK:RELEASED during reset`);
    }

    this.currentExecutingLineId = null;
    this.executor.clearExecutionHistory();
    this.stateManager.clear();
    this.uiRenderer.render(this.stateManager.getLiveCodeLines());
    this.eventBus.emit('system:reset');
  }
}
