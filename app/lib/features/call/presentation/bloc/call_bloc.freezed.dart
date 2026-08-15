// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'call_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CallEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CallEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CallEvent()';
}


}

/// @nodoc
class $CallEventCopyWith<$Res>  {
$CallEventCopyWith(CallEvent _, $Res Function(CallEvent) __);
}


/// Adds pattern-matching-related methods to [CallEvent].
extension CallEventPatterns on CallEvent {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( CallSignalingStarted value)?  signalingStarted,TResult Function( CallOutgoingRequested value)?  outgoingCallRequested,TResult Function( CallGroupRequested value)?  groupCallRequested,TResult Function( CallAcceptRequested value)?  acceptRequested,TResult Function( CallRejectRequested value)?  rejectRequested,TResult Function( CallEndRequested value)?  endRequested,TResult Function( CallMuteToggled value)?  muteToggled,TResult Function( CallCameraToggled value)?  cameraToggled,TResult Function( CallSwitchCameraRequested value)?  switchCameraRequested,TResult Function( CallSpeakerToggled value)?  speakerToggled,TResult Function( CallAudioOutputSelected value)?  audioOutputSelected,TResult Function( CallRingTimedOut value)?  ringTimedOut,TResult Function( CallSignalingMessageReceived value)?  signalingMessageReceived,TResult Function( CallLocalIceCandidateGenerated value)?  localIceCandidateGenerated,TResult Function( CallRemoteStreamReceived value)?  remoteStreamReceived,TResult Function( CallGroupRemoteStreamsChanged value)?  groupRemoteStreamsChanged,TResult Function( CallPeerConnectionStateChanged value)?  peerConnectionStateChanged,TResult Function( CallTicked value)?  tick,required TResult orElse(),}){
final _that = this;
switch (_that) {
case CallSignalingStarted() when signalingStarted != null:
return signalingStarted(_that);case CallOutgoingRequested() when outgoingCallRequested != null:
return outgoingCallRequested(_that);case CallGroupRequested() when groupCallRequested != null:
return groupCallRequested(_that);case CallAcceptRequested() when acceptRequested != null:
return acceptRequested(_that);case CallRejectRequested() when rejectRequested != null:
return rejectRequested(_that);case CallEndRequested() when endRequested != null:
return endRequested(_that);case CallMuteToggled() when muteToggled != null:
return muteToggled(_that);case CallCameraToggled() when cameraToggled != null:
return cameraToggled(_that);case CallSwitchCameraRequested() when switchCameraRequested != null:
return switchCameraRequested(_that);case CallSpeakerToggled() when speakerToggled != null:
return speakerToggled(_that);case CallAudioOutputSelected() when audioOutputSelected != null:
return audioOutputSelected(_that);case CallRingTimedOut() when ringTimedOut != null:
return ringTimedOut(_that);case CallSignalingMessageReceived() when signalingMessageReceived != null:
return signalingMessageReceived(_that);case CallLocalIceCandidateGenerated() when localIceCandidateGenerated != null:
return localIceCandidateGenerated(_that);case CallRemoteStreamReceived() when remoteStreamReceived != null:
return remoteStreamReceived(_that);case CallGroupRemoteStreamsChanged() when groupRemoteStreamsChanged != null:
return groupRemoteStreamsChanged(_that);case CallPeerConnectionStateChanged() when peerConnectionStateChanged != null:
return peerConnectionStateChanged(_that);case CallTicked() when tick != null:
return tick(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( CallSignalingStarted value)  signalingStarted,required TResult Function( CallOutgoingRequested value)  outgoingCallRequested,required TResult Function( CallGroupRequested value)  groupCallRequested,required TResult Function( CallAcceptRequested value)  acceptRequested,required TResult Function( CallRejectRequested value)  rejectRequested,required TResult Function( CallEndRequested value)  endRequested,required TResult Function( CallMuteToggled value)  muteToggled,required TResult Function( CallCameraToggled value)  cameraToggled,required TResult Function( CallSwitchCameraRequested value)  switchCameraRequested,required TResult Function( CallSpeakerToggled value)  speakerToggled,required TResult Function( CallAudioOutputSelected value)  audioOutputSelected,required TResult Function( CallRingTimedOut value)  ringTimedOut,required TResult Function( CallSignalingMessageReceived value)  signalingMessageReceived,required TResult Function( CallLocalIceCandidateGenerated value)  localIceCandidateGenerated,required TResult Function( CallRemoteStreamReceived value)  remoteStreamReceived,required TResult Function( CallGroupRemoteStreamsChanged value)  groupRemoteStreamsChanged,required TResult Function( CallPeerConnectionStateChanged value)  peerConnectionStateChanged,required TResult Function( CallTicked value)  tick,}){
final _that = this;
switch (_that) {
case CallSignalingStarted():
return signalingStarted(_that);case CallOutgoingRequested():
return outgoingCallRequested(_that);case CallGroupRequested():
return groupCallRequested(_that);case CallAcceptRequested():
return acceptRequested(_that);case CallRejectRequested():
return rejectRequested(_that);case CallEndRequested():
return endRequested(_that);case CallMuteToggled():
return muteToggled(_that);case CallCameraToggled():
return cameraToggled(_that);case CallSwitchCameraRequested():
return switchCameraRequested(_that);case CallSpeakerToggled():
return speakerToggled(_that);case CallAudioOutputSelected():
return audioOutputSelected(_that);case CallRingTimedOut():
return ringTimedOut(_that);case CallSignalingMessageReceived():
return signalingMessageReceived(_that);case CallLocalIceCandidateGenerated():
return localIceCandidateGenerated(_that);case CallRemoteStreamReceived():
return remoteStreamReceived(_that);case CallGroupRemoteStreamsChanged():
return groupRemoteStreamsChanged(_that);case CallPeerConnectionStateChanged():
return peerConnectionStateChanged(_that);case CallTicked():
return tick(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( CallSignalingStarted value)?  signalingStarted,TResult? Function( CallOutgoingRequested value)?  outgoingCallRequested,TResult? Function( CallGroupRequested value)?  groupCallRequested,TResult? Function( CallAcceptRequested value)?  acceptRequested,TResult? Function( CallRejectRequested value)?  rejectRequested,TResult? Function( CallEndRequested value)?  endRequested,TResult? Function( CallMuteToggled value)?  muteToggled,TResult? Function( CallCameraToggled value)?  cameraToggled,TResult? Function( CallSwitchCameraRequested value)?  switchCameraRequested,TResult? Function( CallSpeakerToggled value)?  speakerToggled,TResult? Function( CallAudioOutputSelected value)?  audioOutputSelected,TResult? Function( CallRingTimedOut value)?  ringTimedOut,TResult? Function( CallSignalingMessageReceived value)?  signalingMessageReceived,TResult? Function( CallLocalIceCandidateGenerated value)?  localIceCandidateGenerated,TResult? Function( CallRemoteStreamReceived value)?  remoteStreamReceived,TResult? Function( CallGroupRemoteStreamsChanged value)?  groupRemoteStreamsChanged,TResult? Function( CallPeerConnectionStateChanged value)?  peerConnectionStateChanged,TResult? Function( CallTicked value)?  tick,}){
final _that = this;
switch (_that) {
case CallSignalingStarted() when signalingStarted != null:
return signalingStarted(_that);case CallOutgoingRequested() when outgoingCallRequested != null:
return outgoingCallRequested(_that);case CallGroupRequested() when groupCallRequested != null:
return groupCallRequested(_that);case CallAcceptRequested() when acceptRequested != null:
return acceptRequested(_that);case CallRejectRequested() when rejectRequested != null:
return rejectRequested(_that);case CallEndRequested() when endRequested != null:
return endRequested(_that);case CallMuteToggled() when muteToggled != null:
return muteToggled(_that);case CallCameraToggled() when cameraToggled != null:
return cameraToggled(_that);case CallSwitchCameraRequested() when switchCameraRequested != null:
return switchCameraRequested(_that);case CallSpeakerToggled() when speakerToggled != null:
return speakerToggled(_that);case CallAudioOutputSelected() when audioOutputSelected != null:
return audioOutputSelected(_that);case CallRingTimedOut() when ringTimedOut != null:
return ringTimedOut(_that);case CallSignalingMessageReceived() when signalingMessageReceived != null:
return signalingMessageReceived(_that);case CallLocalIceCandidateGenerated() when localIceCandidateGenerated != null:
return localIceCandidateGenerated(_that);case CallRemoteStreamReceived() when remoteStreamReceived != null:
return remoteStreamReceived(_that);case CallGroupRemoteStreamsChanged() when groupRemoteStreamsChanged != null:
return groupRemoteStreamsChanged(_that);case CallPeerConnectionStateChanged() when peerConnectionStateChanged != null:
return peerConnectionStateChanged(_that);case CallTicked() when tick != null:
return tick(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  signalingStarted,TResult Function( String calleeId,  bool isVideo)?  outgoingCallRequested,TResult Function( List<String> participantIds)?  groupCallRequested,TResult Function()?  acceptRequested,TResult Function()?  rejectRequested,TResult Function()?  endRequested,TResult Function()?  muteToggled,TResult Function()?  cameraToggled,TResult Function()?  switchCameraRequested,TResult Function()?  speakerToggled,TResult Function( String deviceId,  bool isSpeaker)?  audioOutputSelected,TResult Function( String roomId)?  ringTimedOut,TResult Function( SignalingMessage message)?  signalingMessageReceived,TResult Function( RTCIceCandidate candidate)?  localIceCandidateGenerated,TResult Function( MediaStream stream)?  remoteStreamReceived,TResult Function()?  groupRemoteStreamsChanged,TResult Function( RTCPeerConnectionState state)?  peerConnectionStateChanged,TResult Function()?  tick,required TResult orElse(),}) {final _that = this;
switch (_that) {
case CallSignalingStarted() when signalingStarted != null:
return signalingStarted();case CallOutgoingRequested() when outgoingCallRequested != null:
return outgoingCallRequested(_that.calleeId,_that.isVideo);case CallGroupRequested() when groupCallRequested != null:
return groupCallRequested(_that.participantIds);case CallAcceptRequested() when acceptRequested != null:
return acceptRequested();case CallRejectRequested() when rejectRequested != null:
return rejectRequested();case CallEndRequested() when endRequested != null:
return endRequested();case CallMuteToggled() when muteToggled != null:
return muteToggled();case CallCameraToggled() when cameraToggled != null:
return cameraToggled();case CallSwitchCameraRequested() when switchCameraRequested != null:
return switchCameraRequested();case CallSpeakerToggled() when speakerToggled != null:
return speakerToggled();case CallAudioOutputSelected() when audioOutputSelected != null:
return audioOutputSelected(_that.deviceId,_that.isSpeaker);case CallRingTimedOut() when ringTimedOut != null:
return ringTimedOut(_that.roomId);case CallSignalingMessageReceived() when signalingMessageReceived != null:
return signalingMessageReceived(_that.message);case CallLocalIceCandidateGenerated() when localIceCandidateGenerated != null:
return localIceCandidateGenerated(_that.candidate);case CallRemoteStreamReceived() when remoteStreamReceived != null:
return remoteStreamReceived(_that.stream);case CallGroupRemoteStreamsChanged() when groupRemoteStreamsChanged != null:
return groupRemoteStreamsChanged();case CallPeerConnectionStateChanged() when peerConnectionStateChanged != null:
return peerConnectionStateChanged(_that.state);case CallTicked() when tick != null:
return tick();case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  signalingStarted,required TResult Function( String calleeId,  bool isVideo)  outgoingCallRequested,required TResult Function( List<String> participantIds)  groupCallRequested,required TResult Function()  acceptRequested,required TResult Function()  rejectRequested,required TResult Function()  endRequested,required TResult Function()  muteToggled,required TResult Function()  cameraToggled,required TResult Function()  switchCameraRequested,required TResult Function()  speakerToggled,required TResult Function( String deviceId,  bool isSpeaker)  audioOutputSelected,required TResult Function( String roomId)  ringTimedOut,required TResult Function( SignalingMessage message)  signalingMessageReceived,required TResult Function( RTCIceCandidate candidate)  localIceCandidateGenerated,required TResult Function( MediaStream stream)  remoteStreamReceived,required TResult Function()  groupRemoteStreamsChanged,required TResult Function( RTCPeerConnectionState state)  peerConnectionStateChanged,required TResult Function()  tick,}) {final _that = this;
switch (_that) {
case CallSignalingStarted():
return signalingStarted();case CallOutgoingRequested():
return outgoingCallRequested(_that.calleeId,_that.isVideo);case CallGroupRequested():
return groupCallRequested(_that.participantIds);case CallAcceptRequested():
return acceptRequested();case CallRejectRequested():
return rejectRequested();case CallEndRequested():
return endRequested();case CallMuteToggled():
return muteToggled();case CallCameraToggled():
return cameraToggled();case CallSwitchCameraRequested():
return switchCameraRequested();case CallSpeakerToggled():
return speakerToggled();case CallAudioOutputSelected():
return audioOutputSelected(_that.deviceId,_that.isSpeaker);case CallRingTimedOut():
return ringTimedOut(_that.roomId);case CallSignalingMessageReceived():
return signalingMessageReceived(_that.message);case CallLocalIceCandidateGenerated():
return localIceCandidateGenerated(_that.candidate);case CallRemoteStreamReceived():
return remoteStreamReceived(_that.stream);case CallGroupRemoteStreamsChanged():
return groupRemoteStreamsChanged();case CallPeerConnectionStateChanged():
return peerConnectionStateChanged(_that.state);case CallTicked():
return tick();}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  signalingStarted,TResult? Function( String calleeId,  bool isVideo)?  outgoingCallRequested,TResult? Function( List<String> participantIds)?  groupCallRequested,TResult? Function()?  acceptRequested,TResult? Function()?  rejectRequested,TResult? Function()?  endRequested,TResult? Function()?  muteToggled,TResult? Function()?  cameraToggled,TResult? Function()?  switchCameraRequested,TResult? Function()?  speakerToggled,TResult? Function( String deviceId,  bool isSpeaker)?  audioOutputSelected,TResult? Function( String roomId)?  ringTimedOut,TResult? Function( SignalingMessage message)?  signalingMessageReceived,TResult? Function( RTCIceCandidate candidate)?  localIceCandidateGenerated,TResult? Function( MediaStream stream)?  remoteStreamReceived,TResult? Function()?  groupRemoteStreamsChanged,TResult? Function( RTCPeerConnectionState state)?  peerConnectionStateChanged,TResult? Function()?  tick,}) {final _that = this;
switch (_that) {
case CallSignalingStarted() when signalingStarted != null:
return signalingStarted();case CallOutgoingRequested() when outgoingCallRequested != null:
return outgoingCallRequested(_that.calleeId,_that.isVideo);case CallGroupRequested() when groupCallRequested != null:
return groupCallRequested(_that.participantIds);case CallAcceptRequested() when acceptRequested != null:
return acceptRequested();case CallRejectRequested() when rejectRequested != null:
return rejectRequested();case CallEndRequested() when endRequested != null:
return endRequested();case CallMuteToggled() when muteToggled != null:
return muteToggled();case CallCameraToggled() when cameraToggled != null:
return cameraToggled();case CallSwitchCameraRequested() when switchCameraRequested != null:
return switchCameraRequested();case CallSpeakerToggled() when speakerToggled != null:
return speakerToggled();case CallAudioOutputSelected() when audioOutputSelected != null:
return audioOutputSelected(_that.deviceId,_that.isSpeaker);case CallRingTimedOut() when ringTimedOut != null:
return ringTimedOut(_that.roomId);case CallSignalingMessageReceived() when signalingMessageReceived != null:
return signalingMessageReceived(_that.message);case CallLocalIceCandidateGenerated() when localIceCandidateGenerated != null:
return localIceCandidateGenerated(_that.candidate);case CallRemoteStreamReceived() when remoteStreamReceived != null:
return remoteStreamReceived(_that.stream);case CallGroupRemoteStreamsChanged() when groupRemoteStreamsChanged != null:
return groupRemoteStreamsChanged();case CallPeerConnectionStateChanged() when peerConnectionStateChanged != null:
return peerConnectionStateChanged(_that.state);case CallTicked() when tick != null:
return tick();case _:
  return null;

}
}

}

/// @nodoc


class CallSignalingStarted implements CallEvent {
  const CallSignalingStarted();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CallSignalingStarted);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CallEvent.signalingStarted()';
}


}




