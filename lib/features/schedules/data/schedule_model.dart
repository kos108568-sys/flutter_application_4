class ScheduleModel {
  final String groupName;
  final String imageUrl;
  final bool isFavorite;

  ScheduleModel({
    required this.groupName,
    required this.imageUrl,
    this.isFavorite = false,
  });
}
