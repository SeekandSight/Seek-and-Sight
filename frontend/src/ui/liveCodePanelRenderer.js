const STATUS_COLORS = {
  pending: '#ffffff',
  active: '#5ad3ff',
  success: '#7cff7c',
  error: '#ff7676',
};

const STATUS_BG_COLORS = {
  pending: 0x1a1a1a,
  active: 0x1a3a4a,
  success: 0x1a3a1a,
  error: 0x4a1a1a,
};

export default class LiveCodePanelRenderer {
  constructor(scene, x = 560, y = 40, width = 240, height = 350) {
    this.scene = scene;
    this.panelX = x;
    this.panelY = y;
    this.width = width;
    this.height = height;
    this.originX = x;
    this.originY = y + 30;
    this.lineHeight = 28;
    this.lines = [];
    this.backgrounds = [];
    this.activeLineIndex = -1;

    this.scene.add.rectangle(x + width / 2, y + height / 2, width, height, 0x111111).setStrokeStyle(2, 0x444444);
    this.scene.add.text(x - 110, y - 10, 'LIVE CODE', { fontSize: '16px', fill: '#888888', fontFamily: 'monospace' });
  }

  render(lines) {
    this.clear();

    if (!lines || lines.length === 0) {
      this.lines.push(
        this.scene.add.text(this.originX, this.originY, '// No code yet', {
          fontSize: '14px', fill: '#555555', fontFamily: 'monospace', wordWrap: { width: 220 }
        })
      );
      return;
    }

    let activeIndex = -1;
    lines.forEach((line, index) => {
      if (line.status === 'active') {
        activeIndex = index;
      }
    });

    lines.forEach((line, index) => {
      const yPos = this.originY + index * this.lineHeight;
      const color = STATUS_COLORS[line.status] || STATUS_COLORS.pending;
      const bgColor = STATUS_BG_COLORS[line.status] || STATUS_BG_COLORS.pending;

      const background = this.scene.add.rectangle(
        this.originX + 5,
        yPos + 5,
        this.width - 20,
        this.lineHeight - 4,
        bgColor
      );
      background.setOrigin(0);
      background.setDepth(-1);
      this.backgrounds.push(background);

      const pointer = line.status === 'active' ? '▶ ' : '  ';
      const lineNumber = String(line.index).padStart(2, ' ');
      const lineText = `${pointer}${lineNumber}. ${line.commandRef} → ${line.text}`;

      const textObj = this.scene.add.text(this.originX + 8, yPos + 2, lineText, {
        fontSize: '14px', fill: color, fontFamily: 'monospace', wordWrap: { width: 210 }
      });

      if (line.status === 'active') {
        textObj.setStyle({ fontStyle: 'italic' });
      }

      if (line.status === 'error') {
        this.triggerShakeAnimation(background, textObj);
      }

      if (line.status === 'success') {
        this.triggerSuccessAnimation(background);
      }

      this.lines.push(textObj);
    });

    if (activeIndex >= 0) {
      this.scrollToActiveLine(activeIndex);
    }
  }

  triggerShakeAnimation(background, textObj) {
    const originalX = background.x;
    this.scene.tweens.add({
      targets: [background, textObj],
      x: { from: originalX, to: originalX - 3 },
      duration: 50,
      yoyo: true,
      repeat: 3,
      ease: 'Linear',
    });
  }

  triggerSuccessAnimation(background) {
    this.scene.tweens.add({
      targets: background,
      alpha: 0.2,
      duration: 1500,
      ease: 'Linear',
    });
  }

  scrollToActiveLine(activeIndex) {
    const maxVisibleLines = Math.floor(this.height / this.lineHeight);
    if (activeIndex >= maxVisibleLines) {
      const scrollOffset = (activeIndex - maxVisibleLines + 1) * this.lineHeight;
      this.lines.forEach((line) => {
        if (line) {
          line.y -= scrollOffset;
        }
      });
      this.backgrounds.forEach((bg) => {
        if (bg) {
          bg.y -= scrollOffset;
        }
      });
    }
  }

  clear() {
    this.lines.forEach((object) => {
      if (object) {
        object.destroy();
      }
    });
    this.lines = [];

    this.backgrounds.forEach((bg) => {
      if (bg) {
        bg.destroy();
      }
    });
    this.backgrounds = [];
  }
}
