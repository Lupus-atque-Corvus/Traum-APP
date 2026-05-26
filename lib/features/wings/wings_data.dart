import 'package:flutter/material.dart';

enum WingsDifficulty {
  lowBeginner,
  highBeginner,
  lowIntermediate,
  highIntermediate,
  elite,
}

enum WingsCategory {
  verticalPull,
  horizontalPull,
  horizontalPush,
  verticalPush,
  legs,
  core,
}

class WingsExercise {
  final String id;
  final String name;
  final WingsDifficulty difficulty;
  final WingsCategory category;
  final String muscles;
  final String description;
  final List<String> instructions;
  final List<String> goodForm;
  final List<String> badForm;
  final bool hasDetail;

  const WingsExercise({
    required this.id,
    required this.name,
    required this.difficulty,
    required this.category,
    required this.muscles,
    required this.description,
    this.instructions = const [],
    this.goodForm = const [],
    this.badForm = const [],
    this.hasDetail = true,
  });
}

class WingsSkillRow {
  final List<String> names;
  const WingsSkillRow(this.names);
}

class WingsSkillCategory {
  final String titleEn;
  final String blurb;
  final WingsCategory category;
  final List<WingsSkillRow> rows;

  const WingsSkillCategory({
    required this.titleEn,
    required this.blurb,
    required this.category,
    required this.rows,
  });
}

