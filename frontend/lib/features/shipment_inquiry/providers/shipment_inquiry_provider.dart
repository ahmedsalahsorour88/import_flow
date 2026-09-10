import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../import_files/models/import_file_model.dart';
import '../../import_files/providers/import_files_provider.dart';
import '../models/shipment_inquiry_filter_model.dart';

enum ShipmentInquirySortField {
  shipmentName,
  supplierName,
  companyName,
  itemAndHs,
  route,
  shippingMode,
  incoterm,
  freightCost,
  date,
}

class ShipmentInquiryState {
  final ShipmentInquiryFilterModel filters;
  final ShipmentInquirySortField sortField;
  final bool isAscending;
  final bool isAdvancedExpanded;
  final List<String> savedPresets;

  const ShipmentInquiryState({
    this.filters = ShipmentInquiryFilterModel.empty,
    this.sortField = ShipmentInquirySortField.date,
    this.isAscending = false,
    this.isAdvancedExpanded = false,
    this.savedPresets = const [],
  });

  ShipmentInquiryState copyWith({
    ShipmentInquiryFilterModel? filters,
    ShipmentInquirySortField? sortField,
    bool? isAscending,
    bool? isAdvancedExpanded,
    List<String>? savedPresets,
  }) {
    return ShipmentInquiryState(
      filters: filters ?? this.filters,
      sortField: sortField ?? this.sortField,
      isAscending: isAscending ?? this.isAscending,
      isAdvancedExpanded: isAdvancedExpanded ?? this.isAdvancedExpanded,
      savedPresets: savedPresets ?? this.savedPresets,
    );
  }
}

class ShipmentInquiryNotifier extends StateNotifier<ShipmentInquiryState> {
  ShipmentInquiryNotifier() : super(const ShipmentInquiryState());

  void setFilter(ShipmentInquiryFilterModel newFilters) {
    state = state.copyWith(filters: newFilters);
  }

  void updateFilter({
    int? supplierId,
    bool clearSupplier = false,
    int? companyId,
    bool clearCompany = false,
    String? hsCodeOrProduct,
    String? incotermCode,
    bool clearIncoterm = false,
    String? portOfLoading,
    bool clearPol = false,
    String? portOfDischarge,
    bool clearPod = false,
    String? shipmentMode,
    bool clearMode = false,
    String? carrier,
    bool clearCarrier = false,
    DateTime? dateFrom,
    bool clearDateFrom = false,
    DateTime? dateTo,
    bool clearDateTo = false,
    String? search,
  }) {
    final updated = state.filters.copyWith(
      supplierId: supplierId,
      clearSupplier: clearSupplier,
      companyId: companyId,
      clearCompany: clearCompany,
      hsCodeOrProduct: hsCodeOrProduct,
      incotermCode: incotermCode,
      clearIncoterm: clearIncoterm,
      portOfLoading: portOfLoading,
      clearPol: clearPol,
      portOfDischarge: portOfDischarge,
      clearPod: clearPod,
      shipmentMode: shipmentMode,
      clearMode: clearMode,
      carrier: carrier,
      clearCarrier: clearCarrier,
      dateFrom: dateFrom,
      clearDateFrom: clearDateFrom,
      dateTo: dateTo,
      clearDateTo: clearDateTo,
      search: search,
    );
    state = state.copyWith(filters: updated);
  }

  void resetFilters() {
    state = state.copyWith(filters: ShipmentInquiryFilterModel.empty);
  }

  void toggleAdvancedExpanded() {
    state = state.copyWith(isAdvancedExpanded: !state.isAdvancedExpanded);
  }

  void sortBy(ShipmentInquirySortField field) {
    if (state.sortField == field) {
      state = state.copyWith(isAscending: !state.isAscending);
    } else {
      state = state.copyWith(sortField: field, isAscending: true);
    }
  }

  void saveCurrentPreset(String name) {
    if (!state.savedPresets.contains(name)) {
      state = state.copyWith(savedPresets: [...state.savedPresets, name]);
    }
  }
}

final shipmentInquiryStateProvider =
    StateNotifierProvider<ShipmentInquiryNotifier, ShipmentInquiryState>((ref) {
  return ShipmentInquiryNotifier();
});

