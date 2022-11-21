import 'dart:async';
import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:just_audio/just_audio.dart' as just_audio;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_sound_platform_interface/flutter_sound_recorder_platform_interface.dart';
import 'package:voice_demo/model/recorder_model.dart';

/// 录音demo
class RecorderDemo extends StatefulWidget {
  const RecorderDemo({Key? key}) : super(key: key);

  @override
  State<RecorderDemo> createState() => _RecorderDemoState();
}

class _RecorderDemoState extends State<RecorderDemo> {
  List<RecorderModel> recorderListPath = [];

  /// 播放器
  FlutterSoundPlayer? player = FlutterSoundPlayer();

  /// 录音
  FlutterSoundRecorder? recorder = FlutterSoundRecorder();

  /// 获取语音时长
  just_audio.AudioPlayer audioPlayer = just_audio.AudioPlayer();

  /// 录音中
  bool recording = false;

  /// 录音监听
  StreamSubscription? recorderSubscription;

  /// 滚动控制器
  ScrollController controller = ScrollController();

  /// 插入到右边
  bool addRight = true;

  @override
  void initState() {
    super.initState();
    initRecorder();
    initPlayer();
    loadData();
  }

  @override
  void dispose() {
    audioPlayer.dispose();

    player?.closePlayer();
    player = null;

    recorder?.closeRecorder();
    recorder = null;

    controller.dispose();
    super.dispose();
  }

  /// 初始化 录音
  void initRecorder() async {
    // 麦克风权限
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw RecordingPermissionException('未授予麦克风权限');
    }
    await recorder?.openRecorder();
    final session = await AudioSession.instance;
    await session.configure(
      AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
        avAudioSessionCategoryOptions:
            AVAudioSessionCategoryOptions.allowBluetooth |
                AVAudioSessionCategoryOptions.defaultToSpeaker,
        avAudioSessionMode: AVAudioSessionMode.spokenAudio,
        avAudioSessionRouteSharingPolicy:
            AVAudioSessionRouteSharingPolicy.defaultPolicy,
        avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
        androidAudioAttributes: const AndroidAudioAttributes(
          contentType: AndroidAudioContentType.speech,
          flags: AndroidAudioFlags.none,
          usage: AndroidAudioUsage.voiceCommunication,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
        androidWillPauseWhenDucked: true,
      ),
    );
    // 录音监听回调间隔时间
    await recorder?.setSubscriptionDuration(const Duration(milliseconds: 30));
    setState(() {});
  }

  /// 初始化播放
  void initPlayer() {
    player?.openPlayer();
  }

  /// 加载数据
  void loadData() async {
    var tempDir = await getTemporaryDirectory();
    List<FileSystemEntity> list = tempDir.listSync().where((element) {
      String tempPath = element.path;
      debugPrint('test path=$tempPath');
      return tempPath.contains('voice_') && tempPath.endsWith('.mp4');
    }).toList();
    Future.forEach<FileSystemEntity>(list, (element) async {
      RecorderModel temp = await getRecorderData(element.path);
      recorderListPath.insert(0, temp);
    }).whenComplete(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('录音demo'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: changedDirection,
            icon: const Icon(Icons.swap_horiz),
          ),
        ],
      ),
      backgroundColor: Colors.grey[100],
      body: bodyView(),
    );
  }

  /// 内容视图
  Widget bodyView() {
    return Column(
      children: [
        Expanded(
          child: listView(),
        ),
        bottomView(),
      ],
    );
  }

  /// 列表视图
  Widget listView() {
    return Container(
      alignment: Alignment.topCenter,
      child: ListView.builder(
        reverse: true,
        shrinkWrap: true,
        controller: controller,
        itemBuilder: (BuildContext context, int index) {
          var model = recorderListPath[index];
          bool playing = model.playing;
          bool displayLeft = model.direction == 1;
          String time = getTimeValue(model.duration);
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            alignment:
                displayLeft ? Alignment.centerLeft : Alignment.centerRight,
            child: GestureDetector(
              onTap: () => playVoice(model),
              onDoubleTap: () {},
              behavior: HitTestBehavior.translucent,
              child: Container(
                constraints: const BoxConstraints(
                  minHeight: 30,
                  minWidth: 120,
                  maxWidth: 200,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  color: playing ? Colors.green : Colors.white,
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.record_voice_over,
                      color: playing ? Colors.white : Colors.black,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        time,
                        style: TextStyle(
                          color: playing ? Colors.white : Colors.black,
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          );
        },
        itemCount: recorderListPath.length,
      ),
    );
  }

  /// 底部视图
  Widget bottomView() {
    return Container(
      height: 50,
      padding: const EdgeInsets.all(8),
      child: GestureDetector(
        onLongPressStart: (details) {
          debugPrint('语音 长按 开始');
        },
        onLongPressDown: (details) {
          debugPrint('语音 长按 按下');
          startRecorder();
        },
        onLongPressUp: () {
          debugPrint('语音 长按 抬起');
        },
        onLongPressEnd: (details) {
          debugPrint('语音 长按 结束');
          stopRecorder();
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.green,
          ),
          alignment: Alignment.center,
          child: const Text(
            '语音',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }

  /// 改变插入位置
  void changedDirection() {
    addRight = !addRight;
  }

  /// 开始录音
  startRecorder() async {
    if (recording) return;
    recording = true;
    Fluttertoast.showToast(
      msg: "录音中",
      toastLength: Toast.LENGTH_SHORT,
      webBgColor: "#e74c3c",
      textColor: Colors.white,
      gravity: ToastGravity.CENTER,
    );
    try {
      String path = 'voice_${DateTime.now().millisecondsSinceEpoch}.mp4';
      await recorder?.startRecorder(
        toFile: path,
        codec: Codec.aacMP4,
        audioSource: AudioSource.microphone,
      );
    } catch (e) {
      debugPrint('e=$e');
    }
    setState(() {});
  }

  /// 停止录音
  void stopRecorder() async {
    recording = false;
    Fluttertoast.cancel();
    String? value = await recorder?.stopRecorder();
    value ??= '';
    if (value.isEmpty) return;
    RecorderModel temp = await getRecorderData(value);
    temp.direction = addRight ? 2 : 1;
    recorderListPath.insert(0, temp);
    controller.jumpTo(0);
    setState(() {});
  }

  /// 开始播放
  void playVoice(RecorderModel model) {
    bool playIsStopped = player?.isStopped ?? false;
    debugPrint('path=${model.path} playIsStopped=$playIsStopped');
    if (model.playing) {
      player?.stopPlayer().whenComplete(() {
        model.playing = false;
        setState(() {});
      });
    } else {
      if (!playIsStopped) return;
      player?.startPlayer(
        fromURI: model.path,
        whenFinished: () {
          model.playing = false;
          setState(() {});
        },
      );
      model.playing = true;
      setState(() {});
    }
  }

  /// 语音转文字
  String getTimeValue(Duration? duration) {
    if (duration == null) return '1"';
    int minutes = duration.inMinutes;
    int seconds = duration.inSeconds;
    if (seconds < 1) {
      seconds = 1;
    }
    int sum = minutes * 60 + seconds;
    return '$sum"';
  }

  /// 获取语音对象
  Future<RecorderModel> getRecorderData(String path) async {
    Duration? duration = await audioPlayer.setFilePath(path);
    File file = File(path);
    int size = file.lengthSync();
    double sizeInKb = size / 1024;
    debugPrint(
        'path:$path 时长：duration=$duration size=$size sizeInKb=$sizeInKb');
    return RecorderModel(
      path: path,
      length: sizeInKb,
      duration: duration,
    );
  }
}
