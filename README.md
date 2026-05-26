# Martingale Recovery — MQL4 Script

A MetaTrader 4 script that implements a **geometric lot-size recovery strategy** by placing an initial trade via `PlaceTrade()`, monitoring its outcome through `MonitorTrade()` using a 1-second `OrderSelect()` polling loop, and on each loss doubling the lot size via `NormalizeDouble(lotSize × LotMultiplier, 2)` before placing the next attempt — repeating up to `MaxRetries` times until either a profitable close is recorded or the maximum retry depth is exhausted.

---

## Overview

The Martingale strategy is a position-sizing system originating from 18th-century French gambling theory. Its core principle is simple: after each loss, double the position size so that a single win recovers all previous losses and produces a net profit equal to the original stake. In trading, this manifests as a geometric lot progression: `0.1 → 0.2 → 0.4 → 0.8 → 1.6...` Each successive trade requires only a single winning close to erase the entire loss sequence. The strategy's critical risk is that deep losing streaks — which are statistically inevitable given sufficient time — can produce exponential drawdown that exceeds account equity before recovery occurs. This script implements a bounded Martingale with a hard `MaxRetries` cap that halts the sequence once the configurable maximum depth is reached, preventing runaway lot escalation. It is intended for educational and strategy development purposes; deploying a live Martingale without robust risk management infrastructure carries significant risk of account ruin.

---

## Features

- **Geometric lot progression** — `lotSize = NormalizeDouble(lotSize × LotMultiplier, 2)` applied on each loss; `NormalizeDouble(..., 2)` ensures broker lot-step compatibility
- **`PlaceTrade()` dispatcher** — fetches `MarketInfo(TradeSymbol, MODE_BID)` for price, computes `tp = NormalizeDouble(price + TakeProfitPips × Point, digits)` and `sl = NormalizeDouble(price − StopLossPips × Point, digits)`, dispatches `OP_BUY` via `OrderSend()` with `"Martingale Trade"` comment, magic number `0`, and `clrBlue` marker
- **`MonitorTrade()` outcome polling loop** — `Sleep(1000)` per iteration; `OrderSelect(ticket, SELECT_BY_TICKET)` checks `OrderCloseTime() > 0` for closure; `OrderProfit() > 0` → returns `true` (success); `OrderProfit() <= 0` → returns `false` (loss)
- **`MaxRetries` hard cap** — outer `while (retries <= MaxRetries)` loop halts sequence on retry exhaustion, logging "Maximum retries reached" to prevent indefinite lot escalation
- **Completion logging** — "Trade successful. Exiting script." on win; "Martingale Recovery Script Completed. Maximum retries reached." on cap breach
- Logs every trade placement attempt, lot size, ticket, and retry count to the MT4 **Experts** tab

---

## How It Works

1. `lotSize = InitialLotSize`; `retries = 0`
2. `while (retries <= MaxRetries)`: calls `PlaceTrade(lotSize)` → returns ticket or `-1` on failure
3. `MonitorTrade(ticket)` polls `OrderSelect()` every second until `OrderCloseTime() > 0`
4. `OrderProfit() > 0` → logs success and returns; `OrderProfit() <= 0` → `retries++`, `lotSize = NormalizeDouble(lotSize × LotMultiplier, 2)`, continues loop
5. Loop exits on `retries > MaxRetries` with completion log

---

## Input Parameters

| Parameter         | Type   | Default  | Description                                                          |
|-------------------|--------|----------|----------------------------------------------------------------------|
| `TradeSymbol`     | string | `EURUSD` | Symbol to trade on                                                   |
| `InitialLotSize`  | double | `0.1`    | Starting lot size for the first trade in the sequence                |
| `LotMultiplier`   | double | `2.0`    | Geometric multiplier applied to lot size after each loss             |
| `TakeProfitPips`  | double | `50`     | Take profit distance in pips for each trade                          |
| `StopLossPips`    | double | `50`     | Stop loss distance in pips for each trade                            |
| `MaxRetries`      | int    | `6`      | Maximum number of recovery attempts before the sequence is halted    |

---

## ⚠️ Risk Warning

Martingale strategies carry **significant risk of account ruin**. The required lot size grows exponentially: with `LotMultiplier = 2.0` and `InitialLotSize = 0.1`, six consecutive losses require a 7th trade of **6.4 lots**. Always test exclusively on a **demo account**. Never deploy on live capital without independent risk management controls including account-level drawdown limits.

---

## Installation

1. Copy `Martingale_Recovery_001.mq4` to `MQL4/Scripts/` in your MT4 data folder
2. Compile in MetaEditor (F7)
3. Drag onto any chart from Navigator → Scripts
4. Configure inputs and click **OK**

---

## Requirements

- MetaTrader 4 (`#property strict` compatible build)
- MQL4 compiler (MetaEditor)
- AutoTrading enabled in MT4 toolbar

---

## License

MIT License

Copyright (c) 2026

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
