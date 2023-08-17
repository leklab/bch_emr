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

function install_prereqs {
  mkdir -p "$HAIL_ARTIFACT_DIR"

  apt update

  NEEDRESTART_MODE=a apt-get install -y python-is-python3 \
  python3-pip \
  openjdk-8-jdk \
  liblz4-dev \
  awscli

  # Upgrade latest latest pip
  python3 -m pip install --upgrade pip

  #install here
  python3 -m pip install -U pyopenssl cryptography
  python3 -m pip install --ignore-installed -U pyasn1-modules

}

function hail_build
{
  echo "Building Hail v.$HAIL_VERSION from source with Spark v.$SPARK_VERSION"

  git clone "$REPOSITORY_URL"
  cd hail/hail/
  git checkout "$HAIL_VERSION"

  make install-on-cluster HAIL_COMPILE_NATIVES=1 SPARK_VERSION="$SPARK_VERSION"

  python3 -m pip install ipykernel
  python3 -m pip install jupyter

}

function hail_install
{

  echo "Installing Hail locally"

  cat <<- HAIL_PROFILE > "$HAIL_PROFILE"
  export SPARK_HOME="/usr/lib/spark"
  export PYSPARK_PYTHON="python3"
  export PYSPARK_SUBMIT_ARGS="--conf spark.kryo.registrator=is.hail.kryo.HailKryoRegistrator --conf spark.serializer=org.apache.spark.serializer.KryoSerializer pyspark-shell"
  export PYTHONPATH="$HAIL_ARTIFACT_DIR/$ZIP_HAIL:\$SPARK_HOME/python:\$SPARK_HOME/python/lib/py4j-src.zip:\$PYTHONPATH"
HAIL_PROFILE

  cp "$PWD/build/libs/$JAR_HAIL" "$HAIL_ARTIFACT_DIR"
  cp "$PWD/build/deploy/dist/$WHEEL_HAIL" "$HAIL_ARTIFACT_DIR"
}

function cleanup()
{
  rm -rf /home/ubuntu/hail
}

install_prereqs
hail_build
hail_install
cleanup
