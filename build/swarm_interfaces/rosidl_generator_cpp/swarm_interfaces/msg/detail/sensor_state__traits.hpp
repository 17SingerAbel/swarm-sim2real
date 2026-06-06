// generated from rosidl_generator_cpp/resource/idl__traits.hpp.em
// with input from swarm_interfaces:msg/SensorState.idl
// generated code does not contain a copyright notice

#ifndef SWARM_INTERFACES__MSG__DETAIL__SENSOR_STATE__TRAITS_HPP_
#define SWARM_INTERFACES__MSG__DETAIL__SENSOR_STATE__TRAITS_HPP_

#include <stdint.h>

#include <sstream>
#include <string>
#include <type_traits>

#include "swarm_interfaces/msg/detail/sensor_state__struct.hpp"
#include "rosidl_runtime_cpp/traits.hpp"

// Include directives for member types
// Member 'stamp'
#include "builtin_interfaces/msg/detail/time__traits.hpp"

namespace swarm_interfaces
{

namespace msg
{

inline void to_flow_style_yaml(
  const SensorState & msg,
  std::ostream & out)
{
  out << "{";
  // member: sensor_id
  {
    out << "sensor_id: ";
    rosidl_generator_traits::value_to_yaml(msg.sensor_id, out);
    out << ", ";
  }

  // member: fsm_state
  {
    out << "fsm_state: ";
    rosidl_generator_traits::value_to_yaml(msg.fsm_state, out);
    out << ", ";
  }

  // member: role
  {
    out << "role: ";
    rosidl_generator_traits::value_to_yaml(msg.role, out);
    out << ", ";
  }

  // member: assigned_target_id
  {
    out << "assigned_target_id: ";
    rosidl_generator_traits::value_to_yaml(msg.assigned_target_id, out);
    out << ", ";
  }

  // member: pos_x
  {
    out << "pos_x: ";
    rosidl_generator_traits::value_to_yaml(msg.pos_x, out);
    out << ", ";
  }

  // member: pos_y
  {
    out << "pos_y: ";
    rosidl_generator_traits::value_to_yaml(msg.pos_y, out);
    out << ", ";
  }

  // member: stamp
  {
    out << "stamp: ";
    to_flow_style_yaml(msg.stamp, out);
  }
  out << "}";
}  // NOLINT(readability/fn_size)

inline void to_block_style_yaml(
  const SensorState & msg,
  std::ostream & out, size_t indentation = 0)
{
  // member: sensor_id
  {
    if (indentation > 0) {
      out << std::string(indentation, ' ');
    }
    out << "sensor_id: ";
    rosidl_generator_traits::value_to_yaml(msg.sensor_id, out);
    out << "\n";
  }

  // member: fsm_state
  {
    if (indentation > 0) {
      out << std::string(indentation, ' ');
    }
    out << "fsm_state: ";
    rosidl_generator_traits::value_to_yaml(msg.fsm_state, out);
    out << "\n";
  }

  // member: role
  {
    if (indentation > 0) {
      out << std::string(indentation, ' ');
    }
    out << "role: ";
    rosidl_generator_traits::value_to_yaml(msg.role, out);
    out << "\n";
  }

  // member: assigned_target_id
  {
    if (indentation > 0) {
      out << std::string(indentation, ' ');
    }
    out << "assigned_target_id: ";
    rosidl_generator_traits::value_to_yaml(msg.assigned_target_id, out);
    out << "\n";
  }

  // member: pos_x
  {
    if (indentation > 0) {
      out << std::string(indentation, ' ');
    }
    out << "pos_x: ";
    rosidl_generator_traits::value_to_yaml(msg.pos_x, out);
    out << "\n";
  }

  // member: pos_y
  {
    if (indentation > 0) {
      out << std::string(indentation, ' ');
    }
    out << "pos_y: ";
    rosidl_generator_traits::value_to_yaml(msg.pos_y, out);
    out << "\n";
  }

  // member: stamp
  {
    if (indentation > 0) {
      out << std::string(indentation, ' ');
    }
    out << "stamp:\n";
    to_block_style_yaml(msg.stamp, out, indentation + 2);
  }
}  // NOLINT(readability/fn_size)

inline std::string to_yaml(const SensorState & msg, bool use_flow_style = false)
{
  std::ostringstream out;
  if (use_flow_style) {
    to_flow_style_yaml(msg, out);
  } else {
    to_block_style_yaml(msg, out);
  }
  return out.str();
}

}  // namespace msg

}  // namespace swarm_interfaces

namespace rosidl_generator_traits
{

[[deprecated("use swarm_interfaces::msg::to_block_style_yaml() instead")]]
inline void to_yaml(
  const swarm_interfaces::msg::SensorState & msg,
  std::ostream & out, size_t indentation = 0)
{
  swarm_interfaces::msg::to_block_style_yaml(msg, out, indentation);
}

[[deprecated("use swarm_interfaces::msg::to_yaml() instead")]]
inline std::string to_yaml(const swarm_interfaces::msg::SensorState & msg)
{
  return swarm_interfaces::msg::to_yaml(msg);
}

template<>
inline const char * data_type<swarm_interfaces::msg::SensorState>()
{
  return "swarm_interfaces::msg::SensorState";
}

template<>
inline const char * name<swarm_interfaces::msg::SensorState>()
{
  return "swarm_interfaces/msg/SensorState";
}

template<>
struct has_fixed_size<swarm_interfaces::msg::SensorState>
  : std::integral_constant<bool, false> {};

template<>
struct has_bounded_size<swarm_interfaces::msg::SensorState>
  : std::integral_constant<bool, false> {};

template<>
struct is_message<swarm_interfaces::msg::SensorState>
  : std::true_type {};

}  // namespace rosidl_generator_traits

#endif  // SWARM_INTERFACES__MSG__DETAIL__SENSOR_STATE__TRAITS_HPP_
