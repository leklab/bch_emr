#!/bin/bash
set -x -e
export PATH=$PATH:/usr/local/bin

HAIL_ARTIFACT_DIR="/opt/hail"
HAIL_PROFILE="/etc/profile.d/hail.sh"
JAR_HAIL="hail-all-spark.jar"

#No longer creates zip but use wheel instead
#ZIP_HAIL="hail-python.zip"
WHEEL_HAIL="hail-$HAIL_VERSION-py3-none-any.whl"

REPOSITORY_URL="https://github.com/hail-is/hail.git"

function upgrade_python3 {

   yum groupinstall -y "Development Tools"

   yum install -y libffi-devel bzip2-devel wget \
   openssl11 openssl11-devel \
   xz-devel \
   ncurses-devel

   wget https://www.python.org/ftp/python/3.10.2/Python-3.10.2.tgz
   tar xzf Python-3.10.2.tgz
   cd Python-3.10.2

   ./configure --enable-optimizations --prefix=/usr
   make -j $(nproc)
   make altinstall

   rm /usr/bin/python3
   ln -s /usr/bin/python3.10 /usr/bin/python3

}

function install_prereqs {
  mkdir -p "$HAIL_ARTIFACT_DIR"

  amazon-linux-extras enable corretto8

  yum install -y java-1.8.0-amazon-corretto-devel \
  lz4-devel \
  git

  amazon-linux-extras -y install R4

  # Upgrade latest latest pip
  #python3 -m ensurepip
  python3 -m pip install --upgrade pip

  #install here
  #python3 -m pip install --ignore-installed -U requests

  alternatives --set java /usr/lib/jvm/java-1.8.0-amazon-corretto.x86_64/jre/bin/java

}

function hail_build
{
  echo "Building Hail v.$HAIL_VERSION from source with Spark v.$SPARK_VERSION"
  export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk

  git clone "$REPOSITORY_URL"
  cd hail/hail/
  git checkout "$HAIL_VERSION"

  make install-on-cluster HAIL_COMPILE_NATIVES=1 SPARK_VERSION="$SPARK_VERSION"

  python3 -m pip install ipykernel
  python3 -m pip install jupyter
  python3 -m pip install pyspark==3.3.2

}

function hail_install
{

  echo "Installing Hail locally"

  cat <<- HAIL_PROFILE > "$HAIL_PROFILE"
export SPARK_HOME="/usr/lib/spark"
export PYSPARK_PYTHON="python3"
export PYSPARK_SUBMIT_ARGS="--conf spark.kryo.registrator=is.hail.kryo.HailKryoRegistrator --conf spark.serializer=org.apache.spark.serializer.KryoSerializer pyspark-shell"
export PYTHONPATH="\$SPARK_HOME/python:\$SPARK_HOME/python/lib/py4j-src.zip:\$PYTHONPATH"
HAIL_PROFILE

  cp "$PWD/build/libs/$JAR_HAIL" "$HAIL_ARTIFACT_DIR"
}

function cleanup()
{
  rm -rf /home/ec2-user/hail
  rm -rf /home/ec2-user/Python-3.10.2
  rm Python-3.10.2.tgz

}

#upgrade_python3
#install_prereqs
#hail_build
#hail_install
cleanup
