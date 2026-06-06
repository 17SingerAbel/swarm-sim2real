cmake_minimum_required(VERSION 3.8)
project(swarm_interfaces)

find_package(ament_cmake REQUIRED)
find_package(rosidl_default_generators REQUIRED)
find_package(builtin_interfaces REQUIRED)

rosidl_generate_interfaces(${PROJECT_NAME}
  "msg/TargetState.msg"
  "msg/SensorState.msg"
  "msg/TargetEstimate.msg"
  "msg/HandoverRequest.msg"
  "msg/BidMsg.msg"
  "msg/CommitmentMsg.msg"
  DEPENDENCIES builtin_interfaces
)

ament_export_dependencies(rosidl_default_runtime)
ament_package()
