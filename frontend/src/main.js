import CommandStateManager from './state/commandStateManager.js';
import LiveCodePanelRenderer from './ui/liveCodePanelRenderer.js';
import CommandExecutor from './engine/commandExecutor.js';
import CommandFlowController from './commandFlowController.js';
import EventBus from './eventBus.js';
import ExecutionLock from './executionLock.js';
import AiClient from './api/aiClient.js';
import TimAIService from './api/timAIService.js';
import GameRulesEngine from './gameRulesEngine.js';
import CommandPaletteUI from './commandPaletteUI.js';
import DropZoneHandler from './dropZoneHandler.js';
import DragDropCommandSystem from './dragDropCommandSystem.js';
import PlaytestLogger from './playtestLogger.js';
import GameTruthValidator from './gameTruthValidator.js';
import LevelGoalManager from './levelGoalManager.js';
import PlayerClarityManager from './playerClarityManager.js';

class BootScene extends Phaser.Scene {
    constructor() {
        super('BootScene');
    }

    // ==========================================
    // MAIN INITIALIZATION
    // ==========================================
    create() {
        // Playtest Mode Configuration
        const playtestMode = true; // Set to true to enable playtest logging
        const autoLoadTestScenario = false; // Set to true to auto-load test commands

        this.isExecuting = false;
        this.typewriterTimer = null;
        this.maxQueueLength = 10;
        this.lastCommandTime = 0;
        this.commandDebounceMs = 200;

        this.setupGameState();
        this.setupEnvironment();
        this.setupLiveCodePanel();
        this.setupUI();

        this.commandState = new CommandStateManager(this.maxQueueLength);
        this.liveCodePanel = new LiveCodePanelRenderer(this, 560, 40, 240, 350);
        this.apiClient = new AiClient();
        this.timAIService = new TimAIService();
        this.gameRulesEngine = new GameRulesEngine(this);
        this.eventBus = new EventBus();
        this.executionLock = new ExecutionLock();
        this.commandExecutor = new CommandExecutor(this, this.callDjangoAPI.bind(this), this.gameRulesEngine);
        this.commandPaletteUI = new CommandPaletteUI(this);
        this.dropZoneHandler = new DropZoneHandler(this, 300, 310, 360, 140);
        this.dragDropCommandSystem = new DragDropCommandSystem(this, this.eventBus, this.commandPaletteUI, this.dropZoneHandler);
        this.playtestLogger = new PlaytestLogger(playtestMode);
        this.gameTruthValidator = new GameTruthValidator(this, this.commandState, this.eventBus);
        this.levelGoalManager = new LevelGoalManager(this, this.eventBus);
        this.playerClarityManager = new PlayerClarityManager(this, this.eventBus);

        this.collectibleCount = 0;
        this.currentCommandLabel = null;
        this.isResetting = false;

        this.commandFlowController = new CommandFlowController({
            scene: this,
            stateManager: this.commandState,
            uiRenderer: this.liveCodePanel,
            executor: this.commandExecutor,
            eventBus: this.eventBus,
            lock: this.executionLock,
        });
        this.commandFlowController.init();
        this.dragDropCommandSystem.initDragSystem();

        // Define level goal using GRID coordinates only (not pixels)
        this.levelGoalManager.defineGoal({
            targetGridX: this.goalGridX,
            requiredCommands: ['GO', 'JUMP'],
            maxCommands: 10,
        });

        // Start playtest session
        if (playtestMode) {
            this.playtestLogger.startSession();
        }

        // Setup event logging for playtest
        if (playtestMode) {
            this.eventBus.on('command:added:complete', ({ entry }) => {
                this.playtestLogger.logEvent('command:added', entry.id, 'pending', { command: entry.commandRef });
            });
            this.eventBus.on('command:executing', () => {
                this.playtestLogger.logEvent('command:executing', null, 'active', {});
            });
            this.eventBus.on('command:completed', ({ lineId }) => {
                this.playtestLogger.logEvent('command:executed', lineId, 'success', {});
            });
            this.eventBus.on('command:failed', ({ lineId }) => {
                this.playtestLogger.logEvent('command:executed', lineId, 'error', {});
            });
            this.eventBus.on('level:complete', (evaluation) => {
                this.playtestLogger.logEvent('level:complete', null, 'success', evaluation);
            });
            this.eventBus.on('level:fail', (evaluation) => {
                this.playtestLogger.logEvent('level:fail', null, 'error', evaluation);
            });
        }

        // Auto-load test scenario if enabled
        if (autoLoadTestScenario) {
            this.loadTestScenario(['GO', 'GO', 'JUMP', 'FIX']);
        }

        this.eventBus.on('command:executing', () => {
            this.isExecuting = true;
            this.setReplyText('Running code...', true);
        });

        this.eventBus.on('command:execution_finished', () => {
            this.isExecuting = false;
            if (!this.executionLock.isLocked()) {
                this.setReplyText('Finished running code, but you didn\'t reach the goal!', true);
            }
        });

        this.eventBus.on('command:added:complete', ({ entry }) => {
            this.setReplyText(`Added ${entry.commandRef} to the code panel.`, true);
        });

        this.eventBus.on('command:validation_failed', ({ commandId, reason }) => {
            this.setReplyText(`Can't execute: ${reason}`, true);
            console.warn('[GameEngine] Validation failed:', reason);
        });

        this.eventBus.on('command:executor_crash', ({ commandId, error }) => {
            this.setReplyText('System error during execution. Please try again.', true);
            console.error('[GameEngine] Executor crash:', error);
        });

        this.eventBus.on('system:reset', () => {
            this.isExecuting = false;
        });

        console.log('[GameEngine] Initialized with max queue length:', this.maxQueueLength);
        this.updateQueueDisplay();
    }

