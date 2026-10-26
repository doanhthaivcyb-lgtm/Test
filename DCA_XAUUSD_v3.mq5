//+------------------------------------------------------------------+
//|                                            DCA_XAUUSD_v3.mq5     |
//|       Bot DCA + Hedge DCA Duong - MT5 - v3 Rescue  |
//|   Chuc nang v2: Chan tong lot, Chan margin, Tia moi tick,        |
//|   Bao ve lai tia, Chan chuoi moi khi margin thap,                     |
//|   Chong chay truoc stop-out cua san (khong cat lo som 10%)            |
//+------------------------------------------------------------------+
#property copyright "DCA XAUUSD Bot v3.0"
#property version   "3.00"
#property description "Bot DCA + Hedge DCA Duong xu ly lenh ket - v3 Rescue"
#property strict

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\AccountInfo.mqh>
#include <Trade\SymbolInfo.mqh>

//+------------------------------------------------------------------+
//| ENUMS                                                             |
//+------------------------------------------------------------------+
enum ENUM_CHE_DO_CHAY
{
   MODE_BUY_SELL = 0,  // Buy va Sell
   MODE_BUY_ONLY = 1,  // Chi Buy
   MODE_SELL_ONLY = 2   // Chi Sell
};

enum ENUM_CHE_DO_LOT
{
   MODE_CONG_LOT = 0,  // Cong Lots
   MODE_NHAN_LOT = 1   // Nhan Lots
};

//+------------------------------------------------------------------+
//| INPUT PARAMETERS                                                  |
//+------------------------------------------------------------------+

//--- GENERAL ---
input string   sep_general     = "====="; // ===XAUUSD TIMEFRAME BAT KY===
input ENUM_CHE_DO_CHAY InpCheDoChay = MODE_BUY_SELL; // Che Do Chay BOT
input ENUM_TIMEFRAMES  InpTimeframe = PERIOD_M1;      // Thoi Gian Mo Lenh
input double   InpMaxLot       = 1.5;    // Khoi Luong Lon Nhat
input int      InpMaxSpread    = 200;    // Gian Toi Da (Max Spread)
input int      InpMagicNumber  = 1112;   // Ma Dinh Danh (Magic Number)
input ENUM_CHE_DO_LOT InpCheDoLot = MODE_CONG_LOT; // Che Do Vao Lots
input bool     InpCheDoTia     = true;   // Che Do Tia Lenh
input double   InpPipSize      = 0.1;    // Gia Tri 1 Pip ($)
input int      InpSlippage     = 30;     // Slippage (Points)

//--- BO VE TAI KHOAN ---
input string   sep_protect     = "====="; // ===BO VE TAI KHOAN===
input double   InpStopProfitPct   = 0.0;  // Dung BOT Khi Duong (%) 0->Khong Dung
input double   InpStopProfitUSD   = 0.0;  // Dung BOT Khi Duong ($) 0->Khong Dung
input double   InpStopLossPct     = 0.0;  // Cat Lo va Dung BOT (%) 0->Khong Dung
input double   InpStopLossUSD     = 0.0;  // Cat Lo va Dung BOT ($) 0->Khong Dung

//--- TIA LENH DAI PHAP ---
input string   sep_trim        = "====="; // ===TIA LENH DAI PHAP===
input int      InpTrimActivate = 5;       // So Lenh Kich Hoat Tia. 0->Khong Dung
input int      InpTrimFirst    = 2;       // So Lenh Tia Dau
input int      InpTrimKeep     = 3;       // So Lenh Tia Cuoi
input double   InpTrimMinPips  = 4.0;     // >= Pips Tia Lenh

//--- QUAN LY VON ---
input string   sep_money       = "====="; // ===QUAN LY VON===
input bool     InpAutoLot      = false;   // Tang Lots Theo Von
input double   InpAutoLotPct   = 0.3;     // Ty Le TK (%)
input bool     InpCloseAll     = true;    // Dong Tat Ca Lenh
input double   InpTPTotal      = 50.0;    // Chot Loi Nhuan ($)
input double   InpTPOvernight  = 50.0;    // Chot Khi Dat ($) Lenh Qua Ngay

//--- TRAILING STOP ---
input string   sep_trail       = "====="; // ===TRAILING STOP===
input double   InpTrailStart   = 12.0;    // So Tien Bat Dau Trailing ($)
input double   InpTrailProtect = 7.0;     // So Tien Duoc Bao Toan ($)
input double   InpTrailStep    = 1.0;     // Buoc Nhay ($)

//--- DCA NHOM LENH 1 ---
input string   sep_g1          = "====="; // ===DCA NHOM LENH 1===
input int      InpG1_MaxOrders = 5;       // So Luong Lenh
input double   InpG1_StartLot  = 0.01;    // Lots Dau
input double   InpG1_Spacing   = 3.0;     // Khoang Cach Lenh (Pips)
input double   InpG1_TP        = 5.0;     // TP Chuoi DCA (Pips)
input double   InpG1_Multiply  = 1.5;     // He So Nhan Lots
input double   InpG1_Addition  = 0.0025;  // He So Cong Lots

//--- DCA NHOM LENH 2 ---
input string   sep_g2          = "====="; // ===DCA NHOM LENH 2===
input int      InpG2_MaxOrders = 15;      // So Luong Lenh
input double   InpG2_StartLot  = 0.05;    // Lots Dau
input double   InpG2_Spacing   = 3.0;     // Khoang Cach Lenh (Pips)
input double   InpG2_TP        = 5.0;     // TP Chuoi DCA (Pips)
input double   InpG2_Multiply  = 1.5;     // He So Nhan Lots
input double   InpG2_Addition  = 0.005;   // He So Cong Lots
input double   InpG2_Gap       = 5.0;     // Khoang Cach Voi Khoi 1 (Pips)

//--- DCA NHOM LENH 3 ---
input string   sep_g3          = "====="; // ===DCA NHOM LENH 3===
input int      InpG3_MaxOrders = 10;      // So Luong Lenh
input double   InpG3_StartLot  = 0.2;     // Lots Dau
input double   InpG3_Spacing   = 4.0;     // Khoang Cach Lenh (Pips)
input double   InpG3_TP        = 5.0;     // TP Chuoi DCA (Pips)
input double   InpG3_Multiply  = 1.2;     // He So Nhan Lots
input double   InpG3_Addition  = 0.01;    // He So Cong Lots
input double   InpG3_Gap       = 7.0;     // Khoang Cach Voi Khoi 2 (Pips)

//--- DCA NHOM LENH 4 ---
input string   sep_g4          = "====="; // ===DCA NHOM LENH 4===
input int      InpG4_MaxOrders = 10;      // So Luong Lenh
input double   InpG4_StartLot  = 0.1;     // Lots Dau
input double   InpG4_Spacing   = 5.0;     // Khoang Cach Lenh (Pips)
input double   InpG4_TP        = 15.0;    // TP Chuoi DCA (Pips)
input double   InpG4_Multiply  = 1.2;     // He So Nhan Lots
input double   InpG4_Addition  = 0.0;     // He So Cong Lots
input double   InpG4_Gap       = 9.0;     // Khoang Cach Voi Khoi 3 (Pips)

//--- DCA NHOM LENH 5 ---
input string   sep_g5          = "====="; // ===DCA NHOM LENH 5===
input int      InpG5_MaxOrders = 100;     // So Luong Lenh
input double   InpG5_StartLot  = 0.5;     // Lots Dau
input double   InpG5_Spacing   = 6.0;     // Khoang Cach Lenh (Pips)
input double   InpG5_TP        = 5.0;     // TP Chuoi DCA (Pips)
input double   InpG5_Multiply  = 1.2;     // He So Nhan Lots
input double   InpG5_Addition  = 0.0;     // He So Cong Lots
input double   InpG5_Gap       = 11.0;    // Khoang Cach Voi Khoi 4 (Pips)

//--- DCA HEDGE ---
input string   sep_hedge       = "====="; // ===DCA HEDGE (THUAN TREND)===
input bool     InpHedgeEnable  = true;    // Kich Hoat Hedge
input int      InpHedgeActivate = 5;      // So Lenh DCA Kich Hoat Hedge
input double   InpHedgeLotPct  = 30.0;    // % Lot Hedge so voi Tong Lot DCA
input double   InpHedgeStartLot = 0.03;   // Lots Dau Hedge
input double   InpHedgeAddition = 0.005;  // He So Cong Lots Hedge
input int      InpHedgeMaxOrders = 5;     // So Luong Lenh Hedge Toi Da
input double   InpHedgeSpacing = 5.0;     // Khoang Cach Lenh Hedge (Pips)
input double   InpHedgeTP      = 5.0;     // TP Hedge (Pips)
input bool     InpHedgeTrim    = true;    // Dung Lai Hedge De Tia Lenh DCA
input double   InpHedgeMaxLot  = 0.2;     // Max Lot Tong Hedge

//--- NONFARM ---
input string   sep_nfp         = "====="; // ===NONFARM===
input bool     InpStopNFP      = true;    // STOP BOT NonFarm

//--- CO CHE SONG LAU v2 (khong giam toc do mo lenh binh thuong) ---
input string   sep_survival    = "====="; // ===CO CHE SONG LAU v2===
input double   InpMaxTotalLot  = 3.0;     // Tong lot toi da toan TK (0->khong gioi han)
input double   InpMaxTotalLotPerDirection = 1.5; // Tong lot DCA toi da 1 chieu
input double   InpMinMarginLevelNewOrder = 200.0; // Margin Level toi thieu de mo lenh DCA/Hedge tiep theo (%)
input double   InpBlockNewChainMarginLevel = 300.0; // Margin Level toi thieu de mo chuoi moi (%)
input double   InpEmergencyTrimMarginLevel = 150.0; // Margin Level kich hoat tia khan cap (%)
input double   InpTrimMinNetProfit = 1.0;  // Tia chi chay khi lai rong >= so nay ($)
input double   InpSurvivalMarginLevel = 80.0; // Chong chay cuoi: dong het neu Margin Level < muc nay (%)
input double   InpSurvivalEquityDDPct = 70.0; // Chong chay cuoi: dong het neu DD tu dinh equity > muc nay (%)

