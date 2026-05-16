export default class CommandPaletteUI {
  constructor(scene) {
    this.scene = scene;
    this.commands = [
      { id: 'cmd-go', label: 'GO', functionName: 'robotGoForward()' },
      { id: 'cmd-jump', label: 'JUMP', functionName: 'robotJump()' },
      { id: 'cmd-fix', label: 'FIX', functionName: 'robotFix()' },
    ];
    this.tiles = [];
    this.originX = 20;
    this.originY = 380;
    this.tileWidth = 120;
    this.tileHeight = 50;
    this.spacing = 16;
  }

  render() {
    if (this.tiles.length > 0) {
      return;
    }

    this.scene.add.text(this.originX, this.originY - 30, 'COMMAND PALETTE', {
      fontSize: '16px', fill: '#cccccc', fontFamily: 'monospace'
    });

    this.commands.forEach((command, index) => {
      const x = this.originX;
      const y = this.originY + index * (this.tileHeight + this.spacing);
      const container = this.createTile(command, x, y);
      this.tiles.push(container);
    });
  }

  createTile(command, x, y) {
    const background = this.scene.add.rectangle(0, 0, this.tileWidth, this.tileHeight, 0x2a2a2a).setOrigin(0);
    const label = this.scene.add.text(12, 12, command.label, {
      fontSize: '18px', fill: '#ffffff', fontFamily: 'monospace'
    });

    const tileContainer = this.scene.add.container(x, y, [background, label]);
    tileContainer.setSize(this.tileWidth, this.tileHeight);
    tileContainer.setInteractive(new Phaser.Geom.Rectangle(0, 0, this.tileWidth, this.tileHeight), Phaser.Geom.Rectangle.Contains);
    tileContainer.setData('tileData', command);
    tileContainer.setData('origin', { x, y });
    tileContainer.setData('commandId', command.id);
    this.scene.input.setDraggable(tileContainer);

    return tileContainer;
  }

  getTiles() {
    return this.tiles;
  }
}
