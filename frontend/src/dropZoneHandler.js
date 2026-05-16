export default class DropZoneHandler {
  constructor(scene, x = 260, y = 420, width = 520, height = 160) {
    this.scene = scene;
    this.x = x;
    this.y = y;
    this.width = width;
    this.height = height;
    this.dropCallbacks = [];
    this.active = false;
  }

  init() {
    this.dropZone = this.scene.add.zone(this.x, this.y, this.width, this.height).setRectangleDropZone(this.width, this.height);
    this.dropZone.setData('accepted', true);

    this.zoneBackground = this.scene.add.rectangle(this.x, this.y, this.width, this.height, 0x1b1b1b, 0.65);
    this.zoneBackground.setStrokeStyle(2, 0x999999);
    this.dropZoneText = this.scene.add.text(this.x - this.width / 2 + 10, this.y - 14, 'Drag commands here to build code', {
      fontSize: '14px', fill: '#eeeeee', fontFamily: 'monospace'
    });

    this.scene.input.on('dragenter', (pointer, gameObject, dropZone) => this.handleDragEnter(dropZone));
    this.scene.input.on('dragleave', (pointer, gameObject, dropZone) => this.handleDragLeave(dropZone));
    this.scene.input.on('drop', (pointer, gameObject, dropZone) => this.handleDrop(pointer, gameObject, dropZone));
  }

  onDrop(callback) {
    this.dropCallbacks.push(callback);
  }

  handleDragEnter(dropZone) {
    if (this.isValidDropZone(dropZone)) {
      this.highlight(true);
    }
  }

  handleDragLeave(dropZone) {
    if (this.isValidDropZone(dropZone)) {
      this.highlight(false);
    }
  }

  handleDrop(pointer, gameObject, dropZone) {
    if (!this.isValidDropZone(dropZone)) {
      return;
    }

    const tileData = gameObject.getData('tileData');
    if (!tileData) {
      return;
    }

    this.dropCallbacks.forEach((callback) => callback(tileData, gameObject));
    this.highlight(false);
  }

  highlight(active) {
    this.active = active;
    const color = active ? 0x48c774 : 0x1b1b1b;
    const alpha = active ? 0.9 : 0.65;
    this.zoneBackground.setFillStyle(color, alpha);
    this.zoneBackground.setStrokeStyle(2, active ? 0xffffff : 0x999999);
  }

  isValidDropZone(dropZone) {
    return dropZone === this.dropZone;
  }

  // acceptDrop: only scale reset — NO tint calls (Containers crash on setTint/clearTint)
  acceptDrop(gameObject) {
    gameObject.setScale(1);
  }

  // rejectDrop: only scale reset + return to origin — NO tint calls
  rejectDrop(gameObject) {
    gameObject.setScale(1);
    const origin = gameObject.getData('origin');
    if (!origin) {
      return;
    }
    this.scene.tweens.add({
      targets: gameObject,
      x: origin.x,
      y: origin.y,
      duration: 250,
      ease: 'Power2',
    });
  }
}
