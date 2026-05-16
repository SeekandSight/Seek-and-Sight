export default class TimAIService {
  constructor() {
    this.mockDelay = this.randomDelay(800, 1200);
  }

  randomDelay(min, max) {
    return Math.floor(Math.random() * (max - min + 1)) + min;
  }

  async sendToTimAI(payload) {
    await new Promise((resolve) => setTimeout(resolve, this.mockDelay));

    const isSuccess = Math.random() < 0.8;

    if (isSuccess) {
      return {
        reply: this.generateLiveReply(payload),
        mode: 'live',
        status: 'success',
      };
    }

    return {
      reply: 'Tim is learning too! Let me help with that.',
      mode: 'fallback',
      status: 'error',
    };
  }

  generateLiveReply(payload) {
    const commandUsed = payload.commandUsed || 'UNKNOWN';
    const replies = {
      GO: [
        'Great! Moving forward!',
        'Nice move! Keep going!',
        'Forward progress! 🚀',
      ],
      JUMP: [
        'Excellent jump! You cleared it!',
        'High flying! 🎉',
        'Nice air time!',
      ],
      FIX: [
        'Tile fixed! Good work!',
        'Repair complete!',
        'All patched up!',
      ],
    };

    const commandReplies = replies[commandUsed] || [
      'Good command!',
      'Command received!',
      'Executing...',
    ];

    return commandReplies[Math.floor(Math.random() * commandReplies.length)];
  }
}
