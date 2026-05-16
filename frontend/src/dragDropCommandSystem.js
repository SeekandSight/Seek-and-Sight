export default class DragDropCommandSystem {
  constructor(scene, eventBus, paletteUI, dropZoneHandler) {
    this.scene = scene;
    this.eventBus = eventBus;
    this.paletteUI = paletteUI;
    this.dropZoneHandler = dropZoneHandler;
  }

  initDragSystem() {
    this.paletteUI.render();
    this.dropZoneHandler.init();

    this.scene.input.on('dragstart', (pointer, gameObject) => this.onDragStart(pointer, gameObject));
    this.scene.input.on('drag', (pointer, gameObject, dragX, dragY) => this.onDrag(pointer, gameObject, dragX, dragY));
    this.scene.input.on('drop', (pointer, gameObject, dropZone) => this.onDrop(pointer, gameObject, dropZone));
    this.scene.input.on('dragend', (pointer, gameObject, dropped) => this.onDragEnd(pointer, gameObject, dropped));

    this.dropZoneHandler.onDrop((tileData, gameObject) => this.onDropSuccess(tileData, gameObject));
  }

  onDragStart(pointer, gameObject) {
    const tileData = gameObject.getData('tileData');
    if (!tileData) return;

    // Only depth and scale are used — both work on Containers and Sprites.
    // setTint/clearTint are intentionally NOT called here: they crash on Containers.
    gameObject.setDepth(1000);
    gameObject.setScale(1.05);
    this.dropZoneHandler.highlight(true);
  }

  onDrag(pointer, gameObject, dragX, dragY) {
    gameObject.x = dragX;
    gameObject.y = dragY;
  }

  onDrop(pointer, gameObject, dropZone) {
    if (this.dropZoneHandler.isValidDropZone(dropZone)) {
      this.dropZoneHandler.acceptDrop(gameObject);
      return;
    }
    this.dropZoneHandler.rejectDrop(gameObject);
  }

  onDragEnd(pointer, gameObject, dropped) {
    // Reset visual state — no tint calls, safe for all Phaser object types.
    gameObject.setScale(1);
    gameObject.setDepth(0);
    this.dropZoneHandler.highlight(false);

    if (!dropped) {
      this.returnTileToOrigin(gameObject);
    }
  }

  onDropSuccess(tileData, gameObject) {
    const command = this.createCommandFromTile(tileData);
    this.eventBus.emit('command:added', command);
    this.returnTileToOrigin(gameObject);
  }

  createCommandFromTile(tileData) {
    const normalizedFunctionName = this.normalizeFunctionName(tileData.functionName);
    const normalizedCodeLine = this.normalizeCodeLine(tileData.functionName);
    return {
      commandUsed: tileData.label,
      functionName: normalizedFunctionName,
      codeLine: normalizedCodeLine,
    };
  }

  normalizeFunctionName(functionName) {
    return functionName.replace(/\(\)$/, '');
  }

  normalizeCodeLine(functionName) {
    if (functionName.endsWith('()')) {
      return `${functionName};`;
    }
    return `${functionName}();`;
  }

  returnTileToOrigin(gameObject) {
    const origin = gameObject.getData('origin');
    if (!origin) return;

    this.scene.tweens.add({
      targets: gameObject,
      x: origin.x,
      y: origin.y,
      duration: 250,
      ease: 'Power2',
    });
  }
}
