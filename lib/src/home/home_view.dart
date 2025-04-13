import 'dart:async';
import 'dart:convert';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:al_ia/api/speech_api.dart';
import 'package:al_ia/src/home/models.dart';
import 'package:al_ia/src/settings/settings_controller.dart';
import 'package:al_ia/widgets/sliver_custom_app_bar.dart';
import 'package:al_ia/util/common.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:lottie/lottie.dart';

class HomeView extends StatefulWidget {
  final SettingsController controller;
  final String? query;
  const HomeView({Key? key, required this.controller, this.query})
      : super(key: key);
  static const routeName = '/';

  @override
  HomeViewState createState() => HomeViewState();
}

enum TtsState { playing, stopped, paused, continued }

class HomeViewState extends State<HomeView> with TickerProviderStateMixin {
  final String defaultStr = 'Presione el micrófono y di algo...';
  late String text;
  final List<Content> chatHistory = []; //ADDED
  late bool cleared;
  bool isListening = false;
  bool fetchingResponse = false;
  String responseStr = '';
  bool currentlyPlaying = false; //La voz esta hablando true/false
  late final AnimationController _lottieController;

  final ValueNotifier<bool> isPlayingNotifier = ValueNotifier<bool>(false);

  late FlutterTts flutterTts;
  String? language;
  String? engine;
  double volume = 1;
  double pitch = 1.0;
  double rate = 0.5;
  bool isCurrentLanguageInstalled = false;

  TtsState ttsState = TtsState.stopped;

  final gemini = Gemini.instance;

  get isPlaying => ttsState == TtsState.playing;
  get isStopped => ttsState == TtsState.stopped;
  get isPaused => ttsState == TtsState.paused;
  get isContinued => ttsState == TtsState.continued;

  bool get isIOS => !kIsWeb && Platform.isIOS;
  bool get isAndroid => !kIsWeb && Platform.isAndroid;
  bool get isWindows => !kIsWeb && Platform.isWindows;
  bool get isWeb => kIsWeb;

  bool skipHistory = false;

  @override
  void initState() {
    _inicializarAnimaciones();

    cleared = true;
    text = defaultStr;
    initTts();
    handlePresets();
    _initializeChat(); //ADDED

    isPlayingNotifier.addListener(_onPlayingStateChanged);
    super.initState();
  }

  void _onPlayingStateChanged() {
    // Se ejecuta cada vez que el valor cambia
    if (isPlayingNotifier.value) {
      _lottieController.reset(); // Volver al inicio
      _lottieController.repeat(
        // Repetir la animación
        reverse: true, // Ir y volver (efecto boca)
        period: const Duration(seconds: 1), // Duración de cada ciclo
      );
    } else {
      _lottieController.animateTo(0.4);
    }
  }

  @override
  void dispose() {
    flutterTts.stop();
    _lottieController.dispose();
    super.dispose();
  }

  _inicializarAnimaciones() {
    _lottieController = AnimationController(
      value: 0.4,
      vsync: this,
      duration: const Duration(seconds: 10),
    );
  }

