# Prime Collapse — Gameplay Loop Validation Report

Simulated **100 games** = 5 strategies × 2 scenarios × 10 runs each, driving the real `GameState` / `UpgradeManager` / `EventManager` engine (compiled headless via `tools/loop-sim`). Step = 1.0s, event checks = 10/s, cap = 3000s. RNG is the system generator (the engine itself uses unseeded `Double.random`), so exact numbers vary run to run; distributions at n=100 are stable.

## Ending distribution

| Outcome | Count |
|---|---|
| collapse | 67 |
| reform | 16 |
| loop | 0 |
| reformFlagOnly | 0 |
| loopFlagOnly | 0 |
| stagnated | 0 |
| survivedToTimeout | 17 |

## Per strategy × scenario

| Strategy | Scenario | Collapse | Reform met | Loop met | Stagnated | Median collapse t(s) | Median pkgs | Median lifetime\$ |
|---|---|---|---|---|---|---|---|---|
| greedy | freshInstall | 10 | 0 | 0 | 0 | 1304 | 4166 | $5163 |
| greedy | restarted | 10 | 0 | 0 | 0 | 1234 | 4000 | $5208 |
| ethical | freshInstall | 4 | 6 | 0 | 0 | 2336 | 6686 | $8098 |
| ethical | restarted | 8 | 2 | 0 | 0 | 1776 | 6349 | $7087 |
| balanced | freshInstall | 6 | 4 | 0 | 0 | 1256 | 5322 | $9606 |
| balanced | restarted | 7 | 3 | 0 | 0 | 1237 | 4798 | $8674 |
| idle | freshInstall | 1 | 0 | 0 | 0 | 2969 | 2842 | $3424 |
| idle | restarted | 2 | 0 | 0 | 0 | 2588 | 2822 | $3418 |
| random | freshInstall | 10 | 0 | 0 | 0 | 1356 | 4352 | $6427 |
| random | restarted | 9 | 1 | 0 | 0 | 1110 | 3740 | $5299 |

## Pacing (medians, seconds of active play)

| Strategy | Scenario | 1st upgrade | 1st idle income | 100 pkg | 500 pkg | 1500 pkg | \$1000 |
|---|---|---|---|---|---|---|---|
| greedy | freshInstall | 25 | 1 | 33 | 151 | 426 | — |
| greedy | restarted | 25 | 1 | 33 | 151 | 430 | — |
| ethical | freshInstall | 15 | 1 | 33 | 153 | 394 | 1445 |
| ethical | restarted | 15 | 1 | 33 | 153 | 395 | 1350 |
| balanced | freshInstall | 15 | 1 | 33 | 154 | 403 | 1392 |
| balanced | restarted | 15 | 1 | 33 | 154 | 404 | 1033 |
| idle | freshInstall | 60 | 1 | 91 | 376 | 1104 | — |
| idle | restarted | 60 | 1 | 91 | 376 | 1102 | — |
| random | freshInstall | 15 | 1 | 33 | 154 | 410 | — |
| random | restarted | 15 | 1 | 33 | 154 | 408 | 1004 |

## Fresh-install economy diagnostic

- New installs are seeded by `SaveManager` via `reset()` (1 worker, `baseWorkerRate = 0.1`), so fresh and restarted games start identically.
- Median fresh-install idle income at 60s: **$0.250/s**.
- Fresh median time-to-first-idle-income: **1s** vs restarted **1s**.

## Events fired across all games

Total events fired: **1407** (avg 14.1/game).

| Event | Times fired |
|---|---|
| Market Boom | 258 |
| Competitor Undercuts Prices | 211 |
| Media Spotlight | 194 |
| Tax Audit | 180 |
| Social Media Backlash | 139 |
| Worker Unrest | 134 |
| Environmental Inspection | 125 |
| Workplace Safety Incident | 81 |
| Natural Disaster | 64 |
| Labor Law Changes | 21 |

### Most common choices

