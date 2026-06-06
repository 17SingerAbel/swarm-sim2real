// generated from rosidl_generator_cpp/resource/idl__struct.hpp.em
// with input from swarm_interfaces:msg/SensorState.idl
// generated code does not contain a copyright notice

#ifndef SWARM_INTERFACES__MSG__DETAIL__SENSOR_STATE__STRUCT_HPP_
#define SWARM_INTERFACES__MSG__DETAIL__SENSOR_STATE__STRUCT_HPP_

#include <algorithm>
#include <array>
#include <cstdint>
#include <memory>
#include <string>
#include <vector>

#include "rosidl_runtime_cpp/bounded_vector.hpp"
#include "rosidl_runtime_cpp/message_initialization.hpp"


// Include directives for member types
// Member 'stamp'
#include "builtin_interfaces/msg/detail/time__struct.hpp"

#ifndef _WIN32
# define DEPRECATED__swarm_interfaces__msg__SensorState __attribute__((deprecated))
#else
# define DEPRECATED__swarm_interfaces__msg__SensorState __declspec(deprecated)
#endif

namespace swarm_interfaces
{

namespace msg
{

// message struct
template<class ContainerAllocator>
struct SensorState_
{
  using Type = SensorState_<ContainerAllocator>;

  explicit SensorState_(rosidl_runtime_cpp::MessageInitialization _init = rosidl_runtime_cpp::MessageInitialization::ALL)
  : stamp(_init)
  {
    if (rosidl_runtime_cpp::MessageInitialization::ALL == _init ||
      rosidl_runtime_cpp::MessageInitialization::ZERO == _init)
    {
      this->sensor_id = 0l;
      this->fsm_state = "";
      this->role = "";
      this->assigned_target_id = 0l;
      this->pos_x = 0.0;
      this->pos_y = 0.0;
    }
  }

  explicit SensorState_(const ContainerAllocator & _alloc, rosidl_runtime_cpp::MessageInitialization _init = rosidl_runtime_cpp::MessageInitialization::ALL)
  : fsm_state(_alloc),
    role(_alloc),
    stamp(_alloc, _init)
  {
    if (rosidl_runtime_cpp::MessageInitialization::ALL == _init ||
      rosidl_runtime_cpp::MessageInitialization::ZERO == _init)
    {
      this->sensor_id = 0l;
      this->fsm_state = "";
      this->role = "";
      this->assigned_target_id = 0l;
      this->pos_x = 0.0;
      this->pos_y = 0.0;
    }
  }

  // field types and members
  using _sensor_id_type =
    int32_t;
  _sensor_id_type sensor_id;
  using _fsm_state_type =
    std::basic_string<char, std::char_traits<char>, typename std::allocator_traits<ContainerAllocator>::template rebind_alloc<char>>;
  _fsm_state_type fsm_state;
  using _role_type =
    std::basic_string<char, std::char_traits<char>, typename std::allocator_traits<ContainerAllocator>::template rebind_alloc<char>>;
  _role_type role;
  using _assigned_target_id_type =
    int32_t;
  _assigned_target_id_type assigned_target_id;
  using _pos_x_type =
    double;
  _pos_x_type pos_x;
  using _pos_y_type =
    double;
  _pos_y_type pos_y;
  using _stamp_type =
    builtin_interfaces::msg::Time_<ContainerAllocator>;
  _stamp_type stamp;

  // setters for named parameter idiom
  Type & set__sensor_id(
    const int32_t & _arg)
  {
    this->sensor_id = _arg;
    return *this;
  }
  Type & set__fsm_state(
    const std::basic_string<char, std::char_traits<char>, typename std::allocator_traits<ContainerAllocator>::template rebind_alloc<char>> & _arg)
  {
    this->fsm_state = _arg;
    return *this;
  }
  Type & set__role(
    const std::basic_string<char, std::char_traits<char>, typename std::allocator_traits<ContainerAllocator>::template rebind_alloc<char>> & _arg)
  {
    this->role = _arg;
    return *this;
  }
  Type & set__assigned_target_id(
    const int32_t & _arg)
  {
    this->assigned_target_id = _arg;
    return *this;
  }
  Type & set__pos_x(
    const double & _arg)
  {
    this->pos_x = _arg;
    return *this;
  }
  Type & set__pos_y(
    const double & _arg)
  {
    this->pos_y = _arg;
    return *this;
  }
  Type & set__stamp(
    const builtin_interfaces::msg::Time_<ContainerAllocator> & _arg)
  {
    this->stamp = _arg;
    return *this;
  }

  // constant declarations

  // pointer types
  using RawPtr =
    swarm_interfaces::msg::SensorState_<ContainerAllocator> *;
  using ConstRawPtr =
    const swarm_interfaces::msg::SensorState_<ContainerAllocator> *;
  using SharedPtr =
    std::shared_ptr<swarm_interfaces::msg::SensorState_<ContainerAllocator>>;
  using ConstSharedPtr =
    std::shared_ptr<swarm_interfaces::msg::SensorState_<ContainerAllocator> const>;

  template<typename Deleter = std::default_delete<
      swarm_interfaces::msg::SensorState_<ContainerAllocator>>>
  using UniquePtrWithDeleter =
    std::unique_ptr<swarm_interfaces::msg::SensorState_<ContainerAllocator>, Deleter>;

  using UniquePtr = UniquePtrWithDeleter<>;

  template<typename Deleter = std::default_delete<
      swarm_interfaces::msg::SensorState_<ContainerAllocator>>>
  using ConstUniquePtrWithDeleter =
    std::unique_ptr<swarm_interfaces::msg::SensorState_<ContainerAllocator> const, Deleter>;
  using ConstUniquePtr = ConstUniquePtrWithDeleter<>;

  using WeakPtr =
    std::weak_ptr<swarm_interfaces::msg::SensorState_<ContainerAllocator>>;
  using ConstWeakPtr =
    std::weak_ptr<swarm_interfaces::msg::SensorState_<ContainerAllocator> const>;

  // pointer types similar to ROS 1, use SharedPtr / ConstSharedPtr instead
  // NOTE: Can't use 'using' here because GNU C++ can't parse attributes properly
  typedef DEPRECATED__swarm_interfaces__msg__SensorState
    std::shared_ptr<swarm_interfaces::msg::SensorState_<ContainerAllocator>>
    Ptr;
  typedef DEPRECATED__swarm_interfaces__msg__SensorState
    std::shared_ptr<swarm_interfaces::msg::SensorState_<ContainerAllocator> const>
    ConstPtr;

  // comparison operators
  bool operator==(const SensorState_ & other) const
  {
    if (this->sensor_id != other.sensor_id) {
      return false;
    }
    if (this->fsm_state != other.fsm_state) {
      return false;
    }
    if (this->role != other.role) {
      return false;
    }
    if (this->assigned_target_id != other.assigned_target_id) {
      return false;
    }
    if (this->pos_x != other.pos_x) {
      return false;
    }
    if (this->pos_y != other.pos_y) {
      return false;
    }
    if (this->stamp != other.stamp) {
      return false;
    }
    return true;
  }
  bool operator!=(const SensorState_ & other) const
  {
    return !this->operator==(other);
  }
};  // struct SensorState_

// alias to use template instance with default allocator
using SensorState =
  swarm_interfaces::msg::SensorState_<std::allocator<void>>;

// constant definitions

}  // namespace msg

}  // namespace swarm_interfaces

#endif  // SWARM_INTERFACES__MSG__DETAIL__SENSOR_STATE__STRUCT_HPP_
