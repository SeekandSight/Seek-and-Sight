export default class EventBus {
  constructor() {
    this.listeners = new Map();
  }

  on(event, callback) {
    if (!this.listeners.has(event)) {
      this.listeners.set(event, new Set());
    }
    this.listeners.get(event).add(callback);
  }

  emit(event, data) {
    const subscribers = this.listeners.get(event);
    if (!subscribers) {
      return;
    }
    subscribers.forEach((callback) => {
      try {
        callback(data);
      } catch (error) {
        console.error(`[EventBus] error handling event ${event}:`, error);
      }
    });
  }

  off(event, callback) {
    const subscribers = this.listeners.get(event);
    if (!subscribers) {
      return;
    }
    subscribers.delete(callback);
    if (subscribers.size === 0) {
      this.listeners.delete(event);
    }
  }
}
