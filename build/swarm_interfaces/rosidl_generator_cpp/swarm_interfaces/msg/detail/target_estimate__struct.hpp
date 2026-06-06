// generated from rosidl_generator_cpp/resource/idl__struct.hpp.em
// with input from swarm_interfaces:msg/TargetEstimate.idl
// generated code does not contain a copyright notice

#ifndef SWARM_INTERFACES__MSG__DETAIL__TARGET_ESTIMATE__STRUCT_HPP_
#define SWARM_INTERFACES__MSG__DETAIL__TARGET_ESTIMATE__STRUCT_HPP_

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
# define DEPRECATED__swarm_interfaces__msg__TargetEstimate __attribute__((deprecated))
#else
# define DEPRECATED__swarm_interfaces__msg__TargetEstimate __declspec(deprecated)
#endif

namespace swarm_interfaces
{

namespace msg
{

// message struct
template<class ContainerAllocator>
struct TargetEstimate_
{
  using Type = TargetEstimate_<ContainerAllocator>;

  explicit TargetEstimate_(rosidl_runtime_cpp::MessageInitialization _init = rosidl_runtime_cpp::MessageInitialization::ALL)
  : stamp(_init)
  {
    if (rosidl_runtime_cpp::MessageInitialization::ALL == _init ||
      rosidl_runtime_cpp::MessageInitialization::ZERO == _init)
    {
      this->sensor_id = 0l;
      this->target_id = 0l;
      this->x = 0.0;
      this->y = 0.0;
      this->vx = 0.0;
      this->vy = 0.0;
      std::fill<typename std::array<double, 4>::iterator, double>(this->covariance.begin(), this->covariance.end(), 0.0);
      this->ekf_converged = false;
    }
  }

  explicit TargetEstimate_(const ContainerAllocator & _alloc, rosidl_runtime_cpp::MessageInitialization _init = rosidl_runtime_cpp::MessageInitialization::ALL)
  : covariance(_alloc),
    stamp(_alloc, _init)
  {
    if (rosidl_runtime_cpp::MessageInitialization::ALL == _init ||
      rosidl_runtime_cpp::MessageInitialization::ZERO == _init)
    {
      this->sensor_id = 0l;
      this->target_id = 0l;
      this->x = 0.0;
      this->y = 0.0;
      this->vx = 0.0;
      this->vy = 0.0;
      std::fill<typename std::array<double, 4>::iterator, double>(this->covariance.begin(), this->covariance.end(), 0.0);
      this->ekf_converged = false;
    }
  }

  // field types and members
  using _sensor_id_type =
    int32_t;
  _sensor_id_type sensor_id;
  using _target_id_type =
    int32_t;
  _target_id_type target_id;
  using _x_type =
    double;
  _x_type x;
  using _y_type =
    double;
  _y_type y;
  using _vx_type =
    double;
  _vx_type vx;
  using _vy_type =
    double;
  _vy_type vy;
  using _covariance_type =
    std::array<double, 4>;
  _covariance_type covariance;
  using _ekf_converged_type =
    bool;
  _ekf_converged_type ekf_converged;
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
  Type & set__target_id(
    const int32_t & _arg)
  {
    this->target_id = _arg;
    return *this;
  }
  Type & set__x(
    const double & _arg)
  {
    this->x = _arg;
    return *this;
  }
  Type & set__y(
    const double & _arg)
  {
    this->y = _arg;
    return *this;
  }
  Type & set__vx(
    const double & _arg)
  {
    this->vx = _arg;
    return *this;
  }
  Type & set__vy(
    const double & _arg)
  {
    this->vy = _arg;
    return *this;
  }
  Type & set__covariance(
    const std::array<double, 4> & _arg)
  {
    this->covariance = _arg;
    return *this;
  }
  Type & set__ekf_converged(
    const bool & _arg)
  {
    this->ekf_converged = _arg;
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
    swarm_interfaces::msg::TargetEstimate_<ContainerAllocator> *;
  using ConstRawPtr =
    const swarm_interfaces::msg::TargetEstimate_<ContainerAllocator> *;
  using SharedPtr =
    std::shared_ptr<swarm_interfaces::msg::TargetEstimate_<ContainerAllocator>>;
  using ConstSharedPtr =
    std::shared_ptr<swarm_interfaces::msg::TargetEstimate_<ContainerAllocator> const>;

  template<typename Deleter = std::default_delete<
      swarm_interfaces::msg::TargetEstimate_<ContainerAllocator>>>
  using UniquePtrWithDeleter =
    std::unique_ptr<swarm_interfaces::msg::TargetEstimate_<ContainerAllocator>, Deleter>;

  using UniquePtr = UniquePtrWithDeleter<>;

  template<typename Deleter = std::default_delete<
      swarm_interfaces::msg::TargetEstimate_<ContainerAllocator>>>
  using ConstUniquePtrWithDeleter =
    std::unique_ptr<swarm_interfaces::msg::TargetEstimate_<ContainerAllocator> const, Deleter>;
  using ConstUniquePtr = ConstUniquePtrWithDeleter<>;

  using WeakPtr =
    std::weak_ptr<swarm_interfaces::msg::TargetEstimate_<ContainerAllocator>>;
  using ConstWeakPtr =
    std::weak_ptr<swarm_interfaces::msg::TargetEstimate_<ContainerAllocator> const>;

  // pointer types similar to ROS 1, use SharedPtr / ConstSharedPtr instead
  // NOTE: Can't use 'using' here because GNU C++ can't parse attributes properly
  typedef DEPRECATED__swarm_interfaces__msg__TargetEstimate
    std::shared_ptr<swarm_interfaces::msg::TargetEstimate_<ContainerAllocator>>
    Ptr;
  typedef DEPRECATED__swarm_interfaces__msg__TargetEstimate
    std::shared_ptr<swarm_interfaces::msg::TargetEstimate_<ContainerAllocator> const>
    ConstPtr;

  // comparison operators
  bool operator==(const TargetEstimate_ & other) const
  {
    if (this->sensor_id != other.sensor_id) {
      return false;
    }
    if (this->target_id != other.target_id) {
      return false;
    }
    if (this->x != other.x) {
      return false;
    }
    if (this->y != other.y) {
      return false;
    }
    if (this->vx != other.vx) {
      return false;
    }
    if (this->vy != other.vy) {
      return false;
    }
    if (this->covariance != other.covariance) {
      return false;
    }
    if (this->ekf_converged != other.ekf_converged) {
      return false;
    }
    if (this->stamp != other.stamp) {
      return false;
    }
    return true;
  }
  bool operator!=(const TargetEstimate_ & other) const
  {
    return !this->operator==(other);
  }
};  // struct TargetEstimate_

// alias to use template instance with default allocator
using TargetEstimate =
  swarm_interfaces::msg::TargetEstimate_<std::allocator<void>>;

// constant definitions

}  // namespace msg

}  // namespace swarm_interfaces

#endif  // SWARM_INTERFACES__MSG__DETAIL__TARGET_ESTIMATE__STRUCT_HPP_
