#!/usr/bin/env zx
// vim: set ft=javascript :
$.verbose = false; // don't echo the gh/tmux/git commands we run
// verbose only governs the echo: without this, a git that fails in a worktree
// which has since been deleted still forwards its complaint to our stderr, and
// the daemon's log is that stderr.
$.quiet = true;

import os from "node:os";
import { spawn } from "node:child_process";
import { fileURLToPath } from "node:url";

const HOME = os.homedir();
const STATE_DIR = path.join(HOME, ".cache", "prstatus");
const STATE_FILE = path.join(STATE_DIR, "state.json");
const PID_FILE = path.join(STATE_DIR, "daemon.pid");
const LOG_FILE = path.join(STATE_DIR, "daemon.log");

// The letter, and the pull request number behind it. tmux only honours a
// #[range=] marker written literally in the format option, but it will expand a
// format inside the marker's argument, so the number rides in its own option
// and .tmux.conf turns the letter into a clickable range.
const LETTER_OPTION = "@pr";
const NUMBER_OPTION = "@prnum";
// How many pull requests are waiting on me to review them. Server-scoped rather
// than per window, because unlike the letter it belongs to no one worktree;
// .tmux.conf renders it in status-right. A bare number, with no styling: a
// letter's colour is data and so has to be written here, whereas this is always
// the same colour, which makes it presentation and the config's business.
const REVIEW_OPTION = "@prreview";
// The name .tmux.conf gives the count's click range, and so what arrives as the
// argument to `open` when it is clicked. A letter's range carries a pull request
// number, so a word cannot collide with one.
const REVIEW_TARGET = "reviews";
// Bump whenever a stored record changes shape, so an old cache is discarded
// rather than rendered with fields the current code no longer sets.
const STATE_VERSION = 5;

// A 304 on /notifications costs no rate limit, so the heartbeat can run at
// GitHub's own advertised cadence. The aggregate query costs a point, so it
// only runs when the heartbeat moves or a backstop falls due.
const HEARTBEAT_SECS = 60;
const BACKSTOP_IDLE_SECS = 300;
const BACKSTOP_BUSY_SECS = 30;
const RATE_LIMIT_FLOOR = 200;

// Nothing a cycle waits on is allowed to wait forever. Node's fetch has no
// timeout of its own, and a socket that dies while the laptop is asleep can
// leave its promise pending for good — which wedges the loop in a way nothing
// ever notices, because the log only speaks when something refetched, so a
// wedged daemon and a quiet one read the same. Hence a deadline on every fetch,
// on every command, and one around the whole cycle for whatever that list
// forgot.
const FETCH_TIMEOUT_SECS = 20;
const COMMAND_TIMEOUT_SECS = 20;
const CYCLE_TIMEOUT_SECS = 90;
$.timeout = `${COMMAND_TIMEOUT_SECS}s`;

// How long the loop may go without finishing an iteration before another
// process is entitled to call it wedged and replace it. Comfortably past the
// longest legitimate gap, which is a full backoff sleep plus a cycle deadline.
const STALL_SECS = 600;
const MAX_BACKOFF = 5;

// A sleep that overruns its own deadline by this much was suspended rather than
// slept: the machine went away, and everything on the bar is now arbitrarily
// old.
const WAKE_SLACK_SECS = 60;

// Notifications never report a check going green, a base branch moving, or a
// fresh conflict, which is why the idle backstop above is not optional. A review
// request does arrive here, so the count rides the cheap path on the way up;
// submitting the review does not, so it only falls away on the backstop.
const NOTIFICATIONS_URL = "https://api.github.com/notifications";
const GRAPHQL_URL = "https://api.github.com/graphql";

// Where a click lands: the pull request itself for a letter, and the dashboard
// for the review count, which has no single pull request behind it to open.
const GRAPHITE_URL = "https://app.graphite.com";
const graphitePrUrl = (pr) =>
  `${GRAPHITE_URL}/github/pr/${pr.repo}/${pr.number}`;

const FAIL_STATES = new Set([
  "FAILURE",
  "TIMED_OUT",
  "ACTION_REQUIRED",
  "STARTUP_FAILURE",
  "ERROR",
]);
// CANCELLED is green on purpose. Restacking a graphite branch cancels its
// in-flight runs, and GitHub's own rollup state calls that a FAILURE even
// though no check failed.
const GREEN_STATES = new Set(["SUCCESS", "SKIPPED", "NEUTRAL", "CANCELLED"]);

// Chromatic parks its UI statuses at PENDING once the build is done and a
// person has to act — accept a baseline, or go collect approvals. Nothing is
// running, so counting it as "building" hides it behind whatever genuinely is.
// Matched on the description rather than the context name, because the very
// same context is also, legitimately, PENDING while the build runs. An
// unrecognised description therefore falls through to building, which is the
// safe way round: a check we cannot read stays yellow instead of crying wolf.
const AWAITING_DESCRIPTIONS = [
  /^awaiting \d+ approval/i,
  /must be accepted as baseline/i,
];

