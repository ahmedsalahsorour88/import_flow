import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/localization/app_localizations.dart';
import 'package:frontend/core/localization/app_localizations_ar.dart';
import 'package:frontend/core/localization/app_localizations_en.dart';
import 'package:frontend/core/localization/locale_provider.dart';
import 'package:frontend/features/auth/models/user_model.dart';
import 'package:frontend/features/auth/providers/auth_provider.dart';
import 'package:frontend/features/auth/providers/users_provider.dart';
import 'package:frontend/features/auth/screens/users_management_screen.dart';

class MockUsersNotifier extends UsersNotifier {
  MockUsersNotifier(List<UserDetail> users) : super(Dio()) {
    state = UsersState(users: users, isLoading: false);
  }

  @override
  Future<void> fetchUsers() async {}
}

class MockAuthNotifier extends AuthNotifier {
  MockAuthNotifier(UserModel user) : super(Dio(), const FlutterSecureStorage()) {
    state = AuthState(user: user, isAuthenticated: true);
  }
}

void main() {
  group('Screen 66: Users Management & RBAC Localization Tests', () {
    late AppLocalizations ar;
    late AppLocalizations en;

    setUp(() {
      ar = const AppLocalizationsAr();
      en = const AppLocalizationsEn();
    });

    test('All Screen 66 getters should return non-empty strings in Arabic and English', () {
      // Header & Navigation
      expect(ar.usersMgmtTitle, isNotEmpty);
      expect(en.usersMgmtTitle, isNotEmpty);
      expect(ar.usersMgmtSubtitle(5), contains('5'));
      expect(en.usersMgmtSubtitle(5), contains('5'));
      expect(ar.usersMgmtRefreshTooltip, isNotEmpty);
      expect(en.usersMgmtRefreshTooltip, isNotEmpty);
      expect(ar.usersMgmtNewUserBtn, isNotEmpty);
      expect(en.usersMgmtNewUserBtn, isNotEmpty);
      expect(ar.usersMgmtReadOnlyNotice, isNotEmpty);
      expect(en.usersMgmtReadOnlyNotice, isNotEmpty);

      // Stat Chips & Filters
      expect(ar.usersMgmtStatAll, isNotEmpty);
      expect(en.usersMgmtStatAll, isNotEmpty);
      expect(ar.usersMgmtStatActive, isNotEmpty);
      expect(en.usersMgmtStatActive, isNotEmpty);
      expect(ar.usersMgmtStatAdmin, isNotEmpty);
      expect(en.usersMgmtStatAdmin, isNotEmpty);
      expect(ar.usersMgmtStatManager, isNotEmpty);
      expect(en.usersMgmtStatManager, isNotEmpty);
      expect(ar.usersMgmtStatOperator, isNotEmpty);
      expect(en.usersMgmtStatOperator, isNotEmpty);
      expect(ar.usersMgmtSearchHint, isNotEmpty);
      expect(en.usersMgmtSearchHint, isNotEmpty);

      // Table Column Headers
      expect(ar.usersMgmtColFullName, isNotEmpty);
      expect(en.usersMgmtColFullName, isNotEmpty);
      expect(ar.usersMgmtColUsername, isNotEmpty);
      expect(en.usersMgmtColUsername, isNotEmpty);
      expect(ar.usersMgmtColEmail, isNotEmpty);
      expect(en.usersMgmtColEmail, isNotEmpty);
      expect(ar.usersMgmtColRole, isNotEmpty);
      expect(en.usersMgmtColRole, isNotEmpty);
      expect(ar.usersMgmtColStatus, isNotEmpty);
      expect(en.usersMgmtColStatus, isNotEmpty);
      expect(ar.usersMgmtColCreatedAt, isNotEmpty);
      expect(en.usersMgmtColCreatedAt, isNotEmpty);
      expect(ar.usersMgmtColActions, isNotEmpty);
      expect(en.usersMgmtColActions, isNotEmpty);

      // Row Badges & Actions
      expect(ar.usersMgmtSelfBadge, isNotEmpty);
      expect(en.usersMgmtSelfBadge, isNotEmpty);
      expect(ar.usersMgmtStatusActive, isNotEmpty);
      expect(en.usersMgmtStatusActive, isNotEmpty);
      expect(ar.usersMgmtStatusInactive, isNotEmpty);
      expect(en.usersMgmtStatusInactive, isNotEmpty);
      expect(ar.usersMgmtRoleAdminLabel, isNotEmpty);
      expect(en.usersMgmtRoleAdminLabel, isNotEmpty);
      expect(ar.usersMgmtRoleManagerLabel, isNotEmpty);
      expect(en.usersMgmtRoleManagerLabel, isNotEmpty);
      expect(ar.usersMgmtRoleOperatorLabel, isNotEmpty);
      expect(en.usersMgmtRoleOperatorLabel, isNotEmpty);
      expect(ar.usersMgmtActionEditTooltip, isNotEmpty);
      expect(en.usersMgmtActionEditTooltip, isNotEmpty);
      expect(ar.usersMgmtActionDeactivateTooltip, isNotEmpty);
      expect(en.usersMgmtActionDeactivateTooltip, isNotEmpty);
      expect(ar.usersMgmtActionActivateTooltip, isNotEmpty);
      expect(en.usersMgmtActionActivateTooltip, isNotEmpty);

      // Empty & Error States
      expect(ar.usersMgmtNoResults, isNotEmpty);
      expect(en.usersMgmtNoResults, isNotEmpty);
      expect(ar.usersMgmtNoResultsHint, isNotEmpty);
      expect(en.usersMgmtNoResultsHint, isNotEmpty);
      expect(ar.usersMgmtRetryBtn, isNotEmpty);
      expect(en.usersMgmtRetryBtn, isNotEmpty);

      // Add/Edit Dialog
      expect(ar.usersMgmtDialogEditTitle, isNotEmpty);
      expect(en.usersMgmtDialogEditTitle, isNotEmpty);
      expect(ar.usersMgmtDialogNewTitle, isNotEmpty);
      expect(en.usersMgmtDialogNewTitle, isNotEmpty);
      expect(ar.usersMgmtFieldFullName, isNotEmpty);
      expect(en.usersMgmtFieldFullName, isNotEmpty);
      expect(ar.usersMgmtFieldFullNameHint, isNotEmpty);
      expect(en.usersMgmtFieldFullNameHint, isNotEmpty);
      expect(ar.usersMgmtFieldFullNameRequired, isNotEmpty);
      expect(en.usersMgmtFieldFullNameRequired, isNotEmpty);
      expect(ar.usersMgmtFieldUsername, isNotEmpty);
      expect(en.usersMgmtFieldUsername, isNotEmpty);
      expect(ar.usersMgmtFieldUsernameHint, isNotEmpty);
      expect(en.usersMgmtFieldUsernameHint, isNotEmpty);
      expect(ar.usersMgmtFieldUsernameHelper, isNotEmpty);
      expect(en.usersMgmtFieldUsernameHelper, isNotEmpty);
      expect(ar.usersMgmtFieldUsernameRequired, isNotEmpty);
      expect(en.usersMgmtFieldUsernameRequired, isNotEmpty);
      expect(ar.usersMgmtFieldUsernameMinLength, isNotEmpty);
      expect(en.usersMgmtFieldUsernameMinLength, isNotEmpty);
      expect(ar.usersMgmtFieldUsernameNoSpaces, isNotEmpty);
      expect(en.usersMgmtFieldUsernameNoSpaces, isNotEmpty);
      expect(ar.usersMgmtFieldEmail, isNotEmpty);
      expect(en.usersMgmtFieldEmail, isNotEmpty);
      expect(ar.usersMgmtFieldEmailHint, isNotEmpty);
      expect(en.usersMgmtFieldEmailHint, isNotEmpty);
      expect(ar.usersMgmtFieldEmailRequired, isNotEmpty);
      expect(en.usersMgmtFieldEmailRequired, isNotEmpty);
      expect(ar.usersMgmtFieldEmailInvalid, isNotEmpty);
      expect(en.usersMgmtFieldEmailInvalid, isNotEmpty);
      expect(ar.usersMgmtFieldRole, isNotEmpty);
      expect(en.usersMgmtFieldRole, isNotEmpty);
      expect(ar.usersMgmtRoleAdminOption, isNotEmpty);
      expect(en.usersMgmtRoleAdminOption, isNotEmpty);
      expect(ar.usersMgmtRoleManagerOption, isNotEmpty);
      expect(en.usersMgmtRoleManagerOption, isNotEmpty);
      expect(ar.usersMgmtRoleOperatorOption, isNotEmpty);
      expect(en.usersMgmtRoleOperatorOption, isNotEmpty);
      expect(ar.usersMgmtFieldRoleRequired, isNotEmpty);
      expect(en.usersMgmtFieldRoleRequired, isNotEmpty);
      expect(ar.usersMgmtFieldPasswordNew, isNotEmpty);
      expect(en.usersMgmtFieldPasswordNew, isNotEmpty);
      expect(ar.usersMgmtFieldPassword, isNotEmpty);
      expect(en.usersMgmtFieldPassword, isNotEmpty);
      expect(ar.usersMgmtFieldPasswordRequired, isNotEmpty);
      expect(en.usersMgmtFieldPasswordRequired, isNotEmpty);
      expect(ar.usersMgmtFieldPasswordMinLength, isNotEmpty);
      expect(en.usersMgmtFieldPasswordMinLength, isNotEmpty);
      expect(ar.usersMgmtBtnCancel, isNotEmpty);
      expect(en.usersMgmtBtnCancel, isNotEmpty);
      expect(ar.usersMgmtBtnSave, isNotEmpty);
      expect(en.usersMgmtBtnSave, isNotEmpty);
      expect(ar.usersMgmtBtnCreate, isNotEmpty);
      expect(en.usersMgmtBtnCreate, isNotEmpty);
      expect(ar.usersMgmtSuccessUpdated, isNotEmpty);
      expect(en.usersMgmtSuccessUpdated, isNotEmpty);
      expect(ar.usersMgmtSuccessCreated, isNotEmpty);
      expect(en.usersMgmtSuccessCreated, isNotEmpty);

      // Confirm Toggle Status Dialog
      expect(ar.usersMgmtConfirmActivateTitle, isNotEmpty);
      expect(en.usersMgmtConfirmActivateTitle, isNotEmpty);
      expect(ar.usersMgmtConfirmDeactivateTitle, isNotEmpty);
      expect(en.usersMgmtConfirmDeactivateTitle, isNotEmpty);
      expect(ar.usersMgmtConfirmActivatePrompt, isNotEmpty);
      expect(en.usersMgmtConfirmActivatePrompt, isNotEmpty);
      expect(ar.usersMgmtConfirmDeactivatePrompt, isNotEmpty);
      expect(en.usersMgmtConfirmDeactivatePrompt, isNotEmpty);
      expect(ar.usersMgmtBtnActivate, isNotEmpty);
      expect(en.usersMgmtBtnActivate, isNotEmpty);
      expect(ar.usersMgmtBtnDeactivate, isNotEmpty);
      expect(en.usersMgmtBtnDeactivate, isNotEmpty);
      expect(ar.usersMgmtSuccessActivated, isNotEmpty);
      expect(en.usersMgmtSuccessActivated, isNotEmpty);
      expect(ar.usersMgmtSuccessDeactivated, isNotEmpty);
      expect(en.usersMgmtSuccessDeactivated, isNotEmpty);

      // Role Description Card & Permissions
      expect(ar.usersMgmtRoleAdminDescTitle, isNotEmpty);
      expect(en.usersMgmtRoleAdminDescTitle, isNotEmpty);
      expect(ar.usersMgmtRoleAdminPerm1, isNotEmpty);
      expect(en.usersMgmtRoleAdminPerm1, isNotEmpty);
      expect(ar.usersMgmtRoleAdminPerm2, isNotEmpty);
      expect(en.usersMgmtRoleAdminPerm2, isNotEmpty);
      expect(ar.usersMgmtRoleAdminPerm3, isNotEmpty);
      expect(en.usersMgmtRoleAdminPerm3, isNotEmpty);
      expect(ar.usersMgmtRoleAdminPerm4, isNotEmpty);
      expect(en.usersMgmtRoleAdminPerm4, isNotEmpty);
      expect(ar.usersMgmtRoleAdminPerm5, isNotEmpty);
      expect(en.usersMgmtRoleAdminPerm5, isNotEmpty);

      expect(ar.usersMgmtRoleManagerDescTitle, isNotEmpty);
      expect(en.usersMgmtRoleManagerDescTitle, isNotEmpty);
      expect(ar.usersMgmtRoleManagerPerm1, isNotEmpty);
      expect(en.usersMgmtRoleManagerPerm1, isNotEmpty);
      expect(ar.usersMgmtRoleManagerPerm2, isNotEmpty);
      expect(en.usersMgmtRoleManagerPerm2, isNotEmpty);
      expect(ar.usersMgmtRoleManagerPerm3, isNotEmpty);
      expect(en.usersMgmtRoleManagerPerm3, isNotEmpty);
      expect(ar.usersMgmtRoleManagerPerm4, isNotEmpty);
      expect(en.usersMgmtRoleManagerPerm4, isNotEmpty);
      expect(ar.usersMgmtRoleManagerPerm5, isNotEmpty);
      expect(en.usersMgmtRoleManagerPerm5, isNotEmpty);

      expect(ar.usersMgmtRoleOperatorDescTitle, isNotEmpty);
      expect(en.usersMgmtRoleOperatorDescTitle, isNotEmpty);
      expect(ar.usersMgmtRoleOperatorPerm1, isNotEmpty);
      expect(en.usersMgmtRoleOperatorPerm1, isNotEmpty);
      expect(ar.usersMgmtRoleOperatorPerm2, isNotEmpty);
      expect(en.usersMgmtRoleOperatorPerm2, isNotEmpty);
      expect(ar.usersMgmtRoleOperatorPerm3, isNotEmpty);
      expect(en.usersMgmtRoleOperatorPerm3, isNotEmpty);
      expect(ar.usersMgmtRoleOperatorPerm4, isNotEmpty);
      expect(en.usersMgmtRoleOperatorPerm4, isNotEmpty);
      expect(ar.usersMgmtRoleOperatorPerm5, isNotEmpty);
      expect(en.usersMgmtRoleOperatorPerm5, isNotEmpty);

      // Export Toolbar, Copy Feedback & Permissions Detail
      expect(ar.usersMgmtPermBadgeGrant, isNotEmpty);
      expect(en.usersMgmtPermBadgeGrant, isNotEmpty);
      expect(ar.usersMgmtPermBadgeRevoke, isNotEmpty);
      expect(en.usersMgmtPermBadgeRevoke, isNotEmpty);
      expect(ar.usersMgmtPermBadgeRole, isNotEmpty);
      expect(en.usersMgmtPermBadgeRole, isNotEmpty);
      expect(ar.usersMgmtPermTooltipGrant, isNotEmpty);
      expect(en.usersMgmtPermTooltipGrant, isNotEmpty);
      expect(ar.usersMgmtPermTooltipRevoke, isNotEmpty);
      expect(en.usersMgmtPermTooltipRevoke, isNotEmpty);
      expect(ar.usersMgmtPermTooltipRevertGrant, isNotEmpty);
      expect(en.usersMgmtPermTooltipRevertGrant, isNotEmpty);
      expect(ar.usersMgmtPermTooltipRevertRevoke, isNotEmpty);
      expect(en.usersMgmtPermTooltipRevertRevoke, isNotEmpty);
      expect(ar.usersMgmtExportTsvBtn, isNotEmpty);
      expect(en.usersMgmtExportTsvBtn, isNotEmpty);
      expect(ar.usersMgmtExportExcelBtn, isNotEmpty);
      expect(en.usersMgmtExportExcelBtn, isNotEmpty);
      expect(ar.usersMgmtPrintPdfBtn, isNotEmpty);
      expect(en.usersMgmtPrintPdfBtn, isNotEmpty);
      expect(ar.usersMgmtCopyDossierBtn, isNotEmpty);
      expect(en.usersMgmtCopyDossierBtn, isNotEmpty);
      expect(ar.usersMgmtCopiedTsvSuccess, isNotEmpty);
      expect(en.usersMgmtCopiedTsvSuccess, isNotEmpty);
      expect(ar.usersMgmtCopiedExcelSuccess, isNotEmpty);
      expect(en.usersMgmtCopiedExcelSuccess, isNotEmpty);
      expect(ar.usersMgmtCopiedDossierSuccess, isNotEmpty);
      expect(en.usersMgmtCopiedDossierSuccess, isNotEmpty);
      expect(ar.usersMgmtCopyRowSummaryBtn, isNotEmpty);
      expect(en.usersMgmtCopyRowSummaryBtn, isNotEmpty);
      expect(ar.usersMgmtCopyRowSummarySuccess, isNotEmpty);
      expect(en.usersMgmtCopyRowSummarySuccess, isNotEmpty);
      expect(ar.usersMgmtCopyBadgeSuccess('اسم المستخدم', 'admin'), isNotEmpty);
      expect(en.usersMgmtCopyBadgeSuccess('Username', 'admin'), isNotEmpty);
      expect(ar.usersMgmtSearchCopied, isNotEmpty);
      expect(en.usersMgmtSearchCopied, isNotEmpty);
      expect(ar.usersMgmtCopyFieldTooltip('الاسم'), isNotEmpty);
      expect(en.usersMgmtCopyFieldTooltip('Name'), isNotEmpty);
      expect(ar.usersMgmtPdfTitle, isNotEmpty);
      expect(en.usersMgmtPdfTitle, isNotEmpty);
      expect(ar.usersMgmtPdfSubtitle, isNotEmpty);
      expect(en.usersMgmtPdfSubtitle, isNotEmpty);
      expect(ar.usersMgmtDossierHeader, isNotEmpty);
      expect(en.usersMgmtDossierHeader, isNotEmpty);
      expect(ar.usersMgmtDossierKpiSummary, isNotEmpty);
      expect(en.usersMgmtDossierKpiSummary, isNotEmpty);
      expect(ar.usersMgmtDossierRecordsDetails, isNotEmpty);
      expect(en.usersMgmtDossierRecordsDetails, isNotEmpty);
      expect(ar.usersMgmtDossierFooter, isNotEmpty);
      expect(en.usersMgmtDossierFooter, isNotEmpty);
    });

    test('Arabic static strings should not contain English or Latin characters', () {
      final latinPattern = RegExp(r'[a-zA-Z]');

      expect(latinPattern.hasMatch(ar.usersMgmtTitle), isFalse);
      expect(latinPattern.hasMatch(ar.usersMgmtSubtitle(10)), isFalse);
      expect(latinPattern.hasMatch(ar.usersMgmtRefreshTooltip), isFalse);
      expect(latinPattern.hasMatch(ar.usersMgmtNewUserBtn), isFalse);
      expect(latinPattern.hasMatch(ar.usersMgmtReadOnlyNotice), isFalse);
      expect(latinPattern.hasMatch(ar.usersMgmtStatAll), isFalse);
      expect(latinPattern.hasMatch(ar.usersMgmtStatActive), isFalse);
      expect(latinPattern.hasMatch(ar.usersMgmtStatAdmin), isFalse);
      expect(latinPattern.hasMatch(ar.usersMgmtStatManager), isFalse);
      expect(latinPattern.hasMatch(ar.usersMgmtStatOperator), isFalse);
      expect(latinPattern.hasMatch(ar.usersMgmtSearchHint), isFalse);
      expect(latinPattern.hasMatch(ar.usersMgmtColFullName), isFalse);
      expect(latinPattern.hasMatch(ar.usersMgmtColUsername), isFalse);
      expect(latinPattern.hasMatch(ar.usersMgmtColEmail), isFalse);
      expect(latinPattern.hasMatch(ar.usersMgmtColRole), isFalse);
      expect(latinPattern.hasMatch(ar.usersMgmtColStatus), isFalse);
      expect(latinPattern.hasMatch(ar.usersMgmtColCreatedAt), isFalse);
      expect(latinPattern.hasMatch(ar.usersMgmtColActions), isFalse);
      expect(latinPattern.hasMatch(ar.usersMgmtSelfBadge), isFalse);
      expect(latinPattern.hasMatch(ar.usersMgmtStatusActive), isFalse);
      expect(latinPattern.hasMatch(ar.usersMgmtStatusInactive), isFalse);
      expect(latinPattern.hasMatch(ar.usersMgmtRoleAdminLabel), isFalse);
      expect(latinPattern.hasMatch(ar.usersMgmtRoleManagerLabel), isFalse);
      expect(latinPattern.hasMatch(ar.usersMgmtRoleOperatorLabel), isFalse);
      expect(latinPattern.hasMatch(ar.usersMgmtActionEditTooltip), isFalse);
      expect(latinPattern.hasMatch(ar.usersMgmtActionDeactivateTooltip), isFalse);
      expect(latinPattern.hasMatch(ar.usersMgmtActionActivateTooltip), isFalse);
      expect(latinPattern.hasMatch(ar.usersMgmtNoResults), isFalse);
      expect(latinPattern.hasMatch(ar.usersMgmtNoResultsHint), isFalse);
      expect(latinPattern.hasMatch(ar.usersMgmtRetryBtn), isFalse);

      expect(latinPattern.hasMatch(ar.usersMgmtDialogEditTitle), isFalse);
      expect(latinPattern.hasMatch(ar.usersMgmtDialogNewTitle), isFalse);
      expect(latinPattern.hasMatch(ar.usersMgmtFieldFullName), isFalse);
      expect(latinPattern.hasMatch(ar.usersMgmtFieldFullNameHint), isFalse);
      expect(latinPattern.hasMatch(ar.usersMgmtFieldUsername), isFalse);
      expect(ar.usersMgmtFieldUsernameHint, startsWith('مثال:'));
      expect(latinPattern.hasMatch(ar.usersMgmtFieldUsernameHelper), isFalse);
      expect(latinPattern.hasMatch(ar.usersMgmtFieldUsernameRequired), isFalse);
      expect(latinPattern.hasMatch(ar.usersMgmtFieldUsernameMinLength), isFalse);
      expect(latinPattern.hasMatch(ar.usersMgmtFieldUsernameNoSpaces), isFalse);
      expect(latinPattern.hasMatch(ar.usersMgmtFieldEmail), isFalse);
      expect(ar.usersMgmtFieldEmailHint, startsWith('مثال:'));
      expect(latinPattern.hasMatch(ar.usersMgmtFieldEmailRequired), isFalse);
      expect(latinPattern.hasMatch(ar.usersMgmtFieldEmailInvalid), isFalse);
      expect(latinPattern.hasMatch(ar.usersMgmtFieldRole), isFalse);
      expect(latinPattern.hasMatch(ar.usersMgmtRoleAdminOption), isFalse);
      expect(latinPattern.hasMatch(ar.usersMgmtRoleManagerOption), isFalse);
      expect(latinPattern.hasMatch(ar.usersMgmtRoleOperatorOption), isFalse);
      expect(latinPattern.hasMatch(ar.usersMgmtFieldRoleRequired), isFalse);
      expect(latinPattern.hasMatch(ar.usersMgmtFieldPasswordNew), isFalse);
      expect(latinPattern.hasMatch(ar.usersMgmtFieldPassword), isFalse);
      expect(latinPattern.hasMatch(ar.usersMgmtFieldPasswordRequired), isFalse);
      expect(latinPattern.hasMatch(ar.usersMgmtFieldPasswordMinLength), isFalse);
      expect(latinPattern.hasMatch(ar.usersMgmtBtnCancel), isFalse);
      expect(latinPattern.hasMatch(ar.usersMgmtBtnSave), isFalse);
      expect(latinPattern.hasMatch(ar.usersMgmtBtnCreate), isFalse);
      expect(latinPattern.hasMatch(ar.usersMgmtSuccessUpdated), isFalse);
      expect(latinPattern.hasMatch(ar.usersMgmtSuccessCreated), isFalse);

      expect(latinPattern.hasMatch(ar.usersMgmtConfirmActivateTitle), isFalse);
      expect(latinPattern.hasMatch(ar.usersMgmtConfirmDeactivateTitle), isFalse);
      expect(latinPattern.hasMatch(ar.usersMgmtConfirmActivatePrompt), isFalse);
      expect(latinPattern.hasMatch(ar.usersMgmtConfirmDeactivatePrompt), isFalse);
      expect(latinPattern.hasMatch(ar.usersMgmtBtnActivate), isFalse);
      expect(latinPattern.hasMatch(ar.usersMgmtBtnDeactivate), isFalse);
      expect(latinPattern.hasMatch(ar.usersMgmtSuccessActivated), isFalse);
      expect(latinPattern.hasMatch(ar.usersMgmtSuccessDeactivated), isFalse);

      expect(latinPattern.hasMatch(ar.usersMgmtRoleAdminDescTitle), isFalse);
      expect(latinPattern.hasMatch(ar.usersMgmtRoleAdminPerm1), isFalse);
      expect(latinPattern.hasMatch(ar.usersMgmtRoleAdminPerm2), isFalse);
      expect(latinPattern.hasMatch(ar.usersMgmtRoleAdminPerm3), isFalse);
      expect(latinPattern.hasMatch(ar.usersMgmtRoleAdminPerm4), isFalse);
      expect(latinPattern.hasMatch(ar.usersMgmtRoleAdminPerm5), isFalse);

      expect(latinPattern.hasMatch(ar.usersMgmtRoleManagerDescTitle), isFalse);
      expect(latinPattern.hasMatch(ar.usersMgmtRoleManagerPerm1), isFalse);
      expect(latinPattern.hasMatch(ar.usersMgmtRoleManagerPerm2), isFalse);
      expect(latinPattern.hasMatch(ar.usersMgmtRoleManagerPerm3), isFalse);
      expect(latinPattern.hasMatch(ar.usersMgmtRoleManagerPerm4), isFalse);
      expect(latinPattern.hasMatch(ar.usersMgmtRoleManagerPerm5), isFalse);

      expect(latinPattern.hasMatch(ar.usersMgmtRoleOperatorDescTitle), isFalse);
      expect(latinPattern.hasMatch(ar.usersMgmtRoleOperatorPerm1), isFalse);
      expect(latinPattern.hasMatch(ar.usersMgmtRoleOperatorPerm2), isFalse);
      expect(latinPattern.hasMatch(ar.usersMgmtRoleOperatorPerm3), isFalse);
      expect(latinPattern.hasMatch(ar.usersMgmtRoleOperatorPerm4), isFalse);
      expect(latinPattern.hasMatch(ar.usersMgmtRoleOperatorPerm5), isFalse);

      expect(latinPattern.hasMatch(ar.usersMgmtPermBadgeGrant), isFalse);
      expect(latinPattern.hasMatch(ar.usersMgmtPermBadgeRevoke), isFalse);
      expect(latinPattern.hasMatch(ar.usersMgmtPermBadgeRole), isFalse);
      expect(latinPattern.hasMatch(ar.usersMgmtPermTooltipGrant), isFalse);
      expect(latinPattern.hasMatch(ar.usersMgmtPermTooltipRevoke), isFalse);
      expect(latinPattern.hasMatch(ar.usersMgmtPermTooltipRevertGrant), isFalse);
      expect(latinPattern.hasMatch(ar.usersMgmtPermTooltipRevertRevoke), isFalse);
      expect(latinPattern.hasMatch(ar.usersMgmtExportTsvBtn), isFalse);
      expect(latinPattern.hasMatch(ar.usersMgmtExportExcelBtn), isFalse);
      expect(latinPattern.hasMatch(ar.usersMgmtPrintPdfBtn), isFalse);
      expect(latinPattern.hasMatch(ar.usersMgmtCopyDossierBtn), isFalse);
      expect(latinPattern.hasMatch(ar.usersMgmtCopiedTsvSuccess), isFalse);
      expect(latinPattern.hasMatch(ar.usersMgmtCopiedExcelSuccess), isFalse);
      expect(latinPattern.hasMatch(ar.usersMgmtCopiedDossierSuccess), isFalse);
      expect(latinPattern.hasMatch(ar.usersMgmtCopyRowSummaryBtn), isFalse);
      expect(latinPattern.hasMatch(ar.usersMgmtCopyRowSummarySuccess), isFalse);
      expect(latinPattern.hasMatch(ar.usersMgmtCopyBadgeSuccess('الاسم', 'أحمد')), isFalse);
      expect(latinPattern.hasMatch(ar.usersMgmtSearchCopied), isFalse);
      expect(latinPattern.hasMatch(ar.usersMgmtCopyFieldTooltip('الاسم')), isFalse);
      expect(latinPattern.hasMatch(ar.usersMgmtPdfTitle), isFalse);
      expect(latinPattern.hasMatch(ar.usersMgmtPdfSubtitle), isFalse);
      expect(latinPattern.hasMatch(ar.usersMgmtDossierHeader), isFalse);
      expect(latinPattern.hasMatch(ar.usersMgmtDossierKpiSummary), isFalse);
      expect(latinPattern.hasMatch(ar.usersMgmtDossierRecordsDetails), isFalse);
      expect(latinPattern.hasMatch(ar.usersMgmtDossierFooter), isFalse);
    });

    test('Arabic strings must NEVER contain bilingual slashes "/"', () {
      expect(ar.usersMgmtTitle.contains('/'), isFalse);
      expect(ar.usersMgmtSubtitle(5).contains('/'), isFalse);
      expect(ar.usersMgmtRefreshTooltip.contains('/'), isFalse);
      expect(ar.usersMgmtNewUserBtn.contains('/'), isFalse);
      expect(ar.usersMgmtReadOnlyNotice.contains('/'), isFalse);
      expect(ar.usersMgmtStatAll.contains('/'), isFalse);
      expect(ar.usersMgmtStatActive.contains('/'), isFalse);
      expect(ar.usersMgmtStatAdmin.contains('/'), isFalse);
      expect(ar.usersMgmtStatManager.contains('/'), isFalse);
      expect(ar.usersMgmtStatOperator.contains('/'), isFalse);
      expect(ar.usersMgmtColFullName.contains('/'), isFalse);
      expect(ar.usersMgmtColUsername.contains('/'), isFalse);
      expect(ar.usersMgmtColEmail.contains('/'), isFalse);
      expect(ar.usersMgmtColRole.contains('/'), isFalse);
      expect(ar.usersMgmtColStatus.contains('/'), isFalse);
      expect(ar.usersMgmtColCreatedAt.contains('/'), isFalse);
      expect(ar.usersMgmtColActions.contains('/'), isFalse);
      expect(ar.usersMgmtExportTsvBtn.contains('/'), isFalse);
      expect(ar.usersMgmtExportExcelBtn.contains('/'), isFalse);
      expect(ar.usersMgmtPrintPdfBtn.contains('/'), isFalse);
      expect(ar.usersMgmtCopyDossierBtn.contains('/'), isFalse);
      expect(ar.usersMgmtPdfTitle.contains('/'), isFalse);
      expect(ar.usersMgmtDossierHeader.contains('/'), isFalse);
      expect(ar.usersMgmtDossierFooter.contains('/'), isFalse);
    });

    test('Stacked bilingual patterns should not exist in English strings', () {
      final stackedPattern = RegExp(r'[\u0600-\u06FF]');
      expect(stackedPattern.hasMatch(en.usersMgmtTitle), isFalse);
      expect(stackedPattern.hasMatch(en.usersMgmtSubtitle(10)), isFalse);
      expect(stackedPattern.hasMatch(en.usersMgmtRefreshTooltip), isFalse);
      expect(stackedPattern.hasMatch(en.usersMgmtNewUserBtn), isFalse);
      expect(stackedPattern.hasMatch(en.usersMgmtReadOnlyNotice), isFalse);
      expect(stackedPattern.hasMatch(en.usersMgmtStatAll), isFalse);
      expect(stackedPattern.hasMatch(en.usersMgmtStatActive), isFalse);
      expect(stackedPattern.hasMatch(en.usersMgmtStatAdmin), isFalse);
      expect(stackedPattern.hasMatch(en.usersMgmtStatManager), isFalse);
      expect(stackedPattern.hasMatch(en.usersMgmtStatOperator), isFalse);
      expect(stackedPattern.hasMatch(en.usersMgmtSearchHint), isFalse);
      expect(stackedPattern.hasMatch(en.usersMgmtColFullName), isFalse);
      expect(stackedPattern.hasMatch(en.usersMgmtColUsername), isFalse);
      expect(stackedPattern.hasMatch(en.usersMgmtColEmail), isFalse);
      expect(stackedPattern.hasMatch(en.usersMgmtColRole), isFalse);
      expect(stackedPattern.hasMatch(en.usersMgmtColStatus), isFalse);
      expect(stackedPattern.hasMatch(en.usersMgmtColCreatedAt), isFalse);
      expect(stackedPattern.hasMatch(en.usersMgmtColActions), isFalse);
      expect(stackedPattern.hasMatch(en.usersMgmtSelfBadge), isFalse);
      expect(stackedPattern.hasMatch(en.usersMgmtStatusActive), isFalse);
      expect(stackedPattern.hasMatch(en.usersMgmtStatusInactive), isFalse);
      expect(stackedPattern.hasMatch(en.usersMgmtRoleAdminLabel), isFalse);
      expect(stackedPattern.hasMatch(en.usersMgmtRoleManagerLabel), isFalse);
      expect(stackedPattern.hasMatch(en.usersMgmtRoleOperatorLabel), isFalse);
      expect(stackedPattern.hasMatch(en.usersMgmtActionEditTooltip), isFalse);
      expect(stackedPattern.hasMatch(en.usersMgmtActionDeactivateTooltip), isFalse);
      expect(stackedPattern.hasMatch(en.usersMgmtActionActivateTooltip), isFalse);
      expect(stackedPattern.hasMatch(en.usersMgmtNoResults), isFalse);
      expect(stackedPattern.hasMatch(en.usersMgmtNoResultsHint), isFalse);
      expect(stackedPattern.hasMatch(en.usersMgmtRetryBtn), isFalse);
      expect(stackedPattern.hasMatch(en.usersMgmtDialogEditTitle), isFalse);
      expect(stackedPattern.hasMatch(en.usersMgmtDialogNewTitle), isFalse);
      expect(stackedPattern.hasMatch(en.usersMgmtFieldFullName), isFalse);
      expect(stackedPattern.hasMatch(en.usersMgmtFieldUsername), isFalse);
      expect(stackedPattern.hasMatch(en.usersMgmtFieldEmail), isFalse);
      expect(stackedPattern.hasMatch(en.usersMgmtFieldRole), isFalse);
      expect(stackedPattern.hasMatch(en.usersMgmtRoleAdminOption), isFalse);
      expect(stackedPattern.hasMatch(en.usersMgmtRoleManagerOption), isFalse);
      expect(stackedPattern.hasMatch(en.usersMgmtRoleOperatorOption), isFalse);
      expect(stackedPattern.hasMatch(en.usersMgmtBtnCancel), isFalse);
      expect(stackedPattern.hasMatch(en.usersMgmtBtnSave), isFalse);
      expect(stackedPattern.hasMatch(en.usersMgmtBtnCreate), isFalse);
      expect(stackedPattern.hasMatch(en.usersMgmtRoleAdminDescTitle), isFalse);
      expect(stackedPattern.hasMatch(en.usersMgmtRoleManagerDescTitle), isFalse);
      expect(stackedPattern.hasMatch(en.usersMgmtRoleOperatorDescTitle), isFalse);
    });

    final sampleUsers = [
      UserDetail(
        userId: 1,
        username: 'ahmed_admin',
        email: 'ahmed@company.com',
        fullName: 'Ahmed Sorour',
        role: 'ADMIN',
        isActive: true,
        createdAt: '2026-09-01T10:00:00Z',
      ),
      UserDetail(
        userId: 2,
        username: 'salah_manager',
        email: 'salah@company.com',
        fullName: 'Salah Mohamed',
        role: 'MANAGER',
        isActive: true,
        createdAt: '2026-09-02T11:00:00Z',
      ),
      UserDetail(
        userId: 3,
        username: 'karim_op',
        email: 'karim@company.com',
        fullName: 'Karim Ali',
        role: 'OPERATOR',
        isActive: false,
        createdAt: '2026-09-03T12:00:00Z',
      ),
    ];

    testWidgets('UsersManagementScreen renders purely in Arabic without stacked English text', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localeProvider.overrideWith((ref) {
              final n = LocaleNotifier();
              n.setLocale(const Locale('ar'));
              return n;
            }),
            usersProvider.overrideWith((ref) => MockUsersNotifier(sampleUsers)),
            authProvider.overrideWith((ref) => MockAuthNotifier(sampleUsers.first)),
          ],
          child: const MaterialApp(
            home: AppLocalizationsProvider(
              locale: Locale('ar'),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: UsersManagementScreen(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify pure Arabic headers and titles
      expect(find.text('إدارة المستخدمين والصلاحيات'), findsOneWidget);
      expect(find.text('مستخدم جديد'), findsOneWidget);
      expect(find.text('الاسم الكامل'), findsOneWidget);
      expect(find.text('اسم المستخدم'), findsOneWidget);
      expect(find.text('البريد الإلكتروني'), findsOneWidget);
      expect(find.text('الدور والصلاحية'), findsOneWidget);

      // Verify no stacked bilingual strings exist
      expect(find.text('User Access Control (RBAC) — 3 مستخدم مسجل'), findsNothing);
      expect(find.text('Users & Access Control'), findsNothing);
      expect(find.text('New User'), findsNothing);
    });

    testWidgets('UsersManagementScreen renders purely in English without stacked Arabic text', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localeProvider.overrideWith((ref) {
              final n = LocaleNotifier();
              n.setLocale(const Locale('en'));
              return n;
            }),
            usersProvider.overrideWith((ref) => MockUsersNotifier(sampleUsers)),
            authProvider.overrideWith((ref) => MockAuthNotifier(sampleUsers.first)),
          ],
          child: const MaterialApp(
            home: AppLocalizationsProvider(
              locale: Locale('en'),
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: UsersManagementScreen(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify pure English headers and titles
      expect(find.text('Users & Access Control (RBAC)'), findsOneWidget);
      expect(find.text('New User'), findsOneWidget);
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Username'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Role & Access'), findsOneWidget);

      // Verify no Arabic text is shown on English UI
      expect(find.text('إدارة المستخدمين والصلاحيات'), findsNothing);
      expect(find.text('مستخدم جديد'), findsNothing);
      expect(find.text('الاسم الكامل'), findsNothing);
    });
  });
}
