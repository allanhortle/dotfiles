function notAlacritty() {
    const window = Window.focused();
    return window && window.app().name() !== 'Alacritty';
}

Key.on('escape', ['option'], () => {
    const app = App.get('Alacritty');
    if (app) app.isActive() ? app.hide() : app.focus();
});

Key.on('`', ['option'], () => {
    const app = App.get('Alacritty');
    if (app) app.isActive() ? app.hide() : app.focus();
});

// Maximise
Key.on('space', ['command', 'option'], () => {
    const frame = Screen.main().visibleFrame();
    const window = Window.focused();
    if (notAlacritty) window.maximise();
});

// Right Half
Key.on('right', ['command', 'option'], () => {
    const screen = Screen.main().flippedVisibleFrame();
    const window = Window.focused();

    if (notAlacritty) {
        window.setSize({width: screen.width / 2, height: screen.height});
        window.setTopLeft({x: screen.x + screen.width / 2, y: 0});
    }
});

// Left Half
Key.on('left', ['command', 'option'], () => {
    const screen = Screen.main().flippedVisibleFrame();
    const window = Window.focused();

    if (notAlacritty) {
        window.setSize({width: screen.width / 2, height: screen.height});
        window.setTopLeft({x: 0, y: 0});
    }
});
