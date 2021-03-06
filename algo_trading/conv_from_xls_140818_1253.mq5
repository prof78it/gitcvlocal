//+------------------------------------------------------------------+
//|                                                conv_from_xls.mq5 |
//|                        Copyright 2018, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include<Trade\Trade.mqh>
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum tmode
  {
   tp1=0,//Нет тренда
   tp2=1,//Вверх
   tp3=2//Вниз
  };

//--- input parameters
input int MagicNumber=123;//Magic Number
input int Slippage=30;//Максимальное проскальзывание
input tmode start_trend=1;//Направление начального истинного тренда 
input int prevtime=10;//Открывать сделку за, секунд до начала нового бара
input double Lot=1.0;//Первоначальный лот 
input double Coef=1.5;//Усреднение
input int StopTrade=-3;//Запрет торговли при убытке N таймфреймов подряд
input int StopBars=25;//Длительность запрета
input double Rotate=50;//Oграничение смены тренда в % 
input bool Reverse=false;//Противофаза
input int Step=10;//Минимальное расстояние от цены открытия
input ENUM_ORDER_TYPE_FILLING Tmode=ORDER_FILLING_RETURN;//Торговый режим 

input bool Day1=true;//Торговать в понедельник:
input bool Day2=true;//Торговать во вторник:
input bool Day3=true;//Торговать в среду:  
input bool Day4=true;//Торговать в четверг:
input bool Day5=true;//Торговать в пятницу:

input string TimeD1="10:00-23:15";//Период 1: 
input string TimeD2="10:00-23:15";//Период 2: 
input string TimeD3="10:00-23:15";//Период 3:
input string TimeD4="10:00-23:15";//Период 4:
input string TimeD5="10:00-23:15";//Период 5:

input int               InpX=80;                // Расстояние по оси X 
input int               InpY=80;                // Расстояние по оси Y 
input int               FontSize=10;            // Размер шрифта
input color             clrs=clrWhite;          // Цвет текста
double            InpAngle=0.0;           // Угол наклона в градусах 
ENUM_ANCHOR_POINT InpAnchor=ANCHOR_LEFT;   // Способ привязки 
input ENUM_BASE_CORNER InpCorner2=CORNER_LEFT_UPPER; // Угол графика для привязки 

CTrade  trade;
double Open[10],High[10],Low[10],Close[10];
datetime time[],ptime=0;
double Bid=0;
double Ask=0;
int BuyCount=0;
int SellCount=0;
double BuyLots=0;
double SellLots=0;
double DProf=0,OPb=0,OPs=0;
double volat,hvostO,modul,vol_hvost;
double hvostO_p,modul_p,vol_hvost_p;
int trend=0,ptrend=0,tru_trend=0,ptru_trend=0,
smena_trendaB=0,smena_trendaS=0,smena_trendaR=0;
int ress=0;
int SH1,SM1,EH1,EM1;
int SH2,SM2,EH2,EM2;
int SH3,SM3,EH3,EM3;
int SH4,SM4,EH4,EM4;
int SH5,SM5,EH5,EM5;
string StartH1="",EndH1="";
string StartH2="",EndH2="";
string StartH3="",EndH3="";
string StartH4="",EndH4="";
string StartH5="",EndH5="";
bool work=false;
double LastLot,LastProf,sBal=0,Bal=0;
int LastType=0;
int LastCom=0;
double maxDD=0,DD[],Eq;
int stopLot=0;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- create timer
   EventSetMillisecondTimer(100);

//--- зададим MagicNumber для идентификации своих ордеров
   trade.SetExpertMagicNumber(MagicNumber);
//--- установим допустимое проскальзывание в пунктах при совершении покупки/продажи
   trade.SetDeviationInPoints(Slippage);