// One letter per pull request, and the colour says whose move it is: yellow a
// machine's, blue a reviewer's, red mine, green nobody's, grey nothing to do.
//   G ready   D draft   B building   Q queued   M merged   X closed unmerged
//   W waiting on a reviewer (blue) or on me (red)
//   F failing   C conflict   R changes requested   ? unknown
//
// WAITING_ME covers both a Chromatic baseline parked on my approval and a merge
// GitHub will not let through, because a human being in the way is the whole of
// what the letter has to say — which human does not change what I do next.
const LABELS = {
  READY: ["G", "green"],
  DRAFT: ["D", "colour242"],
  BUILDING: ["B", "yellow"],
  WAITING_REVIEW: ["W", "blue"],
  WAITING_ME: ["W", "red"],
  FAILING: ["F", "red"],
  CONFLICT: ["C", "red"],
  CHANGES_REQUESTED: ["R", "red"],
  QUEUED: ["Q", "yellow"],
  MERGED: ["M", "magenta"],
  CLOSED: ["X", "colour242"],
  UNKNOWN: ["?", "colour242"],
};

// How far back to look for merged and closed pull requests. A worktree usually
// outlives the merge, and its letter is the signal that it can go.
const CLOSED_WINDOW_DAYS = 7;

// Checks and review threads are only asked for on the open side. Requesting
// them for both searches makes GitHub time the whole query out with a 504, and
// a merged or closed pull request renders from its state alone anyway. The
// review-requested side stays light for the same reason: a count needs nothing
// but the count, and issueCount is the true total even when it outruns `first`,
// so the tally cannot silently cap at the page size.
const PR_QUERY = `
  query($qOpen: String!, $qClosed: String!, $qReview: String!) {
    rateLimit { cost remaining }
    open: search(query: $qOpen, type: ISSUE, first: 40) { nodes { ...prFull } }
    closed: search(query: $qClosed, type: ISSUE, first: 30) { nodes { ...prLight } }
    review: search(query: $qReview, type: ISSUE, first: 40) {
      issueCount
      nodes { ...prReview }
    }
  }
  fragment prLight on PullRequest {
    number title url state headRefName baseRefName isDraft
    repository { nameWithOwner }
  }
  fragment prReview on PullRequest {
    ...prLight
    author { login }
  }
  fragment prFull on PullRequest {
    ...prLight
    mergeable mergeStateStatus reviewDecision
    isInMergeQueue mergeQueueEntry { position }
    reviewThreads(first: 100) { nodes { isResolved } }
    commits(last: 1) { nodes { commit { statusCheckRollup {
      state
      contexts(first: 100) { nodes {
        ... on CheckRun {
          name conclusion status startedAt
          checkSuite {
            app { slug }
            workflowRun { databaseId workflow { databaseId } }
          }
        }
        ... on StatusContext { context state description createdAt }
      } }
    } } } }
  }`;

// ---------------------------------------------------------------------------
// state file
// ---------------------------------------------------------------------------

function emptyState() {
  return {
    version: STATE_VERSION,
    updatedAt: null,
    heartbeat: {},
    rateLimit: null,
    prs: {},
    reviews: { count: 0, prs: [] },
    windows: {},
  };
}

function readState() {
  try {
    const state = fs.readJsonSync(STATE_FILE);
    return state?.version === STATE_VERSION ? state : emptyState();
  } catch {
    return emptyState();
  }
}

// Rename so a reader never catches a half-written file.
function writeState(state) {
  fs.ensureDirSync(STATE_DIR);
  const tmp = `${STATE_FILE}.${process.pid}`;
  fs.writeJsonSync(tmp, state, { spaces: 2 });
  fs.renameSync(tmp, STATE_FILE);
}

// ---------------------------------------------------------------------------
// github
// ---------------------------------------------------------------------------

let cachedToken = null;

async function token() {
  if (cachedToken) return cachedToken;
  const out = await $`gh auth token`.nothrow();
  if (out.exitCode !== 0)
    throw new Error("gh auth token failed — run `gh auth login`");
  cachedToken = out.stdout.trim();
  return cachedToken;
}

async function login() {
  const out = await $`gh api user -q .login`.nothrow();
  if (out.exitCode !== 0)
    throw new Error("cannot resolve the current github login");
  return out.stdout.trim();
}

// Returns true when something in the notification feed moved. A 304 is free,
// so this is the cheap half of the poll.
async function heartbeatMoved(state) {
  const headers = {
    Authorization: `Bearer ${await token()}`,
    Accept: "application/vnd.github+json",
  };
  if (state.heartbeat.lastModified)
    headers["If-Modified-Since"] = state.heartbeat.lastModified;

  const res = await fetch(NOTIFICATIONS_URL, {
    headers,
    signal: AbortSignal.timeout(FETCH_TIMEOUT_SECS * 1000),
  });
  await res.text(); // release the socket

  const pollInterval = Number(res.headers.get("x-poll-interval"));
  if (Number.isFinite(pollInterval) && pollInterval > 0)
    state.heartbeat.pollSecs = pollInterval;

  if (res.status === 304) return false;
  if (!res.ok) throw new Error(`notifications: HTTP ${res.status}`);

  state.heartbeat.lastModified =
    res.headers.get("last-modified") ?? state.heartbeat.lastModified;
  return true;
}

async function fetchPrs(author) {
  const since = new Date(Date.now() - CLOSED_WINDOW_DAYS * 86400000)
    .toISOString()
    .slice(0, 10);
  const variables = {
    qOpen: `is:pr is:open author:${author}`,
    qClosed: `is:pr is:closed author:${author} sort:updated-desc updated:>=${since}`,
    // user-review-requested: and not review-requested:, so this only ever counts
    // pull requests that named me. review-requested: also matches anything aimed
    // at a team I am on, which is the team's queue rather than mine — the same
    // line graphite draws between its "Just Me" and "Team review". Drafts are
    // excluded: a draft is not asking yet. Submitting a review drops the pull
    // request out of the search on its own, so the count needs no notion of
    // "done" of its own.
    qReview:
      `is:pr is:open draft:false archived:false ` +
      `user-review-requested:${author} -author:${author} sort:updated-desc`,
  };
  const res = await fetch(GRAPHQL_URL, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${await token()}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ query: PR_QUERY, variables }),
    signal: AbortSignal.timeout(FETCH_TIMEOUT_SECS * 1000),
  });
  if (!res.ok) throw new Error(`graphql: HTTP ${res.status}`);
  const body = await res.json();
  if (body.errors?.length)
    throw new Error(`graphql: ${body.errors[0].message}`);
  return body.data;
}