/// @nodoc


class CallOutgoingRequested implements CallEvent {
  const CallOutgoingRequested({required this.calleeId, required this.isVideo});
  

 final  String calleeId;
 final  bool isVideo;

/// Create a copy of CallEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CallOutgoingRequestedCopyWith<CallOutgoingRequested> get copyWith => _$CallOutgoingRequestedCopyWithImpl<CallOutgoingRequested>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CallOutgoingRequested&&(identical(other.calleeId, calleeId) || other.calleeId == calleeId)&&(identical(other.isVideo, isVideo) || other.isVideo == isVideo));
}


@override
int get hashCode => Object.hash(runtimeType,calleeId,isVideo);

@override
String toString() {
  return 'CallEvent.outgoingCallRequested(calleeId: $calleeId, isVideo: $isVideo)';
}


}

/// @nodoc
abstract mixin class $CallOutgoingRequestedCopyWith<$Res> implements $CallEventCopyWith<$Res> {
  factory $CallOutgoingRequestedCopyWith(CallOutgoingRequested value, $Res Function(CallOutgoingRequested) _then) = _$CallOutgoingRequestedCopyWithImpl;
@useResult
$Res call({
 String calleeId, bool isVideo
});




}
/// @nodoc
class _$CallOutgoingRequestedCopyWithImpl<$Res>
    implements $CallOutgoingRequestedCopyWith<$Res> {
  _$CallOutgoingRequestedCopyWithImpl(this._self, this._then);

  final CallOutgoingRequested _self;
  final $Res Function(CallOutgoingRequested) _then;

/// Create a copy of CallEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? calleeId = null,Object? isVideo = null,}) {
  return _then(CallOutgoingRequested(
calleeId: null == calleeId ? _self.calleeId : calleeId // ignore: cast_nullable_to_non_nullable
as String,isVideo: null == isVideo ? _self.isVideo : isVideo // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class CallGroupRequested implements CallEvent {
  const CallGroupRequested({required  List<String> participantIds}): _participantIds = participantIds;
  

 final  List<String> _participantIds;
 List<String> get participantIds {
  if (_participantIds is EqualUnmodifiableListView) return _participantIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_participantIds);
}


/// Create a copy of CallEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CallGroupRequestedCopyWith<CallGroupRequested> get copyWith => _$CallGroupRequestedCopyWithImpl<CallGroupRequested>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CallGroupRequested&&const DeepCollectionEquality().equals(other._participantIds, _participantIds));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_participantIds));

@override
String toString() {
  return 'CallEvent.groupCallRequested(participantIds: $participantIds)';
}


}

/// @nodoc
abstract mixin class $CallGroupRequestedCopyWith<$Res> implements $CallEventCopyWith<$Res> {
  factory $CallGroupRequestedCopyWith(CallGroupRequested value, $Res Function(CallGroupRequested) _then) = _$CallGroupRequestedCopyWithImpl;
@useResult
$Res call({
 List<String> participantIds
});




}
/// @nodoc
class _$CallGroupRequestedCopyWithImpl<$Res>
    implements $CallGroupRequestedCopyWith<$Res> {
  _$CallGroupRequestedCopyWithImpl(this._self, this._then);

  final CallGroupRequested _self;
  final $Res Function(CallGroupRequested) _then;

/// Create a copy of CallEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? participantIds = null,}) {
  return _then(CallGroupRequested(
participantIds: null == participantIds ? _self._participantIds : participantIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

/// @nodoc


class CallAcceptRequested implements CallEvent {
  const CallAcceptRequested();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CallAcceptRequested);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CallEvent.acceptRequested()';
}


}




/// @nodoc


class CallRejectRequested implements CallEvent {
  const CallRejectRequested();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CallRejectRequested);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CallEvent.rejectRequested()';
}


}




