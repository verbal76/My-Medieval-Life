# Build 12: AI efficiency and token-savings audit

**Question:** did the three token skills and RTK actually reduce AI resource use and development time during the Build 12 run?

**Short answer:**
- **RTK gave a small, real, measurable saving.** It is overstated by its own counter.
- **The three skills gave no measurable benefit.** They were never invoked as skills, never reached the subagents that did most of the work, and the behaviour they target did not measurably change.
- **Most of the potential savings lie elsewhere**, chiefly in screenshots and in work done by subagents (section 7).

**Labels:**
- **[M] measured:** read directly from `rtk gain`, the RTK database, the Claude Code session logs, Git or GitHub Actions.
- **[E] estimated:** derived from measured figures by a stated method.
- **[U] unavailable:** cannot be measured from this container.

**Scope:** written 2026-10-19, documentation only. No gameplay code, build or merge.

## 1. Data sources and limits

**RTK:**
- `rtk gain` and its options `-F`, `--recalls` and `-d`.
- RTK's own database (`~/.local/share/rtk/history.db`): 742 command records and 1,070 hook decisions.

**Claude Code session logs (`~/.claude/projects/*/…jsonl`):**
- 2 main transcripts and 60 subagent transcripts.
- From them: every API response's `usage` (deduplicated by message id), tool calls, tool results and timestamps.

**Work done:** Git history, counting non-merge commits and lines changed. Generated data (`village.json`, `docs/systems/`, `game/assets/`) is excluded from line counts.

**Build and test time:** GitHub Actions run timings.

**Limits:**
- **RTK started on 2026-10-19 06:24 UTC.** It has no history before Build 12, so there is no RTK "before" figure; the before/after comparison uses the session logs.
- **Billing is [U].** The logs give tokens, not charges, and the account's plan and billing data are not visible here. The owner reported reaching 99% of a *weekly usage allowance* on 2026-10-18, which points to a subscription, not per-token billing.
- **Only one long session exists** (this one, across several compactions). There is no independent control session.
- **Token counts from RTK are its own estimates** (from output size). Token counts from the logs are the API's own figures.

### Time windows compared

| Window | UTC | What it was |
|---|---|---|
| **B11 run** | 2026-10-18 20:43 to 22:43 | Build 11 completion (Living Forest), before skills and RTK |
| **B8-fix run** | 2026-10-19 00:19 to 06:14 | Build 8 master fixes. The skills were synced into the container at 02:08 but not read by Claude until 06:15; no RTK |
| **B12 run** | 2026-10-19 06:15 to 08:35 | Punch lists 1 and 2, integration, Build 12. Skills read at 06:15; RTK hook live from 06:28 |
| **B12 audit** | 2026-10-19 11:51 to 12:04 | The full development audit (six read-only agents) |

## 2. RTK

### 2.1 Totals from `rtk gain`

| Metric | Value | Label |
|---|---|---|
| Commands processed | 725 (742 rows in the database by the time of this audit) | M |
| Output before filtering | 223.7K tokens | M (RTK estimate) |
| Output after filtering | 129.7K tokens | M (RTK estimate) |
| Tokens saved | 94.0K | M (RTK estimate) |
| Reduction | 42.0% | M (RTK estimate) |
| Time added by RTK's own processing | 1 m 58 s in total (163 ms average) | M |
| Oversized outputs excluded from the count | 3 | M |
| Parse failures | 2, both recovered by running the command raw | M |
| Recall rate (hidden output the agent came back for) | 0 of 94 elisions (grep 79, ls 15) | M |

### 2.2 How the savings break down

**By command:**
- `grep` (549 runs) saved 64.5K tokens.
- `read`/`cat` (41 runs) saved 13.9K.
- `ls` saved the rest.

**The largest single savings:**
- `grep -n INT- docs/SYSTEM_INTERACTION_MANIFEST.md`: 10.1K → 0.4K.
- `cat tests/aging_test.gd`: 6.9K → 0.2K.
- `cat balance.json`: 4.6K → 0.03K.

**By window** [M]:

| Window | Records | Saved | Rate |
|---|---|---|---|
| B12 run (06:28 to 08:35) | 579 | 80.7K | 49% |
| B12 audit (11:51 to 12:04) | 126 | 12.5K | 5% (the audit agents mostly read whole source files) |

### 2.3 Hook coverage

| Path | Count | Label |
|---|---|---|
| Hook decisions | 1,070 | M |
| Rewritten to RTK ("ask") | 448 (42%) | M |
| Passed through unchanged ("defer"): Python heredocs, `mkdir`, Godot runs, etc. | 622 (58%) | M |
| Never seen by RTK (any command containing "git", skipped by the wrapper) | 129 Bash calls in the B12 run, 106,775 characters of output | M |
| 200 RTK records saved nothing | 200 of 742 | M |

