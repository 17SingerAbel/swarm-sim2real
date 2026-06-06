// generated from rosidl_typesupport_introspection_c/resource/idl__type_support.c.em
// with input from swarm_interfaces:msg/SensorState.idl
// generated code does not contain a copyright notice

#include <stddef.h>
#include "swarm_interfaces/msg/detail/sensor_state__rosidl_typesupport_introspection_c.h"
#include "swarm_interfaces/msg/rosidl_typesupport_introspection_c__visibility_control.h"
#include "rosidl_typesupport_introspection_c/field_types.h"
#include "rosidl_typesupport_introspection_c/identifier.h"
#include "rosidl_typesupport_introspection_c/message_introspection.h"
#include "swarm_interfaces/msg/detail/sensor_state__functions.h"
#include "swarm_interfaces/msg/detail/sensor_state__struct.h"


// Include directives for member types
// Member `fsm_state`
// Member `role`
#include "rosidl_runtime_c/string_functions.h"
// Member `stamp`
#include "builtin_interfaces/msg/time.h"
// Member `stamp`
#include "builtin_interfaces/msg/detail/time__rosidl_typesupport_introspection_c.h"

#ifdef __cplusplus
extern "C"
{
#endif

void swarm_interfaces__msg__SensorState__rosidl_typesupport_introspection_c__SensorState_init_function(
  void * message_memory, enum rosidl_runtime_c__message_initialization _init)
{
  // TODO(karsten1987): initializers are not yet implemented for typesupport c
  // see https://github.com/ros2/ros2/issues/397
  (void) _init;
  swarm_interfaces__msg__SensorState__init(message_memory);
}

void swarm_interfaces__msg__SensorState__rosidl_typesupport_introspection_c__SensorState_fini_function(void * message_memory)
{
  swarm_interfaces__msg__SensorState__fini(message_memory);
}

static rosidl_typesupport_introspection_c__MessageMember swarm_interfaces__msg__SensorState__rosidl_typesupport_introspection_c__SensorState_message_member_array[7] = {
  {
    "sensor_id",  // name
    rosidl_typesupport_introspection_c__ROS_TYPE_INT32,  // type
    0,  // upper bound of string
    NULL,  // members of sub message
    false,  // is array
    0,  // array size
    false,  // is upper bound
    offsetof(swarm_interfaces__msg__SensorState, sensor_id),  // bytes offset in struct
    NULL,  // default value
    NULL,  // size() function pointer
    NULL,  // get_const(index) function pointer
    NULL,  // get(index) function pointer
    NULL,  // fetch(index, &value) function pointer
    NULL,  // assign(index, value) function pointer
    NULL  // resize(index) function pointer
  },
  {
    "fsm_state",  // name
    rosidl_typesupport_introspection_c__ROS_TYPE_STRING,  // type
    0,  // upper bound of string
    NULL,  // members of sub message
    false,  // is array
    0,  // array size
    false,  // is upper bound
    offsetof(swarm_interfaces__msg__SensorState, fsm_state),  // bytes offset in struct
    NULL,  // default value
    NULL,  // size() function pointer
    NULL,  // get_const(index) function pointer
    NULL,  // get(index) function pointer
    NULL,  // fetch(index, &value) function pointer
    NULL,  // assign(index, value) function pointer
    NULL  // resize(index) function pointer
  },
  {
    "role",  // name
    rosidl_typesupport_introspection_c__ROS_TYPE_STRING,  // type
    0,  // upper bound of string
    NULL,  // members of sub message
    false,  // is array
    0,  // array size
    false,  // is upper bound
    offsetof(swarm_interfaces__msg__SensorState, role),  // bytes offset in struct
    NULL,  // default value
    NULL,  // size() function pointer
    NULL,  // get_const(index) function pointer
    NULL,  // get(index) function pointer
    NULL,  // fetch(index, &value) function pointer
    NULL,  // assign(index, value) function pointer
    NULL  // resize(index) function pointer
  },
  {
    "assigned_target_id",  // name
    rosidl_typesupport_introspection_c__ROS_TYPE_INT32,  // type
    0,  // upper bound of string
    NULL,  // members of sub message
    false,  // is array
    0,  // array size
    false,  // is upper bound
    offsetof(swarm_interfaces__msg__SensorState, assigned_target_id),  // bytes offset in struct
    NULL,  // default value
    NULL,  // size() function pointer
    NULL,  // get_const(index) function pointer
    NULL,  // get(index) function pointer
    NULL,  // fetch(index, &value) function pointer
    NULL,  // assign(index, value) function pointer
    NULL  // resize(index) function pointer
  },
  {
    "pos_x",  // name
    rosidl_typesupport_introspection_c__ROS_TYPE_DOUBLE,  // type
    0,  // upper bound of string
    NULL,  // members of sub message
    false,  // is array
    0,  // array size
    false,  // is upper bound
    offsetof(swarm_interfaces__msg__SensorState, pos_x),  // bytes offset in struct
    NULL,  // default value
    NULL,  // size() function pointer
    NULL,  // get_const(index) function pointer
    NULL,  // get(index) function pointer
    NULL,  // fetch(index, &value) function pointer
    NULL,  // assign(index, value) function pointer
    NULL  // resize(index) function pointer
  },
  {
    "pos_y",  // name
    rosidl_typesupport_introspection_c__ROS_TYPE_DOUBLE,  // type
    0,  // upper bound of string
    NULL,  // members of sub message
    false,  // is array
    0,  // array size
    false,  // is upper bound
    offsetof(swarm_interfaces__msg__SensorState, pos_y),  // bytes offset in struct
    NULL,  // default value
    NULL,  // size() function pointer
    NULL,  // get_const(index) function pointer
    NULL,  // get(index) function pointer
    NULL,  // fetch(index, &value) function pointer
    NULL,  // assign(index, value) function pointer
    NULL  // resize(index) function pointer
  },
  {
    "stamp",  // name
    rosidl_typesupport_introspection_c__ROS_TYPE_MESSAGE,  // type
    0,  // upper bound of string
    NULL,  // members of sub message (initialized later)
    false,  // is array
    0,  // array size
    false,  // is upper bound
    offsetof(swarm_interfaces__msg__SensorState, stamp),  // bytes offset in struct
    NULL,  // default value
    NULL,  // size() function pointer
    NULL,  // get_const(index) function pointer
    NULL,  // get(index) function pointer
    NULL,  // fetch(index, &value) function pointer
    NULL,  // assign(index, value) function pointer
    NULL  // resize(index) function pointer
  }
};

static const rosidl_typesupport_introspection_c__MessageMembers swarm_interfaces__msg__SensorState__rosidl_typesupport_introspection_c__SensorState_message_members = {
  "swarm_interfaces__msg",  // message namespace
  "SensorState",  // message name
  7,  // number of fields
  sizeof(swarm_interfaces__msg__SensorState),
  swarm_interfaces__msg__SensorState__rosidl_typesupport_introspection_c__SensorState_message_member_array,  // message members
  swarm_interfaces__msg__SensorState__rosidl_typesupport_introspection_c__SensorState_init_function,  // function to initialize message memory (memory has to be allocated)
  swarm_interfaces__msg__SensorState__rosidl_typesupport_introspection_c__SensorState_fini_function  // function to terminate message instance (will not free memory)
};

// this is not const since it must be initialized on first access
// since C does not allow non-integral compile-time constants
static rosidl_message_type_support_t swarm_interfaces__msg__SensorState__rosidl_typesupport_introspection_c__SensorState_message_type_support_handle = {
  0,
  &swarm_interfaces__msg__SensorState__rosidl_typesupport_introspection_c__SensorState_message_members,
  get_message_typesupport_handle_function,
};

ROSIDL_TYPESUPPORT_INTROSPECTION_C_EXPORT_swarm_interfaces
const rosidl_message_type_support_t *
ROSIDL_TYPESUPPORT_INTERFACE__MESSAGE_SYMBOL_NAME(rosidl_typesupport_introspection_c, swarm_interfaces, msg, SensorState)() {
  swarm_interfaces__msg__SensorState__rosidl_typesupport_introspection_c__SensorState_message_member_array[6].members_ =
    ROSIDL_TYPESUPPORT_INTERFACE__MESSAGE_SYMBOL_NAME(rosidl_typesupport_introspection_c, builtin_interfaces, msg, Time)();
  if (!swarm_interfaces__msg__SensorState__rosidl_typesupport_introspection_c__SensorState_message_type_support_handle.typesupport_identifier) {
    swarm_interfaces__msg__SensorState__rosidl_typesupport_introspection_c__SensorState_message_type_support_handle.typesupport_identifier =
      rosidl_typesupport_introspection_c__identifier;
  }
  return &swarm_interfaces__msg__SensorState__rosidl_typesupport_introspection_c__SensorState_message_type_support_handle;
}
#ifdef __cplusplus
}
#endif
