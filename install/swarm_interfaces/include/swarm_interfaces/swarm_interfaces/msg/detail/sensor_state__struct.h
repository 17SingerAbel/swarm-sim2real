// generated from rosidl_generator_c/resource/idl__struct.h.em
// with input from swarm_interfaces:msg/SensorState.idl
// generated code does not contain a copyright notice

#ifndef SWARM_INTERFACES__MSG__DETAIL__SENSOR_STATE__STRUCT_H_
#define SWARM_INTERFACES__MSG__DETAIL__SENSOR_STATE__STRUCT_H_

#ifdef __cplusplus
extern "C"
{
#endif

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>


// Constants defined in the message

// Include directives for member types
// Member 'fsm_state'
// Member 'role'
#include "rosidl_runtime_c/string.h"
// Member 'stamp'
#include "builtin_interfaces/msg/detail/time__struct.h"

/// Struct defined in msg/SensorState in the package swarm_interfaces.
typedef struct swarm_interfaces__msg__SensorState
{
  int32_t sensor_id;
  rosidl_runtime_c__String fsm_state;
  rosidl_runtime_c__String role;
  int32_t assigned_target_id;
  double pos_x;
  double pos_y;
  builtin_interfaces__msg__Time stamp;
} swarm_interfaces__msg__SensorState;

// Struct for a sequence of swarm_interfaces__msg__SensorState.
typedef struct swarm_interfaces__msg__SensorState__Sequence
{
  swarm_interfaces__msg__SensorState * data;
  /// The number of valid items in data
  size_t size;
  /// The number of allocated items in data
  size_t capacity;
} swarm_interfaces__msg__SensorState__Sequence;

#ifdef __cplusplus
}
#endif

#endif  // SWARM_INTERFACES__MSG__DETAIL__SENSOR_STATE__STRUCT_H_