/// @nodoc


class CallEndRequested implements CallEvent {
  const CallEndRequested();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CallEndRequested);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CallEvent.endRequested()';
}


}




/// @nodoc


class CallMuteToggled implements CallEvent {
  const CallMuteToggled();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CallMuteToggled);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CallEvent.muteToggled()';
}


}




/// @nodoc


class CallCameraToggled implements CallEvent {
  const CallCameraToggled();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CallCameraToggled);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CallEvent.cameraToggled()';
}


}




/// @nodoc


class CallSwitchCameraRequested implements CallEvent {
  const CallSwitchCameraRequested();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CallSwitchCameraRequested);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CallEvent.switchCameraRequested()';
}


}




/// @nodoc


class CallSpeakerToggled implements CallEvent {
  const CallSpeakerToggled();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CallSpeakerToggled);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CallEvent.speakerToggled()';
}


}




/// @nodoc


class CallAudioOutputSelected implements CallEvent {
  const CallAudioOutputSelected({required this.deviceId, required this.isSpeaker});
  

 final  String deviceId;
 final  bool isSpeaker;

/// Create a copy of CallEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CallAudioOutputSelectedCopyWith<CallAudioOutputSelected> get copyWith => _$CallAudioOutputSelectedCopyWithImpl<CallAudioOutputSelected>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CallAudioOutputSelected&&(identical(other.deviceId, deviceId) || other.deviceId == deviceId)&&(identical(other.isSpeaker, isSpeaker) || other.isSpeaker == isSpeaker));
}


