
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

IconData getIconForType(String type) {
  switch (type) {
    case 'bike':
      return Icons.directions_bike;
    case 'hiking':
      return Icons.hiking;
    case 'beach':
      return Icons.beach_access;
    case 'museum':
      return Icons.museum;
    case 'park':
      return Icons.park;
    case 'art':
      return Icons.brush;
    default:
      return Icons.place;
  }
}