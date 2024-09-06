enum Muscle {
  abdominals(scientificName: 'abdominals'),
  obliques(scientificName: 'obliques'),
  biceps(scientificName: 'biceps brachii'),
  triceps(scientificName: 'triceps brachii'),
  frontDelts(scientificName: 'anterior deltoid'),
  sideDelts(scientificName: 'medial deltoid'),
  rearDelts(scientificName: 'posterior deltoid'),
  lowerBack(scientificName: 'erector spinae'),
  lats(scientificName: 'latissimus dorsi'),
  traps(scientificName: 'trapezius'),
  chest(scientificName: 'pectoralis major'),
  glutes(scientificName: 'glutaeus maximus'),
  gastroc(scientificName: 'gastrocnemius'),
  soleus(scientificName: 'soleus'),
  hamstrings(scientificName: 'hamstrings'),
  quadriceps(scientificName: 'quadriceps');

  const Muscle({
    required this.scientificName,
  });

  final String scientificName;

  static final Map<Muscle, MuscleGroup> muscleToGroup = {
    Muscle.abdominals: MuscleGroup.abdominals,
    Muscle.obliques: MuscleGroup.abdominals,
    Muscle.biceps: MuscleGroup.arms,
    Muscle.triceps: MuscleGroup.arms,
    Muscle.frontDelts: MuscleGroup.shoulders,
    Muscle.sideDelts: MuscleGroup.shoulders,
    Muscle.rearDelts: MuscleGroup.shoulders,
    Muscle.lowerBack: MuscleGroup.back,
    Muscle.lats: MuscleGroup.back,
    Muscle.traps: MuscleGroup.back,
    Muscle.chest: MuscleGroup.chest,
    Muscle.quadriceps: MuscleGroup.legs,
    Muscle.hamstrings: MuscleGroup.legs,
    Muscle.gastroc: MuscleGroup.legs,
    Muscle.soleus: MuscleGroup.legs,
    Muscle.glutes: MuscleGroup.legs,
  };
}

enum MuscleGroup {
  abdominals,
  arms,
  shoulders,
  back,
  legs,
  chest,
}
