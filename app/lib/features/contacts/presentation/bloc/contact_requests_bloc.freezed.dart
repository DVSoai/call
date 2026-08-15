// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'contact_requests_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ContactRequestsEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ContactRequestsEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ContactRequestsEvent()';
}


}

/// @nodoc
class $ContactRequestsEventCopyWith<$Res>  {
$ContactRequestsEventCopyWith(ContactRequestsEvent _, $Res Function(ContactRequestsEvent) __);
}


/// Adds pattern-matching-related methods to [ContactRequestsEvent].
extension ContactRequestsEventPatterns on ContactRequestsEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ContactRequestsStarted value)?  started,TResult Function( ContactRequestsRefreshed value)?  refreshed,TResult Function( ContactRequestsResponded value)?  responded,TResult Function( ContactRequestsOutgoingCancelled value)?  outgoingCancelled,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ContactRequestsStarted() when started != null:
return started(_that);case ContactRequestsRefreshed() when refreshed != null:
return refreshed(_that);case ContactRequestsResponded() when responded != null:
return responded(_that);case ContactRequestsOutgoingCancelled() when outgoingCancelled != null:
return outgoingCancelled(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ContactRequestsStarted value)  started,required TResult Function( ContactRequestsRefreshed value)  refreshed,required TResult Function( ContactRequestsResponded value)  responded,required TResult Function( ContactRequestsOutgoingCancelled value)  outgoingCancelled,}){
final _that = this;
switch (_that) {
case ContactRequestsStarted():
return started(_that);case ContactRequestsRefreshed():
return refreshed(_that);case ContactRequestsResponded():
return responded(_that);case ContactRequestsOutgoingCancelled():
return outgoingCancelled(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ContactRequestsStarted value)?  started,TResult? Function( ContactRequestsRefreshed value)?  refreshed,TResult? Function( ContactRequestsResponded value)?  responded,TResult? Function( ContactRequestsOutgoingCancelled value)?  outgoingCancelled,}){
final _that = this;
switch (_that) {
case ContactRequestsStarted() when started != null:
return started(_that);case ContactRequestsRefreshed() when refreshed != null:
return refreshed(_that);case ContactRequestsResponded() when responded != null:
return responded(_that);case ContactRequestsOutgoingCancelled() when outgoingCancelled != null:
return outgoingCancelled(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  started,TResult Function()?  refreshed,TResult Function( String contactId,  bool accept)?  responded,TResult Function( String contactId)?  outgoingCancelled,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ContactRequestsStarted() when started != null:
return started();case ContactRequestsRefreshed() when refreshed != null:
return refreshed();case ContactRequestsResponded() when responded != null:
return responded(_that.contactId,_that.accept);case ContactRequestsOutgoingCancelled() when outgoingCancelled != null:
return outgoingCancelled(_that.contactId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  started,required TResult Function()  refreshed,required TResult Function( String contactId,  bool accept)  responded,required TResult Function( String contactId)  outgoingCancelled,}) {final _that = this;
switch (_that) {
case ContactRequestsStarted():
return started();case ContactRequestsRefreshed():
return refreshed();case ContactRequestsResponded():
return responded(_that.contactId,_that.accept);case ContactRequestsOutgoingCancelled():
return outgoingCancelled(_that.contactId);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  started,TResult? Function()?  refreshed,TResult? Function( String contactId,  bool accept)?  responded,TResult? Function( String contactId)?  outgoingCancelled,}) {final _that = this;
switch (_that) {
case ContactRequestsStarted() when started != null:
return started();case ContactRequestsRefreshed() when refreshed != null:
return refreshed();case ContactRequestsResponded() when responded != null:
return responded(_that.contactId,_that.accept);case ContactRequestsOutgoingCancelled() when outgoingCancelled != null:
return outgoingCancelled(_that.contactId);case _:
  return null;

}
}

}

/// @nodoc


class ContactRequestsStarted implements ContactRequestsEvent {
  const ContactRequestsStarted();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ContactRequestsStarted);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ContactRequestsEvent.started()';
}


}




/// @nodoc


class ContactRequestsRefreshed implements ContactRequestsEvent {
  const ContactRequestsRefreshed();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ContactRequestsRefreshed);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ContactRequestsEvent.refreshed()';
}


}




/// @nodoc


class ContactRequestsResponded implements ContactRequestsEvent {
  const ContactRequestsResponded({required this.contactId, required this.accept});
  