@override
int get hashCode => Object.hash(runtimeType,deviceId,isSpeaker);

@override
String toString() {
  return 'CallEvent.audioOutputSelected(deviceId: $deviceId, isSpeaker: $isSpeaker)';
}


}

/// @nodoc
abstract mixin class $CallAudioOutputSelectedCopyWith<$Res> implements $CallEventCopyWith<$Res> {
  factory $CallAudioOutputSelectedCopyWith(CallAudioOutputSelected value, $Res Function(CallAudioOutputSelected) _then) = _$CallAudioOutputSelectedCopyWithImpl;
@useResult
$Res call({
 String deviceId, bool isSpeaker
});




}
/// @nodoc
class _$CallAudioOutputSelectedCopyWithImpl<$Res>
    implements $CallAudioOutputSelectedCopyWith<$Res> {
  _$CallAudioOutputSelectedCopyWithImpl(this._self, this._then);

  final CallAudioOutputSelected _self;
  final $Res Function(CallAudioOutputSelected) _then;

/// Create a copy of CallEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? deviceId = null,Object? isSpeaker = null,}) {
  return _then(CallAudioOutputSelected(
deviceId: null == deviceId ? _self.deviceId : deviceId // ignore: cast_nullable_to_non_nullable
as String,isSpeaker: null == isSpeaker ? _self.isSpeaker : isSpeaker // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class CallRingTimedOut implements CallEvent {
  const CallRingTimedOut(this.roomId);
  

 final  String roomId;

/// Create a copy of CallEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CallRingTimedOutCopyWith<CallRingTimedOut> get copyWith => _$CallRingTimedOutCopyWithImpl<CallRingTimedOut>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CallRingTimedOut&&(identical(other.roomId, roomId) || other.roomId == roomId));
}


@override
int get hashCode => Object.hash(runtimeType,roomId);

@override
String toString() {
  return 'CallEvent.ringTimedOut(roomId: $roomId)';
}


}

/// @nodoc
abstract mixin class $CallRingTimedOutCopyWith<$Res> implements $CallEventCopyWith<$Res> {
  factory $CallRingTimedOutCopyWith(CallRingTimedOut value, $Res Function(CallRingTimedOut) _then) = _$CallRingTimedOutCopyWithImpl;
@useResult
$Res call({
 String roomId
});




}
/// @nodoc
class _$CallRingTimedOutCopyWithImpl<$Res>
    implements $CallRingTimedOutCopyWith<$Res> {
  _$CallRingTimedOutCopyWithImpl(this._self, this._then);

  final CallRingTimedOut _self;
  final $Res Function(CallRingTimedOut) _then;

/// Create a copy of CallEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? roomId = null,}) {
  return _then(CallRingTimedOut(
null == roomId ? _self.roomId : roomId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class CallSignalingMessageReceived implements CallEvent {
  const CallSignalingMessageReceived(this.message);
  

 final  SignalingMessage message;

/// Create a copy of CallEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CallSignalingMessageReceivedCopyWith<CallSignalingMessageReceived> get copyWith => _$CallSignalingMessageReceivedCopyWithImpl<CallSignalingMessageReceived>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CallSignalingMessageReceived&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'CallEvent.signalingMessageReceived(message: $message)';
}


}

/// @nodoc
abstract mixin class $CallSignalingMessageReceivedCopyWith<$Res> implements $CallEventCopyWith<$Res> {
  factory $CallSignalingMessageReceivedCopyWith(CallSignalingMessageReceived value, $Res Function(CallSignalingMessageReceived) _then) = _$CallSignalingMessageReceivedCopyWithImpl;
@useResult
$Res call({
 SignalingMessage message
});




}
/// @nodoc
class _$CallSignalingMessageReceivedCopyWithImpl<$Res>
    implements $CallSignalingMessageReceivedCopyWith<$Res> {
  _$CallSignalingMessageReceivedCopyWithImpl(this._self, this._then);

  final CallSignalingMessageReceived _self;
  final $Res Function(CallSignalingMessageReceived) _then;

/// Create a copy of CallEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(CallSignalingMessageReceived(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as SignalingMessage,
  ));
}


}