//--- HEDGE DCA DUONG v3 (xu ly lenh ket, khong phai hedge cu HG) ---
input string   sep_hedgegroup  = "====="; // ===HEDGE DCA DUONG v3===
input bool     InpHedgeGroupEnable = true; // Kich hoat Hedge DCA Duong
input double   InpHedgeGroupMaxTotalLot = 1.0; // Tong lot Hedge DCA toi da 1 chieu
input double   InpHedgeGroupTP = 100.0; // Chot lai rieng cho chuoi Hedge DCA ($, 0->khong chot rieng)
input double   InpHedgeGroupActivateDistance = 20.0; // Chuoi chinh ket khi gia di nguoc >= muc nay (Pips)
input int      InpHG1_MaxOrders = 5;       // Hedge Nhom 1: So lenh
input double   InpHG1_StartLot  = 0.02;     // Hedge Nhom 1: Lot dau
input double   InpHG1_Spacing   = 5.0;      // Hedge Nhom 1: Khoang cach theo xu huong (Pips)
input double   InpHG1_Addition  = 0.01;     // Hedge Nhom 1: Cong lot (>=0.01 de khong bi lam tron ve 0)
input int      InpHG2_MaxOrders = 5;       // Hedge Nhom 2: So lenh
input double   InpHG2_StartLot  = 0.05;     // Hedge Nhom 2: Lot dau
input double   InpHG2_Spacing   = 5.0;      // Hedge Nhom 2: Khoang cach theo xu huong (Pips)
input double   InpHG2_Addition  = 0.01;     // Hedge Nhom 2: Cong lot
input double   InpHG2_Gap       = 5.0;      // Hedge Nhom 2: Khoang cach voi Nhom 1 (Pips)
input int      InpHG3_MaxOrders = 5;       // Hedge Nhom 3: So lenh
input double   InpHG3_StartLot  = 0.10;     // Hedge Nhom 3: Lot dau
input double   InpHG3_Spacing   = 6.0;      // Hedge Nhom 3: Khoang cach theo xu huong (Pips)
input double   InpHG3_Addition  = 0.01;     // Hedge Nhom 3: Cong lot
input double   InpHG3_Gap       = 7.0;      // Hedge Nhom 3: Khoang cach voi Nhom 2 (Pips)

//+------------------------------------------------------------------+
//| STRUCTURES                                                        |
//+------------------------------------------------------------------+
struct GroupParams
{
   int    maxOrders;
   double startLot;
   double spacing;
   double tpPips;
   double multiply;
   double addition;
   double gapFromPrev;
};

struct PositionData
{
   ulong  ticket;
   double openPrice;
   double lot;
   double profit;
   datetime openTime;
   string comment;
   int    group;       // 1-5 cho DCA, 0 cho hedge
   int    orderIndex;  // Thu tu trong nhom
   ENUM_POSITION_TYPE type;
};

//+------------------------------------------------------------------+
//| GLOBAL VARIABLES                                                  |
//+------------------------------------------------------------------+
CTrade         g_trade;
CPositionInfo  g_posInfo;
CAccountInfo   g_accInfo;
CSymbolInfo    g_symInfo;

GroupParams    g_groups[5];        // 5 nhom DCA
GroupParams    g_hedgeGroups[3];   // 3 nhom Hedge DCA Duong v3
datetime       g_lastBarTime;      // Thoi gian nen cuoi
bool           g_botStopped;       // Bot da dung
double         g_trailHighProfit;  // Lai cao nhat (cho trailing)
bool           g_trailActive;      // Trailing dang hoat dong
double         g_trailSL;          // Muc SL trailing hien tai
double         g_startBalance;     // Balance khi bat dau
double         g_peakEquity;       // Equity cao nhat tu khi bot chay (cho chong chay v2)

//+------------------------------------------------------------------+
//| Expert initialization                                             |
//+------------------------------------------------------------------+
int OnInit()
{
   // Kiem tra tai khoan hedging
   if(AccountInfoInteger(ACCOUNT_MARGIN_MODE) != ACCOUNT_MARGIN_MODE_RETAIL_HEDGING)
   {
      Alert("Bot yeu cau tai khoan HEDGING! Vui long su dung tai khoan hedging.");
      return(INIT_FAILED);
   }
   
   // Cau hinh trade
   g_trade.SetExpertMagicNumber(InpMagicNumber);
   g_trade.SetDeviationInPoints(InpSlippage);
   g_trade.SetTypeFilling(ORDER_FILLING_IOC);
   
   // Khoi tao symbol info
   g_symInfo.Name(_Symbol);
   g_symInfo.Refresh();
   
   // Khoi tao cac nhom DCA
   InitGroups();
   InitHedgeGroups();
   
   // Khoi tao bien
   g_lastBarTime = 0;
   g_botStopped = false;
   g_trailHighProfit = 0;
   g_trailActive = false;
   g_trailSL = 0;
   g_startBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   g_peakEquity = AccountInfoDouble(ACCOUNT_EQUITY);
   
   Print("===== DCA XAUUSD Bot v3.0 RESCUE STARTED =====");
   Print("Survival: MaxTotalLot=", DoubleToString(InpMaxTotalLot, 2),
         " | PerDirection=", DoubleToString(InpMaxTotalLotPerDirection, 2),
         " | MinMarginNewOrder=", DoubleToString(InpMinMarginLevelNewOrder, 1),
         " | SurvivalMargin=", DoubleToString(InpSurvivalMarginLevel, 1),
         " | SurvivalDD=", DoubleToString(InpSurvivalEquityDDPct, 1));
   Print("Mode: ", EnumToString(InpCheDoChay));
   Print("Lot Mode: ", InpCheDoLot == MODE_CONG_LOT ? "CONG LOTS" : "NHAN LOTS");
   Print("Hedge: ", InpHedgeEnable ? "ON" : "OFF");
   Print("Pip Size: ", DoubleToString(InpPipSize, 4));
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization                                           |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   Comment("");
   Print("===== DCA XAUUSD Bot v3.0 STOPPED =====");
}

//+------------------------------------------------------------------+
//| Khoi tao tham so cac nhom DCA                                    |
//+------------------------------------------------------------------+
void InitGroups()
{
   g_groups[0].maxOrders   = InpG1_MaxOrders;
   g_groups[0].startLot    = InpG1_StartLot;
   g_groups[0].spacing     = InpG1_Spacing;
   g_groups[0].tpPips      = InpG1_TP;
   g_groups[0].multiply    = InpG1_Multiply;
   g_groups[0].addition    = InpG1_Addition;
   g_groups[0].gapFromPrev = 0;
   
   g_groups[1].maxOrders   = InpG2_MaxOrders;
   g_groups[1].startLot    = InpG2_StartLot;
   g_groups[1].spacing     = InpG2_Spacing;
   g_groups[1].tpPips      = InpG2_TP;
   g_groups[1].multiply    = InpG2_Multiply;
   g_groups[1].addition    = InpG2_Addition;
   g_groups[1].gapFromPrev = InpG2_Gap;
   
   g_groups[2].maxOrders   = InpG3_MaxOrders;
   g_groups[2].startLot    = InpG3_StartLot;
   g_groups[2].spacing     = InpG3_Spacing;
   g_groups[2].tpPips      = InpG3_TP;
   g_groups[2].multiply    = InpG3_Multiply;
   g_groups[2].addition    = InpG3_Addition;
   g_groups[2].gapFromPrev = InpG3_Gap;
   
   g_groups[3].maxOrders   = InpG4_MaxOrders;
   g_groups[3].startLot    = InpG4_StartLot;
   g_groups[3].spacing     = InpG4_Spacing;
   g_groups[3].tpPips      = InpG4_TP;
   g_groups[3].multiply    = InpG4_Multiply;
   g_groups[3].addition    = InpG4_Addition;
   g_groups[3].gapFromPrev = InpG4_Gap;
   
   g_groups[4].maxOrders   = InpG5_MaxOrders;
   g_groups[4].startLot    = InpG5_StartLot;
   g_groups[4].spacing     = InpG5_Spacing;
   g_groups[4].tpPips      = InpG5_TP;
   g_groups[4].multiply    = InpG5_Multiply;
   g_groups[4].addition    = InpG5_Addition;
   g_groups[4].gapFromPrev = InpG5_Gap;
}

//+------------------------------------------------------------------+
//| Khoi tao tham so cac nhom Hedge DCA Duong v3                      |
//+------------------------------------------------------------------+
void InitHedgeGroups()
{
   g_hedgeGroups[0].maxOrders   = InpHG1_MaxOrders;
   g_hedgeGroups[0].startLot    = InpHG1_StartLot;
   g_hedgeGroups[0].spacing     = InpHG1_Spacing;
   g_hedgeGroups[0].tpPips      = 0;
   g_hedgeGroups[0].multiply    = 1.0;
   g_hedgeGroups[0].addition    = InpHG1_Addition;
   g_hedgeGroups[0].gapFromPrev = 0;

   g_hedgeGroups[1].maxOrders   = InpHG2_MaxOrders;
   g_hedgeGroups[1].startLot    = InpHG2_StartLot;
   g_hedgeGroups[1].spacing     = InpHG2_Spacing;
   g_hedgeGroups[1].tpPips      = 0;
   g_hedgeGroups[1].multiply    = 1.0;
   g_hedgeGroups[1].addition    = InpHG2_Addition;
   g_hedgeGroups[1].gapFromPrev = InpHG2_Gap;

   g_hedgeGroups[2].maxOrders   = InpHG3_MaxOrders;
   g_hedgeGroups[2].startLot    = InpHG3_StartLot;
   g_hedgeGroups[2].spacing     = InpHG3_Spacing;
   g_hedgeGroups[2].tpPips      = 0;
   g_hedgeGroups[2].multiply    = 1.0;
   g_hedgeGroups[2].addition    = InpHG3_Addition;
   g_hedgeGroups[2].gapFromPrev = InpHG3_Gap;
}

