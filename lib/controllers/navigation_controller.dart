import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'base_controller.dart';

class NavigationController extends BaseController {
  final RxInt _currentIndex = 0.obs;
  final RxInt _previousIndex = 0.obs;
  final RxBool _canNavigate = true.obs;
  
  int get currentIndex => _currentIndex.value;
  int get previousIndex => _previousIndex.value;
  bool get canNavigate => _canNavigate.value;
  
  @override
  void onInit() {
    super.onInit();
    setIdle();
  }

  Future<void> changeIndex(int index) async {
    if (!_canNavigate.value || _currentIndex.value == index) return;
    
    _canNavigate.value = false;
    _previousIndex.value = _currentIndex.value;
    
    try {
      setLoading();

      await Future.delayed(const Duration(milliseconds: 100));
      
      _currentIndex.value = index;
      setSuccess();
      
    } catch (e) {
      setError('Navigation failed: $e');
      _currentIndex.value = _previousIndex.value;
    } finally {
      _canNavigate.value = true;
    }
  }

  Future<void> goToHome() async => await changeIndex(0);
  Future<void> goToUsers() async => await changeIndex(1);
  Future<void> goToContent() async => await changeIndex(2);
  Future<void> goToAnalytics() async => await changeIndex(3);
  Future<void> goToSettings() async => await changeIndex(4);

  void resetNavigation() {
    _currentIndex.value = 0;
    _previousIndex.value = 0;
    _canNavigate.value = true;
    setIdle();
  }

  bool canNavigateToIndex(int index) {
    return index >= 0 && index <= 4 && _canNavigate.value;
  }

  @override
  void onClose() {
    debugPrint('NavigationController disposed');
    super.onClose();
  }
}