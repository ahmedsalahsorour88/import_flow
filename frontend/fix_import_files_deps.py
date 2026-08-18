def fix(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        text = f.read()
    
    # Just dump all the imports from the screen file
    imports = """
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';
import '../../import_companies/providers/import_companies_provider.dart';
import '../../incoterms/providers/incoterms_provider.dart';
import '../../projects/providers/projects_provider.dart';
import '../../purchase_orders/providers/purchase_orders_provider.dart';
import '../../suppliers/providers/suppliers_provider.dart';
import '../../purchase_orders/models/purchase_order_model.dart' hide PackingListItemModel;
import '../../external_service_providers/providers/partners_provider.dart';
import '../../financial_approval/providers/financial_approval_provider.dart';
import '../../financial_approval/models/financial_approval_model.dart';
import '../../import_documentation/providers/import_documentation_provider.dart';
import '../../import_documentation/models/import_documentation_model.dart';
import '../../customs_consultation/providers/customs_consultation_provider.dart';
import '../../customs_consultation/models/customs_consultation_model.dart';
import '../../currencies/providers/currencies_provider.dart';
import '../../projects/models/project_model.dart';
import '../../../core/utils/container_requirement_engine.dart';
import '../../../core/widgets/container_load_plan_painter.dart';
import '../../../core/widgets/back_to_dashboard_button.dart';
import '../../../core/widgets/change_diff_dialog.dart';
import '../../../core/widgets/master_data_toolbar.dart';
import '../../../core/widgets/reopen_shipment_dialog.dart';
import '../../../core/widgets/row_actions_pill.dart';
import '../../../core/widgets/smart_upload_button.dart';
import '../../../core/widgets/stop_shipment_dialog.dart';
import '../models/import_file_model.dart';
import '../providers/import_files_provider.dart';
import '../../shipping_scenarios/providers/shipping_scenarios_provider.dart';
import '../widgets/close_shipment_dialog.dart';
"""
    import re
    # replace existing imports block
    text = re.sub(r'^(import .*\n)+', imports + '\n', text, flags=re.MULTILINE)
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(text)

fix('lib/features/import_files/widgets/import_file_details_dialog.dart')
fix('lib/features/import_files/widgets/import_file_form_dialog.dart')
