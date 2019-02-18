#!/bin/bash

echo "**************************************************"
echo "** Check compatibility of python code with PEP8 **"
echo "**************************************************"

find . -name "*.py" -exec  pycodestyle --show-pep8 --statistics --verbose {} \;