/// Computes filtered and sorted list of shipments based on full active filters
final filteredShipmentsProvider = Provider<List<ImportFileModel>>((ref) {
  final filesAsync = ref.watch(importFilesProvider);
  final inquiryState = ref.watch(shipmentInquiryStateProvider);
  final filters = inquiryState.filters;

  return filesAsync.maybeWhen(
    data: (files) {
      var result = files.where((f) {
        // 1. Supplier Filter
        if (filters.supplierId != null && f.supplierId != filters.supplierId) {
          return false;
        }

        // 2. Importing Company Filter
        if (filters.companyId != null && f.companyId != filters.companyId) {
          return false;
        }

        // 3. HS Code / Product Description Filter
        if (filters.hsCodeOrProduct.trim().isNotEmpty) {
          final query = filters.hsCodeOrProduct.trim().toLowerCase();
          final hs = (f.hsCode ?? '').toLowerCase();
          final cat = (f.productCategory ?? '').toLowerCase();
          final notes = (f.notes ?? '').toLowerCase();
          final name = (f.customFileNumber ?? f.importFileCode).toLowerCase();

          final matches = hs.contains(query) ||
              cat.contains(query) ||
              notes.contains(query) ||
              name.contains(query);
          if (!matches) return false;
        }

        // 4. Incoterm Filter
        if (filters.incotermCode != null &&
            filters.incotermCode!.isNotEmpty &&
            filters.incotermCode != 'All') {
          if (f.incotermCode.toLowerCase() != filters.incotermCode!.toLowerCase()) {
            return false;
          }
        }

        // 5. Port of Loading (POL)
        if (filters.portOfLoading != null && filters.portOfLoading!.trim().isNotEmpty) {
          final pol = (f.portOfLoading ?? '').toLowerCase();
          if (!pol.contains(filters.portOfLoading!.trim().toLowerCase())) {
            return false;
          }
        }

        // 6. Port of Discharge (POD)
        if (filters.portOfDischarge != null && filters.portOfDischarge!.trim().isNotEmpty) {
          final pod = (f.portOfDischarge ?? '').toLowerCase();
          if (!pod.contains(filters.portOfDischarge!.trim().toLowerCase())) {
            return false;
          }
        }

        // 7. Shipping Mode
        if (filters.shipmentMode != null &&
            filters.shipmentMode!.isNotEmpty &&
            filters.shipmentMode != 'All') {
          if (!f.shipmentMode.toLowerCase().contains(filters.shipmentMode!.toLowerCase())) {
            return false;
          }
        }

        // 8. Carrier / Shipping Line
        if (filters.carrier != null && filters.carrier!.trim().isNotEmpty) {
          final car = (f.selectedScenario ?? '').toLowerCase();
          if (!car.contains(filters.carrier!.trim().toLowerCase())) {
            return false;
          }
        }

        // 9. Free-text search
        if (filters.search.trim().isNotEmpty) {
          final s = filters.search.trim().toLowerCase();
          final matches = f.importFileCode.toLowerCase().contains(s) ||
              (f.customFileNumber ?? '').toLowerCase().contains(s) ||
              f.companyName.toLowerCase().contains(s) ||
              f.supplierName.toLowerCase().contains(s) ||
              (f.poNumber ?? '').toLowerCase().contains(s) ||
              (f.piNumber ?? '').toLowerCase().contains(s) ||
              (f.hsCode ?? '').toLowerCase().contains(s) ||
              (f.productCategory ?? '').toLowerCase().contains(s) ||
              (f.portOfLoading ?? '').toLowerCase().contains(s) ||
              (f.portOfDischarge ?? '').toLowerCase().contains(s) ||
              (f.selectedScenario ?? '').toLowerCase().contains(s) ||
              (f.notes ?? '').toLowerCase().contains(s);
          if (!matches) return false;
        }

        return true;
      }).toList();

      // Sorting
      result.sort((a, b) {
        int cmp = 0;
        switch (inquiryState.sortField) {
          case ShipmentInquirySortField.shipmentName:
            cmp = (a.customFileNumber ?? a.importFileCode)
                .compareTo(b.customFileNumber ?? b.importFileCode);
            break;
          case ShipmentInquirySortField.supplierName:
            cmp = a.supplierName.compareTo(b.supplierName);
            break;
          case ShipmentInquirySortField.companyName:
            cmp = a.companyName.compareTo(b.companyName);
            break;
          case ShipmentInquirySortField.itemAndHs:
            cmp = (a.hsCode ?? '').compareTo(b.hsCode ?? '');
            break;
          case ShipmentInquirySortField.route:
            cmp = (a.portOfDischarge ?? '').compareTo(b.portOfDischarge ?? '');
            break;
          case ShipmentInquirySortField.shippingMode:
            cmp = a.shipmentMode.compareTo(b.shipmentMode);
            break;
          case ShipmentInquirySortField.incoterm:
            cmp = a.incotermCode.compareTo(b.incotermCode);
            break;
          case ShipmentInquirySortField.freightCost:
            cmp = a.estimatedCost.compareTo(b.estimatedCost);
            break;
          case ShipmentInquirySortField.date:
            cmp = (a.fileOpeningDate ?? '').compareTo(b.fileOpeningDate ?? '');
            break;
        }
        return inquiryState.isAscending ? cmp : -cmp;
      });

      return result;
    },
    orElse: () => [],
  );
});

/// Stats Provider for KPI banner
final shipmentInquiryStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final shipments = ref.watch(filteredShipmentsProvider);
  final totalCount = shipments.length;
  final totalFreightCost = shipments.fold<double>(
      0.0, (sum, item) => sum + item.estimatedCost);
  final avgFreightCost = totalCount > 0 ? (totalFreightCost / totalCount) : 0.0;

  return {
    'total_count': totalCount,
    'total_freight_cost': totalFreightCost,
    'average_freight_cost': avgFreightCost,
  };
});
