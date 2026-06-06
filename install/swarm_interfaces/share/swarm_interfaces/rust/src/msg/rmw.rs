#[cfg(feature = "serde")]
use serde::{Deserialize, Serialize};


#[link(name = "swarm_interfaces__rosidl_typesupport_c")]
extern "C" {
    fn rosidl_typesupport_c__get_message_type_support_handle__swarm_interfaces__msg__TargetState() -> *const std::ffi::c_void;
}

#[link(name = "swarm_interfaces__rosidl_generator_c")]
extern "C" {
    fn swarm_interfaces__msg__TargetState__init(msg: *mut TargetState) -> bool;
    fn swarm_interfaces__msg__TargetState__Sequence__init(seq: *mut rosidl_runtime_rs::Sequence<TargetState>, size: usize) -> bool;
    fn swarm_interfaces__msg__TargetState__Sequence__fini(seq: *mut rosidl_runtime_rs::Sequence<TargetState>);
    fn swarm_interfaces__msg__TargetState__Sequence__copy(in_seq: &rosidl_runtime_rs::Sequence<TargetState>, out_seq: *mut rosidl_runtime_rs::Sequence<TargetState>) -> bool;
}

// Corresponds to swarm_interfaces__msg__TargetState
#[cfg_attr(feature = "serde", derive(Deserialize, Serialize))]


// This struct is not documented.
#[allow(missing_docs)]

#[repr(C)]
#[derive(Clone, Debug, PartialEq, PartialOrd)]
pub struct TargetState {

    // This member is not documented.
    #[allow(missing_docs)]
    pub target_id: i32,


    // This member is not documented.
    #[allow(missing_docs)]
    pub x: f64,


    // This member is not documented.
    #[allow(missing_docs)]
    pub y: f64,


    // This member is not documented.
    #[allow(missing_docs)]
    pub vx: f64,


    // This member is not documented.
    #[allow(missing_docs)]
    pub vy: f64,


    // This member is not documented.
    #[allow(missing_docs)]
    pub stamp: builtin_interfaces::msg::rmw::Time,

}



impl Default for TargetState {
  fn default() -> Self {
    unsafe {
      let mut msg = std::mem::zeroed();
      if !swarm_interfaces__msg__TargetState__init(&mut msg as *mut _) {
        panic!("Call to swarm_interfaces__msg__TargetState__init() failed");
      }
      msg
    }
  }
}

impl rosidl_runtime_rs::SequenceAlloc for TargetState {
  fn sequence_init(seq: &mut rosidl_runtime_rs::Sequence<Self>, size: usize) -> bool {
    // SAFETY: This is safe since the pointer is guaranteed to be valid/initialized.
    unsafe { swarm_interfaces__msg__TargetState__Sequence__init(seq as *mut _, size) }
  }
  fn sequence_fini(seq: &mut rosidl_runtime_rs::Sequence<Self>) {
    // SAFETY: This is safe since the pointer is guaranteed to be valid/initialized.
    unsafe { swarm_interfaces__msg__TargetState__Sequence__fini(seq as *mut _) }
  }
  fn sequence_copy(in_seq: &rosidl_runtime_rs::Sequence<Self>, out_seq: &mut rosidl_runtime_rs::Sequence<Self>) -> bool {
    // SAFETY: This is safe since the pointer is guaranteed to be valid/initialized.
    unsafe { swarm_interfaces__msg__TargetState__Sequence__copy(in_seq, out_seq as *mut _) }
  }
}

