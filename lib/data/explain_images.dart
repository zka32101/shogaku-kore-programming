/// 説明画像（assets/illustrations/explain_*.webp）の対応表。
/// 画像が無いステージ／レッスンは null を返し、UI 側では非表示にする。
const Set<String> kExplainStageIds = {
  'stage_01',
  'stage_06',
  'stage_07',
  'stage_08',
  'stage_09',
  'stage_10',
  'stage_21',
  'stage_22',
  'stage_24',
  'stage_41',
  'stage_42',
  'stage_47',
  'stage_53',
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
  'stage_11',
  'stage_12',
  'stage_16',
  'stage_18',
  'stage_19',
  'stage_23',
  'stage_25',
  'stage_27',
  'stage_28',
  'stage_31',
  'stage_32',
  'stage_35',
  'stage_37',
  'stage_38',
  'stage_39',
  'stage_40',
  'stage_45',
  'stage_48',
  'stage_50',
  'stage_55',
  'stage_57',
  'stage_58',
  'stage_59',
  'stage_60',
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

/// 画像ファイルを他ステージと共有するもの（stage_24 は stage_21 の画像を流用）。
const Map<String, String> _kExplainStageAlias = {'stage_24': 'stage_21'};

String? explainImageForStage(String stageId) =>
    kExplainStageIds.contains(stageId)
    ? 'assets/illustrations/explain_${_kExplainStageAlias[stageId] ?? stageId}.webp'
    : null;

String? explainImageForLesson(String lessonId) =>
    kExplainLessonIds.contains(lessonId)
    ? 'assets/illustrations/explain_$lessonId.webp'
    : null;
