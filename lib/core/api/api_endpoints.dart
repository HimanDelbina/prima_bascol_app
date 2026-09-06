class ApiEndpoints {
  // Auth
  static const String token = '/auth/token/';
  static const String tokenRefresh = '/auth/token/refresh/';
  static const String tokenVerify = '/auth/token/verify/';
  static const String logout = '/auth/logout/';
  static const String me = '/auth/me/';
  static const String verifyPassword = '/auth/verify-password/';

  // Dashboard
  static const String dashboardSummary = '/dashboard/summary/';
  static const String dashboardTrends = '/dashboard/trends/';

  // Weighbridge Tickets
  static const String tickets = '/tickets/';
  static String ticketDetail(int id) => '/tickets/$id/';
  static String ticketFirstWeight(int id) => '/tickets/$id/first-weight/';
  static String ticketSecondWeight(int id) => '/tickets/$id/second-weight/';
  static String ticketComplete(int id) => '/tickets/$id/complete/';
  static String ticketCancel(int id) => '/tickets/$id/cancel/';
  static String ticketCorrect(int id) => '/tickets/$id/correct/';
  static const String ticketsOpen = '/tickets/open/';
  static const String ticketsWaitingSecond = '/tickets/waiting-second-weight/';
  static String ticketAnalysis(int id) => '/tickets/$id/analysis/';

  // Master Data
  static const String products = '/products/';
  static String productDetail(int id) => '/products/$id/';
  static const String parties = '/parties/';
  static String partyDetail(int id) => '/parties/$id/';
  static const String drivers = '/drivers/';
  static String driverDetail(int id) => '/drivers/$id/';
  static const String vehicles = '/vehicles/';
  static String vehicleDetail(int id) => '/vehicles/$id/';
  static const String vehicleTypes = '/vehicle-types/';
  static String vehicleTypeDetail(int id) => '/vehicle-types/$id/';
  static const String locations = '/locations/';
  static String locationDetail(int id) => '/locations/$id/';
  static const String unloadLocations = '/unload-locations/';
  static String unloadLocationDetail(int id) => '/unload-locations/$id/';
  static const String operationTypes = '/operation-types/';
  static String operationTypeDetail(int id) => '/operation-types/$id/';
  static const String lossTypes = '/loss-types/';
  static String lossTypeDetail(int id) => '/loss-types/$id/';

  // Reports
  static const String reportTickets = '/reports/tickets/';
  static const String reportSummary = '/reports/tickets/summary/';
  static const String reportGrouped = '/reports/tickets/grouped/';
  static const String reportExportXlsx = '/reports/tickets/export/xlsx/';
  static const String reportExportCsv = '/reports/tickets/export/csv/';
  static const String reportExportPdf = '/reports/tickets/export/pdf/';

  // Management BI
  static const String managementSummary = '/management/summary/';
  static const String managementProducts = '/management/products/';
  static const String managementParties = '/management/parties/';
  static const String managementDiscrepancies = '/management/discrepancies/';
  static const String managementLosses = '/management/losses/';
  static const String managementVehicles = '/management/vehicles/';
  static const String managementDrivers = '/management/drivers/';
  static const String managementTurnaround = '/management/turnaround/';

  // Monitoring
  static const String monitoringAlerts = '/monitoring/alerts/';
  static String monitoringAlertDetail(int id) => '/monitoring/alerts/$id/';
  static String monitoringAlertReview(int id) =>
      '/monitoring/alerts/$id/review/';
  static String monitoringAlertResolve(int id) =>
      '/monitoring/alerts/$id/resolve/';
  static String monitoringAlertIgnore(int id) =>
      '/monitoring/alerts/$id/ignore/';
  static const String monitoringSummary = '/monitoring/summary/';
  static const String monitoringRules = '/monitoring/rules/';
  static String monitoringRuleDetail(int id) => '/monitoring/rules/$id/';

  // Audit
  static const String audit = '/audit/';

  // Users & Roles
  static const String users = '/users/';
  static String userDetail(int id) => '/users/$id/';
  static const String roles = '/roles/';

  // System & Settings
  static const String settings = '/settings/';
  static const String adminSettings = '/admin/settings/';
  static const String health = '/health/';
  static const String meta = '/meta/';
}
