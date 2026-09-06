import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/masterdata_repository.dart';
import '../domain/masterdata_models.dart';

enum MasterDataTab { products, parties, drivers, vehicles, locations, lossTypes }

final masterDataRepositoryProvider = Provider<MasterDataRepository>((ref) {
  return MasterDataRepository(ref.watch(apiClientProvider));
});

final selectedMasterTabProvider = StateProvider<MasterDataTab>((ref) => MasterDataTab.products);
final masterDataSearchProvider = StateProvider<String>((ref) => '');

final productsListProvider = FutureProvider.autoDispose<List<ProductItem>>((ref) async {
  final repo = ref.watch(masterDataRepositoryProvider);
  final search = ref.watch(masterDataSearchProvider);
  return repo.fetchProducts(search: search);
});

final partiesListProvider = FutureProvider.autoDispose<List<PartyItem>>((ref) async {
  final repo = ref.watch(masterDataRepositoryProvider);
  final search = ref.watch(masterDataSearchProvider);
  return repo.fetchParties(search: search);
});

final driversListProvider = FutureProvider.autoDispose<List<DriverItem>>((ref) async {
  final repo = ref.watch(masterDataRepositoryProvider);
  final search = ref.watch(masterDataSearchProvider);
  return repo.fetchDrivers(search: search);
});

final vehiclesListProvider = FutureProvider.autoDispose<List<VehicleItem>>((ref) async {
  final repo = ref.watch(masterDataRepositoryProvider);
  final search = ref.watch(masterDataSearchProvider);
  return repo.fetchVehicles(search: search);
});