### 2.4 How real the savings are

**The headline figure overstates context savings.**
- 330 of the 448 rewritten commands [M] were already piped into `head`, `tail`, `cut` or `wc`.
- RTK counts its saving against the command's full raw output, before that pipe. But `head` would have cut most of that output anyway, so it would never have reached Claude.
- In the sample of rewrites that could be matched to log entries, 22.2K of 23.2K counted tokens (96%) came from such piped commands [M].
- The true saving is therefore below 94K. The data does not allow an exact figure [U].

**The saving compounds.**
- A token kept out of an agent's context is not re-read on that agent's later turns (each later turn reads its context from the prompt cache).
- The median rewritten command was followed by 49 more API calls in the same agent [M].
- Applying 49 to 83 later reads to the B12 run's 80.7K counted saving gives an **upper bound of about 4 to 7 million fewer cache-read tokens** [E]. That is **1 to 2% of the B12 run's 346M input tokens**.
- The bound is high for two reasons: the head-pipe overstatement above, and context compaction, which drops old tool output anyway.

**Share of Bash output:**
- Bash output that reached the model after the hook went live: 1.52M characters, about 380K tokens [E, at 4 characters per token].
- RTK's counted 80.7K would be at most **17%** of what Bash output would otherwise have been [E].

### 2.5 Problems RTK introduced

| Problem | Effect | Label |
|---|---|---|
| Agents' sandbox refused `rtk git …` | A custom wrapper (`/root/.local/bin/rtk-hook-skip-git`) now passes every command containing "git" through raw. So git output, about 7% of Bash output, is never compressed | M |
| `rtk grep -c` across several files fails ("invalid max count") | Seen once (2026-10-19 12:06); 13 other `grep -c` rewrites returned counts | M |
| `rtk gain` reports "No hook installed" | Because of the wrapper; misleading but harmless | M |
| Not persistent | Installed only in this container; a new container loses RTK unless the environment setup script installs it | M |
| Hook start-up cost | One shell plus a Python start-up per Bash call (about 1,200 calls); not timed | U |
| Output format changes | `rtk grep` groups matches by file ("46 matches in 3 files") instead of grep's format. No misread was found in the logs, but scripts that parse grep output could break | M |

## 3. The three skills

### 3.1 What they are and how they were installed

| Skill | Content | Installed |
|---|---|---|
| `token-efficiency` | 15.5 KB of principles: lean prose, search before reading, batch tool calls, keep big output out of context, delegate exploration to subagents | 02:08 UTC, as `SKILL.md` only |
| `session-token-hygiene` | Compact at 55 to 65% of context with explicit keep/drop instructions; `/clear` after 3 to 4 compactions; one topic per conversation | same |
| `mcp-output-token-discipline` | Disable unneeded MCP servers; narrow noisy shell commands; do not invent per-server token figures | same |

**Missing parts of `token-efficiency`:**
- Its own text depends on a `CORE.md` re-injected every turn by a `UserPromptSubmit` hook, plus `hooks/` and `references/examples.md`.
- **None of these exist in the container** [M].
- The skill itself says that without the hook the guidance "drifts out of effect over a session".

### 3.2 Were they used?

| Evidence | Finding | Label |
|---|---|---|
| Skill tool invocations in all 62 transcripts | **Zero** for all three (the only Skill call in the logs is `artifact-capabilities`, on 2026-10-18) | M |
| When Claude read them | Once, at 06:15, in the main session, with `cat` and `sed -n 1,80p`. `token-efficiency` was read only to line 80 of about 200 | M |
| How long they stayed in context | Until the next compaction (11:58); then only the summary's mention remained | M |
| Subagents | None was told to apply them. The only mention in subagent transcripts is the skill listing every agent receives | M |
| Share of the B12 run's work done by subagents | 71% of input tokens, 48% of output tokens, about 90% of API calls (Sonnet) | M |

**So the skills could only have shaped the main session, which did about a third of the work, for under six hours.**

### 3.3 Did behaviour change? (all [M])

