from setuptools import find_packages, setup

package_name = 'swarm_bringup'

setup(
    name=package_name,
    version='0.0.1',
    packages=find_packages(exclude=['test']),
    data_files=[
        ('share/ament_index/resource_index/packages',
            ['resource/' + package_name]),
        ('share/' + package_name, ['package.xml']),
        ('share/' + package_name + '/launch', [
            'launch/sim_m1.launch.py',
            'launch/sim_m2.launch.py',
        ]),
        ('share/' + package_name + '/config', [
            'config/sim_m1_params.yaml',
            'config/sim_m2_params.yaml',
        ]),
    ],
    install_requires=['setuptools'],
    zip_safe=True,
    maintainer='Abel Sang',
    maintainer_email='yeqisang@gmail.com',
    description='Launch files and configs for swarm WSN tracking',
    license='Apache-2.0',
    entry_points={
        'console_scripts': [],
    },
)
