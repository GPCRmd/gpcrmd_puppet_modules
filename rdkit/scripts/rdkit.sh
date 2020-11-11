#! /usr/bin/bash
if [ -z "$1" ]; then
  BOOST_ROOT=/usr
else
  BOOST_ROOT=/usr/local
fi
OLD_PWD=$(pwd -L)
tar -xvzf rdkit.tar.gz
cd rdkit*
export RDBASE=$(pwd)
OLD_PYTHONPATH=$PYTHONPATH
OLD_LD_LIBRARY_PATH=$LD_LIBRARY_PATH
export PYTHONPATH=$RDBASE:$PYTHONPATH
export LD_LIBRARY_PATH=$RDBASE/lib:$LD_LIBRARY_PATH
mkdir build
cd build
PY_LIBRARY_PATHS=("/usr/lib/python3.4/config-3.4m-x86_64-linux-gnu/libpython3.4m.so"
                  "/usr/lib64/libpython3.4m.so")
for path in ${PY_LIBRARY_PATHS[@]}; do
  if [ -f "$path" ]; then
    PY_LIBRARY_PATH="$path"
  fi
done



cmake -D RDK_BUILD_SWIG_WRAPPERS=OFF \
-D CMAKE_C_FLAGS="-I /env/lib64/python3.4/site-packages/numpy/core/include" \
-D CMAKE_CXX_FLAGS="-I /env/lib64/python3.4/site-packages/numpy/core/include" \
-D PYTHON_LIBRARY="$PY_LIBRARY_PATH" \
-D PYTHON_INCLUDE_DIR=/usr/include/python3.4m/ \
-D PYTHON_EXECUTABLE=/env/bin/python3 \
-D RDK_BUILD_AVALON_SUPPORT=ON \
-D RDK_BUILD_INCHI_SUPPORT=ON \
-D RDK_BUILD_PYTHON_WRAPPERS=ON \
-D BOOST_ROOT=$BOOST_ROOT \
-D PYTHON_INSTDIR=/env/lib/python3.4/site-packages/ \
-D RDK_INSTALL_INTREE=OFF .. || ( export PYTHONPATH=$OLD_PYTHONPATH
                                  export LD_LIBRARY_PATH=$OLD_LD_LIBRARY_PATH
                                  cd $OLD_PWD
                                  exit 1
                                )
make -j2 ||                     ( export PYTHONPATH=$OLD_PYTHONPATH
                                  export LD_LIBRARY_PATH=$OLD_LD_LIBRARY_PATH
                                  cd $OLD_PWD
                                  exit 1
                                )

cd $RDBASE/build
make -j2 install ||             ( export PYTHONPATH=$OLD_PYTHONPATH
                                  export LD_LIBRARY_PATH=$OLD_LD_LIBRARY_PATH
                                  cd $OLD_PWD
                                  exit 1
                                )

export PYTHONPATH=$OLD_PYTHONPATH
export LD_LIBRARY_PATH=$OLD_LD_LIBRARY_PATH
cd $OLD_PWD
ldconfig