//--- режим заполнения ордера, нужно использовать тот режим, который разрешается сервером
   trade.SetTypeFilling(Tmode);

   CopyOpen(NULL,0,0,2,Open);
   CopyClose(NULL,0,0,2,Close);

   ptru_trend=start_trend;

   sBal=AccountInfoDouble(ACCOUNT_BALANCE);

   string sep=":";
   ushort u_sep;
   string result[2];

   StartH1=StringSubstr(TimeD1,0,5);
   EndH1=StringSubstr(TimeD1,6,5);

   StartH2=StringSubstr(TimeD2,0,5);
   EndH2=StringSubstr(TimeD2,6,5);

   StartH3=StringSubstr(TimeD3,0,5);
   EndH3=StringSubstr(TimeD3,6,5);

   StartH4=StringSubstr(TimeD4,0,5);
   EndH4=StringSubstr(TimeD4,6,5);

   StartH5=StringSubstr(TimeD5,0,5);
   EndH5=StringSubstr(TimeD5,6,5);

   u_sep=StringGetCharacter(sep,0);

   int ks=StringSplit(StartH1,u_sep,result);
   SH1=(int)StringToInteger(result[0]);
   SM1=(int)StringToInteger(result[1]);

   ks=StringSplit(EndH1,u_sep,result);
   EH1=(int)StringToInteger(result[0]);
   EM1=(int)StringToInteger(result[1]);

   ks=StringSplit(StartH2,u_sep,result);
   SH2=(int)StringToInteger(result[0]);
   SM2=(int)StringToInteger(result[1]);

   ks=StringSplit(EndH2,u_sep,result);
   EH2=(int)StringToInteger(result[0]);
   EM2=(int)StringToInteger(result[1]);

   ks=StringSplit(StartH3,u_sep,result);
   SH3=(int)StringToInteger(result[0]);
   SM3=(int)StringToInteger(result[1]);

   ks=StringSplit(EndH3,u_sep,result);
   EH3=(int)StringToInteger(result[0]);
   EM3=(int)StringToInteger(result[1]);

   ks=StringSplit(StartH4,u_sep,result);
   SH4=(int)StringToInteger(result[0]);
   SM4=(int)StringToInteger(result[1]);

   ks=StringSplit(EndH4,u_sep,result);
   EH4=(int)StringToInteger(result[0]);
   EM4=(int)StringToInteger(result[1]);

   ks=StringSplit(StartH5,u_sep,result);
   SH5=(int)StringToInteger(result[0]);
   SM5=(int)StringToInteger(result[1]);

   ks=StringSplit(EndH5,u_sep,result);
   EH5=(int)StringToInteger(result[0]);
   EM5=(int)StringToInteger(result[1]);