// ---------------------------------------------------------------------------
// pull request state
// ---------------------------------------------------------------------------

function checkState(context) {
  return context.conclusion ?? context.state ?? context.status ?? null;
}

function needsAPerson(context) {
  const description = context.description ?? "";
  return AWAITING_DESCRIPTIONS.some((pattern) => pattern.test(description));
}

const contextNames = (contexts) =>
  [...new Set(contexts.map((c) => c.name ?? c.context ?? "?"))].sort((a, b) =>
    a.localeCompare(b),
  );

// What a check has to match to count as the same check across attempts. The
// workflow rather than the run, so a re-run lands on the attempt it replaced,
// and the workflow as well as the name, because two workflows legitimately
// publish a check under one name — E2E Tests runs in both the deploy workflow
// and the ephemeral one, and neither supersedes the other. A check posted by an
// app rather than by Actions has no workflow and groups by the app instead.
function attemptKey(context) {
  const name = context.name ?? context.context ?? "?";
  const workflow = context.checkSuite?.workflowRun?.workflow?.databaseId;
  if (workflow != null) return `workflow:${workflow} ${name}`;
  return `app:${context.checkSuite?.app?.slug ?? ""} ${name}`;
}

// Which of two attempts is the later one. Run ids climb, so they order a
// workflow's attempts even while the newest is still queued and carries no
// start time; everything else falls back to when it was posted. Only ever
// compared within one attemptKey, so the two scales never meet.
function attemptOrder(context) {
  const run = context.checkSuite?.workflowRun?.databaseId;
  if (run != null) return run;
  const at = context.startedAt ?? context.createdAt;
  return at ? Date.parse(at) : 0;
}

// A commit's rollup keeps every attempt of a check, so a re-run sits alongside
// the run it replaced and a failure that has since been re-run green still
// counts as a failure. GitHub's own rollup state has the same flaw, which is
// why it is only trusted below when there are no contexts to read.
function latestAttempts(contexts) {
  const newest = new Map();
  for (const context of contexts) {
    const key = attemptKey(context);
    const held = newest.get(key);
    if (!held || attemptOrder(context) >= attemptOrder(held))
      newest.set(key, context);
  }
  return [...newest.values()];
}

function summariseChecks(node) {
  const rollup = node.commits?.nodes?.[0]?.commit?.statusCheckRollup ?? null;
  const contexts = latestAttempts(rollup?.contexts?.nodes ?? []);

  if (contexts.length === 0) {
    // Nothing to classify ourselves, so the rollup state is all we have.
    const state = rollup?.state ?? null;
    return {
      pass: 0,
      fail: FAIL_STATES.has(state) ? 1 : 0,
      pending: state === "PENDING" ? 1 : 0,
      awaiting: 0,
      failing: [],
      awaitingOn: [],
    };
  }

  const failing = contexts.filter((c) => FAIL_STATES.has(checkState(c)));
  const pass = contexts.filter((c) => GREEN_STATES.has(checkState(c))).length;
  // Neither green nor failing: in flight, or parked on a human. Splitting the
  // two is the whole point — pending has to mean "a machine is still working",
  // otherwise the busy backstop below chases a state that will never move.
  const unsettled = contexts.filter(
    (c) => !FAIL_STATES.has(checkState(c)) && !GREEN_STATES.has(checkState(c)),
  );
  const awaiting = unsettled.filter(needsAPerson);
  return {
    pass,
    fail: failing.length,
    pending: unsettled.length - awaiting.length,
    awaiting: awaiting.length,
    failing: contextNames(failing),
    awaitingOn: contextNames(awaiting),
  };
}

// Draftness is deliberately not a status. Every PR here starts as a draft, so
// a DRAFT glyph would hide red CI on most of the bar. It changes how READY
// renders instead, and nothing else.
function deriveStatus(pr) {
  if (pr.state === "MERGED") return "MERGED";
  if (pr.state === "CLOSED") return "CLOSED";
  if (pr.isInMergeQueue) return "QUEUED";
  if (pr.checks.fail > 0) return "FAILING";
  if (pr.mergeable === "CONFLICTING" || pr.mergeStateStatus === "DIRTY")
    return "CONFLICT";
  if (pr.reviewDecision === "CHANGES_REQUESTED") return "CHANGES_REQUESTED";
  // Ahead of BUILDING deliberately. A build clears itself and this does not, so
  // the thing worth showing while both are outstanding is the one wanting me.
  if (pr.checks.awaiting > 0) return "WAITING_ME";
  if (pr.checks.pending > 0) return "BUILDING";

  switch (pr.mergeStateStatus) {
    case "CLEAN":
    case "BEHIND":
    case "HAS_HOOKS":
    case "DRAFT":
    // Nothing is failing or pending by this point, so UNSTABLE can only mean
    // cancelled or neutral runs, which we already count as green.
    case "UNSTABLE":
      return "READY";
    case "BLOCKED":
      if (pr.isDraft) return "READY"; // blocked by its own draftness, not by us
      return pr.reviewDecision === "REVIEW_REQUIRED"
        ? "WAITING_REVIEW"
        : "WAITING_ME";
    default:
      // GitHub computes mergeability lazily and answers UNKNOWN while it works.
      return "UNKNOWN";
  }
}

