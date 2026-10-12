import 'package:flutter/material.dart';

/// The icon for a place-interest key (`profiles.interests`): setup step 2,
/// the Interests editor and the Home card. Unknown keys get a generic pin.
IconData interestIconForKey(String key) => switch (key) {
  'nature' => Icons.park_outlined,
  'water' => Icons.terrain,
  'coast' => Icons.waves,
  'culture' => Icons.account_balance_outlined,
  'wild' => Icons.pets_outlined,
  'food' => Icons.restaurant_outlined,
  'views' => Icons.visibility_outlined,
  'relax' => Icons.spa_outlined,
  _ => Icons.place_outlined,
};
