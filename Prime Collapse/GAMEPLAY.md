# Prime Collapse: Gameplay Plan

## Current State Overview

### Core Game Loop
1. **Manual Shipping Phase**
   - Player taps to ship packages (1 package = $1)
   - Initial gameplay is fully manual with no automation

2. **Early Automation Phase**
   - Player hires workers to begin automation
   - Automation rate builds gradually (packages shipped automatically per second)
   - Player balances between ethical and unethical upgrades

3. **Mid-Game Decisions**
   - Player chooses between paths:
     - Ethical path (low moral decay, moderate profits)
     - Balanced path (medium moral decay, higher profits)
     - Unethical path (high moral decay, highest profits but risk of collapse)

4. **Late Game Phase**
   - Player approaches one of three endings based on their choices

### Game Stats & Metrics
- **Packages Shipped**: Core progression metric
- **Money**: Currency for purchasing upgrades
- **Workers**: Determines base automation capability
- **Automation Rate**: Packages per second shipped automatically
- **Moral Decay**: 0-100 scale indicating ethical standing
- **Ethical Choices**: Counter of ethical upgrades chosen

### Ending Conditions

1. **Reform Ending** (Ethical Victory)
   - Requirements:
     - 5+ ethical choices made
     - Moral decay under 50
     - $1,000+ earned
   - Visuals: Green background with light rays and confetti

2. **Loop Ending** (Balanced Approach)
   - Requirements:
     - Moral decay between 75-85
     - $2,500+ earned
     - 1,500+ packages shipped
     - 3+ workers hired
   - Important: This state is unstable and difficult to maintain
   - After 60 seconds in Loop state, moral decay begins increasing
   - Visuals: Blue background with circular patterns

3. **Collapse Ending** (Failure State)
   - Triggered when moral decay reaches 100
   - Shows economic collapse effects and warnings
   - Visual effects: Red background with falling debris

### Player Feedback
- Dashboard shows progress toward each ending
- Ethics meter indicates moral standing
- Visual effects intensify as moral decay increases
- Haptic feedback on important events

### Current Balance
- Reform ending requires consistent ethical choices
- Loop ending is challenging to achieve and maintain
- Collapse is the default outcome if moral decay isn't managed
- Game is designed for ~5-15 minute play sessions

## Upgrade Progression

### Early Game Upgrades
- Hire Worker: Basic automation boost with minimal ethical impact
- Improve Packaging: Increased efficiency with neutral ethical standing
- Basic Training: Small automation boost with positive ethical impact

### Mid Game Upgrades
- Rush Delivery: Moderate automation boost with slight ethical impact
- Extended Shifts: Higher production but increased moral decay
- Automate Sorting: Efficiency improvement with neutral ethical standing

### Late Game Upgrades
- AI Optimization: Major automation boost with significant moral impact
- Remove Worker Breaks: Large production boost but severe ethical concerns
- Sustainable Practices: Moderate boost with positive ethical impact

## Gameplay Tips

- Balance ethical and unethical upgrades to navigate toward desired ending
- The dashboard is key to monitoring progress toward each ending type
- The Loop ending requires precise management of the moral decay meter
- Ethical upgrades typically provide less immediate benefit but prevent collapse
- Unethical upgrades offer greater short-term gains but accelerate toward collapse 