const List<WingsExercise> wingsExercises = [
  // ── Vertical Pull ────────────────────────────────────────────
  WingsExercise(
    id: 'deadhang',
    name: 'Deadhang',
    difficulty: WingsDifficulty.lowBeginner,
    category: WingsCategory.verticalPull,
    muscles: 'Lats, Biceps, Forearms, Grip',
    description:
        'The Deadhang is the most basic hanging exercise. It builds grip strength and stretches the shoulders. Hang from a bar with both hands in a fully extended position.',
    instructions: [
      'Grab a bar with hands shoulder-width apart.',
      'Let your body hang with arms fully extended.',
      'Relax your body and hold the position.',
      'Build up to 30–60 second holds.',
    ],
    goodForm: ['Body is hanging', 'Arms are straight', 'Hands placed shoulder-width apart'],
    badForm: ['Arms bent'],
  ),
  WingsExercise(
    id: 'activehang',
    name: 'Active Hang',
    difficulty: WingsDifficulty.lowBeginner,
    category: WingsCategory.verticalPull,
    muscles: 'Lats, Scapular muscles, Upper back',
    description:
        'The Active Hang builds scapular strength and body tension. Depress and retract your scapula while hanging from the bar without bending the arms.',
    instructions: [
      'Start in a deadhang position.',
      'Without bending the arms, depress and retract your scapula (pull shoulder blades down and together).',
      'Hold this position for 5–10 seconds.',
      'This is the base for all pulling exercises.',
    ],
    goodForm: ['Scapula is depressed', 'Upper back and scapula is engaged', 'Body is hanging'],
    badForm: ['Body is relaxed', 'Elevated Scapula', 'Scapula is not engaged'],
  ),
  WingsExercise(
    id: 'assistpullup',
    name: 'Assisted Pull-up',
    difficulty: WingsDifficulty.lowBeginner,
    category: WingsCategory.verticalPull,
    muscles: 'Lats, Biceps',
    description:
        'Regression for the Pull-up. Use leg/ground assistance or resistance bands to reduce the load. Great for building pulling strength.',
    instructions: [
      'Set up a band on the bar or use a box under your feet.',
      'Grab bar with hands shoulder-width apart.',
      'Pull yourself up, driving elbows downward.',
      'Get chin above bar level, then lower with control.',
      'Use 4–8 reps for strength, 8–12 for volume.',
    ],
    goodForm: ['Elbows drive downward', 'Chin gets above bar', 'Hands placed shoulder-width apart'],
    badForm: ['Bent body'],
  ),
  WingsExercise(
    id: 'pullup',
    name: 'Pull-up',
    difficulty: WingsDifficulty.lowBeginner,
    category: WingsCategory.verticalPull,
    muscles: 'Lats, Biceps, Rear Deltoids',
    description:
        'The most fundamental vertical pulling exercise. Hang from a bar and pull yourself up until your chin clears the bar, then lower with control.',
    instructions: [
      'Start in a deadhang with hands shoulder-width apart.',
      'Engage scapula (active hang position).',
      'Pull yourself up, driving elbows downward and toward your hips.',
      'Get your chin above bar height.',
      'Lower slowly back to full extension.',
    ],
    goodForm: [
      'Elbows drive downward',
      'Chin gets above bar',
      'Hands placed shoulder-width apart',
      'Full range of motion',
    ],
    badForm: ['Bent body', 'Half reps', 'Arms pulling on neck/head'],
  ),
  WingsExercise(
    id: 'scapulapullup',
    name: 'Scapula Pull-up',
    difficulty: WingsDifficulty.lowBeginner,
    category: WingsCategory.verticalPull,
    muscles: 'Scapular muscles, Lats',
    description:
        'Trains scapular depression and retraction – critical for advanced pulling skills. From a dead hang, move scapula without bending elbows.',
    instructions: [
      'Start in a deadhang with straight arms.',
      'Without bending elbows, pull your scapula down and back.',
      'Your body rises slightly.',
      'Hold for 1–2 seconds, then slowly release.',
    ],
    goodForm: ['Arms are straight', 'Scapula is retracted and depressed', 'Body is hanging'],
    badForm: ['Bent elbows', 'Weak/disengaged scapula'],
  ),
  WingsExercise(
    id: 'chestpullup',
    name: 'Chest Pull-up',
    difficulty: WingsDifficulty.lowIntermediate,
    category: WingsCategory.verticalPull,
    muscles: 'Lats, Biceps, Rear Deltoids',
    description:
        'An advanced pull-up where you pull until your chest touches the bar. Builds explosive pulling strength for the muscle-up.',
    goodForm: ['Chest gets to or above bar level', 'Elbows drive downward'],
    badForm: ['Half reps'],
  ),
  WingsExercise(
    id: 'waistpullup',
    name: 'Waist Pull-up',
    difficulty: WingsDifficulty.lowIntermediate,
    category: WingsCategory.verticalPull,
    muscles: 'Lats, Biceps',
    description: 'A pull-up variation where you pull until your waist reaches bar height. Advanced strength builder.',
    goodForm: ['Waist gets to or above bar level'],
    badForm: ['Half reps'],
  ),
  WingsExercise(
    id: 'muscleup',
    name: 'Muscle-Up',
    difficulty: WingsDifficulty.highBeginner,
    category: WingsCategory.verticalPull,
    muscles: 'Lats, Triceps, Chest, Biceps',
    description:
        'The Muscle-Up transitions from a pull to a push above the bar. Requires explosive pulling power and a smooth transition.',
    instructions: [
      'Start with a strong explosive pull.',
      'Pull aiming chest to bar.',
      'As chest passes bar, transition by pushing elbows up and forward.',
      'Press to full lockout above bar.',
    ],
    goodForm: ['Body gets over bar', 'Pull is timed with the swing backward', 'Chest gets to or above bar level'],
    badForm: ['Pulling to the bar instead of around', 'Incomplete range of motion'],
  ),
  WingsExercise(
    id: 'archerpullup',
    name: 'Archer Pull-up',
    difficulty: WingsDifficulty.lowIntermediate,
    category: WingsCategory.verticalPull,
    muscles: 'Lats, Biceps',
    description: 'One arm does most of the pulling while the other assists, building single-arm strength.',
    goodForm: ['Chin gets above bar', 'Full range of motion'],
    badForm: [],
    hasDetail: false,
  ),
  WingsExercise(
    id: 'weightedpullup',
    name: 'Weighted Pull-ups',
    difficulty: WingsDifficulty.lowIntermediate,
    category: WingsCategory.verticalPull,
    muscles: 'Lats, Biceps, Rear Deltoids',
    description: 'Pull-ups with added weight via belt or vest. Builds raw pulling strength for advanced skills.',
    goodForm: ['Full range of motion', 'Chin gets above bar'],
    badForm: ['Half reps'],
    hasDetail: false,
  ),

  // ── Horizontal Pull (Front Lever) ──────────────────────────
  WingsExercise(
    id: 'assistedinvrow',
    name: 'Assisted Inverted Row',
    difficulty: WingsDifficulty.lowBeginner,
    category: WingsCategory.horizontalPull,
    muscles: 'Lats, Rear Deltoids, Biceps',
    description: 'Beginner horizontal pulling under a low bar with feet on ground to reduce load.',
    instructions: [
      'Set a bar at hip height.',
      'Hang under the bar with hands shoulder-width apart.',
      'Pull chest to bar while keeping body straight.',
      'Use legs to assist as needed.',
    ],
    goodForm: ['Body is mostly flat', 'Scapula is retracted and depressed', 'Chest gets to or above bar level'],
    badForm: ['Sagging hips'],
  ),
  WingsExercise(
    id: 'invertedrow',
    name: 'Inverted Row',
    difficulty: WingsDifficulty.lowBeginner,
    category: WingsCategory.horizontalPull,
    muscles: 'Lats, Rear Deltoids, Biceps',
    description: 'Full body horizontal pull. Feet elevated or on ground. Great foundation for Front Lever.',
    goodForm: ['Body is flat and parallel to the ground', 'Chest gets to or above bar level', 'Scapula is retracted and depressed'],
    badForm: ['Sagging hips', 'Incomplete range of motion'],
  ),
  WingsExercise(
    id: 'tuckfl',
    name: 'Tuck Front Lever',
    difficulty: WingsDifficulty.highBeginner,
    category: WingsCategory.horizontalPull,
    muscles: 'Lats, Core, Rear Deltoids',
    description: 'First true Front Lever progression. Knees tucked to chest, body parallel to ground.',
    instructions: [
      'Hang from bar with straight arms.',
      'Raise knees to chest.',
      'Depress and retract scapula.',
      'Pull body up until parallel to ground.',
      'Hold for 5–10 seconds.',
    ],
    goodForm: [
      'Body is flat and parallel to the ground',
      'Core is compressed',
      'Scapula is protracted and depressed',
      'Knees tucked to chest',
    ],
    badForm: ['Sagging hips', 'Knees not fully tucked', 'Weak/disengaged scapula'],
  ),
  WingsExercise(
    id: 'tuckflrow',
    name: 'Tuck FL Row',
    difficulty: WingsDifficulty.highBeginner,
    category: WingsCategory.horizontalPull,
    muscles: 'Lats, Core, Biceps',
    description: 'Dynamic Tuck Front Lever – pull from tuck FL position. Builds horizontal pulling strength.',
    goodForm: ['Body is flat and parallel to the ground', 'Slow and controlled movement'],
    badForm: ['Sagging hips'],
  ),
  WingsExercise(
    id: 'pikefl',
    name: 'Pike Front Lever',
    difficulty: WingsDifficulty.highBeginner,
    category: WingsCategory.horizontalPull,
    muscles: 'Lats, Core, Hip Flexors',
    description: 'Front Lever with legs in pike (90°) position. Harder than tuck, easier than straddle.',
    goodForm: ['Body in a pike (90 degree) position', 'Body is flat and parallel to the ground'],
    badForm: ['Sagging hips'],
  ),
  WingsExercise(
    id: 'advtuckfl',
    name: 'Adv. Tuck Front Lever',
    difficulty: WingsDifficulty.lowIntermediate,
    category: WingsCategory.horizontalPull,
    muscles: 'Lats, Core, Rear Deltoids',
    description: 'Advanced Tuck FL with knees extended further from chest. Bridges tuck and straddle.',
    goodForm: ['Body is flat and parallel to the ground', 'Core is compressed'],
    badForm: ['Sagging hips'],
  ),
  WingsExercise(
    id: 'straddlefl',
    name: 'Straddle Front Lever',
    difficulty: WingsDifficulty.lowIntermediate,
    category: WingsCategory.horizontalPull,
    muscles: 'Lats, Core, Rear Deltoids',
    description: 'Front Lever with legs spread wide. Reduces lever arm compared to full FL.',
    goodForm: ['Body is flat and parallel to the ground', 'Legs are straight', 'Scapula is protracted and depressed'],
    badForm: ['Sagging hips', 'Arched back'],
  ),
  WingsExercise(
    id: 'halflayfl',
    name: 'Half Lay Front Lever',
    difficulty: WingsDifficulty.highIntermediate,
    category: WingsCategory.horizontalPull,
    muscles: 'Lats, Core, Rear Deltoids',
    description: 'Front Lever with one leg extended and one knee bent. Final step before full FL.',
    goodForm: ['Body is flat and parallel to the ground', 'Legs are mostly straight'],
    badForm: ['Sagging hips', 'Arched back'],
  ),
  WingsExercise(
    id: 'fullfl',
    name: 'Full Front Lever',
    difficulty: WingsDifficulty.highIntermediate,
    category: WingsCategory.horizontalPull,
    muscles: 'Lats, Core, Rear Deltoids, Biceps',
    description:
        'Body held perfectly parallel to the ground with legs fully extended and together. One of the pinnacle calisthenics skills.',
    goodForm: [
      'Body is flat and parallel to the ground',
      'Legs are straight',
      'Scapula is protracted and depressed',
      'Arms are straight',
    ],
    badForm: ['Sagging hips', 'Arched back', 'Legs are bent'],
  ),

  // ── Horizontal Push (Planche) ─────────────────────────────
  WingsExercise(
    id: 'assistedpushup',
    name: 'Assisted Push-up',
    difficulty: WingsDifficulty.lowBeginner,
    category: WingsCategory.horizontalPush,
    muscles: 'Chest, Triceps',
    description: 'Knee or incline push-up for beginners. Reduces load while learning the movement pattern.',
    goodForm: ['Body forms a straight line', 'Chest touches the floor'],
    badForm: ['Sagging hips'],
  ),
  WingsExercise(
    id: 'pushup',
    name: 'Push-up',
    difficulty: WingsDifficulty.lowBeginner,
    category: WingsCategory.horizontalPush,
    muscles: 'Chest, Triceps, Shoulders',
    description: 'Foundational horizontal push. Lower from plank until chest touches floor, then push back up.',
    instructions: [
      'Start in plank with hands shoulder-width apart.',
      'Lower your body until chest touches the floor.',
      'Keep elbows close to body (not flared).',
      'Push back up to full lockout.',
    ],
    goodForm: ['Body forms a straight line', 'Chest touches the floor', 'Full range of motion', 'Elbows close to body'],
    badForm: ['Sagging hips', 'Flared elbows', 'Half reps'],
  ),
  WingsExercise(
    id: 'dip',
    name: 'Dip',
    difficulty: WingsDifficulty.lowBeginner,
    category: WingsCategory.horizontalPush,
    muscles: 'Triceps, Chest, Shoulders',
    description: 'Dips on parallel bars. Lower until elbows reach 90°, then push back up.',
    instructions: [
      'Mount parallel bars, arms fully extended.',
      'Lower body by bending elbows to 90°.',
      'Keep body upright for tricep focus.',
      'Press back to lockout.',
    ],
    goodForm: ['Elbows bend to around 90 degrees', 'Hands shoulder-width apart', 'Full range of motion'],
    badForm: ['Elbows not fully bent', 'Incomplete range of motion'],
  ),
  WingsExercise(
    id: 'elbowlever',
    name: 'Elbow Lever',
    difficulty: WingsDifficulty.lowBeginner,
    category: WingsCategory.horizontalPush,
    muscles: 'Core, Triceps, Wrists',
    description: 'Balance skill where body is supported horizontally on bent elbows pressed into the abdomen.',
    instructions: [
      'Place hands on floor, dig elbows into abs.',
      'Lean forward and lift feet off the ground.',
      'Keep body straight and parallel to floor.',
    ],
    goodForm: ['Elbows are jammed into the abs', 'Body is mostly flat', 'Arms are relatively straight'],
    badForm: ['Body touching floor'],
  ),
  WingsExercise(
    id: 'planchelean',
    name: 'Planche Lean',
    difficulty: WingsDifficulty.lowBeginner,
    category: WingsCategory.horizontalPush,
    muscles: 'Shoulders, Wrists, Core',
    description: 'Lean forward in push-up top position until shoulders are over or past hands. Conditions shoulders for planche.',
    instructions: [
      'In push-up top position with fingers pointing out at 45°.',
      'Shift body forward until shoulders pass over wrists.',
      'Hold for 10–30 seconds.',
    ],
    goodForm: ['Hands turned at a 45 degree angle', 'Body forms a straight line', 'Arms are straight'],
    badForm: ['Bent elbows'],
  ),
  WingsExercise(
    id: 'pseudopu',
    name: 'Pseudo Push-up',
    difficulty: WingsDifficulty.lowBeginner,
    category: WingsCategory.horizontalPush,
    muscles: 'Shoulders, Triceps, Core',
    description: 'Push-up with hands at hip level and fingers pointing back. Builds planche-specific shoulder strength.',
    goodForm: ['Arms are behind the hips', 'Body forms a straight line'],
    badForm: ['Bent elbows'],
  ),
  WingsExercise(
    id: 'tuckpl',
    name: 'Tuck Planche',
    difficulty: WingsDifficulty.highBeginner,
    category: WingsCategory.horizontalPush,
    muscles: 'Shoulders, Triceps, Core, Wrists',
    description: 'First true planche hold. Hips over hands with knees tucked tightly to chest.',
    instructions: [
      'Place hands on floor, fingers at 45°.',
      'Lean forward and tuck knees to chest.',
      'Push down into floor with straight arms.',
      'Hold body parallel to ground.',
    ],
    goodForm: ['Arms are straight', 'Scapula is protracted and depressed', 'Knees tucked to chest'],
    badForm: ['Arms bent', 'High or low hips', 'Weak/protracted scapula'],
  ),
  WingsExercise(
    id: 'straddlepl',
    name: 'Straddle Planche',
    difficulty: WingsDifficulty.highIntermediate,
    category: WingsCategory.horizontalPush,
    muscles: 'Shoulders, Triceps, Core',
    description: 'Planche with legs spread wide. Body parallel to ground with full straight arms.',
    goodForm: ['Arms are straight', 'Body is flat and parallel to the ground', 'Legs are straight'],
    badForm: ['Arms bent', 'Sagging hips'],
  ),
  WingsExercise(
    id: 'fullplanche',
    name: 'Full Planche',
    difficulty: WingsDifficulty.elite,
    category: WingsCategory.horizontalPush,
    muscles: 'Shoulders, Triceps, Core, Lats',
    description:
        'Body held parallel to the ground on straight arms with legs together. One of the hardest calisthenics skills.',
    goodForm: ['Arms are straight', 'Body is flat and parallel to the ground', 'Legs are straight and fully extended'],
    badForm: ['Arms bent', 'Sagging hips', 'Legs are bent'],
  ),

  // ── Vertical Push (Handstand/HSPU) ────────────────────────
  WingsExercise(
    id: 'pikepu',
    name: 'Pike Push-up',
    difficulty: WingsDifficulty.lowBeginner,
    category: WingsCategory.verticalPush,
    muscles: 'Shoulders, Triceps',
    description: 'Pike position push-up targeting shoulders. First step toward handstand push-ups.',
    instructions: [
      'Form an inverted V with hips high in the air.',
      'Lower head toward floor by bending elbows.',
      'Head comes close to or touches the floor.',
      'Push back up to start.',
    ],
    goodForm: ['Body in a pike position', 'Head is close to or touching the floor', 'Elbows bend to about 90 degrees'],
    badForm: ['High or low hips'],
  ),
  WingsExercise(
    id: 'crowpose',
    name: 'Crow Pose',
    difficulty: WingsDifficulty.lowBeginner,
    category: WingsCategory.verticalPush,
    muscles: 'Shoulders, Core, Wrists',
    description: 'Balance skill where knees rest on bent elbows. Entry to handbalancing.',
    instructions: [
      'Squat down, place hands shoulder-width on floor.',
      'Bend elbows slightly, place knees on upper arms.',
      'Lean forward and lift feet off ground.',
      'Find balance point.',
    ],
    goodForm: ['Knees resting on bent elbows', 'Hands placed shoulder-width apart'],
    badForm: ['Feet touching the ground'],
  ),
  WingsExercise(
    id: 'assistedhs',
    name: 'Assisted Handstand',
    difficulty: WingsDifficulty.lowBeginner,
    category: WingsCategory.verticalPush,
    muscles: 'Shoulders, Core, Wrists',
    description: 'Handstand with wall support or partner help. Builds inverted strength and proprioception.',
    goodForm: ['Body is stacked in a straight line', 'Arms are straight', 'Look between your hands'],
    badForm: ['Bent arms or legs', 'Arched/bent body'],
  ),
  WingsExercise(
    id: 'handstand',
    name: 'Handstand',
    difficulty: WingsDifficulty.highBeginner,
    category: WingsCategory.verticalPush,
    muscles: 'Shoulders, Core, Wrists, Forearms',
    description: 'Freestanding handstand balance. Foundation of all vertical push training.',
    instructions: [
      'Kick up to handstand from lunge position.',
      'Stack shoulders over wrists, hips over shoulders.',
      'Engage core in hollow body position.',
      'Balance using fingertips and heel of palm.',
      'Remember to breathe even when upside down.',
    ],
    goodForm: [
      'Arms are straight',
      'Body is stacked in a straight line',
      'Legs point straight up',
      'Using fingers and heel of hand to balance',
    ],
    badForm: ['Bent arms or legs', 'Arched/bent body', 'Not using fingers and heel of hand'],
  ),
  WingsExercise(
    id: 'elevatedpikepu',
    name: 'Elevated Pike PU',
    difficulty: WingsDifficulty.highBeginner,
    category: WingsCategory.verticalPush,
    muscles: 'Shoulders, Triceps',
    description: 'Pike push-up with feet elevated on a box or bench. More shoulder loading than flat pike push-up.',
    goodForm: ['Body in a pike position', 'Head is close to or touching the floor'],
    badForm: ['High or low hips'],
  ),
  WingsExercise(
    id: 'hspu',
    name: 'HSPU',
    difficulty: WingsDifficulty.lowIntermediate,
    category: WingsCategory.verticalPush,
    muscles: 'Shoulders, Triceps, Upper Chest',
    description: 'Handstand Push-up. Lower from handstand until head touches floor, then press back up.',
    goodForm: ['Head is close to or touching the floor', 'Body is stacked in a straight line', 'Full range of motion'],
    badForm: ['Arched back'],
  ),

  // ── Legs ─────────────────────────────────────────────────
  WingsExercise(
    id: 'squat',
    name: 'Bodyweight Squat',
    difficulty: WingsDifficulty.lowBeginner,
    category: WingsCategory.legs,
    muscles: 'Quads, Glutes, Hamstrings',
    description: 'Foundation of leg training. Feet shoulder-width, squat until thighs parallel to ground.',
    instructions: [
      'Stand with feet shoulder-width apart, slightly turned out.',
      'Squat down keeping chest up and knees over toes.',
      'Get thighs parallel to the ground or lower.',
      'Push through heels to stand.',
    ],
    goodForm: ['Feet are flat on the ground', 'Knees remain over the toes', 'Full range of motion'],
    badForm: ['Toes or heels lifting off the ground', 'Knees caving inward'],
  ),
  WingsExercise(
    id: 'splitsquat',
    name: 'Split Squat',
    difficulty: WingsDifficulty.lowBeginner,
    category: WingsCategory.legs,
    muscles: 'Quads, Glutes',
    description: 'Lunge-style squat with both feet on ground. Progression toward single-leg movements.',
    goodForm: ['Knees remain over the toes', 'Feet are flat on the ground'],
    badForm: ['Knees pointing inward'],
  ),
  WingsExercise(
    id: 'reversenordiccurl',
    name: 'Reverse Nordic Curl',
    difficulty: WingsDifficulty.lowBeginner,
    category: WingsCategory.legs,
    muscles: 'Quads',
    description: 'Knee flexion exercise targeting quads. Kneel upright, lean backward under control.',
    goodForm: ['Body forms a straight line', 'Controlled descent'],
    badForm: [],
  ),
  WingsExercise(
    id: 'nordiccurl',
    name: 'Nordic Curl',
    difficulty: WingsDifficulty.lowIntermediate,
    category: WingsCategory.legs,
    muscles: 'Hamstrings',
    description: 'Advanced hamstring exercise. Knees on floor, lower body forward using hamstrings.',
    goodForm: ['Body forms a straight line', 'Controlled descent'],
    badForm: [],
  ),
  WingsExercise(
    id: 'sissysquat',
    name: 'Sissy Squat',
    difficulty: WingsDifficulty.lowIntermediate,
    category: WingsCategory.legs,
    muscles: 'Quads',
    description: 'Extreme quad stretch squat. Lean back while squatting with knees forward.',
    goodForm: ['Full range of motion', 'Knees remain over the toes'],
    badForm: [],
    hasDetail: false,
  ),
  WingsExercise(
    id: 'pistolsquat',
    name: 'Pistol Squat',
    difficulty: WingsDifficulty.highBeginner,
    category: WingsCategory.legs,
    muscles: 'Quads, Glutes, Hamstrings, Core',
    description: 'Single-leg squat with free leg extended forward. Pinnacle bodyweight leg exercise.',
    instructions: [
      'Stand on one leg, extend the other forward.',
      'Squat down on the standing leg to full depth.',
      'Keep chest up and knee over toes.',
      'Drive through heel to stand back up.',
    ],
    goodForm: ['Knees remain over the toes', 'Feet are flat on the ground', 'Full range of motion'],
    badForm: ['Toes or heels lifting off the ground', 'Weight shifting excessively forward or back'],
  ),
  WingsExercise(
    id: 'shrimpquat',
    name: 'Shrimp Squat',
    difficulty: WingsDifficulty.highBeginner,
    category: WingsCategory.legs,
    muscles: 'Quads, Glutes',
    description: 'Single-leg squat with rear leg bent behind and held with hand. Requires balance and quad strength.',
    goodForm: ['Full range of motion', 'Knees remain over the toes'],
    badForm: [],
    hasDetail: false,
  ),

  // ── Core ─────────────────────────────────────────────────
  WingsExercise(
    id: 'situp',
    name: 'Sit-up',
    difficulty: WingsDifficulty.lowBeginner,
    category: WingsCategory.core,
    muscles: 'Abs, Hip Flexors',
    description: 'Basic core exercise. Lie on back with knees bent, curl torso up toward knees.',
    goodForm: ['Full range of motion', 'Core is engaged'],
    badForm: ['Pulling on neck/head'],
  ),
  WingsExercise(
    id: 'hollowbody',
    name: 'Hollow Body Hold',
    difficulty: WingsDifficulty.lowBeginner,
    category: WingsCategory.core,
    muscles: 'Core, Hip Flexors, Abs',
    description:
        'Fundamental core position in calisthenics. Lie on back, press lower back into ground, extend arms and legs.',
    instructions: [
      'Lie on your back.',
      'Press lower back firmly into the ground.',
      'Extend arms overhead and legs out.',
      'Raise arms and legs off the ground slightly.',
      'Hold – maintain lower back contact with floor.',
    ],
    goodForm: ['Lower back is pressed against the ground', 'Body forms a straight line', 'Core is engaged'],
    badForm: ['Lower back lifting off the ground', 'Weak core', 'Body not engaged'],
  ),
  WingsExercise(
    id: 'lsitcompression',
    name: 'L-sit Compression',
    difficulty: WingsDifficulty.lowBeginner,
    category: WingsCategory.core,
    muscles: 'Hip Flexors, Core',
    description: 'Seated compression training for L-sit. Sit on floor and pull legs up without using hands.',
    goodForm: ['Legs are together out in front', 'Core is engaged'],
    badForm: ['Legs are bent'],
  ),
  WingsExercise(
    id: 'lsit',
    name: 'L-sit',
    difficulty: WingsDifficulty.lowBeginner,
    category: WingsCategory.core,
    muscles: 'Hip Flexors, Core, Triceps',
    description: 'Hold body in L-shape while supported on hands. Legs parallel to ground, arms straight.',
    instructions: [
      'Sit on floor with legs extended.',
      'Place hands beside hips and push down.',
      'Lift hips and legs off the ground.',
      'Keep arms straight and legs together.',
    ],
    goodForm: ['Legs are together out in front', 'Arms are straight', 'Body is stacked in a straight line'],
    badForm: ['Legs are bent', 'Sagging hips', 'Arms bent'],
  ),
  WingsExercise(
    id: 'dragonflag',
    name: 'Dragon Flag',
    difficulty: WingsDifficulty.lowIntermediate,
    category: WingsCategory.core,
    muscles: 'Core, Abs, Hip Flexors, Lats',
    description:
        'Advanced core exercise. Body lowered toward ground pivoting only at shoulders, everything else stays rigid.',
    instructions: [
      'Lie on bench, grip overhead support.',
      'Raise body to shoulder stand.',
      'Lower body slowly as one straight unit.',
      'Stop before legs touch the bench.',
      'Raise back up with full body tension.',
    ],
    goodForm: ['Body forms a straight line', 'Core is engaged', 'Legs are straight', 'Slow and controlled movement'],
    badForm: ['Sagging hips', 'Bent body', 'Weak core'],
  ),
];

