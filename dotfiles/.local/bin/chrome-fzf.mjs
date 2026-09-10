// Chrome tabs, bookmarks and history in one fuzzy finder, ranked by how well
// they match with a nudge in favour of tabs, then bookmarks.
//
//   chrome.fzf                    open the finder
//   chrome.fzf --once             the same, but opening an entry closes it
//   chrome.fzf --list             write every record to stdout
//   chrome.fzf --cache [GROUP…]   rebuild cached records; used by the finder
//   chrome.fzf --rank QUERY       order the records; used by the finder
//
// macOS only: the tab list, and focusing and closing a tab, all go through
// Chrome's own AppleScript.

import { DatabaseSync } from "node:sqlite";
import { execFileSync, spawn, spawnSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";

// The finder re-invokes itself for every keystroke, through the wrapper that
// adds node's flag for node:sqlite.
const SELF = path.join(import.meta.dirname, "chrome.fzf");
const TABS_SCRIPT = path.join(import.meta.dirname, "chrome-fzf-tabs.scpt");
const TAB_SCRIPT = path.join(import.meta.dirname, "chrome-fzf-tab.scpt");

// Chrome keeps one directory per profile, each with its own History and
// Bookmarks file.
const CHROME_PATH = path.join(
  os.homedir(),
  "Library/Application Support/Google/Chrome",
);
const CACHE_PATH = path.join(
  process.env.XDG_CACHE_HOME ?? path.join(os.homedir(), ".cache"),
  "chrome-fzf",
);

// A record is one NUL terminated run of BEL separated fields: plain label,
// plain URL, tab id, coloured label, coloured URL. fzf matches the first two
// and displays the last two.
const RS = "\0";
const DELIMITER = "\x07";

// Cache order, which is also the order fzf sees, so an earlier group wins a
// tie under --scheme history.
const GROUPS = ["tabs", "bookmarks", "history"];

// Longest list handed to fzf, and the most records the ranker reads to build
// it. A fuzzy query can match most of the history and nobody scrolls that far,
// so the rest goes unread.
const LIMIT = 500;
const READ_LIMIT = 3000;

// How many places a match climbs for being a tab or a bookmark. Kept small on
// purpose: it lifts a tab above an equally good history entry without burying
// an exact history match under a loose fuzzy one.
const BIAS = { tabs: 40, bookmarks: 20, history: 0 };

// Badges are plain words, so they can be typed to narrow the list to one
// group, and exactly four characters wide, because the ranker reads them back
// off the front of a record to tell which group it came from.
const BADGES = { tabs: "tab ", bookmarks: "mark", history: "hist", search: "web " };
const GROUP_BY_BADGE = Object.fromEntries(
  GROUPS.map((group) => [BADGES[group], group]),
);

const BADGE_COLOURS = { tabs: 36, bookmarks: 35, history: 32, search: 33 };
const TIME_COLOUR = 33;
const URL_COLOUR = "34;2";

// A query that opens with a slash searches the web rather than filtering the
// list, which becomes the single row that runs the search. That row carries
// the search URL in the field enter opens, so searching needs no binding of
// its own.
const SEARCH_PREFIX = "/";
const SEARCH_URL = "https://www.google.com/search?q=";

// Chrome counts microseconds since 1601, the rest of the world seconds since
// 1970.
const EPOCH_OFFSET = 11_644_473_600;

const colour = (code, text) => `\x1b[${code}m${text}\x1b[0m`;
const plain = (text) => text.replaceAll(/\x1b\[[0-9;]*m/g, "");
const toUnix = (microseconds) =>
  Math.trunc(microseconds / 1_000_000) - EPOCH_OFFSET;

function timestamp(seconds) {
  const time = new Date(seconds * 1000);
  const pad = (part) => String(part).padStart(2, "0");

  return (
    `${time.getFullYear()}-${pad(time.getMonth() + 1)}-${pad(time.getDate())} ` +
    `${pad(time.getHours())}:${pad(time.getMinutes())}:${pad(time.getSeconds())}`
  );
}

function record(group, { title = "", url, time, id = "" }) {
  const label = [
    colour(BADGE_COLOURS[group], BADGES[group]),
    title.trim(),
    time ? `(${colour(TIME_COLOUR, timestamp(time))})` : null,
  ]
    .filter(Boolean)
    .join(" ");

  return (
    [plain(label), url, id, label, colour(URL_COLOUR, url)].join(DELIMITER) + RS
  );
}

//
// Where the records come from
//

function profileFiles(name) {
  return fs
    .readdirSync(CHROME_PATH, { withFileTypes: true })
    .filter((entry) => entry.isDirectory())
    .map((entry) => path.join(CHROME_PATH, entry.name, name))
    .filter((file) => fs.existsSync(file));
}

function tabs() {
  return execFileSync("osascript", [TABS_SCRIPT], { encoding: "utf8" })
    .split("\x1e")
    .map((tab) => tab.split("\x1f"))
    .filter(([, , url]) => url)
    .map(([id, title, url]) => ({ id, title, url }));
}

function bookmarks() {
  const walk = (parent, node) => {
    const name = [parent, node.name].filter(Boolean).join("/");

    if (node.type === "folder") {
      return (node.children ?? []).flatMap((child) => walk(name, child));
    }

    // Both dates are Chrome's microseconds, held as strings.
    const time = Math.max(
      Number(node.date_last_used ?? 0),
      Number(node.date_added ?? 0),
    );

    return [{ title: name, url: node.url, time: toUnix(time) }];
  };

  return profileFiles("Bookmarks").flatMap((file) =>
    Object.values(JSON.parse(fs.readFileSync(file, "utf8")).roots ?? {})
      .filter((root) => root?.type === "folder")
      .flatMap((root) => walk(null, root)),
  );
}

function history() {
  return profileFiles("History").flatMap((file) => {
    // Chrome holds the database open, so read a copy of it.
    const directory = fs.mkdtempSync(path.join(os.tmpdir(), "chrome-fzf-"));
    const copy = path.join(directory, "History");

    try {
      fs.copyFileSync(file, copy);

      const database = new DatabaseSync(copy, { readOnly: true });
      // SQLite does the epoch arithmetic because the raw value is a
      // larger integer than JavaScript can hold.
      const rows = database
        .prepare(
          `select title, url, last_visit_time / 1000000 - ${EPOCH_OFFSET} as time
					 from urls order by last_visit_time desc`,
        )
        .all();

      database.close();

      return rows;
    } finally {
      fs.rmSync(directory, { recursive: true, force: true });
    }
  });
}

const SOURCES = { tabs, bookmarks, history };

//
// The cache the finder reads
//

const groupPath = (group) =>
  path.join(CACHE_PATH, `${GROUPS.indexOf(group) + 1}-${group}`);

// Written under a dotted name and renamed into place, so a rebuild running
// alongside the finder can never hand the ranker half a file.
function write(file, content) {
  const temp = path.join(
    path.dirname(file),
    `.${path.basename(file)}.${process.pid}`,
  );

  fs.writeFileSync(temp, content);
  fs.renameSync(temp, file);
}

function cache(groups = GROUPS) {
  fs.mkdirSync(CACHE_PATH, { recursive: true });

  for (const group of groups) {
    // Newest first. Sorting is stable, so tabs, which carry no timestamp,
    // keep the order Chrome listed them in.
    const records = SOURCES[group]()
      .sort((left, right) => (right.time ?? 0) - (left.time ?? 0))
      .map((row) => record(group, row));

    write(groupPath(group), records.join(""));
  }
}

// Rebuild the slow groups for the next run while this one is on screen. Its
// own process group keeps it clear of the signals the terminal sends its
// foreground processes when the window closes.
function refreshLater() {
  const slow = GROUPS.filter((group) => group !== "tabs");

  spawn(SELF, ["--cache", ...slow], {
    detached: true,
    stdio: "ignore",
  }).unref();
}

//
// Ranking, which fzf reloads on every keystroke
//

// fzf's own matcher, run over the records here rather than inside the finder,
// so that the order below can overrule its ranking. Matching is limited to the
// plain fields because the display fields carry ANSI codes, and --ansi has to
// stay off for the same reason: it would strip those codes from the output.
function match(input, query) {
  const { stdout } = spawnSync(
    "fzf",
    [
      "--read0",
      "--print0",
      `--delimiter=${DELIMITER}`,
      "--nth=1,2",
      "--scheme",
      "history",
      `--filter=${query}`,
    ],
    { input, maxBuffer: 1 << 28 },
  );

  return stdout ?? Buffer.alloc(0);
}

// A URL an earlier group already showed is dropped, tabs and bookmarks climb
// their BIAS in places, and the list is cut to LIMIT. Every tab is kept, even
// two on the same URL, since those are the rows that focus something already
// open.
function order(matched) {
  const rows = [];

  for (const row of matched.toString("utf8").split(RS)) {
    if (rows.length >= READ_LIMIT) break;
    if (!row) continue;

    const group = GROUP_BY_BADGE[row.slice(0, 4)];

    rows.push({
      group: group ? GROUPS.indexOf(group) : GROUPS.length,
      place: rows.length,
      url: row.split(DELIMITER)[1] ?? "",
      score: rows.length - (group ? BIAS[group] : 0),
      row,
    });
  }

  const seen = new Set();
  const kept = rows
    .toSorted(
      (left, right) => left.group - right.group || left.place - right.place,
    )
    .filter(({ group, url }) => {
      const repeat = group > 0 && seen.has(url);

      seen.add(url);

      return !repeat;
    });

  return kept
    .toSorted(
      (left, right) => left.score - right.score || left.place - right.place,
    )
    .slice(0, LIMIT)
    .map(({ row }) => row + RS)
    .join("");
}

function search(query) {
  const terms = query.slice(SEARCH_PREFIX.length).trim();

  if (!terms) return "";

  return record("search", {
    title: terms,
    url: SEARCH_URL + encodeURIComponent(terms),
  });
}

function rank(query) {
  if (query.startsWith(SEARCH_PREFIX)) {
    process.stdout.write(search(query));
    return;
  }

  // fzf kills a reload that is still running when the next keystroke lands,
  // so pausing first keeps the work off fast typing.
  if (query) Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, 50);

  const records = Buffer.concat(
    GROUPS.map((group) =>
      fs.existsSync(groupPath(group))
        ? fs.readFileSync(groupPath(group))
        : Buffer.alloc(0),
    ),
  );

  process.stdout.write(order(query ? match(records, query) : records));
}

//
// The finder itself
//

// Matching is delegated to --rank, so fzf's own matcher is --disabled; the
// cost is that matched characters are not highlighted. Paths go in double
// quotes because the bindings themselves are single quoted.
function command({ once }) {
  const ranked = `"${SELF}" --rank {q}`;
  // ctrl-w echoes its reload as a string, so its copy needs the quotes kept.
  const quoted = ranked.replaceAll('"', '\\"');

  return `
		fzf --ansi --read0 --multi --disabled --info inline-right --reverse \\
		    --highlight-line --height 100% --wrap word --wrap-sign '' \\
		    --delimiter "${DELIMITER}" \\
		    --with-shell 'bash -c' \\
		    --with-nth "{4}\n{5}" \\
		    --bind 'enter:execute-silent(
		              if [[ {3} ]]; then
		                osascript "${TAB_SCRIPT}" activate {3}
		              else
		                open {+2}
		              fi)+${once ? "abort" : "deselect-all"}' \\
		    --bind 'ctrl-y:execute-silent(echo -n {+2} | pbcopy)+bell+deselect-all' \\
		    --bind 'ctrl-w:transform:
		            [[ {3} ]] || { echo unix-word-rubout; exit; }
		            osascript "${TAB_SCRIPT}" close {3}
		            "${SELF}" --cache tabs
		            echo "reload:${quoted}"
		    ' \\
		    --bind 'ctrl-r:reload:"${SELF}" --cache; ${ranked}' \\
		    --bind 'start:reload:${ranked}' \\
		    --bind 'change:first+reload:${ranked}'
	`
    .replaceAll(/^\t\t/gm, "")
    .trim();
}

function run({ once }) {
  fs.mkdirSync(CACHE_PATH, { recursive: true });

  const missing = GROUPS.filter((group) => !fs.existsSync(groupPath(group)));

  // A warm cache opens the finder straight away, so the slow groups are only
  // built here on the very first run. Freshening them in the background while
  // the finder is up keeps the next run just as quick.
  if (missing.length === 0) refreshLater();
  cache([...new Set([...missing, "tabs"])]);

  // The records come from the start binding above, not from stdin.
  spawnSync("/bin/sh", ["-c", `${command({ once })} < /dev/null`], {
    stdio: "inherit",
  });
}

const [option, ...rest] = process.argv.slice(2);

switch (option) {
  case undefined:
  case "--once":
    run({ once: option === "--once" });
    break;

  case "--list":
    cache();
    for (const group of GROUPS)
      process.stdout.write(fs.readFileSync(groupPath(group)));
    break;

  case "--cache":
    cache(
      rest.length > 0 ? rest.filter((group) => GROUPS.includes(group)) : GROUPS,
    );
    break;

  case "--rank":
    rank(rest[0] ?? "");
    break;

  default:
    console.error(
      "Usage: chrome.fzf [--once|--list|--cache [GROUP…]|--rank QUERY]",
    );
    process.exit(1);
}
