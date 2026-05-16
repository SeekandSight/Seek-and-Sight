export default class PlayerClarityManager {
  constructor(scene, eventBus) {
    this.scene = scene;
    this.eventBus = eventBus;
    this.hintsEnabled = true;
    this.currentHint = null;
    this.currentFailureReason = null;

    this.setupEventListeners();
  }

  setupEventListeners() {
    this.eventBus.on('command:added:complete', ({ entry }) => {
      this.showCommandAddedHint(entry);
    });

    this.eventBus.on('command:validation_failed', ({ reason }) => {
      this.showValidationFailureHint(reason);
    });

    this.eventBus.on('command:executing', () => {
      this.showExecutingHint();
    });

    this.eventBus.on('command:completed', () => {
      this.showCommandSuccessHint();
    });

    this.eventBus.on('command:failed', ({ result }) => {
      this.showCommandFailureHint(result);
    });

    this.eventBus.on('level:complete', (evaluation) => {
      this.showLevelCompleteHint(evaluation);
    });

    this.eventBus.on('level:fail', (evaluation) => {
      this.showLevelFailHint(evaluation);
    });
  }

  showHint(message, temporary = true) {
    if (!this.hintsEnabled) return;

    this.currentHint = message;
    const textObj = this.scene.add.text(20, 560, message, {
      fontSize: '16px',
      fill: '#ffcc00',
      fontFamily: 'monospace',
      wordWrap: { width: 750 },
      backgroundColor: '#1a1a1a',
      padding: { x: 8, y: 8 },
    });

    if (temporary) {
      this.scene.time.delayedCall(4000, () => {
        if (textObj) {
          textObj.destroy();
        }
      });
    }

    return textObj;
  }

  showCommandAddedHint(entry) {
    const command = entry.commandRef;
    const hints = {
      GO: 'Good! 🚀 GO moves you one step forward.',
      JUMP: 'Great! 🎉 JUMP helps you skip obstacles.',
      FIX: 'Smart! 🔧 FIX repairs broken tiles.',
      'TURN LEFT': 'Nice! ↪️ Turn LEFT to change direction.',
    };

    const hint = hints[command] || `Added ${command} to your code!`;
    this.showHint(hint);
  }

  showExecutingHint() {
    this.showHint('Running your code... 🤖', false);
  }

  showCommandSuccessHint() {
    this.showHint('✅ Command worked! Nice job!');
  }

  showCommandFailureHint(result) {
    const hints = {
      validation_failed: 'That move is not allowed here. Try a different command.',
      collision: 'Oops! Hit an obstacle. Use JUMP next time!',
      api_error: 'Techie Tim had a hiccup. Try again!',
      executor_crash: 'Something went wrong. Please reset and try again.',
    };

    const hint = hints[result.reason] || 'Command failed. Try again!';
    this.showHint(`❌ ${hint}`);
  }

  showValidationFailureHint(reason) {
    const childFriendlyReason = this.translateReason(reason);
    this.showHint(`⚠️ ${childFriendlyReason}`);
  }

  showLevelCompleteHint(evaluation) {
    const message = `🎊 You did it! Reached the goal in ${evaluation.commandCount} moves! 🌟`;
    this.showHint(message);
  }

  showLevelFailHint(evaluation) {
    if (evaluation.failureReasons && evaluation.failureReasons.length > 0) {
      const reason = evaluation.failureReasons[0];
      const hint = this.translateLevelFailure(reason);
      this.showHint(`Try again! ${hint}`);
    } else {
      this.showHint('Almost there! Try again.');
    }
  }

  translateReason(technicalReason) {
    const reasonMap = {
      'Obstacle ahead! Use JUMP to bypass.': 'Rock blocking your path! Try JUMP to jump over it.',
      'No cracked tile here. Move to a broken zone first.': 'No broken tile here yet. Move closer to a cracked area first.',
      'Unknown command': 'I don\'t know that command. Try GO, JUMP, or FIX.',
    };

    return reasonMap[technicalReason] || technicalReason;
  }

  translateLevelFailure(technicalFailure) {
    if (technicalFailure.includes('distance')) {
      return 'You need to get closer to the goal. Try adding more GO commands.';
    }
    if (technicalFailure.includes('Missing required')) {
      return 'You need to use all the required moves. Look at the instructions again.';
    }
    if (technicalFailure.includes('too many')) {
      return 'You\'re using too many moves! Try a shorter path.';
    }
    return 'Check if you\'re following all the rules and try again.';
  }

  getNextExpectedCommand() {
    const usedCommands = this.scene.commandState.getLiveCodeLines().map((line) => line.commandRef);

    const suggestions = {
      default: 'Try adding a GO command to move forward.',
      afterGO: 'Try JUMP if you see an obstacle ahead.',
      afterJUMP: 'Try GO again, or FIX a broken tile if you see one.',
      afterFIX: 'Keep moving! Add GO or JUMP.',
    };

    if (usedCommands.length === 0) {
      return suggestions.default;
    }

    const lastCommand = usedCommands[usedCommands.length - 1];
    if (lastCommand === 'GO') {
      return suggestions.afterGO;
    }
    if (lastCommand === 'JUMP') {
      return suggestions.afterJUMP;
    }
    if (lastCommand === 'FIX') {
      return suggestions.afterFIX;
    }

    return suggestions.default;
  }

  showNextExpectedCommandHint() {
    const hint = this.getNextExpectedCommand();
    this.showHint(`💡 Tip: ${hint}`);
  }

  disableHints() {
    this.hintsEnabled = false;
  }

  enableHints() {
    this.hintsEnabled = true;
  }
}