    setupGameState() {
        this.activeProfile = 'DYSLEXIA';
        this.miniGame = 'robot_path_builder';
        this.consecutiveStreak = 0;
        this.sessionAccuracy = 100;
        this.obstacleAhead = 'rock';
        this.wordsMissed = [];
        this.attemptNumber = 1;
        this.gameEvents = new Phaser.Events.EventEmitter();
    }

    // ==========================================
    // HELPER: Load Test Scenario
    // ==========================================
    loadTestScenario(commands = ['GO', 'GO', 'JUMP', 'FIX']) {
        console.log('[GameEngine] Loading test scenario:', commands);
        commands.forEach((cmd) => {
            const definition = this.getCommandDefinition(cmd);
            if (definition) {
                this.eventBus.emit('command:added', {
                    commandUsed: cmd,
                    functionName: definition.functionName,
                    codeLine: definition.codeLine,
                });
            }
        });
    }

    // ==========================================
    // HELPER: Print Playtest Summary
    // ==========================================
    printPlaytestSummary() {
        const summary = this.playtestLogger.summarizePlaytest();
        return summary;
    }

    // ==========================================
    // HELPER: Get Validation Results
    // ==========================================
    getValidationResults() {
        return this.gameTruthValidator.getValidationResults();
    }

    getCommandDefinition(commandUsed) {
        const definitions = {
            GO: { functionName: 'robotGoForward', codeLine: 'robotGoForward();' },
            JUMP: { functionName: 'robotJump', codeLine: 'robotJump();' },
            FIX: { functionName: 'robotFix', codeLine: 'robotFix();' },
            'TURN LEFT': { functionName: 'robotTurnLeft', codeLine: 'robotTurnLeft();' },
        };
        return definitions[commandUsed] || null;
    }

