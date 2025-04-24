# Game Center Integration Guide for Prime Collapse

This guide helps you set up Game Center leaderboards and achievements for Prime Collapse in App Store Connect.

## Prerequisites

1. An Apple Developer account
2. Access to App Store Connect
3. Your app registered in App Store Connect with Game Center capability enabled

## Setting Up Game Center in App Store Connect

1. Sign in to [App Store Connect](https://appstoreconnect.apple.com/)
2. Navigate to "My Apps" and select your Prime Collapse app
3. Go to the "Features" tab
4. Select "Game Center" from the left sidebar

## Leaderboards Setup

Create the following leaderboards:

### 1. Total Packages Shipped
- **Reference Name**: Total Packages Shipped
- **ID**: `total_packages_shipped`
- **Format**: Integer
- **Sort Order**: High to Low
- **Score Submission**: Allow only higher scores
- **Icon**: Use a package/box icon
- **Localization**: Add descriptions for all supported languages

### 2. Total Money Earned
- **Reference Name**: Total Money Earned
- **ID**: `total_money_earned`
- **Format**: Integer
- **Sort Order**: High to Low
- **Score Submission**: Allow only higher scores
- **Icon**: Use a money/dollar icon
- **Localization**: Add descriptions for all supported languages

### 3. Highest Ethics Score
- **Reference Name**: Highest Ethics Score
- **ID**: `highest_ethics_score`
- **Format**: Integer
- **Sort Order**: High to Low
- **Score Submission**: Allow only higher scores
- **Icon**: Use an ethics/balance icon
- **Localization**: Add descriptions for all supported languages

### 4. Packages Per Second
- **Reference Name**: Packages Per Second
- **ID**: `packages_per_second`
- **Format**: Integer (Note: The actual value is multiplied by 100 in code to preserve 2 decimal places)
- **Sort Order**: High to Low
- **Score Submission**: Allow only higher scores
- **Icon**: Use a speed/clock icon
- **Localization**: Add descriptions for all supported languages

### 5. Total Workers Hired
- **Reference Name**: Total Workers Hired
- **ID**: `total_workers_hired`
- **Format**: Integer
- **Sort Order**: High to Low
- **Score Submission**: Allow only higher scores
- **Icon**: Use a worker/person icon
- **Localization**: Add descriptions for all supported languages

## Achievements Setup

Create the following achievements:

### Core Achievements

#### 1. First Worker
- **Reference Name**: First Worker Hired
- **ID**: `first_worker_hired`
- **Points**: 10
- **Hidden**: No
- **Description**: "Hire your first worker and begin your journey to automation."
- **Icon**: Worker icon

#### 2. Automation Milestone
- **Reference Name**: Automation Milestone
- **ID**: `automation_milestone`
- **Points**: 20
- **Hidden**: No
- **Description**: "Reach a production rate of 10 packages per second."
- **Icon**: Automation/robot icon

#### 3. Ethical Choices
- **Reference Name**: Ethical Choices
- **ID**: `ethical_choices`
- **Points**: 30
- **Hidden**: No
- **Description**: "Make 5 ethical business decisions."
- **Icon**: Ethics/morality icon

#### 4. Economic Collapse
- **Reference Name**: Economic Collapse
- **ID**: `economic_collapse`
- **Points**: 25
- **Hidden**: Yes
- **Description**: "Experience economic collapse due to unethical business practices."
- **Icon**: Collapse/downfall icon

#### 5. Reform Ending
- **Reference Name**: Corporate Reform
- **ID**: `reform_ending`
- **Points**: 50
- **Hidden**: Yes
- **Description**: "Achieve the corporate reform ending through ethical business practices."
- **Icon**: Growth/rebirth icon

#### 6. Loop Ending
- **Reference Name**: Time Loop
- **ID**: `loop_ending`
- **Points**: 40
- **Hidden**: Yes
- **Description**: "Discover the mysterious time loop ending."
- **Icon**: Loop/cycle icon

### Milestone Achievements

#### 7. Packages 100
- **Reference Name**: 100 Packages Shipped
- **ID**: `packages_100`
- **Points**: 10
- **Hidden**: No
- **Description**: "Ship 100 packages."
- **Icon**: Small package pile

#### 8. Packages 1,000
- **Reference Name**: 1,000 Packages Shipped
- **ID**: `packages_1000`
- **Points**: 20
- **Hidden**: No
- **Description**: "Ship 1,000 packages."
- **Icon**: Medium package pile

#### 9. Packages 10,000
- **Reference Name**: 10,000 Packages Shipped
- **ID**: `packages_10000`
- **Points**: 30
- **Hidden**: No
- **Description**: "Ship 10,000 packages."
- **Icon**: Large package pile

#### 10. Money $1,000
- **Reference Name**: $1,000 Earned
- **ID**: `money_1000`
- **Points**: 10
- **Hidden**: No
- **Description**: "Earn a total of $1,000."
- **Icon**: Small money stack

#### 11. Money $10,000
- **Reference Name**: $10,000 Earned
- **ID**: `money_10000`
- **Points**: 20
- **Hidden**: No
- **Description**: "Earn a total of $10,000."
- **Icon**: Medium money stack

#### 12. Money $100,000
- **Reference Name**: $100,000 Earned
- **ID**: `money_100000`
- **Points**: 30
- **Hidden**: No
- **Description**: "Earn a total of $100,000."
- **Icon**: Large money stack

#### 13. 10 Workers
- **Reference Name**: 10 Workers Hired
- **ID**: `workers_10`
- **Points**: 15
- **Hidden**: No
- **Description**: "Hire 10 workers for your operation."
- **Icon**: Small worker group icon

#### 14. 50 Workers
- **Reference Name**: 50 Workers Hired
- **ID**: `workers_50`
- **Points**: 25
- **Hidden**: No
- **Description**: "Hire 50 workers for your operation."
- **Icon**: Large worker group icon

### Special Achievements

#### 15. Maximum Automation
- **Reference Name**: Maximum Automation
- **ID**: `max_automation`
- **Points**: 40
- **Hidden**: No
- **Description**: "Reach maximum automation efficiency."
- **Icon**: Advanced robot/AI icon

#### 16. Perfect Ethics
- **Reference Name**: Perfect Ethics
- **ID**: `perfect_ethics`
- **Points**: 50
- **Hidden**: Yes
- **Description**: "Maintain perfect ethical standards throughout your corporate journey."
- **Icon**: Halo/perfect ethics icon

## Testing

1. Enable Sandbox in your iOS device:
   - On your device, go to Settings > Game Center
   - Sign in with your sandbox test account

2. In Xcode:
   - Set your active scheme to "Development"
   - Run the app on your device
   - Verify Game Center authentication works

3. Test all leaderboards and achievements:
   - Ensure scores submit properly
   - Verify achievements trigger at the correct times
   - Check that the Game Center UI displays correctly

## Troubleshooting

- **Authentication Issues**: Make sure Game Center is enabled in Settings and you're signed in
- **Leaderboard Not Updating**: Game Center can take time to sync; wait a few minutes
- **Score Not Submitting**: Verify the leaderboard ID matches exactly with App Store Connect

## Common Errors

- "Error 1": Leaderboard ID mismatch or not configured in App Store Connect
- "Error 2": Score format mismatch (integer vs decimal)
- "Error 3": Authentication failure or Game Center service unavailable

## Notes

1. Game Center has a submission throttle to prevent spam - don't submit scores too frequently
2. Leaderboard updates may have a delay before appearing in the Game Center UI
3. Always test in the sandbox environment before releasing 