import 'dart:async';
import 'dart:io';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_sound_platform_interface/flutter_sound_recorder_platform_interface.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

const theSource = AudioSource.microphone;
const int tSampleRate = 44000;

/// Example app.
class RecorderPcm16 extends StatefulWidget {
  const RecorderPcm16({Key? key}) : super(key: key);

  @override
  RecorderPcm16State createState() => RecorderPcm16State();
}

class RecorderPcm16State extends State<RecorderPcm16> {
  // 音频存储格式
  final Codec codec = Codec.pcm16;

  // 音频存储路径
  String path = 'tau_file.pcm';

  // 播放器
  FlutterSoundPlayer? player = FlutterSoundPlayer();

  // 录音
  FlutterSoundRecorder? recorder = FlutterSoundRecorder();

  // 播放器是否初始化
  bool playerHasInit = false;

  // 录音是否初始化
  bool recorderHasInit = false;

  // 是否可以播放
  bool playbackReady = false;

  // 录音监听
  StreamSubscription? recorderSubscription;

  // 文件流监听
  StreamSubscription? recordingDataSubscription;

  @override
  void initState() {
    // 初始化录音
    initRecorder();
    // 初始化播放
    initPlayer();
    super.initState();
  }

  /// 初始化播放
  void initPlayer() async {
    await player?.openPlayer();
    playerHasInit = true;
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
    recorderHasInit = true;
    // 录音监听回调间隔时间
    await recorder?.setSubscriptionDuration(const Duration(milliseconds: 30));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    bool isRecording = recorder?.isRecording ?? false;

    return Scaffold(
      backgroundColor: Colors.blue,
      appBar: AppBar(
        title: const Text('录音播放Demo'),
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(3),
            padding: const EdgeInsets.all(3),
            height: 80,
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFFAF0E6),
              border: Border.all(
                color: Colors.indigo,
                width: 3,
              ),
            ),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: getRecorderFn(),
                  child: Text(isRecording ? '暂停' : '录音'),
                ),
                const SizedBox(width: 20),
                Text(isRecording ? '录音中' : '录音已停止'),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.all(3),
            padding: const EdgeInsets.all(3),
            height: 80,
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFFAF0E6),
              border: Border.all(
                color: Colors.indigo,
                width: 3,
              ),
            ),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: getPlaybackFn(),
                  child: Text(player!.isPlaying ? '暂停播放' : '开始播放'),
                ),
                const SizedBox(width: 20),
                Text(player!.isPlaying ? '播放中' : '播放已停止'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 录音按钮执行方法
  VoidCallback? getRecorderFn() {
    bool playIsStopped = player?.isStopped ?? false;
    bool recorderIsStopped = recorder?.isStopped ?? false;
    debugPrint('test getRecorderFn'
        ' playIsStopped=$playIsStopped'
        ' recorderHasInit=$recorderHasInit'
        ' recorderIsStopped=$recorderIsStopped');
    if (!recorderHasInit || !playIsStopped) {
      return null;
    }
    return recorderIsStopped ? record : stopRecorder;
  }

  /// 播放按钮执行方法
  VoidCallback? getPlaybackFn() {
    bool playIsStopped = player?.isStopped ?? false;
    bool recorderIsStopped = recorder?.isStopped ?? false;
    debugPrint('test getPlaybackFn'
        ' playerHasInit=$playerHasInit'
        ' playbackReady=$playbackReady'
        ' recorderHasInit=$recorderHasInit'
        ' recorderIsStopped=$recorderIsStopped');
    if (!playerHasInit || !playbackReady || !recorderIsStopped) {
      return null;
    }
    return playIsStopped ? play : stopPlayer;
  }

  /// 创建文件
  Future<IOSink> createFile() async {
    var tempDir = await getTemporaryDirectory();
    path = '${tempDir.path}/$path';
    var outputFile = File(path);
    if (outputFile.existsSync()) {
      await outputFile.delete();
    }
    return outputFile.openWrite();
  }

  /// 录音
  void record() async {
    try {
      var sink = await createFile();
      var recordingDataController = StreamController<Food>();
      recordingDataSubscription = recordingDataController.stream.listen(
        (buffer) {
          if (buffer is FoodData) {
            sink.add(buffer.data!);
          }
        },
      );
      await recorder?.startRecorder(
        toStream: recordingDataController.sink,
        codec: Codec.pcm16,
        numChannels: 1,
      );
      // 注册录音监听
      registerRecorderSubscription();
    } catch (e) {
      unRegisterRecorderSubscription();
    }
    setState(() {});
  }

  /// 停止录音
  void stopRecorder() async {
    String? value = await recorder?.stopRecorder();
    debugPrint('test 停止录音 value=$value');

    if (recordingDataSubscription != null) {
      await recordingDataSubscription!.cancel();
      recordingDataSubscription = null;
    }
    setState(() {
      playbackReady = true;
    });
  }

  /// 播放
  void play() {
    bool recorderIsStopped = recorder?.isStopped ?? false;
    bool playIsStopped = player?.isStopped ?? false;
    if (playerHasInit && playbackReady && recorderIsStopped && playIsStopped) {
      // 使用pcm16播放，会生成本地缓存
      player?.startPlayer(
        fromURI: path,
        codec: Codec.pcm16,
        numChannels: 1,
        whenFinished: () {
          setState(() {});
        },
      );
      setState(() {});
    }
  }

  /// 停止播放
  void stopPlayer() async {
    await player?.stopPlayer();
    setState(() {});
  }

  /// 注册录音监听
  void registerRecorderSubscription() {
    recorderSubscription = recorder?.onProgress?.listen((e) {
      debugPrint('test e=$e');
    });
  }

  /// 注销录音监听
  void unRegisterRecorderSubscription() async {
    await recorderSubscription?.cancel();
    recorderSubscription = null;
  }

  @override
  void dispose() {
    player?.closePlayer();
    player = null;

    recorder?.closeRecorder();
    recorder = null;
    super.dispose();
  }
}
