445    final cameraController = _cameraController;
446    if (cameraController != null) {
447      unawaited(cameraController.dispose());
448      _cameraController = null;
449      }
450    }
451​
452    final accelerometerSubscription = _accelerometerSubscription;
453    if (accelerometerSubscription != null) {
454      unawaited(accelerometerSubscription.cancel());
455      _accelerometerSubscription = null;
456    }
457​
458    final gyroscopeSubscription = _gyroscopeSubscription;
459    if (gyroscopeSubscription != null) {
460      unawaited(gyroscopeSubscription.cancel());
461      _gyroscopeSubscription = null;
462    }
463​
464    super.dispose();
465  }
466​
467  @visibleForTesting
468  void setInitializationOverride(Future<void> Function()? override) {
469    _initializationOverride = override;
470  }
471​
472  @visibleForTesting
473  void setSensorSubscriptionsForTesting({
474    StreamSubscription<AccelerometerEvent>? accelerometer,
475    StreamSubscription<GyroscopeEvent>? gyroscope,
476  }) {
477    _accelerometerSubscription = accelerometer;
478    _gyroscopeSubscription = gyroscope;
479  }
480​
481  @visibleForTesting
482  void setTestMode(bool isTestMode) {
483    _isTestMode = isTestMode;
484  }
485​
486  bool _permissionStatusAllowsUse(PermissionStatus status) {
487    return status.isGranted || status.isLimited || status.isProvisional;
488  }
489​
490  Future<bool> _ensureCameraPermission() async {
491    PermissionStatus status = await Permission.camera.status;
492​
493    if (!_permissionStatusAllowsUse(status)) {
494      status = await Permission.camera.request();
495    }
496​
497    if (_permissionStatusAllowsUse(status)) {
498      _updateCameraPermissionState(true, null);
499      return true;
500    }
501​