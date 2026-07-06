class Item {
  final String name;
  final String hsn;
  final String unit;
  final String category;
  final String code;
  final double salePrice;
  final String taxStatus;

  Item({
    required this.name,
    this.hsn = '',
    this.unit = 'NONE',
    this.category = 'None',
    this.code = '',
    required this.salePrice,
    this.taxStatus = 'Without Tax',
  });
}