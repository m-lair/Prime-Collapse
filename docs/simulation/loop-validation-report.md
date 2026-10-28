# Prime Collapse — Gameplay Loop Validation Report

Simulated **120 games** = 6 strategies × 2 scenarios × 10 runs each, driving the real `GameState` / `UpgradeManager` / `EventManager` engine (compiled headless via `tools/loop-sim`). Step = 1.0s, event checks = 10/s, cap = 3000s. RNG is the system generator (the engine itself uses unseeded `Double.random`), so exact numbers vary run to run; these distributions describe scripts and are not player difficulty measurements.

## Ending distribution

| Outcome | Count |
|---|---|
| collapse | 10 |
| reform | 75 |
| loop | 35 |
| reformFlagOnly | 0 |
| loopFlagOnly | 0 |
| stagnated | 0 |
| survivedToTimeout | 0 |

## Per strategy × scenario

| Strategy | Scenario | Collapse | Reform met | Loop met | Stagnated | Median collapse t(s) | Median pkgs | Median lifetime\$ |
|---|---|---|---|---|---|---|---|---|
| deliberateLoop | freshInstall | 0 | 0 | 10 | 0 | — | 4401 | $4799 |
| deliberateLoop | restarted | 0 | 0 | 10 | 0 | — | 4401 | $4799 |
| greedy | freshInstall | 4 | 0 | 7 | 0 | 1042 | 3076 | $3962 |
| greedy | restarted | 5 | 0 | 7 | 0 | 990 | 3204 | $3881 |
| ethical | freshInstall | 0 | 10 | 0 | 0 | — | 896 | $1001 |
| ethical | restarted | 0 | 10 | 0 | 0 | — | 1091 | $1170 |
| balanced | freshInstall | 0 | 9 | 1 | 0 | — | 1360 | $1720 |
| balanced | restarted | 0 | 10 | 0 | 0 | — | 1096 | $1346 |
| idle | freshInstall | 0 | 10 | 0 | 0 | — | 978 | $1144 |
| idle | restarted | 0 | 10 | 0 | 0 | — | 857 | $1001 |
| random | freshInstall | 0 | 9 | 1 | 0 | — | 2144 | $3043 |
| random | restarted | 1 | 7 | 3 | 0 | 889 | 1928 | $2554 |

## Pacing (medians, seconds of active play)

| Strategy | Scenario | 1st upgrade | 1st idle income | 100 pkg | 500 pkg | 1500 pkg | \$1000 |
|---|---|---|---|---|---|---|---|
| deliberateLoop | freshInstall | 25 | 1 | 32 | 152 | 457 | 268 |
| deliberateLoop | restarted | 25 | 1 | 32 | 152 | 457 | 268 |
| greedy | freshInstall | 25 | 1 | 33 | 151 | 422 | 268 |
| greedy | restarted | 25 | 1 | 33 | 151 | 427 | 272 |
| ethical | freshInstall | 15 | 1 | 33 | 153 | 401 | 258 |
| ethical | restarted | 15 | 1 | 33 | 153 | 400 | 268 |
| balanced | freshInstall | 15 | 1 | 33 | 154 | 403 | 243 |
| balanced | restarted | 15 | 1 | 33 | 154 | 406 | 243 |
| idle | freshInstall | 60 | 1 | 91 | 376 | — | 569 |
| idle | restarted | 60 | 1 | 91 | 376 | — | 570 |
| random | freshInstall | 15 | 1 | 33 | 154 | 406 | 244 |
| random | restarted | 15 | 1 | 33 | 154 | 410 | 244 |

## Fresh-install economy diagnostic

- New installs are seeded by `SaveManager` via `reset()` (1 worker, `baseWorkerRate = 0.1`), so fresh and restarted games start identically.
- Median fresh-install idle income at 60s: **$0.250/s**.
- Fresh median time-to-first-idle-income: **1s** vs restarted **1s**.

## Events fired across all games

Total events fired: **674** (avg 5.6/game).

| Event | Times fired |
|---|---|
| Market Boom | 351 |
| Competitor Undercuts Prices | 91 |
| Social Media Backlash | 64 |
| Media Spotlight | 63 |
| Tax Audit | 47 |
| Worker Unrest | 38 |
| Workplace Safety Incident | 12 |
| Natural Disaster | 8 |

### Most common choices

| Event → Choice | Count |
|---|---|
| Market Boom → Raise prices temporarily | 255 |
| Market Boom → Keep prices stable for customer loyalty | 96 |
| Social Media Backlash → Issue PR statement without changes | 64 |
| Media Spotlight → Showcase innovation and efficiency | 63 |
| Competitor Undercuts Prices → Focus on quality over price | 57 |
| Tax Audit → Hide questionable deductions | 47 |
| Competitor Undercuts Prices → Spread rumors about competitor quality | 34 |
| Worker Unrest → Ignore their complaints | 26 |
| Worker Unrest → Hold a listening session and shorten shifts | 12 |
| Workplace Safety Incident → Cover it up (legal risk) | 12 |
| Natural Disaster → Use disaster to layoff underperforming workers | 8 |

## Sample transcripts (restarted scenario)

### deliberateLoop

