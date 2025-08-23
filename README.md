## 📋 Overview

A blockchain-based real-time food price oracle that helps developing nations track food inflation by aggregating market vendor data. This smart contract enables transparent, trustless price tracking for essential food commodities.

## 🎯 Problem Statement

Food price hikes (rice, maize, wheat) are poorly tracked in developing nations, severely impacting policy response and farmers' decision-making.

## 💡 Solution

Decentralized food price oracle that:
- 📊 Aggregates real-time vendor price data
- 🔐 Provides trustless validation mechanisms  
- 📈 Offers dashboards for policymakers & farmers
- 🌍 Tracks regional price variations

## 🚀 Features

### Core Functionality
- ✅ Vendor registration and management
- 📥 Price submission by verified vendors
- 📊 Real-time price aggregation
- 🔍 Price history tracking
- 📈 Inflation rate calculations
- 🌍 Regional price comparisons
- 🚨 Price alert system

### Supported Food Types
- 🍚 Rice
- 🌽 Maize
- 🌾 Wheat
- 🫘 Beans
- 🍠 Cassava
- 🌾 Millet
- 🌾 Sorghum
- 🍠 Yam
- 🍌 Plantain
- 🥥 Coconut

### Regional Coverage
- 🧭 North, South, East, West, Central
- 📍 Northeast, Northwest, Southeast, Southwest

## 🛠️ Usage Instructions

### For Market Vendors

#### 1. Register as a Vendor
```clarity
(contract-call? .Food-Inflation-Tracking register-vendor "Market Vendor Name" "north")
```

#### 2. Submit Price Data
```clarity
(contract-call? .Food-Inflation-Tracking submit-price "rice" u2500 "north")
```
*Price should be in smallest currency unit per kg (e.g., 2500 = 25.00 in local currency)*

### For Data Consumers

#### 3. Get Current Prices
```clarity
(contract-call? .Food-Inflation-Tracking get-current-price "rice" "north")
```

#### 4. Check Inflation Rate
```clarity
(contract-call? .Food-Inflation-Tracking calculate-inflation-rate "rice" "north")
```

#### 5. Get Market Summary
```clarity
(contract-call? .Food-Inflation-Tracking get-market-summary "north")
```

#### 6. Compare Regional Prices
```clarity
(contract-call? .Food-Inflation-Tracking compare-regional-prices "rice" "north" "south")
```

#### 7. Set Price Alerts
```clarity
(contract-call? .Food-Inflation-Tracking get-price-alerts "rice" "north" u1000)
```
*Alert threshold: 1000 = 10% inflation*

### For Administrators

#### 8. Validate Price Submissions
```clarity
(contract-call? .Food-Inflation-Tracking validate-price u1)
```

#### 9. Deactivate Vendor
```clarity
(contract-call? .Food-Inflation-Tracking deactivate-vendor u1)
```

#### 10. Emergency Price Update
```clarity
(contract-call? .Food-Inflation-Tracking emergency-price-update "rice" "north" u3000)
```

## 📊 Data Structure

### Vendor Information
- Unique vendor ID
- Principal address
- Vendor name & region
- Reputation score (0-1000)
- Registration timestamp

### Price Records
- Food type & price per kg
- Vendor ID & region
- Timestamp & validation status
- Automatic aggregation

### Analytics
- Regional averages by time period
- Min/max price tracking
- Sample counts for accuracy
- Inflation rate calculations

## 🔒 Security Features

- ✅ Vendor verification system
- 🎯 Input validation for all parameters
- 🛡️ Admin-only emergency functions
- 📊 Reputation scoring system
- 🔐 Principal-based authentication

## 🧪 Testing

### Run Contract Tests
```bash
clarinet test
```

### Check Contract Syntax
```bash
clarinet check
```

### Deploy Locally
```bash
clarinet integrate
```

## 🌟 Impact

This smart contract enables:
- 📈 Real-time food price monitoring
- 🏛️ Data-driven policy decisions
- 👨‍🌾 Better farmer market insights
- 🌍 Cross-regional price transparency
- 🚨 Early inflation warning systems

## 🤝 Contributing

1. Fork the repository
2. Create feature branch
3. Submit pull request with clear description
4. Ensure all tests pass

## 📜 License

MIT License - see LICENSE file for details.

---

Built with ❤️ for developing nations' food security 🌍
