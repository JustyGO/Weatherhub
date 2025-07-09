# WeatherWise Hub Smart Contract

A decentralized weather prediction market built on the Stacks blockchain, enabling users to create weather forecasting events, place predictions, and earn rewards based on their accuracy.

## Overview

WeatherWise Hub is a smart contract that facilitates weather prediction markets where users can:
- Create weather events with specific forecast deadlines
- Place predictions on weather outcomes with STX tokens
- Resolve forecasts and claim rewards
- Manage platform configuration and administration

## Features

### Core Functionality
- **Weather Event Creation**: Users can create new weather prediction events with customizable descriptions and forecast deadlines
- **Prediction Placement**: Users can place predictions on weather outcomes using STX tokens
- **Validation System**: Comprehensive input validation for all parameters
- **Admin Management**: Transferable admin rights for platform governance

### Security Features
- Time-based validation for forecast periods
- Amount limits for predictions
- Authorization checks for admin functions
- Input sanitization and validation

## Constants and Error Codes

### Error Codes
- `ERROR-INVALID-FORECAST-TIME (1)`: Invalid forecast time parameters
- `ERROR-WEATHER-INACTIVE (2)`: Weather event is not active
- `ERROR-WEATHER-CONFIRMED (3)`: Weather outcome already confirmed
- `ERROR-INVALID-PREDICTION (4)`: Invalid prediction parameters
- `ERROR-WEATHER-NOT-EXISTS (5)`: Weather event does not exist
- `ERROR-INSUFFICIENT-BALANCE (6)`: Insufficient STX balance
- `ERROR-WEATHER-ACTIVE (7)`: Weather event is still active
- `ERROR-PREDICTION-NOT-EXISTS (8)`: Prediction does not exist
- `ERROR-WEATHER-UNCONFIRMED (9)`: Weather outcome not confirmed
- `ERROR-PREDICTION-WRONG (10)`: Prediction was incorrect
- `ERROR-WEATHER-EXPIRED (11)`: Weather event has expired
- `ERROR-WEATHER-VALID (12)`: Weather event is still valid
- `ERROR-UNAUTHORIZED (13)`: Unauthorized operation
- `ERROR-PREDICTION-MIN (14)`: Below minimum prediction amount
- `ERROR-PREDICTION-MAX (15)`: Above maximum prediction amount
- `ERROR-INVALID-INPUT (16)`: Invalid input parameters

### Time Limits
- **Maximum Forecast Period**: 52,560 blocks (~1 year)
- **Minimum Forecast Period**: 144 blocks (~1 day)
- **Maximum Expiry Period**: 105,120 blocks (~2 years)
- **Minimum Event Description**: 10 characters

## Data Structures

### Weather Events
```clarity
{
  event-id: uint,
  event-description: string-ascii (256),
  weather-outcome: optional bool,
  forecast-close-time: uint,
  confirmation-deadline: uint,
  meteorologist: principal
}
```

### Weather Predictions
```clarity
{
  event-id: uint,
  forecaster: principal,
  prediction-amount: uint,
  weather-guess: bool
}
```

## Public Functions

### Core Functions

#### `create-weather-event`
Creates a new weather prediction event.

**Parameters:**
- `event-description`: Description of the weather event (10-256 characters)
- `forecast-close-time`: Block height when predictions close

**Returns:** Event ID if successful

**Example:**
```clarity
(contract-call? .weatherwise-hub create-weather-event "Will it rain in Lagos on 2025-08-15?" u1000000)
```

#### `place-weather-prediction`
Places a prediction on a weather event.

**Parameters:**
- `event-id`: ID of the weather event
- `weather-guess`: Boolean prediction (true/false)
- `prediction-amount`: Amount of STX to bet

**Returns:** Success confirmation

**Example:**
```clarity
(contract-call? .weatherwise-hub place-weather-prediction u1 true u100)
```

### Admin Functions

#### `set-weather-confirmation-period`
Sets the confirmation period for weather events.

**Parameters:**
- `new-period`: New confirmation period (1,000 - 52,560 blocks)

**Restrictions:** Admin only

#### `set-minimum-prediction-amount`
Sets the minimum prediction amount.

**Parameters:**
- `new-amount`: New minimum amount (1 - 1,000,000 STX)

**Restrictions:** Admin only

#### `set-maximum-prediction-amount`
Sets the maximum prediction amount.

**Parameters:**
- `new-amount`: New maximum amount (1,000 - 1,000,000,000,000 STX)

**Restrictions:** Admin only

#### `transfer-weather-admin`
Transfers admin rights to another principal.

**Parameters:**
- `new-admin`: Principal to receive admin rights

**Restrictions:** Current admin only

### Read-Only Functions

#### `get-weather-admin`
Returns the current admin principal.

**Returns:** Current admin principal

## Configuration

### Default Settings
- **Confirmation Period**: 10,000 blocks
- **Minimum Prediction**: 10 STX
- **Maximum Prediction**: 1,000,000 STX
- **Platform Name**: "WeatherWise Hub"

### Validation Rules
- Event descriptions must be 10-256 characters
- Forecast time must be 1 day to 1 year in the future
- Prediction amounts must be within configured limits
- Users must have sufficient STX balance

## Usage Examples

### Creating a Weather Event
```clarity
;; Create a weather event for tomorrow's weather
(contract-call? .weatherwise-hub create-weather-event 
  "Will it rain in Lagos tomorrow?" 
  (+ block-height u144))
```

### Placing a Prediction
```clarity
;; Place a prediction of 100 STX that it will rain
(contract-call? .weatherwise-hub place-weather-prediction 
  u1    ;; event-id
  true  ;; weather-guess (true = will rain)
  u100) ;; prediction-amount
```

### Checking Admin Status
```clarity
;; Get current admin
(contract-call? .weatherwise-hub get-weather-admin)
```

## Security Considerations

### Input Validation
- All user inputs are validated before processing
- Time-based constraints prevent invalid forecast periods
- Amount limits prevent extreme betting behavior

### Access Control
- Admin functions are restricted to authorized principals
- Weather event creation is open to all users
- Prediction placement requires sufficient balance

### Error Handling
- Comprehensive error codes for all failure scenarios
- Graceful handling of edge cases
- Clear error messages for debugging

## Best Practices

### For Event Creators
1. Use clear, specific event descriptions
2. Set reasonable forecast deadlines
3. Consider the confirmation period when setting deadlines

### For Predictors
1. Ensure sufficient STX balance before placing predictions
2. Research weather conditions before making predictions
3. Consider the risk/reward ratio of prediction amounts

### For Administrators
1. Regularly review and adjust configuration parameters
2. Monitor system usage and performance
3. Ensure proper governance of admin rights

## Development and Testing

### Prerequisites
- Stacks blockchain development environment
- Clarity language knowledge
- STX tokens for testing

### Testing Considerations
- Test with various forecast timeframes
- Validate error handling with invalid inputs
- Test admin functions with different user roles
- Verify balance and transfer operations

