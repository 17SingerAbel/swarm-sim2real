// generated from rosidl_generator_cpp/resource/idl__builder.hpp.em
// with input from swarm_interfaces:msg/TargetEstimate.idl
// generated code does not contain a copyright notice

#ifndef SWARM_INTERFACES__MSG__DETAIL__TARGET_ESTIMATE__BUILDER_HPP_
#define SWARM_INTERFACES__MSG__DETAIL__TARGET_ESTIMATE__BUILDER_HPP_

#include <algorithm>
#include <utility>

#include "swarm_interfaces/msg/detail/target_estimate__struct.hpp"
#include "rosidl_runtime_cpp/message_initialization.hpp"


namespace swarm_interfaces
{

namespace msg
{

namespace builder
{

class Init_TargetEstimate_stamp
{
public:
  explicit Init_TargetEstimate_stamp(::swarm_interfaces::msg::TargetEstimate & msg)
  : msg_(msg)
  {}
  ::swarm_interfaces::msg::TargetEstimate stamp(::swarm_interfaces::msg::TargetEstimate::_stamp_type arg)
  {
    msg_.stamp = std::move(arg);
    return std::move(msg_);
  }

private:
  ::swarm_interfaces::msg::TargetEstimate msg_;
};

class Init_TargetEstimate_ekf_converged
{
public:
  explicit Init_TargetEstimate_ekf_converged(::swarm_interfaces::msg::TargetEstimate & msg)
  : msg_(msg)
  {}
  Init_TargetEstimate_stamp ekf_converged(::swarm_interfaces::msg::TargetEstimate::_ekf_converged_type arg)
  {
    msg_.ekf_converged = std::move(arg);
    return Init_TargetEstimate_stamp(msg_);
  }

private:
  ::swarm_interfaces::msg::TargetEstimate msg_;
};

class Init_TargetEstimate_covariance
{
public:
  explicit Init_TargetEstimate_covariance(::swarm_interfaces::msg::TargetEstimate & msg)
  : msg_(msg)
  {}
  Init_TargetEstimate_ekf_converged covariance(::swarm_interfaces::msg::TargetEstimate::_covariance_type arg)
  {
    msg_.covariance = std::move(arg);
    return Init_TargetEstimate_ekf_converged(msg_);
  }

private:
  ::swarm_interfaces::msg::TargetEstimate msg_;
};

class Init_TargetEstimate_vy
{
public:
  explicit Init_TargetEstimate_vy(::swarm_interfaces::msg::TargetEstimate & msg)
  : msg_(msg)
  {}
  Init_TargetEstimate_covariance vy(::swarm_interfaces::msg::TargetEstimate::_vy_type arg)
  {
    msg_.vy = std::move(arg);
    return Init_TargetEstimate_covariance(msg_);
  }

private:
  ::swarm_interfaces::msg::TargetEstimate msg_;
};

class Init_TargetEstimate_vx
{
public:
  explicit Init_TargetEstimate_vx(::swarm_interfaces::msg::TargetEstimate & msg)
  : msg_(msg)
  {}
  Init_TargetEstimate_vy vx(::swarm_interfaces::msg::TargetEstimate::_vx_type arg)
  {
    msg_.vx = std::move(arg);
    return Init_TargetEstimate_vy(msg_);
  }

private:
  ::swarm_interfaces::msg::TargetEstimate msg_;
};

class Init_TargetEstimate_y
{
public:
  explicit Init_TargetEstimate_y(::swarm_interfaces::msg::TargetEstimate & msg)
  : msg_(msg)
  {}
  Init_TargetEstimate_vx y(::swarm_interfaces::msg::TargetEstimate::_y_type arg)
  {
    msg_.y = std::move(arg);
    return Init_TargetEstimate_vx(msg_);
  }

private:
  ::swarm_interfaces::msg::TargetEstimate msg_;
};

class Init_TargetEstimate_x
{
public:
  explicit Init_TargetEstimate_x(::swarm_interfaces::msg::TargetEstimate & msg)
  : msg_(msg)
  {}
  Init_TargetEstimate_y x(::swarm_interfaces::msg::TargetEstimate::_x_type arg)
  {
    msg_.x = std::move(arg);
    return Init_TargetEstimate_y(msg_);
  }

private:
  ::swarm_interfaces::msg::TargetEstimate msg_;
};

class Init_TargetEstimate_target_id
{
public:
  explicit Init_TargetEstimate_target_id(::swarm_interfaces::msg::TargetEstimate & msg)
  : msg_(msg)
  {}
  Init_TargetEstimate_x target_id(::swarm_interfaces::msg::TargetEstimate::_target_id_type arg)
  {
    msg_.target_id = std::move(arg);
    return Init_TargetEstimate_x(msg_);
  }

private:
  ::swarm_interfaces::msg::TargetEstimate msg_;
};

class Init_TargetEstimate_sensor_id
{
public:
  Init_TargetEstimate_sensor_id()
  : msg_(::rosidl_runtime_cpp::MessageInitialization::SKIP)
  {}
  Init_TargetEstimate_target_id sensor_id(::swarm_interfaces::msg::TargetEstimate::_sensor_id_type arg)
  {
    msg_.sensor_id = std::move(arg);
    return Init_TargetEstimate_target_id(msg_);
  }

private:
  ::swarm_interfaces::msg::TargetEstimate msg_;
};

}  // namespace builder

}  // namespace msg

template<typename MessageType>
auto build();

template<>
inline
auto build<::swarm_interfaces::msg::TargetEstimate>()
{
  return swarm_interfaces::msg::builder::Init_TargetEstimate_sensor_id();
}

}  // namespace swarm_interfaces

#endif  // SWARM_INTERFACES__MSG__DETAIL__TARGET_ESTIMATE__BUILDER_HPP_
