# Prime Collapse — Gameplay Loop Validation Report

Simulated **100 games** = 5 strategies × 2 scenarios × 10 runs each, driving the real `GameState` / `UpgradeManager` / `EventManager` engine (compiled headless via `tools/loop-sim`). Step = 1.0s, event checks = 10/s, cap = 3000s. RNG is the system generator (the engine itself uses unseeded `Double.random`), so exact numbers vary run to run; distributions at n=100 are stable.

## Ending distribution

| Outcome | Count |
|---|---|
| collapse | 53 |
| reformFlagOnly | 21 |
| loopFlagOnly | 0 |
| stagnated | 0 |
| survivedToTimeout | 26 |

## Per strategy × scenario

| Strategy | Scenario | Collapse | Reform met | Loop met | Stagnated | Median collapse t(s) | Median pkgs | Median lifetime\$ |
|---|---|---|---|---|---|---|---|---|
| greedy | freshInstall | 10 | 1 | 0 | 0 | 864 | 2622 | $3305 |
| greedy | restarted | 10 | 0 | 0 | 0 | 921 | 3032 | $3869 |
| ethical | freshInstall | 4 | 0 | 0 | 0 | 2152 | 9934 | $10756 |
| ethical | restarted | 4 | 5 | 0 | 0 | 1656 | 56240 | $75124 |
| balanced | freshInstall | 3 | 6 | 0 | 0 | 1221 | 43558 | $96428 |
| balanced | restarted | 3 | 8 | 0 | 0 | 982 | 1186154 | $2543345 |
| idle | freshInstall | 1 | 0 | 0 | 0 | 2686 | 3318 | $3872 |
| idle | restarted | 1 | 0 | 0 | 0 | 2432 | 2510 | $2848 |
| random | freshInstall | 7 | 3 | 0 | 0 | 986 | 6286 | $9609 |
| random | restarted | 10 | 7 | 0 | 0 | 2263 | 883479 | $2368680 |

## Pacing (medians, seconds of active play)

| Strategy | Scenario | 1st upgrade | 1st idle income | 100 pkg | 500 pkg | 1500 pkg | \$1000 |
|---|---|---|---|---|---|---|---|
| greedy | freshInstall | 20 | 40 | 34 | 165 | 488 | 1250 |
| greedy | restarted | 25 | 1 | 33 | 150 | 414 | 1142 |
| ethical | freshInstall | 20 | 55 | 34 | 165 | 478 | — |
| ethical | restarted | 15 | 1 | 33 | 152 | 379 | 2276 |
| balanced | freshInstall | 20 | 55 | 34 | 165 | 486 | 2381 |
| balanced | restarted | 15 | 1 | 33 | 154 | 392 | 1276 |
| idle | freshInstall | 55 | 120 | 100 | 478 | 1328 | — |
| idle | restarted | 60 | 1 | 91 | 371 | 1154 | — |
| random | freshInstall | 20 | 55 | 34 | 166 | 485 | 2341 |
| random | restarted | 15 | 1 | 33 | 154 | 400 | 1283 |

## Fresh-install economy diagnostic

- A brand-new install never calls `reset()`, so it keeps `GameState()` defaults: **0 workers, `baseWorkerRate = 0.0`**.
- Median fresh-install idle income at 60s: **$0.021/s**.
- Fresh median time-to-first-idle-income: **55s** vs restarted **1s**.

## Events fired across all games

Total events fired: **1777** (avg 17.8/game).

| Event | Times fired |
|---|---|
| Market Boom | 267 |
| Competitor Undercuts Prices | 266 |
| Tax Audit | 208 |
| Media Spotlight | 200 |
| Natural Disaster | 154 |
| Environmental Inspection | 147 |
| Social Media Backlash | 145 |
| Workplace Safety Incident | 114 |
| Labor Law Changes | 97 |
| Worker Unrest | 93 |
| Supply Chain Disruption | 25 |
| Hostile Takeover Attempt | 15 |
| Charity Partnership Offer | 12 |
| Corporate Espionage Opportunity | 11 |
| Automation Breakthrough | 8 |
| Employee Training Opportunity | 8 |
| Systemic Industry Crisis | 7 |

### Most common choices

| Event → Choice | Count |
|---|---|
| Market Boom → Keep prices stable for customer loyalty | 219 |
| Competitor Undercuts Prices → Focus on quality over price | 214 |
| Tax Audit → Hide questionable deductions | 194 |
| Media Spotlight → Showcase innovation and efficiency | 183 |
| Social Media Backlash → Issue PR statement without changes | 145 |
| Natural Disaster → Use disaster to layoff underperforming workers | 145 |
| Environmental Inspection → Upgrade for full compliance ($5000) | 130 |
| Workplace Safety Incident → Cover it up (legal risk) | 107 |
| Worker Unrest → Ignore their complaints | 90 |
| Labor Law Changes → Implement full compliance | 77 |
| Market Boom → Raise prices temporarily | 48 |
| Competitor Undercuts Prices → Spread rumors about competitor quality | 43 |
| Labor Law Changes → Minimal compliance with loopholes | 19 |
| Media Spotlight → Highlight worker treatment | 17 |
| Environmental Inspection → Cut corners with minimal upgrades ($1000) | 16 |

