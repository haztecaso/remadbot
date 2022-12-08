#!/bin/env python3

import setuptools

with open("readme.md", "r") as readme_file:
    long_description = readme_file.read()

setuptools.setup(
    name="remadbot",
    version="0.1.0",
    author="haztecaso",
    long_description=long_description,
    long_description_content_type="text/markdown",
    packages=setuptools.find_packages(),
    scripts=["remadbot"],
    classifiers=[
        "Programming Language :: Python :: 3",
        "License :: OSI Approved :: GNU General Public License v3 (GPLv3)",
    ],
    python_requires=">=3.6",
)
