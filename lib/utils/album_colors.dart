import 'package:flutter/material.dart';

const List<String> albumColorHex = ['1565F5', 'EF5350', '66BB6A', 'FFA726', 'AB47BC', '26A69A', 'EC407A', '78909C'];

Color colorFromHex(String hex) => Color(int.parse('FF$hex', radix: 16));