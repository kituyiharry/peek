class KeyStats {
  static String sEndpoint = '/stats';

  //final String companyName;
  final dynamic marketCap;
  final dynamic beta;
  final dynamic week52High;
  final dynamic week52low;
  final dynamic week52change;
  final dynamic shortInterest;
  final dynamic dividendRate;
  final dynamic dividendYield;
  //final DateTime exDividendDate;
  final dynamic latestEPS;
  //final DateTime latestEPSDate;
  final dynamic float;
  final dynamic returnOnEquityTTM;
  //final String symbol;
  final dynamic ebitdattm;
  final dynamic grossProfit;
  final dynamic revenueTTM;
  final dynamic revenuePerShare;
  final dynamic revenuePerEmployee;
  final dynamic peRatioHigh;
  final dynamic peRatioLow;
  final dynamic returnOnAssetsTTM;
  final dynamic returnOnCapitalTTM;
  final dynamic profitMargin;
  final dynamic priceToSales;
  final dynamic priceToMargin;
  final dynamic day50movingAvg;
  final dynamic day200movingAvg;
  final dynamic cash;
  final dynamic ytdChangePercent;

  KeyStats(
      // this.companyName,
      this.marketCap,
      this.beta,
      this.week52High,
      this.week52low,
      this.cash,
      this.week52change,
      this.shortInterest,
      this.dividendRate,
      this.dividendYield,
      this.grossProfit,
      // this.exDividendDate,
      this.latestEPS,
      // this.latestEPSDate,
      this.float,
      this.returnOnEquityTTM,
      //this.symbol,
      this.ebitdattm,
      this.revenueTTM,
      this.revenuePerShare,
      this.revenuePerEmployee,
      this.peRatioHigh,
      this.peRatioLow,
      this.returnOnAssetsTTM,
      this.returnOnCapitalTTM,
      this.profitMargin,
      this.priceToSales,
      this.priceToMargin,
      this.day50movingAvg,
      this.day200movingAvg,
      this.ytdChangePercent);

  KeyStats.fromJsonMap(Map jsonData)
      : //companyName = jsonData['companyName'],
        marketCap = jsonData['marketCap'],
        beta = jsonData['beta'],
        week52High = jsonData['week52high'],
        grossProfit = jsonData['grossProfit'],
        week52low = jsonData['week52low'],
        cash = jsonData['cash'],
        week52change = jsonData['week52change'],
        shortInterest = jsonData['shortInterest'],
        dividendRate = jsonData['dividendRate'],
        dividendYield = jsonData['dividendYield'],
        // exDividendDate = DateTime.parse(jsonData['exDividendDate']),
        latestEPS = jsonData['latestEPS'],
        //latestEPSDate = DateTime.parse(jsonData['latestEPSDate']),
        float = jsonData['float'],
        returnOnEquityTTM = jsonData['returnOnEquity'],
        //symbol = jsonData['symbol'],
        ebitdattm = jsonData['EBITDA'],
        revenueTTM = jsonData['revenue'],
        revenuePerShare = jsonData['revenuePerShare'],
        revenuePerEmployee = jsonData['revenuePerEmployee'],
        peRatioHigh = jsonData['peRatioHigh'],
        peRatioLow = jsonData['peRatioLow'],
        returnOnAssetsTTM = jsonData['returnOnAssets'],
        returnOnCapitalTTM = jsonData['returnOnCapital'],
        profitMargin = jsonData['profitMargin'],
        priceToSales = jsonData['priceToSales'],
        priceToMargin = jsonData['priceToMargin'],
        day50movingAvg = jsonData['day50MovingAvg'],
        day200movingAvg = jsonData['day200MovingAvg'],
        ytdChangePercent = jsonData['ytdChangePercent'];
}
