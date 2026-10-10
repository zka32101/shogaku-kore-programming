/// 説明画像（assets/illustrations/explain_*.webp）の対応表。
/// 画像が無いステージ／レッスンは null を返し、UI 側では非表示にする。
const Set<String> kExplainStageIds = {
  'stage_02',
  'stage_03',
  'stage_04',
  'stage_05',
  'stage_13',
  'stage_14',
  'stage_15',
  'stage_17',
  'stage_20',
  'stage_26',
  'stage_29',
  'stage_30',
  'stage_33',
  'stage_34',
  'stage_36',
  'stage_43',
  'stage_44',
  'stage_46',
  'stage_49',
  'stage_51',
  'stage_52',
  'stage_54',
  'stage_56',
};

const Set<String> kExplainLessonIds = {
  'lesson_variable',
  'lesson_sequence',
  'lesson_loop',
  'lesson_conditional',
  'lesson_function',
  'lesson_list',
  'lesson_bug',
};

String? explainImageForStage(String stageId) =>
    kExplainStageIds.contains(stageId)
    ? 'assets/illustrations/explain_$stageId.webp'
    : null;

String? explainImageForLesson(String lessonId) =>
    kExplainLessonIds.contains(lessonId)
    ? 'assets/illustrations/explain_$lessonId.webp'
    : null;
