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

  // Whether this activity has the roach travelling towards a target.
  // Listed exhaustively so adding a new Activity forces a decision here.
  bool get isMoving => switch (this) {
    Activity.wandering ||
    Activity.seekingFood ||
    Activity.seekingWater ||
    Activity.seekingHide ||
    Activity.enteringHide ||
    Activity.exitingHide ||
    Activity.seekingEnrichment ||
    Activity.seekingSocial ||
    Activity.excitedForTreat => true,
    Activity.idle ||
    Activity.eating ||
    Activity.drinking ||
    Activity.hiding ||
    Activity.usingEnrichment ||
    Activity.interacting => false,
  };

  // Activities that must finish before the roach picks something new
  bool get isTransitional =>
      this == enteringHide || this == exitingHide || this == excitedForTreat;
}