## Sample transcripts (restarted scenario)

### greedy

- Outcome: **collapse** at 970s
- Final: 3118 pkgs, $496 cash, $3964 lifetime, 9 workers, ethics 0.0, perception 0, env 0
- Upgrades (22): Optimize Logistics, Hire Worker, Hire Worker, Improve Packaging, Hire Worker, Hire Worker, Hire Worker, Automate Sorting, Hire Worker, Rush Delivery, Hire Worker, Employee Surveillance, Aggressive Marketing Campaign, Extended Shifts, Hire Worker, Hire Worker, Predictive Maintenance, Hire Worker, Hire Worker, Hire Worker, Child Labor Loopholes, Hire Worker
- Events:
    - t=120s — *Social Media Backlash* → Issue PR statement without changes (moral -6)
    - t=241s — *Competitor Undercuts Prices* → Spread rumors about competitor quality (moral -8)
    - t=362s — *Worker Unrest* → Ignore their complaints (moral -8)
    - t=484s — *Media Spotlight* → Showcase innovation and efficiency (moral -2)
    - t=604s — *Competitor Undercuts Prices* → Spread rumors about competitor quality (moral -8)
    - t=729s — *Social Media Backlash* → Issue PR statement without changes (moral -6)
    - t=849s — *Environmental Inspection* → Upgrade for full compliance ($5000) (moral 8)
    - t=970s — *Workplace Safety Incident* → Cover it up (legal risk) (moral -10)

### ethical

- Outcome: **reformFlagOnly** at 3000s
- Final: 118303 pkgs, $247 cash, $162674 lifetime, 19 workers, ethics 100.0, perception 100, env 0
- Upgrades (102): Safety Placards, Optimize Logistics, Hire Worker, Improve Packaging, Hire Worker, Hire Worker, Basic Training, Hire Worker, Hire Worker, Hire Worker, Hire Worker, Performance Bonuses, Hire Worker, Hire Worker, Performance Bonuses, Performance Bonuses, Performance Bonuses, Performance Bonuses, Performance Bonuses, Performance Bonuses, Performance Bonuses, Performance Bonuses, Hire Worker, Hire Worker, Performance Bonuses, Performance Bonuses, Performance Bonuses, Performance Bonuses, Performance Bonuses, Performance Bonuses, Performance Bonuses, Performance Bonuses, Hire Worker, Performance Bonuses, Performance Bonuses, Performance Bonuses, Performance Bonuses, Performance Bonuses, Performance Bonuses, Performance Bonuses
- Events:
    - t=128s — *Market Boom* → Keep prices stable for customer loyalty (moral 3)
    - t=248s — *Competitor Undercuts Prices* → Focus on quality over price (moral 3)
    - t=368s — *Tax Audit* → Hide questionable deductions (moral -7)
    - t=489s — *Market Boom* → Keep prices stable for customer loyalty (moral 3)
    - t=609s — *Social Media Backlash* → Issue PR statement without changes (moral -6)
    - t=735s — *Competitor Undercuts Prices* → Focus on quality over price (moral 3)
    - t=863s — *Social Media Backlash* → Issue PR statement without changes (moral -6)
    - t=983s — *Labor Law Changes* → Implement full compliance (moral 7)
    - t=1105s — *Media Spotlight* → Showcase innovation and efficiency (moral -2)
    - t=1228s — *Natural Disaster* → Use disaster to layoff underperforming workers (moral -10)
    - t=1354s — *Market Boom* → Keep prices stable for customer loyalty (moral 3)
    - t=1475s — *Labor Law Changes* → Implement full compliance (moral 7)

### balanced

- Outcome: **reformFlagOnly** at 3000s
- Final: 2032443 pkgs, $4107385 cash, $4310760 lifetime, 36 workers, ethics 74.8, perception 94, env 5
- Upgrades (136): Safety Placards, Optimize Logistics, Hire Worker, Improve Packaging, Bulk Material Purchase, Hire Worker, Basic Training, Hire Worker, Hire Worker, Hire Worker, Automate Sorting, Hire Worker, Rush Delivery, Employee Surveillance, Aggressive Marketing Campaign, Hire Worker, Extended Shifts, Performance Bonuses, Hire Worker, Predictive Maintenance, Child Labor Loopholes, Hire Worker, Performance Bonuses, Hire Worker, Hire Worker, Hire Worker, Performance Bonuses, Performance Bonuses, Performance Bonuses, Performance Bonuses, Hire Worker, Hire Worker, Performance Bonuses, Performance Bonuses, Performance Bonuses, Performance Bonuses, Performance Bonuses, Performance Bonuses, Performance Bonuses, Performance Bonuses
- Events:
    - t=123s — *Market Boom* → Keep prices stable for customer loyalty (moral 3)
    - t=254s — *Market Boom* → Keep prices stable for customer loyalty (moral 3)
    - t=376s — *Tax Audit* → Hide questionable deductions (moral -7)
    - t=499s — *Tax Audit* → Hide questionable deductions (moral -7)
    - t=623s — *Tax Audit* → Hide questionable deductions (moral -7)
    - t=746s — *Competitor Undercuts Prices* → Focus on quality over price (moral 3)
    - t=876s — *Natural Disaster* → Use disaster to layoff underperforming workers (moral -10)
    - t=1000s — *Tax Audit* → Hide questionable deductions (moral -7)
    - t=1126s — *Natural Disaster* → Use disaster to layoff underperforming workers (moral -10)
    - t=1247s — *Labor Law Changes* → Implement full compliance (moral 7)
    - t=1376s — *Tax Audit* → Hide questionable deductions (moral -7)
    - t=1497s — *Corporate Espionage Opportunity* → Decline the offer (moral 3)

