;; Food Inflation Tracking Smart Contract
;; Blockchain-based real-time food price oracle for developing nations

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u401))
(define-constant ERR_INVALID_VENDOR (err u402))
(define-constant ERR_INVALID_PRICE (err u403))
(define-constant ERR_VENDOR_EXISTS (err u404))
(define-constant ERR_INVALID_FOOD_TYPE (err u405))
(define-constant ERR_NO_DATA (err u406))
(define-constant ERR_INVALID_REGION (err u407))

;; Data Variables
(define-data-var next-vendor-id uint u1)
(define-data-var next-price-id uint u1)
(define-data-var admin principal CONTRACT_OWNER)

;; Data Maps
(define-map vendors
  { vendor-id: uint }
  {
    address: principal,
    name: (string-ascii 64),
    region: (string-ascii 32),
    reputation-score: uint,
    active: bool,
    registered-at: uint
  }
)

(define-map vendor-addresses
  { address: principal }
  { vendor-id: uint }
)

(define-map food-prices
  { price-id: uint }
  {
    food-type: (string-ascii 32),
    price-per-kg: uint,
    vendor-id: uint,
    region: (string-ascii 32),
    timestamp: uint,
    validated: bool
  }
)

(define-map food-type-prices
  { food-type: (string-ascii 32), region: (string-ascii 32) }
  { 
    latest-price: uint,
    price-count: uint,
    total-price: uint,
    last-updated: uint
  }
)

(define-map regional-averages
  { region: (string-ascii 32), food-type: (string-ascii 32), period: uint }
  {
    average-price: uint,
    sample-count: uint,
    min-price: uint,
    max-price: uint
  }
)

(define-private (accumulate-stats (iter uint) (state {sum: uint, sumsq: uint, count: uint, food-type: (string-ascii 32), region: (string-ascii 32), start-period: uint}))
  (let (
    (period (- (get start-period state) iter))
    (avg (map-get? regional-averages { region: (get region state), food-type: (get food-type state), period: period }))
  )
    (match avg
      data
      (let (
        (price (get average-price data))
        (new-sum (+ (get sum state) price))
        (new-sumsq (+ (get sumsq state) (* price price)))
        (new-count (+ (get count state) u1))
      )
        {sum: new-sum, sumsq: new-sumsq, count: new-count, food-type: (get food-type state), region: (get region state), start-period: (get start-period state)}
      )
      state
    )
  )
)

;; Read-only functions
(define-read-only (get-vendor (vendor-id uint))
  (map-get? vendors { vendor-id: vendor-id })
)

(define-read-only (get-vendor-by-address (address principal))
  (match (map-get? vendor-addresses { address: address })
    vendor-data (map-get? vendors { vendor-id: (get vendor-id vendor-data) })
    none
  )
)

(define-read-only (get-price-record (price-id uint))
  (map-get? food-prices { price-id: price-id })
)

(define-read-only (get-current-price (food-type (string-ascii 32)) (region (string-ascii 32)))
  (map-get? food-type-prices { food-type: food-type, region: region })
)

(define-read-only (get-regional-average (region (string-ascii 32)) (food-type (string-ascii 32)) (period uint))
  (map-get? regional-averages { region: region, food-type: food-type, period: period })
)

(define-read-only (calculate-inflation-rate (food-type (string-ascii 32)) (region (string-ascii 32)))
  (let (
    (current-period (/ stacks-block-height u144))
    (previous-period (- current-period u1))
    (current-avg (map-get? regional-averages { region: region, food-type: food-type, period: current-period }))
    (previous-avg (map-get? regional-averages { region: region, food-type: food-type, period: previous-period }))
  )
    (match current-avg
      current-data
      (match previous-avg
        previous-data
        (let (
          (current-price (get average-price current-data))
          (previous-price (get average-price previous-data))
        )
          (if (> previous-price u0)
            (ok (/ (* (- current-price previous-price) u10000) previous-price))
            (err ERR_NO_DATA)
          )
        )
        (err ERR_NO_DATA)
      )
      (err ERR_NO_DATA)
    )
  )
)

(define-read-only (calculate-price-volatility (food-type (string-ascii 32)) (region (string-ascii 32)) (periods uint))
  (let (
    (current-period (/ stacks-block-height u144))
    (initial-state {sum: u0, sumsq: u0, count: u0, food-type: food-type, region: region, start-period: current-period})
    (stats (fold accumulate-stats (list u1 u2 u3 u4 u5 u6 u7 u8 u9 u10) initial-state))
  )
    (if (>= (get count stats) periods)
      (let (
        (sum (get sum stats))
        (sumsq (get sumsq stats))
        (count (get count stats))
        (variance (/ (* (- (* sumsq count) (* sum sum)) u10000) (* count count)))
      )
        (ok variance)
      )
      (err ERR_NO_DATA)
    )
  )
)