function normalisePr(node) {
  const checks = summariseChecks(node);
  const threads = node.reviewThreads?.nodes ?? [];
  const pr = {
    number: node.number,
    title: node.title,
    url: node.url,
    state: node.state,
    repo: node.repository.nameWithOwner,
    head: node.headRefName,
    base: node.baseRefName,
    isDraft: node.isDraft,
    mergeable: node.mergeable ?? "UNKNOWN",
    mergeStateStatus: node.mergeStateStatus ?? "UNKNOWN",
    reviewDecision: node.reviewDecision ?? "NONE",
    isInMergeQueue: node.isInMergeQueue,
    queuePosition: node.mergeQueueEntry?.position ?? null,
    unresolved: threads.filter((t) => !t.isResolved).length,
    checks,
  };
  pr.status = deriveStatus(pr);
  return pr;
}

// No status and no letter. Whose move it is has already been answered by the
// pull request landing in the search at all — it is mine — so there is nothing
// left for deriveStatus to say, and the vocabulary in LABELS is about my own
// pull requests anyway.
function normaliseReview(node) {
  return {
    number: node.number,
    title: node.title,
    url: node.url,
    repo: node.repository.nameWithOwner,
    author: node.author?.login ?? null,
    head: node.headRefName,
    base: node.baseRefName,
  };
}

// A graphite stack is the connected component of the base -> head graph that
// contains this branch. Anything based on a branch with no open PR of its own
// (master, or an unpushed base) ends the chain.
function buildStacks(prs) {
  // A branch can carry an old closed pull request as well as a live one, so an
  // open pull request always wins the branch, then the newest number.
  const ranked = [...prs].sort((a, b) => {
    if ((a.state === "OPEN") !== (b.state === "OPEN"))
      return a.state === "OPEN" ? -1 : 1;
    return b.number - a.number;
  });
  const byHead = new Map();
  for (const pr of ranked) {
    const key = `${pr.repo}#${pr.head}`;
    if (!byHead.has(key)) byHead.set(key, pr);
  }
  const parent = new Map(prs.map((pr) => [pr.number, pr.number]));

  const find = (n) =>
    parent.get(n) === n
      ? n
      : (parent.set(n, find(parent.get(n))), parent.get(n));
  const union = (a, b) => parent.set(find(a), find(b));

  for (const pr of prs) {
    const base = byHead.get(`${pr.repo}#${pr.base}`);
    if (base) union(pr.number, base.number);
  }

  const stacks = new Map();
  for (const pr of prs) {
    const root = find(pr.number);
    if (!stacks.has(root)) stacks.set(root, []);
    stacks.get(root).push(pr.number);
  }
  for (const members of stacks.values()) members.sort((a, b) => a - b);

  // Nothing above the bottom can merge until the bottom does, so the bottom is
  // the pull request a window reports on. Following base links rather than
  // taking the lowest number, because a stack is reordered by restacking.
  const bottomOf = (pr) => {
    const seen = new Set([pr.number]);
    let current = pr;
    for (;;) {
      const base = byHead.get(`${current.repo}#${current.base}`);
      if (!base || seen.has(base.number)) return current;
      seen.add(base.number);
      current = base;
    }
  };

  return {
    byHead,
    bottomOf,
    stackOf: (pr) => stacks.get(find(pr.number)) ?? [pr.number],
  };
}

// ---------------------------------------------------------------------------
// tmux and git
// ---------------------------------------------------------------------------

class NoTmuxServer extends Error {}

async function tmux(args) {
  const out = await $`tmux ${args}`.nothrow();
  if (
    out.exitCode !== 0 &&
    /no server running|no such file or directory/i.test(out.stderr)
  ) {
    throw new NoTmuxServer();
  }
  return out;
}

const gitCache = new Map();

async function gitInfo(dir) {
  if (!dir) return null;
  if (gitCache.has(dir)) return gitCache.get(dir);
  const out =
    await $`git -C ${dir} rev-parse --show-toplevel --abbrev-ref HEAD --git-common-dir`.nothrow();
  let info = null;
  if (out.exitCode === 0) {
    const [root, branch, commonDir] = out.stdout.trim().split("\n");
    info = {
      root,
      branch: branch === "HEAD" ? null : branch, // detached, which happens mid-restack
      commonDir: path.resolve(root, commonDir),
    };
  }
  gitCache.set(dir, info);
  return info;
}

const repoCache = new Map();

// One lookup per checkout rather than one per worktree: every worktree of a
// repo shares its common dir, and therefore its remote.
async function repoName(commonDir) {
  if (repoCache.has(commonDir)) return repoCache.get(commonDir);
  const out =
    await $`git --git-dir=${commonDir} config --get remote.origin.url`.nothrow();
  const match =
    out.exitCode === 0
      ? out.stdout.trim().match(/[:/]([^/:]+\/[^/]+?)(?:\.git)?$/)
      : null;
  const name = match?.[1] ?? null;
  repoCache.set(commonDir, name);
  return name;
}

