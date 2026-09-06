class AppRoutes {
  static const String splash = '/splash';
  static const String login = '/login';
  
  // Shell Items
  static const String dashboard = '/dashboard';
  static const String tickets = '/tickets';
  static const String ticketCreate = '/tickets/new';
  static const String ticketDetail = '/tickets/:id';
  static String ticketDetailPath(int id) => '/tickets/$id';

  static const String trucksInYard = '/trucks-in-yard';
  static const String masterdata = '/masterdata';
  static const String reports = '/reports';
  static const String management = '/management';
  static const String partyRanking = '/management/parties/ranking';
  static const String partyDetail = '/management/parties/:id';
  static String partyDetailPath(int id) => '/management/parties/$id';
  static const String partyCompare = '/management/parties/compare';
  static const String monitoring = '/monitoring';
  static const String monitoringRules = '/monitoring/rules';
  static const String audit = '/audit';
  static const String users = '/users';
  static const String settings = '/settings';
  static const String securitySettings = '/settings/security';
  static const String patternSetup = '/settings/security/pattern-setup';
}