  //ADDED
  Future<void> _initializeChat() async {
    // Contexto inicial
    chatHistory.add(
      Content(
        role: 'user',
        parts: [
          Part.text("""
          Eres un asistente amigable que:
          0. Tus creadores son $elian $jordan $solange y $carolina
          1. Da respuestas concisas y claras
          3. Usa un tono amable y profesional
          4. Si no sabes algo, lo admites honestamente
          5. Esta app fue hecha para exponerla a un público y mostrarles las capacidades de la tecnología actual
          """)
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverPersistentHeader(
            delegate: SliverCustomAppBar(),
            pinned: false,
            floating: true,
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                return Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // const SizedBox(height: 8.0),
                      Center(
                        child: Lottie.asset(
                          'assets/boca_lottie.json', // tu archivo de animación
                          width: 100,
                          height: 100,
                          controller: _lottieController,
                          onLoaded: (composition) {
                            _lottieController.duration = composition.duration;
                          },
                        ),
                      ),
                      Text(
                        text.toCapitalized(),
                        style: const TextStyle(
                          fontSize: 22.0,
                        ),
                      ),
                      const SizedBox(height: 10.0),
                      !isListening && !cleared && !fetchingResponse
                          ? InkWell(
                              onTap: _clearChat,
                              child: const Text(
                                "Borrar \u2573",
                                style: TextStyle(
                                  color: Colors.transparent,
                                  decoration: TextDecoration.underline,
                                  decorationStyle: TextDecorationStyle.dotted,
                                  decorationColor: Colors.red,
                                  shadows: [
                                    Shadow(
                                        color: Colors.red,
                                        offset: Offset(0, -4))
                                  ],
                                ),
                              ),
                              // onTap: () async {
                              //   await _stop();
                              //   text = defaultStr;
                              //   cleared = true;
                              //   responseStr = '';
                              //   setState(() {});
                              // },
                            )
                          : const SizedBox(),
                      const SizedBox(height: 40.0),
                      fetchingResponse
                          ? const SizedBox(
                              width: double.infinity,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SpinKitThreeBounce(
                                    color: Colors.red,
                                    size: 22,
                                  ),
                                ],
                              ),
                            )
                          : Opacity(
                              opacity: 0.7,
                              child: DefaultTextStyle(
                                style: TextStyle(
                                  fontSize: 16.0,
                                  color: Theme.of(context)
                                      .buttonTheme
                                      .colorScheme
                                      ?.onSurface,
                                ),
                                child: responseStr.isNotEmpty
                                    ? AnimatedTextKit(
                                        isRepeatingAnimation: false,
                                        displayFullTextOnTap: true,
                                        animatedTexts: [
                                          TypewriterAnimatedText(
                                            responseStr,
                                            speed: const Duration(
                                                milliseconds: 50),
                                            cursor: ' _',
                                          ),
                                        ],
                                      )
                                    : const SizedBox(),
                              ),
                            ),
                      const SizedBox(height: 120.0),
                    ],
                  ),
                );
              },
              childCount: 1,
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Visibility(
        visible: !fetchingResponse && !currentlyPlaying,
        child: AvatarGlow(
          animate: isListening,
          endRadius: 75,
          glowColor: Colors.red,
          child: FloatingActionButton(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            onPressed: toggleRecording,
            child: Icon(
              isListening ? Icons.mic : Icons.mic_none,
              size: 36,
            ),
          ),
        ),
      ),
    );
  }

  Future toggleRecording() {
    try {
      return SpeechApi.toggleRecording(
        onResult: (text) {
          this.text = text;
          cleared = false;
          setState(() {});

          if (!isListening) {
            Future.delayed(const Duration(seconds: 3), () async {
              logger.i(text);
              // Make request to ChatGPT here, and read out loud API response
              await geminiSearch(text);
            });
          }
        },
        onListening: (isListening) {
          setState(() => this.isListening = isListening);
          if (isListening) {
            responseStr = '';
            _stop();
            setState(() {});
          }
        },
      );
    } catch (e) {
      text = defaultStr;
      cleared = true;
      setState(() {});
      logger.e(e);
      rethrow;
    }
  }

  //CHANGED
  Future geminiSearch(String q) async {
    fetchingResponse = true;
    setState(() {});

    try {
      // Agregar la pregunta del usuario al historial
      chatHistory.add(
        Content(
          role: 'user',
          parts: [Part.text(q)],
        ),
      );

      final response = await gemini.chat(chatHistory);

      if (response?.output != null) {
        responseStr = (response?.output ?? '').replaceAll('*', '');

        // Agregar la respuesta al historial
        chatHistory.add(
          Content(
            role: 'model',
            parts: [Part.text(responseStr)],
          ),
        );

        // Primero actualizamos el estado para mostrar el texto
        fetchingResponse = false;
        setState(() {});

        // Luego guardamos en el historial
        await _appHistory(q.toCapitalized());

        // Finalmente iniciamos el texto a voz sin await
        _speak(msg: responseStr);
      }
    } catch (e) {
      logger.e(e);
      fetchingResponse = false;
      setState(() {});
    }
  }

  Future<void> _clearChat() async {
    // Added
    await _stop();
    text = defaultStr;
    cleared = true;
    responseStr = '';
    chatHistory.clear(); // Limpiar el historial
    await _initializeChat(); // Reiniciar el contexto
    setState(() {});
  }

  AnimatedTextKit aiText() {
    List<TypewriterAnimatedText> texts = <TypewriterAnimatedText>[];
    LineSplitter ls = const LineSplitter();
    List<String> strs = ls.convert(responseStr);
    for (String s in strs) {
      texts.add(TypewriterAnimatedText(s,
          speed: const Duration(milliseconds: 50), cursor: ' _'));
    }
    return AnimatedTextKit(
      isRepeatingAnimation: false,
      displayFullTextOnTap: true,
      animatedTexts: texts,
    );
  }

  initTts() {
    flutterTts = FlutterTts();
    flutterTts.setLanguage("es-MX"); // CHANGED

    _setAwaitOptions();

    if (isAndroid) {
      _getDefaultEngine();
      _getDefaultVoice();
    }

    flutterTts.setStartHandler(() {
      setState(() {
        logger.d("Playing");
        currentlyPlaying = true;
        isPlayingNotifier.value = true; // REPEAT LOTTIE ANIMATION
        ttsState = TtsState.playing;
      });
    });

    flutterTts.setCompletionHandler(() {
      setState(() {
        logger.d("Complete");
        currentlyPlaying = false;
        isPlayingNotifier.value = false; // STOP LOTTIE ANIMATION
        ttsState = TtsState.stopped;
      });
    });

    flutterTts.setCancelHandler(() {
      setState(() {
        logger.d("Cancel");
        currentlyPlaying = false;
        ttsState = TtsState.stopped;
      });
    });

    flutterTts.setPauseHandler(() {
      setState(() {
        logger.d("Paused");
        currentlyPlaying = false;
        ttsState = TtsState.paused;
      });
    });

    flutterTts.setContinueHandler(() {
      setState(() {
        logger.d("Continued");
        currentlyPlaying = true;
        ttsState = TtsState.continued;
      });
    });

    flutterTts.setErrorHandler((msg) {
      setState(() {
        logger.d("error: $msg");
        currentlyPlaying = false;
        ttsState = TtsState.stopped;
      });
    });
  }

  Future _appHistory(String q) async {
    DateTime now = DateTime.now();
    List<String> months = [
      '',
      'Jan',
      'Feb' 'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    String entryTime =
        "${now.day.toString().padLeft(2, '0')} ${months[now.month]} ${now.year.toString()}, ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";
    Map entry = {"time": entryTime, "query": q};
    List<Map> appHistory = [...widget.controller.appHistory];
    appHistory.insert(0, entry);
    const maxHistory = 20;
    if (appHistory.length > maxHistory) {
      appHistory.removeRange((maxHistory - 1), appHistory.length);
    }
    if (skipHistory == false) {
      await widget.controller.updateAppHistory(appHistory);
    }
    skipHistory = false;
    setState(() {});
  }

  Future _getDefaultEngine() async {
    var engine = await flutterTts.getDefaultEngine;
    if (engine != null) {
      logger.d(engine);
    }
  }

  Future _getDefaultVoice() async {
    var voice = await flutterTts.getDefaultVoice;
    if (voice != null) {
      // logger.d(voice);
    }
  }

  Future _speak({String msg = ''}) async {
    if (msg.isNotEmpty) {
      await flutterTts.setVolume(volume);
      await flutterTts.setSpeechRate(rate);
      await flutterTts.setPitch(pitch);

      setState(() {
        currentlyPlaying = true;
      });

      flutterTts.speak(msg); // Removido el await
    }
  }

  Future _setAwaitOptions() async {
    await flutterTts.awaitSpeakCompletion(true);
  }

  Future _stop() async {
    var result = await flutterTts.stop();
    if (result == 1) {
      ttsState = TtsState.stopped;
      currentlyPlaying = false;
      setState(() {});
    }
  }

  // ignore: unused_element
  Future _pause() async {
    var result = await flutterTts.pause();
    if (result == 1) setState(() => ttsState = TtsState.paused);
  }

  handlePresets() async {
    logger.i(widget.query);
    if (widget.query != null) {
      text = "${widget.query}";
      cleared = false;
      isListening = false;
      skipHistory = true;
      setState(() {});
      _stop();
      await geminiSearch(text);
    }
  }
}
