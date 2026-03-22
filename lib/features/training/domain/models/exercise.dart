class Exercise {
  final String id;
  final String packageId;
  final int sequenceNumber;
  final String titleDe;
  final String titleEn;
  final List<String> positionInstructionsDe;
  final List<String> positionInstructionsEn;
  final List<String> movementInstructionsDe;
  final List<String> movementInstructionsEn;
  final List<String>? hintsDe;
  final List<String>? hintsEn;
  final String executionGuideDe;
  final String executionGuideEn;
  final int durationSeconds;
  final int repetitions;
  final String imagePath;
  final String? videoPath; // Supabase Storage path e.g. 'moro/moro_1.mp4'
  final String? audioCuePath;

  const Exercise({
    required this.id,
    required this.packageId,
    required this.sequenceNumber,
    required this.titleDe,
    required this.titleEn,
    required this.positionInstructionsDe,
    required this.positionInstructionsEn,
    required this.movementInstructionsDe,
    required this.movementInstructionsEn,
    this.hintsDe,
    this.hintsEn,
    required this.executionGuideDe,
    required this.executionGuideEn,
    required this.durationSeconds,
    required this.repetitions,
    required this.imagePath,
    this.videoPath,
    this.audioCuePath,
  });

  String title(String locale) => locale == 'de' ? titleDe : titleEn;
  List<String> positionInstructions(String locale) =>
      locale == 'de' ? positionInstructionsDe : positionInstructionsEn;
  List<String> movementInstructions(String locale) =>
      locale == 'de' ? movementInstructionsDe : movementInstructionsEn;
  List<String>? hints(String locale) => locale == 'de' ? hintsDe : hintsEn;
  String executionGuide(String locale) =>
      locale == 'de' ? executionGuideDe : executionGuideEn;
}

// ============================================================================
// MORO PACKAGE — 7 exercises (static fallback content)
// Primary source: Supabase 'exercises' table. This list is the offline fallback.
// ============================================================================

