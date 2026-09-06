import '../../../../core/constants/permissions.dart';
import 'reauth_session.dart';

enum SensitiveAction {
  correctCompletedTicket,
  cancelTicket,
  overrideLoss,
  changeSecuritySettings,
  changePattern,
  disablePattern,
  disableBiometric,
  manageUser,
  managePermission,
  changeSystemSettings,
  exportSensitiveReport;

  String get titleFa {
    switch (this) {
      case SensitiveAction.correctCompletedTicket:
        return 'اصلاح وزن قبض';
      case SensitiveAction.cancelTicket:
        return 'ابطال قبض';
      case SensitiveAction.overrideLoss:
        return 'Override افت';
      case SensitiveAction.changeSecuritySettings:
        return 'تغییر تنظیمات امنیتی';
      case SensitiveAction.changePattern:
        return 'تغییر الگو';
      case SensitiveAction.disablePattern:
        return 'حذف الگو';
      case SensitiveAction.disableBiometric:
        return 'غیرفعال کردن بیومتریک';
      case SensitiveAction.manageUser:
        return 'مدیریت کاربران و تغییر نقش';
      case SensitiveAction.managePermission:
        return 'مدیریت مجوزها و دسترسی‌ها';
      case SensitiveAction.changeSystemSettings:
        return 'تغییر تنظیمات سیستم';
      case SensitiveAction.exportSensitiveReport:
        return 'مشاهده یا دریافت خروجی گزارش‌های حساس';
    }
  }

  String get descriptionFa {
    switch (this) {
      case SensitiveAction.correctCompletedTicket:
        return 'برای ادامه عملیات «اصلاح وزن قبض»، هویت خود را تأیید کنید.';
      case SensitiveAction.cancelTicket:
        return 'برای ادامه عملیات «ابطال قبض»، هویت خود را تأیید کنید.';
      case SensitiveAction.overrideLoss:
        return 'برای اعمال تغییرات دستی بر افت باسکول، هویت خود را تأیید کنید.';
      case SensitiveAction.changeSecuritySettings:
        return 'جهت تغییر تنظیمات امنیتی برنامه، هویت خود را تأیید نمایید.';
      case SensitiveAction.changePattern:
        return 'جهت تغییر الگوی ترسیمی ورود سریع، هویت خود را تأیید نمایید.';
      case SensitiveAction.disablePattern:
        return 'جهت حذف الگوی ترسیمی ورود، هویت خود را تأیید نمایید.';
      case SensitiveAction.disableBiometric:
        return 'جهت غیرفعال‌سازی ورود با اثر انگشت یا چهره، هویت خود را تأیید نمایید.';
      case SensitiveAction.manageUser:
        return 'جهت مدیریت یا ویرایش اطلاعات و نقش کاربر، هویت خود را تأیید نمایید.';
      case SensitiveAction.managePermission:
        return 'جهت تخصیص یا تغییر مجوزهای سیستم، هویت خود را تأیید نمایید.';
      case SensitiveAction.changeSystemSettings:
        return 'جهت تغییر پیکربندی سامانه باسکول، هویت خود را تأیید نمایید.';
      case SensitiveAction.exportSensitiveReport:
        return 'جهت دریافت خروجی و گزارش‌های حساس، هویت خود را تأیید نمایید.';
    }
  }

  /// Backend permission required for this action (if any).
  /// Re-authentication NEVER bypasses missing permissions.
  String? get requiredPermission {
    switch (this) {
      case SensitiveAction.correctCompletedTicket:
        return AppPermissions.ticketEditCompleted;
      case SensitiveAction.cancelTicket:
        return AppPermissions.ticketCancel;
      case SensitiveAction.overrideLoss:
        return AppPermissions.ticketEditCompleted;
      case SensitiveAction.manageUser:
        return AppPermissions.usersManage;
      case SensitiveAction.managePermission:
        return AppPermissions.usersManage;
      case SensitiveAction.changeSystemSettings:
        return AppPermissions.settingsManage;
      case SensitiveAction.exportSensitiveReport:
        return AppPermissions.reportsExport;
      case SensitiveAction.changeSecuritySettings:
      case SensitiveAction.changePattern:
      case SensitiveAction.disablePattern:
      case SensitiveAction.disableBiometric:
        return null;
    }
  }

  /// Minimum security level required to authorize this action.
  /// Allows critical actions (e.g. system changes or pattern deletions)
  /// to strictly require Backend Password in future policies.
  ReauthSecurityLevel get minimumSecurityLevel {
    switch (this) {
      case SensitiveAction.changeSystemSettings:
      case SensitiveAction.managePermission:
      case SensitiveAction.disablePattern:
        return ReauthSecurityLevel.backendPassword;
      case SensitiveAction.correctCompletedTicket:
      case SensitiveAction.cancelTicket:
      case SensitiveAction.overrideLoss:
      case SensitiveAction.changeSecuritySettings:
      case SensitiveAction.changePattern:
      case SensitiveAction.disableBiometric:
      case SensitiveAction.manageUser:
      case SensitiveAction.exportSensitiveReport:
        return ReauthSecurityLevel.biometric;
    }
  }
}