/// @nodoc


class CallLocalIceCandidateGenerated implements CallEvent {
  const CallLocalIceCandidateGenerated(this.candidate);
  

 final  RTCIceCandidate candidate;

/// Create a copy of CallEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CallLocalIceCandidateGeneratedCopyWith<CallLocalIceCandidateGenerated> get copyWith => _$CallLocalIceCandidateGeneratedCopyWithImpl<CallLocalIceCandidateGenerated>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CallLocalIceCandidateGenerated&&(identical(other.candidate, candidate) || other.candidate == candidate));
}


@override
int get hashCode => Object.hash(runtimeType,candidate);

@override
String toString() {
  return 'CallEvent.localIceCandidateGenerated(candidate: $candidate)';
}


}

/// @nodoc
abstract mixin class $CallLocalIceCandidateGeneratedCopyWith<$Res> implements $CallEventCopyWith<$Res> {
  factory $CallLocalIceCandidateGeneratedCopyWith(CallLocalIceCandidateGenerated value, $Res Function(CallLocalIceCandidateGenerated) _then) = _$CallLocalIceCandidateGeneratedCopyWithImpl;
@useResult
$Res call({
 RTCIceCandidate candidate
});




}
/// @nodoc
class _$CallLocalIceCandidateGeneratedCopyWithImpl<$Res>
    implements $CallLocalIceCandidateGeneratedCopyWith<$Res> {
  _$CallLocalIceCandidateGeneratedCopyWithImpl(this._self, this._then);

  final CallLocalIceCandidateGenerated _self;
  final $Res Function(CallLocalIceCandidateGenerated) _then;

/// Create a copy of CallEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? candidate = null,}) {
  return _then(CallLocalIceCandidateGenerated(
null == candidate ? _self.candidate : candidate // ignore: cast_nullable_to_non_nullable
as RTCIceCandidate,
  ));
}


}

/// @nodoc


class CallRemoteStreamReceived implements CallEvent {
  const CallRemoteStreamReceived(this.stream);
  

 final  MediaStream stream;

/// Create a copy of CallEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CallRemoteStreamReceivedCopyWith<CallRemoteStreamReceived> get copyWith => _$CallRemoteStreamReceivedCopyWithImpl<CallRemoteStreamReceived>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CallRemoteStreamReceived&&(identical(other.stream, stream) || other.stream == stream));
}


@override
int get hashCode => Object.hash(runtimeType,stream);

@override
String toString() {
  return 'CallEvent.remoteStreamReceived(stream: $stream)';
}


}

/// @nodoc
abstract mixin class $CallRemoteStreamReceivedCopyWith<$Res> implements $CallEventCopyWith<$Res> {
  factory $CallRemoteStreamReceivedCopyWith(CallRemoteStreamReceived value, $Res Function(CallRemoteStreamReceived) _then) = _$CallRemoteStreamReceivedCopyWithImpl;
@useResult
$Res call({
 MediaStream stream
});




}
/// @nodoc
class _$CallRemoteStreamReceivedCopyWithImpl<$Res>
    implements $CallRemoteStreamReceivedCopyWith<$Res> {
  _$CallRemoteStreamReceivedCopyWithImpl(this._self, this._then);

  final CallRemoteStreamReceived _self;
  final $Res Function(CallRemoteStreamReceived) _then;

/// Create a copy of CallEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? stream = null,}) {
  return _then(CallRemoteStreamReceived(
null == stream ? _self.stream : stream // ignore: cast_nullable_to_non_nullable
as MediaStream,
  ));
}


}