//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//--- destroy timer
   EventKillTimer();

   ObjectDelete(0,"L1");
   ObjectDelete(0,"L2");
   ObjectDelete(0,"L3");
   ObjectDelete(0,"L4");
   ObjectDelete(0,"L5");
   ObjectDelete(0,"L6");
   ObjectDelete(0,"L7");
   
   ObjectDelete(0,"L9");
   ObjectDelete(0,"L10");
   ObjectDelete(0,"L11");
   ObjectDelete(0,"L12");
   ObjectDelete(0,"L13");
   ObjectDelete(0,"L14");
   ObjectDelete(0,"L15");

   ObjectsDeleteAll(0,"Pros");

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {

   MyMarkets();
 
   Bal=AccountInfoDouble(ACCOUNT_BALANCE);

//--------------------- Work Time -------------------------------------------

   work=false;
   int Dd=DayOfWeek();

   bool w1=WorkTime(SH1,SM1,EH1,EM1);
   bool w2=WorkTime(SH2,SM2,EH2,EM2);
   bool w3=WorkTime(SH3,SM3,EH3,EM3);
   bool w4=WorkTime(SH4,SM4,EH4,EM4);
   bool w5=WorkTime(SH5,SM5,EH5,EM5);

   if(SH1==0 && SM1==0 && EH1==0 && EM1==0)w1=false;
   if(SH2==0 && SM2==0 && EH2==0 && EM2==0)w2=false;
   if(SH3==0 && SM3==0 && EH3==0 && EM3==0)w3=false;
   if(SH4==0 && SM4==0 && EH4==0 && EM4==0)w4=false;
   if(SH5==0 && SM5==0 && EH5==0 && EM5==0)w5=false;

   if((w1==true
      || w2==true
      || w3==true
      || w4==true
      || w5==true)
      && 
      ((Dd==1 && Day1==true)
      || (Dd==2 && Day2==true)
      || (Dd==3 && Day3==true)
      || (Dd==4 && Day4==true)
      || (Dd==5 && Day5==true))
      )work=true;

//------------------------------------------------------------------------------

   CopyTime(NULL,0,0,1,time);

   if(TimeCurrent()+prevtime>=ptime)
     {


      MqlTick last_tick;
      ZeroMemory(last_tick);
      if(SymbolInfoTick(Symbol(),last_tick))
        {
         Ask=last_tick.ask;
         Bid=last_tick.bid;
        }

      CopyOpen(NULL,0,0,2,Open);
      CopyHigh(NULL,0,0,2,High);
      CopyLow(NULL,0,0,2,Low);
      CopyClose(NULL,0,0,2,Close);

      volat=High[0]-Low[0];

      if(Close[0]>Open[0])hvostO=Open[0]-Low[0];
      else hvostO=High[0]-Open[0];

      modul=MathAbs(Close[0]-Open[0]);

      vol_hvost=volat-hvostO;

      if(Close[0]>Open[0])hvostO_p=(Open[0]-Low[0])*100/Low[0];
      else hvostO_p=(High[0]-Open[0])*100/Open[0];

      modul_p=MathAbs(Close[0]-Open[0])*100/Open[0];

      vol_hvost_p=(volat-hvostO)*100/Open[0];

      trend=0;
      if(Close[0]>Open[0])trend=1;
      else trend=2;
      
      

      tru_trend=0;
      smena_trendaB=0;

      if(vol_hvost_p*100>Rotate)
        {
         tru_trend=trend;
         smena_trendaB=1;
        }
      else
        {
         tru_trend=ptru_trend;
         smena_trendaB=-1;
        }
        
         

      smena_trendaS=0;
      if(tru_trend==ptru_trend)smena_trendaS=1;
      else smena_trendaS=-1;

      smena_trendaR=smena_trendaB*smena_trendaS;

      ptrend=trend;
      ptru_trend=tru_trend;

      ress=(int)(modul_p*smena_trendaR*(Open[0]/(100*_Point)));

      if((OPb>0 && OPs==0 && MathAbs(Bid-OPb)>=Step*_Point) || (OPs>0 && OPb==0 && MathAbs(Ask-OPs)>=Step*_Point))
      if(BuyCount+SellCount>0)trade.PositionClose(_Symbol);


      Last();
      Last2();
      if((tru_trend==1 && Reverse==false) || (trend==2 && Reverse==true))
        {
         if(BuyCount+SellCount==0 && work==true)
           {
            MyMarkets();
            if(LastCom>MathAbs(StopTrade) && stopLot==0){ptime=time[0]+StopBars*PeriodSeconds();stopLot=1;return;}
            double size=GetLot();
            trade.Buy(size);
           }
        }

      if((tru_trend==2 && Reverse==false) || (trend==1 && Reverse==true))
        {
         if(BuyCount+SellCount==0 && work==true)
           {
            MyMarkets();
            if(LastCom>MathAbs(StopTrade) && stopLot==0){ptime=time[0]+StopBars*PeriodSeconds();stopLot=1;return;}
            double size=GetLot();
            trade.Sell(size);
           }
        }

      MyMarkets();
      Text();

      if(BuyCount+SellCount>0)
        {
         if(ptime<time[0])
            ptime=time[0]+PeriodSeconds();
         else ptime=time[0]+2*PeriodSeconds(); 
        }

     }
  }
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
//---
OnTick();
  }