// Skill tree structure (names only – includes "in progress" ones not in wingsExercises)
const List<WingsSkillCategory> wingsSkillCategories = [
  WingsSkillCategory(
    titleEn: 'Vertical Pull',
    blurb:
        'Vertical pull involves exercises with your body perpendicular to the ground. Targets lats, biceps, and rear deltoids.',
    category: WingsCategory.verticalPull,
    rows: [
      WingsSkillRow(['Deadhang', 'Active Hang', 'Assisted Pull-up', 'Pull-up', 'Scapula Pull-up']),
      WingsSkillRow(['Chest Pull-up', 'Waist Pull-up', 'Muscle-Up', 'Archer Pull-up', 'Clean Muscle-Up']),
      WingsSkillRow(['Assisted OAC', 'Assisted OAP', 'OAC/OAP', 'Weighted Pull-ups', 'Butterfly']),
    ],
  ),
  WingsSkillCategory(
    titleEn: 'Horizontal Pull',
    blurb:
        'Horizontal pull involves exercises with your body parallel to the ground. Targets lats, triceps, and rear deltoids.',
    category: WingsCategory.horizontalPull,
    rows: [
      WingsSkillRow(['Assisted Inverted Row', 'Inverted Row', 'Tuck FL', 'Tuck FL Row', 'Pike FL']),
      WingsSkillRow(['Pike FL Row', 'Adv. Tuck FL', 'Super Adv. Tuck FL', 'Adv. Tuck FL Row', 'Straddle FL']),
      WingsSkillRow(['Straddle FL Row', 'Half Lay FL', 'Full Front Lever', 'Full FL Row', 'Front Lever Touch']),
    ],
  ),
  WingsSkillCategory(
    titleEn: 'Horizontal Push',
    blurb:
        'Horizontal push involves push exercises with your body parallel to the ground. Targets shoulders, arms, and chest.',
    category: WingsCategory.horizontalPush,
    rows: [
      WingsSkillRow(['Assisted Push-up', 'Push-up', 'Dip', 'Elbow Lever', 'Planche Lean']),
      WingsSkillRow(['Pseudo Push-up', 'Tuck Planche', 'Tuck Planche PU', 'Adv. Tuck Planche', 'Adv. Tuck Planche PU']),
      WingsSkillRow(['90 Degree Hold', 'Back Lever', 'Super Adv. Tuck PL', 'Straddle Planche', 'Straddle Planche PU']),
      WingsSkillRow(['Half Lay Planche', 'Full Planche', 'Full Planche PU', 'One Arm Planche', 'Maltese']),
    ],
  ),
  WingsSkillCategory(
    titleEn: 'Vertical Push',
    blurb:
        'Vertical push involves exercises with your body perpendicular to the ground (handstand). Targets shoulders, triceps, and upper chest.',
    category: WingsCategory.verticalPush,
    rows: [
      WingsSkillRow(['Pike Push-up', 'Crow Pose', 'Assisted Handstand', 'Handstand', 'Elevated Pike PU']),
      WingsSkillRow(['Bent Arm Press to HS', 'Straight Arm Press to HS', 'Bent Arm Stand', 'Assisted HSPU', 'HSPU']),
      WingsSkillRow(['Deep HSPU', '90 Degree PU', 'Assisted OAHS', 'OAHS', 'OA Flag']),
    ],
  ),
  WingsSkillCategory(
    titleEn: 'Legs',
    blurb: 'Leg training for strength and mobility. Bodyweight squats, single-leg movements, and posterior chain work.',
    category: WingsCategory.legs,
    rows: [
      WingsSkillRow(['Bodyweight Squat', 'Split Squat', 'Reverse Nordic Curl', 'Nordic Curl', 'Sissy Squat']),
      WingsSkillRow(['Assisted Pistol Squat', 'Bulgarian Split Squat', 'Pistol Squat', 'Shrimp Squat', 'Dragon Pistol Squat']),
    ],
  ),
  WingsSkillCategory(
    titleEn: 'Core',
    blurb:
        'Core strength is fundamental to all calisthenics skills. These exercises build the tension and compression needed for advanced holds.',
    category: WingsCategory.core,
    rows: [
      WingsSkillRow(['Sit-up', 'Hollow Body Hold', 'L-sit Compression', 'L-sit', 'Dragon Flag']),
      WingsSkillRow(['V-sit', 'I-sit', 'Manna', 'Human Flag', 'Victorian']),
    ],
  ),
];