### idle

- Outcome: **survivedToTimeout** at 3000s
- Final: 3530 pkgs, $8 cash, $4098 lifetime, 5 workers, ethics 84.8, perception 44, env 0
- Upgrades (34): Optimize Logistics, Hire Worker, Improve Packaging, Hire Worker, Hire Worker, Hire Worker, Hire Worker, Automate Sorting, Hire Worker, Hire Worker, Hire Worker, Hire Worker, Performance Bonuses, Hire Worker, Hire Worker, Hire Worker, Hire Worker, Hire Worker, Hire Worker, Hire Worker, Hire Worker, Hire Worker, Hire Worker, Hire Worker, Hire Worker, Hire Worker, Hire Worker, Hire Worker, Hire Worker, Hire Worker, Predictive Maintenance, Hire Worker, Hire Worker, Hire Worker
- Events:
    - t=120s — *Market Boom* → Keep prices stable for customer loyalty (moral 3)
    - t=241s — *Market Boom* → Keep prices stable for customer loyalty (moral 3)
    - t=364s — *Market Boom* → Keep prices stable for customer loyalty (moral 3)
    - t=495s — *Environmental Inspection* → Upgrade for full compliance ($5000) (moral 8)
    - t=624s — *Competitor Undercuts Prices* → Focus on quality over price (moral 3)
    - t=744s — *Environmental Inspection* → Upgrade for full compliance ($5000) (moral 8)
    - t=865s — *Natural Disaster* → Use disaster to layoff underperforming workers (moral -10)
    - t=990s — *Media Spotlight* → Showcase innovation and efficiency (moral -2)
    - t=1111s — *Workplace Safety Incident* → Cover it up (legal risk) (moral -10)
    - t=1236s — *Competitor Undercuts Prices* → Focus on quality over price (moral 3)
    - t=1361s — *Natural Disaster* → Use disaster to layoff underperforming workers (moral -10)
    - t=1491s — *Media Spotlight* → Showcase innovation and efficiency (moral -2)

### random

- Outcome: **collapse** at 2936s
- Final: 1961556 pkgs, $4504240 cash, $4591748 lifetime, 19 workers, ethics 0.0, perception 6, env 55
- Upgrades (136): Safety Placards, Improve Packaging, Hire Worker, Optimize Logistics, Bulk Material Purchase, Hire Worker, Basic Training, Hire Worker, Hire Worker, Hire Worker, Automate Sorting, Hire Worker, Rush Delivery, Aggressive Marketing Campaign, Hire Worker, Employee Surveillance, Hire Worker, Hire Worker, Extended Shifts, Performance Bonuses, Predictive Maintenance, Child Labor Loopholes, Hire Worker, Hire Worker, Performance Bonuses, Performance Bonuses, Performance Bonuses, Performance Bonuses, Performance Bonuses, Performance Bonuses, Performance Bonuses, Performance Bonuses, Performance Bonuses, Performance Bonuses, Performance Bonuses, Performance Bonuses, Performance Bonuses, Performance Bonuses, Hire Worker, Performance Bonuses
- Events:
    - t=120s — *Market Boom* → Raise prices temporarily (moral -5)
    - t=244s — *Market Boom* → Keep prices stable for customer loyalty (moral 3)
    - t=370s — *Natural Disaster* → Use disaster to layoff underperforming workers (moral -10)
    - t=492s — *Workplace Safety Incident* → Cover it up (legal risk) (moral -10)
    - t=613s — *Competitor Undercuts Prices* → Spread rumors about competitor quality (moral -8)
    - t=733s — *Labor Law Changes* → Implement full compliance (moral 7)
    - t=856s — *Labor Law Changes* → Implement full compliance (moral 7)
    - t=976s — *Competitor Undercuts Prices* → Spread rumors about competitor quality (moral -8)
    - t=1096s — *Competitor Undercuts Prices* → Focus on quality over price (moral 3)
    - t=1217s — *Supply Chain Disruption* → Absorb the costs temporarily (moral 4)
    - t=1340s — *Environmental Inspection* → Cut corners with minimal upgrades ($1000) (moral -5)
    - t=1464s — *Tax Audit* → Full transparency with records (moral 5)
