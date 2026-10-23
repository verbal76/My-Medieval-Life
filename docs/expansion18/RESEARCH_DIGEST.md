<!-- Committed for Expansion 18 (owner master directive 2026-10-21, docs/directives/2026-10-21_expansion18_master_directive.md on staging). The three papers the owner attached (TenureExperience.pdf, 9501lync.pdf, c8781.pdf) are not committed; this digest of them is unchanged in substance. -->

# Research digest: experience, tenure and training effects on productivity vs pay

Input for the "settlement capability" scale (0-10 per industry, separate output and pay multipliers).
I read every page of all three PDFs, including tables and appendices.

**How page numbers are cited.** "p." is the page number printed on the page.
- Caplin et al.: the PDF page is the printed page + 1, because the title page has no number.
- Lynch: the printed journal pages are 54-58.
- Bishop: the printed book pages are 161-199, so the PDF page is the book page minus 159. Tables 6.6, 6.8, 6.9, 6.10 and 6.11 are on pages with no printed number; their positions are inferred and marked "(unnumbered)".

Anything marked **[derived]** is my arithmetic on numbers the papers print. The papers do not state it.

---

## Paper 1: Caplin, Lee, Leth-Petersen, Sæverud and Shapiro (2026)

**Citation (as printed):** Andrew Caplin, Minjoon Lee, Søren Leth-Petersen, Johan Sæverud, and Matthew D. Shapiro, "How Worker Productivity and Wages Grow with Tenure and Experience: The Firm Perspective", February 14, 2026. The online appendix is dated February 1, 2026. No journal, working-paper series or number is printed. JEL E24, J24, J30. Acknowledgements note "This paper is a chapter of Sæverud's Ph.D. thesis" (title page).

