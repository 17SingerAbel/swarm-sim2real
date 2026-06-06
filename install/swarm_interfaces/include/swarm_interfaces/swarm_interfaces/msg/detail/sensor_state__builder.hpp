// generated from rosidl_generator_cpp/resource/idl__builder.hpp.em
// with input from swarm_interfaces:msg/SensorState.idl
// generated code does not contain a copyright notice

#ifndef SWARM_INTERFACES__MSG__DETAIL__SENSOR_STATE__BUILDER_HPP_
#define SWARM_INTERFACES__MSG__DETAIL__SENSOR_STATE__BUILDER_HPP_

#include <algorithm>
#include <utility>

#include "swarm_interfaces/msg/detail/sensor_state__struct.hpp"
#include "rosidl_runtime_cpp/message_initialization.hpp"


namespace swarm_interfaces
{

namespace msg
{

namespace builder
{

class Init_SensorState_stamp
{
public:
  explicit Init_SensorState_stamp(::swarm_interfaces::msg::SensorState & msg)
  : msg_(msg)
  {}
  ::swarm_interfaces::msg::SensorState stamp(::swarm_interfaces::msg::SensorState::_stamp_type arg)
  {
    msg_.stamp = std::move(arg);
    return std::move(msg_);
  }

private:
  ::swarm_interfaces::msg::SensorState msg_;
};

class Init_SensorState_pos_y
{
public:
  explicit Init_SensorState_pos_y(::swarm_interfaces::msg::SensorState & msg)
  : msg_(msg)
  {}
  Init_SensorState_stamp pos_y(::swarm_interfaces::msg::SensorState::_pos_y_type arg)
  {
    msg_.pos_y = std::move(arg);
    return Init_SensorState_stamp(msg_);
  }

private:
  ::swarm_interfaces::msg::SensorState msg_;
};

class Init_SensorState_pos_x
{
public:
  explicit Init_SensorState_pos_x(::swarm_interfaces::msg::SensorState & msg)
  : msg_(msg)
  {}
  Init_SensorState_pos_y pos_x(::swarm_interfaces::msg::SensorState::_pos_x_type arg)
  {
    msg_.pos_x = std::move(arg);
    return Init_SensorState_pos_y(msg_);
  }

private:
  ::swarm_interfaces::msg::SensorState msg_;
};

class Init_SensorState_assigned_target_id
{
public:
  explicit Init_SensorState_assigned_target_id(::swarm_interfaces::msg::SensorState & msg)
  : msg_(msg)
  {}
  Init_SensorState_pos_x assigned_target_id(::swarm_interfaces::msg::SensorState::_assigned_target_id_type arg)
  {
    msg_.assigned_target_id = std::move(arg);
    return Init_SensorState_pos_x(msg_);
  }

private:
  ::swarm_interfaces::msg::SensorState msg_;
};

class Init_SensorState_role
{
public:
  explicit Init_SensorState_role(::swarm_interfaces::msg::SensorState & msg)
  : msg_(msg)
  {}
  Init_SensorState_assigned_target_id role(::swarm_interfaces::msg::SensorState::_role_type arg)
  {
    msg_.role = std::move(arg);
    return Init_SensorState_assigned_target_id(msg_);
  }

private:
  ::swarm_interfaces::msg::SensorState msg_;
};

class Init_SensorState_fsm_state
{
public:
  explicit Init_SensorState_fsm_state(::swarm_interfaces::msg::SensorState & msg)
  : msg_(msg)
  {}
  Init_SensorState_role fsm_state(::swarm_interfaces::msg::SensorState::_fsm_state_type arg)
  {
    msg_.fsm_state = std::move(arg);
    return Init_SensorState_role(msg_);
  }

private:
  ::swarm_interfaces::msg::SensorState msg_;
};

class Init_SensorState_sensor_id
{
public:
  Init_SensorState_sensor_id()
  : msg_(::rosidl_runtime_cpp::MessageInitialization::SKIP)
  {}
  Init_SensorState_fsm_state sensor_id(::swarm_interfaces::msg::SensorState::_sensor_id_type arg)
  {
    msg_.sensor_id = std::move(arg);
    return Init_SensorState_fsm_state(msg_);
  }

private:
  ::swarm_interfaces::msg::SensorState msg_;
};

}  // namespace builder

}  // namespace msg

template<typename MessageType>
auto build();

template<>
inline
auto build<::swarm_interfaces::msg::SensorState>()
{
  return swarm_interfaces::msg::builder::Init_SensorState_sensor_id();
}

}  // namespace swarm_interfaces

#endif  // SWARM_INTERFACES__MSG__DETAIL__SENSOR_STATE__BUILDER_HPP_