impl rosidl_runtime_rs::Message for TargetState {
  type RmwMsg = Self;
  fn into_rmw_message(msg_cow: std::borrow::Cow<'_, Self>) -> std::borrow::Cow<'_, Self::RmwMsg> { msg_cow }
  fn from_rmw_message(msg: Self::RmwMsg) -> Self { msg }
}

impl rosidl_runtime_rs::RmwMessage for TargetState where Self: Sized {
  const TYPE_NAME: &'static str = "swarm_interfaces/msg/TargetState";
  fn get_type_support() -> *const std::ffi::c_void {
    // SAFETY: No preconditions for this function.
    unsafe { rosidl_typesupport_c__get_message_type_support_handle__swarm_interfaces__msg__TargetState() }
  }
}


#[link(name = "swarm_interfaces__rosidl_typesupport_c")]
extern "C" {
    fn rosidl_typesupport_c__get_message_type_support_handle__swarm_interfaces__msg__SensorState() -> *const std::ffi::c_void;
}

#[link(name = "swarm_interfaces__rosidl_generator_c")]
extern "C" {
    fn swarm_interfaces__msg__SensorState__init(msg: *mut SensorState) -> bool;
    fn swarm_interfaces__msg__SensorState__Sequence__init(seq: *mut rosidl_runtime_rs::Sequence<SensorState>, size: usize) -> bool;
    fn swarm_interfaces__msg__SensorState__Sequence__fini(seq: *mut rosidl_runtime_rs::Sequence<SensorState>);
    fn swarm_interfaces__msg__SensorState__Sequence__copy(in_seq: &rosidl_runtime_rs::Sequence<SensorState>, out_seq: *mut rosidl_runtime_rs::Sequence<SensorState>) -> bool;
}

// Corresponds to swarm_interfaces__msg__SensorState
#[cfg_attr(feature = "serde", derive(Deserialize, Serialize))]


// This struct is not documented.
#[allow(missing_docs)]

#[repr(C)]
#[derive(Clone, Debug, PartialEq, PartialOrd)]
pub struct SensorState {

    // This member is not documented.
    #[allow(missing_docs)]
    pub sensor_id: i32,


    // This member is not documented.
    #[allow(missing_docs)]
    pub fsm_state: rosidl_runtime_rs::String,


    // This member is not documented.
    #[allow(missing_docs)]
    pub role: rosidl_runtime_rs::String,


    // This member is not documented.
    #[allow(missing_docs)]
    pub assigned_target_id: i32,


    // This member is not documented.
    #[allow(missing_docs)]
    pub pos_x: f64,


    // This member is not documented.
    #[allow(missing_docs)]
    pub pos_y: f64,


    // This member is not documented.
    #[allow(missing_docs)]
    pub stamp: builtin_interfaces::msg::rmw::Time,

}



impl Default for SensorState {
  fn default() -> Self {
    unsafe {
      let mut msg = std::mem::zeroed();
      if !swarm_interfaces__msg__SensorState__init(&mut msg as *mut _) {
        panic!("Call to swarm_interfaces__msg__SensorState__init() failed");
      }
      msg
    }
  }
}

impl rosidl_runtime_rs::SequenceAlloc for SensorState {
  fn sequence_init(seq: &mut rosidl_runtime_rs::Sequence<Self>, size: usize) -> bool {
    // SAFETY: This is safe since the pointer is guaranteed to be valid/initialized.
    unsafe { swarm_interfaces__msg__SensorState__Sequence__init(seq as *mut _, size) }
  }
  fn sequence_fini(seq: &mut rosidl_runtime_rs::Sequence<Self>) {
    // SAFETY: This is safe since the pointer is guaranteed to be valid/initialized.
    unsafe { swarm_interfaces__msg__SensorState__Sequence__fini(seq as *mut _) }
  }
  fn sequence_copy(in_seq: &rosidl_runtime_rs::Sequence<Self>, out_seq: &mut rosidl_runtime_rs::Sequence<Self>) -> bool {
    // SAFETY: This is safe since the pointer is guaranteed to be valid/initialized.
    unsafe { swarm_interfaces__msg__SensorState__Sequence__copy(in_seq, out_seq as *mut _) }
  }
}

impl rosidl_runtime_rs::Message for SensorState {
  type RmwMsg = Self;
  fn into_rmw_message(msg_cow: std::borrow::Cow<'_, Self>) -> std::borrow::Cow<'_, Self::RmwMsg> { msg_cow }
  fn from_rmw_message(msg: Self::RmwMsg) -> Self { msg }
}

impl rosidl_runtime_rs::RmwMessage for SensorState where Self: Sized {
  const TYPE_NAME: &'static str = "swarm_interfaces/msg/SensorState";
  fn get_type_support() -> *const std::ffi::c_void {
    // SAFETY: No preconditions for this function.
    unsafe { rosidl_typesupport_c__get_message_type_support_handle__swarm_interfaces__msg__SensorState() }
  }
}


#[link(name = "swarm_interfaces__rosidl_typesupport_c")]
extern "C" {
    fn rosidl_typesupport_c__get_message_type_support_handle__swarm_interfaces__msg__TargetEstimate() -> *const std::ffi::c_void;
}

#[link(name = "swarm_interfaces__rosidl_generator_c")]
extern "C" {
    fn swarm_interfaces__msg__TargetEstimate__init(msg: *mut TargetEstimate) -> bool;
    fn swarm_interfaces__msg__TargetEstimate__Sequence__init(seq: *mut rosidl_runtime_rs::Sequence<TargetEstimate>, size: usize) -> bool;
    fn swarm_interfaces__msg__TargetEstimate__Sequence__fini(seq: *mut rosidl_runtime_rs::Sequence<TargetEstimate>);
    fn swarm_interfaces__msg__TargetEstimate__Sequence__copy(in_seq: &rosidl_runtime_rs::Sequence<TargetEstimate>, out_seq: *mut rosidl_runtime_rs::Sequence<TargetEstimate>) -> bool;
}

// Corresponds to swarm_interfaces__msg__TargetEstimate
#[cfg_attr(feature = "serde", derive(Deserialize, Serialize))]


// This struct is not documented.
#[allow(missing_docs)]

#[repr(C)]
#[derive(Clone, Debug, PartialEq, PartialOrd)]
pub struct TargetEstimate {

