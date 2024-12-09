import 'package:flutter/material.dart';

class OrderProvider with ChangeNotifier {
  Map<String, dynamic>? _savedOrder;
  Map<String, dynamic>? _savedMerchant;

  Map<String, dynamic>? get savedOrder => _savedOrder;
  Map<String, dynamic>? get savedMerchant => _savedMerchant;

  void saveOrder(Map<String, dynamic> order, Map<String, dynamic> merchant) {
    _savedOrder = order;
    _savedMerchant = merchant;
    notifyListeners();
  }

  void clearOrder() {
    _savedOrder = null;
    _savedMerchant = null;
    notifyListeners();
  }
}
