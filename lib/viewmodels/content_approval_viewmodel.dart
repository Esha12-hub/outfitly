import 'package:get/get.dart';
import '../controllers/base_controller.dart';
import '../models/content_model.dart';

class ContentApprovalViewModel extends BaseController {
  // Observable data
  final RxList<ContentModel> _allContent = <ContentModel>[].obs;
  final RxList<ContentModel> _pendingContent = <ContentModel>[].obs;
  final RxList<ContentModel> _approvedContent = <ContentModel>[].obs;
  final RxList<ContentModel> _rejectedContent = <ContentModel>[].obs;
  final RxInt _selectedFilterIndex = 0.obs;
  final RxString _searchQuery = ''.obs;
  final RxBool _isRefreshing = false.obs;

  // Getters
  List<ContentModel> get allContent => _allContent;
  List<ContentModel> get pendingContent => _pendingContent;
  List<ContentModel> get approvedContent => _approvedContent;
  List<ContentModel> get rejectedContent => _rejectedContent;
  int get selectedFilterIndex => _selectedFilterIndex.value;
  String get searchQuery => _searchQuery.value;
  bool get isRefreshing => _isRefreshing.value;

  List<ContentModel> get filteredContent {
    switch (_selectedFilterIndex.value) {
      case 0:
        return _pendingContent;
      case 1:
        return _approvedContent;
      case 2:
        return _rejectedContent;
      default:
        return _allContent;
    }
  }

  @override
  void onInit() {
    super.onInit();
    loadContentData();
  }

  Future<void> loadContentData() async {
    await safeAsyncCall(() async {
      _isRefreshing.value = true;
      
      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 1000));
      
      // Mock data
      final mockContent = [
        ContentModel(
          id: '1',
          title: 'Summer Collection 2024',
          description: 'Latest summer fashion trends and styles',
          authorId: '1',
          authorName: 'Sarah Johnson',
          type: ContentType.outfit,
          status: ContentStatus.pending,
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          imageUrl: 'https://example.com/image1.jpg',
        ),
        ContentModel(
          id: '2',
          title: 'Fashion Tips for Beginners',
          description: 'Essential fashion tips for new users',
          authorId: '2',
          authorName: 'Mike Wilson',
          type: ContentType.article,
          status: ContentStatus.approved,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        ContentModel(
          id: '3',
          title: 'Winter Wardrobe Essentials',
          description: 'Must-have items for winter season',
          authorId: '3',
          authorName: 'Emma Davis',
          type: ContentType.outfit,
          status: ContentStatus.rejected,
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
          rejectionReason: 'Content quality below standards',
        ),
        ContentModel(
          id: '4',
          title: 'Sustainable Fashion Guide',
          description: 'How to build an eco-friendly wardrobe',
          authorId: '4',
          authorName: 'Alex Brown',
          type: ContentType.article,
          status: ContentStatus.pending,
          createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        ),
      ];
      
      _allContent.value = mockContent;
      _updateFilteredLists();
      
      _isRefreshing.value = false;
    });
  }

  void _updateFilteredLists() {
    _pendingContent.value = _allContent.where((content) => content.status == ContentStatus.pending).toList();
    _approvedContent.value = _allContent.where((content) => content.status == ContentStatus.approved).toList();
    _rejectedContent.value = _allContent.where((content) => content.status == ContentStatus.rejected).toList();
  }

  void changeFilter(int index) {
    _selectedFilterIndex.value = index;
  }

  void updateSearchQuery(String query) {
    _searchQuery.value = query;
  }

  List<ContentModel> get searchResults {
    if (_searchQuery.value.isEmpty) {
      return filteredContent;
    }
    
    return filteredContent.where((content) =>
      content.title.toLowerCase().contains(_searchQuery.value.toLowerCase()) ||
      content.authorName.toLowerCase().contains(_searchQuery.value.toLowerCase()) ||
      content.description.toLowerCase().contains(_searchQuery.value.toLowerCase())
    ).toList();
  }

  Future<void> approveContent(String contentId) async {
    await safeAsyncCall(() async {
      final index = _allContent.indexWhere((content) => content.id == contentId);
      if (index != -1) {
        final content = _allContent[index];
        final updatedContent = content.copyWith(status: ContentStatus.approved);
        _allContent[index] = updatedContent;
        _updateFilteredLists();
        
        Get.snackbar(
          'Success',
          'Content approved successfully',
          backgroundColor: Get.theme.colorScheme.primary,
          colorText: Get.theme.colorScheme.onPrimary,
        );
      }
    });
  }

  Future<void> rejectContent(String contentId, String reason) async {
    await safeAsyncCall(() async {
      final index = _allContent.indexWhere((content) => content.id == contentId);
      if (index != -1) {
        final content = _allContent[index];
        final updatedContent = content.copyWith(
          status: ContentStatus.rejected,
          rejectionReason: reason,
        );
        _allContent[index] = updatedContent;
        _updateFilteredLists();
        
        Get.snackbar(
          'Success',
          'Content rejected',
          backgroundColor: Get.theme.colorScheme.error,
          colorText: Get.theme.colorScheme.onError,
        );
      }
    });
  }

  Future<void> refreshData() async {
    await loadContentData();
  }

  void clearSearch() {
    _searchQuery.value = '';
  }
}