| Event → Choice | Count |
|---|---|
| Market Boom → Keep prices stable for customer loyalty | 217 |
| Media Spotlight → Showcase innovation and efficiency | 193 |
| Tax Audit → Hide questionable deductions | 176 |
| Competitor Undercuts Prices → Focus on quality over price | 160 |
| Social Media Backlash → Issue PR statement without changes | 139 |
| Worker Unrest → Ignore their complaints | 134 |
| Environmental Inspection → Upgrade for full compliance ($5000) | 125 |
| Workplace Safety Incident → Cover it up (legal risk) | 79 |
| Natural Disaster → Use disaster to layoff underperforming workers | 64 |
| Competitor Undercuts Prices → Spread rumors about competitor quality | 51 |
| Market Boom → Raise prices temporarily | 41 |
| Labor Law Changes → Implement full compliance | 21 |
| Tax Audit → Full transparency with records | 4 |
| Workplace Safety Incident → Minimum required fixes ($800) | 2 |
| Media Spotlight → Highlight worker treatment | 1 |

## Sample transcripts (restarted scenario)

### greedy

- Outcome: **collapse** at 920s
- Final: 3067 pkgs, $208 cash, $3892 lifetime, 7 workers, ethics 0.0, perception 0, env 7
- Upgrades (18): Optimize Logistics, Hire Worker, Hire Worker, Improve Packaging, Hire Worker, Hire Worker, Hire Worker, Automate Sorting, Hire Worker, Rush Delivery, Hire Worker, Employee Surveillance, Aggressive Marketing Campaign, Extended Shifts, Hire Worker, Hire Worker, Predictive Maintenance, Child Labor Loopholes
- Events:
    - t=121s — *Market Boom* → Raise prices temporarily (moral -5)
    - t=241s — *Tax Audit* → Hide questionable deductions (moral -7)
    - t=361s — *Market Boom* → Raise prices temporarily (moral -5)
    - t=481s — *Media Spotlight* → Showcase innovation and efficiency (moral -2)
    - t=603s — *Social Media Backlash* → Issue PR statement without changes (moral -6)
    - t=723s — *Workplace Safety Incident* → Cover it up (legal risk) (moral -10)
    - t=846s — *Worker Unrest* → Ignore their complaints (moral -8)

### ethical

- Outcome: **collapse** at 1614s
- Final: 6504 pkgs, $542 cash, $6828 lifetime, 12 workers, ethics 0.0, perception 0, env 0
- Upgrades (17): Safety Placards, Optimize Logistics, Hire Worker, Improve Packaging, Hire Worker, Hire Worker, Basic Training, Hire Worker, Hire Worker, Hire Worker, Hire Worker, Performance Bonuses, Hire Worker, Hire Worker, Performance Bonuses, Hire Worker, Hire Worker
- Events:
    - t=126s — *Competitor Undercuts Prices* → Focus on quality over price (moral 3)
    - t=267s — *Tax Audit* → Hide questionable deductions (moral -7)
    - t=388s — *Social Media Backlash* → Issue PR statement without changes (moral -6)
    - t=509s — *Media Spotlight* → Showcase innovation and efficiency (moral -2)
    - t=629s — *Tax Audit* → Hide questionable deductions (moral -7)
    - t=756s — *Social Media Backlash* → Issue PR statement without changes (moral -6)
    - t=880s — *Workplace Safety Incident* → Cover it up (legal risk) (moral -10)
    - t=1001s — *Social Media Backlash* → Issue PR statement without changes (moral -6)
    - t=1126s — *Social Media Backlash* → Issue PR statement without changes (moral -6)
    - t=1246s — *Media Spotlight* → Showcase innovation and efficiency (moral -2)
    - t=1372s — *Workplace Safety Incident* → Cover it up (legal risk) (moral -10)
    - t=1492s — *Labor Law Changes* → Implement full compliance (moral 7)

### balanced