// Map exercise display name → WingsExercise id
const Map<String, String> _nameToId = {
  'Deadhang': 'deadhang',
  'Active Hang': 'activehang',
  'Assisted Pull-up': 'assistpullup',
  'Pull-up': 'pullup',
  'Scapula Pull-up': 'scapulapullup',
  'Chest Pull-up': 'chestpullup',
  'Waist Pull-up': 'waistpullup',
  'Muscle-Up': 'muscleup',
  'Archer Pull-up': 'archerpullup',
  'Weighted Pull-ups': 'weightedpullup',
  'Assisted Inverted Row': 'assistedinvrow',
  'Inverted Row': 'invertedrow',
  'Tuck FL': 'tuckfl',
  'Tuck FL Row': 'tuckflrow',
  'Pike FL': 'pikefl',
  'Adv. Tuck FL': 'advtuckfl',
  'Straddle FL': 'straddlefl',
  'Half Lay FL': 'halflayfl',
  'Full Front Lever': 'fullfl',
  'Assisted Push-up': 'assistedpushup',
  'Push-up': 'pushup',
  'Dip': 'dip',
  'Elbow Lever': 'elbowlever',
  'Planche Lean': 'planchelean',
  'Pseudo Push-up': 'pseudopu',
  'Tuck Planche': 'tuckpl',
  'Straddle Planche': 'straddlepl',
  'Full Planche': 'fullplanche',
  'Pike Push-up': 'pikepu',
  'Crow Pose': 'crowpose',
  'Assisted Handstand': 'assistedhs',
  'Handstand': 'handstand',
  'Elevated Pike PU': 'elevatedpikepu',
  'HSPU': 'hspu',
  'Bodyweight Squat': 'squat',
  'Split Squat': 'splitsquat',
  'Reverse Nordic Curl': 'reversenordiccurl',
  'Nordic Curl': 'nordiccurl',
  'Sissy Squat': 'sissysquat',
  'Pistol Squat': 'pistolsquat',
  'Shrimp Squat': 'shrimpquat',
  'Sit-up': 'situp',
  'Hollow Body Hold': 'hollowbody',
  'L-sit Compression': 'lsitcompression',
  'L-sit': 'lsit',
  'Dragon Flag': 'dragonflag',
};

