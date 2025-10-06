163
  void _handleShareScore() {
164    final level = _readInt('level', defaultValue: 1);
165    final totalScore = _readInt('totalScore', defaultValue: 0);
166    final stars = _readInt('starsEarned', defaultValue: 0);
167    final message =
168        'I just completed level $level in SortBliss with $stars ⭐ and a score of $totalScore!';
169 
170    Share.share(message);
171  }
172 
173  @override
174  void dispose() {
175    _confettiTimer?.cancel();
176    _backgroundController.dispose();
177    _contentController.dispose();
178    super.dispose();
179  }
180 
181  @override
182  Widget build(BuildContext context) {
183    if (widget.levelData.isEmpty) {
184      return _buildMissingLevelDataFallback(context);
185    }
186 
187    final colorScheme = Theme.of(context).colorScheme;
188    final level = _readInt('level', defaultValue: 1);
189    final levelTitle = _readString('levelTitle', defaultValue: 'Level $level Complete');
190    final completionTime = _readString('completionTime', defaultValue: 'Just now');
191    final difficulty = _readString('difficulty', defaultValue: 'Standard');
192 
193    return Scaffold(
194      backgroundColor: colorScheme.surface,
195      body: AnimatedBuilder(
196        animation: Listenable.merge([
197          _backgroundController,
198          _contentController,
199        ]),
200        builder: (context, child) {