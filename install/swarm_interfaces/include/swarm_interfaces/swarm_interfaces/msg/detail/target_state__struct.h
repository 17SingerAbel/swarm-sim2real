// generated from rosidl_generator_c/resource/idl__struct.h.em
// with input from swarm_interfaces:msg/TargetState.idl
// generated code does not contain a copyright notice

#ifndef SWARM_INTERFACES__MSG__DETAIL__TARGET_STATE__STRUCT_H_
#define SWARM_INTERFACES__MSG__DETAIL__TARGET_STATE__STRUCT_H_

#ifdef __cplusplus
extern "C"
{
#endif

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>


// Constants defined in the message

// Include directives for member types
// Member 'stamp'
#include "builtin_interfaces/msg/detail/time__struct.h"

/// Struct defined in msg/TargetState in the package swarm_interfaces.
typedef struct swarm_interfaces__msg__TargetState
{
  int32_t target_id;
  double x;
  double y;
  double vx;
  double vy;
  builtin_interfaces__msg__Time stamp;
} swarm_interfaces__msg__TargetState;

// Struct for a sequence of swarm_interfaces__msg__TargetState.
typedef struct swarm_interfaces__msg__TargetState__Sequence
{
  swarm_interfaces__msg__TargetState * data;
  /// The number of valid items in data
  size_t size;
  /// The number of allocated items in data
  size_t capacity;
} swarm_interfaces__msg__TargetState__Sequence;

#ifdef __cplusplus
}
#endif

#endif  // SWARM_INTERFACES__MSG__DETAIL__TARGET_STATE__STRUCT_H_