| Behaviour the skills target | B11 | B8-fix | B12 | B12 audit | Reading |
|---|---|---|---|---|---|
| Responses with parallel tool calls (all agents) | 11% | 13% | 16% | 17% | Slight rise; also explained by more Read-plus-Bash batches in agents |
| Responses with parallel tool calls (main only) | 3% | 11% | 10% | 11% | No change after the skills |
| Exact duplicate file reads | 4 (all screenshots) | 4 (all screenshots) | 27 (26 screenshots, 1 text) | 0 | Worse in B12, driven by re-reading screenshots |
| Bash commands with no output limiter | 30% | 33% | 29% | 36% | No change |
| Average Bash output per call | 1,127 characters | 2,317 | 1,675 | 5,452 | Mixed; RTK, not the skills, explains B12's drop |
| Manual compaction before auto-compact (`session-token-hygiene`) | — | — | none | none | Not applied. Compaction is triggered by the user in this cloud setup, and the session auto-compacted at 11:58 |
| Exploration delegated to subagents (`token-efficiency` §5) | 1 agent | 6 agents | 13 agents | 6 agents | Already the practice before the skills (user preference: Sonnet agents) |
| MCP servers disabled (`mcp-output-token-discipline`) | — | — | none | none | Not applied. Server choice belongs to the environment, not to Claude |

**Examples of the skills' advice being followed in the main session:**
- concise reports;
- `grep` before reading;
- line-range reads;
- RTK used throughout.