// The active pane defines the window's worktree. If it has wandered somewhere
// without a repo, fall back to any pane in the window that has one.
async function resolveWindows() {
  // Space-separated and parsed from the left: a tab in the format string does
  // not survive shell quoting the same way on every zx build, and a path may
  // legitimately contain spaces.
  const out = await tmux([
    "list-panes",
    "-a",
    "-F",
    "#{window_id} #{pane_active} #{pane_current_path}",
  ]);
  if (out.exitCode !== 0) return new Map();

  const panes = new Map();
  for (const line of out.stdout.trim().split("\n").filter(Boolean)) {
    const [windowId, active, ...rest] = line.split(" ");
    const panePath = rest.join(" ");
    if (!windowId || !panePath) continue;
    if (!panes.has(windowId)) panes.set(windowId, []);
    panes.get(windowId)[active === "1" ? "unshift" : "push"](panePath);
  }

  const windows = new Map();
  for (const [windowId, paths] of panes) {
    for (const panePath of paths) {
      const info = await gitInfo(panePath);
      if (!info?.branch) continue;
      windows.set(windowId, {
        path: info.root,
        branch: info.branch,
        repo: await repoName(info.commonDir),
      });
      break;
    }
  }
  return windows;
}

async function clientAttached() {
  const out = await tmux(["list-clients", "-F", "#{client_name}"]);
  return out.exitCode === 0 && out.stdout.trim().length > 0;
}

// ---------------------------------------------------------------------------
// rendering
// ---------------------------------------------------------------------------

function labelFor(pr) {
  if (pr.status === "READY" && pr.isDraft) return LABELS.DRAFT;
  return LABELS[pr.status] ?? LABELS.UNKNOWN;
}

// Everything here describes the bottom of the stack and nothing else, threads
// included, so the whole indicator has one subject.
function render(bottom) {
  const [letter, colour] = labelFor(bottom);
  let out = `#[fg=${colour}]${letter}`;
  if (bottom.unresolved > 0) out += `#[fg=red]${bottom.unresolved}`;
  return out;
}

// Deliberately not in the state file. A tmux option lives and dies with the
// server, and so does the daemon, so process scope is exactly the right scope:
// a fresh server always gets the count pushed to it once, and an unchanged count
// on a later cycle costs no tmux round trip at all.
let pushedReviews = null;

async function push(rendered, windowIds, reviews) {
  const args = [];
  const add = (...parts) => {
    if (args.length) args.push(";");
    args.push(...parts);
  };

  if (reviews !== pushedReviews) {
    add("set", "-g", REVIEW_OPTION, reviews > 0 ? String(reviews) : "");
    pushedReviews = reviews;
  }

  for (const windowId of windowIds) {
    const entry = rendered.get(windowId);
    if (entry) {
      add("set", "-w", "-t", windowId, LETTER_OPTION, entry.letter);
      add("set", "-w", "-t", windowId, NUMBER_OPTION, String(entry.number));
    } else {
      add("set", "-uw", "-t", windowId, LETTER_OPTION);
      add("set", "-uw", "-t", windowId, NUMBER_OPTION);
    }
  }

  if (args.length === 0) return;
  await tmux(args);
  await tmux(["refresh-client", "-S"]);
}

// ---------------------------------------------------------------------------
// one poll cycle
// ---------------------------------------------------------------------------

async function cycle(state, { force = false } = {}) {
  gitCache.clear();

  const windows = await resolveWindows();
  const windowKey = [...windows.entries()]
    .map(([id, w]) => `${id}:${w.repo}#${w.branch}`)
    .sort()
    .join("|");
  const windowsChanged = windowKey !== state.windowKey;

  const sinceFetch = state.updatedAt
    ? (Date.now() - Date.parse(state.updatedAt)) / 1000
    : Infinity;
  state.busy = Object.values(state.prs).some(
    (pr) => pr.checks.pending > 0 || pr.isInMergeQueue,
  );
  const backstopDue =
    sinceFetch >= (state.busy ? BACKSTOP_BUSY_SECS : BACKSTOP_IDLE_SECS);

  let refetch = force || windowsChanged || backstopDue;
  if (!refetch) refetch = await heartbeatMoved(state);

  if (refetch) {
    if (state.rateLimit && state.rateLimit.remaining < RATE_LIMIT_FLOOR) {
      throw new Error(
        `rate limit floor reached (${state.rateLimit.remaining} left)`,
      );
    }
    const data = await fetchPrs(state.author ?? (state.author = await login()));
    const prs = [...data.open.nodes, ...data.closed.nodes]
      .filter((n) => n?.number)
      .map(normalisePr);
    state.rateLimit = data.rateLimit;
    state.prs = Object.fromEntries(prs.map((pr) => [pr.number, pr]));
    // Its own bucket on purpose, never folded into state.prs, which is keyed by
    // branch downstream in buildStacks and resolveTarget: a colleague's pull
    // request on a branch name I also have checked out would win that key and
    // hang their letter on my tab.
    state.reviews = {
      count: data.review.issueCount,
      prs: data.review.nodes.filter((n) => n?.number).map(normaliseReview),
    };
    state.updatedAt = new Date().toISOString();
  }

  const prs = Object.values(state.prs);
  const { byHead, bottomOf, stackOf } = buildStacks(prs);

  const rendered = new Map();
  state.windows = {};
  for (const [windowId, window] of windows) {
    const pr = byHead.get(`${window.repo}#${window.branch}`);
    if (!pr) {
      state.windows[windowId] = { ...window, pr: null };
      continue;
    }
    const bottom = bottomOf(pr);
    rendered.set(windowId, { letter: render(bottom), number: bottom.number });
    state.windows[windowId] = {
      ...window,
      pr: pr.number,
      bottom: bottom.number,
      stack: stackOf(pr),
      unresolved: bottom.unresolved,
    };
  }

  const reviews = state.reviews?.count ?? 0;
  state.windowKey = windowKey;
  writeState(state);
  await push(rendered, [...windows.keys()], reviews);

  return {
    refetched: refetch,
    windows: windows.size,
    prs: prs.length,
    reviews,
  };
}

