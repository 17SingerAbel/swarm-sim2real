// generated from rosidl_generator_cpp/resource/idl__builder.hpp.em
// with input from swarm_interfaces:msg/TargetState.idl
// generated code does not contain a copyright notice

#ifndef SWARM_INTERFACES__MSG__DETAIL__TARGET_STATE__BUILDER_HPP_
#define SWARM_INTERFACES__MSG__DETAIL__TARGET_STATE__BUILDER_HPP_

#include <algorithm>
#include <utility>

#include "swarm_interfaces/msg/detail/target_state__struct.hpp"
#include "rosidl_runtime_cpp/message_initialization.hpp"


namespace swarm_interfaces
{

namespace msg
{

namespace builder
{

class Init_TargetState_stamp
{
public:
  explicit Init_TargetState_stamp(::swarm_interfaces::msg::TargetState & msg)
  : msg_(msg)
  {}
  ::swarm_interfaces::msg::TargetState stamp(::swarm_interfaces::msg::TargetState::_stamp_type arg)
  {
    msg_.stamp = std::move(arg);
    return std::move(msg_);
  }

private:
  ::swarm_interfaces::msg::TargetState msg_;
};

class Init_TargetState_vy
{
public:
  explicit Init_TargetState_vy(::swarm_interfaces::msg::TargetState & msg)
  : msg_(msg)
  {}
  Init_TargetState_stamp vy(::swarm_interfaces::msg::TargetState::_vy_type arg)
  {
    msg_.vy = std::move(arg);
    return Init_TargetState_stamp(msg_);
  }

private:
  ::swarm_interfaces::msg::TargetState msg_;
};

class Init_TargetState_vx
{
public:
  explicit Init_TargetState_vx(::swarm_interfaces::msg::TargetState & msg)
  : msg_(msg)
  {}
  Init_TargetState_vy vx(::swarm_interfaces::msg::TargetState::_vx_type arg)
  {
    msg_.vx = std::move(arg);
    return Init_TargetState_vy(msg_);
  }

private:
  ::swarm_interfaces::msg::TargetState msg_;
};

class Init_TargetState_y
{
public:
  explicit Init_TargetState_y(::swarm_interfaces::msg::TargetState & msg)
  : msg_(msg)
  {}
  Init_TargetState_vx y(::swarm_interfaces::msg::TargetState::_y_type arg)
  {
    msg_.y = std::move(arg);
    return Init_TargetState_vx(msg_);
  }

private:
  ::swarm_interfaces::msg::TargetState msg_;
};

class Init_TargetState_x
{
public:
  explicit Init_TargetState_x(::swarm_interfaces::msg::TargetState & msg)
  : msg_(msg)
  {}
  Init_TargetState_y x(::swarm_interfaces::msg::TargetState::_x_type arg)
  {
    msg_.x = std::move(arg);
    return Init_TargetState_y(msg_);
  }

private:
  ::swarm_interfaces::msg::TargetState msg_;
};

class Init_TargetState_target_id
{
public:
  Init_TargetState_target_id()
  : msg_(::rosidl_runtime_cpp::MessageInitialization::SKIP)
  {}
  Init_TargetState_x target_id(::swarm_interfaces::msg::TargetState::_target_id_type arg)
  {
    msg_.target_id = std::move(arg);
    return Init_TargetState_x(msg_);
  }

private:
  ::swarm_interfaces::msg::TargetState msg_;
};

}  // namespace builder

}  // namespace msg

template<typename MessageType>
auto build();

template<>
inline
auto build<::swarm_interfaces::msg::TargetState>()
{
  return swarm_interfaces::msg::builder::Init_TargetState_target_id();
}

}  // namespace swarm_interfaces

#endif  // SWARM_INTERFACES__MSG__DETAIL__TARGET_STATE__BUILDER_HPP_