/// @nodoc


class CallGroupRemoteStreamsChanged implements CallEvent {
  const CallGroupRemoteStreamsChanged();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CallGroupRemoteStreamsChanged);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CallEvent.groupRemoteStreamsChanged()';
}


}




/// @nodoc


class CallPeerConnectionStateChanged implements CallEvent {
  const CallPeerConnectionStateChanged(this.state);
  

 final  RTCPeerConnectionState state;

/// Create a copy of CallEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CallPeerConnectionStateChangedCopyWith<CallPeerConnectionStateChanged> get copyWith => _$CallPeerConnectionStateChangedCopyWithImpl<CallPeerConnectionStateChanged>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CallPeerConnectionStateChanged&&(identical(other.state, state) || other.state == state));
}


@override
int get hashCode => Object.hash(runtimeType,state);

@override
String toString() {
  return 'CallEvent.peerConnectionStateChanged(state: $state)';
}


}

/// @nodoc
abstract mixin class $CallPeerConnectionStateChangedCopyWith<$Res> implements $CallEventCopyWith<$Res> {
  factory $CallPeerConnectionStateChangedCopyWith(CallPeerConnectionStateChanged value, $Res Function(CallPeerConnectionStateChanged) _then) = _$CallPeerConnectionStateChangedCopyWithImpl;
@useResult
$Res call({
 RTCPeerConnectionState state
});




}
/// @nodoc
class _$CallPeerConnectionStateChangedCopyWithImpl<$Res>
    implements $CallPeerConnectionStateChangedCopyWith<$Res> {
  _$CallPeerConnectionStateChangedCopyWithImpl(this._self, this._then);

  final CallPeerConnectionStateChanged _self;
  final $Res Function(CallPeerConnectionStateChanged) _then;

/// Create a copy of CallEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? state = null,}) {
  return _then(CallPeerConnectionStateChanged(
null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as RTCPeerConnectionState,
  ));
}


}

/// @nodoc


class CallTicked implements CallEvent {
  const CallTicked();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CallTicked);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CallEvent.tick()';
}


}




/// @nodoc
mixin _$CallState {

 CallStatus get status; String? get roomId; String? get peerId; String get callType; bool get isMuted; bool get isCameraOff; bool get isSpeakerOn; String get callMode; List<String> get participantIds; bool get isSignalingConnected; String? get errorMessage; Duration get elapsed;/// SDP offer nhận được (chưa xử lý tới khi user bấm Accept) — không
/// đưa MediaStream/RTCPeerConnection vào state để tránh so sánh
/// Equatable trên object không immutable; CallBloc giữ chúng riêng
/// (truy cập qua CallBloc.localStream/remoteStream).
 String? get pendingRemoteOfferSdp;/// Tăng dần mỗi khi remote MediaStream mới sẵn sàng — UI dùng làm tín
/// hiệu để đọc lại CallBloc.remoteStream và gán vào RTCVideoRenderer,
/// vì bản thân MediaStream không nằm trong state (xem ghi chú trên).
 int get remoteStreamTick;
/// Create a copy of CallState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CallStateCopyWith<CallState> get copyWith => _$CallStateCopyWithImpl<CallState>(this as CallState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CallState&&(identical(other.status, status) || other.status == status)&&(identical(other.roomId, roomId) || other.roomId == roomId)&&(identical(other.peerId, peerId) || other.peerId == peerId)&&(identical(other.callType, callType) || other.callType == callType)&&(identical(other.isMuted, isMuted) || other.isMuted == isMuted)&&(identical(other.isCameraOff, isCameraOff) || other.isCameraOff == isCameraOff)&&(identical(other.isSpeakerOn, isSpeakerOn) || other.isSpeakerOn == isSpeakerOn)&&(identical(other.callMode, callMode) || other.callMode == callMode)&&const DeepCollectionEquality().equals(other.participantIds, participantIds)&&(identical(other.isSignalingConnected, isSignalingConnected) || other.isSignalingConnected == isSignalingConnected)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.elapsed, elapsed) || other.elapsed == elapsed)&&(identical(other.pendingRemoteOfferSdp, pendingRemoteOfferSdp) || other.pendingRemoteOfferSdp == pendingRemoteOfferSdp)&&(identical(other.remoteStreamTick, remoteStreamTick) || other.remoteStreamTick == remoteStreamTick));
}


@override
int get hashCode => Object.hash(runtimeType,status,roomId,peerId,callType,isMuted,isCameraOff,isSpeakerOn,callMode,const DeepCollectionEquality().hash(participantIds),isSignalingConnected,errorMessage,elapsed,pendingRemoteOfferSdp,remoteStreamTick);

@override
String toString() {
  return 'CallState(status: $status, roomId: $roomId, peerId: $peerId, callType: $callType, isMuted: $isMuted, isCameraOff: $isCameraOff, isSpeakerOn: $isSpeakerOn, callMode: $callMode, participantIds: $participantIds, isSignalingConnected: $isSignalingConnected, errorMessage: $errorMessage, elapsed: $elapsed, pendingRemoteOfferSdp: $pendingRemoteOfferSdp, remoteStreamTick: $remoteStreamTick)';
}


}

