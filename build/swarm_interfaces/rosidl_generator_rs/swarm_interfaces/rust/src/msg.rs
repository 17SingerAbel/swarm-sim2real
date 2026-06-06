#[cfg(feature = "serde")]
use serde::{Deserialize, Serialize};



// Corresponds to swarm_interfaces__msg__TargetState

// This struct is not documented.
#[allow(missing_docs)]

#[cfg_attr(feature = "serde", derive(Deserialize, Serialize))]
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
    pub stamp: builtin_interfaces::msg::Time,

}



impl Default for TargetState {
  fn default() -> Self {
    <Self as rosidl_runtime_rs::Message>::from_rmw_message(super::msg::rmw::TargetState::default())
  }
}

impl rosidl_runtime_rs::Message for TargetState {
  type RmwMsg = super::msg::rmw::TargetState;

  fn into_rmw_message(msg_cow: std::borrow::Cow<'_, Self>) -> std::borrow::Cow<'_, Self::RmwMsg> {
    match msg_cow {
      std::borrow::Cow::Owned(msg) => std::borrow::Cow::Owned(Self::RmwMsg {
        target_id: msg.target_id,
        x: msg.x,
        y: msg.y,
        vx: msg.vx,
        vy: msg.vy,
        stamp: builtin_interfaces::msg::Time::into_rmw_message(std::borrow::Cow::Owned(msg.stamp)).into_owned(),
      }),
      std::borrow::Cow::Borrowed(msg) => std::borrow::Cow::Owned(Self::RmwMsg {
      target_id: msg.target_id,
      x: msg.x,
      y: msg.y,
      vx: msg.vx,
      vy: msg.vy,
        stamp: builtin_interfaces::msg::Time::into_rmw_message(std::borrow::Cow::Borrowed(&msg.stamp)).into_owned(),
      })
    }
  }

  fn from_rmw_message(msg: Self::RmwMsg) -> Self {
    Self {
      target_id: msg.target_id,
      x: msg.x,
      y: msg.y,
      vx: msg.vx,
      vy: msg.vy,
      stamp: builtin_interfaces::msg::Time::from_rmw_message(msg.stamp),
    }
  }
}


// Corresponds to swarm_interfaces__msg__SensorState

// This struct is not documented.
#[allow(missing_docs)]

#[cfg_attr(feature = "serde", derive(Deserialize, Serialize))]
#[derive(Clone, Debug, PartialEq, PartialOrd)]
pub struct SensorState {

    // This member is not documented.
    #[allow(missing_docs)]
    pub sensor_id: i32,


    // This member is not documented.
    #[allow(missing_docs)]
    pub fsm_state: std::string::String,


    // This member is not documented.
    #[allow(missing_docs)]
    pub role: std::string::String,


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
    pub stamp: builtin_interfaces::msg::Time,

}



impl Default for SensorState {
  fn default() -> Self {
    <Self as rosidl_runtime_rs::Message>::from_rmw_message(super::msg::rmw::SensorState::default())
  }
}

impl rosidl_runtime_rs::Message for SensorState {
  type RmwMsg = super::msg::rmw::SensorState;

  fn into_rmw_message(msg_cow: std::borrow::Cow<'_, Self>) -> std::borrow::Cow<'_, Self::RmwMsg> {
    match msg_cow {
      std::borrow::Cow::Owned(msg) => std::borrow::Cow::Owned(Self::RmwMsg {
        sensor_id: msg.sensor_id,
        fsm_state: msg.fsm_state.as_str().into(),
        role: msg.role.as_str().into(),
        assigned_target_id: msg.assigned_target_id,
        pos_x: msg.pos_x,
        pos_y: msg.pos_y,
        stamp: builtin_interfaces::msg::Time::into_rmw_message(std::borrow::Cow::Owned(msg.stamp)).into_owned(),
      }),
      std::borrow::Cow::Borrowed(msg) => std::borrow::Cow::Owned(Self::RmwMsg {
      sensor_id: msg.sensor_id,
        fsm_state: msg.fsm_state.as_str().into(),
        role: msg.role.as_str().into(),
      assigned_target_id: msg.assigned_target_id,
      pos_x: msg.pos_x,
      pos_y: msg.pos_y,
        stamp: builtin_interfaces::msg::Time::into_rmw_message(std::borrow::Cow::Borrowed(&msg.stamp)).into_owned(),
      })
    }
  }

  fn from_rmw_message(msg: Self::RmwMsg) -> Self {
    Self {
      sensor_id: msg.sensor_id,
      fsm_state: msg.fsm_state.to_string(),
      role: msg.role.to_string(),
      assigned_target_id: msg.assigned_target_id,
      pos_x: msg.pos_x,
      pos_y: msg.pos_y,
      stamp: builtin_interfaces::msg::Time::from_rmw_message(msg.stamp),
    }
  }
}


// Corresponds to swarm_interfaces__msg__TargetEstimate

// This struct is not documented.
#[allow(missing_docs)]

#[cfg_attr(feature = "serde", derive(Deserialize, Serialize))]
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
    pub stamp: builtin_interfaces::msg::Time,

}



impl Default for TargetEstimate {
  fn default() -> Self {
    <Self as rosidl_runtime_rs::Message>::from_rmw_message(super::msg::rmw::TargetEstimate::default())
  }
}

impl rosidl_runtime_rs::Message for TargetEstimate {
  type RmwMsg = super::msg::rmw::TargetEstimate;

  fn into_rmw_message(msg_cow: std::borrow::Cow<'_, Self>) -> std::borrow::Cow<'_, Self::RmwMsg> {
    match msg_cow {
      std::borrow::Cow::Owned(msg) => std::borrow::Cow::Owned(Self::RmwMsg {
        sensor_id: msg.sensor_id,
        target_id: msg.target_id,
        x: msg.x,
        y: msg.y,
        vx: msg.vx,
        vy: msg.vy,
        covariance: msg.covariance,
        ekf_converged: msg.ekf_converged,
        stamp: builtin_interfaces::msg::Time::into_rmw_message(std::borrow::Cow::Owned(msg.stamp)).into_owned(),
      }),
      std::borrow::Cow::Borrowed(msg) => std::borrow::Cow::Owned(Self::RmwMsg {
      sensor_id: msg.sensor_id,
      target_id: msg.target_id,
      x: msg.x,
      y: msg.y,
      vx: msg.vx,
      vy: msg.vy,
        covariance: msg.covariance,
      ekf_converged: msg.ekf_converged,
        stamp: builtin_interfaces::msg::Time::into_rmw_message(std::borrow::Cow::Borrowed(&msg.stamp)).into_owned(),
      })
    }
  }

  fn from_rmw_message(msg: Self::RmwMsg) -> Self {
    Self {
      sensor_id: msg.sensor_id,
      target_id: msg.target_id,
      x: msg.x,
      y: msg.y,
      vx: msg.vx,
      vy: msg.vy,
      covariance: msg.covariance,
      ekf_converged: msg.ekf_converged,
      stamp: builtin_interfaces::msg::Time::from_rmw_message(msg.stamp),
    }
  }
}


