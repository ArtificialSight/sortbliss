22​
23  const AdaptiveTutorialWidget({
24    Key? key,
25    required this.currentLevel,
26    required this.isFirstTime,
27    required this.userSpeed,
28    required this.completedActions,
29    required this.onActionCompleted,
30    required this.onTutorialCompleted,
31    this.gestureController,
32  }) : super(key: key);
33​
34  @override
35  State<AdaptiveTutorialWidget> createState() => _AdaptiveTutorialWidgetState();
36}
37​
38class _AdaptiveTutorialWidgetState extends State<AdaptiveTutorialWidget>
39  with TickerProviderStateMixin {
40  late AnimationController _overlayController;
41  late AnimationController _highlightController;
42  late AnimationController _pulseController;
43  late AnimationController _textController;
44​
45  late Animation<double> _overlayAnimation;
46  late Animation<double> _highlightAnimation;
47  late Animation<double> _pulseAnimation;
48  late Animation<double> _textScaleAnimation;
49​
50  final PremiumAudioManager _audioManager = PremiumAudioManager();
51  final HapticManager _hapticManager = HapticManager();
52  late final GestureController _gestureController;
53  String? _lastSpeechPermissionMessage;
54  String? _lastCameraPermissionMessage;
55​
56  int _currentStepIndex = 0;
57  bool _isVisible = true;
58  bool _voiceEnabled = false;
59  bool _isWaitingForAction = false;