import '../roach/activity.dart';

extension ActivityLabel on Activity {
  // Translates enum values into a clean readable format for the UI
  String get label => switch (this) {
    Activity.idle => 'Idle',
    Activity.wandering => 'Wandering',
    Activity.seekingFood => 'Seeking Food',
    Activity.eating => 'Eating',
    Activity.seekingWater => 'Seeking Water',
    Activity.drinking => 'Drinking',
    Activity.seekingHide => 'Seeking Hide',
    Activity.enteringHide => 'Entering Hide',
    Activity.hiding => 'Hiding',
    Activity.exitingHide => 'Exiting Hide',
    Activity.seekingEnrichment => 'Seeking Enrichment',
    Activity.usingEnrichment => 'Using Enrichment',
    Activity.seekingSocial => 'Seeking Social Interaction',
    Activity.interacting => 'Interacting with another roach',
    Activity.excitedForTreat => 'Excited for Treat',
  };
}