/// @nodoc
abstract mixin class $CallStateCopyWith<$Res>  {
  factory $CallStateCopyWith(CallState value, $Res Function(CallState) _then) = _$CallStateCopyWithImpl;
@useResult
$Res call({
 CallStatus status, String? roomId, String? peerId, String callType, bool isMuted, bool isCameraOff, bool isSpeakerOn, String callMode, List<String> participantIds, bool isSignalingConnected, String? errorMessage, Duration elapsed, String? pendingRemoteOfferSdp, int remoteStreamTick
});




}
/// @nodoc
class _$CallStateCopyWithImpl<$Res>
    implements $CallStateCopyWith<$Res> {
  _$CallStateCopyWithImpl(this._self, this._then);

  final CallState _self;
  final $Res Function(CallState) _then;

/// Create a copy of CallState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? roomId = freezed,Object? peerId = freezed,Object? callType = null,Object? isMuted = null,Object? isCameraOff = null,Object? isSpeakerOn = null,Object? callMode = null,Object? participantIds = null,Object? isSignalingConnected = null,Object? errorMessage = freezed,Object? elapsed = null,Object? pendingRemoteOfferSdp = freezed,Object? remoteStreamTick = null,}) {
  return _then(CallState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as CallStatus,roomId: freezed == roomId ? _self.roomId : roomId // ignore: cast_nullable_to_non_nullable
as String?,peerId: freezed == peerId ? _self.peerId : peerId // ignore: cast_nullable_to_non_nullable
as String?,callType: null == callType ? _self.callType : callType // ignore: cast_nullable_to_non_nullable
as String,isMuted: null == isMuted ? _self.isMuted : isMuted // ignore: cast_nullable_to_non_nullable
as bool,isCameraOff: null == isCameraOff ? _self.isCameraOff : isCameraOff // ignore: cast_nullable_to_non_nullable
as bool,isSpeakerOn: null == isSpeakerOn ? _self.isSpeakerOn : isSpeakerOn // ignore: cast_nullable_to_non_nullable
as bool,callMode: null == callMode ? _self.callMode : callMode // ignore: cast_nullable_to_non_nullable
as String,participantIds: null == participantIds ? _self.participantIds : participantIds // ignore: cast_nullable_to_non_nullable
as List<String>,isSignalingConnected: null == isSignalingConnected ? _self.isSignalingConnected : isSignalingConnected // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,elapsed: null == elapsed ? _self.elapsed : elapsed // ignore: cast_nullable_to_non_nullable
as Duration,pendingRemoteOfferSdp: freezed == pendingRemoteOfferSdp ? _self.pendingRemoteOfferSdp : pendingRemoteOfferSdp // ignore: cast_nullable_to_non_nullable
as String?,remoteStreamTick: null == remoteStreamTick ? _self.remoteStreamTick : remoteStreamTick // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [CallState].
extension CallStatePatterns on CallState {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CallState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CallState() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CallState value)  $default,){
final _that = this;
switch (_that) {
case _CallState():
return $default(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CallState value)?  $default,){
final _that = this;
switch (_that) {
case _CallState() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( CallStatus status,  String? roomId,  String? peerId,  String callType,  bool isMuted,  bool isCameraOff,  bool isSpeakerOn,  String callMode,  List<String> participantIds,  bool isSignalingConnected,  String? errorMessage,  Duration elapsed,  String? pendingRemoteOfferSdp,  int remoteStreamTick)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CallState() when $default != null:
return $default(_that.status,_that.roomId,_that.peerId,_that.callType,_that.isMuted,_that.isCameraOff,_that.isSpeakerOn,_that.callMode,_that.participantIds,_that.isSignalingConnected,_that.errorMessage,_that.elapsed,_that.pendingRemoteOfferSdp,_that.remoteStreamTick);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( CallStatus status,  String? roomId,  String? peerId,  String callType,  bool isMuted,  bool isCameraOff,  bool isSpeakerOn,  String callMode,  List<String> participantIds,  bool isSignalingConnected,  String? errorMessage,  Duration elapsed,  String? pendingRemoteOfferSdp,  int remoteStreamTick)  $default,) {final _that = this;
switch (_that) {
case _CallState():
return $default(_that.status,_that.roomId,_that.peerId,_that.callType,_that.isMuted,_that.isCameraOff,_that.isSpeakerOn,_that.callMode,_that.participantIds,_that.isSignalingConnected,_that.errorMessage,_that.elapsed,_that.pendingRemoteOfferSdp,_that.remoteStreamTick);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( CallStatus status,  String? roomId,  String? peerId,  String callType,  bool isMuted,  bool isCameraOff,  bool isSpeakerOn,  String callMode,  List<String> participantIds,  bool isSignalingConnected,  String? errorMessage,  Duration elapsed,  String? pendingRemoteOfferSdp,  int remoteStreamTick)?  $default,) {final _that = this;
switch (_that) {
case _CallState() when $default != null:
return $default(_that.status,_that.roomId,_that.peerId,_that.callType,_that.isMuted,_that.isCameraOff,_that.isSpeakerOn,_that.callMode,_that.participantIds,_that.isSignalingConnected,_that.errorMessage,_that.elapsed,_that.pendingRemoteOfferSdp,_that.remoteStreamTick);case _:
  return null;

}
}

}

/// @nodoc


class _CallState implements CallState {
  const _CallState({this.status = CallStatus.idle, this.roomId, this.peerId, this.callType = 'audio', this.isMuted = false, this.isCameraOff = false, this.isSpeakerOn = false, this.callMode = 'direct',  List<String> participantIds = const <String>[], this.isSignalingConnected = false, this.errorMessage, this.elapsed = Duration.zero, this.pendingRemoteOfferSdp, this.remoteStreamTick = 0}): _participantIds = participantIds;
  

@override@JsonKey() final  CallStatus status;
@override final  String? roomId;
@override final  String? peerId;
@override@JsonKey() final  String callType;
@override@JsonKey() final  bool isMuted;
@override@JsonKey() final  bool isCameraOff;
@override@JsonKey() final  bool isSpeakerOn;
@override@JsonKey() final  String callMode;
 final  List<String> _participantIds;
@override@JsonKey() List<String> get participantIds {
  if (_participantIds is EqualUnmodifiableListView) return _participantIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_participantIds);
}

@override@JsonKey() final  bool isSignalingConnected;
@override final  String? errorMessage;
@override@JsonKey() final  Duration elapsed;
/// SDP offer nhận được (chưa xử lý tới khi user bấm Accept) — không
/// đưa MediaStream/RTCPeerConnection vào state để tránh so sánh
/// Equatable trên object không immutable; CallBloc giữ chúng riêng
/// (truy cập qua CallBloc.localStream/remoteStream).
@override final  String? pendingRemoteOfferSdp;
/// Tăng dần mỗi khi remote MediaStream mới sẵn sàng — UI dùng làm tín
/// hiệu để đọc lại CallBloc.remoteStream và gán vào RTCVideoRenderer,
/// vì bản thân MediaStream không nằm trong state (xem ghi chú trên).
@override@JsonKey() final  int remoteStreamTick;

/// Create a copy of CallState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CallStateCopyWith<_CallState> get copyWith => __$CallStateCopyWithImpl<_CallState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CallState&&(identical(other.status, status) || other.status == status)&&(identical(other.roomId, roomId) || other.roomId == roomId)&&(identical(other.peerId, peerId) || other.peerId == peerId)&&(identical(other.callType, callType) || other.callType == callType)&&(identical(other.isMuted, isMuted) || other.isMuted == isMuted)&&(identical(other.isCameraOff, isCameraOff) || other.isCameraOff == isCameraOff)&&(identical(other.isSpeakerOn, isSpeakerOn) || other.isSpeakerOn == isSpeakerOn)&&(identical(other.callMode, callMode) || other.callMode == callMode)&&const DeepCollectionEquality().equals(other._participantIds, _participantIds)&&(identical(other.isSignalingConnected, isSignalingConnected) || other.isSignalingConnected == isSignalingConnected)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.elapsed, elapsed) || other.elapsed == elapsed)&&(identical(other.pendingRemoteOfferSdp, pendingRemoteOfferSdp) || other.pendingRemoteOfferSdp == pendingRemoteOfferSdp)&&(identical(other.remoteStreamTick, remoteStreamTick) || other.remoteStreamTick == remoteStreamTick));
}


@override
int get hashCode => Object.hash(runtimeType,status,roomId,peerId,callType,isMuted,isCameraOff,isSpeakerOn,callMode,const DeepCollectionEquality().hash(_participantIds),isSignalingConnected,errorMessage,elapsed,pendingRemoteOfferSdp,remoteStreamTick);

@override
String toString() {
  return 'CallState(status: $status, roomId: $roomId, peerId: $peerId, callType: $callType, isMuted: $isMuted, isCameraOff: $isCameraOff, isSpeakerOn: $isSpeakerOn, callMode: $callMode, participantIds: $participantIds, isSignalingConnected: $isSignalingConnected, errorMessage: $errorMessage, elapsed: $elapsed, pendingRemoteOfferSdp: $pendingRemoteOfferSdp, remoteStreamTick: $remoteStreamTick)';
}


}

/// @nodoc
abstract mixin class _$CallStateCopyWith<$Res> implements $CallStateCopyWith<$Res> {
  factory _$CallStateCopyWith(_CallState value, $Res Function(_CallState) _then) = __$CallStateCopyWithImpl;
@override @useResult
$Res call({
 CallStatus status, String? roomId, String? peerId, String callType, bool isMuted, bool isCameraOff, bool isSpeakerOn, String callMode, List<String> participantIds, bool isSignalingConnected, String? errorMessage, Duration elapsed, String? pendingRemoteOfferSdp, int remoteStreamTick
});




}
/// @nodoc
class __$CallStateCopyWithImpl<$Res>
    implements _$CallStateCopyWith<$Res> {
  __$CallStateCopyWithImpl(this._self, this._then);

  final _CallState _self;
  final $Res Function(_CallState) _then;

/// Create a copy of CallState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? roomId = freezed,Object? peerId = freezed,Object? callType = null,Object? isMuted = null,Object? isCameraOff = null,Object? isSpeakerOn = null,Object? callMode = null,Object? participantIds = null,Object? isSignalingConnected = null,Object? errorMessage = freezed,Object? elapsed = null,Object? pendingRemoteOfferSdp = freezed,Object? remoteStreamTick = null,}) {
  return _then(_CallState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as CallStatus,roomId: freezed == roomId ? _self.roomId : roomId // ignore: cast_nullable_to_non_nullable
as String?,peerId: freezed == peerId ? _self.peerId : peerId // ignore: cast_nullable_to_non_nullable
as String?,callType: null == callType ? _self.callType : callType // ignore: cast_nullable_to_non_nullable
as String,isMuted: null == isMuted ? _self.isMuted : isMuted // ignore: cast_nullable_to_non_nullable
as bool,isCameraOff: null == isCameraOff ? _self.isCameraOff : isCameraOff // ignore: cast_nullable_to_non_nullable
as bool,isSpeakerOn: null == isSpeakerOn ? _self.isSpeakerOn : isSpeakerOn // ignore: cast_nullable_to_non_nullable
as bool,callMode: null == callMode ? _self.callMode : callMode // ignore: cast_nullable_to_non_nullable
as String,participantIds: null == participantIds ? _self._participantIds : participantIds // ignore: cast_nullable_to_non_nullable
as List<String>,isSignalingConnected: null == isSignalingConnected ? _self.isSignalingConnected : isSignalingConnected // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,elapsed: null == elapsed ? _self.elapsed : elapsed // ignore: cast_nullable_to_non_nullable
as Duration,pendingRemoteOfferSdp: freezed == pendingRemoteOfferSdp ? _self.pendingRemoteOfferSdp : pendingRemoteOfferSdp // ignore: cast_nullable_to_non_nullable
as String?,remoteStreamTick: null == remoteStreamTick ? _self.remoteStreamTick : remoteStreamTick // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
