import 'package:flutter/foundation.dart';

class AppFeatureSettings {
  const AppFeatureSettings({
    this.enableItems = true,
    this.stockMaintenance = true,
    this.showLowStockDialog = true,
    this.itemsUnit = true,
    this.defaultUnit = false,
    this.itemCategory = true,
    this.description = false,
    this.itemWiseTax = true,
    this.itemWiseDiscount = true,
    this.quantityDecimalPlaces = 2,
    this.wholesalePrice = true,
    this.mrp = false,
    this.calculateTaxOnMrp = false,
    this.expDate = true,
    this.mfgDate = true,
    this.modelNo = false,
    this.size = false,
    this.enableGst = true,
    this.enableHsn = true,
    this.additionalCess = false,
    this.enablePlaceOfSupply = true,
  });

  final bool enableItems;
  final bool stockMaintenance;
  final bool showLowStockDialog;
  final bool itemsUnit;
  final bool defaultUnit;
  final bool itemCategory;
  final bool description;
  final bool itemWiseTax;
  final bool itemWiseDiscount;
  final int quantityDecimalPlaces;
  final bool wholesalePrice;
  final bool mrp;
  final bool calculateTaxOnMrp;
  final bool expDate;
  final bool mfgDate;
  final bool modelNo;
  final bool size;
  final bool enableGst;
  final bool enableHsn;
  final bool additionalCess;
  final bool enablePlaceOfSupply;

  AppFeatureSettings copyWith({
    bool? enableItems,
    bool? stockMaintenance,
    bool? showLowStockDialog,
    bool? itemsUnit,
    bool? defaultUnit,
    bool? itemCategory,
    bool? description,
    bool? itemWiseTax,
    bool? itemWiseDiscount,
    int? quantityDecimalPlaces,
    bool? wholesalePrice,
    bool? mrp,
    bool? calculateTaxOnMrp,
    bool? expDate,
    bool? mfgDate,
    bool? modelNo,
    bool? size,
    bool? enableGst,
    bool? enableHsn,
    bool? additionalCess,
    bool? enablePlaceOfSupply,
  }) {
    return AppFeatureSettings(
      enableItems: enableItems ?? this.enableItems,
      stockMaintenance: stockMaintenance ?? this.stockMaintenance,
      showLowStockDialog: showLowStockDialog ?? this.showLowStockDialog,
      itemsUnit: itemsUnit ?? this.itemsUnit,
      defaultUnit: defaultUnit ?? this.defaultUnit,
      itemCategory: itemCategory ?? this.itemCategory,
      description: description ?? this.description,
      itemWiseTax: itemWiseTax ?? this.itemWiseTax,
      itemWiseDiscount: itemWiseDiscount ?? this.itemWiseDiscount,
      quantityDecimalPlaces:
          quantityDecimalPlaces ?? this.quantityDecimalPlaces,
      wholesalePrice: wholesalePrice ?? this.wholesalePrice,
      mrp: mrp ?? this.mrp,
      calculateTaxOnMrp: calculateTaxOnMrp ?? this.calculateTaxOnMrp,
      expDate: expDate ?? this.expDate,
      mfgDate: mfgDate ?? this.mfgDate,
      modelNo: modelNo ?? this.modelNo,
      size: size ?? this.size,
      enableGst: enableGst ?? this.enableGst,
      enableHsn: enableHsn ?? this.enableHsn,
      additionalCess: additionalCess ?? this.additionalCess,
      enablePlaceOfSupply: enablePlaceOfSupply ?? this.enablePlaceOfSupply,
    );
  }
}

final ValueNotifier<AppFeatureSettings> appFeatureSettings =
    ValueNotifier<AppFeatureSettings>(const AppFeatureSettings());