// ---------------------------------------------------------------------------
// daemon lifecycle
// ---------------------------------------------------------------------------

// The wrapper rather than this file: it execs zx with the .mjs path, which
// keeps the pid and avoids zx's leftover compiled copy.
function selfPath() {
  const installed = path.join(HOME, ".local", "bin", "prstatusd");
  return fs.pathExistsSync(installed)
    ? installed
    : fileURLToPath(import.meta.url);
}

function runningPid() {
  try {
    const pid = Number(fs.readFileSync(PID_FILE, "utf8").trim());
    if (!pid) return null;
    process.kill(pid, 0); // liveness probe, not a signal
    return pid;
  } catch {
    return null;
  }
}

// The pid file's mtime is the loop's pulse, touched on every iteration whether
// or not anything was fetched or a client was even attached. Its contents never
// change, so the file it lives on is the one already being read to find the
// daemon at all — and the two questions belong together, since a process that
// exists but has stopped cycling is exactly the case the pid alone cannot see.
function beat() {
  try {
    const now = new Date();
    fs.utimesSync(PID_FILE, now, now);
  } catch {}
}

function sinceBeat() {
  try {
    return (Date.now() - fs.statSync(PID_FILE).mtimeMs) / 1000;
  } catch {
    return Infinity;
  }
}

const stalled = (pid) => pid != null && sinceBeat() > STALL_SECS;

// SIGTERM first, because a loop wedged on a promise that will never settle still
// has an idle event loop and runs its handler; SIGKILL for one that does not.
async function kill(pid) {
  try {
    process.kill(pid, "SIGTERM");
  } catch {
    return;
  }
  for (let i = 0; i < 20; i += 1) {
    await sleep(100);
    try {
      process.kill(pid, 0);
    } catch {
      return;
    }
  }
  try {
    process.kill(pid, "SIGKILL");
  } catch {}
}

function log(message) {
  fs.ensureDirSync(STATE_DIR);
  fs.appendFileSync(LOG_FILE, `${new Date().toISOString()} ${message}\n`);
}

async function clearAllLetters() {
  const out = await $`tmux list-windows -a -F '#{window_id}'`.nothrow();
  if (out.exitCode !== 0) return;
  const ids = out.stdout.trim().split("\n").filter(Boolean);
  // Zero rather than undefined, so a stopped daemon takes the review count down
  // with the letters instead of leaving a stale one on the bar.
  await push(new Map(), ids, 0).catch(() => {});
}

async function start() {
  const pid = runningPid();
  if (pid && !stalled(pid)) return console.log(`already running (pid ${pid})`);
  if (pid) {
    // A pid that answers but a loop that stopped turning. Nothing else would
    // ever clear this: `start` is idempotent against the pid, so every config
    // reload from here on would decline to replace the corpse.
    const age = Math.round(sinceBeat());
    log(`wedged for ${age}s (pid ${pid}) — replacing`);
    console.log(`wedged for ${age}s (pid ${pid}) — replacing`);
    await kill(pid);
  }

  fs.ensureDirSync(STATE_DIR);
  const out = fs.openSync(LOG_FILE, "a");
  const child = spawn(selfPath(), ["run"], {
    detached: true,
    stdio: ["ignore", out, out],
  });
  child.unref();
  fs.writeFileSync(PID_FILE, String(child.pid));
  console.log(`started (pid ${child.pid})`);
}

async function stop() {
  const pid = runningPid();
  if (!pid) {
    fs.removeSync(PID_FILE);
    await clearAllLetters();
    return console.log("not running");
  }
  await kill(pid);
  fs.removeSync(PID_FILE);
  await clearAllLetters();
  console.log(`stopped (pid ${pid})`);
}

async function run() {
  fs.ensureDirSync(STATE_DIR);
  fs.writeFileSync(PID_FILE, String(process.pid));

  const bye = () => {
    if (runningPid() === process.pid) fs.removeSync(PID_FILE);
    process.exit(0);
  };
  process.on("SIGTERM", bye);
  process.on("SIGINT", bye);

  const state = readState();
  log(`daemon up (pid ${process.pid})`);

  let failures = 0;
  let force = false;
  for (;;) {
    try {
      const result = await withDeadline(
        (async () =>
          (await clientAttached()) ? cycle(state, { force }) : null)(),
        CYCLE_TIMEOUT_SECS,
        "cycle",
      );
      if (result?.refetched)
        log(
          `refetched: ${result.prs} prs, ${result.windows} windows, ${result.reviews} to review`,
        );
      force = false;
      failures = 0;
    } catch (error) {
      if (error instanceof NoTmuxServer) {
        log("tmux server gone — exiting");
        fs.removeSync(PID_FILE);
        process.exit(0);
      }
      failures += 1;
      log(`error: ${error.message}`);
    }
    beat();
    // Checks in flight want a tighter loop than the notification heartbeat,
    // which would otherwise pin every cycle at 60s.
    const idle = state.heartbeat.pollSecs ?? HEARTBEAT_SECS;
    const wait = state.busy ? Math.min(idle, BACKSTOP_BUSY_SECS) : idle;
    // Capped low enough that the longest backoff still beats STALL_SECS, so a
    // daemon that is merely waiting out an outage is never mistaken for a dead
    // one and killed.
    const target = wait * Math.min(2 ** failures, MAX_BACKOFF) * 1000;
    const before = Date.now();
    await sleep(target);
    // Suspend and resume, not a slow timer. The notification heartbeat cannot
    // report the hours that just went missing, so skip it and fetch.
    if (Date.now() - before > target + WAKE_SLACK_SECS * 1000) force = true;
  }
}

