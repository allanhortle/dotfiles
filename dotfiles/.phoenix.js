Key.on('escape', ['option'], () => {
    const app = App.get('Alacritty');
    if (app) app.isActive() ? app.hide() : app.focus();
});

Key.on('space', ['control'], () => {
    const screenFrame = Screen.main().flippedVisibleFrame();
    const modal = new Modal();
    modal.isInput = true;
    modal.appearance = 'dark';
    modal.origin = {
        x: screenFrame.width / 2 - modal.frame().width / 2,
        y: screenFrame.height / 2 - modal.frame().height / 2
    };
    modal.textDidChange = (value) => {
        //console.log('Text did change:', value);
    };
    modal.show();

    Key.once('escape', [], (e) => modal.close());
});
