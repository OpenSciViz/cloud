import setuptools

setuptools.setup(
    install_requires=open('requires.txt').readlines(),
    version='2.0.1',
    name='novaconsole',
    packages=['novaconsole'],
    entry_points={
        'console_scripts': [
            'novaconsole = novaconsole.main:main',
        ],
    }
)