(define-read-only (is-valid-food-type (food-type (string-ascii 32)))
  (or 
    (is-eq food-type "rice")
    (or (is-eq food-type "maize")
    (or (is-eq food-type "wheat")
    (or (is-eq food-type "beans")
    (or (is-eq food-type "cassava")
    (or (is-eq food-type "millet")
    (or (is-eq food-type "sorghum")
    (or (is-eq food-type "yam")
    (or (is-eq food-type "plantain")
        (is-eq food-type "coconut")
    ))))))))
  )
)

(define-read-only (is-valid-region (region (string-ascii 32)))
  (or 
    (is-eq region "north")
    (or (is-eq region "south")
    (or (is-eq region "east")
    (or (is-eq region "west")
    (or (is-eq region "central")
    (or (is-eq region "northeast")
    (or (is-eq region "northwest")
    (or (is-eq region "southeast")
        (is-eq region "southwest")
    ))))))))
)

;; Public functions
(define-public (register-vendor (name (string-ascii 64)) (region (string-ascii 32)))
  (let (
    (vendor-id (var-get next-vendor-id))
    (caller tx-sender)
  )
    (asserts! (is-valid-region region) ERR_INVALID_REGION)
    (asserts! (is-none (map-get? vendor-addresses { address: caller })) ERR_VENDOR_EXISTS)
    (asserts! (> (len name) u0) ERR_INVALID_VENDOR)
    
    (map-set vendors
      { vendor-id: vendor-id }
      {
        address: caller,
        name: name,
        region: region,
        reputation-score: u100,
        active: true,
        registered-at: stacks-block-height
      }
    )
    
    (map-set vendor-addresses
      { address: caller }
      { vendor-id: vendor-id }
    )
    
    (var-set next-vendor-id (+ vendor-id u1))
    (ok vendor-id)
  )
)

(define-public (submit-price (food-type (string-ascii 32)) (price-per-kg uint) (region (string-ascii 32)))
  (let (
    (price-id (var-get next-price-id))
    (caller tx-sender)
    (vendor-data (get-vendor-by-address caller))
    (current-time stacks-block-height)
  )
    (asserts! (is-valid-food-type food-type) ERR_INVALID_FOOD_TYPE)
    (asserts! (is-valid-region region) ERR_INVALID_REGION)
    (asserts! (> price-per-kg u0) ERR_INVALID_PRICE)
    (asserts! (is-some vendor-data) ERR_INVALID_VENDOR)
    
    (let (
      (vendor-info (unwrap! vendor-data ERR_INVALID_VENDOR))
      (vendor-id-data (unwrap! (map-get? vendor-addresses { address: caller }) ERR_INVALID_VENDOR))
      (vendor-id (get vendor-id vendor-id-data))
    )
      (asserts! (get active vendor-info) ERR_INVALID_VENDOR)
      
      (map-set food-prices
        { price-id: price-id }
        {
          food-type: food-type,
          price-per-kg: price-per-kg,
          vendor-id: vendor-id,
          region: region,
          timestamp: current-time,
          validated: true
        }
      )
      
      (update-price-averages food-type region price-per-kg)
      (update-vendor-reputation vendor-id)
      
      (var-set next-price-id (+ price-id u1))
      (ok price-id)
    )
  )
)

(define-public (validate-price (price-id uint))
  (let (
    (price-data (unwrap! (map-get? food-prices { price-id: price-id }) ERR_NO_DATA))
  )
    (asserts! (is-eq tx-sender (var-get admin)) ERR_UNAUTHORIZED)
    
    (map-set food-prices
      { price-id: price-id }
      (merge price-data { validated: true })
    )
    (ok true)
  )
)

(define-public (deactivate-vendor (vendor-id uint))
  (let (
    (vendor-data (unwrap! (map-get? vendors { vendor-id: vendor-id }) ERR_INVALID_VENDOR))
  )
    (asserts! (is-eq tx-sender (var-get admin)) ERR_UNAUTHORIZED)
    
    (map-set vendors
      { vendor-id: vendor-id }
      (merge vendor-data { active: false })
    )
    (ok true)
  )
)

