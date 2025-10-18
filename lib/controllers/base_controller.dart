import 'package:get/get.dart';
import 'package:flutter/material.dart';

enum ViewState { idle, loading, success, error, empty }

class BaseController extends GetxController {
  final Rx<ViewState> _viewState = ViewState.idle.obs;
  final RxString _errorMessage = ''.obs;
  final RxBool _isDisposed = false.obs;

  ViewState get viewState => _viewState.value;
  bool get isLoading => _viewState.value == ViewState.loading;
  bool get isSuccess => _viewState.value == ViewState.success;
  bool get isError => _viewState.value == ViewState.error;
  bool get isEmpty => _viewState.value == ViewState.empty;
  bool get isIdle => _viewState.value == ViewState.idle;
  String get errorMessage => _errorMessage.value;
  bool get isDisposed => _isDisposed.value;

  void setLoading() {
    if (!_isDisposed.value) {
      _viewState.value = ViewState.loading;
      _errorMessage.value = '';
    }
  }

  void setSuccess() {
    if (!_isDisposed.value) {
      _viewState.value = ViewState.success;
      _errorMessage.value = '';
    }
  }

  void setError(String error) {
    if (!_isDisposed.value) {
      _viewState.value = ViewState.error;
      _errorMessage.value = error;
    }
  }

  void setEmpty() {
    if (!_isDisposed.value) {
      _viewState.value = ViewState.empty;
      _errorMessage.value = '';
    }
  }

  void setIdle() {
    if (!_isDisposed.value) {
      _viewState.value = ViewState.idle;
      _errorMessage.value = '';
    }
  }

  void clearError() {
    if (!_isDisposed.value) {
      _errorMessage.value = '';
    }
  }

  // Safe async operation wrapper
  Future<T?> safeAsyncCall<T>(Future<T> Function() operation, {
    String? errorMessage,
    bool showLoading = true,
  }) async {
    try {
      if (showLoading) setLoading();
      
      final result = await operation();
      
      if (!_isDisposed.value) {
        setSuccess();
      }
      
      return result;
    } catch (e) {
      if (!_isDisposed.value) {
        setError(errorMessage ?? e.toString());
      }
      debugPrint('BaseController Error: $e');
      return null;
    }
  }

  @override
  void onClose() {
    _isDisposed.value = true;
    super.onClose();
  }
}