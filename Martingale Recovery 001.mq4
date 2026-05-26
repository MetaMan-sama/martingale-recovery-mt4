//+------------------------------------------------------------------+
//|                     MartingaleRecovery.mq4                       |
//|     Implements a martingale strategy to recover losses           |
//+------------------------------------------------------------------+
#property strict

// Input parameters
input string TradeSymbol = "EURUSD";         // Symbol to trade
input double InitialLotSize = 0.1;           // Initial lot size
input double LotMultiplier = 2.0;            // Multiplier for lot size after a loss
input double TakeProfitPips = 50;            // Take Profit in pips
input double StopLossPips = 50;              // Stop Loss in pips
input int MaxRetries = 6;                    // Maximum number of retries (levels)

//+------------------------------------------------------------------+
//| Main Function                                                   |
//+------------------------------------------------------------------+
void OnStart()
{
   Print("Martingale Recovery Script Started.");

   double lotSize = InitialLotSize;
   int retries = 0;

   while (retries <= MaxRetries && !IsStopped()) {
      // Place the trade
      bool success = PlaceTrade(lotSize);

      if (success) {
         Print("Trade successful. Exiting script.");
         return; // Exit the loop on success
      } else {
         retries++;
         lotSize = NormalizeDouble(lotSize * LotMultiplier, 2); // Increase lot size
         Print("Trade failed. Retrying with lot size: ", lotSize, " (Retry ", retries, " of ", MaxRetries, ")");
      }
   }

   Print("Martingale Recovery Script Completed. Maximum retries reached.");
}

//+------------------------------------------------------------------+
//| Place a trade                                                   |
//+------------------------------------------------------------------+
bool PlaceTrade(double lotSize)
{
   double price = MarketInfo(TradeSymbol, MODE_BID);
   double slippage = 3;
   double tp = NormalizeDouble(price + TakeProfitPips * MarketInfo(TradeSymbol, MODE_POINT), MarketInfo(TradeSymbol, MODE_DIGITS));
   double sl = NormalizeDouble(price - StopLossPips * MarketInfo(TradeSymbol, MODE_POINT), MarketInfo(TradeSymbol, MODE_DIGITS));

   int ticket = OrderSend(
      TradeSymbol,            // Symbol
      OP_BUY,                 // Order type (OP_BUY or OP_SELL)
      lotSize,                // Lot size
      NormalizeDouble(price, MarketInfo(TradeSymbol, MODE_DIGITS)), // Normalized price
      (int)slippage,          // Slippage as int
      sl,                     // Stop Loss
      tp,                     // Take Profit
      "Martingale Trade",      // Comment
      0,                      // Magic number
      0,                      // Expiration
      clrBlue                 // Arrow color
   );

   if (ticket < 0) {
      Print("Failed to place trade. Error: ", GetLastError());
      return false;
   }

   Print("Trade placed. Ticket: ", ticket, " | Lot size: ", lotSize);
   return MonitorTrade(ticket);
}

//+------------------------------------------------------------------+
//| Monitor the trade                                               |
//+------------------------------------------------------------------+
bool MonitorTrade(int ticket)
{
   while (true) {
      if (!OrderSelect(ticket, SELECT_BY_TICKET)) {
         Print("Failed to select order. Error: ", GetLastError());
         return false;
      }

      if (OrderCloseTime() > 0) {
         double profit = OrderProfit();
         if (profit > 0) {
            Print("Trade closed in profit. Profit: ", profit);
            return true;
         } else {
            Print("Trade closed in loss. Loss: ", profit);
            return false;
         }
      }

      Sleep(1000); // Wait 1 second before checking again
   }
}