 final  String contactId;
 final  bool accept;

/// Create a copy of ContactRequestsEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ContactRequestsRespondedCopyWith<ContactRequestsResponded> get copyWith => _$ContactRequestsRespondedCopyWithImpl<ContactRequestsResponded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ContactRequestsResponded&&(identical(other.contactId, contactId) || other.contactId == contactId)&&(identical(other.accept, accept) || other.accept == accept));
}


@override
int get hashCode => Object.hash(runtimeType,contactId,accept);

@override
String toString() {
  return 'ContactRequestsEvent.responded(contactId: $contactId, accept: $accept)';
}


}

/// @nodoc
abstract mixin class $ContactRequestsRespondedCopyWith<$Res> implements $ContactRequestsEventCopyWith<$Res> {
  factory $ContactRequestsRespondedCopyWith(ContactRequestsResponded value, $Res Function(ContactRequestsResponded) _then) = _$ContactRequestsRespondedCopyWithImpl;
@useResult
$Res call({
 String contactId, bool accept
});




}
/// @nodoc
class _$ContactRequestsRespondedCopyWithImpl<$Res>
    implements $ContactRequestsRespondedCopyWith<$Res> {
  _$ContactRequestsRespondedCopyWithImpl(this._self, this._then);

  final ContactRequestsResponded _self;
  final $Res Function(ContactRequestsResponded) _then;

/// Create a copy of ContactRequestsEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? contactId = null,Object? accept = null,}) {
  return _then(ContactRequestsResponded(
contactId: null == contactId ? _self.contactId : contactId // ignore: cast_nullable_to_non_nullable
as String,accept: null == accept ? _self.accept : accept // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class ContactRequestsOutgoingCancelled implements ContactRequestsEvent {
  const ContactRequestsOutgoingCancelled({required this.contactId});
  

 final  String contactId;

/// Create a copy of ContactRequestsEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ContactRequestsOutgoingCancelledCopyWith<ContactRequestsOutgoingCancelled> get copyWith => _$ContactRequestsOutgoingCancelledCopyWithImpl<ContactRequestsOutgoingCancelled>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ContactRequestsOutgoingCancelled&&(identical(other.contactId, contactId) || other.contactId == contactId));
}


@override
int get hashCode => Object.hash(runtimeType,contactId);

@override
String toString() {
  return 'ContactRequestsEvent.outgoingCancelled(contactId: $contactId)';
}


}

/// @nodoc
abstract mixin class $ContactRequestsOutgoingCancelledCopyWith<$Res> implements $ContactRequestsEventCopyWith<$Res> {
  factory $ContactRequestsOutgoingCancelledCopyWith(ContactRequestsOutgoingCancelled value, $Res Function(ContactRequestsOutgoingCancelled) _then) = _$ContactRequestsOutgoingCancelledCopyWithImpl;
@useResult
$Res call({
 String contactId
});




}
/// @nodoc
class _$ContactRequestsOutgoingCancelledCopyWithImpl<$Res>
    implements $ContactRequestsOutgoingCancelledCopyWith<$Res> {
  _$ContactRequestsOutgoingCancelledCopyWithImpl(this._self, this._then);

  final ContactRequestsOutgoingCancelled _self;
  final $Res Function(ContactRequestsOutgoingCancelled) _then;

/// Create a copy of ContactRequestsEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? contactId = null,}) {
  return _then(ContactRequestsOutgoingCancelled(
contactId: null == contactId ? _self.contactId : contactId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$ContactRequestsState {

 ContactRequestsStatus get status; List<ContactEntity> get incoming; List<ContactEntity> get outgoing; String? get errorMessage;
/// Create a copy of ContactRequestsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ContactRequestsStateCopyWith<ContactRequestsState> get copyWith => _$ContactRequestsStateCopyWithImpl<ContactRequestsState>(this as ContactRequestsState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ContactRequestsState&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.incoming, incoming)&&const DeepCollectionEquality().equals(other.outgoing, outgoing)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,status,const DeepCollectionEquality().hash(incoming),const DeepCollectionEquality().hash(outgoing),errorMessage);

@override
String toString() {
  return 'ContactRequestsState(status: $status, incoming: $incoming, outgoing: $outgoing, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class $ContactRequestsStateCopyWith<$Res>  {
  factory $ContactRequestsStateCopyWith(ContactRequestsState value, $Res Function(ContactRequestsState) _then) = _$ContactRequestsStateCopyWithImpl;
@useResult
$Res call({
 ContactRequestsStatus status, List<ContactEntity> incoming, List<ContactEntity> outgoing, String? errorMessage
});




}
/// @nodoc
class _$ContactRequestsStateCopyWithImpl<$Res>
    implements $ContactRequestsStateCopyWith<$Res> {
  _$ContactRequestsStateCopyWithImpl(this._self, this._then);

  final ContactRequestsState _self;
  final $Res Function(ContactRequestsState) _then;

/// Create a copy of ContactRequestsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? incoming = null,Object? outgoing = null,Object? errorMessage = freezed,}) {
  return _then(ContactRequestsState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ContactRequestsStatus,incoming: null == incoming ? _self.incoming : incoming // ignore: cast_nullable_to_non_nullable
as List<ContactEntity>,outgoing: null == outgoing ? _self.outgoing : outgoing // ignore: cast_nullable_to_non_nullable
as List<ContactEntity>,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ContactRequestsState].
extension ContactRequestsStatePatterns on ContactRequestsState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ContactRequestsState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ContactRequestsState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ContactRequestsState value)  $default,){
final _that = this;
switch (_that) {
case _ContactRequestsState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ContactRequestsState value)?  $default,){
final _that = this;
switch (_that) {
case _ContactRequestsState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ContactRequestsStatus status,  List<ContactEntity> incoming,  List<ContactEntity> outgoing,  String? errorMessage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ContactRequestsState() when $default != null:
return $default(_that.status,_that.incoming,_that.outgoing,_that.errorMessage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ContactRequestsStatus status,  List<ContactEntity> incoming,  List<ContactEntity> outgoing,  String? errorMessage)  $default,) {final _that = this;
switch (_that) {
case _ContactRequestsState():
return $default(_that.status,_that.incoming,_that.outgoing,_that.errorMessage);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ContactRequestsStatus status,  List<ContactEntity> incoming,  List<ContactEntity> outgoing,  String? errorMessage)?  $default,) {final _that = this;
switch (_that) {
case _ContactRequestsState() when $default != null:
return $default(_that.status,_that.incoming,_that.outgoing,_that.errorMessage);case _:
  return null;

}
}

}

/// @nodoc


class _ContactRequestsState implements ContactRequestsState {
  const _ContactRequestsState({this.status = ContactRequestsStatus.initial,  List<ContactEntity> incoming = const <ContactEntity>[],  List<ContactEntity> outgoing = const <ContactEntity>[], this.errorMessage}): _incoming = incoming,_outgoing = outgoing;
  

@override@JsonKey() final  ContactRequestsStatus status;
 final  List<ContactEntity> _incoming;
@override@JsonKey() List<ContactEntity> get incoming {
  if (_incoming is EqualUnmodifiableListView) return _incoming;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_incoming);
}

 final  List<ContactEntity> _outgoing;
@override@JsonKey() List<ContactEntity> get outgoing {
  if (_outgoing is EqualUnmodifiableListView) return _outgoing;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_outgoing);
}

@override final  String? errorMessage;

/// Create a copy of ContactRequestsState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ContactRequestsStateCopyWith<_ContactRequestsState> get copyWith => __$ContactRequestsStateCopyWithImpl<_ContactRequestsState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ContactRequestsState&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other._incoming, _incoming)&&const DeepCollectionEquality().equals(other._outgoing, _outgoing)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,status,const DeepCollectionEquality().hash(_incoming),const DeepCollectionEquality().hash(_outgoing),errorMessage);

@override
String toString() {
  return 'ContactRequestsState(status: $status, incoming: $incoming, outgoing: $outgoing, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class _$ContactRequestsStateCopyWith<$Res> implements $ContactRequestsStateCopyWith<$Res> {
  factory _$ContactRequestsStateCopyWith(_ContactRequestsState value, $Res Function(_ContactRequestsState) _then) = __$ContactRequestsStateCopyWithImpl;
@override @useResult
$Res call({
 ContactRequestsStatus status, List<ContactEntity> incoming, List<ContactEntity> outgoing, String? errorMessage
});




}
/// @nodoc
class __$ContactRequestsStateCopyWithImpl<$Res>
    implements _$ContactRequestsStateCopyWith<$Res> {
  __$ContactRequestsStateCopyWithImpl(this._self, this._then);

  final _ContactRequestsState _self;
  final $Res Function(_ContactRequestsState) _then;

/// Create a copy of ContactRequestsState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? incoming = null,Object? outgoing = null,Object? errorMessage = freezed,}) {
  return _then(_ContactRequestsState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ContactRequestsStatus,incoming: null == incoming ? _self._incoming : incoming // ignore: cast_nullable_to_non_nullable
as List<ContactEntity>,outgoing: null == outgoing ? _self._outgoing : outgoing // ignore: cast_nullable_to_non_nullable
as List<ContactEntity>,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