- Outcome: **loop** at 1380s
- Final: 4401 pkgs, $4578 cash, $4799 lifetime, 3 workers, ethics 19.3, perception 17, env 0
- Upgrades (3): Hire Worker, Hire Worker, Improve Packaging
- Events:
    - t=120s — *Market Boom* → Raise prices temporarily (moral -5)
    - t=240s — *Market Boom* → Raise prices temporarily (moral -5)
    - t=360s — *Market Boom* → Raise prices temporarily (moral -5)
    - t=480s — *Market Boom* → Raise prices temporarily (moral -5)
    - t=600s — *Market Boom* → Raise prices temporarily (moral -5)
    - t=720s — *Market Boom* → Raise prices temporarily (moral -5)
    - t=840s — *Market Boom* → Raise prices temporarily (moral -5)
    - t=960s — *Market Boom* → Raise prices temporarily (moral -5)
    - t=1080s — *Market Boom* → Raise prices temporarily (moral -5)
    - t=1200s — *Market Boom* → Raise prices temporarily (moral -5)
    - t=1320s — *Market Boom* → Raise prices temporarily (moral -5)

### greedy

- Outcome: **loop** at 923s
- Final: 3051 pkgs, $91 cash, $3841 lifetime, 8 workers, ethics 22.3, perception 6, env 7
- Upgrades (17): Optimize Logistics, Hire Worker, Hire Worker, Improve Packaging, Hire Worker, Hire Worker, Hire Worker, Automate Sorting, Hire Worker, Rush Delivery, Hire Worker, Employee Surveillance, Aggressive Marketing Campaign, Extended Shifts, Hire Worker, Predictive Maintenance, Hire Worker
- Events:
    - t=121s — *Social Media Backlash* → Issue PR statement without changes (moral -6)
    - t=243s — *Tax Audit* → Hide questionable deductions (moral -7)
    - t=363s — *Social Media Backlash* → Issue PR statement without changes (moral -6)
    - t=485s — *Market Boom* → Raise prices temporarily (moral -5)
    - t=610s — *Media Spotlight* → Showcase innovation and efficiency (moral -2)
    - t=739s — *Market Boom* → Raise prices temporarily (moral -5)
    - t=863s — *Competitor Undercuts Prices* → Spread rumors about competitor quality (moral -8)

### ethical

- Outcome: **reform** at 500s
- Final: 1928 pkgs, $400 cash, $2053 lifetime, 8 workers, ethics 93.8, perception 49, env 0
- Upgrades (12): Safety Placards, Optimize Logistics, Hire Worker, Improve Packaging, Hire Worker, Hire Worker, Basic Training, Hire Worker, Hire Worker, Hire Worker, Hire Worker, Performance Bonuses
- Events:
    - t=133s — *Social Media Backlash* → Issue PR statement without changes (moral -6)
    - t=259s — *Media Spotlight* → Showcase innovation and efficiency (moral -2)
    - t=380s — *Social Media Backlash* → Issue PR statement without changes (moral -6)
    - t=500s — *Competitor Undercuts Prices* → Focus on quality over price (moral 3)

### balanced

- Outcome: **reform** at 365s
- Final: 1343 pkgs, $97 cash, $1678 lifetime, 7 workers, ethics 95.2, perception 75, env 9
- Upgrades (13): Safety Placards, Optimize Logistics, Hire Worker, Improve Packaging, Bulk Material Purchase, Hire Worker, Basic Training, Hire Worker, Hire Worker, Hire Worker, Automate Sorting, Hire Worker, Rush Delivery
- Events:
    - t=120s — *Competitor Undercuts Prices* → Focus on quality over price (moral 3)
    - t=240s — *Media Spotlight* → Showcase innovation and efficiency (moral -2)
    - t=365s — *Market Boom* → Keep prices stable for customer loyalty (moral 3)

### idle

- Outcome: **reform** at 566s
- Final: 854 pkgs, $109 cash, $1001 lifetime, 6 workers, ethics 97.0, perception 70, env 3
- Upgrades (8): Optimize Logistics, Hire Worker, Improve Packaging, Hire Worker, Hire Worker, Hire Worker, Hire Worker, Automate Sorting
- Events:
    - t=122s — *Market Boom* → Keep prices stable for customer loyalty (moral 3)
    - t=243s — *Competitor Undercuts Prices* → Focus on quality over price (moral 3)
    - t=365s — *Market Boom* → Keep prices stable for customer loyalty (moral 3)
    - t=488s — *Competitor Undercuts Prices* → Focus on quality over price (moral 3)

### random

- Outcome: **reform** at 600s
- Final: 2206 pkgs, $14 cash, $3175 lifetime, 8 workers, ethics 63.6, perception 42, env 9
- Upgrades (18): Safety Placards, Improve Packaging, Hire Worker, Optimize Logistics, Bulk Material Purchase, Hire Worker, Hire Worker, Basic Training, Hire Worker, Hire Worker, Hire Worker, Automate Sorting, Rush Delivery, Aggressive Marketing Campaign, Hire Worker, Employee Surveillance, Extended Shifts, Performance Bonuses
- Events:
    - t=121s — *Market Boom* → Raise prices temporarily (moral -5)
    - t=251s — *Media Spotlight* → Showcase innovation and efficiency (moral -2)
    - t=375s — *Tax Audit* → Hide questionable deductions (moral -7)
    - t=496s — *Worker Unrest* → Hold a listening session and shorten shifts (moral 2)
