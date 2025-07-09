;; WeatherWise Hub Smart Contract
;; This contract allows users to create weather prediction markets,
;; place weather bets, resolve forecasts, claim rewards, and handles forecast expiration.

;; Constants
(define-constant ERROR-INVALID-FORECAST-TIME (err u1))
(define-constant ERROR-WEATHER-INACTIVE (err u2))
(define-constant ERROR-WEATHER-CONFIRMED (err u3))
(define-constant ERROR-INVALID-PREDICTION (err u4))
(define-constant ERROR-WEATHER-NOT-EXISTS (err u5))
(define-constant ERROR-INSUFFICIENT-BALANCE (err u6))
(define-constant ERROR-WEATHER-ACTIVE (err u7))
(define-constant ERROR-PREDICTION-NOT-EXISTS (err u8))
(define-constant ERROR-WEATHER-UNCONFIRMED (err u9))
(define-constant ERROR-PREDICTION-WRONG (err u10))
(define-constant ERROR-WEATHER-EXPIRED (err u11))
(define-constant ERROR-WEATHER-VALID (err u12))
(define-constant ERROR-UNAUTHORIZED (err u13))
(define-constant ERROR-PREDICTION-MIN (err u14))
(define-constant ERROR-PREDICTION-MAX (err u15))
(define-constant ERROR-INVALID-INPUT (err u16))

;; Additional Constants for Validation
(define-constant MAX-BLOCKS-UNTIL-FORECAST u52560) ;; Maximum ~1 year worth of blocks
(define-constant MIN-BLOCKS-UNTIL-FORECAST u144)   ;; Minimum ~1 day worth of blocks
(define-constant MAX-BLOCKS-UNTIL-EXPIRY u105120) ;; Maximum ~2 years worth of blocks
(define-constant MIN-EVENT-LENGTH u10)         ;; Minimum event description length

;; Data Variables
(define-data-var platform-name (string-ascii 50) "WeatherWise Hub")
(define-data-var next-weather-event-id uint u1)
(define-data-var weather-admin principal tx-sender)

;; Configuration
(define-data-var weather-confirmation-period uint u10000)
(define-data-var minimum-prediction-amount uint u10)
(define-data-var maximum-prediction-amount uint u1000000)

;; Maps
(define-map weather-events
  { event-id: uint }
  {
    event-description: (string-ascii 256),
    weather-outcome: (optional bool),
    forecast-close-time: uint,
    confirmation-deadline: uint,
    meteorologist: principal
  }
)

(define-map weather-predictions
  { event-id: uint, forecaster: principal }
  { prediction-amount: uint, weather-guess: bool }
)

;; Enhanced Private Validation Functions
(define-private (is-valid-event-id (event-id uint))
  (< event-id (var-get next-weather-event-id))
)

(define-private (is-valid-event-length (event-description (string-ascii 256)))
  (and 
    (>= (len event-description) MIN-EVENT-LENGTH)
    (<= (len event-description) u256)
  )
)

(define-private (is-valid-forecast-time (forecast-close-time uint))
  (let 
    (
      (blocks-until-forecast (- forecast-close-time u0))
    )
    (and
      (>= blocks-until-forecast MIN-BLOCKS-UNTIL-FORECAST)
      (<= blocks-until-forecast MAX-BLOCKS-UNTIL-FORECAST)
    )
  )
)

(define-private (is-valid-expiry-time (forecast-close-time uint) (confirmation-deadline uint))
  (let
    (
      (blocks-until-expiry (- confirmation-deadline forecast-close-time))
    )
    (and
      (> confirmation-deadline forecast-close-time)
      (<= blocks-until-expiry MAX-BLOCKS-UNTIL-EXPIRY)
    )
  )
)

(define-private (is-valid-prediction-amount (amount uint))
  (and
    (>= amount (var-get minimum-prediction-amount))
    (<= amount (var-get maximum-prediction-amount))
  )
)

;; Public Functions

