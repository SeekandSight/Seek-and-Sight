class BootScene extends Phaser.Scene {
    constructor() {
        super('BootScene');
    }

    // ==========================================
    // MAIN INITIALIZATION
    // ==========================================
    create() {
        this.setupEnvironment();
        this.setupLiveCodePanel();
        this.setupUI();

        this.commandQueue = [];
        this.isExecuting = false;

        // Draw the initial placeholder text in the panel
        this.updateQueueDisplay();
    }

    // ==========================================
    // 1. ENVIRONMENT & ENTITIES
    // ==========================================
    setupEnvironment() {
        this.add.text(20, 20, "Level 1: Jump the Rock!", { fontSize: '24px', fill: '#00ff00' });

        this.startX = 100;
        this.startY = 250;

        // Player
        this.player = this.add.rectangle(this.startX, this.startY, 40, 40, 0x00aaff);

        // Obstacle (Red rock)
        this.obstacle = this.add.rectangle(300, 250, 40, 40, 0xff0000);
        this.add.text(285, 220, 'Rock', { fontSize: '14px', fill: '#ff0000' });

        // Goal (Yellow Star)
        this.star = this.add.rectangle(500, 250, 40, 40, 0xffff00);
        this.add.text(480, 220, 'Goal', { fontSize: '14px', fill: '#ffff00' });

        // System Feedback Text
        this.replyText = this.add.text(20, 520, 'Write code to reach the yellow Goal!', {
            fontSize: '18px', fill: '#aaaaaa', wordWrap: { width: 760 }
        });
    }

    // ==========================================
    // 2. UI RENDERING
    // ==========================================
    setupLiveCodePanel() {
        // Draw Dark Panel Background on the right side
        this.add.rectangle(670, 200, 240, 350, 0x111111).setStrokeStyle(2, 0x444444);
        this.add.text(560, 40, 'LIVE CODE', { fontSize: '16px', fill: '#888888', fontFamily: 'monospace' });

        this.codeLineTexts = []; // Holds the visual text objects
    }

    setupUI() {
        // Input Buttons
        this.createButton(20, 440, 'GO', () => this.addToQueue('GO', 'robotGoForward', 'robotGoForward();'));
        this.createButton(90, 440, 'JUMP', () => this.addToQueue('JUMP', 'robotJump', 'robotJump();'));
        this.createButton(180, 440, 'TURN LEFT', () => this.addToQueue('TURN LEFT', 'robotTurnLeft', 'robotTurnLeft();'));

        // Control Buttons
        this.createButton(400, 440, '▶ RUN CODE', () => this.executeQueue(), '#00aa00');
        this.createButton(560, 440, '✖ RESET', () => this.resetGame(), '#aa0000');
    }

    createButton(x, y, text, callback, bgColor = '#333333') {
        return this.add.text(x, y, `[ ${text} ]`, {
            fontSize: '18px', fill: '#ffffff', backgroundColor: bgColor, padding: { x: 8, y: 8 }
        }).setInteractive({ useHandCursor: true }).on('pointerdown', callback);
    }

    // ==========================================
    // 3. QUEUE MANAGEMENT
    // ==========================================
    addToQueue(commandUsed, functionName, codeLine) {
        if (this.isExecuting) return;

        if (this.commandQueue.length >= 10) {
            this.replyText.setText("Code Panel is full!");
            return;
        }

        this.commandQueue.push({ commandUsed, functionName, codeLine });
        this.updateQueueDisplay();
    }

    updateQueueDisplay() {
        // Clear old text lines
        this.codeLineTexts.forEach(txt => txt.destroy());
        this.codeLineTexts = [];

        if (this.commandQueue.length === 0) {
            let placeholder = this.add.text(560, 70, '// No code yet', { fontSize: '14px', fill: '#555555', fontFamily: 'monospace' });
            this.codeLineTexts.push(placeholder);
            return;
        }

        // Draw fresh code lines
        for (let i = 0; i < this.commandQueue.length; i++) {
            let yPos = 70 + (i * 25);
            let codeStr = `${i + 1}. ${this.commandQueue[i].functionName}();`;

            let textObj = this.add.text(560, yPos, codeStr, {
                fontSize: '14px', fill: '#ffffff', fontFamily: 'monospace'
            });
            this.codeLineTexts.push(textObj);
        }
    }

    resetGame() {
        if (this.isExecuting) return;

        this.commandQueue = [];
        this.updateQueueDisplay();

        this.player.setPosition(this.startX, this.startY);
        this.player.setAngle(0);
        this.replyText.setText('Level reset. Try writing new code!');
    }

    // ==========================================
    // 4. ASYNC EXECUTION LOGIC
    // ==========================================
    async executeQueue() {
        if (this.isExecuting || this.commandQueue.length === 0) return;
        this.isExecuting = true;

        for (let i = 0; i < this.commandQueue.length; i++) {
            const cmd = this.commandQueue[i];

            // Highlight current line
            if (this.codeLineTexts[i]) this.codeLineTexts[i].setColor('#00ffff');

            // Talk to Backend
            await this.callDjangoAPI(cmd, i + 1);

            // Play Animation
            await this.playCommandAnimation(cmd.commandUsed);

            // Check Collisions (Stops execution if it returns 'stop')
            const collisionResult = this.checkCollisions(i);
            if (collisionResult === 'stop') return;

            // Safe move completed: Highlight green
            if (this.codeLineTexts[i]) this.codeLineTexts[i].setColor('#00ff00');

            await new Promise(resolve => setTimeout(resolve, 300));
        }

        this.isExecuting = false;
        this.replyText.setText('Finished running code, but you didn\'t reach the goal!');
    }

    // ==========================================
    // 5. COLLISION DETECTION
    // ==========================================
    checkCollisions(lineIndex) {
        const playerBounds = this.player.getBounds();

        // Star Collision
        if (Phaser.Geom.Intersects.RectangleToRectangle(playerBounds, this.star.getBounds())) {
            this.replyText.setText('🌟 SUCCESS! You reached the goal! 🌟');
            if (this.codeLineTexts[lineIndex]) this.codeLineTexts[lineIndex].setColor('#00ff00');
            this.isExecuting = false;
            return 'stop';
        }

        // Obstacle Collision
        if (Phaser.Geom.Intersects.RectangleToRectangle(playerBounds, this.obstacle.getBounds())) {
            this.replyText.setText('Oops! You hit a rock. Reset and try jumping over it!');
            if (this.codeLineTexts[lineIndex]) this.codeLineTexts[lineIndex].setColor('#ff0000');
            this.tweens.add({ targets: this.player, x: this.player.x - 20, duration: 200 });
            this.isExecuting = false;
            return 'stop';
        }

        return 'continue';
    }

    // ==========================================
    // 6. ANIMATION LOGIC
    // ==========================================
    playCommandAnimation(command) {
        return new Promise(resolve => {
            let tweenConfig = { targets: this.player, onComplete: resolve };

            if (command === 'GO') {
                tweenConfig.x = this.player.x + 100;
                tweenConfig.duration = 500;
                tweenConfig.ease = 'Power2';
            } else if (command === 'JUMP') {
                tweenConfig.x = this.player.x + 100;
                tweenConfig.y = this.player.y - 100;
                tweenConfig.duration = 500;
                tweenConfig.yoyo = true;
                tweenConfig.ease = 'Sine.easeInOut';
            } else if (command === 'TURN LEFT') {
                tweenConfig.angle = this.player.angle - 90;
                tweenConfig.duration = 300;
                tweenConfig.ease = 'Linear';
            }
            this.tweens.add(tweenConfig);
        });
    }

    // ==========================================
    // 7. API COMMUNICATION
    // ==========================================
    async callDjangoAPI(cmd, attemptNumber) {
        try {
            const response = await fetch('http://127.0.0.1:8000/api/tim/ai-response/', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    message: `Executing ${cmd.commandUsed}!`,
                    command_used: cmd.commandUsed,
                    function_name: cmd.functionName,
                    code_line: cmd.codeLine,
                    is_correct: false,  // Will be updated based on collision later
                    attempt_number: attemptNumber,
                    active_profile: "DYSLEXIA",  // Default for demo
                    mini_game: "level_1",
                    consecutive_streak: 2,  // Mock value
                    session_accuracy: 85.5,  // Mock value
                    obstacle_ahead: "rock",
                    words_missed: []  // Empty for now
                })
            });

            if (!response.ok) {
                throw new Error(`HTTP ${response.status}: ${response.statusText}`);
            }

            const data = await response.json();

            // Only update text if the game is still executing (not interrupted by collision)
            if (this.isExecuting) this.replyText.setText(data.reply);
        } catch (error) {
            console.error('API call failed:', error);
            // Graceful fallback - don't break the game
            if (this.isExecuting) {
                this.replyText.setText('Techie Tim is taking a break. Keep coding!');
            }
        }
    }
}

// ------------------------------------------
// PHASER BOOTSTRAP
// ------------------------------------------
const config = { type: Phaser.AUTO, width: 800, height: 600, parent: 'game-container', backgroundColor: '#1e1e1e', scene: [BootScene] };
const game = new Phaser.Game(config);