### Data and method
- **Survey.** The authors designed the "Danish Firm Survey" and Epinion fielded it in November 2020 (p.8). It sampled from the 44,000 privately owned Danish firms with 5 or more employees, invited 15,000 and received 2,747 complete responses. "The final response rate is 18.3%" (p.8). The sample was stratified into 10 industries × 4 size classes and weighted.
- **Linked registry data.** The survey is linked to Danish registry data, used to validate answers and to calibrate separation rates (pp.9-10, Section III, Appendix D).
- **What managers were asked** (all about the firm's most common occupation, workers aged 35+):
  - how many years of tenure a new hire with no relevant experience needs to reach "maximal productivity", defined as the level "where additional tenure no longer results in a meaningful increase in productivity" (p.1);
  - how that tenure changes with 1-2, 3-4, 5-9 and 10+ years of prior sector-specific experience;
  - the entry wage for each experience level, and the wage at maximal productivity (Appendix B, pp.47-51).
- **Accounting model** (pp.25-30):
  - productivity is log-linear in tenure until it reaches maximal productivity, which is normalised to 1 (eq. 4);
  - the wage path is also log-linear (eq. 5);
  - the present value of productivity equals the present value of wages (break-even condition, eq. 3), with a 4% discount rate and separation rates from the registry;
  - a front-loading factor x is calibrated at 7%, "the smallest value of x that is consistent with this pattern" (p.29);
  - R^P is estimated by GMM (eq. 8).
- **Decomposition.** Both returns are split into a tenure part (firm-specific) and an experience part (sector-specific, portable), by eqs. 2 and 9.

### Headline quantitative findings

**Tenure needed to reach maximal productivity, with no prior experience (Table 2, p.14):**
- 1 year: 48.5% of jobs
- 2 years: 13.9%
- 3-4 years: 27.4%
- 5+ years: 10.2%
- Mean 2.2 years, median 2 (Table 3, p.15).

**Productivity vs wage returns to tenure:**
- "productivity returns to tenure are estimated to be two to three times larger than wage returns to tenure" (p.3).
- **"the weighted average of the productivity return to tenure (across job groups) is 7.9% per year, while that of the wage return to tenure is 3.2% per year"** (p.32; PDF page 33). This is where the 7.9% and 3.2% figures come from.
- The conclusion says "the productive return to tenure is three times the wage return to tenure" (p.38).

**Table 7 (p.30): annual returns before maximal productivity is reached, by job group (T0Max = tenure needed with no prior experience). Standard errors in parentheses.**

| | 1 yr jobs | 2 yr | 3-4 yr | 5+ yr |
|---|---|---|---|---|
| Total productivity return R^P (GMM) | 12.0 (3.4) | 11.3 (2.6) | 10.1 (1.1) | 7.6 (1.3) |
| Productivity return to tenure R^P_T | 10.8 | 7.8 | 4.8 | 3.0 |
| Productivity return to experience R^P_E | 1.2 | 3.5 | 5.4 | 4.6 |
| Wage return to tenure R^W_T | 4.8 | 2.7 | 1.6 | 1.1 |
| Wage return to experience R^W_E | 4.1 | 4.3 | 3.8 | 3.5 |
| N | 1,277 | 385 | 754 | 293 |

- Only R^P has standard errors. The decomposition rows have none.
- Text: R^P "varies between 7%-12% per year, with greater annual (though less cumulative) productivity growth for jobs that take fewer years" (p.29).

**Wage returns, Table 6 (p.24), in % per year:**
- Average total wage return R^W: 8.9, 7.0, 5.4, 4.6.
- Median total wage return R^W: 4.8, 4.4, 4.0, 3.5.
- Median return to tenure R^W_T: 2.0, 0.7, 0.7, 0.5.
- The literature's range of wage returns to tenure runs "from less than 1% per year ... to 4% per year" (p.3). Dustmann-Meghir's "6-10% per year for the return to experience and 2-4% per year for the return to tenure" is cited on p.23.

**Replacement-cost example (p.33).** Replacing a 5-year incumbent in a 5+ year job with an outsider who has 5 years of experience:
- costs "15.0% (3.0% per year times 5 years)" in productivity;
- "only 5.5% (1.1% per year times 5 years)" if it is inferred from wages.

**Entry wages relative to the wage at maximal productivity (Table 5, p.22):**
- With no experience, the median is 0.94, 0.89, 0.84 and 0.77 for the 1, 2, 3-4 and 5+ year job groups.
- It reaches 1.00 once prior experience is about T0Max years or more.
- Figure 6 (p.31) shows implied entry *productivity* well below entry wage. For 5+ year jobs it is about 0.55 on the 1+log(P) axis.
- Front-loading: "new employees with 5 to 9 years of experience still need about 2 years of tenure ... but their initial wage is already the same as that of an employee with maximal productivity" (p.25).

### Shape of returns
- **Within a job the model is a plateau, by construction.** Productivity rises until T^Max and is flat afterwards, because maximal productivity is defined as the point where more tenure adds nothing. Log-linear growth before the plateau is an *assumption* (p.26), not a finding. The paper therefore says nothing about concavity *inside* the climb, but it is clear that the climb ends early: about 90% of jobs plateau within 5 years (Table 2).
- **Prior experience shows diminishing returns.** "There are positive but diminishing returns from relevant previous experience. Moving from zero to one year of relevant experience reduces required tenure by about 0.6 year ... The slope reduces to negative 0.3 year between 4 and 6 years ... and to close to zero (negative 0.016 year) for above 7 years" (p.16).
- **Tenure needed, by prior experience (Table 4, "All" column, p.16):**

  | Prior experience | 0 | 1-2 yrs | 3-4 yrs | 5-9 yrs | 10+ yrs |
  |---|---|---|---|---|---|
  | Tenure needed (years) | 2.2 | 1.6 | 1.0 | 0.8 | 0.7 |

  **[derived]** Of the total 1.5-year reduction, about 40% comes from the first 1-2 years of experience, about 80% by 3-4 years and about 93-97% by 5-9 years. That is strongly concave, and essentially flat after about 7 years.
- **A floor that experience cannot remove.** "even when a new employee has at least 10 years of experience, she still needs to be on this job for more than a half year" (p.16). For 5+ year jobs, 10+ years of experience still leaves 1.1 years of tenure needed (Table 4).

### Differences by occupation and skill
**Tenure to maximal productivity by occupation group (Table 3, p.15):**

| Occupation group | Mean (median) years |
|---|---|
| Require high knowledge | 2.9 (3) |
| Management | 2.3 (2) |
| Farming | 2.3 (2) |
| Manual labour, skilled | 2.3 (2) |
| Medium knowledge | 2.2 (2) |
| Sales & service | 2.0 (1) |
| Office | 1.8 (1) |
| Operator/assembly | 1.6 (1) |
| Manual, unskilled | 1.5 (1) |

- Registry-based groups are similar: farming 2.3, skilled manual 2.3 (Table 9, p.35).
- Occupation dummies explain little: adjusted R² 0.059; industry dummies alone give 0.030 (p.14, fn 11). "substantial across-firm heterogeneity within occupation groups" (p.14).
- Education: +0.13 years of T0Max per year of schooling (t = 6.8). This falls to 0.03 (not significant) once occupation is controlled for (p.15).
- **Unskilled manual labour:** one year of prior experience replaces only 0.25 years of tenure, and the slope reaches about zero at higher levels.
- **High-knowledge jobs:** one year of prior experience replaces 0.41 years of tenure, and the slope never reaches zero (p.18, Fig. 4).
- **Jobs needing 1 year:** "The first year of experience only replaces 0.13 years of tenure" (p.16).
- **Jobs needing 5+ years:** the first several years of experience reduce tenure "one-to-one"; 3.5 years of experience cut 3.2 years (pp.17-18).
- "the bulk of human capital of unskilled workers is acquired on the job" (p.18). "returns to tenure are more important for jobs that are more likely to be taken by unskilled workers while returns to experience are more important for jobs that are more likely to be taken by skilled workers" (p.3).
- **Separation rates in year 1 (Appendix D, Table D1, p.57):** farming 37.4%, skilled manual 37.6%, unskilled manual 41.8%, management 24.4%. All fall to about 6-7.5% at 10+ years.

### Mechanisms the authors propose
- **Firm-specific vs sector-specific human capital.** Tenure builds both; prior experience brings only sector-specific capital (pp.5-6). Firm-specific capital "has a distinct role ... which accumulates only with tenure on the current job" (p.16).
- **Wages are not spot prices.** "wages not being allocative period-by-period" (abstract). Wages are front-loaded because firms "anticipate these employees staying for a number of years and front-load some of the productivity gains in the initial wage" (p.25).
- **Training-cost theories.** "most theories where employers bear the costs of on-the-job training suggest that productivity should rise more rapidly than wages (e.g., Becker, 1964, Acemoglu and Pischke, 1998, 1999, ...)". Lazear's bonding theory implies the opposite (p.25, fn 15). The authors stress that the flatter wage path "is a result, not an assumption".
- **Rent sharing.** Only mentioned as something the normalisation is neutral to: "allowing for rent-sharing by adjusting the entire wage path by the same factor will not affect our estimation" (p.27).
- **Monopsony.** Not discussed.

### Stated limitations
- The data are survey perceptions of managers about the *most common* occupation, which are mostly entry-level jobs (p.6, fn 5; p.10).
- Workers are aged 35+, and general labour-market experience is excluded (pp.2, 10).
- Maximal productivity is assumed not to vary with prior experience (fn 5).
- Log-linear paths with a common slope are assumed (p.26).
- x is not uniquely identified and 7% is a lower bound; "Under a larger value of x, the estimated R^P will be larger" (p.29, fns 18-19). The productivity-to-wage gap is therefore, if anything, a lower bound under this model.
- The order in which firm-specific and sector-specific capital accumulate is not identified (fn 13).
- The parametric results rely on auxiliary assumptions (p.33).
- Context: Danish firm-level bargaining and "Flexicurity", with turnover of about 20-25% a year (p.9). The survey was fielded during COVID; respondents were asked to imagine hiring "2-3 years from now" with herd immunity (p.47).
- **Validation:** survey and registry agree on the most common occupation (Table 8: 24.8-61.0% exact alignment) and on entry wages (Fig. 7, pp.36-37). Only the T0Max = 1 group deviates, by "around 2 percentage points" (p.36).

---

## Paper 2: Lynch (1995)

**Citation (as printed):** Lisa M. Lynch, "The Growing Wage Gap: Is Training the Answer?", *FRBNY Economic Policy Review*, January 1995, pp. 54-58. Lynch is described as "William L. Clayton Associate Professor of International Economic Affairs, Fletcher School ... Tufts University, and Research Associate, National Bureau of Economic Research" (p.54).

### Data and method
This is a short conference policy essay. It presents no new estimation, standard errors or tables of its own. It summarises Lynch (1992, AER), Lynch ed. (1994), the 1991 CPS, OECD Employment Outlook 1991, and a 1994 BLS survey of establishments. Its one chart shows the share of individuals receiving company training in the US, Germany, Germany aged 20-24, and Japan (p.55).

### Headline figures
- **Wages:** "company-provided training programs, apprenticeships, and off-the-job training seem to increase wages of workers on the order of 4.4 to 11 percent (see Lynch 1994)" (p.55). This is where the 4.4%-11% figure comes from. It is a cited range with no standard errors and no time horizon.
- **Productivity:** "The few studies that do exist (see Lynch 1994 for a summary of these studies) suggest that training increased productivity on the order of 16 to 17 percent. This is a very high rate of return" (p.56). This is where the 16%-17% figure comes from. It is a cited summary with no standard errors.
- The productivity figure is qualified in the same sentence: "until we have a more representative sample of establishments in the United States in which we can control for capital and other characteristics of firms, the returns to training for the typical firm remain somewhat speculative" (p.56).
- **Training incidence:**
  - "in 1991 only 16 percent of U.S. workers said they had received formal skills training in their current job", although "nearly half of all establishments ... in 1993 provided some type of formal skills training" (p.55).
  - Apprenticeship programmes: ">50 percent of establishments with 250 or more employees" against "only 17 percent of establishments with less than 50 employees". Formal job-skills training: "45 percent of establishments with less than 50 employees" (p.56).
- **Ratio [derived]:** 16-17% productivity against 4.4-11% wages implies a productivity-to-wage ratio of about 1.5 to 3.9, so pay is about 0.26-0.69 × productivity. These come from different studies, not the same sample.

### Shape over time
Not addressed. The paper gives no tenure profile or dose-response curve.

### Differences by group
- Training is concentrated among technical, managerial and highly educated workers, a "'virtuous circle'". Low-educated workers get least, a "vicious circle" (p.55).
- "Production workers are not receiving as much skills upgrading as workers in other occupations" (p.56).
- Small firms train less, because of higher per-worker fixed costs and the lost output of an absent worker (p.56).

### Mechanisms
- **Firm specificity.** US on-the-job training is "generally task-specific" (p.55). "workers in the United States do not seem to gain from previous company-provided on-the-job training when they move to a new employer. This may suggest that a great deal of company-provided training is relatively firm-specific" (pp.55-56).
- **Poaching and turnover risk.** Firm-specific training "is a more sensible investment for firms than more general training" (p.56).
- **Market failures that discourage general training:** credit constraints ("workers cannot easily borrow money for workplace training") and the lack of certification of skills (p.56).
- **Remedies:** coinvestment, certification and codetermination (p.57).
- Training is not "some magic elixir" (p.57).
- Monopsony and rent sharing are not named.

### Stated limitations
- The wage estimates "may be upwardly biased because of self-selection of more 'trainable' or motivated workers" (p.56).
- The productivity evidence is thin and does not control for capital (p.56).

---

## Paper 3: Bishop (1994)

**Citation (as printed):** John H. Bishop, "The Impact of Previous Training on Productivity and Wages", chapter 6 in Lisa M. Lynch (ed.), *Training and the Private Sector: International Comparisons*, University of Chicago Press for the NBER, publication date January 1994. Conference December 15-17, 1991; chapter pages 161-200; ISBN 0-226-49810-7; http://www.nber.org/chapters/c8781 (cover page).

### Data and method
**Two employer surveys:**
- **EOPP-NCRVE Employer Survey, 1982** (pp.167-168; Appendix A pp.194-195).
  - 3,412 establishments; low-wage industries oversampled; 75% response in wave 1.
  - 659 pairs of new hires in the same job at the same firm; about 480 used after missing data.
  - "Seventy percent have fewer than 50 employees" (p.168).
- **NFIB small-business survey, 1987** (pp.169-170).
  - About 11,000 mailed, 2,599 responses.
  - Covers the job with the most hiring (or the most skilled, if several); 1,624 "person A" and 1,403 "person B" records.
  - Analysis N: 1,164 for starting wage and 1,121 for initial productivity.

**Method:**
- Within-job pair differences (eq. 2, p.167), so job and firm characteristics difference out.
- Productivity is a supervisor rating "on a 'scale of zero to 100 where 100 equals the maximum productivity rating any of your employees in (NAME'S) position can obtain'" (p.168). It is assumed to be ratio-scale.
- Outcomes: training time, productivity at several dates, wages, turnover, and a profitability proxy (productivity minus wage minus training cost; Appendix B).
- Results are reduced-form, not structural (p.162).

### Headline quantitative findings
Coefficients are in the tables with t-statistics in parentheses, not standard errors. Percentage effects are in Tables 6.7, 6.8, 6.10 and 6.11.

**EOPP: 5 years of *relevant* experience in place of irrelevant experience, total experience held constant (Table 6.7, p.179; text p.176).**

| Outcome | Effect |
|---|---|
| Productivity, first two weeks | +25%*** |
| Productivity, next twelve weeks | +15%*** |
| Productivity, current for stayers | +8.9%*** |
| Training required | −33%*** total |
| Productivity net of training cost, first 3 months | +44%*** |
| Starting wage | +6.4%*** |
| Current wage, full sample | +5.6%*** |
| Current wage, stayers | +9.8%*** |
| Profitability, first 3 months | +30%*** |
| Productivity minus wage, current (stayers) | +3.3, not significant |
| Discharge or layoff | −65%** |

- Text: "raised productivity by 25 percent in the first two weeks, by 15 percent over the course of the next ten weeks, and by 8-9 percent at the time of the interview. It also reduced training costs by one-third and raised productivity net of training costs by 44 percent" (pp.176, 179).
- On pay: "The additional pay seems to be considerably smaller than the benefit" (p.185).

**NFIB: 10 years of relevant experience in place of irrelevant experience (Table 6.8, p.180, unnumbered; text p.181, p.185).**

| Outcome | Effect |
|---|---|
| Productivity, first week | +32.7%*** |
| Productivity, six months | +20.3%*** |
| Productivity, current | +13.3%*** |
| Required training | −30.7%*** |
| Starting wage | +22.1%*** |
| Current wage | +24.6%*** |
| Profitability, first week | +32.8%*** |
| Profitability, six months | +3.2%* |
| Profitability, current | −6.6, not significant |

**Shrinking advantage.** "The spillover benefit of hiring relevantly trained workers diminished with tenure, apparently approaching zero after a year or so" (p.185).

**Formal training at a previous employer (NFIB, Table 6.8; pp.185-186):**
- *On the job:* initial productivity +9.5%, required training −17.3%, starting wage no effect; "no effect, however, at the time of the interview".
- *Off the job:* no initial effect; suggestions index +37%; current productivity +15.9%. It "does not increase current wage rates however, so profitability increased by 13.8 percent of the wage at six months of tenure and by 18.6 percent of the wage at the time of the interview" (p.186).

**Irrelevant experience:**
- EOPP: 5 years made new hires "3-6 percent less productive" (p.181).
- NFIB: 10 years "reduced productivity after six months of tenure by a statistically significant 6.9 percent" (p.181).
- Wage effect: irrelevant experience still raises wages, by about "one-third of the size of the effect of relevant experience" (p.182).

**School-based vocational training (Tables 6.10-6.11; pp.186-191):**
- *Some college (EOPP):* productivity in the first two weeks +13%, starting wage +8%. The employer's spillover is "16 percent of productivity net of training costs" (p.187).
- *Private voc/tech schools (EOPP):* "20 percent more productive, initially, ... and 7 percent more productive at the time of the interview ... starting wage rates are only 4 percent higher" (pp.187, 191).
- *Military:* 10.6% more productive at six months (p.191).
- *JTPA:* 15.7% more productive at six months (p = .089), but wages 10% below (p = .129) (p.191).

**Productivity ratings rise with tenure:**
- EOPP pairs: mean rating 49.2 in the first two weeks, 64.7 over the next eleven weeks, 75.4 at the interview (pp.168-169).
- NFIB means, relative to six months (Appendix C, p.198): end of second week .72, six months 1.00, current 1.085, at a mean tenure of 1.29 years.
- **[derived]** About 77% of the rise from week 2 to the interview happens in the first six months.

**Spread across workers in the same job:**
- Coefficients of variation of output in the same job: "average .144 for factory operatives, .35 for sales clerks, and .28 for craft workers" (p.161). On p.171 it is .144 for semiskilled blue-collar and .28 for craft.
- Within-firm standard deviation of log wage in the same job: .146 (p.163).

### Shape of returns
- **Experience is concave.** Squared terms on relevant experience are significantly negative. For example, NFIB first-week productivity: .045*** and −.00105*** (Table 6.2, p.173); NFIB current productivity: .023*** and −.00046* (Table 6.4, p.175).
- **Wages are also concave in relevant experience.** Starting wage NFIB: .026*** and −.00052*** (Table 6.3, p.174).
- **The first year of tenure is large.** Current-productivity models include a "Tenure first year" term of .430*** (EOPP, t = 6.86) and .328*** (NFIB, t = 4.98), plus tenure and tenure² terms (Table 6.4, p.175). Most within-job learning therefore happens in year 1.
- **Wage tenure terms are small.** EOPP .045 (t = 1.50), not significant; augmented NFIB .086*** (Table 6.5, p.176).
- **The experience advantage is front-loaded.** It is largest in the first weeks (25-33%) and falls to 8-13% by the interview (Tables 6.7-6.8).
- **Horizon is limited.** "Since members of the sample had fewer than two years of tenure at the time of the interview, it is not possible to say what happens ... in the third and subsequent years" (p.185).

### Differences by occupation and skill
- Results are not split by occupation, apart from the coefficients of variation above (craft .28, semiskilled blue-collar .144).
- Relevance matters more than amount: "it is the occupation- or industry-specific skills that have the greatest impact on productivity" (p.181).
- Effects differ by the type of training provider (private vs public, college vs high school), as in the vocational results above.

### Mechanisms
- **Third-party externalities from on-the-job training.** Training firms lose trainees to poachers. "most firms find it is cheaper to poach trained workers from competitors than to train their own skilled workers" (p.161). On-the-job training sponsored by firm A "also sometimes benefits other employers in the industry" (p.186).
- **Match-specific rents** (p.163).
- **Imperfect information.** Employers often do not know how relevant a hire's past experience is when they hire. "60 percent of recent hires had been selected without a single contact being made with a supervisor on a previous job" (pp.164-165). Productivity "surprises" correlate with relevant experience (Table 6.9). The model of surprises has R² 2.8% (p.193).
- **Bargaining power and reservation wages** (H2, p.165). This is supported for married men vs women and not for Black or Hispanic workers (pp.192-193).
- **Interaction with the workplace.** "Shop-floor practices and technology often constrain the degree to which individual differences in learning ability or competence can generate individual differences in productivity" (p.166). Abler workforces let a firm "introduce profitable changes in technology and work assignments that firm B is unable to introduce" (p.166). This is why within-job (β) and across-job (A) effects differ.
- Monopsony is not named. The closest ideas are local skill-specific markets: "only a few firms in the locality that use these skills ... will not have to pay wages that fully reflect the high productivity" (p.163).

### Stated limitations
- Non-random selection prevents structural estimates; incidental selection biases coefficients toward zero (p.162, fn 1).
- Ratings measure productivity *relative to other workers in the same job*. They are assumed ratio-scale, and measurement error probably *understates* differences (pp.170-171).
- Reports are retrospective (p.171).
- Tenure is short (under 2 years), so there is no long-run evidence (p.185).
- The profitability proxy is partial (fn 4, p.185).
- The NFIB training questions are simplified (pp.169-170).
- Results are sensitive to assumptions on wage/productivity scaling for the experience tests (p.197).

---

## Synthesis for the settlement capability design

### (a) Ratio of productivity gains to wage gains

**Where each requested figure appears:**
- **"7.9%" productivity vs "3.2%" wage tenure returns:** yes, Caplin et al., p.32 (PDF page 33), as quoted above. They are weighted averages across job groups, per year, *before* maximal productivity is reached, and for the **tenure (firm-specific) component only**.
- **Training wage gains 4.4%-11%:** yes, Lynch, p.55, as a cited summary of Lynch (1994). No standard errors or time horizon.
- **Productivity gains 16%-17%:** yes, Lynch, p.56, as a cited summary of "the few studies that do exist". The author calls it "somewhat speculative".

**What the three papers support:**
- **Firm-specific (tenure) learning.** Pay is about 0.3-0.5 × productivity: 7.9 vs 3.2 gives 0.41 [derived]. The "two to three times" range gives 0.33-0.5; the conclusion's "three times" gives 0.33. By job group (Table 7): 4.8/10.8 = 0.44, 2.7/7.8 = 0.35, 1.6/4.8 = 0.33, 1.1/3.0 = 0.37 [derived]. **The owner's pay = 0.4 × output sits inside this range.**
- **Portable (sector-specific) experience.** Pay tracks productivity much more closely. In Table 7, R^W_E (3.5-4.3) is similar to or larger than R^P_E (1.2-5.4), and the authors call the experience returns "similar" (p.32).
- **Total returns (tenure + experience).** R^W/R^P is 8.9/12.0 = 0.74, 7.0/11.3 = 0.62, 5.4/10.1 = 0.53 and 4.6/7.6 = 0.61 [derived, using the Table 6 averages].
- **Formal training (Lynch).** The ratio is about 0.26-0.69 [derived; different studies].
- **Bishop: the gap is mostly transient.**
  - Early in the job, pay is well below the productivity gain: EOPP starting wage +6.4% against first-weeks productivity +25%, about 0.26 [derived].
  - By roughly a year, wage gains match or exceed productivity gains: NFIB current wage +24.6% against current productivity +13.3%.
  - Some kinds of training (off-the-job formal, private voc/tech, military, JTPA) raise productivity with little or no wage effect, so for them the ratio is close to 0.
- **Range across all evidence:** pay/productivity runs from about 0 (some training types) to about 1.8 (Bishop NFIB at the interview). The central, best-identified figure for firm- or settlement-specific capability is about 0.33-0.45.
- **Design reading.** A fixed 0.4 ratio is well supported **for the part of capability that is local or firm-specific**. For portable individual skill, the evidence points to a ratio nearer 0.6-1.0. A ratio that rises with time spent at the capability level (pay catching up with output) is also consistent with Bishop.

### (b) Curve shape
- **Every paper that measures a profile finds it concave or plateauing.**
  - Caplin: maximal productivity is reached within 1 year for 48.5% of jobs and within 5 years for about 90% (Table 2). Prior experience has diminishing returns; about 80% of its tenure-saving comes by 3-4 years and almost all by about 7 years [derived from Table 4].
  - Bishop: a large first-year tenure term (.33-.43); negative squared experience terms; productivity index .72 → 1.00 → 1.085, so about 77% of the observed gain comes in the first six months [derived].
  - Lynch gives no profile.
- **Plateau timing differs by occupation.** Mean years to maximal productivity are 1.5 (unskilled), 2.3 (skilled manual and farming) and 2.9 (high knowledge). The 5+ year jobs grow more slowly each year but more in total.
  - **[derived]** Cumulative log gains are about 12% for 1-year jobs, about 23% for 2-year jobs, about 32% for 3-4 year jobs and about 45% for 5+ year jobs, from R^P × the mean T^Max in Table 4.
- **Comparison with the owner's curve.** It puts 18% of the total gain at level 1, 49% by level 3 and 70% by level 5. That is concave but less front-loaded than the empirical individual learning curves. If a level is roughly a year of accumulated local practice, the evidence would put most of the gain in the first 2-3 levels for unskilled or simple industries and spread it out more for complex crafts.
- The papers do not support any specific mapping from "levels" to years. That mapping is a design choice.

### (c) Differences across occupations
- **Total learning:** skilled and knowledge-heavy jobs take longer to reach the plateau and accumulate a larger total gain. Simple or unskilled jobs reach the plateau fast, in about 1-1.5 years.
- **Firm-specific vs portable share:**
  - Unskilled and simple jobs are dominated by **firm-specific** learning: prior experience substitutes 0.13-0.25 years of tenure per year, and "the bulk of human capital of unskilled workers is acquired on the job" (p.18).
  - Skilled and complex jobs have a larger **portable** (sector-specific) share: up to one-to-one substitution in 5+ year jobs.
- **Farming and skilled manual work are mid-range:** 2.3 years mean, 2 median, in both the survey and the registry (Tables 3 and 9). Mining, smithing and carpentry are not separate categories. The nearest is "Manual labor, skilled" at 2.3; the occupation split is ISCO first digit only.
- **Wage tenure returns run the other way:** larger in short-plateau jobs (4.8%/yr) than in long-plateau jobs (1.1%/yr) (Table 6/7).
- **Spread between workers in the same job is larger for craft than for factory operatives:** CV .28 vs .144 (Bishop p.161).
- Occupation explains only a small part of the variation (adjusted R² 0.059). Firm-level variation within an occupation is large.

### (d) General vs specific capital (people vs place)
- **Both papers that measure it find that firm-specific capital is real and never zero.** Caplin: even 10+ years of experience leaves 0.5-1.1 years of tenure needed (Table 4). Lynch: workers "do not seem to gain from previous company-provided on-the-job training when they move" (pp.55-56).
- **Its share differs by job:**
  - In 1-year jobs, the productivity return to tenure is 10.8 against 1.2 for experience, so about 90% firm-specific [derived].
  - In 5+ year jobs it is 3.0 against 4.6, about 40% firm-specific [derived].
  - Weighted average: 7.9 out of a total R^P of about 7.6-12, so roughly two-thirds firm-specific. **This is my inference only; the paper gives no weighted total R^P.**
- **None of the three papers measures tools, facilities, infrastructure or physical capital.** Lynch explicitly warns that training-productivity estimates do not "control for capital" (p.56). Caplin's "firm-specific human capital" is knowledge held *by workers* about how things work at that employer ("learn how things work under the current employer", p.17), not equipment.
  - The evidence can inform the split between *portable personal skill* and *local know-how*.
  - It gives **no figure** for the share contributed by tools or buildings. Any tool or facility component of capability is a design assumption, not something these papers estimate.
- **Bishop (p.166):** shop-floor practices and technology both constrain and enable how much individual skill turns into output. This supports making the people component and the place component interact, for example capping or gating one by the other, rather than simply adding them.

### (e) Double counting (individual vs organisational learning)
- **Caplin's decomposition is the closest analogue.** R^P = R^P_T (firm-specific, tied to this employer) + R^P_E (portable, carried by the person) (eqs. 2 and 9). The two components add up to the total and each year of tenure is counted once.
- **The design analogue:**
  - Individual worker skill corresponds to the portable component.
  - Settlement capability should correspond to the local, non-portable component: how this place's work is organised, plus any tool or facility factor added by design.
  - Both multipliers should be calibrated so that their **sum (or product) matches the total**. The settlement component should not repeat the worker component's gain.
- **Bishop handles the same problem by within-job differencing.** Comparing two hires in the same job at the same firm removes firm and job effects (β vs A coefficients, pp.166-167), and he notes that across-job estimates "end up being a mixture of the two" (p.167). Population-level estimates that add firm effects to individual effects would double count.
- **Caveat on comparing the two decompositions:** Caplin's productivity decomposition depends on a common log-linear slope and the calibrated x. Wage decompositions show tenure and experience to be "much more substitutable in compensation ... than in productivity" (p.23).
- **No paper measures organisational learning separate from individual workers.** There are no firm-level learning-curve estimates. Any separate settlement-level learning term is unsupported by these three papers.

### (f) Caveats for a medieval game
- **Modern settings.** All the data are modern:
  - Denmark 2020: firm-level bargaining, flexicurity, about 20-25% annual turnover, workers 35+, mostly entry-level occupations.
  - US small business 1982 and 1987, oversampling low-wage industries.
  - US 1990s training literature.

  Wage-setting institutions (collective agreements, deferred pay, anti-poaching) shape the measured productivity-to-pay gaps. Medieval customary wages, guild rules, apprenticeship and household production are not studied in these papers.
- **What "productivity" means.** It is manager-perceived or supervisor-rated output value relative to the best worker in the job, or per-year growth inferred from a model. It is not physical output per unit of material.
  - None of the papers separates "faster work" from "less waste" from "higher quality". Bishop's suggestions index is the only measure of improvement ideas.
  - None of them speaks to raw-material constraints. The rule that productivity never creates raw materials is a design rule that these papers neither support nor contradict; their productivity measures implicitly include quality and value.
- **Horizons are short.** Bishop covers under 2 years of tenure. Caplin stops at maximal productivity, which is mostly 5 years or less. Neither says anything about decades of accumulated craft or settlement tradition.
- **Magnitudes are not transferable as caps.** They are % per year before a plateau (7-12%), cumulative log gains (about 12-45% [derived]), or relative ratings (8-33%). A "+20% at level 10" ceiling is in the same order as the mid-range cumulative figures for 2-4 year jobs, but no paper gives a settlement-wide ceiling.
- **Several figures are second-hand or weak.** Lynch's 4.4-11% and 16-17% are cited summaries without standard errors, and she flags selection bias and missing capital controls. Many of Bishop's percentages are anti-logs of point estimates with mixed significance.
- **Not in the papers:** occupation-specific figures for mining, smithing or carpentry; effects of tools, facilities or infrastructure; organisational (settlement-level) learning curves; and any monopsony analysis.