    // ==========================================
    // 1. ENVIRONMENT & ENTITIES
    // ==========================================
    setupEnvironment() {
        this.add.text(20, 20, 'Level 1: Robot Path Builder', { fontSize: '24px', fill: '#00ff00' });
        this.add.text(20, 50, 'Use GO, JUMP, and FIX to reach the goal and collect the tools!', { fontSize: '16px', fill: '#cccccc' });

        // ==========================================
        // GRID SYSTEM — Single Source of Truth
        // playerGridX and playerGridY are the ONLY gameplay state.
        // All pixel positions are derived from these at render time.
        // NEVER read sprite.x / sprite.y for gameplay logic.
        // ==========================================
        this.TILE_SIZE = 100;       // pixels per grid tile
        this.GRID_ORIGIN_X = 100;   // pixel x of gridX=0
        this.GRID_ORIGIN_Y = 280;   // pixel y of gridY=0

        this.playerGridX = 0;       // grid column (integer)
        this.playerGridY = 0;       // grid row   (integer, 0 = ground row)
        this.playerDirection = 'right'; // cardinal direction state (not sprite angle)

        // ==========================================
        // RENDER STATE — the tween target layer
        // Tweens ONLY mutate these numbers.
        // syncPlayerToGrid() reads them and writes to the sprite.
        // This is the bridge between animation and Phaser rendering.
        // ==========================================
        this.renderState = {
            x: this.GRID_ORIGIN_X,          // current interpolated pixel x
            y: this.GRID_ORIGIN_Y,          // current interpolated pixel y
            angle: 0,                        // current visual rotation (degrees)
            scaleX: 1,                       // current visual scale X
            scaleY: 1,                       // current visual scale Y
        };

        // goalGridX is declared here so setupEnvironment owns all grid constants
        this.goalGridX = 6;

        this.pathZones = [];
        this.collectibles = [];

        this.createPathLayout();

        // Spawn player at the grid origin — derived from grid state, not hardcoded pixels
        this.player = this.add.rectangle(
            this.gridToPixelX(this.playerGridX),
            this.gridToPixelY(this.playerGridY),
            40, 40, 0x00aaff
        ).setStrokeStyle(2, 0xffffff);
        this.player.setDepth(2);

        // Goal sprite — position derived from grid constant
        const goalPixelX = this.gridToPixelX(this.goalGridX);
        this.goal = this.add.rectangle(goalPixelX, this.gridToPixelY(0), 48, 48, 0xffd700).setStrokeStyle(2, 0xffffff);
        this.add.text(goalPixelX - 20, this.gridToPixelY(0) - 50, 'Goal', { fontSize: '16px', fill: '#ffff00' });

        this.collectibleCounterText = this.add.text(20, 520, 'Tools collected: 0', {
            fontSize: '18px', fill: '#ffffff'
        });

        this.replyText = this.add.text(20, 550, 'Write code to reach the goal. Watch the obstacles!', {
            fontSize: '18px', fill: '#aaaaaa', wordWrap: { width: 760 }
        });
    }

    // ==========================================
    // GRID ↔ PIXEL CONVERSION
    // These are the ONLY functions that know pixel formulas.
    // ==========================================

    // Converts grid column → pixel x centre
    gridToPixelX(gridX) {
        return this.GRID_ORIGIN_X + gridX * this.TILE_SIZE;
    }

    // Converts grid row → pixel y centre
    gridToPixelY(gridY) {
        return this.GRID_ORIGIN_Y + gridY * this.TILE_SIZE;
    }

    // ==========================================
    // SINGLE RENDER-SYNC FUNCTION
    // The ONLY place allowed to call ANY Phaser sprite method.
    // Reads renderState (set by tweens) and game state (playerGridX/Y)
    // and applies them to the sprite. Called by tweens via onUpdate
    // and directly for instant snaps (reset, collision).
    // ==========================================
    syncPlayerToGrid() {
        this.player.setPosition(this.renderState.x, this.renderState.y);
        this.player.setAngle(this.renderState.angle);
        this.player.setScale(this.renderState.scaleX, this.renderState.scaleY);
    }

    // Snap renderState to exact grid position, then sync sprite.
    // Used for instant moves: reset, collision correction.
    snapToGrid() {
        this.renderState.x = this.gridToPixelX(this.playerGridX);
        this.renderState.y = this.gridToPixelY(this.playerGridY);
        this.syncPlayerToGrid();
    }