//+------------------------------------------------------------------+
//| Expert tick function - MAIN LOOP                                  |
//+------------------------------------------------------------------+
void OnTick()
{
   // Refresh du lieu
   g_symInfo.Refresh();
   g_symInfo.RefreshRates();
   
   // Kiem tra bot da dung chua
   if(g_botStopped) return;

   // Cap nhat dinh equity truoc khi kiem tra chong chay (v2)
   double currentEquity = AccountInfoDouble(ACCOUNT_EQUITY);
   if(currentEquity > g_peakEquity)
      g_peakEquity = currentEquity;
   
   // === XU LY TREN MOI TICK (khong cho nen dong) ===
   
   // 1. Kiem tra bao ve tai khoan (moi tick)
   if(CheckAccountProtection()) return;
   
   // 2. Kiem tra TP tong + Trailing (moi tick)
   if(CheckTotalTP()) return;
   ProcessTrailing();
   
   // 3. Kiem tra TP lenh qua ngay (moi tick)
   CheckOvernightTP();

   // 3b. TIA LENH MOI TICK (v2, thay cho chi tia khi nen dong o v1).
   //     Toc do khong giam: bot van mo DCA/Hedge nhu cu, chi tia som hon
   //     de giai phong margin truoc khi gia chay manh trong 1 phut.
   if(InpCheDoTia && InpTrimActivate > 0)
   {
      ProcessTrim(POSITION_TYPE_BUY);
      ProcessTrim(POSITION_TYPE_SELL);
   }

   // 3c. TIA KHAN CAP (v2): margin thap thi tia ca khi chua du dieu kien
   //     kich hoat thuong, nhung van phai co lai rong >= InpTrimMinNetProfit.
   if(InpCheDoTia && InpEmergencyTrimMarginLevel > 0)
   {
      double emMargin = AccountInfoDouble(ACCOUNT_MARGIN);
      double emLevel = AccountInfoDouble(ACCOUNT_MARGIN_LEVEL);
      if(emMargin > 0 && emLevel > 0 && emLevel < InpEmergencyTrimMarginLevel)
      {
         ProcessTrim(POSITION_TYPE_BUY, true);
         ProcessTrim(POSITION_TYPE_SELL, true);
      }
   }
   
   // 3d. HEDGE DCA DUONG v3 (moi tick, khong cho nen dong).
   //     Thu tu co y nghia: tia truoc (dung lai hedge de xu ly ket),
   //     roi chot lai rieng cho chuoi hedge neu con lai >= nguong,
   //     roi moi mo hedge moi neu chuoi chinh van ket.
   if(InpHedgeGroupEnable)
   {
      ProcessHedgeGroupTP(POSITION_TYPE_BUY);
      ProcessHedgeGroupTP(POSITION_TYPE_SELL);
      ProcessHedgeGroup(POSITION_TYPE_BUY);
      ProcessHedgeGroup(POSITION_TYPE_SELL);
   }

   // === XU LY KHI NEN DONG ===
   if(!IsNewCandle()) return;
   
   // 4. Kiem tra NFP
   if(InpStopNFP && IsNFPTime())
   {
      UpdateDisplay("DANG DUNG - NFP");
      return;
   }
   
   // 5. Kiem tra spread
   if(g_symInfo.Spread() > InpMaxSpread)
   {
      UpdateDisplay("CHO - Spread cao: " + IntegerToString(g_symInfo.Spread()));
      return;
   }
   
   // 6. Xu ly DCA cho chuoi BUY
   if(InpCheDoChay == MODE_BUY_SELL || InpCheDoChay == MODE_BUY_ONLY)
      ProcessDCAChain(POSITION_TYPE_BUY);
   
   // 7. Xu ly DCA cho chuoi SELL
   if(InpCheDoChay == MODE_BUY_SELL || InpCheDoChay == MODE_SELL_ONLY)
      ProcessDCAChain(POSITION_TYPE_SELL);
   
   // 8. Xu ly Hedge
   if(InpHedgeEnable)
   {
      ProcessHedge(POSITION_TYPE_BUY);  // Hedge cho chuoi BUY (mo SELL)
      ProcessHedge(POSITION_TYPE_SELL); // Hedge cho chuoi SELL (mo BUY)
   }
   
   // 9. Tia lenh da chay moi tick o muc 3b/3c (v2), khong lap lai o day.
   
   // 10. Cap nhat hien thi
   UpdateDisplay("DANG CHAY");
}

//+------------------------------------------------------------------+
//| Kiem tra nen moi (candle close)                                   |
//+------------------------------------------------------------------+
bool IsNewCandle()
{
   datetime currentBarTime = iTime(_Symbol, InpTimeframe, 0);
   if(currentBarTime == 0) return false;
   
   if(currentBarTime != g_lastBarTime)
   {
      g_lastBarTime = currentBarTime;
      return true;
   }
   return false;
}

//+------------------------------------------------------------------+
//| XU LY CHUOI DCA (BUY hoac SELL)                                  |
//+------------------------------------------------------------------+
void ProcessDCAChain(ENUM_POSITION_TYPE chainType)
{
   // Lay tat ca vi the DCA cua chuoi nay
   PositionData positions[];
   int count = GetDCAPositions(chainType, positions);
   
   // === CHUA CO LENH → MO LENH DAU TIEN ===
   if(count == 0)
   {
      OpenFirstOrder(chainType);
      return;
   }
   
   // === DA CO LENH → KIEM TRA DCA TIEP ===
   
   // Sap xep theo gia (BUY: cao->thap, SELL: thap->cao)
   SortPositionsByPrice(positions, chainType);
   
   // Xac dinh nhom hien tai va so lenh trong nhom
   int currentGroup = 0;
   int orderInGroup = 0;
   GetCurrentGroupInfo(positions, count, currentGroup, orderInGroup);
   
   // Kiem tra nhom hien tai da day chua
   if(currentGroup >= 5) return; // Da het 5 nhom
   
   if(orderInGroup >= g_groups[currentGroup].maxOrders)
   {
      // Nhom hien tai day → kiem tra chuyen sang nhom tiep theo
      int nextGroup = currentGroup + 1;
      if(nextGroup >= 5) return;
      
      // Kiem tra khoang cach gap
      double lastPrice = GetLastDCAPrice(positions, count, chainType);
      double currentPrice = (chainType == POSITION_TYPE_BUY) ? g_symInfo.Ask() : g_symInfo.Bid();
      double gapNeeded = g_groups[nextGroup].gapFromPrev * InpPipSize;
      
      double distance;
      if(chainType == POSITION_TYPE_BUY)
         distance = lastPrice - currentPrice;
      else
         distance = currentPrice - lastPrice;
      
      if(distance >= gapNeeded)
      {
         // Du gap → Mo lenh dau tien cua nhom moi
         double lot = GetGroupStartLot(nextGroup);
         OpenDCAOrder(chainType, lot, nextGroup, 1);
      }
   }
   else
   {
      // Nhom chua day → kiem tra spacing
      double lastPrice = GetLastDCAPrice(positions, count, chainType);
      double currentPrice = (chainType == POSITION_TYPE_BUY) ? g_symInfo.Ask() : g_symInfo.Bid();
      double spacingNeeded = g_groups[currentGroup].spacing * InpPipSize;
      
      double distance;
      if(chainType == POSITION_TYPE_BUY)
         distance = lastPrice - currentPrice;
      else
         distance = currentPrice - lastPrice;
      
      if(distance >= spacingNeeded)
      {
         // Du spacing → Tinh lot va mo lenh DCA
         int nextOrderIdx = orderInGroup + 1;
         double prevLot = positions[count - 1].lot; // Lot lenh cuoi cung
         double lot = CalculateNextLot(prevLot, currentGroup);
         OpenDCAOrder(chainType, lot, currentGroup, nextOrderIdx);
      }
   }
}

//+------------------------------------------------------------------+
//| Mo lenh dau tien (DCA Am - nguoc trend)                          |
//+------------------------------------------------------------------+
void OpenFirstOrder(ENUM_POSITION_TYPE chainType)
{
   // v2: Chan chuoi MOI khi margin thap, chuoi cu van chay binh thuong.
   if(InpBlockNewChainMarginLevel > 0)
   {
      double ncMargin = AccountInfoDouble(ACCOUNT_MARGIN);
      double ncLevel = AccountInfoDouble(ACCOUNT_MARGIN_LEVEL);
      if(ncMargin > 0 && ncLevel > 0 && ncLevel < InpBlockNewChainMarginLevel)
         return;
   }
   
   // DCA Am: Gia giam → BUY, Gia tang → SELL
   // Kiem tra nen truoc do
   double prevOpen = iOpen(_Symbol, InpTimeframe, 1);
   double prevClose = iClose(_Symbol, InpTimeframe, 1);
   
   if(prevOpen == 0 || prevClose == 0) return;
   
   bool isBearish = (prevClose < prevOpen);
   bool isBullish = (prevClose > prevOpen);
   
   // DCA Am: Nen giam → BUY, Nen tang → SELL
   if(chainType == POSITION_TYPE_BUY && !isBearish) return;
   if(chainType == POSITION_TYPE_SELL && !isBullish) return;
   
   // Lot dau tien
   double lot = GetGroupStartLot(0); // Nhom 1
   
   OpenDCAOrder(chainType, lot, 0, 1);
}

//+------------------------------------------------------------------+
//| Mo lenh DCA                                                       |
//+------------------------------------------------------------------+
bool OpenDCAOrder(ENUM_POSITION_TYPE type, double lot, int group, int orderIdx)
{
   // Chuan hoa lot
   lot = NormalizeLot(lot);
   if(lot <= 0) return false;

   // v2: Chan tong lot + chan margin TRUOC KHI mo lenh.
   //     Khong lam cham toc do mo lenh binh thuong: chi chan phan duoi
   //     cua chuoi DCA khi tong lot da sat gioi han.
   if(InpMaxTotalLot > 0)
   {
      double totalLotNow = GetTotalLots(POSITION_TYPE_BUY, false) + GetTotalLots(POSITION_TYPE_SELL, false);
      if(totalLotNow + lot > InpMaxTotalLot + 0.000001)
         return false;
   }
   if(InpMaxTotalLotPerDirection > 0)
   {
      double dirLotNow = GetTotalLots(type, true);
      if(dirLotNow + lot > InpMaxTotalLotPerDirection + 0.000001)
         return false;
   }
   if(InpMinMarginLevelNewOrder > 0)
   {
      double odMargin = AccountInfoDouble(ACCOUNT_MARGIN);
      double odLevel = AccountInfoDouble(ACCOUNT_MARGIN_LEVEL);
      if(odMargin > 0 && odLevel > 0 && odLevel < InpMinMarginLevelNewOrder)
         return false;
   }
   
   // Tao comment de nhan dien
   string comment = "DC" + (type == POSITION_TYPE_BUY ? "B" : "S") 
                    + IntegerToString(group + 1) + "_" + IntegerToString(orderIdx);
   
   double price;
   if(type == POSITION_TYPE_BUY)
   {
      price = g_symInfo.Ask();
      if(!g_trade.Buy(lot, _Symbol, price, 0, 0, comment))
      {
         Print("LOI mo lenh BUY: ", g_trade.ResultComment());
         return false;
      }
   }
   else
   {
      price = g_symInfo.Bid();
      if(!g_trade.Sell(lot, _Symbol, price, 0, 0, comment))
      {
         Print("LOI mo lenh SELL: ", g_trade.ResultComment());
         return false;
      }
   }
   
   Print("Mo lenh DCA: ", (type == POSITION_TYPE_BUY ? "BUY" : "SELL"),
         " | Nhom ", group + 1, " | Lenh #", orderIdx,
         " | Lot: ", DoubleToString(lot, 4),
         " | Gia: ", DoubleToString(price, (int)g_symInfo.Digits()));
   
   return true;
}

