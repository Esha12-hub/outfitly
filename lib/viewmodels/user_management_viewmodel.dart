import 'package:get/get.dart';
import '../controllers/base_controller.dart';
import '../models/user_model.dart';

class UserManagementViewModel extends BaseController {
  // Observable data
  final RxList<UserModel> _allUsers = <UserModel>[].obs;
  final RxList<UserModel> _activeUsers = <UserModel>[].obs;
  final RxList<UserModel> _blockedUsers = <UserModel>[].obs;
  final RxList<UserModel> _regularUsers = <UserModel>[].obs;
  final RxString _searchQuery = ''.obs;
  final RxString _selectedFilter = 'all'.obs;
  final RxBool _isRefreshing = false.obs;

  // Getters
  List<UserModel> get allUsers => _allUsers;
  List<UserModel> get activeUsers => _activeUsers;
  List<UserModel> get blockedUsers => _blockedUsers;
  List<UserModel> get regularUsers => _regularUsers;
  String get searchQuery => _searchQuery.value;
  String get selectedFilter => _selectedFilter.value;
  bool get isRefreshing => _isRefreshing.value;

  List<UserModel> get filteredUsers {
    List<UserModel> baseList;
    
    switch (_selectedFilter.value) {
      case 'active':
        baseList = _activeUsers;
        break;
      case 'blocked':
        baseList = _blockedUsers;
        break;
      case 'regular':
        baseList = _regularUsers;
        break;
      default:
        baseList = _allUsers;
    }

    if (_searchQuery.value.isEmpty) {
      return baseList;
    }

    return baseList.where((user) =>
      user.name.toLowerCase().contains(_searchQuery.value.toLowerCase()) ||
      user.email.toLowerCase().contains(_searchQuery.value.toLowerCase()) ||
      user.role.toLowerCase().contains(_searchQuery.value.toLowerCase())
    ).toList();
  }

  @override
  void onInit() {
    super.onInit();
    loadUsersData();
  }

  Future<void> loadUsersData() async {
    await safeAsyncCall(() async {
      _isRefreshing.value = true;
      await Future.delayed(const Duration(milliseconds: 1000));

      final mockUsers = [
        UserModel(
          id: '1',
          name: 'John Doe',
          email: 'john@example.com',
          role: 'Regular User',
          status: 'Active',
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
          wardrobeItems: 15,
          outfitsCreated: 8,
          tryOns: 12,
        ),
        UserModel(
          id: '2',
          name: 'Jane Smith',
          email: 'jane@example.com',
          role: 'Premium User',
          status: 'Active',
          createdAt: DateTime.now().subtract(const Duration(days: 15)),
          wardrobeItems: 25,
          outfitsCreated: 15,
          tryOns: 20,
        ),
        UserModel(
          id: '3',
          name: 'Mike Johnson',
          email: 'mike@example.com',
          role: 'Regular User',
          status: 'Blocked',
          createdAt: DateTime.now().subtract(const Duration(days: 45)),
          wardrobeItems: 8,
          outfitsCreated: 3,
          tryOns: 5,
        ),
        UserModel(
          id: '4',
          name: 'Sarah Wilson',
          email: 'sarah@example.com',
          role: 'Premium User',
          status: 'Active',
          createdAt: DateTime.now().subtract(const Duration(days: 7)),
          wardrobeItems: 30,
          outfitsCreated: 20,
          tryOns: 25,
        ),
        UserModel(
          id: '5',
          name: 'Alex Brown',
          email: 'alex@example.com',
          role: 'Regular User',
          status: 'Active',
          createdAt: DateTime.now().subtract(const Duration(days: 60)),
          wardrobeItems: 12,
          outfitsCreated: 6,
          tryOns: 10,
        ),
      ];
      
      _allUsers.value = mockUsers;
      _updateFilteredLists();
      
      _isRefreshing.value = false;
    });
  }

  void _updateFilteredLists() {
    _activeUsers.value = _allUsers.where((user) => user.status == 'Active').toList();
    _blockedUsers.value = _allUsers.where((user) => user.status == 'Blocked').toList();
    _regularUsers.value = _allUsers.where((user) => user.role == 'Regular User').toList();
  }

  void updateSearchQuery(String query) {
    _searchQuery.value = query;
  }

  void changeFilter(String filter) {
    _selectedFilter.value = filter;
  }

  Future<void> blockUser(String userId) async {
    await safeAsyncCall(() async {
      final index = _allUsers.indexWhere((user) => user.id == userId);
      if (index != -1) {
        final user = _allUsers[index];
        final updatedUser = user.copyWith(status: 'Blocked');
        _allUsers[index] = updatedUser;
        _updateFilteredLists();
        
        Get.snackbar(
          'Success',
          'User blocked successfully',
          backgroundColor: Get.theme.colorScheme.error,
          colorText: Get.theme.colorScheme.onError,
        );
      }
    });
  }

  Future<void> unblockUser(String userId) async {
    await safeAsyncCall(() async {
      final index = _allUsers.indexWhere((user) => user.id == userId);
      if (index != -1) {
        final user = _allUsers[index];
        final updatedUser = user.copyWith(status: 'Active');
        _allUsers[index] = updatedUser;
        _updateFilteredLists();
        
        Get.snackbar(
          'Success',
          'User unblocked successfully',
          backgroundColor: Get.theme.colorScheme.primary,
          colorText: Get.theme.colorScheme.onPrimary,
        );
      }
    });
  }

  Future<void> deleteUser(String userId) async {
    await safeAsyncCall(() async {
      _allUsers.removeWhere((user) => user.id == userId);
      _updateFilteredLists();
      
      Get.snackbar(
        'Success',
        'User deleted successfully',
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    });
  }

  Future<void> upgradeToPremium(String userId) async {
    await safeAsyncCall(() async {
      final index = _allUsers.indexWhere((user) => user.id == userId);
      if (index != -1) {
        final user = _allUsers[index];
        final updatedUser = user.copyWith(role: 'Premium User');
        _allUsers[index] = updatedUser;
        _updateFilteredLists();
        
        Get.snackbar(
          'Success',
          'User upgraded to premium',
          backgroundColor: Get.theme.colorScheme.primary,
          colorText: Get.theme.colorScheme.onPrimary,
        );
      }
    });
  }

  Future<void> refreshData() async {
    await loadUsersData();
  }

  void clearSearch() {
    _searchQuery.value = '';
  }

  int get totalUsers => _allUsers.length;
  int get activeUsersCount => _activeUsers.length;
  int get blockedUsersCount => _blockedUsers.length;
  int get premiumUsersCount => _allUsers.where((user) => user.role == 'Premium User').length;
}