    createPathLayout() {
        // Draw decorative ground
        this.add.rectangle(400, 330, 760, 240, 0x2d2d2d).setOrigin(0.5);
        const ground = this.add.rectangle(400, 340, 760, 100, 0x444444).setOrigin(0.5);
        ground.setDepth(0);

        // --- OBSTACLE ZONES (defined by gridX, rendered at matching pixel position) ---
        // Layout:  tile 0=start  1=safe  2=lava  3=safe  4=water  5=cracked  6=goal

        const lavaGridX = 2;
        const lavaPixelX = this.gridToPixelX(lavaGridX);
        const lavaZone = this.add.rectangle(lavaPixelX, 285, 80, 40, 0xff4500).setOrigin(0.5);
        this.add.text(lavaPixelX - 20, 260, 'LAVA', { fontSize: '14px', fill: '#ffffff' });
        this.pathZones.push({ type: 'lava', gridX: lavaGridX, rect: lavaZone });

        const waterGridX = 4;
        const waterPixelX = this.gridToPixelX(waterGridX);
        const waterZone = this.add.rectangle(waterPixelX, 285, 80, 40, 0x1e90ff).setOrigin(0.5);
        this.add.text(waterPixelX - 25, 260, 'WATER', { fontSize: '14px', fill: '#ffffff' });
        this.pathZones.push({ type: 'water', gridX: waterGridX, rect: waterZone });

        const crackedGridX = 5;
        const crackedPixelX = this.gridToPixelX(crackedGridX);
        const crackedZone = this.add.rectangle(crackedPixelX, 285, 80, 40, 0x8b4513).setOrigin(0.5);
        this.add.text(crackedPixelX - 35, 260, 'CRACKED', { fontSize: '14px', fill: '#ffffff' });
        this.pathZones.push({ type: 'cracked', gridX: crackedGridX, rect: crackedZone, fixed: false });

        // Collectibles — placed between tiles, still use pixel positions for visual flair
        const tool1 = this.add.rectangle(this.gridToPixelX(1), 235, 28, 28, 0xffff00).setOrigin(0.5);
        this.add.text(this.gridToPixelX(1) - 14, 215, 'Tool', { fontSize: '12px', fill: '#ffffff' });
        this.collectibles.push({ rect: tool1, collected: false, gridX: 1 });

        const tool2 = this.add.rectangle(this.gridToPixelX(3), 235, 28, 28, 0x00ff00).setOrigin(0.5);
        this.add.text(this.gridToPixelX(3) - 14, 215, 'Tool', { fontSize: '12px', fill: '#ffffff' });
        this.collectibles.push({ rect: tool2, collected: false, gridX: 3 });
    }

    // ==========================================
    // 2. UI RENDERING
    // ==========================================
    setupLiveCodePanel() {
        // LiveCodePanelRenderer will render the panel and content.
    }