//+------------------------------------------------------------------+
int MyMarkets()
  {
   BuyCount=0;
   SellCount=0;
   OPb=0;
   OPs=0;
   BuyLots=0;
   SellLots=0;
 

   for(int i=0;i<PositionsTotal();i++)
     {
      if(PositionGetSymbol(i)==_Symbol)
        {
         if(PositionGetInteger(POSITION_MAGIC)==MagicNumber)
           {
            if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY)
              {
               BuyCount++;
               OPb=PositionGetDouble(POSITION_PRICE_OPEN);
               BuyLots=PositionGetDouble(POSITION_VOLUME);
            
              }
            if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL)
              {
               SellCount++;
               OPs=PositionGetDouble(POSITION_PRICE_OPEN);
               SellLots=PositionGetDouble(POSITION_VOLUME);
               
              }
           }

        }

     }

   return(0);
  }
//+------------------------------------------------------------------+
int Hour()
  {
   MqlDateTime tm;
   TimeToStruct(TimeCurrent(),tm);
   return(tm.hour);
  }
//+------------------------------------------------------------------+
int Minute()
  {
   MqlDateTime tm;
   TimeToStruct(TimeCurrent(),tm);
   return(tm.min);
  }
//+------------------------------------------------------------------+
bool WorkTime(int SH,int SM,int EH,int EM)
  {
   bool res=false;
   datetime hr=Hour();
   datetime mn=Minute();

   if(hr*100+mn>=SH*100+SM && hr*100+mn<=EH*100+EM)res=true;

   return (res);
  }
//+------------------------------------------------------------------+
int DayOfWeek()
  {
   MqlDateTime tm;
   TimeCurrent(tm);
   return(tm.day_of_week);
  }
//+------------------------------------------------------------------+
int Day()
  {
   MqlDateTime tm;
   TimeToStruct(TimeCurrent(),tm);
   return(tm.day);
  }
//+------------------------------------------------------------------+
int Last()
  {

   LastLot=0;
   LastProf=0;
   LastType=0;
   LastCom=0;

   double maxdd=0;
   int j=0;
   ArrayFree(DD);

   HistorySelect(0,TimeCurrent());
//--- create objects 
   uint     total=HistoryDealsTotal();
   ulong    ticket=0;
   double   price;
   double   profit;
   datetime times,ot=0,ct=0;
   string   symbol,comm="";
   long     type;
   long     entry;
   int      magic;
   double   volume;
   int      res=0;

   for(uint i=0;i<total;i++)

     {
      if((ticket=HistoryDealGetTicket(i))>0)
        {
         price=HistoryDealGetDouble(ticket,DEAL_PRICE);
         times=(datetime)HistoryDealGetInteger(ticket,DEAL_TIME);
         symbol=HistoryDealGetString(ticket,DEAL_SYMBOL);
         type  =HistoryDealGetInteger(ticket,DEAL_TYPE);
         entry =HistoryDealGetInteger(ticket,DEAL_ENTRY);
         profit=HistoryDealGetDouble(ticket,DEAL_PROFIT);
         magic=(int)HistoryDealGetInteger(ticket,DEAL_MAGIC);
         volume=HistoryDealGetDouble(ticket,DEAL_VOLUME);
         comm=(string)HistoryDealGetString(ticket,DEAL_COMMENT);
         res =(int)HistoryDealGetInteger(ticket,DEAL_REASON);


         if(symbol==Symbol() && magic==MagicNumber)
           {

            if(entry==DEAL_ENTRY_OUT)
              {

               LastProf=profit;
               LastLot=volume;
              
              
              if(profit<0)maxdd+=profit;

               else {LastCom=0;
               
                  if(maxdd<0){
                  ArrayResize(DD,j+1);
                  DD[j]=maxdd;
                  j++;
                  maxdd=0;
               
               }}

              }

           }
        }
     }

      ArraySort(DD);
   if(j>0)
   maxDD=DD[0];

   return(0);
  }
