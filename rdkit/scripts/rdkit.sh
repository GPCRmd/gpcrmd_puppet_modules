#! /usr/bin/bash
cd rdkit*
export RDBASE=$(pwd)
OLD_PYTHONPATH = $PYTHONPATH
OLD_LD_LIBRARY_PATH = $LD_LIBRARY_PATH
export PYTHONPATH=$RDBASE:$PYTHONPATH
export LD_LIBRARY_PATH=$RDBASE/lib:$LD_LIBRARY_PATH
mkdir build
cd build
cmake -D RDK_BUILD_SWIG_WRAPPERS=OFF \
-D PYTHON_LIBRARY=/env/lib/python3.4/config-3.4m-x86_64-linux-gnu/libpython3.4m.so \
-D PYTHON_INCLUDE_DIR=/env/include/python3.4m/ \
-D PYTHON_EXECUTABLE=/env/bin/python3 \
-D RDK_BUILD_AVALON_SUPPORT=ON \
-D RDK_BUILD_INCHI_SUPPORT=ON \
-D RDK_BUILD_PYTHON_WRAPPERS=ON \
-D BOOST_ROOT=/usr/ \
-D PYTHON_INSTDIR=/env/lib/python3.4/site-packages/ \
-D RDK_INSTALL_INTREE=OFF ..
make -j2
cd $RDBASE/build
make -j2 install
export PYTHONPATH=$OLD_PYTHONPATH
export LD_LIBRARY_PATH=$OLD_LD_LIBRARY_PATH
ldconfig