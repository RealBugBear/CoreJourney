class Exercise {
  final String id;
  final int exerciseNumber;
  final String title;
  
  // Instructional content
  final List<String> positionInstructions;  // Position/Ausgangsposition
  final List<String> movementInstructions;  // Bewegung
  final List<String>? hints;                // Hinweise
  
  // Exercise execution
  final int durationSeconds;
  final int repetitions;         // Anzahl der Wiederholungen (1-5: 3x, 6-7: 6x)
  final String executionGuide;   // Guide text during exercise
  
  // Media
  final String imagePath;        // Path to exercise image
  final String? audioUrl;
  final String? videoUrl;

  const Exercise({
    required this.id,
    required this.exerciseNumber,
    required this.title,
    required this.positionInstructions,
    required this.movementInstructions,
    this.hints,
    required this.durationSeconds,
    required this.repetitions,
    required this.executionGuide,
    required this.imagePath,
    this.audioUrl,
    this.videoUrl,
  });
}

// Complete 7 Moro Exercises
const List<Exercise> exercises = [
  // ÜBUNG 1 – Moro 1
  Exercise(
    id: 'ex1',
    exerciseNumber: 1,
    title: 'Moro 1',
    positionInstructions: [
      'Rückenlage',
      'Beine zusammen und angewinkelt, Füße am Boden',
      'Arme ausgestreckt neben dem Körper, Handflächen am Boden',
    ],
    movementInstructions: [
      'Knie langsam drei Sekunden nach rechts führen',
      'Drei Sekunden zurück zur Mitte',
      'Knie drei Sekunden nach links führen',
      'Zurück zur Mitte',
      'Drei Durchgänge',
    ],
    hints: [
      'Hüfte bleibt stabil am Boden, ohne sich abzuheben oder mitzudrehen',
      'Bewegung nur so weit, wie die Hüfte neutral bleibt',
    ],
    durationSeconds: 45,
    repetitions: 3,
    executionGuide: 'Knie langsam zur Seite führen. Hüfte bleibt stabil am Boden.',
    imagePath: 'assets/images/trainings/moro/moro1.png',
  ),

  // ÜBUNG 2 – Moro 2
  Exercise(
    id: 'ex2',
    exerciseNumber: 2,
    title: 'Moro 2',
    positionInstructions: [
      'Rückenlage',
      'Beine zusammen und angewinkelt, Füße am Boden',
      'Arme ausgestreckt neben dem Körper, Handflächen am Boden',
    ],
    movementInstructions: [
      'Mit dem Ausatmen Kopf und Oberkörper langsam in ca. drei Sekunden anheben',
      'Stirn bewegt sich Richtung Knie',
      'Kurz halten',
      'Langsam wieder ablegen',
    ],
    hints: [
      'Wenn die Rumpfkraft nicht ausreicht: Hände an die Schienbeine legen, Handflächen offen lassen',
      'Arme unterstützen nur leicht, nicht ziehen',
    ],
    durationSeconds: 30,
    repetitions: 3,
    executionGuide: 'Kopf und Oberkörper langsam anheben, Stirn Richtung Knie.',
    imagePath: 'assets/images/trainings/moro/moro2.png',
  ),

  // ÜBUNG 3 – Moro 3 – Halber Frosch
  Exercise(
    id: 'ex3',
    exerciseNumber: 3,
    title: 'Moro 3 – Halber Frosch',
    positionInstructions: [
      'Rückenlage',
      'Beide Beine ausgestreckt',
      'Neutrale Ausgangsposition',
    ],
    movementInstructions: [
      'Ein Bein bewegt sich:',
      'Fußsohle gleitet an der Innenseite des anderen Beins nach oben zum Körper, ca. drei Sekunden',
      'Dann in drei Sekunden wieder vollständig zurück in die neutrale Position',
      'Danach Seitenwechsel',
    ],
    hints: [
      'Fußsohle bleibt während der gesamten Bewegung am anderen Bein anliegend',
      'Bewegungsweite richtet sich nach diesem Kontakt',
    ],
    durationSeconds: 40,
    repetitions: 3,
    executionGuide: 'Fußsohle gleitet am anderen Bein entlang nach oben.',
    imagePath: 'assets/images/trainings/moro/moro3.png',
  ),

  // ÜBUNG 4 – Moro 4 – Frosch
  Exercise(
    id: 'ex4',
    exerciseNumber: 4,
    title: 'Moro 4 – Frosch',
    positionInstructions: [
      'Rückenlage',
      'Beide Beine ausgestreckt',
      'Fußsohlen zusammenführen',
    ],
    movementInstructions: [
      'Füße langsam drei Sekunden Richtung Körper führen',
      'Knie gehen dabei nach außen',
      'Füße anschließend drei Sekunden zurückführen',
    ],
    hints: [
      'Range of Motion nur so weit, wie die Fußsohlen während der gesamten Bewegung eng aneinander bleiben',
    ],
    durationSeconds: 35,
    repetitions: 3,
    executionGuide: 'Füße zum Körper führen, Knie gehen nach außen.',
    imagePath: 'assets/images/trainings/moro/moro4.png',
  ),

  // ÜBUNG 5 – Moro 5
  Exercise(
    id: 'ex5',
    exerciseNumber: 5,
    title: 'Moro 5',
    positionInstructions: [
      'Rückenlage',
      'Beide Beine ausgestreckt',
      'Arme ausgestreckt neben dem Körper, Handflächen am Boden',
    ],
    movementInstructions: [
      'Nur ein Bein bewegt sich',
      'Dieses Bein langsam in ca. drei Sekunden anheben und auf dem Schienbein des anderen Beins ablegen',
      'Kurz halten',
      'In drei Sekunden wieder zurück',
      'Seitenwechsel',
    ],
    hints: [
      'Das nicht bewegte Bein bleibt komplett ruhig und unverändert liegen',
    ],
    durationSeconds: 40,
    repetitions: 3,
    executionGuide: 'Bein anheben und auf dem Schienbein des anderen Beins ablegen.',
    imagePath: 'assets/images/trainings/moro/moro5.png',
  ),

  // ÜBUNG 6 – Moro 6 / 6.1 – Isometrischer Gegendruck
  Exercise(
    id: 'ex6',
    exerciseNumber: 6,
    title: 'Moro 6 – Isometrischer Gegendruck',
    positionInstructions: [
      'Rückenlage',
      'Beine angewinkelt',
      'Hände überkreuz auf den Knien oder Schienbeinen',
    ],
    movementInstructions: [
      'Leichter Gegendruck: Beine ziehen Richtung Körper, Hände halten dagegen',
      'Kopf leicht anheben',
      'Sieben Sekunden durch den Mund ausatmen',
      'Drei Sekunden Pause',
      'Drei Wiederholungen',
      'Armkreuz wechseln',
      'Drei weitere Wiederholungen',
    ],
    hints: [
      'Spannung gleichmäßig halten, nicht ruckartig',
    ],
    durationSeconds: 90,
    repetitions: 6,
    executionGuide: 'Gegendruck aufbauen. Sieben Sekunden ausatmen.',
    imagePath: 'assets/images/trainings/moro/moro6.png',
  ),

  // ÜBUNG 7 – Moro 7 / 7.1 – Überkreuzter Gegendruck
  Exercise(
    id: 'ex7',
    exerciseNumber: 7,
    title: 'Moro 7 – Überkreuzter Gegendruck',
    positionInstructions: [
      'Rückenlage',
      'Beine angewinkelt',
      'Hände überkreuz auf Oberschenkeln oder Knien',
    ],
    movementInstructions: [
      'Beine Richtung Körper ziehen',
      'Hände arbeiten dagegen',
      'Kopf leicht zur Brust anheben',
      'Sieben Sekunden ausatmen',
      'Drei Sekunden Pause',
      'Sechs Wiederholungen',
      'Nach drei Wiederholungen Armkreuz wechseln',
    ],
    hints: [
      'Bewegung bleibt klein; Fokus auf kontrollierter Spannung',
    ],
    durationSeconds: 90,
    repetitions: 6,
    executionGuide: 'Beine und Hände arbeiten gegeneinander. Sieben Sekunden ausatmen.',
    imagePath: 'assets/images/trainings/moro/moro7.png',
  ),
];