const List<Exercise> moroExercises = [
  // Exercise 1 of 7 — Moro 5
  Exercise(
    id: 'moro_ex1',
    packageId: 'moro',
    sequenceNumber: 1,
    titleDe: 'Moro 5',
    titleEn: 'Moro 5',
    positionInstructionsDe: [
      'Rückenlage',
      'Beide Beine ausgestreckt',
      'Arme ausgestreckt neben dem Körper, Handflächen am Boden',
    ],
    positionInstructionsEn: [
      'Lie on your back',
      'Both legs extended',
      'Arms extended alongside the body, palms on the floor',
    ],
    movementInstructionsDe: [
      'Nur ein Bein bewegt sich',
      'Dieses Bein langsam in ca. drei Sekunden anheben und auf dem Schienbein des anderen Beins ablegen',
      'Kurz halten',
      'In drei Sekunden wieder zurück',
      'Seitenwechsel',
    ],
    movementInstructionsEn: [
      'Only one leg moves',
      'Slowly raise this leg over about three seconds and rest it on the shin of the other leg',
      'Hold briefly',
      'Return in three seconds',
      'Switch sides',
    ],
    hintsDe: [
      'Das nicht bewegte Bein bleibt komplett ruhig und unverändert liegen',
    ],
    hintsEn: [
      'The non-moving leg remains completely still',
    ],
    executionGuideDe: 'Bein anheben und auf dem Schienbein des anderen Beins ablegen.',
    executionGuideEn: 'Raise leg and rest it on the shin of the other leg.',
    durationSeconds: 40,
    repetitions: 3,
    imagePath: 'assets/images/trainings/moro/moro5.png',
    videoPath: 'moro/moro_5.mp4',
  ),

  // Exercise 2 of 7 — Moro 3 – Halber Frosch
  Exercise(
    id: 'moro_ex2',
    packageId: 'moro',
    sequenceNumber: 2,
    titleDe: 'Moro 3 – Halber Frosch',
    titleEn: 'Moro 3 – Half Frog',
    positionInstructionsDe: [
      'Rückenlage',
      'Beide Beine ausgestreckt',
      'Neutrale Ausgangsposition',
    ],
    positionInstructionsEn: [
      'Lie on your back',
      'Both legs extended',
      'Neutral starting position',
    ],
    movementInstructionsDe: [
      'Ein Bein bewegt sich:',
      'Fußsohle gleitet an der Innenseite des anderen Beins nach oben zum Körper, ca. drei Sekunden',
      'Dann in drei Sekunden wieder vollständig zurück in die neutrale Position',
      'Danach Seitenwechsel',
    ],
    movementInstructionsEn: [
      'One leg moves:',
      'The sole of the foot slides along the inside of the other leg upward toward the body, about three seconds',
      'Then slide back down to neutral over three seconds',
      'Switch sides',
    ],
    hintsDe: [
      'Fußsohle bleibt während der gesamten Bewegung am anderen Bein anliegend',
      'Bewegungsweite richtet sich nach diesem Kontakt',
    ],
    hintsEn: [
      'The sole of the foot remains in contact with the other leg throughout',
      'Range of motion is guided by this contact',
    ],
    executionGuideDe: 'Fußsohle gleitet am anderen Bein entlang nach oben.',
    executionGuideEn: 'Sole of foot slides up along the other leg.',
    durationSeconds: 40,
    repetitions: 3,
    imagePath: 'assets/images/trainings/moro/moro3.png',
    videoPath: 'moro/moro_3.mp4',
  ),

  // Exercise 3 of 7 — Moro 4 – Frosch
  Exercise(
    id: 'moro_ex3',
    packageId: 'moro',
    sequenceNumber: 3,
    titleDe: 'Moro 4 – Frosch',
    titleEn: 'Moro 4 – Frog',
    positionInstructionsDe: [
      'Rückenlage',
      'Beide Beine ausgestreckt',
      'Fußsohlen zusammenführen',
    ],
    positionInstructionsEn: [
      'Lie on your back',
      'Both legs extended',
      'Bring the soles of the feet together',
    ],
    movementInstructionsDe: [
      'Füße langsam drei Sekunden Richtung Körper führen',
      'Knie gehen dabei nach außen',
      'Füße anschließend drei Sekunden zurückführen',
    ],
    movementInstructionsEn: [
      'Slowly bring feet toward the body over three seconds',
      'Knees open outward',
      'Return feet over three seconds',
    ],
    hintsDe: [
      'Range of Motion nur so weit, wie die Fußsohlen während der gesamten Bewegung eng aneinander bleiben',
    ],
    hintsEn: [
      'Only move as far as the soles of the feet can remain together throughout',
    ],
    executionGuideDe: 'Füße zum Körper führen, Knie gehen nach außen.',
    executionGuideEn: 'Bring feet toward the body, knees open outward.',
    durationSeconds: 35,
    repetitions: 3,
    imagePath: 'assets/images/trainings/moro/moro4.png',
    videoPath: 'moro/moro_4.mp4', // placeholder video
  ),

  // Exercise 4 of 7 — Moro 1
  Exercise(
    id: 'moro_ex4',
    packageId: 'moro',
    sequenceNumber: 4,
    titleDe: 'Moro 1',
    titleEn: 'Moro 1',
    positionInstructionsDe: [
      'Rückenlage',
      'Beine zusammen und angewinkelt, Füße am Boden',
      'Arme ausgestreckt neben dem Körper, Handflächen am Boden',
    ],
    positionInstructionsEn: [
      'Lie on your back',
      'Legs together and bent, feet on the floor',
      'Arms extended alongside the body, palms on the floor',
    ],
    movementInstructionsDe: [
      'Knie langsam drei Sekunden nach rechts führen',
      'Drei Sekunden zurück zur Mitte',
      'Knie drei Sekunden nach links führen',
      'Zurück zur Mitte',
      'Drei Durchgänge',
    ],
    movementInstructionsEn: [
      'Slowly lower knees to the right over three seconds',
      'Return to center over three seconds',
      'Lower knees to the left over three seconds',
      'Return to center',
      'Three rounds',
    ],
    hintsDe: [
      'Hüfte bleibt stabil am Boden, ohne sich abzuheben oder mitzudrehen',
      'Bewegung nur so weit, wie die Hüfte neutral bleibt',
    ],
    hintsEn: [
      'Hips remain stable on the floor, not lifting or rotating',
      'Only move as far as the hips stay neutral',
    ],
    executionGuideDe: 'Knie langsam zur Seite führen. Hüfte bleibt stabil am Boden.',
    executionGuideEn: 'Slowly lower knees to the side. Hips stay stable on the floor.',
    durationSeconds: 45,
    repetitions: 3,
    imagePath: 'assets/images/trainings/moro/moro1.png',
    videoPath: 'moro/moro_1.mp4',
  ),

  // Exercise 5 of 7 — Moro 2
  Exercise(
    id: 'moro_ex5',
    packageId: 'moro',
    sequenceNumber: 5,
    titleDe: 'Moro 2',
    titleEn: 'Moro 2',
    positionInstructionsDe: [
      'Rückenlage',
      'Beine zusammen und angewinkelt, Füße am Boden',
      'Arme ausgestreckt neben dem Körper, Handflächen am Boden',
    ],
    positionInstructionsEn: [
      'Lie on your back',
      'Legs together and bent, feet on the floor',
      'Arms extended alongside the body, palms on the floor',
    ],
    movementInstructionsDe: [
      'Mit dem Ausatmen Kopf und Oberkörper langsam in ca. drei Sekunden anheben',
      'Stirn bewegt sich Richtung Knie',
      'Kurz halten',
      'Langsam wieder ablegen',
    ],
    movementInstructionsEn: [
      'While exhaling, slowly raise the head and upper body over about three seconds',
      'Forehead moves toward the knees',
      'Hold briefly',
      'Slowly lower back down',
    ],
    hintsDe: [
      'Wenn die Rumpfkraft nicht ausreicht: Hände an die Schienbeine legen, Handflächen offen lassen',
      'Arme unterstützen nur leicht, nicht ziehen',
    ],
    hintsEn: [
      'If core strength is insufficient: place hands on the shins, palms open',
      'Arms only support lightly, do not pull',
    ],
    executionGuideDe: 'Kopf und Oberkörper langsam anheben, Stirn Richtung Knie.',
    executionGuideEn: 'Slowly raise head and upper body, forehead toward knees.',
    durationSeconds: 30,
    repetitions: 3,
    imagePath: 'assets/images/trainings/moro/moro2.png',
    videoPath: 'moro/moro_2.mp4',
  ),

  // Exercise 6 of 7 — Moro 6 – Isometrischer Gegendruck
  Exercise(
    id: 'moro_ex6',
    packageId: 'moro',
    sequenceNumber: 6,
    titleDe: 'Moro 6 – Isometrischer Gegendruck',
    titleEn: 'Moro 6 – Isometric Counterpressure',
    positionInstructionsDe: [
      'Rückenlage',
      'Beine angewinkelt',
      'Hände überkreuz auf den Knien oder Schienbeinen',
    ],
    positionInstructionsEn: [
      'Lie on your back',
      'Legs bent',
      'Hands crossed on the knees or shins',
    ],
    movementInstructionsDe: [
      'Leichter Gegendruck: Beine ziehen Richtung Körper, Hände halten dagegen',
      'Kopf leicht anheben',
      'Sieben Sekunden durch den Mund ausatmen',
      'Drei Sekunden Pause',
      'Drei Wiederholungen',
      'Armkreuz wechseln',
      'Drei weitere Wiederholungen',
    ],
    movementInstructionsEn: [
      'Light counterpressure: legs pull toward body, hands push against',
      'Slightly lift the head',
      'Exhale through the mouth for seven seconds',
      'Three seconds rest',
      'Three repetitions',
      'Switch arm cross',
      'Three more repetitions',
    ],
    hintsDe: [
      'Spannung gleichmäßig halten, nicht ruckartig',
    ],
    hintsEn: [
      'Maintain even tension, no jerking',
    ],
    executionGuideDe: 'Gegendruck aufbauen. Sieben Sekunden ausatmen.',
    executionGuideEn: 'Build counterpressure. Exhale for seven seconds.',
    durationSeconds: 90,
    repetitions: 6,
    imagePath: 'assets/images/trainings/moro/moro6.png',
    videoPath: 'moro/moro_6.mp4',
  ),

  // Exercise 7 of 7 — Moro 7 – Überkreuzter Gegendruck
  Exercise(
    id: 'moro_ex7',
    packageId: 'moro',
    sequenceNumber: 7,
    titleDe: 'Moro 7 – Überkreuzter Gegendruck',
    titleEn: 'Moro 7 – Crossed Counterpressure',
    positionInstructionsDe: [
      'Rückenlage',
      'Beine angewinkelt',
      'Hände überkreuz auf Oberschenkeln oder Knien',
    ],
    positionInstructionsEn: [
      'Lie on your back',
      'Legs bent',
      'Hands crossed on the thighs or knees',
    ],
    movementInstructionsDe: [
      'Beine Richtung Körper ziehen',
      'Hände arbeiten dagegen',
      'Kopf leicht zur Brust anheben',
      'Sieben Sekunden ausatmen',
      'Drei Sekunden Pause',
      'Sechs Wiederholungen',
      'Nach drei Wiederholungen Armkreuz wechseln',
    ],
    movementInstructionsEn: [
      'Pull legs toward the body',
      'Hands work against it',
      'Slightly raise head toward chest',
      'Exhale for seven seconds',
      'Three seconds rest',
      'Six repetitions',
      'Switch arm cross after three repetitions',
    ],
    hintsDe: [
      'Bewegung bleibt klein; Fokus auf kontrollierter Spannung',
    ],
    hintsEn: [
      'Movement stays small; focus on controlled tension',
    ],
    executionGuideDe: 'Beine und Hände arbeiten gegeneinander. Sieben Sekunden ausatmen.',
    executionGuideEn: 'Legs and hands work against each other. Exhale for seven seconds.',
    durationSeconds: 90,
    repetitions: 6,
    imagePath: 'assets/images/trainings/moro/moro7.png',
    videoPath: 'moro/moro_7.mp4',
  ),
];