//+------------------------------------------------------------------+
int Last2()
  {

   LastCom=0;

   HistorySelect(0,TimeCurrent());
//--- create objects 
   uint     total=HistoryDealsTotal();
   ulong    ticket=0;
   double   price;
   double   profit;
   datetime times,ot=0,ct=0;
   string   symbol,comm="";
   long     type;
   long     entry;
   int      magic;
   double   volume;
   int      res=0;

   for(uint i=0;i<total;i++)

     {
      if((ticket=HistoryDealGetTicket(i))>0)
        {
         price=HistoryDealGetDouble(ticket,DEAL_PRICE);
         times=(datetime)HistoryDealGetInteger(ticket,DEAL_TIME);
         symbol=HistoryDealGetString(ticket,DEAL_SYMBOL);
         type  =HistoryDealGetInteger(ticket,DEAL_TYPE);
         entry =HistoryDealGetInteger(ticket,DEAL_ENTRY);
         profit=HistoryDealGetDouble(ticket,DEAL_PROFIT);
         magic=(int)HistoryDealGetInteger(ticket,DEAL_MAGIC);
         volume=HistoryDealGetDouble(ticket,DEAL_VOLUME);
         comm=(string)HistoryDealGetString(ticket,DEAL_COMMENT);
         res =(int)HistoryDealGetInteger(ticket,DEAL_REASON);


         if(symbol==Symbol() && magic==MagicNumber)
           {

            if(entry==DEAL_ENTRY_OUT)
              {

               if(profit<0)LastCom++;
               else LastCom=0;

              }

           }
        }
     }



   return(0);
  }
//+------------------------------------------------------------------+
double GetLot()
  {

   double lots=Lot;
   Last();

   if( LastProf<0)lots=LastLot*Coef;
   
   if(stopLot==1){lots=Lot;stopLot=0;}

   double minLot=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN);
   double maxLot=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MAX);

   if(lots<minLot)lots=minLot;
   if(lots>maxLot)lots=maxLot;

   lots=NL(lots);

   return (lots);
  }
//+------------------------------------------------------------------+
double NL(double lo=0.01,bool ro=false)
  {
   double l,k;
   double ls=SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_STEP);
   double ml=SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN);
   double mx=SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX);
   if(ml==0) ml=0.01;
   if(mx==0) mx=100;
   if(ls>0) k=1/ls; else k=1/ml;
   if(ro) l=MathCeil(lo*k)/k; else l=MathFloor(lo*k)/k;
   if(l<ml) l=ml;
   if(l>mx) l=mx;
   if(ls == 1.0)l = NormalizeDouble(l,0);
   if(ls == 0.1)l = NormalizeDouble(l,1);
   if(ls == 0.01)l = NormalizeDouble(l,2);
   return(l);
  }
//+------------------------------------------------------------------+
bool LabelCreate(const long              chart_ID=0,               // ID графика 
                 const string            name="Label",             // имя метки 
                 const int               sub_window=0,             // номер подокна 
                 const int               x=0,                      // координата по оси X 
                 const int               y=0,                      // координата по оси Y 
                 const ENUM_BASE_CORNER  corner=CORNER_LEFT_UPPER, // угол графика для привязки 
                 const string            text="Label",             // текст 
                 const string            font="Arial",             // шрифт 
                 const int               font_size=10,             // размер шрифта 
                 const color             clr=clrRed,               // цвет 
                 const double            angle=0.0,                // наклон текста 
                 const ENUM_ANCHOR_POINT anchor=ANCHOR_LEFT_UPPER, // способ привязки 
                 const bool              back=false,               // на заднем плане 
                 const bool              selection=false,          // выделить для перемещений 
                 const bool              hidden=true,              // скрыт в списке объектов 
                 const long              z_order=0)                // приоритет на нажатие мышью 
  {
//--- сбросим значение ошибки 
   ResetLastError();

   ObjectDelete(0,name);
//--- создадим текстовую метку 
   if(!ObjectCreate(chart_ID,name,OBJ_LABEL,sub_window,0,0))
     {
      Print(__FUNCTION__,
            ": не удалось создать текстовую метку! Код ошибки = ",GetLastError());
      return(false);
     }
//--- установим координаты метки 
   ObjectSetInteger(chart_ID,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(chart_ID,name,OBJPROP_YDISTANCE,y);
//--- установим угол графика, относительно которого будут определяться координаты точки 
   ObjectSetInteger(chart_ID,name,OBJPROP_CORNER,corner);
//--- установим текст 
   ObjectSetString(chart_ID,name,OBJPROP_TEXT,text);
//--- установим шрифт текста 
   ObjectSetString(chart_ID,name,OBJPROP_FONT,font);
//--- установим размер шрифта 
   ObjectSetInteger(chart_ID,name,OBJPROP_FONTSIZE,font_size);
//--- установим угол наклона текста 
   ObjectSetDouble(chart_ID,name,OBJPROP_ANGLE,angle);
//--- установим способ привязки 
   ObjectSetInteger(chart_ID,name,OBJPROP_ANCHOR,anchor);
//--- установим цвет 
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
//--- отобразим на переднем (false) или заднем (true) плане 
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
//--- включим (true) или отключим (false) режим перемещения метки мышью 
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection);
//--- скроем (true) или отобразим (false) имя графического объекта в списке объектов 
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden);
//--- установим приоритет на получение события нажатия мыши на графике 
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order);
//--- успешное выполнение 
   return(true);
  }
