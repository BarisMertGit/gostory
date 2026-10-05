/// Compact Turkish labels shared by discovery and archive cards.
String memoryDateLabel(DateTime date) {
  const months = [
    'Oca',
    'Şub',
    'Mar',
    'Nis',
    'May',
    'Haz',
    'Tem',
    'Ağu',
    'Eyl',
    'Eki',
    'Kas',
    'Ara',
  ];
  final local = date.toLocal();
  return '${local.day} ${months[local.month - 1]} ${local.year}';
}

String memoryDistanceLabel(double meters) => meters < 1000
    ? '${meters.round()} m uzaklıkta'
    : '${(meters / 1000).toStringAsFixed(1).replaceAll('.', ',')} km uzaklıkta';