//+------------------------------------------------------------------+
//| Tinh lot cho lenh tiep theo                                      |
//+------------------------------------------------------------------+
double CalculateNextLot(double prevLot, int group)
{
   double nextLot;
   
   if(InpCheDoLot == MODE_CONG_LOT)
   {
      // Che do CONG: Lot[n] = Lot[n-1] + He So Cong
      nextLot = prevLot + g_groups[group].addition;
   }
   else
   {
      // Che do NHAN: Lot[n] = Lot[n-1] x He So Nhan
      nextLot = prevLot * g_groups[group].multiply;
   }
   
   return nextLot;
}

//+------------------------------------------------------------------+
//| Lay lot dau tien cua nhom (co tinh auto lot)                     |
//+------------------------------------------------------------------+
double GetGroupStartLot(int group)
{
   double lot = g_groups[group].startLot;
   
   // Neu bat tang lot theo von
   if(InpAutoLot)
   {
      double balance = AccountInfoDouble(ACCOUNT_BALANCE);
      double factor = (balance / g_startBalance) * (InpAutoLotPct / 0.3);
      lot = g_groups[group].startLot * factor;
   }
   
   return NormalizeLot(lot);
}

//+------------------------------------------------------------------+
//| TIA LENH DAI PHAP                                                |
//+------------------------------------------------------------------+
void ProcessTrim(ENUM_POSITION_TYPE chainType, bool emergency=false)
{
   PositionData positions[];
   int count = GetDCAPositions(chainType, positions);
   
   if(emergency)
   {
      // v2 tia khan cap: chi can it nhat 2 lenh, khong doi du so lenh
      // kich hoat va khong doi du khoang cach, nhung van giu it nhat 1 lenh.
      if(count < 2) return;
   }
   else
   {
      // Kiem tra dieu kien kich hoat
      if(count < InpTrimActivate) return;
      
      // Sap xep theo khoang cach tu gia hien tai (xa nhat truoc)
      SortPositionsByDistance(positions, chainType);
      
      // Kiem tra khoang cach toi thieu giua lenh dau va lenh cuoi
      double firstPrice = positions[0].openPrice;
      double lastPrice = positions[count - 1].openPrice;
      double distancePips = MathAbs(firstPrice - lastPrice) / InpPipSize;
      
      if(distancePips < InpTrimMinPips) return;
   }
   
   // Voi tia khan cap, can sap xep lai neu chua sap xep o tren.
   if(emergency)
      SortPositionsByDistance(positions, chainType);
   
   // Tinh tong lo cua cac lenh dau (can tia)
   int trimCount;
   if(emergency)
      trimCount = MathMin(InpTrimFirst, count - 1);
   else
      trimCount = MathMin(InpTrimFirst, count - InpTrimKeep);
   if(trimCount <= 0) return;
   
   double totalLoss = 0;
   for(int i = 0; i < trimCount; i++)
   {
      if(positions[i].profit < 0)
         totalLoss += positions[i].profit; // Gia tri am
   }
   
   if(totalLoss >= 0) return; // Khong co lenh lo → khong can tia
   
   // Tinh tong lai cua cac lenh cuoi (lenh gan gia)
   double totalProfit = 0;
   PositionData profitPositions[];
   int profitCount = 0;
   
   // Thu thap lenh co lai (tu cuoi len)
   for(int i = count - 1; i >= trimCount; i--)
   {
      if(positions[i].profit > 0)
      {
         ArrayResize(profitPositions, profitCount + 1);
         profitPositions[profitCount] = positions[i];
         totalProfit += positions[i].profit;
         profitCount++;
      }
   }
   
   // Kiem tra: Cung tinh lai tu hedge (neu bat)
   double hedgeProfit = 0;
   if(InpHedgeTrim)
   {
      PositionData hedgePositions[];
      ENUM_POSITION_TYPE hedgeType = (chainType == POSITION_TYPE_BUY) ? 
                                      POSITION_TYPE_SELL : POSITION_TYPE_BUY;
      int hedgeCount = GetHedgePositions(hedgeType, hedgePositions);
      
      for(int i = 0; i < hedgeCount; i++)
      {
         if(hedgePositions[i].profit > 0)
            hedgeProfit += hedgePositions[i].profit;
      }

      // v3: Lai tu Hedge DCA Duong (GH) cung duoc dung de tia lenh ket.
      if(InpHedgeGroupEnable)
      {
         PositionData ghPositionsCalc[];
         int ghCountCalc = GetHedgeGroupPositions(hedgeType, ghPositionsCalc);
         for(int i = 0; i < ghCountCalc; i++)
         {
            if(ghPositionsCalc[i].profit > 0)
               hedgeProfit += ghPositionsCalc[i].profit;
         }
      }
   }
   
   double availableProfit = totalProfit + hedgeProfit;
   
   // v2: Tia chi chay khi lai rong >= InpTrimMinNetProfit.
   //      Nghia la phep tia nay tu than no khong duoc lam tai khoan lo them,
   //      va phai giu lai it nhat muc lai nay (truoc phi/truot gia khi dong lenh).
   //      Day la "bao dam lai" o muc phep tia, khong phai bao dam lai tuyet doi
   //      cho ca tai khoan trong moi dieu kien thi truong.
   if(availableProfit < MathAbs(totalLoss) + InpTrimMinNetProfit) return;
   
   Print("=== TIA LENH: ", (chainType == POSITION_TYPE_BUY ? "BUY" : "SELL"),
         " | Lo can bu: ", DoubleToString(MathAbs(totalLoss), 2),
         " | Lai kha dung: ", DoubleToString(availableProfit, 2), " ===");
   
   // === THUC HIEN TIA ===
   
   // 1. Dong cac lenh lo xa
   double lossRealized = 0;
   for(int i = 0; i < trimCount; i++)
   {
      if(positions[i].profit < 0)
      {
         lossRealized += MathAbs(positions[i].profit);
         ClosePosition(positions[i].ticket);
         Print("TIA: Dong lenh LO #", positions[i].ticket,
               " | Lo: ", DoubleToString(positions[i].profit, 2));
      }
   }
   
   // 2. Dong (hoac dong 1 phan) lenh lai de bu lo
   double profitToRealize = lossRealized;
   
   // Uu tien dung lai hedge truoc (neu co)
   if(InpHedgeTrim && hedgeProfit > 0)
   {
      PositionData hedgePos[];
      ENUM_POSITION_TYPE hedgeType = (chainType == POSITION_TYPE_BUY) ? 
                                      POSITION_TYPE_SELL : POSITION_TYPE_BUY;
      int hCount = GetHedgePositions(hedgeType, hedgePos);
      
      for(int i = 0; i < hCount && profitToRealize > 0; i++)
      {
         if(hedgePos[i].profit > 0)
         {
            if(hedgePos[i].profit >= profitToRealize)
            {
               // Dong 1 phan lenh hedge
               double ratio = profitToRealize / hedgePos[i].profit;
               double closeLot = NormalizeLot(hedgePos[i].lot * ratio);
               if(closeLot > 0)
               {
                  g_trade.PositionClosePartial(hedgePos[i].ticket, closeLot);
                  Print("TIA: Dong 1 phan HEDGE #", hedgePos[i].ticket,
                        " | Lot dong: ", DoubleToString(closeLot, 4));
               }
               profitToRealize = 0;
            }
            else
            {
               profitToRealize -= hedgePos[i].profit;
               ClosePosition(hedgePos[i].ticket);
               Print("TIA: Dong toan bo HEDGE #", hedgePos[i].ticket);
            }
         }
      }
   }
   
   // v3: Dung lai Hedge DCA Duong (GH) sau hedge cu (HG), truoc DCA gan.
   if(InpHedgeTrim && InpHedgeGroupEnable && profitToRealize > 0)
   {
      PositionData ghPos[];
      ENUM_POSITION_TYPE ghHedgeType = (chainType == POSITION_TYPE_BUY) ?
                                        POSITION_TYPE_SELL : POSITION_TYPE_BUY;
      int ghCount = GetHedgeGroupPositions(ghHedgeType, ghPos);

      for(int i = 0; i < ghCount && profitToRealize > 0; i++)
      {
         if(ghPos[i].profit > 0)
         {
            if(ghPos[i].profit >= profitToRealize)
            {
               double ratio = profitToRealize / ghPos[i].profit;
               double closeLot = NormalizeLot(ghPos[i].lot * ratio);
               if(closeLot > 0)
               {
                  g_trade.PositionClosePartial(ghPos[i].ticket, closeLot);
                  Print("TIA: Dong 1 phan HEDGE-DCA #", ghPos[i].ticket,
                        " | Lot dong: ", DoubleToString(closeLot, 4));
               }
               profitToRealize = 0;
            }
            else
            {
               profitToRealize -= ghPos[i].profit;
               ClosePosition(ghPos[i].ticket);
               Print("TIA: Dong toan bo HEDGE-DCA #", ghPos[i].ticket);
            }
         }
      }
   }

   // Dung lai cac lenh DCA gan de bu phan con lai
   for(int i = 0; i < profitCount && profitToRealize > 0; i++)
   {
      if(profitPositions[i].profit >= profitToRealize)
      {
         // Dong 1 phan
         double ratio = profitToRealize / profitPositions[i].profit;
         double closeLot = NormalizeLot(profitPositions[i].lot * ratio);
         if(closeLot > 0 && closeLot < profitPositions[i].lot)
         {
            g_trade.PositionClosePartial(profitPositions[i].ticket, closeLot);
            Print("TIA: Dong 1 phan DCA #", profitPositions[i].ticket,
                  " | Lot dong: ", DoubleToString(closeLot, 4));
         }
         else
         {
            ClosePosition(profitPositions[i].ticket);
         }
         profitToRealize = 0;
      }
      else
      {
         profitToRealize -= profitPositions[i].profit;
         ClosePosition(profitPositions[i].ticket);
         Print("TIA: Dong toan bo DCA #", profitPositions[i].ticket);
      }
   }
   
   Print("=== TIA LENH HOAN TAT ===");
}

