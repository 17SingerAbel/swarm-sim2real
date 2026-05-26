from setuptools import find_packages, setup

package_name = 'sensor_agent'

setup(
    name=package_name,
    version='0.0.1',
    packages=find_packages(exclude=['test']),
    data_files=[
        ('share/ament_index/resource_index/packages',
            ['resource/' + package_name]),
        ('share/' + package_name, ['package.xml']),
    ],
    install_requires=['setuptools'],
    zip_safe=True,
    maintainer='Abel Sang',
    maintainer_email='yeqisang@gmail.com',
    description='Sensor FSM agent for WSN tracking',
    license='Apache-2.0',
    entry_points={
        'console_scripts': [
            'sensor_agent_node = sensor_agent.sensor_agent_node:main',
        ],
    },
)
