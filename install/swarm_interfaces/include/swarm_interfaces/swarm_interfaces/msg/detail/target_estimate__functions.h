// generated from rosidl_generator_c/resource/idl__functions.h.em
// with input from swarm_interfaces:msg/TargetEstimate.idl
// generated code does not contain a copyright notice

#ifndef SWARM_INTERFACES__MSG__DETAIL__TARGET_ESTIMATE__FUNCTIONS_H_
#define SWARM_INTERFACES__MSG__DETAIL__TARGET_ESTIMATE__FUNCTIONS_H_

#ifdef __cplusplus
extern "C"
{
#endif

#include <stdbool.h>
#include <stdlib.h>

#include "rosidl_runtime_c/visibility_control.h"
#include "swarm_interfaces/msg/rosidl_generator_c__visibility_control.h"

#include "swarm_interfaces/msg/detail/target_estimate__struct.h"

/// Initialize msg/TargetEstimate message.
/**
 * If the init function is called twice for the same message without
 * calling fini inbetween previously allocated memory will be leaked.
 * \param[in,out] msg The previously allocated message pointer.
 * Fields without a default value will not be initialized by this function.
 * You might want to call memset(msg, 0, sizeof(
 * swarm_interfaces__msg__TargetEstimate
 * )) before or use
 * swarm_interfaces__msg__TargetEstimate__create()
 * to allocate and initialize the message.
 * \return true if initialization was successful, otherwise false
 */
ROSIDL_GENERATOR_C_PUBLIC_swarm_interfaces
bool
swarm_interfaces__msg__TargetEstimate__init(swarm_interfaces__msg__TargetEstimate * msg);

/// Finalize msg/TargetEstimate message.
/**
 * \param[in,out] msg The allocated message pointer.
 */
ROSIDL_GENERATOR_C_PUBLIC_swarm_interfaces
void
swarm_interfaces__msg__TargetEstimate__fini(swarm_interfaces__msg__TargetEstimate * msg);

/// Create msg/TargetEstimate message.
/**
 * It allocates the memory for the message, sets the memory to zero, and
 * calls
 * swarm_interfaces__msg__TargetEstimate__init().
 * \return The pointer to the initialized message if successful,
 * otherwise NULL
 */
ROSIDL_GENERATOR_C_PUBLIC_swarm_interfaces
swarm_interfaces__msg__TargetEstimate *
swarm_interfaces__msg__TargetEstimate__create();

/// Destroy msg/TargetEstimate message.
/**
 * It calls
 * swarm_interfaces__msg__TargetEstimate__fini()
 * and frees the memory of the message.
 * \param[in,out] msg The allocated message pointer.
 */
ROSIDL_GENERATOR_C_PUBLIC_swarm_interfaces
void
swarm_interfaces__msg__TargetEstimate__destroy(swarm_interfaces__msg__TargetEstimate * msg);

/// Check for msg/TargetEstimate message equality.
/**
 * \param[in] lhs The message on the left hand size of the equality operator.
 * \param[in] rhs The message on the right hand size of the equality operator.
 * \return true if messages are equal, otherwise false.
 */
ROSIDL_GENERATOR_C_PUBLIC_swarm_interfaces
bool
swarm_interfaces__msg__TargetEstimate__are_equal(const swarm_interfaces__msg__TargetEstimate * lhs, const swarm_interfaces__msg__TargetEstimate * rhs);

/// Copy a msg/TargetEstimate message.
/**
 * This functions performs a deep copy, as opposed to the shallow copy that
 * plain assignment yields.
 *
 * \param[in] input The source message pointer.
 * \param[out] output The target message pointer, which must
 *   have been initialized before calling this function.
 * \return true if successful, or false if either pointer is null
 *   or memory allocation fails.
 */
ROSIDL_GENERATOR_C_PUBLIC_swarm_interfaces
bool
swarm_interfaces__msg__TargetEstimate__copy(
  const swarm_interfaces__msg__TargetEstimate * input,
  swarm_interfaces__msg__TargetEstimate * output);

/// Initialize array of msg/TargetEstimate messages.
/**
 * It allocates the memory for the number of elements and calls
 * swarm_interfaces__msg__TargetEstimate__init()
 * for each element of the array.
 * \param[in,out] array The allocated array pointer.
 * \param[in] size The size / capacity of the array.
 * \return true if initialization was successful, otherwise false
 * If the array pointer is valid and the size is zero it is guaranteed
 # to return true.
 */
ROSIDL_GENERATOR_C_PUBLIC_swarm_interfaces
bool
swarm_interfaces__msg__TargetEstimate__Sequence__init(swarm_interfaces__msg__TargetEstimate__Sequence * array, size_t size);

/// Finalize array of msg/TargetEstimate messages.
/**
 * It calls
 * swarm_interfaces__msg__TargetEstimate__fini()
 * for each element of the array and frees the memory for the number of
 * elements.
 * \param[in,out] array The initialized array pointer.
 */
ROSIDL_GENERATOR_C_PUBLIC_swarm_interfaces
void
swarm_interfaces__msg__TargetEstimate__Sequence__fini(swarm_interfaces__msg__TargetEstimate__Sequence * array);

/// Create array of msg/TargetEstimate messages.
/**
 * It allocates the memory for the array and calls
 * swarm_interfaces__msg__TargetEstimate__Sequence__init().
 * \param[in] size The size / capacity of the array.
 * \return The pointer to the initialized array if successful, otherwise NULL
 */
ROSIDL_GENERATOR_C_PUBLIC_swarm_interfaces
swarm_interfaces__msg__TargetEstimate__Sequence *
swarm_interfaces__msg__TargetEstimate__Sequence__create(size_t size);

/// Destroy array of msg/TargetEstimate messages.
/**
 * It calls
 * swarm_interfaces__msg__TargetEstimate__Sequence__fini()
 * on the array,
 * and frees the memory of the array.
 * \param[in,out] array The initialized array pointer.
 */
ROSIDL_GENERATOR_C_PUBLIC_swarm_interfaces
void
swarm_interfaces__msg__TargetEstimate__Sequence__destroy(swarm_interfaces__msg__TargetEstimate__Sequence * array);

/// Check for msg/TargetEstimate message array equality.
/**
 * \param[in] lhs The message array on the left hand size of the equality operator.
 * \param[in] rhs The message array on the right hand size of the equality operator.
 * \return true if message arrays are equal in size and content, otherwise false.
 */
ROSIDL_GENERATOR_C_PUBLIC_swarm_interfaces
bool
swarm_interfaces__msg__TargetEstimate__Sequence__are_equal(const swarm_interfaces__msg__TargetEstimate__Sequence * lhs, const swarm_interfaces__msg__TargetEstimate__Sequence * rhs);

/// Copy an array of msg/TargetEstimate messages.
/**
 * This functions performs a deep copy, as opposed to the shallow copy that
 * plain assignment yields.
 *
 * \param[in] input The source array pointer.
 * \param[out] output The target array pointer, which must
 *   have been initialized before calling this function.
 * \return true if successful, or false if either pointer
 *   is null or memory allocation fails.
 */
ROSIDL_GENERATOR_C_PUBLIC_swarm_interfaces
bool
swarm_interfaces__msg__TargetEstimate__Sequence__copy(
  const swarm_interfaces__msg__TargetEstimate__Sequence * input,
  swarm_interfaces__msg__TargetEstimate__Sequence * output);

#ifdef __cplusplus
}
#endif

#endif  // SWARM_INTERFACES__MSG__DETAIL__TARGET_ESTIMATE__FUNCTIONS_H_