//+------------------------------------------------------------------+
//| XU LY HEDGE                                                       |
//+------------------------------------------------------------------+
void ProcessHedge(ENUM_POSITION_TYPE mainChainType)
{
   // Dem so lenh DCA cua chuoi chinh
   PositionData dcaPositions[];
   int dcaCount = GetDCAPositions(mainChainType, dcaPositions);
   
   // Chua du lenh de kich hoat hedge
   if(dcaCount < InpHedgeActivate) return;
   
   // Hedge la chieu NGUOC chuoi chinh
   ENUM_POSITION_TYPE hedgeType = (mainChainType == POSITION_TYPE_BUY) ? 
                                   POSITION_TYPE_SELL : POSITION_TYPE_BUY;
   
   // Lay cac vi the hedge hien tai
   PositionData hedgePositions[];
   int hedgeCount = GetHedgePositions(hedgeType, hedgePositions);
   
   // Kiem tra da dat toi da lenh hedge chua
   if(hedgeCount >= InpHedgeMaxOrders) return;
   
   // Kiem tra tong lot hedge khong vuot qua gioi han
   double totalHedgeLot = 0;
   for(int i = 0; i < hedgeCount; i++)
      totalHedgeLot += hedgePositions[i].lot;
   
   if(totalHedgeLot >= InpHedgeMaxLot) return;
   
   // Kiem tra tong lot hedge khong vuot % tong lot DCA
   double totalDCALot = 0;
   for(int i = 0; i < dcaCount; i++)
      totalDCALot += dcaPositions[i].lot;
   
   double maxHedgeLot = totalDCALot * InpHedgeLotPct / 100.0;
   if(totalHedgeLot >= maxHedgeLot) return;
   
   // Kiem tra spacing cho lenh hedge tiep theo
   double currentPrice = (hedgeType == POSITION_TYPE_BUY) ? g_symInfo.Ask() : g_symInfo.Bid();
   double spacingNeeded = InpHedgeSpacing * InpPipSize;
   
   if(hedgeCount > 0)
   {
      double lastHedgePrice = GetLastHedgePrice(hedgePositions, hedgeCount, hedgeType);
      double distance;
      
      if(hedgeType == POSITION_TYPE_SELL)
         distance = currentPrice - lastHedgePrice;
      else
         distance = lastHedgePrice - currentPrice;
      
      if(distance < spacingNeeded) return;
   }
   else
   {
      // Lenh hedge dau tien - kiem tra khoang cach tu lenh DCA cuoi
      double lastDCAPrice = GetLastDCAPrice(dcaPositions, dcaCount, mainChainType);
      double distance;
      
      if(mainChainType == POSITION_TYPE_BUY)
         distance = lastDCAPrice - currentPrice; // Gia dang thap hon DCA cuoi
      else
         distance = currentPrice - lastDCAPrice; // Gia dang cao hon DCA cuoi
      
      if(distance < spacingNeeded) return;
   }
   
   // Tinh lot cho lenh hedge
   double hedgeLot;
   if(hedgeCount == 0)
      hedgeLot = InpHedgeStartLot;
   else
      hedgeLot = hedgePositions[hedgeCount - 1].lot + InpHedgeAddition;
   
   hedgeLot = MathMin(hedgeLot, InpHedgeMaxLot - totalHedgeLot);
   hedgeLot = NormalizeLot(hedgeLot);
   if(hedgeLot <= 0) return;

   // v2: Hedge cung bi chan tong lot va chan margin nhu DCA.
   if(InpMaxTotalLot > 0)
   {
      double hgTotalLotNow = GetTotalLots(POSITION_TYPE_BUY, false) + GetTotalLots(POSITION_TYPE_SELL, false);
      if(hgTotalLotNow + hedgeLot > InpMaxTotalLot + 0.000001)
         return;
   }
   if(InpMinMarginLevelNewOrder > 0)
   {
      double hgMargin = AccountInfoDouble(ACCOUNT_MARGIN);
      double hgLevel = AccountInfoDouble(ACCOUNT_MARGIN_LEVEL);
      if(hgMargin > 0 && hgLevel > 0 && hgLevel < InpMinMarginLevelNewOrder)
         return;
   }
   
   // Mo lenh hedge
   string comment = "HG" + (hedgeType == POSITION_TYPE_BUY ? "B" : "S") 
                    + "_" + IntegerToString(hedgeCount + 1);
   
   double price;
   bool result;
   if(hedgeType == POSITION_TYPE_BUY)
   {
      price = g_symInfo.Ask();
      result = g_trade.Buy(hedgeLot, _Symbol, price, 0, 0, comment);
   }
   else
   {
      price = g_symInfo.Bid();
      result = g_trade.Sell(hedgeLot, _Symbol, price, 0, 0, comment);
   }
   
   if(result)
   {
      Print("Mo HEDGE: ", (hedgeType == POSITION_TYPE_BUY ? "BUY" : "SELL"),
            " | Lot: ", DoubleToString(hedgeLot, 4),
            " | Gia: ", DoubleToString(price, (int)g_symInfo.Digits()),
            " | Cho chuoi ", (mainChainType == POSITION_TYPE_BUY ? "BUY" : "SELL"));
   }
}

//+------------------------------------------------------------------+
//| LAY TAT CA VI THE HEDGE DCA DUONG (GH) CUA 1 CHIEU v3             |
//+------------------------------------------------------------------+
int GetHedgeGroupPositions(ENUM_POSITION_TYPE type, PositionData &positions[])
{
   ArrayResize(positions, 0);
   int count = 0;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket <= 0) continue;
      if(PositionGetInteger(POSITION_MAGIC) != InpMagicNumber) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE) != type) continue;

      string comment = PositionGetString(POSITION_COMMENT);
      // Chi lay lenh Hedge DCA Duong (bat dau bang "GH"), khong lay HG cu.
      if(StringFind(comment, "GH") != 0) continue;

      ArrayResize(positions, count + 1);
      positions[count].ticket    = ticket;
      positions[count].openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      positions[count].lot       = PositionGetDouble(POSITION_VOLUME);
      positions[count].profit    = PositionGetDouble(POSITION_PROFIT) +
                                   PositionGetDouble(POSITION_SWAP);
      positions[count].openTime  = (datetime)PositionGetInteger(POSITION_TIME);
      positions[count].comment   = comment;
      positions[count].type      = type;
      ParseComment(comment, positions[count].group, positions[count].orderIndex);

      count++;
   }

   return count;
}

//+------------------------------------------------------------------+
//| Xac dinh nhom Hedge DCA hien tai v3                               |
//+------------------------------------------------------------------+
void GetHedgeGroupInfo(PositionData &positions[], int count, int &currentGroup, int &orderInGroup)
{
   currentGroup = 0;
   orderInGroup = 0;
   int groupCounts[3] = {0, 0, 0};

   for(int i = 0; i < count; i++)
   {
      int g = positions[i].group;
      if(g >= 0 && g < 3)
         groupCounts[g]++;
   }

   currentGroup = 0;
   for(int g = 2; g >= 0; g--)
   {
      if(groupCounts[g] > 0)
      {
         currentGroup = g;
         break;
      }
   }

   orderInGroup = groupCounts[currentGroup];
}

//+------------------------------------------------------------------+
//| Gia Hedge DCA cuoi theo xu huong v3 (BUY: cao nhat, SELL: thap nhat)|
//+------------------------------------------------------------------+
double GetLastHedgeGroupPrice(PositionData &positions[], int count, ENUM_POSITION_TYPE type)
{
   if(count == 0) return 0;
   double lastPrice = positions[0].openPrice;
   for(int i = 1; i < count; i++)
   {
      if(type == POSITION_TYPE_BUY)
      {
         if(positions[i].openPrice > lastPrice)
            lastPrice = positions[i].openPrice;
      }
      else
      {
         if(positions[i].openPrice < lastPrice)
            lastPrice = positions[i].openPrice;
      }
   }
   return lastPrice;
}

//+------------------------------------------------------------------+
//| Mo 1 lenh Hedge DCA Duong v3                                      |
//+------------------------------------------------------------------+
bool OpenHedgeGroupOrder(ENUM_POSITION_TYPE type, double lot, int group, int orderIdx)
{
   lot = NormalizeLot(lot);
   if(lot <= 0) return false;

   string comment = "GH" + (type == POSITION_TYPE_BUY ? "B" : "S")
                    + IntegerToString(group + 1) + "_" + IntegerToString(orderIdx);

   double price;
   bool result = false;
   if(type == POSITION_TYPE_BUY)
   {
      price = g_symInfo.Ask();
      result = g_trade.Buy(lot, _Symbol, price, 0, 0, comment);
   }
   else
   {
      price = g_symInfo.Bid();
      result = g_trade.Sell(lot, _Symbol, price, 0, 0, comment);
   }

   if(result)
   {
      Print("Mo HEDGE-DCA: ", (type == POSITION_TYPE_BUY ? "BUY" : "SELL"),
            " | Nhom ", group + 1, " | Lenh #", orderIdx,
            " | Lot: ", DoubleToString(lot, 4),
            " | Gia: ", DoubleToString(price, (int)g_symInfo.Digits()));
   }
   else
   {
      Print("LOI mo HEDGE-DCA: ", g_trade.ResultComment());
   }
   return result;
}

