export default class PlaytestLogger {
  constructor(enabled = false) {
    this.enabled = enabled;
    this.gameSessionLog = [];
    this.sessionStartTime = null;
  }

  startSession() {
    if (!this.enabled) return;
    this.sessionStartTime = Date.now();
    this.gameSessionLog = [];
    console.log('[PlaytestLogger] SESSION START');
  }

  logEvent(eventType, commandId = null, status = null, metadata = {}) {
    if (!this.enabled) return;

    const timestamp = Date.now();
    const entry = {
      eventType,
      timestamp,
      commandId,
      status,
      metadata,
      sessionElapsed: timestamp - this.sessionStartTime,
    };

    this.gameSessionLog.push(entry);
    console.log(`[PlaytestLogger] ${eventType}`, entry);
  }

  summarizePlaytest() {
    if (!this.enabled || this.gameSessionLog.length === 0) {
      console.warn('[PlaytestLogger] No session data to summarize');
      return null;
    }

    const executedCommands = this.gameSessionLog.filter((e) => e.eventType === 'command:executed');
    const successCount = executedCommands.filter((e) => e.status === 'success').length;
    const errorCount = executedCommands.filter((e) => e.status === 'error').length;

    const executionTimes = [];
    for (let i = 0; i < executedCommands.length - 1; i += 1) {
      const nextStart = executedCommands[i + 1].timestamp;
      const currentStart = executedCommands[i].timestamp;
      executionTimes.push(nextStart - currentStart);
    }

    const avgExecutionTime = executionTimes.length > 0
      ? (executionTimes.reduce((a, b) => a + b, 0) / executionTimes.length).toFixed(2)
      : 0;

    const sessionDuration = this.gameSessionLog[this.gameSessionLog.length - 1].timestamp - this.sessionStartTime;

    const summary = {
      totalCommandsExecuted: executedCommands.length,
      successCount,
      errorCount,
      averageExecutionTime: `${avgExecutionTime}ms`,
      sessionDuration: `${sessionDuration}ms`,
      successRate: `${((successCount / executedCommands.length) * 100).toFixed(2)}%`,
      fullLog: this.gameSessionLog,
    };

    console.log('[PlaytestLogger] === PLAYTEST SUMMARY ===');
    console.table(summary);
    console.log('[PlaytestLogger] Full log:', this.gameSessionLog);

    return summary;
  }

  getSessionLog() {
    return this.gameSessionLog;
  }
}