The same habits appear in the B11 and B8-fix windows. They come from the standing instructions (the `CLAUDE.md` conciseness rule and the user's "be token-efficient" preference), not from the skills. **No behaviour change attributable to the skills could be found.**

**Overhead the skills caused:** about 8K tokens to read them at 06:15, plus the skill listing on every turn [E]. That is negligible.

## 4. Build 12 resource use

| Metric | B12 run (06:15 to 08:35) | Label |
|---|---|---|
| API responses | 1,512 (Opus 163, Sonnet 1,349) | M |
| Agents | Main session plus 13 subagents, one session | M |
| Input tokens, uncached | 3,072 | M |
| Cache writes | 3.07M | M |
| Cache reads | 343.0M | M |
| **Total input** | **346.1M (99.1% from cache)** | M |
| Output | 191.3K | M |
| Wall-clock time | 2 h 20 m (directive to packet commit 08:17) | M |
| Main session active time (gaps under 10 min) | about 1.2 h | M |
| Godot test runs (summed over agents, which run in parallel) | 4,511 s, about 75 min | M |
| Python tests and checks | 399 s | M |
| CI tests on `f8b4a98` | 2 m 54 s | M |
| Release build of all three platforms | 2 m 06 s | M |
| Debugging time | Not separable from other Bash time | U |
| Screenshots read | 137 images | M |
| Text files read | 26 | M |
| RTK saving (direct) | 80.7K tokens counted, less in practice | M / E |
| RTK saving (compounded upper bound) | 4M to 7M cache-read tokens (1 to 2%) | E |

**The B12 audit:** 32.0M input, 47.1K output, 6 Sonnet agents [M].

**All logged sessions, 2026-10-17 to 2026-10-19:** 2.10 billion input tokens (98.5% cache reads) and 3.22M output [M].

## 5. Before and after, normalised by work done

| | B11 run | B8-fix run | B12 run |
|---|---|---|---|
| Skills read / RTK | no / no | no / no | yes / yes |
| Non-merge commits | 14 | 16 | 31 (plus 18 merges) |
| Lines changed (excluding generated data) | 3,052 | 6,689 | 11,753 |
| Total input tokens | 128.2M | 153.4M | 346.1M |
| Output tokens | 98.6K | 95.2K | 191.3K |
| **Input per commit** | 9.2M | 9.6M | 11.2M |
| **Input per 1,000 lines** | 42.0M | 22.9M | 29.5M |
| **Output per commit** | 7.0K | 6.0K | 6.2K |
| **Output per 1,000 lines** | 32.3K | 14.2K | 16.3K |
| Cache hit rate | 98.4% | 97.8% | 99.1% |

All figures are [M]; the ratios are [E].

**Reading:**
- Build 12 used **more** input per commit than either earlier run and sits between them per line changed.
- Nothing here shows the skills or RTK reducing consumption. Their effect, if any, is smaller than the variation between runs caused by the kind of work done:
  - B12 integrated six agents' branches, with 18 merges, conflict resolution and repeated full test runs;
  - B11 was mostly one feature.
- **Do not attribute B12's higher total to the tools either.** B12 simply did about twice the work of either earlier run.

## 6. Financial impact

**Actual billing savings: none that can be shown** [U].
- The account appears to be on a subscription with a weekly allowance.
- Fewer tokens there means more headroom before the limit, not a lower bill.

**Hypothetical per-token cost.** These are *assumed* list prices, not the account's prices:
- Opus-class: $5/M input, $6.25/M cache write, $0.50/M cache read, $25/M output.
- Sonnet-class: $3, $3.75, $0.30 and $15.

| | Hypothetical cost |
|---|---|
| B11 run | $59.78 |
| B8-fix run | $68.33 |
| B12 run | $138.62 (Opus $53.25, Sonnet $85.37) |
| B12 audit | $19.67 |
| RTK in the B12 run, at those prices | **about $1.50 to $2.30** (1 to 1.7% of the run; an upper bound) |
| The three skills | **$0** measurable |

The RTK figure is computed as 80.7K direct tokens at the cache-write price, plus 4M to 7M compounded cache reads, mostly by Sonnet agents.

**Allowance headroom:** at those proportions, RTK bought back about 1 to 2% of the allowance used in the run [E]. That is useful, but it is not what decides whether a run hits the weekly limit.

## 7. Where the real savings are

These figures come from the same logs [M]. They are recommendations, not changes made here.

1. **Screenshots are the biggest avoidable cost.**
   - The B12 run read 137 screenshots, 26 of them more than once.
   - Each full 1280×720 image is roughly 1,200 tokens of fresh context [E], about 165K tokens in all. That is more than twice RTK's whole saving, before compounding.
   - Fixes:
     - crop to the region being checked;
     - capture at a lower resolution;
     - look once, record the verdict, and do not re-read.
2. **Subagent prompts should carry the efficiency rules.**
   - Subagents did 71% of the input.
   - The skills reached none of them.
   - Fix: add a short "read line ranges, cap output, don't re-read" paragraph to every agent brief, or install the `token-efficiency` `UserPromptSubmit` hook so every agent gets `CORE.md`.
3. **Audit agents should not `cat` whole files.**
   - The B12 audit's agents averaged 5,452 characters per Bash call.
   - RTK saved only 5% there, because the content was source code it does not compress.
4. **Compaction is automatic here.** The `session-token-hygiene` advice (compact at 60%) cannot be applied by Claude in this cloud setup. Only the owner can run `/compact` or `/clear`.

## 8. Summary by tool

| Tool | Measurable evidence | Estimated benefit | Limitations | Confidence |
|---|---|---|---|---|
| **RTK** | 725 commands, 94.0K tokens counted as saved (42%); 80.7K in the B12 run; 0 recalls; 1 visible failure | Real but small: under 17% of Bash output, about 1 to 2% of total input tokens, about $1.50 to $2.30 hypothetical in the B12 run | Savings overstated (330 of 448 rewrites already piped to `head`); git output bypassed; not persistent; `grep -c` bug; `rtk gain` misreports the hook | **Medium** that savings are real and small; **low** on the exact size |
| **token-efficiency** | Read once (to line 80) at 06:15; never invoked; no subagent received it; no metric changed | None measurable | Its always-on hook and `CORE.md` are missing; partly read; lost at compaction | **High** that it had no measurable effect |
| **session-token-hygiene** | No manual compaction; auto-compaction at 11:58 | None measurable | Its main lever (`/compact`, `/clear`) is user-only in this cloud session | **High** |
| **mcp-output-token-discipline** | No MCP server disabled; its shell-output advice overlaps RTK and existing habits | None measurable beyond what RTK and existing habits already did | MCP configuration belongs to the environment, not to Claude | **High** |

## 9. Recommendations

1. **Keep RTK, and make it permanent.**
   - Add the install (`cargo install --git https://github.com/rtk-ai/rtk --tag v1.0.1 --locked rtk --root /root/.local`) and the hook to the environment setup script.
   - It costs about 160 ms a command and saves real, if modest, context.
   - Report RTK's figures with the head-pipe caveat, not as headline savings.
2. **Fix RTK's gaps:**
   - Try letting `git status`/`git diff` through RTK in the main session only, leaving agents on the raw path.
   - Report the multi-file `grep -c` bug upstream.
3. **Make `token-efficiency` actually active:**
   - Install its `CORE.md` and `UserPromptSubmit` hook. These are the parts that make it work every turn and reach subagents.
   - Without them, it is a document read once.
4. **Drop `session-token-hygiene` and `mcp-output-token-discipline` from the run instructions for cloud sessions.**
   - Their levers are owner-side here.
   - The owner can use `/compact` with keep/drop instructions at about 60%.
5. **Cut screenshot cost first** (section 7, item 1). It is the largest single measurable saving available.
6. **Put a three-line efficiency rule in every subagent brief** (section 7, item 2).
7. **Measure next time from the start:**
   - Record `rtk gain` and the session's token totals at the start and end of each build run, so the next comparison has clean baselines.

## Verdict

**RTK genuinely reduced resource use, by a small amount:**
- about 1 to 2% of the Build 12 run's input tokens, at most;
- no measurable change in development time.

**The three skills' benefits were theoretical in this run.** They were never invoked and never reached the subagents that did most of the work. Every efficiency metric looked the same before and after they were read.

**Build 12's cost was driven by the amount of work done**: 31 commits and 18 merges in 2 h 20 m, with 13 agents. It was not driven by the presence or absence of these tools.