(define-public (set-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) ERR_UNAUTHORIZED)
    (var-set admin new-admin)
    (ok true)
  )
)

;; Private functions
(define-private (update-price-averages (food-type (string-ascii 32)) (region (string-ascii 32)) (new-price uint))
  (let (
    (current-data (default-to 
      { latest-price: u0, price-count: u0, total-price: u0, last-updated: u0 }
      (map-get? food-type-prices { food-type: food-type, region: region })
    ))
    (new-count (+ (get price-count current-data) u1))
    (new-total (+ (get total-price current-data) new-price))
  )
    (map-set food-type-prices
      { food-type: food-type, region: region }
      {
        latest-price: new-price,
        price-count: new-count,
        total-price: new-total,
        last-updated: stacks-block-height
      }
    )
    (update-regional-averages food-type region new-price)
  )
)

(define-private (update-regional-averages (food-type (string-ascii 32)) (region (string-ascii 32)) (new-price uint))
  (let (
    (current-period (/ stacks-block-height u144))
    (existing-data (default-to
      { average-price: u0, sample-count: u0, min-price: u0, max-price: u0 }
      (map-get? regional-averages { region: region, food-type: food-type, period: current-period })
    ))
    (sample-count (get sample-count existing-data))
    (current-total (* (get average-price existing-data) sample-count))
    (new-sample-count (+ sample-count u1))
    (new-total (+ current-total new-price))
    (new-average (/ new-total new-sample-count))
    (new-min (if (or (is-eq sample-count u0) (< new-price (get min-price existing-data)))
                new-price
                (get min-price existing-data)))
    (new-max (if (or (is-eq sample-count u0) (> new-price (get max-price existing-data)))
                new-price
                (get max-price existing-data)))
  )
    (map-set regional-averages
      { region: region, food-type: food-type, period: current-period }
      {
        average-price: new-average,
        sample-count: new-sample-count,
        min-price: new-min,
        max-price: new-max
      }
    )
  )
)

(define-private (update-vendor-reputation (vendor-id uint))
  (match (map-get? vendors { vendor-id: vendor-id })
    vendor-data
    (let (
      (current-score (get reputation-score vendor-data))
      (new-score (if (< current-score u1000) (+ current-score u1) current-score))
    )
      (begin
        (map-set vendors
          { vendor-id: vendor-id }
          (merge vendor-data { reputation-score: new-score })
        )
        true
      )
    )
    false
  )
)


;; Public query functions
(define-public (get-latest-prices (food-type (string-ascii 32)) (region (string-ascii 32)))
  (let (
    (price-data (map-get? food-type-prices { food-type: food-type, region: region }))
  )
    (match price-data
      data (ok data)
      (err ERR_NO_DATA)
    )
  )
)

(define-public (get-market-summary (region (string-ascii 32)))
  (ok {
    rice: (default-to { latest-price: u0, price-count: u0, total-price: u0, last-updated: u0 }
          (map-get? food-type-prices { food-type: "rice", region: region })),
    maize: (default-to { latest-price: u0, price-count: u0, total-price: u0, last-updated: u0 }
           (map-get? food-type-prices { food-type: "maize", region: region })),
    wheat: (default-to { latest-price: u0, price-count: u0, total-price: u0, last-updated: u0 }
           (map-get? food-type-prices { food-type: "wheat", region: region })),
    beans: (default-to { latest-price: u0, price-count: u0, total-price: u0, last-updated: u0 }
           (map-get? food-type-prices { food-type: "beans", region: region }))
  })
)

(define-public (get-vendor-stats (vendor-id uint))
  (let (
    (vendor-data (unwrap! (map-get? vendors { vendor-id: vendor-id }) ERR_INVALID_VENDOR))
    (submission-count (count-vendor-submissions vendor-id))
  )
    (ok {
      vendor: vendor-data,
      total-submissions: submission-count,
      avg-reputation: (get reputation-score vendor-data)
    })
  )
)

(define-private (count-vendor-submissions (vendor-id uint))
  (fold count-submissions-helper 
    (list u1 u2 u3 u4 u5 u6 u7 u8 u9 u10 u11 u12 u13 u14 u15 u16 u17 u18 u19 u20)
    { vendor-id: vendor-id, count: u0, current-id: u1, max-id: (var-get next-price-id) }
  )
)

