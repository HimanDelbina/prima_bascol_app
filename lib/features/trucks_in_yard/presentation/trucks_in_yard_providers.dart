import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/yard_repository.dart';
import '../domain/yard_truck_model.dart';

final yardRepositoryProvider = Provider<YardRepository>((ref) {
  return YardRepository(ref.watch(apiClientProvider));
});

final yardTrucksSearchProvider = StateProvider<String>((ref) => '');

final waitingTrucksProvider = FutureProvider.autoDispose<List<YardTruckModel>>((ref) async {
  final repo = ref.watch(yardRepositoryProvider);
  return repo.fetchWaitingTrucks();
});

final filteredWaitingTrucksProvider = Provider.autoDispose<List<YardTruckModel>>((ref) {
  final search = ref.watch(yardTrucksSearchProvider).trim().toLowerCase();
  final trucksAsync = ref.watch(waitingTrucksProvider);

  return trucksAsync.maybeWhen(
    data: (trucks) {
      if (search.isEmpty) return trucks;
      return trucks.where((t) {
        return t.serialNumber.toLowerCase().contains(search) ||
            t.licensePlateDisplay.toLowerCase().contains(search) ||
            (t.driverName?.toLowerCase().contains(search) ?? false) ||
            (t.partyName?.toLowerCase().contains(search) ?? false) ||
            (t.productName?.toLowerCase().contains(search) ?? false);
      }).toList();
    },
    orElse: () => [],
  );
});