- Outcome: **collapse** at 1132s
- Final: 3687 pkgs, $178 cash, $4958 lifetime, 4 workers, ethics 0.0, perception 0, env 0
- Upgrades (24): Safety Placards, Optimize Logistics, Hire Worker, Improve Packaging, Bulk Material Purchase, Hire Worker, Basic Training, Hire Worker, Hire Worker, Hire Worker, Automate Sorting, Hire Worker, Rush Delivery, Employee Surveillance, Aggressive Marketing Campaign, Extended Shifts, Predictive Maintenance, Child Labor Loopholes, Hire Worker, Hire Worker, Hire Worker, Hire Worker, Hire Worker, Hire Worker
- Events:
    - t=130s — *Social Media Backlash* → Issue PR statement without changes (moral -6)
    - t=259s — *Social Media Backlash* → Issue PR statement without changes (moral -6)
    - t=390s — *Worker Unrest* → Ignore their complaints (moral -8)
    - t=510s — *Worker Unrest* → Ignore their complaints (moral -8)
    - t=630s — *Tax Audit* → Hide questionable deductions (moral -7)
    - t=759s — *Environmental Inspection* → Upgrade for full compliance ($5000) (moral 8)
    - t=887s — *Tax Audit* → Hide questionable deductions (moral -7)
    - t=1009s — *Market Boom* → Keep prices stable for customer loyalty (moral 3)
    - t=1132s — *Tax Audit* → Hide questionable deductions (moral -7)

### idle

- Outcome: **collapse** at 2703s
- Final: 2481 pkgs, $26 cash, $2624 lifetime, 4 workers, ethics 0.0, perception 0, env 0
- Upgrades (14): Optimize Logistics, Hire Worker, Improve Packaging, Hire Worker, Hire Worker, Hire Worker, Hire Worker, Automate Sorting, Hire Worker, Hire Worker, Hire Worker, Hire Worker, Hire Worker, Hire Worker
- Events:
    - t=122s — *Market Boom* → Keep prices stable for customer loyalty (moral 3)
    - t=245s — *Market Boom* → Keep prices stable for customer loyalty (moral 3)
    - t=367s — *Competitor Undercuts Prices* → Focus on quality over price (moral 3)
    - t=488s — *Tax Audit* → Hide questionable deductions (moral -7)
    - t=609s — *Tax Audit* → Hide questionable deductions (moral -7)
    - t=737s — *Tax Audit* → Hide questionable deductions (moral -7)
    - t=859s — *Market Boom* → Keep prices stable for customer loyalty (moral 3)
    - t=980s — *Tax Audit* → Hide questionable deductions (moral -7)
    - t=1100s — *Social Media Backlash* → Issue PR statement without changes (moral -6)
    - t=1223s — *Worker Unrest* → Ignore their complaints (moral -8)
    - t=1345s — *Media Spotlight* → Showcase innovation and efficiency (moral -2)
    - t=1465s — *Media Spotlight* → Showcase innovation and efficiency (moral -2)

### random

- Outcome: **reform** at 1004s
- Final: 4297 pkgs, $1012 cash, $7816 lifetime, 12 workers, ethics 66.0, perception 60, env 8
- Upgrades (25): Safety Placards, Improve Packaging, Hire Worker, Optimize Logistics, Bulk Material Purchase, Hire Worker, Hire Worker, Basic Training, Hire Worker, Hire Worker, Automate Sorting, Hire Worker, Rush Delivery, Hire Worker, Employee Surveillance, Extended Shifts, Aggressive Marketing Campaign, Performance Bonuses, Predictive Maintenance, Hire Worker, Hire Worker, Performance Bonuses, Hire Worker, Hire Worker, Performance Bonuses
- Events:
    - t=125s — *Competitor Undercuts Prices* → Focus on quality over price (moral 3)
    - t=256s — *Competitor Undercuts Prices* → Focus on quality over price (moral 3)
    - t=376s — *Market Boom* → Keep prices stable for customer loyalty (moral 3)
    - t=501s — *Market Boom* → Keep prices stable for customer loyalty (moral 3)
    - t=624s — *Competitor Undercuts Prices* → Focus on quality over price (moral 3)
    - t=747s — *Competitor Undercuts Prices* → Focus on quality over price (moral 3)
    - t=868s — *Competitor Undercuts Prices* → Spread rumors about competitor quality (moral -8)
    - t=988s — *Workplace Safety Incident* → Cover it up (legal risk) (moral -10)
