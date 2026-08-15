// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'conversations_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ConversationsEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConversationsEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ConversationsEvent()';
}


}

/// @nodoc
class $ConversationsEventCopyWith<$Res>  {
$ConversationsEventCopyWith(ConversationsEvent _, $Res Function(ConversationsEvent) __);
}


/// Adds pattern-matching-related methods to [ConversationsEvent].
extension ConversationsEventPatterns on ConversationsEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ConversationsStarted value)?  started,TResult Function( ConversationsRefreshed value)?  refreshed,TResult Function( ConversationsLoadMoreRequested value)?  loadMoreRequested,TResult Function( ConversationsMessageArrived value)?  messageArrived,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ConversationsStarted() when started != null:
return started(_that);case ConversationsRefreshed() when refreshed != null:
return refreshed(_that);case ConversationsLoadMoreRequested() when loadMoreRequested != null:
return loadMoreRequested(_that);case ConversationsMessageArrived() when messageArrived != null:
return messageArrived(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ConversationsStarted value)  started,required TResult Function( ConversationsRefreshed value)  refreshed,required TResult Function( ConversationsLoadMoreRequested value)  loadMoreRequested,required TResult Function( ConversationsMessageArrived value)  messageArrived,}){
final _that = this;
switch (_that) {
case ConversationsStarted():
return started(_that);case ConversationsRefreshed():
return refreshed(_that);case ConversationsLoadMoreRequested():
return loadMoreRequested(_that);case ConversationsMessageArrived():
return messageArrived(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ConversationsStarted value)?  started,TResult? Function( ConversationsRefreshed value)?  refreshed,TResult? Function( ConversationsLoadMoreRequested value)?  loadMoreRequested,TResult? Function( ConversationsMessageArrived value)?  messageArrived,}){
final _that = this;
switch (_that) {
case ConversationsStarted() when started != null:
return started(_that);case ConversationsRefreshed() when refreshed != null:
return refreshed(_that);case ConversationsLoadMoreRequested() when loadMoreRequested != null:
return loadMoreRequested(_that);case ConversationsMessageArrived() when messageArrived != null:
return messageArrived(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  started,TResult Function()?  refreshed,TResult Function()?  loadMoreRequested,TResult Function( ChatMessageEntity message)?  messageArrived,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ConversationsStarted() when started != null:
return started();case ConversationsRefreshed() when refreshed != null:
return refreshed();case ConversationsLoadMoreRequested() when loadMoreRequested != null:
return loadMoreRequested();case ConversationsMessageArrived() when messageArrived != null:
return messageArrived(_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  started,required TResult Function()  refreshed,required TResult Function()  loadMoreRequested,required TResult Function( ChatMessageEntity message)  messageArrived,}) {final _that = this;
switch (_that) {
case ConversationsStarted():
return started();case ConversationsRefreshed():
return refreshed();case ConversationsLoadMoreRequested():
return loadMoreRequested();case ConversationsMessageArrived():
return messageArrived(_that.message);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  started,TResult? Function()?  refreshed,TResult? Function()?  loadMoreRequested,TResult? Function( ChatMessageEntity message)?  messageArrived,}) {final _that = this;
switch (_that) {
case ConversationsStarted() when started != null:
return started();case ConversationsRefreshed() when refreshed != null:
return refreshed();case ConversationsLoadMoreRequested() when loadMoreRequested != null:
return loadMoreRequested();case ConversationsMessageArrived() when messageArrived != null:
return messageArrived(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class ConversationsStarted implements ConversationsEvent {
  const ConversationsStarted();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConversationsStarted);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ConversationsEvent.started()';
}


}




/// @nodoc


class ConversationsRefreshed implements ConversationsEvent {
  const ConversationsRefreshed();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConversationsRefreshed);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ConversationsEvent.refreshed()';
}


}




/// @nodoc


class ConversationsLoadMoreRequested implements ConversationsEvent {
  const ConversationsLoadMoreRequested();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConversationsLoadMoreRequested);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ConversationsEvent.loadMoreRequested()';
}


}




/// @nodoc


class ConversationsMessageArrived implements ConversationsEvent {
  const ConversationsMessageArrived(this.message);
  

 final  ChatMessageEntity message;

/// Create a copy of ConversationsEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConversationsMessageArrivedCopyWith<ConversationsMessageArrived> get copyWith => _$ConversationsMessageArrivedCopyWithImpl<ConversationsMessageArrived>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConversationsMessageArrived&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'ConversationsEvent.messageArrived(message: $message)';
}


}

/// @nodoc
abstract mixin class $ConversationsMessageArrivedCopyWith<$Res> implements $ConversationsEventCopyWith<$Res> {
  factory $ConversationsMessageArrivedCopyWith(ConversationsMessageArrived value, $Res Function(ConversationsMessageArrived) _then) = _$ConversationsMessageArrivedCopyWithImpl;
@useResult
$Res call({
 ChatMessageEntity message
});




}
/// @nodoc
class _$ConversationsMessageArrivedCopyWithImpl<$Res>
    implements $ConversationsMessageArrivedCopyWith<$Res> {
  _$ConversationsMessageArrivedCopyWithImpl(this._self, this._then);

  final ConversationsMessageArrived _self;
  final $Res Function(ConversationsMessageArrived) _then;

/// Create a copy of ConversationsEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(ConversationsMessageArrived(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as ChatMessageEntity,
  ));
}


}

