import 'package:flutter/material.dart';

/// Defines a column definition for [EnterpriseDataTable].
class EnterpriseColumn<T> {
  /// Unique identifier for the column (used in preferences & sorting).
  final String id;

  /// Display title in the column header.
  final String title;

  /// Optional tooltip shown on header hover.
  final String? tooltip;

  /// Optional fixed column width in pixels. If null, automatically sized or flexed.
  final double? width;

  /// Optional flex factor when in responsive layout.
  final int flex;

  /// Whether the user can sort this column.
  final bool isSortable;

  /// Custom sort comparison function. If null, uses [exportValue] or [searchValue] lexicographical comparison.
  final int Function(T a, T b)? sortComparator;

  /// Whether this column participates in global text search.
  final bool isSearchable;

  /// Function to extract searchable text from the item for this column.
  final String Function(T item)? searchValue;

  /// Function to extract formatted plain-text value for Excel/CSV export and clipboard copy.
  final String Function(T item)? exportValue;

  /// Builder for rendering the cell widget.
  final Widget Function(BuildContext context, T item, int index) cellBuilder;

  /// Cell content alignment.
  final Alignment alignment;

  /// Text alignment in the header and cell.
  final TextAlign textAlign;

  /// Initial default visibility of the column.
  final bool isVisible;

  /// If true, the user cannot hide this column via the column visibility picker.
  final bool isLocked;

  const EnterpriseColumn({
    required this.id,
    required this.title,
    required this.cellBuilder,
    this.tooltip,
    this.width,
    this.flex = 1,
    this.isSortable = true,
    this.sortComparator,
    this.isSearchable = true,
    this.searchValue,
    this.exportValue,
    this.alignment = Alignment.centerLeft,
    this.textAlign = TextAlign.start,
    this.isVisible = true,
    this.isLocked = false,
  });

  /// Creates a copy of this column with modified properties.
  EnterpriseColumn<T> copyWith({
    String? id,
    String? title,
    String? tooltip,
    double? width,
    int? flex,
    bool? isSortable,
    int Function(T a, T b)? sortComparator,
    bool? isSearchable,
    String Function(T item)? searchValue,
    String Function(T item)? exportValue,
    Widget Function(BuildContext context, T item, int index)? cellBuilder,
    Alignment? alignment,
    TextAlign? textAlign,
    bool? isVisible,
    bool? isLocked,
  }) {
    return EnterpriseColumn<T>(
      id: id ?? this.id,
      title: title ?? this.title,
      tooltip: tooltip ?? this.tooltip,
      width: width ?? this.width,
      flex: flex ?? this.flex,
      isSortable: isSortable ?? this.isSortable,
      sortComparator: sortComparator ?? this.sortComparator,
      isSearchable: isSearchable ?? this.isSearchable,
      searchValue: searchValue ?? this.searchValue,
      exportValue: exportValue ?? this.exportValue,
      cellBuilder: cellBuilder ?? this.cellBuilder,
      alignment: alignment ?? this.alignment,
      textAlign: textAlign ?? this.textAlign,
      isVisible: isVisible ?? this.isVisible,
      isLocked: isLocked ?? this.isLocked,
    );
  }
}