    // This member is not documented.
    #[allow(missing_docs)]
    pub sensor_id: i32,


    // This member is not documented.
    #[allow(missing_docs)]
    pub target_id: i32,


    // This member is not documented.
    #[allow(missing_docs)]
    pub x: f64,


    // This member is not documented.
    #[allow(missing_docs)]
    pub y: f64,


    // This member is not documented.
    #[allow(missing_docs)]
    pub vx: f64,


    // This member is not documented.
    #[allow(missing_docs)]
    pub vy: f64,

    /// [Pxx, Pyy, Pvx, Pvy]
    pub covariance: [f64; 4],


    // This member is not documented.
    #[allow(missing_docs)]
    pub ekf_converged: bool,


    // This member is not documented.
    #[allow(missing_docs)]
    pub stamp: builtin_interfaces::msg::rmw::Time,

}



impl Default for TargetEstimate {
  fn default() -> Self {
    unsafe {
      let mut msg = std::mem::zeroed();
      if !swarm_interfaces__msg__TargetEstimate__init(&mut msg as *mut _) {
        panic!("Call to swarm_interfaces__msg__TargetEstimate__init() failed");
      }
      msg
    }
  }
}

impl rosidl_runtime_rs::SequenceAlloc for TargetEstimate {
  fn sequence_init(seq: &mut rosidl_runtime_rs::Sequence<Self>, size: usize) -> bool {
    // SAFETY: This is safe since the pointer is guaranteed to be valid/initialized.
    unsafe { swarm_interfaces__msg__TargetEstimate__Sequence__init(seq as *mut _, size) }
  }
  fn sequence_fini(seq: &mut rosidl_runtime_rs::Sequence<Self>) {
    // SAFETY: This is safe since the pointer is guaranteed to be valid/initialized.
    unsafe { swarm_interfaces__msg__TargetEstimate__Sequence__fini(seq as *mut _) }
  }
  fn sequence_copy(in_seq: &rosidl_runtime_rs::Sequence<Self>, out_seq: &mut rosidl_runtime_rs::Sequence<Self>) -> bool {
    // SAFETY: This is safe since the pointer is guaranteed to be valid/initialized.
    unsafe { swarm_interfaces__msg__TargetEstimate__Sequence__copy(in_seq, out_seq as *mut _) }
  }
}

impl rosidl_runtime_rs::Message for TargetEstimate {
  type RmwMsg = Self;
  fn into_rmw_message(msg_cow: std::borrow::Cow<'_, Self>) -> std::borrow::Cow<'_, Self::RmwMsg> { msg_cow }
  fn from_rmw_message(msg: Self::RmwMsg) -> Self { msg }
}

impl rosidl_runtime_rs::RmwMessage for TargetEstimate where Self: Sized {
  const TYPE_NAME: &'static str = "swarm_interfaces/msg/TargetEstimate";
  fn get_type_support() -> *const std::ffi::c_void {
    // SAFETY: No preconditions for this function.
    unsafe { rosidl_typesupport_c__get_message_type_support_handle__swarm_interfaces__msg__TargetEstimate() }
  }
}


