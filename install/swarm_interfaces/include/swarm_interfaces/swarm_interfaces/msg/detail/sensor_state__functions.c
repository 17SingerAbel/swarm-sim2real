// generated from rosidl_generator_c/resource/idl__functions.c.em
// with input from swarm_interfaces:msg/SensorState.idl
// generated code does not contain a copyright notice
#include "swarm_interfaces/msg/detail/sensor_state__functions.h"

#include <assert.h>
#include <stdbool.h>
#include <stdlib.h>
#include <string.h>

#include "rcutils/allocator.h"


// Include directives for member types
// Member `fsm_state`
// Member `role`
#include "rosidl_runtime_c/string_functions.h"
// Member `stamp`
#include "builtin_interfaces/msg/detail/time__functions.h"

bool
swarm_interfaces__msg__SensorState__init(swarm_interfaces__msg__SensorState * msg)
{
  if (!msg) {
    return false;
  }
  // sensor_id
  // fsm_state
  if (!rosidl_runtime_c__String__init(&msg->fsm_state)) {
    swarm_interfaces__msg__SensorState__fini(msg);
    return false;
  }
  // role
  if (!rosidl_runtime_c__String__init(&msg->role)) {
    swarm_interfaces__msg__SensorState__fini(msg);
    return false;
  }
  // assigned_target_id
  // pos_x
  // pos_y
  // stamp
  if (!builtin_interfaces__msg__Time__init(&msg->stamp)) {
    swarm_interfaces__msg__SensorState__fini(msg);
    return false;
  }
  return true;
}

void
swarm_interfaces__msg__SensorState__fini(swarm_interfaces__msg__SensorState * msg)
{
  if (!msg) {
    return;
  }
  // sensor_id
  // fsm_state
  rosidl_runtime_c__String__fini(&msg->fsm_state);
  // role
  rosidl_runtime_c__String__fini(&msg->role);
  // assigned_target_id
  // pos_x
  // pos_y
  // stamp
  builtin_interfaces__msg__Time__fini(&msg->stamp);
}

bool
swarm_interfaces__msg__SensorState__are_equal(const swarm_interfaces__msg__SensorState * lhs, const swarm_interfaces__msg__SensorState * rhs)
{
  if (!lhs || !rhs) {
    return false;
  }
  // sensor_id
  if (lhs->sensor_id != rhs->sensor_id) {
    return false;
  }
  // fsm_state
  if (!rosidl_runtime_c__String__are_equal(
      &(lhs->fsm_state), &(rhs->fsm_state)))
  {
    return false;
  }
  // role
  if (!rosidl_runtime_c__String__are_equal(
      &(lhs->role), &(rhs->role)))
  {
    return false;
  }
  // assigned_target_id
  if (lhs->assigned_target_id != rhs->assigned_target_id) {
    return false;
  }
  // pos_x
  if (lhs->pos_x != rhs->pos_x) {
    return false;
  }
  // pos_y
  if (lhs->pos_y != rhs->pos_y) {
    return false;
  }
  // stamp
  if (!builtin_interfaces__msg__Time__are_equal(
      &(lhs->stamp), &(rhs->stamp)))
  {
    return false;
  }
  return true;
}

bool
swarm_interfaces__msg__SensorState__copy(
  const swarm_interfaces__msg__SensorState * input,
  swarm_interfaces__msg__SensorState * output)
{
  if (!input || !output) {
    return false;
  }
  // sensor_id
  output->sensor_id = input->sensor_id;
  // fsm_state
  if (!rosidl_runtime_c__String__copy(
      &(input->fsm_state), &(output->fsm_state)))
  {
    return false;
  }
  // role
  if (!rosidl_runtime_c__String__copy(
      &(input->role), &(output->role)))
  {
    return false;
  }
  // assigned_target_id
  output->assigned_target_id = input->assigned_target_id;
  // pos_x
  output->pos_x = input->pos_x;
  // pos_y
  output->pos_y = input->pos_y;
  // stamp
  if (!builtin_interfaces__msg__Time__copy(
      &(input->stamp), &(output->stamp)))
  {
    return false;
  }
  return true;
}

swarm_interfaces__msg__SensorState *
swarm_interfaces__msg__SensorState__create()
{
  rcutils_allocator_t allocator = rcutils_get_default_allocator();
  swarm_interfaces__msg__SensorState * msg = (swarm_interfaces__msg__SensorState *)allocator.allocate(sizeof(swarm_interfaces__msg__SensorState), allocator.state);
  if (!msg) {
    return NULL;
  }
  memset(msg, 0, sizeof(swarm_interfaces__msg__SensorState));
  bool success = swarm_interfaces__msg__SensorState__init(msg);
  if (!success) {
    allocator.deallocate(msg, allocator.state);
    return NULL;
  }
  return msg;
}

void
swarm_interfaces__msg__SensorState__destroy(swarm_interfaces__msg__SensorState * msg)
{
  rcutils_allocator_t allocator = rcutils_get_default_allocator();
  if (msg) {
    swarm_interfaces__msg__SensorState__fini(msg);
  }
  allocator.deallocate(msg, allocator.state);
}


