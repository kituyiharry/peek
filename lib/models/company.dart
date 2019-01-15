class CompanyModel {
  static String sEndpoint = '/company';

  final String symbol;
  final String companyName;
  final String exchange;
  final String industry;
  final String website;
  final String description;
  final String ceo;
  final String issueType;
  final String sector;
  final List<dynamic> tags;

  CompanyModel(
      this.symbol,
      this.companyName,
      this.exchange,
      this.industry,
      this.website,
      this.description,
      this.ceo,
      this.issueType,
      this.sector,
      this.tags);

  CompanyModel.fromJson(Map companyJsonData)
      : symbol = companyJsonData['symbol'],
        companyName = companyJsonData['companyName'],
        exchange = companyJsonData['exchange'],
        industry = companyJsonData['industry'],
        website = companyJsonData['website'],
        description = companyJsonData['description'],
        ceo = companyJsonData['CEO'],
        issueType = companyJsonData['issueType'],
        sector = companyJsonData['sector'],
        tags = companyJsonData['tags'];
}
