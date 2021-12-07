#
# Copyright 2019-2020 JetBrains s.r.o.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

FROM debian AS ideDownloader

# prepare tools:
RUN apt-get update
RUN apt-get install wget -y
# download IDE to the /ide dir:
WORKDIR /download
ARG downloadUrl
RUN wget -q $downloadUrl -O - | tar -xz
RUN find . -maxdepth 1 -type d -name * -execdir mv {} /ide \;

FROM amazoncorretto:11 as projectorGradleBuilder

ENV PROJECTOR_DIR /projector

# projector-server:
ADD projector-server $PROJECTOR_DIR/projector-server
WORKDIR $PROJECTOR_DIR/projector-server
ARG buildGradle
RUN if [ "$buildGradle" = "true" ]; then ./gradlew clean; else echo "Skipping gradle build"; fi
RUN if [ "$buildGradle" = "true" ]; then ./gradlew :projector-server:distZip; else echo "Skipping gradle build"; fi
RUN cd projector-server/build/distributions && find . -maxdepth 1 -type f -name projector-server-*.zip -exec mv {} projector-server.zip \;

FROM debian AS projectorStaticFiles

# prepare tools:
RUN apt-get update
RUN apt-get install unzip -y
# create the Projector dir:
ENV PROJECTOR_DIR /projector
RUN mkdir -p $PROJECTOR_DIR
# copy IDE:
COPY --from=ideDownloader /ide $PROJECTOR_DIR/ide
# copy projector files to the container:
ADD projector-docker/static $PROJECTOR_DIR
# copy projector:
COPY --from=projectorGradleBuilder $PROJECTOR_DIR/projector-server/projector-server/build/distributions/projector-server.zip $PROJECTOR_DIR
# prepare IDE - apply projector-server:
RUN unzip $PROJECTOR_DIR/projector-server.zip
RUN rm $PROJECTOR_DIR/projector-server.zip
RUN find . -maxdepth 1 -type d -name projector-server-* -exec mv {} projector-server \;
RUN mv projector-server $PROJECTOR_DIR/ide/projector-server
RUN mv $PROJECTOR_DIR/ide-projector-launcher.sh $PROJECTOR_DIR/ide/bin
RUN chmod 644 $PROJECTOR_DIR/ide/projector-server/lib/*

FROM debian:10

RUN true \
# Any command which returns non-zero exit code will cause this shell script to exit immediately:
   && set -e \
# Activate debugging to show execution details: all commands will be printed before execution
   && set -x \
# install packages:
    && apt-get update \
# packages for awt:
    && apt-get install libxext6 libxrender1 libxtst6 libxi6 libfreetype6 -y \
# packages for user convenience:
    && apt-get install git bash-completion -y \
# packages for IDEA (to disable warnings):
    && apt-get install procps -y \
# clean apt to reduce image size:
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /var/cache/apt

ARG downloadUrl

RUN true \
# Any command which returns non-zero exit code will cause this shell script to exit immediately:
    && set -e \
# Activate debugging to show execution details: all commands will be printed before execution
    && set -x \
# install specific packages for IDEs:
    && apt-get update \
    && if [ "${downloadUrl#*CLion}" != "$downloadUrl" ]; then apt-get install build-essential clang -y; else echo "Not CLion"; fi \
    && if [ "${downloadUrl#*pycharm}" != "$downloadUrl" ]; then apt-get install python2 python3 python3-distutils python3-pip python3-setuptools -y; else echo "Not pycharm"; fi \
    && if [ "${downloadUrl#*rider}" != "$downloadUrl" ]; then apt install apt-transport-https dirmngr gnupg ca-certificates -y && apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF && echo "deb https://download.mono-project.com/repo/debian stable-buster main" | tee /etc/apt/sources.list.d/mono-official-stable.list && apt update && apt install mono-devel -y && apt install wget -y && wget https://packages.microsoft.com/config/debian/10/packages-microsoft-prod.deb -O packages-microsoft-prod.deb && dpkg -i packages-microsoft-prod.deb && rm packages-microsoft-prod.deb && apt-get update && apt-get install -y apt-transport-https && apt-get update && apt-get install -y dotnet-sdk-3.1 aspnetcore-runtime-3.1; else echo "Not rider"; fi \
# clean apt to reduce image size:
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /var/cache/apt

# copy the Projector dir:
ENV PROJECTOR_DIR /projector
COPY --from=projectorStaticFiles $PROJECTOR_DIR $PROJECTOR_DIR

ENV PROJECTOR_USER_NAME projector-user

RUN true \
# Any command which returns non-zero exit code will cause this shell script to exit immediately:
    && set -e \
# Activate debugging to show execution details: all commands will be printed before execution
    && set -x \
# move run scipt:
    && mv $PROJECTOR_DIR/run.sh run.sh \
# change user to non-root (http://pjdietz.com/2016/08/28/nginx-in-docker-without-root.html):
  && useradd --uid 1000 --create-home --shell /bin/bash u1000 \
  && useradd --uid 1001 --create-home --shell /bin/bash u1001 \
  && useradd --uid 1002 --create-home --shell /bin/bash u1002 \
  && useradd --uid 1003 --create-home --shell /bin/bash u1003 \
  && useradd --uid 1004 --create-home --shell /bin/bash u1004 \
  && useradd --uid 1005 --create-home --shell /bin/bash u1005 \
  && useradd --uid 1006 --create-home --shell /bin/bash u1006 \
  && useradd --uid 1007 --create-home --shell /bin/bash u1007 \
  && useradd --uid 1008 --create-home --shell /bin/bash u1008 \
  && useradd --uid 1009 --create-home --shell /bin/bash u1009 \
  && useradd --uid 1010 --create-home --shell /bin/bash u1010 \
  && useradd --uid 1011 --create-home --shell /bin/bash u1011 \
  && useradd --uid 1012 --create-home --shell /bin/bash u1012 \
  && useradd --uid 1013 --create-home --shell /bin/bash u1013 \
  && useradd --uid 1014 --create-home --shell /bin/bash u1014 \
  && useradd --uid 1015 --create-home --shell /bin/bash u1015 \
  && useradd --uid 1016 --create-home --shell /bin/bash u1016 \
  && useradd --uid 1017 --create-home --shell /bin/bash u1017 \
  && useradd --uid 1018 --create-home --shell /bin/bash u1018 \
  && useradd --uid 1019 --create-home --shell /bin/bash u1019 \  
  && useradd --uid 1020 --create-home --shell /bin/bash u1020 \
  && useradd --uid 1021 --create-home --shell /bin/bash u1021 \
  && useradd --uid 1022 --create-home --shell /bin/bash u1022 \
  && useradd --uid 1023 --create-home --shell /bin/bash u1023 \
  && useradd --uid 1024 --create-home --shell /bin/bash u1024 \
  && useradd --uid 1025 --create-home --shell /bin/bash u1025 \
  && useradd --uid 1026 --create-home --shell /bin/bash u1026 \
  && useradd --uid 1027 --create-home --shell /bin/bash u1027 \
  && useradd --uid 1028 --create-home --shell /bin/bash u1028 \
  && useradd --uid 1029 --create-home --shell /bin/bash u1029 \
  && useradd --uid 1030 --create-home --shell /bin/bash u1030 \
  && useradd --uid 1031 --create-home --shell /bin/bash u1031 \
  && useradd --uid 1032 --create-home --shell /bin/bash u1032 \
  && useradd --uid 1033 --create-home --shell /bin/bash u1033 \
  && useradd --uid 1034 --create-home --shell /bin/bash u1034 \
  && useradd --uid 1035 --create-home --shell /bin/bash u1035 \
  && useradd --uid 1036 --create-home --shell /bin/bash u1036 \
  && useradd --uid 1037 --create-home --shell /bin/bash u1037 \
  && useradd --uid 1038 --create-home --shell /bin/bash u1038 \
  && useradd --uid 1039 --create-home --shell /bin/bash u1039 \  
  && useradd --uid 1040 --create-home --shell /bin/bash u1040 \  
  && echo "u1000 ALL=(ALL) NOPASSWD: ALL" | tee -a /etc/sudoers \
  && echo "u1001 ALL=(ALL) NOPASSWD: ALL" | tee -a /etc/sudoers \
  && echo "u1002 ALL=(ALL) NOPASSWD: ALL" | tee -a /etc/sudoers \
  && echo "u1003 ALL=(ALL) NOPASSWD: ALL" | tee -a /etc/sudoers \
  && echo "u1004 ALL=(ALL) NOPASSWD: ALL" | tee -a /etc/sudoers \
  && echo "u1005 ALL=(ALL) NOPASSWD: ALL" | tee -a /etc/sudoers \
  && echo "u1006 ALL=(ALL) NOPASSWD: ALL" | tee -a /etc/sudoers \
  && echo "u1007 ALL=(ALL) NOPASSWD: ALL" | tee -a /etc/sudoers \
  && echo "u1008 ALL=(ALL) NOPASSWD: ALL" | tee -a /etc/sudoers \
  && echo "u1009 ALL=(ALL) NOPASSWD: ALL" | tee -a /etc/sudoers \
  && echo "u1010 ALL=(ALL) NOPASSWD: ALL" | tee -a /etc/sudoers \
  && echo "u1011 ALL=(ALL) NOPASSWD: ALL" | tee -a /etc/sudoers \
  && echo "u1012 ALL=(ALL) NOPASSWD: ALL" | tee -a /etc/sudoers \
  && echo "u1013 ALL=(ALL) NOPASSWD: ALL" | tee -a /etc/sudoers \
  && echo "u1014 ALL=(ALL) NOPASSWD: ALL" | tee -a /etc/sudoers \
  && echo "u1015 ALL=(ALL) NOPASSWD: ALL" | tee -a /etc/sudoers \
  && echo "u1016 ALL=(ALL) NOPASSWD: ALL" | tee -a /etc/sudoers \
  && echo "u1017 ALL=(ALL) NOPASSWD: ALL" | tee -a /etc/sudoers \
  && echo "u1018 ALL=(ALL) NOPASSWD: ALL" | tee -a /etc/sudoers \
  && echo "u1019 ALL=(ALL) NOPASSWD: ALL" | tee -a /etc/sudoers \
  && echo "u1020 ALL=(ALL) NOPASSWD: ALL" | tee -a /etc/sudoers \
  && echo "u1021 ALL=(ALL) NOPASSWD: ALL" | tee -a /etc/sudoers \
  && echo "u1022 ALL=(ALL) NOPASSWD: ALL" | tee -a /etc/sudoers \
  && echo "u1023 ALL=(ALL) NOPASSWD: ALL" | tee -a /etc/sudoers \
  && echo "u1024 ALL=(ALL) NOPASSWD: ALL" | tee -a /etc/sudoers \
  && echo "u1025 ALL=(ALL) NOPASSWD: ALL" | tee -a /etc/sudoers \
  && echo "u1026 ALL=(ALL) NOPASSWD: ALL" | tee -a /etc/sudoers \
  && echo "u1027 ALL=(ALL) NOPASSWD: ALL" | tee -a /etc/sudoers \
  && echo "u1028 ALL=(ALL) NOPASSWD: ALL" | tee -a /etc/sudoers \
  && echo "u1029 ALL=(ALL) NOPASSWD: ALL" | tee -a /etc/sudoers \
  && echo "u1030 ALL=(ALL) NOPASSWD: ALL" | tee -a /etc/sudoers \
  && echo "u1031 ALL=(ALL) NOPASSWD: ALL" | tee -a /etc/sudoers \
  && echo "u1032 ALL=(ALL) NOPASSWD: ALL" | tee -a /etc/sudoers \
  && echo "u1033 ALL=(ALL) NOPASSWD: ALL" | tee -a /etc/sudoers \
  && echo "u1034 ALL=(ALL) NOPASSWD: ALL" | tee -a /etc/sudoers \
  && echo "u1035 ALL=(ALL) NOPASSWD: ALL" | tee -a /etc/sudoers \
  && echo "u1036 ALL=(ALL) NOPASSWD: ALL" | tee -a /etc/sudoers \
  && echo "u1037 ALL=(ALL) NOPASSWD: ALL" | tee -a /etc/sudoers \
  && echo "u1038 ALL=(ALL) NOPASSWD: ALL" | tee -a /etc/sudoers \
  && echo "u1039 ALL=(ALL) NOPASSWD: ALL" | tee -a /etc/sudoers \
  && echo "u1040 ALL=(ALL) NOPASSWD: ALL" | tee -a /etc/sudoers \    
    && mv $PROJECTOR_DIR/$PROJECTOR_USER_NAME /home \    
    && useradd -m -d /home/$PROJECTOR_USER_NAME -s /bin/bash $PROJECTOR_USER_NAME \
    && chown -R $PROJECTOR_USER_NAME.$PROJECTOR_USER_NAME /home/$PROJECTOR_USER_NAME \
    && chown -R $PROJECTOR_USER_NAME.$PROJECTOR_USER_NAME $PROJECTOR_DIR/ide/bin \
    && chown $PROJECTOR_USER_NAME.$PROJECTOR_USER_NAME run.sh

USER $PROJECTOR_USER_NAME
ENV HOME /home/$PROJECTOR_USER_NAME

EXPOSE 8887

CMD ["bash", "-c", "/run.sh"]
