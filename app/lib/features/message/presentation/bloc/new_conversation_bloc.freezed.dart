// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'new_conversation_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$NewConversationEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NewConversationEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'NewConversationEvent()';
}


}

/// @nodoc
class $NewConversationEventCopyWith<$Res>  {
$NewConversationEventCopyWith(NewConversationEvent _, $Res Function(NewConversationEvent) __);
}


/// Adds pattern-matching-related methods to [NewConversationEvent].
extension NewConversationEventPatterns on NewConversationEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( NewConversationContactToggled value)?  contactToggled,TResult Function( NewConversationGroupNameChanged value)?  groupNameChanged,TResult Function( NewConversationSubmitted value)?  submitted,required TResult orElse(),}){
final _that = this;
switch (_that) {
case NewConversationContactToggled() when contactToggled != null:
return contactToggled(_that);case NewConversationGroupNameChanged() when groupNameChanged != null:
return groupNameChanged(_that);case NewConversationSubmitted() when submitted != null:
return submitted(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( NewConversationContactToggled value)  contactToggled,required TResult Function( NewConversationGroupNameChanged value)  groupNameChanged,required TResult Function( NewConversationSubmitted value)  submitted,}){
final _that = this;
switch (_that) {
case NewConversationContactToggled():
return contactToggled(_that);case NewConversationGroupNameChanged():
return groupNameChanged(_that);case NewConversationSubmitted():
return submitted(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( NewConversationContactToggled value)?  contactToggled,TResult? Function( NewConversationGroupNameChanged value)?  groupNameChanged,TResult? Function( NewConversationSubmitted value)?  submitted,}){
final _that = this;
switch (_that) {
case NewConversationContactToggled() when contactToggled != null:
return contactToggled(_that);case NewConversationGroupNameChanged() when groupNameChanged != null:
return groupNameChanged(_that);case NewConversationSubmitted() when submitted != null:
return submitted(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String userId)?  contactToggled,TResult Function( String name)?  groupNameChanged,TResult Function()?  submitted,required TResult orElse(),}) {final _that = this;
switch (_that) {
case NewConversationContactToggled() when contactToggled != null:
return contactToggled(_that.userId);case NewConversationGroupNameChanged() when groupNameChanged != null:
return groupNameChanged(_that.name);case NewConversationSubmitted() when submitted != null:
return submitted();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String userId)  contactToggled,required TResult Function( String name)  groupNameChanged,required TResult Function()  submitted,}) {final _that = this;
switch (_that) {
case NewConversationContactToggled():
return contactToggled(_that.userId);case NewConversationGroupNameChanged():
return groupNameChanged(_that.name);case NewConversationSubmitted():
return submitted();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String userId)?  contactToggled,TResult? Function( String name)?  groupNameChanged,TResult? Function()?  submitted,}) {final _that = this;
switch (_that) {
case NewConversationContactToggled() when contactToggled != null:
return contactToggled(_that.userId);case NewConversationGroupNameChanged() when groupNameChanged != null:
return groupNameChanged(_that.name);case NewConversationSubmitted() when submitted != null:
return submitted();case _:
  return null;

}
}

}

/// @nodoc


class NewConversationContactToggled implements NewConversationEvent {
  const NewConversationContactToggled(this.userId);
  

 final  String userId;

/// Create a copy of NewConversationEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NewConversationContactToggledCopyWith<NewConversationContactToggled> get copyWith => _$NewConversationContactToggledCopyWithImpl<NewConversationContactToggled>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NewConversationContactToggled&&(identical(other.userId, userId) || other.userId == userId));
}


@override
int get hashCode => Object.hash(runtimeType,userId);

@override
String toString() {
  return 'NewConversationEvent.contactToggled(userId: $userId)';
}


}

