445    final cameraController = _cameraController;
446    if (cameraController != null) {
447      unawaited(
448        (() async {
449          try {
450            await cameraController.dispose();
451          } catch (e) {
452            debugPrint('Error disposing camera controller: $e');
453          }
454        })()
455      );
456      _cameraController = null;
457      }
458    }
459​
460    final accelerometerSubscription = _accelerometerSubscription;
461    if (accelerometerSubscription != null) {
462      unawaited(
463        (() async {
464          try {
465            await accelerometerSubscription.cancel();
466          } catch (e) {
467            debugPrint('Error cancelling accelerometer subscription: $e');
468          }
469        })()
470      );
471      _accelerometerSubscription = null;
472    }
473​
474    final gyroscopeSubscription = _gyroscopeSubscription;
475    if (gyroscopeSubscription != null) {
476      unawaited(
477        (() async {
478          try {
479            await gyroscopeSubscription.cancel();
480          } catch (e) {
481            debugPrint('Error cancelling gyroscope subscription: $e');
482          }
483        })()
484      );
485      _gyroscopeSubscription = null;
486    }
487​
488    super.dispose();
489  }
490​
491  @visibleForTesting
492  void setInitializationOverride(Future<void> Function()? override) {
493    _initializationOverride = override;
494  }
495​
496  @visibleForTesting
497  void setSensorSubscriptionsForTesting({
498    StreamSubscription<AccelerometerEvent>? accelerometer,
499    StreamSubscription<GyroscopeEvent>? gyroscope,
500  }) {
501    _accelerometerSubscription = accelerometer;
502    _gyroscopeSubscription = gyroscope;
503  }
504​
505  @visibleForTesting
506  void setTestMode(bool isTestMode) {
507    _isTestMode = isTestMode;
508  }
509​
510  bool _permissionStatusAllowsUse(PermissionStatus status) {
511    return status.isGranted || status.isLimited || status.isProvisional;
512  }
513​
514  Future<bool> _ensureCameraPermission() async {
515    PermissionStatus status = await Permission.camera.status;
516​
517    if (!_permissionStatusAllowsUse(status)) {
518      status = await Permission.camera.request();
519    }
520​
521    if (_permissionStatusAllowsUse(status)) {
522      _updateCameraPermissionState(true, null);
523      return true;
524    }
525​
