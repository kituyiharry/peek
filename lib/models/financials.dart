class FinancialsModel {
  static String sEndPoint = '/financials';

  final DateTime reportDate;
  final dynamic grossProfit;
  final dynamic costOfRevenue;
  final int operatingRevenue;
  final int totalRevenue;
  final int operatingIncome;
  final int netIncome;
  final int researchAndDevelopment;
  final int operatingExpense;
  final int currentAssets;
  final int totalAssets;
  final int totalLiabilities;
  final int currentCash;
  final int currentDebt;
  final int totalCash;
  final int totalDebt;
  final int shareHolderEquity;
  final int cashChange;
  final int cashFlow;

  FinancialsModel(
      this.reportDate,
      this.grossProfit,
      this.costOfRevenue,
      this.operatingRevenue,
      this.totalRevenue,
      this.operatingIncome,
      this.netIncome,
      this.researchAndDevelopment,
      this.operatingExpense,
      this.currentAssets,
      this.totalAssets,
      this.totalLiabilities,
      this.currentCash,
      this.currentDebt,
      this.totalCash,
      this.totalDebt,
      this.shareHolderEquity,
      this.cashChange,
      this.cashFlow);

  FinancialsModel.fromJsonMap(Map finData)
      : reportDate = DateTime.parse(finData['reportDate']),
        grossProfit = finData['grossProfit'],
        cashChange = finData['cashChange'],
        cashFlow = finData['cashFlow'],
        costOfRevenue = finData['costOfRevenue'],
        operatingRevenue = finData['operatingRevenue'],
        currentAssets = finData['currentAssets'],
        currentCash = finData['currentCash'],
        currentDebt = finData['currentDebt'],
        netIncome = finData['netIncome'],
        operatingExpense = finData['operatingExpense'],
        operatingIncome = finData['operatingIncome'],
        researchAndDevelopment = finData['researchAndDevelopment'],
        shareHolderEquity = finData['shareHolderEquity'],
        totalAssets = finData['totalAssets'],
        totalDebt = finData['totalDebt'],
        totalCash = finData['totalCash'],
        totalLiabilities = finData['totalLiabilities'],
        totalRevenue = finData['totalRevenue'];

  @override
  String toString() {
    // TODO: implement toString
    return this.reportDate.toString();
  }
}

class IncomeModel {
  final dynamic operatingIncome;
  final dynamic netIncome;
  final dynamic researchAndDevelopment;
  final dynamic operatingExpense;
  final dynamic grossProfit;
  final dynamic costOfRevenue;
  final dynamic totalRevenue;
  final dynamic operatingRevenue;

  IncomeModel(
      this.operatingIncome,
      this.netIncome,
      this.researchAndDevelopment,
      this.operatingExpense,
      this.grossProfit,
      this.costOfRevenue,
      this.totalRevenue,
      this.operatingRevenue);

  IncomeModel.fromFinancialsModel(FinancialsModel f)
      : operatingIncome = f.operatingIncome,
        netIncome = f.netIncome,
        researchAndDevelopment = f.researchAndDevelopment,
        operatingExpense = f.operatingExpense,
        grossProfit = f.grossProfit,
        costOfRevenue = f.costOfRevenue,
        totalRevenue = f.totalRevenue,
        operatingRevenue = f.operatingRevenue;
}

class BalanceSheetModel {
  final dynamic currentAssets;
  final dynamic totalAssets;
  final dynamic currentDebt;
  final dynamic totalDebt;

  BalanceSheetModel(
      this.currentAssets, this.totalAssets, this.currentDebt, this.totalDebt);

  BalanceSheetModel.fromFinancialsModel(FinancialsModel f)
      : currentDebt = f.currentDebt,
        currentAssets = f.currentAssets,
        totalDebt = f.totalDebt,
        totalAssets = f.totalAssets;
}

class CashFlowModel {
  final int cashChange;
  final int cashFlow;

  CashFlowModel(this.cashChange, this.cashFlow);

  CashFlowModel.fromFinancials(FinancialsModel f)
      : cashChange = f.cashChange,
        cashFlow = f.cashFlow;
}

class SplitModelAdapter {
  final List<FinancialsModel> _list;
  SplitModelAdapter(this._list);

  List<IncomeModel> toIncomeStatementModel() {
    return _list.map((f) => IncomeModel.fromFinancialsModel(f)).toList();
  }

  List<CashFlowModel> toCashFlowModel() {
    return _list.map((f) => CashFlowModel.fromFinancials(f)).toList();
  }

  List<BalanceSheetModel> toBalanceSheetModel() {
    return _list.map((f) => BalanceSheetModel.fromFinancialsModel(f)).toList();
  }
}