(define-private (count-submissions-helper (iter uint) (state { vendor-id: uint, count: uint, current-id: uint, max-id: uint }))
  (let (
    (current-id (get current-id state))
    (max-id (get max-id state))
    (target-vendor-id (get vendor-id state))
    (current-count (get count state))
  )
    (if (< current-id max-id)
      (let (
        (price-data (map-get? food-prices { price-id: current-id }))
      )
        (match price-data
          data
          (if (is-eq (get vendor-id data) target-vendor-id)
            { vendor-id: target-vendor-id, count: (+ current-count u1), current-id: (+ current-id u1), max-id: max-id }
            { vendor-id: target-vendor-id, count: current-count, current-id: (+ current-id u1), max-id: max-id }
          )
          { vendor-id: target-vendor-id, count: current-count, current-id: (+ current-id u1), max-id: max-id }
        )
      )
      state
    )
  )
)

(define-public (get-vendor-count-by-region (region (string-ascii 32)))
  (let (
    (count (fold count-regional-vendors
      (list u1 u2 u3 u4 u5 u6 u7 u8 u9 u10 u11 u12 u13 u14 u15 u16 u17 u18 u19 u20)
      { region: region, count: u0, max-id: (var-get next-vendor-id) }
    ))
  )
    (ok (get count count))
  )
)

(define-private (count-regional-vendors (iter uint) (state { region: (string-ascii 32), count: uint, max-id: uint }))
  (let (
    (target-region (get region state))
    (current-count (get count state))
    (max-id (get max-id state))
  )
    (if (< iter max-id)
      (let (
        (vendor-data (map-get? vendors { vendor-id: iter }))
      )
        (match vendor-data
          data
          (if (and (is-eq (get region data) target-region) (get active data))
            { region: target-region, count: (+ current-count u1), max-id: max-id }
            { region: target-region, count: current-count, max-id: max-id }
          )
          { region: target-region, count: current-count, max-id: max-id }
        )
      )
      state
    )
  )
)

(define-public (compare-regional-prices (food-type (string-ascii 32)) (region1 (string-ascii 32)) (region2 (string-ascii 32)))
  (let (
    (price1 (map-get? food-type-prices { food-type: food-type, region: region1 }))
    (price2 (map-get? food-type-prices { food-type: food-type, region: region2 }))
  )
    (match price1
      data1
      (match price2
        data2
        (let (
          (avg1 (if (> (get price-count data1) u0) (/ (get total-price data1) (get price-count data1)) u0))
          (avg2 (if (> (get price-count data2) u0) (/ (get total-price data2) (get price-count data2)) u0))
          (difference (if (> avg1 avg2) (- avg1 avg2) (- avg2 avg1)))
          (percentage (if (> avg2 u0) (/ (* difference u10000) avg2) u0))
        )
          (ok {
            region1: region1,
            region2: region2,
            price1: avg1,
            price2: avg2,
            difference: difference,
            percentage-diff: percentage
          })
        )
        (err ERR_NO_DATA)
      )
      (err ERR_NO_DATA)
    )
  )
)

(define-public (get-price-alerts (food-type (string-ascii 32)) (region (string-ascii 32)) (threshold-percentage uint))
  (let (
    (current-period (/ stacks-block-height u144))
    (previous-period (- current-period u1))
    (inflation-rate-result (calculate-inflation-rate food-type region))
  )
    (match inflation-rate-result
      inflation-rate
      (if (> inflation-rate threshold-percentage)
        (ok {
          alert: true,
          food-type: food-type,
          region: region,
          inflation-rate: inflation-rate,
          threshold: threshold-percentage,
          severity: (if (> inflation-rate (* threshold-percentage u2)) "high" "medium")
        })
        (ok {
          alert: false,
          food-type: food-type,
          region: region,
          inflation-rate: inflation-rate,
          threshold: threshold-percentage,
          severity: "low"
        })
      )
      error (err error)
    )
  )
)

;; Emergency functions
(define-public (emergency-price-update (food-type (string-ascii 32)) (region (string-ascii 32)) (emergency-price uint))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) ERR_UNAUTHORIZED)
    (asserts! (is-valid-food-type food-type) ERR_INVALID_FOOD_TYPE)
    (asserts! (is-valid-region region) ERR_INVALID_REGION)
    (asserts! (> emergency-price u0) ERR_INVALID_PRICE)
    
    (map-set food-type-prices
      { food-type: food-type, region: region }
      {
        latest-price: emergency-price,
        price-count: u1,
        total-price: emergency-price,
        last-updated: stacks-block-height
      }
    )
    (ok true)
  )
)

;; Initialization
(define-public (initialize-contract)
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (try! (register-vendor "System Oracle" "central"))
    (ok true)
  )
)
