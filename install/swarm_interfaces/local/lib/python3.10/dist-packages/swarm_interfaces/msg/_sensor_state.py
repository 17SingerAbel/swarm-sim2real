# generated from rosidl_generator_py/resource/_idl.py.em
# with input from swarm_interfaces:msg/SensorState.idl
# generated code does not contain a copyright notice


# Import statements for member types

import builtins  # noqa: E402, I100

import math  # noqa: E402, I100

import rosidl_parser.definition  # noqa: E402, I100


class Metaclass_SensorState(type):
    """Metaclass of message 'SensorState'."""

    _CREATE_ROS_MESSAGE = None
    _CONVERT_FROM_PY = None
    _CONVERT_TO_PY = None
    _DESTROY_ROS_MESSAGE = None
    _TYPE_SUPPORT = None

    __constants = {
    }

    @classmethod
    def __import_type_support__(cls):
        try:
            from rosidl_generator_py import import_type_support
            module = import_type_support('swarm_interfaces')
        except ImportError:
            import logging
            import traceback
            logger = logging.getLogger(
                'swarm_interfaces.msg.SensorState')
            logger.debug(
                'Failed to import needed modules for type support:\n' +
                traceback.format_exc())
        else:
            cls._CREATE_ROS_MESSAGE = module.create_ros_message_msg__msg__sensor_state
            cls._CONVERT_FROM_PY = module.convert_from_py_msg__msg__sensor_state
            cls._CONVERT_TO_PY = module.convert_to_py_msg__msg__sensor_state
            cls._TYPE_SUPPORT = module.type_support_msg__msg__sensor_state
            cls._DESTROY_ROS_MESSAGE = module.destroy_ros_message_msg__msg__sensor_state

            from builtin_interfaces.msg import Time
            if Time.__class__._TYPE_SUPPORT is None:
                Time.__class__.__import_type_support__()

    @classmethod
    def __prepare__(cls, name, bases, **kwargs):
        # list constant names here so that they appear in the help text of
        # the message class under "Data and other attributes defined here:"
        # as well as populate each message instance
        return {
        }