// Promise.race rather than an abort, because the point is to survive a hang
// that nothing here anticipated, and so has no handle to abort by. The
// abandoned promise is the price of the loop carrying on without it.
function withDeadline(promise, secs, what) {
  let timer;
  const deadline = new Promise((_, reject) => {
    timer = setTimeout(
      () => reject(new Error(`${what} timed out after ${secs}s`)),
      secs * 1000,
    );
  });
  return Promise.race([promise, deadline]).finally(() => clearTimeout(timer));
}

// ---------------------------------------------------------------------------
// watch: the pane view, reading what the daemon wrote
// ---------------------------------------------------------------------------

async function resolveTarget(arg) {
  const state = readState();
  const prs = Object.values(state.prs);

  if (/^\d+$/.test(arg ?? "")) return Number(arg);

  if (arg) {
    const byBranch = prs.find((pr) => pr.head === arg);
    if (byBranch) return byBranch.number;
    const byWindow = Object.values(state.windows).find((w) =>
      w.path?.endsWith(`/${arg}`),
    );
    if (byWindow?.pr) return byWindow.pr;
    throw new Error(`no open PR matches "${arg}"`);
  }

  const info = await gitInfo(process.cwd());
  if (!info?.branch) throw new Error("not on a branch");
  const repo = await repoName(info.commonDir);
  const pr = prs.find((p) => p.repo === repo && p.head === info.branch);
  if (!pr) throw new Error(`no open PR for ${info.branch}`);
  return pr.number;
}

const CHALK = {
  green: chalk.green,
  yellow: chalk.yellow,
  blue: chalk.blue,
  red: chalk.red,
  magenta: chalk.magenta,
  colour242: chalk.dim,
};

// Read out of LABELS rather than repeated here, so the pane view cannot end up
// disagreeing with the tab about whose move it is. QUEUED arrives with its
// position appended, and pr.state arrives as MERGED or CLOSED, both of which
// are labels in their own right.
function colourStatus(status) {
  const [, colour] = LABELS[status.split("#")[0]] ?? LABELS.UNKNOWN;
  return (CHALK[colour] ?? chalk.dim)(status);
}

function watchLine(pr, stack) {
  const { checks } = pr;
  let checksOut;
  if (checks.fail > 0) checksOut = chalk.red(`⨯${checks.fail}`);
  else if (checks.pending > 0)
    checksOut = `${chalk.yellow(String(checks.pending).padStart(2, " "))}:${chalk.green(checks.pass)}`;
  else checksOut = chalk.green(checks.pass);

  const threads = chalk[pr.unresolved > 0 ? "red" : "green"](
    `•${pr.unresolved}`,
  );
  const status =
    pr.isInMergeQueue && pr.queuePosition != null
      ? colourStatus(`QUEUED#${pr.queuePosition}`)
      : colourStatus(pr.status);

  const parts = [
    chalk.dim(new Date().toLocaleTimeString()),
    checksOut,
    threads,
    status,
  ];
  if (stack.length > 1)
    parts.push(
      chalk.dim(
        `stack ${stack.map((n) => (n === pr.number ? `[${n}]` : n)).join(" ")}`,
      ),
    );
  if (checks.failing.length) parts.push(chalk.red(checks.failing.join(", ")));
  if (checks.awaitingOn?.length)
    parts.push(chalk.red(`needs you: ${checks.awaitingOn.join(", ")}`));
  return parts.join(" ");
}

async function watch(arg) {
  const number = await resolveTarget(arg);
  let state = readState();
  let pr = state.prs[number];
  if (!pr)
    throw new Error(
      `PR #${number} is not in the daemon's state — is prstatusd running?`,
    );

  console.log(chalk.bold(pr.title));
  console.log(
    chalk.dim(`${pr.head} → ${pr.base}${pr.isDraft ? "  (draft)" : ""}`),
  );
  console.log(chalk.dim(pr.url));
  console.log(chalk.dim(graphitePrUrl(pr)));

  let previousStatus = "";
  let previousMtime = 0;

  for (;;) {
    const mtime = fs.statSync(STATE_FILE).mtimeMs;
    if (mtime !== previousMtime) {
      previousMtime = mtime;
      state = readState();
      pr = state.prs[number];
      if (!pr) {
        console.log(
          `${chalk.dim(new Date().toLocaleTimeString())} ${chalk.yellow("dropped out of the daemon's state — exiting")}`,
        );
        process.stdout.write("\x07");
        process.exit(0);
      }
      const stack = Object.values(state.windows).find((w) => w.pr === number)
        ?.stack ?? [number];
      console.log(watchLine(pr, stack));
      if (previousStatus && previousStatus !== pr.status)
        process.stdout.write("\x07");
      previousStatus = pr.status;
      if (pr.state !== "OPEN") {
        console.log(`\nPR is ${colourStatus(pr.state)} — exiting.`);
        process.stdout.write("\x07");
        process.exit(0);
      }
    }
    await sleep(2000);
  }
}

// ---------------------------------------------------------------------------
// entry point
// ---------------------------------------------------------------------------

