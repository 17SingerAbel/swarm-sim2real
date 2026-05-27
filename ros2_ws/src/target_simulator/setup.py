from setuptools import find_packages, setup

package_name = 'target_simulator'

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
    description='Publishes simulated target ground-truth positions',
    license='Apache-2.0',
    entry_points={
        'console_scripts': [
            'target_simulator_node = target_simulator.target_simulator_node:main',
        ],
    },
)