    setupUI() {
        this.createButton(20, 440, 'GO', () => this.handleCommandButton('GO'));
        this.createButton(90, 440, 'JUMP', () => this.handleCommandButton('JUMP'));
        this.createButton(180, 440, 'TURN LEFT', () => this.handleCommandButton('TURN LEFT'));
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
    handleCommandButton(commandUsed) {
        const now = Date.now();
        if (now - this.lastCommandTime < this.commandDebounceMs) {
            console.log('[GameEngine] Command spam detected, ignoring:', commandUsed);
            return;
        }
        this.lastCommandTime = now;

        if (this.isExecuting || this.executionLock.isLocked()) {
            this.setReplyText('Wait until the current execution finishes.', true);
            console.log('[GameEngine] Command rejected during execution:', commandUsed);
            return;
        }

        const definition = this.getCommandDefinition(commandUsed);
        if (!definition) {
            console.warn('[GameEngine] Rejected invalid command:', commandUsed);
            return;
        }

        this.eventBus.emit('command:added', {
            commandUsed,
            functionName: definition.functionName,
            codeLine: definition.codeLine,
        });
    }

    updateQueueDisplay() {
        this.liveCodePanel.render(this.commandState.getLiveCodeLines());
    }

    clearQueue() {
        this.commandFlowController.reset();
        console.log('[GameEngine] Queue cleared');
    }

    resetGame() {
        if (this.isExecuting) {
            console.log('[GameEngine] Reset triggered during execution, stopping execution');
            this.isExecuting = false;
        }

        this.isResetting = true;
        this.commandFlowController.reset();

        // ==========================================
        // RESET: Mutate grid state only, then snap.
        // NEVER call setPosition/setX/setY/setAngle directly here.
        // ==========================================
        this.playerGridX = 0;
        this.playerGridY = 0;
        this.playerDirection = 'right';

        // Reset renderState to match grid origin, then sync sprite
        this.renderState.x = this.gridToPixelX(0);
        this.renderState.y = this.gridToPixelY(0);
        this.renderState.angle = 0;
        this.renderState.scaleX = 1;
        this.renderState.scaleY = 1;
        this.syncPlayerToGrid();

        this.currentCommandLabel = null;
        this.collectibleCount = 0;
        this.collectibles.forEach((collectible) => {
            collectible.collected = false;
            collectible.rect.setVisible(true);
        });
        // Reset cracked tile state
        this.pathZones.forEach((zone) => {
            if (zone.type === 'cracked') {
                zone.fixed = false;
                zone.rect.setFillStyle(0x8b4513);
            }
        });
        this.updateCollectibleCounter();
        this.setReplyText('Level reset. Try writing new code!', true);
        console.log('[GameEngine] Game reset, queue cleared');
        this.emitGameEvent('queue_finished', { reason: 'reset' });
        this.isResetting = false;
    }

    // ==========================================
    // 4. ASYNC EXECUTION ENGINE
    // ==========================================
    async executeQueue() {
        console.log('[GameEngine] RUN CODE clicked, queue:', this.commandState.getLiveCodeLines().map((line) => line.commandRef));
        const result = await this.commandFlowController.handleExecutionStart();
        if (!result.success) {
            if (result.reason === 'empty_queue') {
                this.setReplyText('Add some commands first!', true);
                console.log('[GameEngine] Empty queue, no execution');
            }
            if (result.reason === 'locked') {
                console.log('[GameEngine] Execution request ignored because lock is held');
            }
        }
    }

    // ==========================================
    // 5. COLLISION DETECTION (Grid-based)
    // ==========================================
    checkCollisions(lineIndex) {
        const gx = this.playerGridX; // grid column — never read sprite.x

        // --- Check Goal ---
        if (gx === this.goalGridX) {
            this.setReplyText('🌟 Goal reached! Great job coding the path!', true);
            this.commandState.updateStatusByIndex(lineIndex, 'success');
            this.updateQueueDisplay();
            this.emitGameEvent('level_completed', { success: true, collectibles: this.collectibleCount });
            return 'stop';
        }

        // --- Check Obstacle Zones ---
        for (const zone of this.pathZones) {
            if (gx !== zone.gridX) continue;

            if (zone.type === 'lava') {
                this.setReplyText('Oops! You landed in lava. Use JUMP to clear it.', true);
                this.commandState.updateStatusByIndex(lineIndex, 'error');
                this.updateQueueDisplay();
                // Mutate grid state, then snap renderState + sprite via snapToGrid()
                this.playerGridX = Math.max(0, gx - 1);
                this.snapToGrid();
                this.emitGameEvent('collision_detected', { type: 'lava', lineIndex });
                return 'stop';
            }

            if (zone.type === 'water') {
                // Water only blocks if you walked (GO); JUMP clears it
                if (this.currentCommandLabel !== 'JUMP') {
                    this.setReplyText('Water stopped you. Try JUMP to cross.', true);
                    this.commandState.updateStatusByIndex(lineIndex, 'error');
                    this.updateQueueDisplay();
                    this.emitGameEvent('collision_detected', { type: 'water', lineIndex });
                    return 'stop';
                }
            }

            if (zone.type === 'cracked') {
                if (this.currentCommandLabel === 'FIX' && !zone.fixed) {
                    zone.fixed = true;
                    zone.rect.setFillStyle(0x228b22);
                    this.setReplyText('Great! You fixed the cracked tile. Now move through safely.', true);
                    continue;
                }
                if (!zone.fixed && this.currentCommandLabel !== 'FIX') {
                    this.setReplyText('That tile is cracked. Use FIX here first.', true);
                    this.commandState.updateStatusByIndex(lineIndex, 'error');
                    this.updateQueueDisplay();
                    this.emitGameEvent('collision_detected', { type: 'cracked', lineIndex });
                    return 'stop';
                }
            }
        }

        // --- Check Collectibles (grid-based) ---
        this.collectibles.forEach((collectible) => {
            if (!collectible.collected && collectible.gridX === gx) {
                collectible.collected = true;
                collectible.rect.setVisible(false);
                this.collectibleCount += 1;
                this.updateCollectibleCounter();
                this.setReplyText(`Nice! You picked up a tool. Tools collected: ${this.collectibleCount}`, true);
            }
        });

        return 'continue';
    }

    // ==========================================
    // 6. ANIMATION LOGIC
    //
    // STRICT ARCHITECTURE RULES:
    //   1. Mutate playerGridX / playerGridY / playerDirection (game state)
    //   2. Tween only mutates this.renderState (numbers, never sprite)
    //   3. Every onUpdate calls syncPlayerToGrid() — the ONLY Phaser write path
    //   4. Never call player.setPosition / setAngle / setScale inside a tween
    // ==========================================
    playCommandAnimation(command, commandIndex) {
        const fromGridX = this.playerGridX;
        const fromGridY = this.playerGridY;

        console.log('[GameEngine] playCommandAnimation: start', { command, commandIndex, gridX: fromGridX });
        this.emitGameEvent('animation_started', { command, commandIndex });

        // -------------------------------------------
        // GO: slide 1 tile forward on X
        // Grid state mutated first. Tween interpolates renderState.x only.
        // -------------------------------------------
        if (command === 'GO') {
            this.playerGridX += 1;
            const fromPx = this.gridToPixelX(fromGridX);
            const toPx   = this.gridToPixelX(this.playerGridX);

            return new Promise((resolve) => {
                this.tweens.addCounter({
                    from: fromPx,
                    to: toPx,
                    duration: 500,
                    ease: 'Power2',
                    onUpdate: (tween) => {
                        // Only renderState is mutated here — never the sprite directly
                        this.renderState.x = tween.getValue();
                        this.syncPlayerToGrid();
                    },
                    onComplete: () => {
                        // Snap to exact pixel to eliminate float drift
                        this.renderState.x = toPx;
                        this.syncPlayerToGrid();
                        console.log('[GameEngine] GO complete', { gridX: this.playerGridX });
                        this.emitGameEvent('animation_completed', { command, commandIndex });
                        resolve();
                    }
                });
            });
        }

        // -------------------------------------------
        // JUMP: two-phase arc — rise then fall
        // Grid state mutated first. Both phases only touch renderState.
        // -------------------------------------------
        if (command === 'JUMP') {
            this.playerGridX += 1;
            const fromPx    = this.gridToPixelX(fromGridX);
            const toPx      = this.gridToPixelX(this.playerGridX);
            const groundPy  = this.gridToPixelY(this.playerGridY);
            const arcPeakPy = groundPy - 100; // Visual-only offset, never in grid state
            const midPx     = (fromPx + toPx) / 2;

            return new Promise((resolve) => {
                // Phase 1: rise from start to arc peak
                this.tweens.addCounter({
                    from: 0, to: 1, duration: 200, ease: 'Sine.easeOut',
                    onUpdate: (tween) => {
                        const t = tween.getValue();
                        this.renderState.x = fromPx + t * (midPx - fromPx);
                        this.renderState.y = groundPy + t * (arcPeakPy - groundPy);
                        this.syncPlayerToGrid();
                    },
                    onComplete: () => {
                        // Phase 2: fall from arc peak to landing tile
                        this.tweens.addCounter({
                            from: 0, to: 1, duration: 300, ease: 'Sine.easeIn',
                            onUpdate: (tween) => {
                                const t = tween.getValue();
                                this.renderState.x = midPx + t * (toPx - midPx);
                                this.renderState.y = arcPeakPy + t * (groundPy - arcPeakPy);
                                this.syncPlayerToGrid();
                            },
                            onComplete: () => {
                                // Snap to exact grid landing position
                                this.renderState.x = toPx;
                                this.renderState.y = groundPy;
                                this.syncPlayerToGrid();
                                console.log('[GameEngine] JUMP complete', { gridX: this.playerGridX });
                                this.emitGameEvent('animation_completed', { command, commandIndex });
                                resolve();
                            }
                        });
                    }
                });
            });
        }

        // -------------------------------------------
        // TURN LEFT: update playerDirection state,
        // animate renderState.angle only — never sprite.angle
        // -------------------------------------------
        if (command === 'TURN LEFT') {
            const dirAngles = { right: 0, up: -90, left: 180, down: 90 };
            const nextDir   = { right: 'up', up: 'left', left: 'down', down: 'right' };

            const fromAngle = this.renderState.angle; // Use renderState, never player.angle
            this.playerDirection = nextDir[this.playerDirection] ?? 'right';
            const toAngle = dirAngles[this.playerDirection];

            return new Promise((resolve) => {
                this.tweens.addCounter({
                    from: fromAngle,
                    to: toAngle,
                    duration: 300,
                    ease: 'Linear',
                    onUpdate: (tween) => {
                        this.renderState.angle = tween.getValue();
                        this.syncPlayerToGrid();
                    },
                    onComplete: () => {
                        this.renderState.angle = toAngle;
                        this.syncPlayerToGrid();
                        console.log('[GameEngine] TURN LEFT complete', { direction: this.playerDirection });
                        this.emitGameEvent('animation_completed', { command, commandIndex });
                        resolve();
                    }
                });
            });
        }

        // -------------------------------------------
        // FIX: in-place pulse — no grid position change
        // Animates renderState.scaleX/Y only — never sprite.setScale directly
        // -------------------------------------------
        if (command === 'FIX') {
            return new Promise((resolve) => {
                this.tweens.addCounter({
                    from: 1, to: 1.15, duration: 120,
                    ease: 'Sine.easeInOut',
                    yoyo: true,
                    onUpdate: (tween) => {
                        const s = tween.getValue();
                        this.renderState.scaleX = s;
                        this.renderState.scaleY = s;
                        this.syncPlayerToGrid();
                    },
                    onComplete: () => {
                        // Snap scale back to neutral in renderState
                        this.renderState.scaleX = 1;
                        this.renderState.scaleY = 1;
                        this.syncPlayerToGrid();
                        console.log('[GameEngine] FIX complete');
                        this.emitGameEvent('animation_completed', { command, commandIndex });
                        resolve();
                    }
                });
            });
        }

        // Unknown command — resolve immediately so execution loop never hangs
        console.warn('[GameEngine] Unknown command, skipping animation:', command);
        return Promise.resolve();
    }

    // ==========================================
    // 7. API COMMUNICATION
    // ==========================================
    async callDjangoAPI(cmd, attemptNumber) {
        const controller = new AbortController();
        const timeoutId = setTimeout(() => controller.abort(), 1800);

        const payload = {
            commandUsed: cmd.commandRef,
            functionName: cmd.functionName,
            codeLine: cmd.text,
            attemptNumber: attemptNumber || this.attemptNumber,
            activeProfile: this.activeProfile,
            miniGame: this.miniGame,
        };

        try {
            const timResponse = await this.timAIService.sendToTimAI(payload);
            console.log('[GameEngine] Tim AI response:', timResponse.mode);

            if (this.executionLock.isLocked()) {
                this.setReplyText(timResponse.reply);
                this.eventBus.emit('ai_response_received', { 
                    reply: timResponse.reply, 
                    mode: timResponse.mode, 
                    status: timResponse.status 
                });
            }

            return { success: timResponse.status === 'success', data: timResponse };
        } catch (error) {
            console.error('[GameEngine] Tim AI error:', error.message);
            if (this.executionLock.isLocked()) {
                this.setReplyText('Tim is learning! Let me help with that.', true);
                this.eventBus.emit('ai_response_received', { 
                    reply: 'fallback', 
                    mode: 'fallback', 
                    status: 'error' 
                });
            }
            return { success: false, error };
        } finally {
            clearTimeout(timeoutId);
        }
    }

    // ==========================================
    // EVENT HELPERS
    // ==========================================
    emitGameEvent(name, detail) {
        this.gameEvents.emit(name, detail);
    }

    updateCollectibleCounter() {
        if (this.collectibleCounterText) {
            this.collectibleCounterText.setText(`Tools collected: ${this.collectibleCount}`);
        }
    }

    setReplyText(text, instant = false) {
        if (this.typewriterTimer) {
            this.typewriterTimer.remove(false);
            this.typewriterTimer = null;
        }

        if (instant) {
            this.replyText.setText(text);
            return;
        }

        this.replyText.setText('');
        let index = 0;
        this.typewriterTimer = this.time.addEvent({
            delay: 20,
            repeat: Math.max(text.length - 1, 0),
            callback: () => {
                this.replyText.setText(this.replyText.text + text[index]);
                index += 1;
            }
        });
    }
}

// ------------------------------------------
// PHASER BOOTSTRAP
// ------------------------------------------
const config = { type: Phaser.AUTO, width: 800, height: 600, parent: 'game-container', backgroundColor: '#1e1e1e', scene: [BootScene] };
const game = new Phaser.Game(config);
window.game = game;
