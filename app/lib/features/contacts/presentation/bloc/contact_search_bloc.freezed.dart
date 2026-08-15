// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'contact_search_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ContactSearchEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ContactSearchEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ContactSearchEvent()';
}


}

/// @nodoc
class $ContactSearchEventCopyWith<$Res>  {
$ContactSearchEventCopyWith(ContactSearchEvent _, $Res Function(ContactSearchEvent) __);
}


/// Adds pattern-matching-related methods to [ContactSearchEvent].
extension ContactSearchEventPatterns on ContactSearchEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ContactSearchSubmitted value)?  submitted,TResult Function( ContactSearchRequestSendRequested value)?  requestSendRequested,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ContactSearchSubmitted() when submitted != null:
return submitted(_that);case ContactSearchRequestSendRequested() when requestSendRequested != null:
return requestSendRequested(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ContactSearchSubmitted value)  submitted,required TResult Function( ContactSearchRequestSendRequested value)  requestSendRequested,}){
final _that = this;
switch (_that) {
case ContactSearchSubmitted():
return submitted(_that);case ContactSearchRequestSendRequested():
return requestSendRequested(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ContactSearchSubmitted value)?  submitted,TResult? Function( ContactSearchRequestSendRequested value)?  requestSendRequested,}){
final _that = this;
switch (_that) {
case ContactSearchSubmitted() when submitted != null:
return submitted(_that);case ContactSearchRequestSendRequested() when requestSendRequested != null:
return requestSendRequested(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String phone)?  submitted,TResult Function()?  requestSendRequested,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ContactSearchSubmitted() when submitted != null:
return submitted(_that.phone);case ContactSearchRequestSendRequested() when requestSendRequested != null:
return requestSendRequested();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String phone)  submitted,required TResult Function()  requestSendRequested,}) {final _that = this;
switch (_that) {
case ContactSearchSubmitted():
return submitted(_that.phone);case ContactSearchRequestSendRequested():
return requestSendRequested();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String phone)?  submitted,TResult? Function()?  requestSendRequested,}) {final _that = this;
switch (_that) {
case ContactSearchSubmitted() when submitted != null:
return submitted(_that.phone);case ContactSearchRequestSendRequested() when requestSendRequested != null:
return requestSendRequested();case _:
  return null;

}
}

}

/// @nodoc


class ContactSearchSubmitted implements ContactSearchEvent {
  const ContactSearchSubmitted({required this.phone});
  

 final  String phone;

/// Create a copy of ContactSearchEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ContactSearchSubmittedCopyWith<ContactSearchSubmitted> get copyWith => _$ContactSearchSubmittedCopyWithImpl<ContactSearchSubmitted>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ContactSearchSubmitted&&(identical(other.phone, phone) || other.phone == phone));
}


@override
int get hashCode => Object.hash(runtimeType,phone);

@override
String toString() {
  return 'ContactSearchEvent.submitted(phone: $phone)';
}


}