//+------------------------------------------------------------------+
//| XU LY HEDGE DCA DUONG v3                                          |
//| - Chi mo khi chuoi DCA chinh KET: du lenh, dang lo, va gia da di  |
//|   nguoc chuoi chinh >= InpHedgeGroupActivateDistance.             |
//| - Cong lenh THEO XU HUONG (DCA duong): BUY thi mua cao hon,        |
//|   SELL thi ban thap hon, khong doi gia hoi ve nhu hedge cu.       |
//| - Khong mo vuot tong lot, tong lot hedge nhom, va chan margin.    |
//+------------------------------------------------------------------+
void ProcessHedgeGroup(ENUM_POSITION_TYPE mainChainType)
{
   if(!InpHedgeGroupEnable) return;

   PositionData dcaPositions[];
   int dcaCount = GetDCAPositions(mainChainType, dcaPositions);
   if(dcaCount < InpHedgeActivate) return;

   // Chuoi chinh phai dang lo moi can cuu.
   double dcaProfit = 0;
   for(int i = 0; i < dcaCount; i++)
      dcaProfit += dcaPositions[i].profit;
   if(dcaProfit >= 0) return;

   double dcaAvg = GetAveragePrice(dcaPositions, dcaCount);
   if(dcaAvg <= 0) return;

   ENUM_POSITION_TYPE hedgeType = (mainChainType == POSITION_TYPE_BUY) ?
                                   POSITION_TYPE_SELL : POSITION_TYPE_BUY;
   double currentPrice = (hedgeType == POSITION_TYPE_BUY) ? g_symInfo.Ask() : g_symInfo.Bid();

   // Khoang cach gia da di nguoc chuoi chinh.
   double adverseDistance;
   if(mainChainType == POSITION_TYPE_SELL)
      adverseDistance = currentPrice - dcaAvg;
   else
      adverseDistance = dcaAvg - currentPrice;
   if(adverseDistance < InpHedgeGroupActivateDistance * InpPipSize) return;

   PositionData ghPositions[];
   int ghCount = GetHedgeGroupPositions(hedgeType, ghPositions);

   double ghTotalLot = 0;
   for(int i = 0; i < ghCount; i++)
      ghTotalLot += ghPositions[i].lot;

   // Lenh dau tien cua chuoi Hedge DCA: mo ngay tai gia thi truong,
   // vi chuoi chinh da ket va gia da chay xa, khong doi them dieu kien.
   if(ghCount == 0)
   {
      double firstLot = g_hedgeGroups[0].startLot;
      if(InpHedgeGroupMaxTotalLot > 0 && firstLot > InpHedgeGroupMaxTotalLot) return;
      if(InpMaxTotalLot > 0)
      {
         double totalNow = GetTotalLots(POSITION_TYPE_BUY, false) + GetTotalLots(POSITION_TYPE_SELL, false);
         if(totalNow + NormalizeLot(firstLot) > InpMaxTotalLot + 0.000001) return;
      }
      if(InpMinMarginLevelNewOrder > 0)
      {
         double m = AccountInfoDouble(ACCOUNT_MARGIN);
         double lv = AccountInfoDouble(ACCOUNT_MARGIN_LEVEL);
         if(m > 0 && lv > 0 && lv < InpMinMarginLevelNewOrder) return;
      }
      OpenHedgeGroupOrder(hedgeType, firstLot, 0, 1);
      return;
   }

   int currentGroup = 0;
   int orderInGroup = 0;
   GetHedgeGroupInfo(ghPositions, ghCount, currentGroup, orderInGroup);
   if(currentGroup >= 3) return;

   double lastPrice = GetLastHedgeGroupPrice(ghPositions, ghCount, hedgeType);

   // Nhom hien tai day -> chuyen nhom tiep theo neu du gap theo xu huong.
   if(orderInGroup >= g_hedgeGroups[currentGroup].maxOrders)
   {
      int nextGroup = currentGroup + 1;
      if(nextGroup >= 3) return;

      double gapNeeded = g_hedgeGroups[nextGroup].gapFromPrev * InpPipSize;
      double gapDistance;
      if(hedgeType == POSITION_TYPE_BUY)
         gapDistance = currentPrice - lastPrice;
      else
         gapDistance = lastPrice - currentPrice;
      if(gapDistance < gapNeeded) return;

      double nextLot = g_hedgeGroups[nextGroup].startLot;
      if(InpHedgeGroupMaxTotalLot > 0 && ghTotalLot + NormalizeLot(nextLot) > InpHedgeGroupMaxTotalLot + 0.000001) return;
      if(InpMaxTotalLot > 0)
      {
         double totalNow2 = GetTotalLots(POSITION_TYPE_BUY, false) + GetTotalLots(POSITION_TYPE_SELL, false);
         if(totalNow2 + NormalizeLot(nextLot) > InpMaxTotalLot + 0.000001) return;
      }
      if(InpMinMarginLevelNewOrder > 0)
      {
         double m2 = AccountInfoDouble(ACCOUNT_MARGIN);
         double lv2 = AccountInfoDouble(ACCOUNT_MARGIN_LEVEL);
         if(m2 > 0 && lv2 > 0 && lv2 < InpMinMarginLevelNewOrder) return;
      }
      OpenHedgeGroupOrder(hedgeType, nextLot, nextGroup, 1);
      return;
   }

   // Nhom chua day -> cong lenh theo xu huong neu du spacing.
   double spacingNeeded = g_hedgeGroups[currentGroup].spacing * InpPipSize;
   double spacingDistance;
   if(hedgeType == POSITION_TYPE_BUY)
      spacingDistance = currentPrice - lastPrice;
   else
      spacingDistance = lastPrice - currentPrice;
   if(spacingDistance < spacingNeeded) return;

   // Lot tiep theo tinh theo thu tu trong nhom, khong lay lot cua lenh
   // cuoi theo thoi gian (tranh loi lam tron buoc lot cua san).
   double nextLotInGroup = g_hedgeGroups[currentGroup].startLot + orderInGroup * g_hedgeGroups[currentGroup].addition;
   if(InpHedgeGroupMaxTotalLot > 0 && ghTotalLot + NormalizeLot(nextLotInGroup) > InpHedgeGroupMaxTotalLot + 0.000001) return;
   if(InpMaxTotalLot > 0)
   {
      double totalNow3 = GetTotalLots(POSITION_TYPE_BUY, false) + GetTotalLots(POSITION_TYPE_SELL, false);
      if(totalNow3 + NormalizeLot(nextLotInGroup) > InpMaxTotalLot + 0.000001) return;
   }
   if(InpMinMarginLevelNewOrder > 0)
   {
      double m3 = AccountInfoDouble(ACCOUNT_MARGIN);
      double lv3 = AccountInfoDouble(ACCOUNT_MARGIN_LEVEL);
      if(m3 > 0 && lv3 > 0 && lv3 < InpMinMarginLevelNewOrder) return;
   }
   OpenHedgeGroupOrder(hedgeType, nextLotInGroup, currentGroup, orderInGroup + 1);
}

//+------------------------------------------------------------------+
//| CHOT LAI RIENG CHO CHUOI HEDGE DCA v3                             |
//| - Lai hedge khong bi giu lai boi tong floating am cua chuoi ket.  |
//| - Khi lai chuoi hedge >= nguong, dong het chuoi hedge do de       |
//|   bank lai, sau do chuoi hedge co the mo lai neu van ket.         |
//+------------------------------------------------------------------+
void ProcessHedgeGroupTP(ENUM_POSITION_TYPE mainChainType)
{
   if(!InpHedgeGroupEnable || InpHedgeGroupTP <= 0) return;

   ENUM_POSITION_TYPE hedgeType = (mainChainType == POSITION_TYPE_BUY) ?
                                   POSITION_TYPE_SELL : POSITION_TYPE_BUY;
   PositionData ghPositions[];
   int ghCount = GetHedgeGroupPositions(hedgeType, ghPositions);
   if(ghCount == 0) return;

   double ghProfit = 0;
   for(int i = 0; i < ghCount; i++)
      ghProfit += ghPositions[i].profit;

   if(ghProfit >= InpHedgeGroupTP)
   {
      Print("=== HEDGE-DCA TP: ", (hedgeType == POSITION_TYPE_BUY ? "BUY" : "SELL"),
            " | Lai chuoi: $", DoubleToString(ghProfit, 2),
            " | Dong het chuoi hedge de bank lai ===");
      for(int i = 0; i < ghCount; i++)
         ClosePosition(ghPositions[i].ticket);
   }
}

//+------------------------------------------------------------------+
//| KIEM TRA TP TONG                                                  |
//+------------------------------------------------------------------+
bool CheckTotalTP()
{
   double totalProfit = GetTotalFloatingProfit();
   
   // TP tong
   if(InpTPTotal > 0 && totalProfit >= InpTPTotal)
   {
      Print("=== CHOT LOI TONG: $", DoubleToString(totalProfit, 2), " ===");
      
      if(InpCloseAll)
         CloseAllPositions();
      
      // Reset trailing
      g_trailActive = false;
      g_trailHighProfit = 0;
      g_trailSL = 0;
      
      return true;
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| KIEM TRA TP LENH QUA NGAY                                         |
//+------------------------------------------------------------------+
void CheckOvernightTP()
{
   if(InpTPOvernight <= 0) return;
   
   datetime todayStart = StringToTime(TimeToString(TimeCurrent(), TIME_DATE));
   double overnightProfit = 0;
   int overnightCount = 0;
   ulong overnightTickets[];
   
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket <= 0) continue;
      if(PositionGetInteger(POSITION_MAGIC) != InpMagicNumber) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      
      datetime openTime = (datetime)PositionGetInteger(POSITION_TIME);
      if(openTime < todayStart)
      {
         overnightProfit += PositionGetDouble(POSITION_PROFIT) + 
                           PositionGetDouble(POSITION_SWAP);
         ArrayResize(overnightTickets, overnightCount + 1);
         overnightTickets[overnightCount] = ticket;
         overnightCount++;
      }
   }
   
   if(overnightCount > 0 && overnightProfit >= InpTPOvernight)
   {
      Print("=== CHOT LOI LENH QUA NGAY: $", DoubleToString(overnightProfit, 2),
            " | ", overnightCount, " lenh ===");
      
      for(int i = 0; i < overnightCount; i++)
         ClosePosition(overnightTickets[i]);
   }
}

//+------------------------------------------------------------------+
//| TRAILING STOP                                                     |
//+------------------------------------------------------------------+
void ProcessTrailing()
{
   if(InpTrailStart <= 0) return;
   
   double totalProfit = GetTotalFloatingProfit();
   
   if(!g_trailActive)
   {
      // Kiem tra kich hoat trailing
      if(totalProfit >= InpTrailStart)
      {
         g_trailActive = true;
         g_trailHighProfit = totalProfit;
         g_trailSL = InpTrailProtect;
         Print("TRAILING KICH HOAT | Lai: $", DoubleToString(totalProfit, 2),
               " | Bao toan: $", DoubleToString(g_trailSL, 2));
      }
   }
   else
   {
      // Cap nhat trailing
      if(totalProfit > g_trailHighProfit)
      {
         double diff = totalProfit - g_trailHighProfit;
         int steps = (int)(diff / InpTrailStep);
         
         if(steps > 0)
         {
            g_trailHighProfit += steps * InpTrailStep;
            g_trailSL += steps * InpTrailStep;
         }
      }
      
      // Kiem tra chạm trailing SL
      if(totalProfit <= g_trailSL && totalProfit > 0)
      {
         Print("=== TRAILING CHOT LOI: $", DoubleToString(totalProfit, 2),
               " | SL Trailing: $", DoubleToString(g_trailSL, 2), " ===");
         
         if(InpCloseAll)
            CloseAllPositions();
         
         g_trailActive = false;
         g_trailHighProfit = 0;
         g_trailSL = 0;
      }
   }
}

