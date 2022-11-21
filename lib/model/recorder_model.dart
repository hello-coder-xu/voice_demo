class RecorderModel {
  String path;
  Duration? duration;
  double length;
  bool playing;
  String? text;

  // 1 左边  2右边
  int direction;

  RecorderModel({
    required this.path,
    this.duration,
    required this.length,
    this.playing = false,
    this.text,
    this.direction = 1,
  });
}