//+------------------------------------------------------------------+
void Text()
  {

   string text="";
   int Y=InpY;

   double lpr=Ask*100;

   text="Исходный счет "+DoubleToString(sBal,2);
   LabelCreate(0,"L1",0,InpX,InpY,InpCorner2,text,"Arial",FontSize,clrs,0,InpAnchor,false,false,true,0);

   Y+=2*FontSize;
   text="Исходный счет, пунктов "+DoubleToString(sBal/(lpr*Lot),0);
   LabelCreate(0,"L2",0,InpX,Y,InpCorner2,text,"Arial",FontSize,clrs,0,InpAnchor,false,false,true,0);

   Y+=2*FontSize;
   text="Максимальная просадка "+DoubleToString(maxDD,2);
   LabelCreate(0,"L3",0,InpX,Y,InpCorner2,text,"Arial",FontSize,clrs,0,InpAnchor,false,false,true,0);

   Y+=2*FontSize;
   text="Максимальная просадка, пунктов "+DoubleToString(maxDD/(lpr*Lot),0);
   LabelCreate(0,"L4",0,InpX,Y,InpCorner2,text,"Arial",FontSize,clrs,0,InpAnchor,false,false,true,0);

   Y+=2*FontSize;
   text="Текущий счет "+DoubleToString(Bal,2);
   LabelCreate(0,"L5",0,InpX,Y,InpCorner2,text,"Arial",FontSize,clrs,0,InpAnchor,false,false,true,0);

   Y+=2*FontSize;
   text="Текущий счет, пунктов "+DoubleToString(Bal/(lpr*Lot),0);
   LabelCreate(0,"L6",0,InpX,Y,InpCorner2,text,"Arial",FontSize,clrs,0,InpAnchor,false,false,true,0);

   if(maxDD>0)
     {
      Y+=2*FontSize;
      text="Маржа за период "+DoubleToString(MathAbs(Bal/maxDD),0);
      LabelCreate(0,"L7",0,InpX,Y,InpCorner2,text,"Arial",FontSize,clrs,0,InpAnchor,false,false,true,0);
     }

   Y+=2*FontSize;
   text="Проверка ";
   if(Bal<MathAbs(2*maxDD))text="Проверка ПЛОХО";
   LabelCreate(0,"L8",0,InpX,Y,InpCorner2,text,"Arial",FontSize,clrs,0,InpAnchor,false,false,true,0);
   
   datetime date[];  
   double   low[];   
   double   high[];  
   
   CopyTime(Symbol(),Period(),0,1,date);
   CopyLow(Symbol(),Period(),0,1,low);
   CopyHigh(Symbol(),Period(),0,1,high);
   string text2="";

   
    Y+=2*FontSize;
   if(trend==1){text="Направление тренда :Вверх";text2="тренд:Вверх";}
   if(trend==2){text="Направление тренда :Вниз";text2="тренд:Вниз";}
   LabelCreate(0,"L9",0,InpX,Y,InpCorner2,text,"Arial",FontSize,clrs,0,InpAnchor,false,false,true,0);
   TextCreate(0,"TextHigh_"+(string)date[0],0,date[0],high[0]+10*_Point,text2,"Arial",10,clrWhite,90,ANCHOR_LEFT,false,false,true,0); 

   
   Y+=2*FontSize;
   if(tru_trend==1){text="Направление истинного тренда :Вверх";text2="ист.тренд:Вверх";}
   if(tru_trend==2){text="Направление истинного тренда :Вниз";text2="ист.тренд:Вниз";}
   LabelCreate(0,"L10",0,InpX,Y,InpCorner2,text,"Arial",FontSize,clrs,0,InpAnchor,false,false,true,0);
    TextCreate(0,"TextLow_"+(string)date[0],0,date[0],low[0]-100*_Point,text2,"Arial",10,clrWhite,270,ANCHOR_RIGHT,false,false,true,0); 

   
   Y+=2*FontSize;
   text="Смена тренда: "+IntegerToString(smena_trendaB);
   LabelCreate(0,"L11",0,InpX,Y,InpCorner2,text,"Arial",FontSize,clrs,0,InpAnchor,false,false,true,0);


 
   int sz=ArraySize(DD);
   if(sz>0)
     {
      int y=8;
      if(sz<y)y=sz;
      for(int i=0; i<y; i++)
        {

         Y+=2*FontSize;
         text="макс просадка место №"+(string)(i+1)+DoubleToString(DD[i],2);
         LabelCreate(0,"Pros"+(string)(i+1),0,InpX,Y,InpCorner2,text,"Arial",FontSize,clrs,0,InpAnchor,false,false,true,0);

        }
     }
      
 

  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+ 
//| Создает объект "Текст"                                           | 
//+------------------------------------------------------------------+ 
bool TextCreate(const long              chart_ID=0,               // ID графика 
                const string            name="Text",              // имя объекта 
                const int               sub_window=0,             // номер подокна 
                datetime                times=0,                   // время точки привязки 
                double                  price=0,                  // цена точки привязки 
                const string            text="Text",              // сам текст 
                const string            font="Arial",             // шрифт 
                const int               font_size=10,             // размер шрифта 
                const color             clr=clrRed,               // цвет 
                const double            angle=0.0,                // наклон текста 
                const ENUM_ANCHOR_POINT anchor=ANCHOR_LEFT_UPPER, // способ привязки 
                const bool              back=false,               // на заднем плане 
                const bool              selection=false,          // выделить для перемещений 
                const bool              hidden=true,              // скрыт в списке объектов 
                const long              z_order=0)                // приоритет на нажатие мышью 
  { 

//--- сбросим значение ошибки 
   ResetLastError(); 
//--- создадим объект "Текст" 
   if(!ObjectCreate(chart_ID,name,OBJ_TEXT,sub_window,times,price)) 
     { 
      Print(__FUNCTION__, 
            ": не удалось создать объект \"Текст\"! Код ошибки = ",GetLastError()); 
      return(false); 
     } 
//--- установим текст 
   ObjectSetString(chart_ID,name,OBJPROP_TEXT,text); 
//--- установим шрифт текста 
   ObjectSetString(chart_ID,name,OBJPROP_FONT,font); 
//--- установим размер шрифта 
   ObjectSetInteger(chart_ID,name,OBJPROP_FONTSIZE,font_size); 
//--- установим угол наклона текста 
   ObjectSetDouble(chart_ID,name,OBJPROP_ANGLE,angle); 
//--- установим способ привязки 
   ObjectSetInteger(chart_ID,name,OBJPROP_ANCHOR,anchor); 
//--- установим цвет 
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr); 
//--- отобразим на переднем (false) или заднем (true) плане 
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back); 
//--- включим (true) или отключим (false) режим перемещения объекта мышью 
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection); 
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection); 
//--- скроем (true) или отобразим (false) имя графического объекта в списке объектов 
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden); 
//--- установим приоритет на получение события нажатия мыши на графике 
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order); 
//--- успешное выполнение 
   return(true); 
  } 

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
