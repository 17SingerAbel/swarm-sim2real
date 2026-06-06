// generated from rosidl_generator_c/resource/idl__functions.c.em
// with input from swarm_interfaces:msg/TargetState.idl
// generated code does not contain a copyright notice
#include "swarm_interfaces/msg/detail/target_state__functions.h"

#include <assert.h>
#include <stdbool.h>
#include <stdlib.h>
#include <string.h>

#include "rcutils/allocator.h"


// Include directives for member types
// Member `stamp`
#include "builtin_interfaces/msg/detail/time__functions.h"

bool
swarm_interfaces__msg__TargetState__init(swarm_interfaces__msg__TargetState * msg)
{
  if (!msg) {
    return false;
  }
  // target_id
  // x
  // y
  // vx
  // vy
  // stamp
  if (!builtin_interfaces__msg__Time__init(&msg->stamp)) {
    swarm_interfaces__msg__TargetState__fini(msg);
    return false;
  }
  return true;
}

void
swarm_interfaces__msg__TargetState__fini(swarm_interfaces__msg__TargetState * msg)
{
  if (!msg) {
    return;
  }
  // target_id
  // x
  // y
  // vx
  // vy
  // stamp
  builtin_interfaces__msg__Time__fini(&msg->stamp);
}

bool
swarm_interfaces__msg__TargetState__are_equal(const swarm_interfaces__msg__TargetState * lhs, const swarm_interfaces__msg__TargetState * rhs)
{
  if (!lhs || !rhs) {
    return false;
  }
  // target_id
  if (lhs->target_id != rhs->target_id) {
    return false;
  }
  // x
  if (lhs->x != rhs->x) {
    return false;
  }
  // y
  if (lhs->y != rhs->y) {
    return false;
  }
  // vx
  if (lhs->vx != rhs->vx) {
    return false;
  }
  // vy
  if (lhs->vy != rhs->vy) {
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
swarm_interfaces__msg__TargetState__copy(
  const swarm_interfaces__msg__TargetState * input,
  swarm_interfaces__msg__TargetState * output)
{
  if (!input || !output) {
    return false;
  }
  // target_id
  output->target_id = input->target_id;
  // x
  output->x = input->x;
  // y
  output->y = input->y;
  // vx
  output->vx = input->vx;
  // vy
  output->vy = input->vy;
  // stamp
  if (!builtin_interfaces__msg__Time__copy(
      &(input->stamp), &(output->stamp)))
  {
    return false;
  }
  return true;
}

swarm_interfaces__msg__TargetState *
swarm_interfaces__msg__TargetState__create()
{
  rcutils_allocator_t allocator = rcutils_get_default_allocator();
  swarm_interfaces__msg__TargetState * msg = (swarm_interfaces__msg__TargetState *)allocator.allocate(sizeof(swarm_interfaces__msg__TargetState), allocator.state);
  if (!msg) {
    return NULL;
  }
  memset(msg, 0, sizeof(swarm_interfaces__msg__TargetState));
  bool success = swarm_interfaces__msg__TargetState__init(msg);
  if (!success) {
    allocator.deallocate(msg, allocator.state);
    return NULL;
  }
  return msg;
}

void
swarm_interfaces__msg__TargetState__destroy(swarm_interfaces__msg__TargetState * msg)
{
  rcutils_allocator_t allocator = rcutils_get_default_allocator();
  if (msg) {
    swarm_interfaces__msg__TargetState__fini(msg);
  }
  allocator.deallocate(msg, allocator.state);
}


bool
swarm_interfaces__msg__TargetState__Sequence__init(swarm_interfaces__msg__TargetState__Sequence * array, size_t size)
{
  if (!array) {
    return false;
  }
  rcutils_allocator_t allocator = rcutils_get_default_allocator();
  swarm_interfaces__msg__TargetState * data = NULL;

  if (size) {
    data = (swarm_interfaces__msg__TargetState *)allocator.zero_allocate(size, sizeof(swarm_interfaces__msg__TargetState), allocator.state);
    if (!data) {
      return false;
    }
    // initialize all array elements
    size_t i;
    for (i = 0; i < size; ++i) {
      bool success = swarm_interfaces__msg__TargetState__init(&data[i]);
      if (!success) {
        break;
      }
    }
    if (i < size) {
      // if initialization failed finalize the already initialized array elements
      for (; i > 0; --i) {
        swarm_interfaces__msg__TargetState__fini(&data[i - 1]);
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
swarm_interfaces__msg__TargetState__Sequence__fini(swarm_interfaces__msg__TargetState__Sequence * array)
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
      swarm_interfaces__msg__TargetState__fini(&array->data[i]);
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

swarm_interfaces__msg__TargetState__Sequence *
swarm_interfaces__msg__TargetState__Sequence__create(size_t size)
{
  rcutils_allocator_t allocator = rcutils_get_default_allocator();
  swarm_interfaces__msg__TargetState__Sequence * array = (swarm_interfaces__msg__TargetState__Sequence *)allocator.allocate(sizeof(swarm_interfaces__msg__TargetState__Sequence), allocator.state);
  if (!array) {
    return NULL;
  }
  bool success = swarm_interfaces__msg__TargetState__Sequence__init(array, size);
  if (!success) {
    allocator.deallocate(array, allocator.state);
    return NULL;
  }
  return array;
}

void
swarm_interfaces__msg__TargetState__Sequence__destroy(swarm_interfaces__msg__TargetState__Sequence * array)
{
  rcutils_allocator_t allocator = rcutils_get_default_allocator();
  if (array) {
    swarm_interfaces__msg__TargetState__Sequence__fini(array);
  }
  allocator.deallocate(array, allocator.state);
}

bool
swarm_interfaces__msg__TargetState__Sequence__are_equal(const swarm_interfaces__msg__TargetState__Sequence * lhs, const swarm_interfaces__msg__TargetState__Sequence * rhs)
{
  if (!lhs || !rhs) {
    return false;
  }
  if (lhs->size != rhs->size) {
    return false;
  }
  for (size_t i = 0; i < lhs->size; ++i) {
    if (!swarm_interfaces__msg__TargetState__are_equal(&(lhs->data[i]), &(rhs->data[i]))) {
      return false;
    }
  }
  return true;
}

bool
swarm_interfaces__msg__TargetState__Sequence__copy(
  const swarm_interfaces__msg__TargetState__Sequence * input,
  swarm_interfaces__msg__TargetState__Sequence * output)
{
  if (!input || !output) {
    return false;
  }
  if (output->capacity < input->size) {
    const size_t allocation_size =
      input->size * sizeof(swarm_interfaces__msg__TargetState);
    rcutils_allocator_t allocator = rcutils_get_default_allocator();
    swarm_interfaces__msg__TargetState * data =
      (swarm_interfaces__msg__TargetState *)allocator.reallocate(
      output->data, allocation_size, allocator.state);
    if (!data) {
      return false;
    }
    // If reallocation succeeded, memory may or may not have been moved
    // to fulfill the allocation request, invalidating output->data.
    output->data = data;
    for (size_t i = output->capacity; i < input->size; ++i) {
      if (!swarm_interfaces__msg__TargetState__init(&output->data[i])) {
        // If initialization of any new item fails, roll back
        // all previously initialized items. Existing items
        // in output are to be left unmodified.
        for (; i-- > output->capacity; ) {
          swarm_interfaces__msg__TargetState__fini(&output->data[i]);
        }
        return false;
      }
    }
    output->capacity = input->size;
  }
  output->size = input->size;
  for (size_t i = 0; i < input->size; ++i) {
    if (!swarm_interfaces__msg__TargetState__copy(
        &(input->data[i]), &(output->data[i])))
    {
      return false;
    }
  }
  return true;
}
