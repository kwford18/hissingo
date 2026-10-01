enum Activity {
  idle,
  wandering,
  seekingFood,
  eating,
  seekingWater,
  drinking,
  seekingHide,
  enteringHide,
  hiding,
  exitingHide,
  seekingEnrichment,
  usingEnrichment,
  seekingSocial,
  interacting,
  excitedForTreat;

  // Whether this activity has the roach travelling towards a target
  bool get isMoving =>
      this == wandering ||
      this == seekingFood ||
      this == seekingWater ||
      this == seekingHide ||
      this == enteringHide ||
      this == exitingHide ||
      this == seekingEnrichment ||
      this == seekingSocial ||
      this == excitedForTreat;
}