class SensorState(metaclass=Metaclass_SensorState):
    """Message class 'SensorState'."""

    __slots__ = [
        '_sensor_id',
        '_fsm_state',
        '_role',
        '_assigned_target_id',
        '_pos_x',
        '_pos_y',
        '_stamp',
    ]

    _fields_and_field_types = {
        'sensor_id': 'int32',
        'fsm_state': 'string',
        'role': 'string',
        'assigned_target_id': 'int32',
        'pos_x': 'double',
        'pos_y': 'double',
        'stamp': 'builtin_interfaces/Time',
    }

    SLOT_TYPES = (
        rosidl_parser.definition.BasicType('int32'),  # noqa: E501
        rosidl_parser.definition.UnboundedString(),  # noqa: E501
        rosidl_parser.definition.UnboundedString(),  # noqa: E501
        rosidl_parser.definition.BasicType('int32'),  # noqa: E501
        rosidl_parser.definition.BasicType('double'),  # noqa: E501
        rosidl_parser.definition.BasicType('double'),  # noqa: E501
        rosidl_parser.definition.NamespacedType(['builtin_interfaces', 'msg'], 'Time'),  # noqa: E501
    )

    def __init__(self, **kwargs):
        assert all('_' + key in self.__slots__ for key in kwargs.keys()), \
            'Invalid arguments passed to constructor: %s' % \
            ', '.join(sorted(k for k in kwargs.keys() if '_' + k not in self.__slots__))
        self.sensor_id = kwargs.get('sensor_id', int())
        self.fsm_state = kwargs.get('fsm_state', str())
        self.role = kwargs.get('role', str())
        self.assigned_target_id = kwargs.get('assigned_target_id', int())
        self.pos_x = kwargs.get('pos_x', float())
        self.pos_y = kwargs.get('pos_y', float())
        from builtin_interfaces.msg import Time
        self.stamp = kwargs.get('stamp', Time())

    def __repr__(self):
        typename = self.__class__.__module__.split('.')
        typename.pop()
        typename.append(self.__class__.__name__)
        args = []
        for s, t in zip(self.__slots__, self.SLOT_TYPES):
            field = getattr(self, s)
            fieldstr = repr(field)
            # We use Python array type for fields that can be directly stored
            # in them, and "normal" sequences for everything else.  If it is
            # a type that we store in an array, strip off the 'array' portion.
            if (
                isinstance(t, rosidl_parser.definition.AbstractSequence) and
                isinstance(t.value_type, rosidl_parser.definition.BasicType) and
                t.value_type.typename in ['float', 'double', 'int8', 'uint8', 'int16', 'uint16', 'int32', 'uint32', 'int64', 'uint64']
            ):
                if len(field) == 0:
                    fieldstr = '[]'
                else:
                    assert fieldstr.startswith('array(')
                    prefix = "array('X', "
                    suffix = ')'
                    fieldstr = fieldstr[len(prefix):-len(suffix)]
            args.append(s[1:] + '=' + fieldstr)
        return '%s(%s)' % ('.'.join(typename), ', '.join(args))

    def __eq__(self, other):
        if not isinstance(other, self.__class__):
            return False
        if self.sensor_id != other.sensor_id:
            return False
        if self.fsm_state != other.fsm_state:
            return False
        if self.role != other.role:
            return False
        if self.assigned_target_id != other.assigned_target_id:
            return False
        if self.pos_x != other.pos_x:
            return False
        if self.pos_y != other.pos_y:
            return False
        if self.stamp != other.stamp:
            return False
        return True

    @classmethod
    def get_fields_and_field_types(cls):
        from copy import copy
        return copy(cls._fields_and_field_types)

    @builtins.property
    def sensor_id(self):
        """Message field 'sensor_id'."""
        return self._sensor_id

    @sensor_id.setter
    def sensor_id(self, value):
        if __debug__:
            assert \
                isinstance(value, int), \
                "The 'sensor_id' field must be of type 'int'"
            assert value >= -2147483648 and value < 2147483648, \
                "The 'sensor_id' field must be an integer in [-2147483648, 2147483647]"
        self._sensor_id = value

    @builtins.property
    def fsm_state(self):
        """Message field 'fsm_state'."""
        return self._fsm_state

    @fsm_state.setter
    def fsm_state(self, value):
        if __debug__:
            assert \
                isinstance(value, str), \
                "The 'fsm_state' field must be of type 'str'"
        self._fsm_state = value

    @builtins.property
    def role(self):
        """Message field 'role'."""
        return self._role

    @role.setter
    def role(self, value):
        if __debug__:
            assert \
                isinstance(value, str), \
                "The 'role' field must be of type 'str'"
        self._role = value

    @builtins.property
    def assigned_target_id(self):
        """Message field 'assigned_target_id'."""
        return self._assigned_target_id

    @assigned_target_id.setter
    def assigned_target_id(self, value):
        if __debug__:
            assert \
                isinstance(value, int), \
                "The 'assigned_target_id' field must be of type 'int'"
            assert value >= -2147483648 and value < 2147483648, \
                "The 'assigned_target_id' field must be an integer in [-2147483648, 2147483647]"
        self._assigned_target_id = value

    @builtins.property
    def pos_x(self):
        """Message field 'pos_x'."""
        return self._pos_x

    @pos_x.setter
    def pos_x(self, value):
        if __debug__:
            assert \
                isinstance(value, float), \
                "The 'pos_x' field must be of type 'float'"
            assert not (value < -1.7976931348623157e+308 or value > 1.7976931348623157e+308) or math.isinf(value), \
                "The 'pos_x' field must be a double in [-1.7976931348623157e+308, 1.7976931348623157e+308]"
        self._pos_x = value

    @builtins.property
    def pos_y(self):
        """Message field 'pos_y'."""
        return self._pos_y

    @pos_y.setter
    def pos_y(self, value):
        if __debug__:
            assert \
                isinstance(value, float), \
                "The 'pos_y' field must be of type 'float'"
            assert not (value < -1.7976931348623157e+308 or value > 1.7976931348623157e+308) or math.isinf(value), \
                "The 'pos_y' field must be a double in [-1.7976931348623157e+308, 1.7976931348623157e+308]"
        self._pos_y = value

    @builtins.property
    def stamp(self):
        """Message field 'stamp'."""
        return self._stamp

    @stamp.setter
    def stamp(self, value):
        if __debug__:
            from builtin_interfaces.msg import Time
            assert \
                isinstance(value, Time), \
                "The 'stamp' field must be a sub message of type 'Time'"
        self._stamp = value
