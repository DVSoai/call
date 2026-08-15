// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'auth_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AuthEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AuthEvent()';
}


}

/// @nodoc
class $AuthEventCopyWith<$Res>  {
$AuthEventCopyWith(AuthEvent _, $Res Function(AuthEvent) __);
}


/// Adds pattern-matching-related methods to [AuthEvent].
extension AuthEventPatterns on AuthEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( AuthSessionCheckRequested value)?  sessionCheckRequested,TResult Function( AuthLoginSubmitted value)?  loginSubmitted,TResult Function( AuthLoggedOut value)?  loggedOut,TResult Function( AuthPreferredLanguageChanged value)?  preferredLanguageChanged,required TResult orElse(),}){
final _that = this;
switch (_that) {
case AuthSessionCheckRequested() when sessionCheckRequested != null:
return sessionCheckRequested(_that);case AuthLoginSubmitted() when loginSubmitted != null:
return loginSubmitted(_that);case AuthLoggedOut() when loggedOut != null:
return loggedOut(_that);case AuthPreferredLanguageChanged() when preferredLanguageChanged != null:
return preferredLanguageChanged(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( AuthSessionCheckRequested value)  sessionCheckRequested,required TResult Function( AuthLoginSubmitted value)  loginSubmitted,required TResult Function( AuthLoggedOut value)  loggedOut,required TResult Function( AuthPreferredLanguageChanged value)  preferredLanguageChanged,}){
final _that = this;
switch (_that) {
case AuthSessionCheckRequested():
return sessionCheckRequested(_that);case AuthLoginSubmitted():
return loginSubmitted(_that);case AuthLoggedOut():
return loggedOut(_that);case AuthPreferredLanguageChanged():
return preferredLanguageChanged(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( AuthSessionCheckRequested value)?  sessionCheckRequested,TResult? Function( AuthLoginSubmitted value)?  loginSubmitted,TResult? Function( AuthLoggedOut value)?  loggedOut,TResult? Function( AuthPreferredLanguageChanged value)?  preferredLanguageChanged,}){
final _that = this;
switch (_that) {
case AuthSessionCheckRequested() when sessionCheckRequested != null:
return sessionCheckRequested(_that);case AuthLoginSubmitted() when loginSubmitted != null:
return loginSubmitted(_that);case AuthLoggedOut() when loggedOut != null:
return loggedOut(_that);case AuthPreferredLanguageChanged() when preferredLanguageChanged != null:
return preferredLanguageChanged(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  sessionCheckRequested,TResult Function( String phone)?  loginSubmitted,TResult Function()?  loggedOut,TResult Function( String language)?  preferredLanguageChanged,required TResult orElse(),}) {final _that = this;
switch (_that) {
case AuthSessionCheckRequested() when sessionCheckRequested != null:
return sessionCheckRequested();case AuthLoginSubmitted() when loginSubmitted != null:
return loginSubmitted(_that.phone);case AuthLoggedOut() when loggedOut != null:
return loggedOut();case AuthPreferredLanguageChanged() when preferredLanguageChanged != null:
return preferredLanguageChanged(_that.language);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  sessionCheckRequested,required TResult Function( String phone)  loginSubmitted,required TResult Function()  loggedOut,required TResult Function( String language)  preferredLanguageChanged,}) {final _that = this;
switch (_that) {
case AuthSessionCheckRequested():
return sessionCheckRequested();case AuthLoginSubmitted():
return loginSubmitted(_that.phone);case AuthLoggedOut():
return loggedOut();case AuthPreferredLanguageChanged():
return preferredLanguageChanged(_that.language);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  sessionCheckRequested,TResult? Function( String phone)?  loginSubmitted,TResult? Function()?  loggedOut,TResult? Function( String language)?  preferredLanguageChanged,}) {final _that = this;
switch (_that) {
case AuthSessionCheckRequested() when sessionCheckRequested != null:
return sessionCheckRequested();case AuthLoginSubmitted() when loginSubmitted != null:
return loginSubmitted(_that.phone);case AuthLoggedOut() when loggedOut != null:
return loggedOut();case AuthPreferredLanguageChanged() when preferredLanguageChanged != null:
return preferredLanguageChanged(_that.language);case _:
  return null;

}
}

}

/// @nodoc


class AuthSessionCheckRequested implements AuthEvent {
  const AuthSessionCheckRequested();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthSessionCheckRequested);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AuthEvent.sessionCheckRequested()';
}


}




/// @nodoc


class AuthLoginSubmitted implements AuthEvent {
  const AuthLoginSubmitted({required this.phone});
  

 final  String phone;

/// Create a copy of AuthEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthLoginSubmittedCopyWith<AuthLoginSubmitted> get copyWith => _$AuthLoginSubmittedCopyWithImpl<AuthLoginSubmitted>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthLoginSubmitted&&(identical(other.phone, phone) || other.phone == phone));
}


@override
int get hashCode => Object.hash(runtimeType,phone);

@override
String toString() {
  return 'AuthEvent.loginSubmitted(phone: $phone)';
}


}