;; Create a new weather event with enhanced validation
(define-public (create-weather-event (event-description (string-ascii 256)) (forecast-close-time uint))
  (let
    (
      (event-id (var-get next-weather-event-id))
      (confirmation-deadline (+ forecast-close-time (var-get weather-confirmation-period)))
    )
    ;; Enhanced input validation
    (asserts! (is-valid-event-length event-description) ERROR-INVALID-INPUT)
    (asserts! (is-valid-forecast-time forecast-close-time) ERROR-INVALID-FORECAST-TIME)
    (asserts! (is-valid-expiry-time forecast-close-time confirmation-deadline) ERROR-INVALID-INPUT)
    
    (map-set weather-events
      { event-id: event-id }
      {
        event-description: event-description,
        weather-outcome: none,
        forecast-close-time: forecast-close-time,
        confirmation-deadline: confirmation-deadline,
        meteorologist: tx-sender
      }
    )
    (var-set next-weather-event-id (+ event-id u1))
    (ok event-id)
  )
)

;; Place a weather prediction with enhanced validation
(define-public (place-weather-prediction (event-id uint) (weather-guess bool) (prediction-amount uint))
  (let
    (
      (existing-prediction (default-to { prediction-amount: u0, weather-guess: false } 
                          (map-get? weather-predictions { event-id: event-id, forecaster: tx-sender })))
    )
    ;; Enhanced input validation
    (asserts! (is-valid-event-id event-id) ERROR-WEATHER-NOT-EXISTS)
    (asserts! (is-valid-prediction-amount prediction-amount) ERROR-INVALID-PREDICTION)
    (let
      (
        (weather-event (unwrap! (map-get? weather-events { event-id: event-id }) ERROR-WEATHER-NOT-EXISTS))
        (total-prediction-amount (+ prediction-amount (get prediction-amount existing-prediction)))
      )
      ;; Additional validation for combined prediction amount
      (asserts! (<= total-prediction-amount (var-get maximum-prediction-amount)) ERROR-PREDICTION-MAX)
      (asserts! (is-none (get weather-outcome weather-event)) ERROR-WEATHER-CONFIRMED)
      (asserts! (>= (stx-get-balance tx-sender) prediction-amount) ERROR-INSUFFICIENT-BALANCE)
      
      (map-set weather-predictions
        { event-id: event-id, forecaster: tx-sender }
        { prediction-amount: total-prediction-amount, weather-guess: weather-guess }
      )
      (stx-transfer? prediction-amount tx-sender (as-contract tx-sender))
    )
  )
)

;; Enhanced setter for weather confirmation period with stricter validation
(define-public (set-weather-confirmation-period (new-period uint))
  (begin
    (asserts! (is-eq tx-sender (var-get weather-admin)) ERROR-UNAUTHORIZED)
    (asserts! (and 
      (>= new-period u1000)  ;; Minimum ~1 day worth of blocks
      (<= new-period u52560) ;; Maximum ~1 year worth of blocks
    ) ERROR-INVALID-INPUT)
    (ok (var-set weather-confirmation-period new-period))
  )
)

;; Enhanced setter for minimum prediction amount with stricter validation
(define-public (set-minimum-prediction-amount (new-amount uint))
  (begin
    (asserts! (is-eq tx-sender (var-get weather-admin)) ERROR-UNAUTHORIZED)
    (asserts! (and 
      (>= new-amount u1)
      (< new-amount (var-get maximum-prediction-amount))
      (<= new-amount u1000000) ;; Upper limit for minimum prediction
    ) ERROR-INVALID-INPUT)
    (ok (var-set minimum-prediction-amount new-amount))
  )
)

;; Enhanced setter for maximum prediction amount with stricter validation
(define-public (set-maximum-prediction-amount (new-amount uint))
  (begin
    (asserts! (is-eq tx-sender (var-get weather-admin)) ERROR-UNAUTHORIZED)
    (asserts! (and 
      (> new-amount (var-get minimum-prediction-amount))
      (<= new-amount u1000000000000)
      (>= new-amount u1000) ;; Lower limit for maximum prediction
    ) ERROR-INVALID-INPUT)
    (ok (var-set maximum-prediction-amount new-amount))
  )
)

;; Getter for weather admin
(define-read-only (get-weather-admin)
  (ok (var-get weather-admin))
)

;; Function to transfer weather admin rights
(define-public (transfer-weather-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get weather-admin)) ERROR-UNAUTHORIZED)
    (asserts! (not (is-eq new-admin (var-get weather-admin))) ERROR-INVALID-INPUT)
    (ok (var-set weather-admin new-admin))
  )
)