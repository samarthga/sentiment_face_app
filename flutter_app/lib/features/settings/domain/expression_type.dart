/// Expression type for AI-generated face images.
enum ExpressionType {
  /// Close-up face shot only.
  faceOnly('Face Only', 'close-up portrait shot of their face'),

  /// Upper body including shoulders and partial torso.
  upperBody('Upper Body', 'upper body shot showing head, shoulders, and upper torso'),

  /// Full body shot.
  fullBody('Full Body', 'full body shot showing the entire person');

  const ExpressionType(this.label, this.promptDescription);

  /// Display label for the UI.
  final String label;

  /// Description used in Gemini prompts.
  final String promptDescription;
}