/// @nodoc
abstract mixin class $AuthLoginSubmittedCopyWith<$Res> implements $AuthEventCopyWith<$Res> {
  factory $AuthLoginSubmittedCopyWith(AuthLoginSubmitted value, $Res Function(AuthLoginSubmitted) _then) = _$AuthLoginSubmittedCopyWithImpl;
@useResult
$Res call({
 String phone
});




}
/// @nodoc
class _$AuthLoginSubmittedCopyWithImpl<$Res>
    implements $AuthLoginSubmittedCopyWith<$Res> {
  _$AuthLoginSubmittedCopyWithImpl(this._self, this._then);

  final AuthLoginSubmitted _self;
  final $Res Function(AuthLoginSubmitted) _then;

/// Create a copy of AuthEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? phone = null,}) {
  return _then(AuthLoginSubmitted(
phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class AuthLoggedOut implements AuthEvent {
  const AuthLoggedOut();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthLoggedOut);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AuthEvent.loggedOut()';
}


}




/// @nodoc


class AuthPreferredLanguageChanged implements AuthEvent {
  const AuthPreferredLanguageChanged(this.language);
  

 final  String language;

/// Create a copy of AuthEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthPreferredLanguageChangedCopyWith<AuthPreferredLanguageChanged> get copyWith => _$AuthPreferredLanguageChangedCopyWithImpl<AuthPreferredLanguageChanged>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthPreferredLanguageChanged&&(identical(other.language, language) || other.language == language));
}


@override
int get hashCode => Object.hash(runtimeType,language);

@override
String toString() {
  return 'AuthEvent.preferredLanguageChanged(language: $language)';
}


}

/// @nodoc
abstract mixin class $AuthPreferredLanguageChangedCopyWith<$Res> implements $AuthEventCopyWith<$Res> {
  factory $AuthPreferredLanguageChangedCopyWith(AuthPreferredLanguageChanged value, $Res Function(AuthPreferredLanguageChanged) _then) = _$AuthPreferredLanguageChangedCopyWithImpl;
@useResult
$Res call({
 String language
});




}
/// @nodoc
class _$AuthPreferredLanguageChangedCopyWithImpl<$Res>
    implements $AuthPreferredLanguageChangedCopyWith<$Res> {
  _$AuthPreferredLanguageChangedCopyWithImpl(this._self, this._then);

  final AuthPreferredLanguageChanged _self;
  final $Res Function(AuthPreferredLanguageChanged) _then;

/// Create a copy of AuthEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? language = null,}) {
  return _then(AuthPreferredLanguageChanged(
null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$AuthState {

 AuthStatus get status; UserEntity? get user; String? get errorMessage;
/// Create a copy of AuthState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthStateCopyWith<AuthState> get copyWith => _$AuthStateCopyWithImpl<AuthState>(this as AuthState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthState&&(identical(other.status, status) || other.status == status)&&(identical(other.user, user) || other.user == user)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,status,user,errorMessage);

@override
String toString() {
  return 'AuthState(status: $status, user: $user, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class $AuthStateCopyWith<$Res>  {
  factory $AuthStateCopyWith(AuthState value, $Res Function(AuthState) _then) = _$AuthStateCopyWithImpl;
@useResult
$Res call({
 AuthStatus status, UserEntity? user, String? errorMessage
});




}
/// @nodoc
class _$AuthStateCopyWithImpl<$Res>
    implements $AuthStateCopyWith<$Res> {
  _$AuthStateCopyWithImpl(this._self, this._then);

  final AuthState _self;
  final $Res Function(AuthState) _then;

/// Create a copy of AuthState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? user = freezed,Object? errorMessage = freezed,}) {
  return _then(AuthState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as AuthStatus,user: freezed == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as UserEntity?,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AuthState].
extension AuthStatePatterns on AuthState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AuthState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AuthState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AuthState value)  $default,){
final _that = this;
switch (_that) {
case _AuthState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AuthState value)?  $default,){
final _that = this;
switch (_that) {
case _AuthState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AuthStatus status,  UserEntity? user,  String? errorMessage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AuthState() when $default != null:
return $default(_that.status,_that.user,_that.errorMessage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AuthStatus status,  UserEntity? user,  String? errorMessage)  $default,) {final _that = this;
switch (_that) {
case _AuthState():
return $default(_that.status,_that.user,_that.errorMessage);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AuthStatus status,  UserEntity? user,  String? errorMessage)?  $default,) {final _that = this;
switch (_that) {
case _AuthState() when $default != null:
return $default(_that.status,_that.user,_that.errorMessage);case _:
  return null;

}
}

}

/// @nodoc


class _AuthState implements AuthState {
  const _AuthState({this.status = AuthStatus.initial, this.user, this.errorMessage});
  

@override@JsonKey() final  AuthStatus status;
@override final  UserEntity? user;
@override final  String? errorMessage;

/// Create a copy of AuthState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuthStateCopyWith<_AuthState> get copyWith => __$AuthStateCopyWithImpl<_AuthState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuthState&&(identical(other.status, status) || other.status == status)&&(identical(other.user, user) || other.user == user)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,status,user,errorMessage);

@override
String toString() {
  return 'AuthState(status: $status, user: $user, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class _$AuthStateCopyWith<$Res> implements $AuthStateCopyWith<$Res> {
  factory _$AuthStateCopyWith(_AuthState value, $Res Function(_AuthState) _then) = __$AuthStateCopyWithImpl;
@override @useResult
$Res call({
 AuthStatus status, UserEntity? user, String? errorMessage
});




}
/// @nodoc
class __$AuthStateCopyWithImpl<$Res>
    implements _$AuthStateCopyWith<$Res> {
  __$AuthStateCopyWithImpl(this._self, this._then);

  final _AuthState _self;
  final $Res Function(_AuthState) _then;

/// Create a copy of AuthState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? user = freezed,Object? errorMessage = freezed,}) {
  return _then(_AuthState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as AuthStatus,user: freezed == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as UserEntity?,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
