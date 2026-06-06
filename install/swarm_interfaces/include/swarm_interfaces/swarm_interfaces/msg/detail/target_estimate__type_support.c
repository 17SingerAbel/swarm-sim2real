// generated from rosidl_typesupport_introspection_c/resource/idl__type_support.c.em
// with input from swarm_interfaces:msg/TargetEstimate.idl
// generated code does not contain a copyright notice

#include <stddef.h>
#include "swarm_interfaces/msg/detail/target_estimate__rosidl_typesupport_introspection_c.h"
#include "swarm_interfaces/msg/rosidl_typesupport_introspection_c__visibility_control.h"
#include "rosidl_typesupport_introspection_c/field_types.h"
#include "rosidl_typesupport_introspection_c/identifier.h"
#include "rosidl_typesupport_introspection_c/message_introspection.h"
#include "swarm_interfaces/msg/detail/target_estimate__functions.h"
#include "swarm_interfaces/msg/detail/target_estimate__struct.h"


// Include directives for member types
// Member `stamp`
#include "builtin_interfaces/msg/time.h"
// Member `stamp`
#include "builtin_interfaces/msg/detail/time__rosidl_typesupport_introspection_c.h"

#ifdef __cplusplus
extern "C"
{
#endif

void swarm_interfaces__msg__TargetEstimate__rosidl_typesupport_introspection_c__TargetEstimate_init_function(
  void * message_memory, enum rosidl_runtime_c__message_initialization _init)
{
  // TODO(karsten1987): initializers are not yet implemented for typesupport c
  // see https://github.com/ros2/ros2/issues/397
  (void) _init;
  swarm_interfaces__msg__TargetEstimate__init(message_memory);
}

void swarm_interfaces__msg__TargetEstimate__rosidl_typesupport_introspection_c__TargetEstimate_fini_function(void * message_memory)
{
  swarm_interfaces__msg__TargetEstimate__fini(message_memory);
}

size_t swarm_interfaces__msg__TargetEstimate__rosidl_typesupport_introspection_c__size_function__TargetEstimate__covariance(
  const void * untyped_member)
{
  (void)untyped_member;
  return 4;
}

const void * swarm_interfaces__msg__TargetEstimate__rosidl_typesupport_introspection_c__get_const_function__TargetEstimate__covariance(
  const void * untyped_member, size_t index)
{
  const double * member =
    (const double *)(untyped_member);
  return &member[index];
}

void * swarm_interfaces__msg__TargetEstimate__rosidl_typesupport_introspection_c__get_function__TargetEstimate__covariance(
  void * untyped_member, size_t index)
{
  double * member =
    (double *)(untyped_member);
  return &member[index];
}

void swarm_interfaces__msg__TargetEstimate__rosidl_typesupport_introspection_c__fetch_function__TargetEstimate__covariance(
  const void * untyped_member, size_t index, void * untyped_value)
{
  const double * item =
    ((const double *)
    swarm_interfaces__msg__TargetEstimate__rosidl_typesupport_introspection_c__get_const_function__TargetEstimate__covariance(untyped_member, index));
  double * value =
    (double *)(untyped_value);
  *value = *item;
}

void swarm_interfaces__msg__TargetEstimate__rosidl_typesupport_introspection_c__assign_function__TargetEstimate__covariance(
  void * untyped_member, size_t index, const void * untyped_value)
{
  double * item =
    ((double *)
    swarm_interfaces__msg__TargetEstimate__rosidl_typesupport_introspection_c__get_function__TargetEstimate__covariance(untyped_member, index));
  const double * value =
    (const double *)(untyped_value);
  *item = *value;
}

static rosidl_typesupport_introspection_c__MessageMember swarm_interfaces__msg__TargetEstimate__rosidl_typesupport_introspection_c__TargetEstimate_message_member_array[9] = {
  {
    "sensor_id",  // name
    rosidl_typesupport_introspection_c__ROS_TYPE_INT32,  // type
    0,  // upper bound of string
    NULL,  // members of sub message
    false,  // is array
    0,  // array size
    false,  // is upper bound
    offsetof(swarm_interfaces__msg__TargetEstimate, sensor_id),  // bytes offset in struct
    NULL,  // default value
    NULL,  // size() function pointer
    NULL,  // get_const(index) function pointer
    NULL,  // get(index) function pointer
    NULL,  // fetch(index, &value) function pointer
    NULL,  // assign(index, value) function pointer
    NULL  // resize(index) function pointer
  },
  {
    "target_id",  // name
    rosidl_typesupport_introspection_c__ROS_TYPE_INT32,  // type
    0,  // upper bound of string
    NULL,  // members of sub message
    false,  // is array
    0,  // array size
    false,  // is upper bound
    offsetof(swarm_interfaces__msg__TargetEstimate, target_id),  // bytes offset in struct
    NULL,  // default value
    NULL,  // size() function pointer
    NULL,  // get_const(index) function pointer
    NULL,  // get(index) function pointer
    NULL,  // fetch(index, &value) function pointer
    NULL,  // assign(index, value) function pointer
    NULL  // resize(index) function pointer
  },
  {
    "x",  // name
    rosidl_typesupport_introspection_c__ROS_TYPE_DOUBLE,  // type
    0,  // upper bound of string
    NULL,  // members of sub message
    false,  // is array
    0,  // array size
    false,  // is upper bound
    offsetof(swarm_interfaces__msg__TargetEstimate, x),  // bytes offset in struct
    NULL,  // default value
    NULL,  // size() function pointer
    NULL,  // get_const(index) function pointer
    NULL,  // get(index) function pointer
    NULL,  // fetch(index, &value) function pointer
    NULL,  // assign(index, value) function pointer
    NULL  // resize(index) function pointer
  },
  {
    "y",  // name
    rosidl_typesupport_introspection_c__ROS_TYPE_DOUBLE,  // type
    0,  // upper bound of string
    NULL,  // members of sub message
    false,  // is array
    0,  // array size
    false,  // is upper bound
    offsetof(swarm_interfaces__msg__TargetEstimate, y),  // bytes offset in struct
    NULL,  // default value
    NULL,  // size() function pointer
    NULL,  // get_const(index) function pointer
    NULL,  // get(index) function pointer
    NULL,  // fetch(index, &value) function pointer
    NULL,  // assign(index, value) function pointer
    NULL  // resize(index) function pointer
  },
  {
    "vx",  // name
    rosidl_typesupport_introspection_c__ROS_TYPE_DOUBLE,  // type
    0,  // upper bound of string
    NULL,  // members of sub message
    false,  // is array
    0,  // array size
    false,  // is upper bound
    offsetof(swarm_interfaces__msg__TargetEstimate, vx),  // bytes offset in struct
    NULL,  // default value
    NULL,  // size() function pointer
    NULL,  // get_const(index) function pointer
    NULL,  // get(index) function pointer
    NULL,  // fetch(index, &value) function pointer
    NULL,  // assign(index, value) function pointer
    NULL  // resize(index) function pointer
  },
  {
    "vy",  // name
    rosidl_typesupport_introspection_c__ROS_TYPE_DOUBLE,  // type
    0,  // upper bound of string
    NULL,  // members of sub message
    false,  // is array
    0,  // array size
    false,  // is upper bound
    offsetof(swarm_interfaces__msg__TargetEstimate, vy),  // bytes offset in struct
    NULL,  // default value
    NULL,  // size() function pointer
    NULL,  // get_const(index) function pointer
    NULL,  // get(index) function pointer
    NULL,  // fetch(index, &value) function pointer
    NULL,  // assign(index, value) function pointer
    NULL  // resize(index) function pointer
  },
  {
    "covariance",  // name
    rosidl_typesupport_introspection_c__ROS_TYPE_DOUBLE,  // type
    0,  // upper bound of string
    NULL,  // members of sub message
    true,  // is array
    4,  // array size
    false,  // is upper bound
    offsetof(swarm_interfaces__msg__TargetEstimate, covariance),  // bytes offset in struct
    NULL,  // default value
    swarm_interfaces__msg__TargetEstimate__rosidl_typesupport_introspection_c__size_function__TargetEstimate__covariance,  // size() function pointer
    swarm_interfaces__msg__TargetEstimate__rosidl_typesupport_introspection_c__get_const_function__TargetEstimate__covariance,  // get_const(index) function pointer
    swarm_interfaces__msg__TargetEstimate__rosidl_typesupport_introspection_c__get_function__TargetEstimate__covariance,  // get(index) function pointer
    swarm_interfaces__msg__TargetEstimate__rosidl_typesupport_introspection_c__fetch_function__TargetEstimate__covariance,  // fetch(index, &value) function pointer
    swarm_interfaces__msg__TargetEstimate__rosidl_typesupport_introspection_c__assign_function__TargetEstimate__covariance,  // assign(index, value) function pointer
    NULL  // resize(index) function pointer
  },
  {
    "ekf_converged",  // name
    rosidl_typesupport_introspection_c__ROS_TYPE_BOOLEAN,  // type
    0,  // upper bound of string
    NULL,  // members of sub message
    false,  // is array
    0,  // array size
    false,  // is upper bound
    offsetof(swarm_interfaces__msg__TargetEstimate, ekf_converged),  // bytes offset in struct
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
    offsetof(swarm_interfaces__msg__TargetEstimate, stamp),  // bytes offset in struct
    NULL,  // default value
    NULL,  // size() function pointer
    NULL,  // get_const(index) function pointer
    NULL,  // get(index) function pointer
    NULL,  // fetch(index, &value) function pointer
    NULL,  // assign(index, value) function pointer
    NULL  // resize(index) function pointer
  }
};

static const rosidl_typesupport_introspection_c__MessageMembers swarm_interfaces__msg__TargetEstimate__rosidl_typesupport_introspection_c__TargetEstimate_message_members = {
  "swarm_interfaces__msg",  // message namespace
  "TargetEstimate",  // message name
  9,  // number of fields
  sizeof(swarm_interfaces__msg__TargetEstimate),
  swarm_interfaces__msg__TargetEstimate__rosidl_typesupport_introspection_c__TargetEstimate_message_member_array,  // message members
  swarm_interfaces__msg__TargetEstimate__rosidl_typesupport_introspection_c__TargetEstimate_init_function,  // function to initialize message memory (memory has to be allocated)
  swarm_interfaces__msg__TargetEstimate__rosidl_typesupport_introspection_c__TargetEstimate_fini_function  // function to terminate message instance (will not free memory)
};

// this is not const since it must be initialized on first access
// since C does not allow non-integral compile-time constants
static rosidl_message_type_support_t swarm_interfaces__msg__TargetEstimate__rosidl_typesupport_introspection_c__TargetEstimate_message_type_support_handle = {
  0,
  &swarm_interfaces__msg__TargetEstimate__rosidl_typesupport_introspection_c__TargetEstimate_message_members,
  get_message_typesupport_handle_function,
};

ROSIDL_TYPESUPPORT_INTROSPECTION_C_EXPORT_swarm_interfaces
const rosidl_message_type_support_t *
ROSIDL_TYPESUPPORT_INTERFACE__MESSAGE_SYMBOL_NAME(rosidl_typesupport_introspection_c, swarm_interfaces, msg, TargetEstimate)() {
  swarm_interfaces__msg__TargetEstimate__rosidl_typesupport_introspection_c__TargetEstimate_message_member_array[8].members_ =
    ROSIDL_TYPESUPPORT_INTERFACE__MESSAGE_SYMBOL_NAME(rosidl_typesupport_introspection_c, builtin_interfaces, msg, Time)();
  if (!swarm_interfaces__msg__TargetEstimate__rosidl_typesupport_introspection_c__TargetEstimate_message_type_support_handle.typesupport_identifier) {
    swarm_interfaces__msg__TargetEstimate__rosidl_typesupport_introspection_c__TargetEstimate_message_type_support_handle.typesupport_identifier =
      rosidl_typesupport_introspection_c__identifier;
  }
  return &swarm_interfaces__msg__TargetEstimate__rosidl_typesupport_introspection_c__TargetEstimate_message_type_support_handle;
}
#ifdef __cplusplus
}
#endif