WingsExercise? findExerciseByName(String name) {
  final id = _nameToId[name];
  if (id == null) return null;
  try {
    return wingsExercises.firstWhere((e) => e.id == id);
  } catch (_) {
    return null;
  }
}

WingsExercise? findExerciseById(String id) {
  try {
    return wingsExercises.firstWhere((e) => e.id == id);
  } catch (_) {
    return null;
  }
}

String difficultyLabel(WingsDifficulty d) {
  switch (d) {
    case WingsDifficulty.lowBeginner:
      return 'Low Beginner';
    case WingsDifficulty.highBeginner:
      return 'High Beginner';
    case WingsDifficulty.lowIntermediate:
      return 'Low Intermediate';
    case WingsDifficulty.highIntermediate:
      return 'High Intermediate';
    case WingsDifficulty.elite:
      return 'Elite';
  }
}

Color difficultyColor(WingsDifficulty d) {
  switch (d) {
    case WingsDifficulty.lowBeginner:
      return const Color(0xFF3DD68C);
    case WingsDifficulty.highBeginner:
      return const Color(0xFF00D4D4);
    case WingsDifficulty.lowIntermediate:
      return const Color(0xFFF5A623);
    case WingsDifficulty.highIntermediate:
      return const Color(0xFFFF6B3D);
    case WingsDifficulty.elite:
      return const Color(0xFFF43F5E);
  }
}

String categoryLabel(WingsCategory c) {
  switch (c) {
    case WingsCategory.horizontalPush:
      return 'Horizontal Push';
    case WingsCategory.verticalPush:
      return 'Vertical Push';
    case WingsCategory.horizontalPull:
      return 'Horizontal Pull';
    case WingsCategory.verticalPull:
      return 'Vertical Pull';
    case WingsCategory.legs:
      return 'Legs';
    case WingsCategory.core:
      return 'Core';
  }
}

IconData categoryIcon(WingsCategory c) {
  switch (c) {
    case WingsCategory.verticalPull:
      return Icons.arrow_upward;
    case WingsCategory.horizontalPull:
      return Icons.arrow_back;
    case WingsCategory.horizontalPush:
      return Icons.arrow_forward;
    case WingsCategory.verticalPush:
      return Icons.arrow_downward;
    case WingsCategory.legs:
      return Icons.directions_walk;
    case WingsCategory.core:
      return Icons.fitness_center;
  }
}
