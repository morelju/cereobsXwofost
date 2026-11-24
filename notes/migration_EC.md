# Migration from EC: phenology extraction

Legacy code: `EC/02_CODES/Crop modelling/cereobsXwofost/paper/` (scripts 00-05, 99).
New code: `R/cereobs.R`, `R/pheno_curves.R`, `R/pheno_dates.R`, `scripts/01-02`.
Check: `scripts/90_compare_legacy_EC.R` -> `notes/legacy_comparison.csv`, `.png`.
Same input in both cases (`cereobs_pheno.rds`), same option (stale repeats removed).

## What changed

| Topic | Legacy | New |
|---|---|---|
| Campaign | winter crops: window from 15 June y-1 to end of year y, then "last 0" heuristics | campaign = harvest year, cut on 1 September (winter crops) |
| Curve segment | first value > 0 minus one, up to first 100 (or > 80) | last 0 before the rise, up to first maximum (>= 80 %) |
| Stale repeats | all repeated values removed | only repeated values strictly between 0 and 100 % |
| Dates | day of year, manual wrapping at 365 (`year %% 4` for leap years) | `Date` objects throughout |
| Linear 50 % | `lm()` on 2 points, `round()` (half to even) | direct interpolation, half-up rounding |
| Logistic | `SSlogis`, free asymptote, padded with artificial 0 and 100 % points | asymptote fixed at 100 %, no padding |
| Output labels | logistic report: `year_harvest` = calendar year of the last record | `campaign` everywhere |
| Years | 2025 filtered out, though the comment says 2024 | all years kept; incomplete curves flagged (`curve_status`) |

## Results of the comparison

**Grain maize: identical.** Linear dates match exactly (540/540). Logistic dates are
all within 1 day of the legacy ones.

**Soft wheat, linear: identical except for harvest.** 753 of the 754 non-harvest curves
match exactly (1 day off for the last one). **Every legacy linear harvest date is the
previous campaign's harvest** (120/120): the June-15 window starts the curve with
harvest y-1. If legacy wheat harvest dates were used anywhere (e.g. as a proxy for
maturity), they are off by one year.

**Soft wheat, logistic:**
- heading, ear at 1 cm, two nodes: within 2 days of legacy.
- harvest: mostly identical, with a few differences of up to 18 days.
- sowing, emergence, tillering: differences of up to ~50 days, caused by the winter
  plateau (see below). In the legacy report these autumn stages are also labelled with
  the calendar year of the last record, i.e. y-1 for campaign y, so any per-year join
  on that table pairs the wrong campaigns.

Legacy script 05 averages days of year across campaigns. For a stage whose 50 % date
falls in December in some years and in January in others (soft wheat tillering: 11 regions),
that average is meaningless (e.g. mean(355, 10) = 182).

## Open method points (to discuss)

1. **Tillering, and to a lesser extent emergence, are poorly constrained.** Over winter
   the value often stays constant for weeks and then jumps after the January gap (no
   records in ISO weeks 50-1). After stale repeats are removed, 77/129 tillering linear
   dates rest on a bracket longer than 14 days, often 63 days. The linear and logistic
   estimates then differ by more than a week for 24 of these curves. A constant value
   in winter may well be genuine (no progress) rather than stale reporting. Neither
   stage is used by WOFOST, but this must be clear if we report them.
2. **Stale-repeat removal** is applied to all stages. It matters little for the stages
   that WOFOST needs: maize emergence/flowering and wheat emergence/heading.
3. **Logistic fit:** fixing the asymptote at 100 % removes the need for artificial
   padding. The fitted `scale` (days) gives the spread of the stage across fields, a
   possible uncertainty measure for the calibration targets.
4. Campaign 2025 (wheat) is complete only up to tillering in the current input.