/// @nodoc
mixin _$ConversationsState {

 ConversationsStatus get status; List<ConversationEntity>? get items; bool get hasReachedMax; String? get errorMessage;
/// Create a copy of ConversationsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConversationsStateCopyWith<ConversationsState> get copyWith => _$ConversationsStateCopyWithImpl<ConversationsState>(this as ConversationsState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConversationsState&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.hasReachedMax, hasReachedMax) || other.hasReachedMax == hasReachedMax)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,status,const DeepCollectionEquality().hash(items),hasReachedMax,errorMessage);

@override
String toString() {
  return 'ConversationsState(status: $status, items: $items, hasReachedMax: $hasReachedMax, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class $ConversationsStateCopyWith<$Res>  {
  factory $ConversationsStateCopyWith(ConversationsState value, $Res Function(ConversationsState) _then) = _$ConversationsStateCopyWithImpl;
@useResult
$Res call({
 ConversationsStatus status, List<ConversationEntity>? items, bool hasReachedMax, String? errorMessage
});




}
/// @nodoc
class _$ConversationsStateCopyWithImpl<$Res>
    implements $ConversationsStateCopyWith<$Res> {
  _$ConversationsStateCopyWithImpl(this._self, this._then);

  final ConversationsState _self;
  final $Res Function(ConversationsState) _then;

/// Create a copy of ConversationsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? items = freezed,Object? hasReachedMax = null,Object? errorMessage = freezed,}) {
  return _then(ConversationsState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ConversationsStatus,items: freezed == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<ConversationEntity>?,hasReachedMax: null == hasReachedMax ? _self.hasReachedMax : hasReachedMax // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ConversationsState].
extension ConversationsStatePatterns on ConversationsState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ConversationsState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ConversationsState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ConversationsState value)  $default,){
final _that = this;
switch (_that) {
case _ConversationsState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ConversationsState value)?  $default,){
final _that = this;
switch (_that) {
case _ConversationsState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ConversationsStatus status,  List<ConversationEntity>? items,  bool hasReachedMax,  String? errorMessage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ConversationsState() when $default != null:
return $default(_that.status,_that.items,_that.hasReachedMax,_that.errorMessage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ConversationsStatus status,  List<ConversationEntity>? items,  bool hasReachedMax,  String? errorMessage)  $default,) {final _that = this;
switch (_that) {
case _ConversationsState():
return $default(_that.status,_that.items,_that.hasReachedMax,_that.errorMessage);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ConversationsStatus status,  List<ConversationEntity>? items,  bool hasReachedMax,  String? errorMessage)?  $default,) {final _that = this;
switch (_that) {
case _ConversationsState() when $default != null:
return $default(_that.status,_that.items,_that.hasReachedMax,_that.errorMessage);case _:
  return null;

}
}

}

/// @nodoc


class _ConversationsState implements ConversationsState {
  const _ConversationsState({this.status = ConversationsStatus.initial,  List<ConversationEntity>? items = const <ConversationEntity>[], this.hasReachedMax = false, this.errorMessage}): _items = items;
  

@override@JsonKey() final  ConversationsStatus status;
 final  List<ConversationEntity>? _items;
@override@JsonKey() List<ConversationEntity>? get items {
  final value = _items;
  if (value == null) return null;
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override@JsonKey() final  bool hasReachedMax;
@override final  String? errorMessage;

/// Create a copy of ConversationsState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConversationsStateCopyWith<_ConversationsState> get copyWith => __$ConversationsStateCopyWithImpl<_ConversationsState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ConversationsState&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.hasReachedMax, hasReachedMax) || other.hasReachedMax == hasReachedMax)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,status,const DeepCollectionEquality().hash(_items),hasReachedMax,errorMessage);

@override
String toString() {
  return 'ConversationsState(status: $status, items: $items, hasReachedMax: $hasReachedMax, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class _$ConversationsStateCopyWith<$Res> implements $ConversationsStateCopyWith<$Res> {
  factory _$ConversationsStateCopyWith(_ConversationsState value, $Res Function(_ConversationsState) _then) = __$ConversationsStateCopyWithImpl;
@override @useResult
$Res call({
 ConversationsStatus status, List<ConversationEntity>? items, bool hasReachedMax, String? errorMessage
});




}
/// @nodoc
class __$ConversationsStateCopyWithImpl<$Res>
    implements _$ConversationsStateCopyWith<$Res> {
  __$ConversationsStateCopyWithImpl(this._self, this._then);

  final _ConversationsState _self;
  final $Res Function(_ConversationsState) _then;

/// Create a copy of ConversationsState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? items = freezed,Object? hasReachedMax = null,Object? errorMessage = freezed,}) {
  return _then(_ConversationsState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ConversationsStatus,items: freezed == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<ConversationEntity>?,hasReachedMax: null == hasReachedMax ? _self.hasReachedMax : hasReachedMax // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
