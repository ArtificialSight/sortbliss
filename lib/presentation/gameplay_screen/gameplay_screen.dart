177
_backgroundAnimation = ColorTween(
178
  begin: const Color(0xFF0F172A), // Deep slate
179
  end: const Color(0xFF1E293B), // Lighter slate
180
).animate(CurvedAnimation(
181
  parent: _backgroundController,
182
  curve: Curves.easeInOut,
183
));
184

185
// Ambient lighting effect
186
_ambientController = AnimationController(
187
  duration: const Duration(seconds: 6),
188
  vsync: this,
189
);
190

191
_ambientAnimation = Tween<double>(
192
  begin: 0.1,
193
  end: 0.3,
194
).animate(CurvedAnimation(
195
  parent: _ambientController,
196
  curve: Curves.easeInOut,
197
));
198

199
_backgroundController.repeat(reverse: true);
200
_ambientController.repeat(reverse: true);
201
}
202

203
void _initializeLevel() {
204
  _comboResetTimer?.cancel();
205
  _comboResetTimer = null;
206
  setState(() {
207
    // Reset basic game state
208
    _resetBasicGameState();
209
    
210
    // Reset speed analytics and timing metrics
211
    _resetSpeedMetrics();
212
    
213
    // Reset scoring and combo system
214
    _resetScoringSystem();
215
  });
216
  
217
  // Reset containers
218
}
219

220
/// Resets basic gameplay state variables
221
/// Separated for maintainability and conflict avoidance
222
void _resetBasicGameState() {
223
  _moveCount = 0;
224
  _isLevelComplete = false;
225
  _showParticleEffect = false;
226
  _highlightedContainerId = null;
227
  _draggedItemId = null;
228
}
229

230
/// Resets speed analytics and move timestamp tracking
231
/// Added from codex/add-move-timestamp-and-user-speed-metrics branch
232
void _resetSpeedMetrics() {
233
  _lastMoveTimestamp = null;
234
}
235

236
/// Resets scoring system, combo streaks, and placement points
237
/// Added from main branch for comprehensive score tracking
238
void _resetScoringSystem() {
239
  _score = 0;
240
  _lastPlacementPoints = 0;
241
  _comboStreak = 0;
242
  _lastCorrectDropTime = null;
243
  _showComboIndicator = false;
244
  _comboText = '';
245
}
246

247
// Reset containers