//+------------------------------------------------------------------+
//| BAO VE TAI KHOAN                                                  |
//+------------------------------------------------------------------+
bool CheckAccountProtection()
{
   // v2: Chong chay cuoi cung, chay TRUOC cac quy tac cu.
   //     Day KHONG phai stop 10% cua ban safe truoc: no chi kich hoat khi
   //     da sat stop-out cua san hoac DD tu dinh da rat lon, de giu DD < 100%.
   //     Trong thi truong gap manh, khong co co che nao bao dam tuyet doi
   //     khoi vuot nguong, vi gia co the nhay qua nguong trong 1 tick.
   if(InpSurvivalMarginLevel > 0 || InpSurvivalEquityDDPct > 0)
   {
      double svEquity = AccountInfoDouble(ACCOUNT_EQUITY);
      double svMargin = AccountInfoDouble(ACCOUNT_MARGIN);
      double svLevel = AccountInfoDouble(ACCOUNT_MARGIN_LEVEL);
      if(InpSurvivalMarginLevel > 0 && svMargin > 0 && svLevel > 0 && svLevel < InpSurvivalMarginLevel)
      {
         Print("=== SURVIVAL GUARD: Margin Level ", DoubleToString(svLevel, 2),
               "% < ", DoubleToString(InpSurvivalMarginLevel, 1), "% -> Dong het va dung bot ===");
         CloseAllPositions();
         g_botStopped = true;
         return true;
      }
      if(InpSurvivalEquityDDPct > 0 && g_peakEquity > 0)
      {
         double svDD = (g_peakEquity - svEquity) / g_peakEquity * 100.0;
         if(svDD > InpSurvivalEquityDDPct)
         {
            Print("=== SURVIVAL GUARD: DD tu dinh ", DoubleToString(svDD, 2),
                  "% > ", DoubleToString(InpSurvivalEquityDDPct, 1), "% -> Dong het va dung bot ===");
            CloseAllPositions();
            g_botStopped = true;
            return true;
         }
      }
   }

   double totalProfit = GetTotalFloatingProfit();
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double profitPct = (balance > 0) ? (totalProfit / balance * 100.0) : 0;
   
   // Dung bot khi lai dat %
   if(InpStopProfitPct > 0 && profitPct >= InpStopProfitPct)
   {
      Print("=== DUNG BOT: Lai dat ", DoubleToString(profitPct, 2), "% ===");
      g_botStopped = true;
      return true;
   }
   
   // Dung bot khi lai dat $
   if(InpStopProfitUSD > 0 && totalProfit >= InpStopProfitUSD)
   {
      Print("=== DUNG BOT: Lai dat $", DoubleToString(totalProfit, 2), " ===");
      g_botStopped = true;
      return true;
   }
   
   // Cat lo khi lo dat %
   if(InpStopLossPct > 0 && profitPct <= -InpStopLossPct)
   {
      Print("=== CAT LO: Lo dat ", DoubleToString(MathAbs(profitPct), 2), "% ===");
      CloseAllPositions();
      g_botStopped = true;
      return true;
   }
   
   // Cat lo khi lo dat $
   if(InpStopLossUSD > 0 && totalProfit <= -InpStopLossUSD)
   {
      Print("=== CAT LO: Lo dat $", DoubleToString(MathAbs(totalProfit), 2), " ===");
      CloseAllPositions();
      g_botStopped = true;
      return true;
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| KIEM TRA THOI GIAN NFP                                            |
//+------------------------------------------------------------------+
bool IsNFPTime()
{
   MqlDateTime dt;
   TimeCurrent(dt);
   
   // NFP: Thu 6 dau tien cua thang, luc 20:30 (GMT+7) = 13:30 UTC
   // Dung bot tu 12:00 UTC den 15:00 UTC ngay NFP
   
   // Tim thu 6 dau tien cua thang
   datetime firstDay = StringToTime(IntegerToString(dt.year) + "." + 
                                     IntegerToString(dt.mon) + ".01");
   MqlDateTime firstDt;
   TimeToStruct(firstDay, firstDt);
   
   // day_of_week: 0=Sun, 1=Mon, ..., 5=Fri, 6=Sat
   int daysToFriday;
   if(firstDt.day_of_week <= 5)
      daysToFriday = (5 - firstDt.day_of_week) % 7;
   else
      daysToFriday = 6; // Sat → next Fri = 6 days
   
   if(daysToFriday == 0 && firstDt.day_of_week != 5)
      daysToFriday = 7;
   
   int nfpDay = 1 + daysToFriday;
   if(firstDt.day_of_week == 5) nfpDay = 1; // Ngay 1 la thu 6
   
   // Kiem tra hom nay co phai ngay NFP khong
   if(dt.day == nfpDay)
   {
      // Dung bot tu 12:00 den 16:00 UTC (19:00-23:00 GMT+7)
      int hourUTC = dt.hour;
      if(hourUTC >= 12 && hourUTC <= 16)
         return true;
   }
   
   // Dung bot ngay truoc NFP (thu 5) tu 20:00 UTC
   if(dt.day == nfpDay - 1 && dt.hour >= 20)
      return true;
   
   return false;
}

//+------------------------------------------------------------------+
//| LAY TAT CA VI THE DCA CUA 1 CHIEU                                |
//+------------------------------------------------------------------+
int GetDCAPositions(ENUM_POSITION_TYPE type, PositionData &positions[])
{
   ArrayResize(positions, 0);
   int count = 0;
   
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket <= 0) continue;
      if(PositionGetInteger(POSITION_MAGIC) != InpMagicNumber) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE) != type) continue;
      
      string comment = PositionGetString(POSITION_COMMENT);
      // Chi lay lenh DCA (bat dau bang "DC"), khong lay hedge ("HG")
      if(StringFind(comment, "DC") != 0) continue;
      
      ArrayResize(positions, count + 1);
      positions[count].ticket    = ticket;
      positions[count].openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      positions[count].lot       = PositionGetDouble(POSITION_VOLUME);
      positions[count].profit    = PositionGetDouble(POSITION_PROFIT) + 
                                   PositionGetDouble(POSITION_SWAP);
      positions[count].openTime  = (datetime)PositionGetInteger(POSITION_TIME);
      positions[count].comment   = comment;
      positions[count].type      = type;
      
      // Parse group tu comment (VD: "DCB2_5" → group=1, index=5)
      ParseComment(comment, positions[count].group, positions[count].orderIndex);
      
      count++;
   }
   
   return count;
}

//+------------------------------------------------------------------+
//| LAY TAT CA VI THE HEDGE CUA 1 CHIEU                              |
//+------------------------------------------------------------------+
int GetHedgePositions(ENUM_POSITION_TYPE type, PositionData &positions[])
{
   ArrayResize(positions, 0);
   int count = 0;
   
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket <= 0) continue;
      if(PositionGetInteger(POSITION_MAGIC) != InpMagicNumber) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE) != type) continue;
      
      string comment = PositionGetString(POSITION_COMMENT);
      // Chi lay lenh Hedge (bat dau bang "HG")
      if(StringFind(comment, "HG") != 0) continue;
      
      ArrayResize(positions, count + 1);
      positions[count].ticket    = ticket;
      positions[count].openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      positions[count].lot       = PositionGetDouble(POSITION_VOLUME);
      positions[count].profit    = PositionGetDouble(POSITION_PROFIT) + 
                                   PositionGetDouble(POSITION_SWAP);
      positions[count].openTime  = (datetime)PositionGetInteger(POSITION_TIME);
      positions[count].comment   = comment;
      positions[count].type      = type;
      positions[count].group     = 0;
      positions[count].orderIndex = 0;
      
      count++;
   }
   
   return count;
}

//+------------------------------------------------------------------+
//| Parse comment de lay group va order index                         |
//+------------------------------------------------------------------+
void ParseComment(string comment, int &group, int &orderIdx)
{
   // Format: "DCB2_5" → group=1 (0-indexed), orderIdx=5
   // "DC" + "B/S" + group_number + "_" + order_index
   
   group = 0;
   orderIdx = 0;
   
   if(StringLen(comment) < 5) return;
   
   // Lay group number (vi tri 3)
   string groupStr = StringSubstr(comment, 3, 1);
   int underscorePos = StringFind(comment, "_");
   
   if(underscorePos < 0) return;
   
   groupStr = StringSubstr(comment, 3, underscorePos - 3);
   group = (int)StringToInteger(groupStr) - 1; // Convert to 0-indexed
   
   string idxStr = StringSubstr(comment, underscorePos + 1);
   orderIdx = (int)StringToInteger(idxStr);
}

