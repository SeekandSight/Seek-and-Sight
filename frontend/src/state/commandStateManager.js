const STATUSES = {
  pending: 'pending',
  active: 'active',
  success: 'success',
  error: 'error',
};

function createUniqueId() {
  if (typeof crypto !== 'undefined' && crypto.randomUUID) {
    return crypto.randomUUID();
  }
  return `line-${Date.now()}-${Math.random().toString(36).slice(2)}`;
}

export default class CommandStateManager {
  constructor(maxQueueLength = 10) {
    this.maxQueueLength = maxQueueLength;
    this.lines = [];
  }

  getLiveCodeLines() {
    return this.lines.map((line) => ({ ...line }));
  }

  getQueueLength() {
    return this.lines.length;
  }

  canAcceptCommand() {
    return this.lines.length < this.maxQueueLength;
  }

  isEmpty() {
    return this.lines.length === 0;
  }

  addCommand(commandUsed, functionName, codeLine) {
    if (!this.canAcceptCommand()) {
      return null;
    }

    const entry = {
      id: createUniqueId(),
      text: codeLine,
      status: STATUSES.pending,
      timestamp: Date.now(),
      commandRef: commandUsed,
      functionName,
      commandUsed,
      index: this.lines.length + 1,
    };

    this.lines.push(entry);
    return entry;
  }

  updateStatusById(id, status) {
    if (!Object.values(STATUSES).includes(status)) {
      return null;
    }
    const target = this.lines.find((line) => line.id === id);
    if (!target) {
      return null;
    }
    target.status = status;
    return target;
  }

  updateStatusByIndex(index, status) {
    if (index < 0 || index >= this.lines.length) {
      return null;
    }
    return this.updateStatusById(this.lines[index].id, status);
  }

  getLineByIndex(index) {
    return this.lines[index] || null;
  }

  clear() {
    this.lines = [];
  }
}