/// @nodoc
abstract mixin class $NewConversationContactToggledCopyWith<$Res> implements $NewConversationEventCopyWith<$Res> {
  factory $NewConversationContactToggledCopyWith(NewConversationContactToggled value, $Res Function(NewConversationContactToggled) _then) = _$NewConversationContactToggledCopyWithImpl;
@useResult
$Res call({
 String userId
});




}
/// @nodoc
class _$NewConversationContactToggledCopyWithImpl<$Res>
    implements $NewConversationContactToggledCopyWith<$Res> {
  _$NewConversationContactToggledCopyWithImpl(this._self, this._then);

  final NewConversationContactToggled _self;
  final $Res Function(NewConversationContactToggled) _then;

/// Create a copy of NewConversationEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? userId = null,}) {
  return _then(NewConversationContactToggled(
null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class NewConversationGroupNameChanged implements NewConversationEvent {
  const NewConversationGroupNameChanged(this.name);
  

 final  String name;

/// Create a copy of NewConversationEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NewConversationGroupNameChangedCopyWith<NewConversationGroupNameChanged> get copyWith => _$NewConversationGroupNameChangedCopyWithImpl<NewConversationGroupNameChanged>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NewConversationGroupNameChanged&&(identical(other.name, name) || other.name == name));
}


@override
int get hashCode => Object.hash(runtimeType,name);

@override
String toString() {
  return 'NewConversationEvent.groupNameChanged(name: $name)';
}


}

/// @nodoc
abstract mixin class $NewConversationGroupNameChangedCopyWith<$Res> implements $NewConversationEventCopyWith<$Res> {
  factory $NewConversationGroupNameChangedCopyWith(NewConversationGroupNameChanged value, $Res Function(NewConversationGroupNameChanged) _then) = _$NewConversationGroupNameChangedCopyWithImpl;
@useResult
$Res call({
 String name
});




}
/// @nodoc
class _$NewConversationGroupNameChangedCopyWithImpl<$Res>
    implements $NewConversationGroupNameChangedCopyWith<$Res> {
  _$NewConversationGroupNameChangedCopyWithImpl(this._self, this._then);

  final NewConversationGroupNameChanged _self;
  final $Res Function(NewConversationGroupNameChanged) _then;

/// Create a copy of NewConversationEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? name = null,}) {
  return _then(NewConversationGroupNameChanged(
null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class NewConversationSubmitted implements NewConversationEvent {
  const NewConversationSubmitted();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NewConversationSubmitted);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'NewConversationEvent.submitted()';
}


}




/// @nodoc
mixin _$NewConversationState {

 NewConversationStatus get status; Set<String> get selectedUserIds; String get groupName; ConversationEntity? get created; String? get errorMessage;
/// Create a copy of NewConversationState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NewConversationStateCopyWith<NewConversationState> get copyWith => _$NewConversationStateCopyWithImpl<NewConversationState>(this as NewConversationState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NewConversationState&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.selectedUserIds, selectedUserIds)&&(identical(other.groupName, groupName) || other.groupName == groupName)&&(identical(other.created, created) || other.created == created)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,status,const DeepCollectionEquality().hash(selectedUserIds),groupName,created,errorMessage);

@override
String toString() {
  return 'NewConversationState(status: $status, selectedUserIds: $selectedUserIds, groupName: $groupName, created: $created, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class $NewConversationStateCopyWith<$Res>  {
  factory $NewConversationStateCopyWith(NewConversationState value, $Res Function(NewConversationState) _then) = _$NewConversationStateCopyWithImpl;
@useResult
$Res call({
 NewConversationStatus status, Set<String> selectedUserIds, String groupName, ConversationEntity? created, String? errorMessage
});




}
/// @nodoc
class _$NewConversationStateCopyWithImpl<$Res>
    implements $NewConversationStateCopyWith<$Res> {
  _$NewConversationStateCopyWithImpl(this._self, this._then);

  final NewConversationState _self;
  final $Res Function(NewConversationState) _then;

/// Create a copy of NewConversationState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? selectedUserIds = null,Object? groupName = null,Object? created = freezed,Object? errorMessage = freezed,}) {
  return _then(NewConversationState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as NewConversationStatus,selectedUserIds: null == selectedUserIds ? _self.selectedUserIds : selectedUserIds // ignore: cast_nullable_to_non_nullable
as Set<String>,groupName: null == groupName ? _self.groupName : groupName // ignore: cast_nullable_to_non_nullable
as String,created: freezed == created ? _self.created : created // ignore: cast_nullable_to_non_nullable
as ConversationEntity?,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [NewConversationState].
extension NewConversationStatePatterns on NewConversationState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NewConversationState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NewConversationState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NewConversationState value)  $default,){
final _that = this;
switch (_that) {
case _NewConversationState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NewConversationState value)?  $default,){
final _that = this;
switch (_that) {
case _NewConversationState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( NewConversationStatus status,  Set<String> selectedUserIds,  String groupName,  ConversationEntity? created,  String? errorMessage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NewConversationState() when $default != null:
return $default(_that.status,_that.selectedUserIds,_that.groupName,_that.created,_that.errorMessage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( NewConversationStatus status,  Set<String> selectedUserIds,  String groupName,  ConversationEntity? created,  String? errorMessage)  $default,) {final _that = this;
switch (_that) {
case _NewConversationState():
return $default(_that.status,_that.selectedUserIds,_that.groupName,_that.created,_that.errorMessage);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( NewConversationStatus status,  Set<String> selectedUserIds,  String groupName,  ConversationEntity? created,  String? errorMessage)?  $default,) {final _that = this;
switch (_that) {
case _NewConversationState() when $default != null:
return $default(_that.status,_that.selectedUserIds,_that.groupName,_that.created,_that.errorMessage);case _:
  return null;

}
}

}

/// @nodoc


class _NewConversationState implements NewConversationState {
  const _NewConversationState({this.status = NewConversationStatus.idle,  Set<String> selectedUserIds = const <String>{}, this.groupName = '', this.created, this.errorMessage}): _selectedUserIds = selectedUserIds;
  

@override@JsonKey() final  NewConversationStatus status;
 final  Set<String> _selectedUserIds;
@override@JsonKey() Set<String> get selectedUserIds {
  if (_selectedUserIds is EqualUnmodifiableSetView) return _selectedUserIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_selectedUserIds);
}

@override@JsonKey() final  String groupName;
@override final  ConversationEntity? created;
@override final  String? errorMessage;

/// Create a copy of NewConversationState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NewConversationStateCopyWith<_NewConversationState> get copyWith => __$NewConversationStateCopyWithImpl<_NewConversationState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NewConversationState&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other._selectedUserIds, _selectedUserIds)&&(identical(other.groupName, groupName) || other.groupName == groupName)&&(identical(other.created, created) || other.created == created)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,status,const DeepCollectionEquality().hash(_selectedUserIds),groupName,created,errorMessage);

@override
String toString() {
  return 'NewConversationState(status: $status, selectedUserIds: $selectedUserIds, groupName: $groupName, created: $created, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class _$NewConversationStateCopyWith<$Res> implements $NewConversationStateCopyWith<$Res> {
  factory _$NewConversationStateCopyWith(_NewConversationState value, $Res Function(_NewConversationState) _then) = __$NewConversationStateCopyWithImpl;
@override @useResult
$Res call({
 NewConversationStatus status, Set<String> selectedUserIds, String groupName, ConversationEntity? created, String? errorMessage
});




}
/// @nodoc
class __$NewConversationStateCopyWithImpl<$Res>
    implements _$NewConversationStateCopyWith<$Res> {
  __$NewConversationStateCopyWithImpl(this._self, this._then);

  final _NewConversationState _self;
  final $Res Function(_NewConversationState) _then;

/// Create a copy of NewConversationState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? selectedUserIds = null,Object? groupName = null,Object? created = freezed,Object? errorMessage = freezed,}) {
  return _then(_NewConversationState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as NewConversationStatus,selectedUserIds: null == selectedUserIds ? _self._selectedUserIds : selectedUserIds // ignore: cast_nullable_to_non_nullable
as Set<String>,groupName: null == groupName ? _self.groupName : groupName // ignore: cast_nullable_to_non_nullable
as String,created: freezed == created ? _self.created : created // ignore: cast_nullable_to_non_nullable
as ConversationEntity?,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