async function status() {
  const pid = runningPid();
  const state = readState();
  console.log(
    `daemon:     ${pid ? chalk.green(`running (pid ${pid})`) : chalk.red("stopped")}`,
  );
  // Separately from the fetch below, because the two go stale for different
  // reasons: no fetch means nothing has moved on github, no cycle means the
  // loop itself has stopped turning, and only the second is a fault.
  if (pid) {
    const age = Math.round(sinceBeat());
    console.log(
      `last cycle: ${stalled(pid) ? chalk.red(`${age}s ago — wedged`) : `${age}s ago`}`,
    );
  }
  console.log(
    `last fetch: ${state.updatedAt ? `${Math.round((Date.now() - Date.parse(state.updatedAt)) / 1000)}s ago` : "never"}`,
  );
  console.log(
    `rate limit: ${state.rateLimit ? `${state.rateLimit.remaining} left` : "unknown"}`,
  );
  const prs = Object.values(state.prs);
  const open = prs.filter((pr) => pr.state === "OPEN").length;
  console.log(`prs:        ${open} open, ${prs.length - open} recently closed`);
  console.log(`to review:  ${state.reviews?.count ?? 0}`);
  for (const [windowId, window] of Object.entries(state.windows)) {
    if (!window.pr) {
      console.log(`  ${windowId} ${window.branch} → ${chalk.dim("no pr")}`);
      continue;
    }
    const parts = [`#${window.pr} ${state.prs[window.pr]?.status ?? "?"}`];
    if (window.stack?.length > 1) parts.push(`stack of ${window.stack.length}`);
    if (window.bottom !== window.pr) {
      parts.push(
        `letter from bottom #${window.bottom} ${state.prs[window.bottom]?.status ?? "?"}`,
      );
    }
    if (window.unresolved)
      parts.push(`${window.unresolved} unresolved on the bottom`);
    console.log(`  ${windowId} ${window.branch} → ${parts.join(", ")}`);
  }
}

// What the count in status-right is actually counting, so it has something to
// act on rather than only nagging.
async function reviews() {
  const { count = 0, prs = [] } = readState().reviews ?? {};
  if (count === 0) return console.log("nothing waiting on you");
  for (const pr of prs) {
    console.log(
      [
        chalk.yellow(`#${pr.number}`),
        chalk.dim(pr.repo),
        pr.author ? chalk.blue(`@${pr.author}`) : null,
        pr.title,
      ]
        .filter(Boolean)
        .join(" "),
    );
  }
  // issueCount is the whole total, the node list only the first page of it.
  if (count > prs.length)
    console.log(chalk.dim(`… and ${count - prs.length} more`));
}

// Clicking a letter in the status bar lands here with the pull request number
// tmux read out of the range under the pointer, and clicking the review count
// lands here with REVIEW_TARGET. Numbers are also reachable by hand from the
// `reviews` list, which is why the review bucket is searched alongside state.prs.
async function openPr(target) {
  let url = GRAPHITE_URL;
  let what = "the graphite dashboard";

  if (target !== REVIEW_TARGET) {
    const state = readState();
    const number = Number(target);
    const pr =
      state.prs[number] ??
      (state.reviews?.prs ?? []).find((r) => r.number === number);
    if (!pr) throw new Error(`PR #${target} is not in the daemon's state`);
    url = graphitePrUrl(pr);
    what = `#${pr.number}`;
  }

  const out = await $`open ${url}`.nothrow();
  // A click discards its output, so the log is the only trace it left.
  if (out.exitCode !== 0) log(`open ${what} failed: ${out.stderr.trim()}`);
}

const HELP = [
  "prstatusd — one poller for every worktree's PR state.",
  "",
  "Usage:",
  "  prstatusd start          # start the background daemon (idempotent)",
  "  prstatusd stop           # stop it and clear the letters",
  "  prstatusd restart",
  "  prstatusd toggle         # bound to prefix P",
  "  prstatusd status         # daemon health, last fetch, resolved windows",
  "  prstatusd once           # one poll cycle now, then exit (prefix R)",
  "  prstatusd run            # run the loop in the foreground",
  "  prstatusd watch [target] # the pane view; target is a PR number, branch, or worktree",
  "  prstatusd reviews        # the PRs waiting on you, as counted in status-right",
  "  prstatusd open <target>  # a PR number, or `reviews` for graphite itself; bound to a click",
].join("\n");

const command = argv._[0] ?? "help";

try {
  switch (command) {
    case "start":
      await start();
      break;
    case "stop":
      await stop();
      break;
    case "restart":
      await stop();
      await start();
      break;
    case "toggle":
      if (runningPid()) await stop();
      else await start();
      break;
    case "status":
      await status();
      break;
    case "once": {
      const state = readState();
      const result = await cycle(state, { force: argv.force ?? false });
      console.log(
        `${result.prs} prs, ${result.windows} windows, ${result.reviews} to review${result.refetched ? " (refetched)" : ""}`,
      );
      // Both the refresh binding and the client-attached hook land here, which
      // makes this the moment a wedged daemon is worth noticing: someone is
      // looking at the bar and it is out of date. A daemon that was deliberately
      // stopped leaves no pid behind, and so is left stopped.
      const pid = runningPid();
      if (stalled(pid)) await start();
      break;
    }
    case "reviews":
      await reviews();
      break;
    case "run":
      await run();
      break;
    case "watch":
      await watch(argv._[1]);
      break;
    case "open":
      await openPr(argv._[1]);
      break;
    default:
      console.log(HELP);
  }
} catch (error) {
  if (error instanceof NoTmuxServer) {
    console.error("no tmux server running");
    process.exit(1);
  }
  console.error(chalk.red(error.message));
  process.exit(1);
}