//+------------------------------------------------------------------+
//| Sap xep vi the theo gia                                           |
//+------------------------------------------------------------------+
void SortPositionsByPrice(PositionData &positions[], ENUM_POSITION_TYPE type)
{
   int count = ArraySize(positions);
   // BUY: sap xep theo gia tu cao->thap (lenh dau = xa nhat = gia cao nhat)
   // SELL: sap xep theo gia tu thap->cao (lenh dau = xa nhat = gia thap nhat)
   
   for(int i = 0; i < count - 1; i++)
   {
      for(int j = i + 1; j < count; j++)
      {
         bool swap = false;
         if(type == POSITION_TYPE_BUY)
            swap = (positions[j].openPrice > positions[i].openPrice);
         else
            swap = (positions[j].openPrice < positions[i].openPrice);
         
         if(swap)
         {
            PositionData temp = positions[i];
            positions[i] = positions[j];
            positions[j] = temp;
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Sap xep theo khoang cach tu gia hien tai (xa nhat truoc)         |
//+------------------------------------------------------------------+
void SortPositionsByDistance(PositionData &positions[], ENUM_POSITION_TYPE type)
{
   double currentPrice = (type == POSITION_TYPE_BUY) ? g_symInfo.Bid() : g_symInfo.Ask();
   int count = ArraySize(positions);
   
   for(int i = 0; i < count - 1; i++)
   {
      for(int j = i + 1; j < count; j++)
      {
         double distI = MathAbs(positions[i].openPrice - currentPrice);
         double distJ = MathAbs(positions[j].openPrice - currentPrice);
         
         if(distJ > distI) // Xa hon → len truoc
         {
            PositionData temp = positions[i];
            positions[i] = positions[j];
            positions[j] = temp;
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Xac dinh nhom hien tai va so lenh trong nhom                     |
//+------------------------------------------------------------------+
void GetCurrentGroupInfo(PositionData &positions[], int count, int &currentGroup, int &orderInGroup)
{
   currentGroup = 0;
   orderInGroup = 0;
   
   // Dem so lenh trong moi nhom
   int groupCounts[5] = {0, 0, 0, 0, 0};
   
   for(int i = 0; i < count; i++)
   {
      int g = positions[i].group;
      if(g >= 0 && g < 5)
         groupCounts[g]++;
   }
   
   // Tim nhom dang hoat dong (nhom co lenh cuoi cung)
   currentGroup = 0;
   for(int g = 4; g >= 0; g--)
   {
      if(groupCounts[g] > 0)
      {
         currentGroup = g;
         break;
      }
   }
   
   orderInGroup = groupCounts[currentGroup];
}

//+------------------------------------------------------------------+
//| Lay gia cua lenh DCA cuoi cung (gan gia hien tai nhat)           |
//+------------------------------------------------------------------+
double GetLastDCAPrice(PositionData &positions[], int count, ENUM_POSITION_TYPE type)
{
   if(count == 0) return 0;
   
   double lastPrice = positions[0].openPrice;
   
   for(int i = 1; i < count; i++)
   {
      if(type == POSITION_TYPE_BUY)
      {
         if(positions[i].openPrice < lastPrice)
            lastPrice = positions[i].openPrice;
      }
      else
      {
         if(positions[i].openPrice > lastPrice)
            lastPrice = positions[i].openPrice;
      }
   }
   
   return lastPrice;
}

//+------------------------------------------------------------------+
//| Lay gia lenh hedge cuoi cung                                     |
//+------------------------------------------------------------------+
double GetLastHedgePrice(PositionData &positions[], int count, ENUM_POSITION_TYPE type)
{
   if(count == 0) return 0;
   
   double lastPrice = positions[0].openPrice;
   
   for(int i = 1; i < count; i++)
   {
      if(type == POSITION_TYPE_SELL)
      {
         if(positions[i].openPrice > lastPrice)
            lastPrice = positions[i].openPrice;
      }
      else
      {
         if(positions[i].openPrice < lastPrice)
            lastPrice = positions[i].openPrice;
      }
   }
   
   return lastPrice;
}

//+------------------------------------------------------------------+
//| Tinh gia trung binh co trong so lot                               |
//+------------------------------------------------------------------+
double GetAveragePrice(PositionData &positions[], int count)
{
   if(count == 0) return 0;
   
   double totalLotPrice = 0;
   double totalLot = 0;
   
   for(int i = 0; i < count; i++)
   {
      totalLotPrice += positions[i].openPrice * positions[i].lot;
      totalLot += positions[i].lot;
   }
   
   if(totalLot == 0) return 0;
   return totalLotPrice / totalLot;
}

//+------------------------------------------------------------------+
//| Tinh tong lai/lo floating cua tat ca vi the                      |
//+------------------------------------------------------------------+
double GetTotalFloatingProfit()
{
   double total = 0;
   
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket <= 0) continue;
      if(PositionGetInteger(POSITION_MAGIC) != InpMagicNumber) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      
      total += PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
   }
   
   return total;
}

//+------------------------------------------------------------------+
//| Dem tong so vi the                                                |
//+------------------------------------------------------------------+
int CountAllPositions()
{
   int count = 0;
   
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket <= 0) continue;
      if(PositionGetInteger(POSITION_MAGIC) != InpMagicNumber) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      count++;
   }
   
   return count;
}

//+------------------------------------------------------------------+
//| Tinh tong lot cua 1 chieu                                        |
//+------------------------------------------------------------------+
double GetTotalLots(ENUM_POSITION_TYPE type, bool dcaOnly)
{
   double total = 0;
   
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket <= 0) continue;
      if(PositionGetInteger(POSITION_MAGIC) != InpMagicNumber) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE) != type) continue;
      
      string comment = PositionGetString(POSITION_COMMENT);
      if(dcaOnly && StringFind(comment, "DC") != 0) continue;
      
      total += PositionGetDouble(POSITION_VOLUME);
   }
   
   return total;
}

//+------------------------------------------------------------------+
//| Dong 1 vi the                                                    |
//+------------------------------------------------------------------+
bool ClosePosition(ulong ticket)
{
   if(!g_trade.PositionClose(ticket, InpSlippage))
   {
      Print("LOI dong vi the #", ticket, ": ", g_trade.ResultComment());
      return false;
   }
   return true;
}

//+------------------------------------------------------------------+
//| Dong tat ca vi the                                                |
//+------------------------------------------------------------------+
void CloseAllPositions()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket <= 0) continue;
      if(PositionGetInteger(POSITION_MAGIC) != InpMagicNumber) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      
      ClosePosition(ticket);
   }
   
   Print("=== DONG TAT CA VI THE ===");
}

//+------------------------------------------------------------------+
//| Chuan hoa lot size                                                |
//+------------------------------------------------------------------+
double NormalizeLot(double lot)
{
   double minLot  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double stepLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   
   // Ap dung max lot cua bot
   double effectiveMax = MathMin(maxLot, InpMaxLot);
   
   // Lam tron theo step
   lot = MathFloor(lot / stepLot) * stepLot;
   
   // Clamp
   lot = MathMax(lot, minLot);
   lot = MathMin(lot, effectiveMax);
   
   // Lam tron so thap phan
   lot = NormalizeDouble(lot, 4);
   
   return lot;
}

//+------------------------------------------------------------------+
//| CAP NHAT HIEN THI TREN CHART                                     |
//+------------------------------------------------------------------+
void UpdateDisplay(string status)
{
   // Dem lenh
   PositionData buyPos[], sellPos[], hedgeBuyPos[], hedgeSellPos[];
   int buyCount  = GetDCAPositions(POSITION_TYPE_BUY, buyPos);
   int sellCount = GetDCAPositions(POSITION_TYPE_SELL, sellPos);
   int hBuyCount = GetHedgePositions(POSITION_TYPE_BUY, hedgeBuyPos);
   int hSellCount = GetHedgePositions(POSITION_TYPE_SELL, hedgeSellPos);
   
   // Tinh toan
   double totalProfit = GetTotalFloatingProfit();
   double buyLots  = GetTotalLots(POSITION_TYPE_BUY, false);
   double sellLots = GetTotalLots(POSITION_TYPE_SELL, false);
   double balance  = AccountInfoDouble(ACCOUNT_BALANCE);
   double equity   = AccountInfoDouble(ACCOUNT_EQUITY);
   double dd       = balance - equity;
   double ddPct    = (balance > 0) ? (dd / balance * 100) : 0;
   
   double buyAvg = GetAveragePrice(buyPos, buyCount);
   double sellAvg = GetAveragePrice(sellPos, sellCount);
   
   int buyGroup = 0, buyInGroup = 0;
   if(buyCount > 0) GetCurrentGroupInfo(buyPos, buyCount, buyGroup, buyInGroup);
   int sellGroup = 0, sellInGroup = 0;
   if(sellCount > 0) GetCurrentGroupInfo(sellPos, sellCount, sellGroup, sellInGroup);
   
   string text = "";
   text += "══════════════════════════════════\n";
   text += "   DCA XAUUSD Bot v3.0 Rescue\n";
   text += "══════════════════════════════════\n";
   text += "Trang thai: " + status + "\n";
   text += "Mode: " + EnumToString(InpCheDoChay) + "\n";
   text += "Lot Mode: " + (InpCheDoLot == MODE_CONG_LOT ? "CONG" : "NHAN") + "\n";
   text += "──────────────────────────────────\n";
   text += "Balance:  $" + DoubleToString(balance, 2) + "\n";
   text += "Equity:   $" + DoubleToString(equity, 2) + "\n";
   text += "P/L:      $" + DoubleToString(totalProfit, 2) + "\n";
   text += "DD:       $" + DoubleToString(dd, 2) + 
           " (" + DoubleToString(ddPct, 1) + "%)\n";
   text += "──────────────────────────────────\n";
   
   if(buyCount > 0)
   {
      text += "BUY DCA:  " + IntegerToString(buyCount) + " lenh" +
              " | Nhom " + IntegerToString(buyGroup + 1) + 
              " | Lot: " + DoubleToString(GetTotalLots(POSITION_TYPE_BUY, true), 4) + "\n";
      text += "  Gia TB: " + DoubleToString(buyAvg, (int)g_symInfo.Digits()) + "\n";
   }
   
   if(sellCount > 0)
   {
      text += "SELL DCA: " + IntegerToString(sellCount) + " lenh" +
              " | Nhom " + IntegerToString(sellGroup + 1) +
              " | Lot: " + DoubleToString(GetTotalLots(POSITION_TYPE_SELL, true), 4) + "\n";
      text += "  Gia TB: " + DoubleToString(sellAvg, (int)g_symInfo.Digits()) + "\n";
   }
   
   if(hBuyCount > 0 || hSellCount > 0)
   {
      text += "──────────────────────────────────\n";
      text += "HEDGE:    ";
      if(hBuyCount > 0) text += "BUY " + IntegerToString(hBuyCount) + " lenh ";
      if(hSellCount > 0) text += "SELL " + IntegerToString(hSellCount) + " lenh";
      text += "\n";
   }

   {
      PositionData ghBuyPos[], ghSellPos[];
      int ghBuyCount = GetHedgeGroupPositions(POSITION_TYPE_BUY, ghBuyPos);
      int ghSellCount = GetHedgeGroupPositions(POSITION_TYPE_SELL, ghSellPos);
      if(ghBuyCount > 0 || ghSellCount > 0)
      {
         text += "HEDGE-DCA: ";
         if(ghBuyCount > 0) text += "BUY " + IntegerToString(ghBuyCount) + " lenh ";
         if(ghSellCount > 0) text += "SELL " + IntegerToString(ghSellCount) + " lenh";
         text += "\n";
      }
   }
   
   if(g_trailActive)
   {
      text += "──────────────────────────────────\n";
      text += "TRAILING: ON | SL: $" + DoubleToString(g_trailSL, 2) +
              " | Max: $" + DoubleToString(g_trailHighProfit, 2) + "\n";
   }
   
   text += "══════════════════════════════════\n";
   text += "Tong lot: " + DoubleToString(GetTotalLots(POSITION_TYPE_BUY, false) + GetTotalLots(POSITION_TYPE_SELL, false), 2) + "\n";
   text += "Margin Level: " + DoubleToString(AccountInfoDouble(ACCOUNT_MARGIN_LEVEL), 1) + "%\n";
   if(g_peakEquity > 0)
   {
      double ddPeak = (g_peakEquity - equity) / g_peakEquity * 100.0;
      if(ddPeak < 0) ddPeak = 0;
      text += "DD tu dinh: " + DoubleToString(ddPeak, 1) + "%\n";
   }
   text += "Spread: " + IntegerToString(g_symInfo.Spread()) + " points\n";
   text += "Time: " + TimeToString(TimeCurrent(), TIME_DATE | TIME_MINUTES) + "\n";
   
   Comment(text);
}
//+------------------------------------------------------------------+
