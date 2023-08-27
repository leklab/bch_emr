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

  dnf install -y python-is-python3 \
  java-1.8.0-amazon-corretto-devel \
  lz4-devel \
  git \
  R

  dnf remove -y awscli

  # Upgrade latest latest pip
  python3 -m ensurepip
  python3 -m pip install --upgrade pip

  #install here
  python3 -m pip install --ignore-installed -U requests

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
}

install_prereqs
hail_build
hail_install
cleanup
