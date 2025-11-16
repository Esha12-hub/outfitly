import 'package:get/get.dart';
import '../controllers/base_controller.dart';
import '../models/user_model.dart';
import '../models/content_model.dart';

class DashboardViewModel extends BaseController {
  // Observable data
  final RxList<UserModel> _recentUsers = <UserModel>[].obs;
  final RxList<ContentModel> _pendingContent = <ContentModel>[].obs;
  final RxMap<String, int> _metrics = <String, int>{}.obs;
  final RxBool _isRefreshing = false.obs;

  // Getters
  List<UserModel> get recentUsers => _recentUsers;
  List<ContentModel> get pendingContent => _pendingContent;
  Map<String, int> get metrics => _metrics;
  bool get isRefreshing => _isRefreshing.value;

  @override
  void onInit() {
    super.onInit();
    loadDashboardData();
  }

  Future<void> loadDashboardData() async {
    await safeAsyncCall(() async {
      _isRefreshing.value = true;

      await Future.delayed(const Duration(milliseconds: 1000));

      _metrics.value = {
        'users': 2456,
        'items': 12500,
        'activeToday': 1046,
        'aiAccuracy': 98,
      };

      _recentUsers.value = [
        UserModel(
          id: '1',
          name: 'John Doe',
          email: 'john@example.com',
          role: 'Regular User',
          status: 'Active',
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
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
          createdAt: DateTime.now().subtract(const Duration(hours: 5)),
          wardrobeItems: 25,
          outfitsCreated: 15,
          tryOns: 20,
        ),
      ];

      _pendingContent.value = [
        ContentModel(
          id: '1',
          title: 'Summer Collection',
          description: 'New summer fashion collection',
          authorId: '1',
          authorName: 'Sarah Johnson',
          type: ContentType.outfit,
          status: ContentStatus.pending,
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        ),
        ContentModel(
          id: '2',
          title: 'Fashion Tips',
          description: 'How to style your wardrobe',
          authorId: '2',
          authorName: 'Mike Wilson',
          type: ContentType.article,
          status: ContentStatus.pending,
          createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        ),
      ];
      
      _isRefreshing.value = false;
    });
  }

  Future<void> refreshData() async {
    await loadDashboardData();
  }

  void approveContent(String contentId) {
    final index = _pendingContent.indexWhere((content) => content.id == contentId);
    if (index != -1) {
      final content = _pendingContent[index];
      final updatedContent = content.copyWith(status: ContentStatus.approved);
      _pendingContent[index] = updatedContent;
      Get.snackbar('Success', 'Content approved successfully');
    }
  }

  void rejectContent(String contentId, String reason) {
    final index = _pendingContent.indexWhere((content) => content.id == contentId);
    if (index != -1) {
      final content = _pendingContent[index];
      final updatedContent = content.copyWith(
        status: ContentStatus.rejected,
        rejectionReason: reason,
      );
      _pendingContent[index] = updatedContent;
      Get.snackbar('Success', 'Content rejected');
    }
  }
}
