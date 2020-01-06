class SectorModel {
  static final String sSectorsEndpoint = '/stock/market/sector-performance';

  final String type, name;
  final dynamic performance;
  final DateTime lastUpdated;

  SectorModel(this.type, this.name, this.performance, this.lastUpdated);

  SectorModel.fromJson(Map sectorJsonData)
      : type = sectorJsonData['type'],
        name = sectorJsonData['name'],
        performance = sectorJsonData['performance'],
        lastUpdated =
            DateTime.fromMillisecondsSinceEpoch(sectorJsonData['lastUpdated']);

  @override
  String toString() {
    return 'Sector: $name \nPerfomance: $performance';
  }
}