bool
swarm_interfaces__msg__SensorState__Sequence__init(swarm_interfaces__msg__SensorState__Sequence * array, size_t size)
{
  if (!array) {
    return false;
  }
  rcutils_allocator_t allocator = rcutils_get_default_allocator();
  swarm_interfaces__msg__SensorState * data = NULL;

  if (size) {
    data = (swarm_interfaces__msg__SensorState *)allocator.zero_allocate(size, sizeof(swarm_interfaces__msg__SensorState), allocator.state);
    if (!data) {
      return false;
    }
    // initialize all array elements
    size_t i;
    for (i = 0; i < size; ++i) {
      bool success = swarm_interfaces__msg__SensorState__init(&data[i]);
      if (!success) {
        break;
      }
    }
    if (i < size) {
      // if initialization failed finalize the already initialized array elements
      for (; i > 0; --i) {
        swarm_interfaces__msg__SensorState__fini(&data[i - 1]);
      }
      allocator.deallocate(data, allocator.state);
      return false;
    }
  }
  array->data = data;
  array->size = size;
  array->capacity = size;
  return true;
}

void
swarm_interfaces__msg__SensorState__Sequence__fini(swarm_interfaces__msg__SensorState__Sequence * array)
{
  if (!array) {
    return;
  }
  rcutils_allocator_t allocator = rcutils_get_default_allocator();

  if (array->data) {
    // ensure that data and capacity values are consistent
    assert(array->capacity > 0);
    // finalize all array elements
    for (size_t i = 0; i < array->capacity; ++i) {
      swarm_interfaces__msg__SensorState__fini(&array->data[i]);
    }
    allocator.deallocate(array->data, allocator.state);
    array->data = NULL;
    array->size = 0;
    array->capacity = 0;
  } else {
    // ensure that data, size, and capacity values are consistent
    assert(0 == array->size);
    assert(0 == array->capacity);
  }
}

swarm_interfaces__msg__SensorState__Sequence *
swarm_interfaces__msg__SensorState__Sequence__create(size_t size)
{
  rcutils_allocator_t allocator = rcutils_get_default_allocator();
  swarm_interfaces__msg__SensorState__Sequence * array = (swarm_interfaces__msg__SensorState__Sequence *)allocator.allocate(sizeof(swarm_interfaces__msg__SensorState__Sequence), allocator.state);
  if (!array) {
    return NULL;
  }
  bool success = swarm_interfaces__msg__SensorState__Sequence__init(array, size);
  if (!success) {
    allocator.deallocate(array, allocator.state);
    return NULL;
  }
  return array;
}

void
swarm_interfaces__msg__SensorState__Sequence__destroy(swarm_interfaces__msg__SensorState__Sequence * array)
{
  rcutils_allocator_t allocator = rcutils_get_default_allocator();
  if (array) {
    swarm_interfaces__msg__SensorState__Sequence__fini(array);
  }
  allocator.deallocate(array, allocator.state);
}

bool
swarm_interfaces__msg__SensorState__Sequence__are_equal(const swarm_interfaces__msg__SensorState__Sequence * lhs, const swarm_interfaces__msg__SensorState__Sequence * rhs)
{
  if (!lhs || !rhs) {
    return false;
  }
  if (lhs->size != rhs->size) {
    return false;
  }
  for (size_t i = 0; i < lhs->size; ++i) {
    if (!swarm_interfaces__msg__SensorState__are_equal(&(lhs->data[i]), &(rhs->data[i]))) {
      return false;
    }
  }
  return true;
}

bool
swarm_interfaces__msg__SensorState__Sequence__copy(
  const swarm_interfaces__msg__SensorState__Sequence * input,
  swarm_interfaces__msg__SensorState__Sequence * output)
{
  if (!input || !output) {
    return false;
  }
  if (output->capacity < input->size) {
    const size_t allocation_size =
      input->size * sizeof(swarm_interfaces__msg__SensorState);
    rcutils_allocator_t allocator = rcutils_get_default_allocator();
    swarm_interfaces__msg__SensorState * data =
      (swarm_interfaces__msg__SensorState *)allocator.reallocate(
      output->data, allocation_size, allocator.state);
    if (!data) {
      return false;
    }
    // If reallocation succeeded, memory may or may not have been moved
    // to fulfill the allocation request, invalidating output->data.
    output->data = data;
    for (size_t i = output->capacity; i < input->size; ++i) {
      if (!swarm_interfaces__msg__SensorState__init(&output->data[i])) {
        // If initialization of any new item fails, roll back
        // all previously initialized items. Existing items
        // in output are to be left unmodified.
        for (; i-- > output->capacity; ) {
          swarm_interfaces__msg__SensorState__fini(&output->data[i]);
        }
        return false;
      }
    }
    output->capacity = input->size;
  }
  output->size = input->size;
  for (size_t i = 0; i < input->size; ++i) {
    if (!swarm_interfaces__msg__SensorState__copy(
        &(input->data[i]), &(output->data[i])))
    {
      return false;
    }
  }
  return true;
}
