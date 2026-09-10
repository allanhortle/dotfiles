function bindApp(name, key) {
  Key.on(key, ["option"], () => {
    const app = App.get(name);
    if (app) app.isActive() ? app.hide() : app.focus();
  });
}

bindApp("Ghostty", "escape");
bindApp("Ghostty", "`");

// Maximise
Key.on("space", ["command", "option"], () => {
  const frame = Screen.main().visibleFrame();
  const window = Window.focused();
  window.maximise();
});

// Right Half
Key.on("right", ["command", "option"], () => {
  const screen = Screen.main().flippedVisibleFrame();
  const window = Window.focused();

  window.setSize({ width: screen.width / 2, height: screen.height });
  window.setTopLeft({ x: screen.x + screen.width / 2, y: 0 });
});

// Left Half
Key.on("left", ["command", "option"], () => {
  const screen = Screen.main().flippedVisibleFrame();
  const window = Window.focused();

  window.setSize({ width: screen.width / 2, height: screen.height });
  window.setTopLeft({ x: 0, y: 0 });
});

//
// Chrome finder
//
// Ctrl-P over Chrome opens the fuzzy finder for tabs, bookmarks and history in
// a small centred Ghostty window that closes as soon as something is picked.
// The key is only bound while Chrome is at the front, so ctrl-p keeps working
// everywhere else.

const CHROME = 'Google Chrome';
const FINDER_TITLE = 'chrome-fzf';

// Ghostty is told where to open the window, rather than being left to place it
// and having it move afterwards. That needs the size in pixels, which depends
// on the font, so the size is measured the first time the window is seen and
// remembered for every launch after. The estimate below only has to be close
// enough that the very first window does not visibly jump.
const FINDER_SIZE = {width: 'chromeFinderWidth', height: 'chromeFinderHeight'};
const FINDER_ESTIMATE = {width: 860, height: 540};

function finderSize() {
  return {
    width: Storage.get(FINDER_SIZE.width) || FINDER_ESTIMATE.width,
    height: Storage.get(FINDER_SIZE.height) || FINDER_ESTIMATE.height,
  };
}

// Run through a shell so $HOME does not have to be spelled out here. `open -n`
// starts a second Ghostty instance, which is what lets the popup config
// override the fullscreen main one, and the popup config is loaded on its own
// so that the main config it pulls in is not read twice. Ghostty counts the
// position from the top left of the screen's visible area, so these are
// offsets within it rather than coordinates on the screen.
function finderCommand() {
  const screen = Screen.main().flippedVisibleFrame();
  const size = finderSize();

  return [
    'open -na Ghostty --args',
    '--config-default-files=false',
    '--config-file="$HOME/.config/ghostty/popup"',
    `--window-position-x=${Math.round((screen.width - size.width) / 2)}`,
    `--window-position-y=${Math.round((screen.height - size.height) / 2)}`,
  ].join(' ');
}

// Centre the window once it is up, both to correct the guess above and to
// handle a screen the position could not account for. It belongs to a process
// that is still starting, so the first attempts usually find nothing.
function centreFinder(attempt) {
  const window = Window.all({visible: true}).find(
    (candidate) => candidate.app().name() === 'Ghostty' && candidate.title().includes(FINDER_TITLE),
  );

  if (!window) {
    if (attempt < 40) Timer.after(0.1, () => centreFinder(attempt + 1));
    return;
  }

  const screen = Screen.main().flippedVisibleFrame();
  const frame = window.frame();

  Storage.set(FINDER_SIZE.width, frame.width);
  Storage.set(FINDER_SIZE.height, frame.height);

  window.setTopLeft({
    x: Math.round(screen.x + (screen.width - frame.width) / 2),
    y: Math.round(screen.y + (screen.height - frame.height) / 2),
  });
  window.focus();
}

const chromeFinder = new Key('p', ['ctrl'], () => {
  Task.run('/bin/sh', ['-c', finderCommand()], () => centreFinder(0));
});

function syncChromeFinder() {
  const app = App.focused();

  if (app && app.name() === CHROME) {
    chromeFinder.enable();
  } else {
    chromeFinder.disable();
  }
}

['appDidActivate', 'appDidTerminate', 'appDidHide', 'windowDidFocus'].forEach((event) =>
  Event.on(event, syncChromeFinder),
);

syncChromeFinder();