/// @nodoc
abstract mixin class $ContactSearchSubmittedCopyWith<$Res> implements $ContactSearchEventCopyWith<$Res> {
  factory $ContactSearchSubmittedCopyWith(ContactSearchSubmitted value, $Res Function(ContactSearchSubmitted) _then) = _$ContactSearchSubmittedCopyWithImpl;
@useResult
$Res call({
 String phone
});




}
/// @nodoc
class _$ContactSearchSubmittedCopyWithImpl<$Res>
    implements $ContactSearchSubmittedCopyWith<$Res> {
  _$ContactSearchSubmittedCopyWithImpl(this._self, this._then);

  final ContactSearchSubmitted _self;
  final $Res Function(ContactSearchSubmitted) _then;

/// Create a copy of ContactSearchEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? phone = null,}) {
  return _then(ContactSearchSubmitted(
phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class ContactSearchRequestSendRequested implements ContactSearchEvent {
  const ContactSearchRequestSendRequested();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ContactSearchRequestSendRequested);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ContactSearchEvent.requestSendRequested()';
}


}




/// @nodoc
mixin _$ContactSearchState {

 ContactSearchStatus get status; UserSummaryEntity? get result; bool get sending; bool get requestSent; String? get errorMessage;
/// Create a copy of ContactSearchState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ContactSearchStateCopyWith<ContactSearchState> get copyWith => _$ContactSearchStateCopyWithImpl<ContactSearchState>(this as ContactSearchState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ContactSearchState&&(identical(other.status, status) || other.status == status)&&(identical(other.result, result) || other.result == result)&&(identical(other.sending, sending) || other.sending == sending)&&(identical(other.requestSent, requestSent) || other.requestSent == requestSent)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,status,result,sending,requestSent,errorMessage);

@override
String toString() {
  return 'ContactSearchState(status: $status, result: $result, sending: $sending, requestSent: $requestSent, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class $ContactSearchStateCopyWith<$Res>  {
  factory $ContactSearchStateCopyWith(ContactSearchState value, $Res Function(ContactSearchState) _then) = _$ContactSearchStateCopyWithImpl;
@useResult
$Res call({
 ContactSearchStatus status, UserSummaryEntity? result, bool sending, bool requestSent, String? errorMessage
});




}
/// @nodoc
class _$ContactSearchStateCopyWithImpl<$Res>
    implements $ContactSearchStateCopyWith<$Res> {
  _$ContactSearchStateCopyWithImpl(this._self, this._then);

  final ContactSearchState _self;
  final $Res Function(ContactSearchState) _then;

/// Create a copy of ContactSearchState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? result = freezed,Object? sending = null,Object? requestSent = null,Object? errorMessage = freezed,}) {
  return _then(ContactSearchState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ContactSearchStatus,result: freezed == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as UserSummaryEntity?,sending: null == sending ? _self.sending : sending // ignore: cast_nullable_to_non_nullable
as bool,requestSent: null == requestSent ? _self.requestSent : requestSent // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ContactSearchState].
extension ContactSearchStatePatterns on ContactSearchState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ContactSearchState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ContactSearchState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ContactSearchState value)  $default,){
final _that = this;
switch (_that) {
case _ContactSearchState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ContactSearchState value)?  $default,){
final _that = this;
switch (_that) {
case _ContactSearchState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ContactSearchStatus status,  UserSummaryEntity? result,  bool sending,  bool requestSent,  String? errorMessage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ContactSearchState() when $default != null:
return $default(_that.status,_that.result,_that.sending,_that.requestSent,_that.errorMessage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ContactSearchStatus status,  UserSummaryEntity? result,  bool sending,  bool requestSent,  String? errorMessage)  $default,) {final _that = this;
switch (_that) {
case _ContactSearchState():
return $default(_that.status,_that.result,_that.sending,_that.requestSent,_that.errorMessage);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ContactSearchStatus status,  UserSummaryEntity? result,  bool sending,  bool requestSent,  String? errorMessage)?  $default,) {final _that = this;
switch (_that) {
case _ContactSearchState() when $default != null:
return $default(_that.status,_that.result,_that.sending,_that.requestSent,_that.errorMessage);case _:
  return null;

}
}

}

/// @nodoc


class _ContactSearchState implements ContactSearchState {
  const _ContactSearchState({this.status = ContactSearchStatus.idle, this.result, this.sending = false, this.requestSent = false, this.errorMessage});
  

@override@JsonKey() final  ContactSearchStatus status;
@override final  UserSummaryEntity? result;
@override@JsonKey() final  bool sending;
@override@JsonKey() final  bool requestSent;
@override final  String? errorMessage;

/// Create a copy of ContactSearchState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ContactSearchStateCopyWith<_ContactSearchState> get copyWith => __$ContactSearchStateCopyWithImpl<_ContactSearchState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ContactSearchState&&(identical(other.status, status) || other.status == status)&&(identical(other.result, result) || other.result == result)&&(identical(other.sending, sending) || other.sending == sending)&&(identical(other.requestSent, requestSent) || other.requestSent == requestSent)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,status,result,sending,requestSent,errorMessage);

@override
String toString() {
  return 'ContactSearchState(status: $status, result: $result, sending: $sending, requestSent: $requestSent, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class _$ContactSearchStateCopyWith<$Res> implements $ContactSearchStateCopyWith<$Res> {
  factory _$ContactSearchStateCopyWith(_ContactSearchState value, $Res Function(_ContactSearchState) _then) = __$ContactSearchStateCopyWithImpl;
@override @useResult
$Res call({
 ContactSearchStatus status, UserSummaryEntity? result, bool sending, bool requestSent, String? errorMessage
});




}
/// @nodoc
class __$ContactSearchStateCopyWithImpl<$Res>
    implements _$ContactSearchStateCopyWith<$Res> {
  __$ContactSearchStateCopyWithImpl(this._self, this._then);

  final _ContactSearchState _self;
  final $Res Function(_ContactSearchState) _then;

/// Create a copy of ContactSearchState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? result = freezed,Object? sending = null,Object? requestSent = null,Object? errorMessage = freezed,}) {
  return _then(_ContactSearchState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ContactSearchStatus,result: freezed == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as UserSummaryEntity?,sending: null == sending ? _self.sending : sending // ignore: cast_nullable_to_non_nullable
as bool,requestSent: null == requestSent ? _self.requestSent : requestSent // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
