# REQ-B17F-JOBS: adult unemployment measured after Batch 3+4 (owner decision B25-B17FJOBS-D1, option (b), measurement only)

## Source

- Run: 43124937749 (`wip/b25-births-diag-base` `0051477`).
- That commit is `fbfd6ad` (Batch 3+4, merged into the development line at `b2cd024`) plus a read-only diagnostic.
- The data are the `JOBS` lines of `economy_sim.gd`, every 5 days, for seeds 2 and 4 over 365 days.
- No code was changed.

## Adults without a job

| Seed | d5 | d65 | d125 | d185 | d245 | d305 | d365 |
|---|---:|---:|---:|---:|---:|---:|---:|
| 2 | 0 | 1 | 2 | 14 | 23 | 52 | 101 |
| 4 | 0 | 0 | 7 | 22 | 29 | 45 | 69 |

## At day 365: who they are, and why

| Measure | Seed 2 | Seed 4 |
|---|---:|---:|
| Without a job (`without_job.n`) | 101 | 69 |
| Arrived or born during the run | 101 (all) | 69 (all) |
| Never had a job | 101 | 69 |
| Median coins | 0 | 0 |
| Adults who came of age | 144 | 158 |
| Migrants in / out | 153 / 46 | 146 / 64 |
| Searches that found nothing (`looked_found_none`) | 8,525 | 9,009 |
| Open vacancies | 0 | 1 (merchant) |
| Household unsustainable | 4 | 2 |
| With children at home and an earner | 68 | 14 |
| Partner works | 5 | 4 |

- The adults out of work were born in the run or arrived in it, and none ever had a job.
- The number of posts stays about level: farmers 12 → 18, manor hands 0 → 12–13, everything else about constant.
- Meanwhile 144–158 children come of age and 146–153 migrants arrive.
- Searches fail about 8,500–9,000 times a year, with almost no vacancies open.

## Cause (measured)

**Labour supply grows faster than the village's posts.** It is not a hiring defect:
- no adult who had a job lost it to an error;
- `job_whys` for the 226–239 job changes are retirement, the master's death (apprenticeship), out of work, and the manor letting a
  stall.

Whether the village should create more work (new posts, emigration for work, more manor labour) is a design question for the
owner. Per the decision, **no employment-system change was made on this measurement.**
