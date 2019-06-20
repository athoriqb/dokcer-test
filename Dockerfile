# Jenkins comes with JDK8
FROM jenkins/jenkins:lts

# Set desired Android Linux SDK version
ENV ANDROID_SDK_VERSION 4333796

ENV ANDROID_SDK_ZIP sdk-tools-linux-$ANDROID_SDK_VERSION.zip
ENV ANDROID_SDK_ZIP_URL https://dl.google.com/android/repository/$ANDROID_SDK_ZIP
ENV ANDROID_HOME /opt/android-sdk-linux

ENV GRADLE_ZIP gradle-5.0-bin.zip
ENV GRADLE_ZIP_URL https://services.gradle.org/distributions/$GRADLE_ZIP

ENV PATH $PATH:$ANDROID_HOME/tools
ENV PATH $PATH:$ANDROID_HOME/platform-tools
ENV PATH $PATH:/opt/gradle-5.0/bin

# Set Maven Version
ENV MAVEN_ZIP apache-maven-3.3.9-bin.zip
ENV MAVEN_ZIP_URL https://www-us.apache.org/dist/maven/maven-3/3.3.9/binaries/$MAVEN_ZIP

ENV MAVEN_HOME /opt/apache-maven-3.3.9
ENV PATH $PATH:$MAVEN_HOME/bin
ENV PATH $PATH:/docker-java-home/bin

# Set path jenkins home
ENV JENKINS_HOME=/var/jenkins_home

# Set desired appium
ARG APPIUM_VERSION=1.12.1
ENV APPIUM_VERSION=$APPIUM_VERSION

USER root

# Init dependencies for the setup process
RUN dpkg --add-architecture i386
RUN apt-get update \
  && apt-get upgrade -y \
  && apt-get install software-properties-common unzip -y \
  && apt-get install -y git curl \
  && apt-get install -y vim \
  && apt-get install -y wget \
#  && apt-get install -y maven \
  && apt-get install -y zip

## Install maven
#RUN mvn -version
ADD $MAVEN_ZIP_URL /opt/
RUN unzip /opt/$MAVEN_ZIP -d /opt/ && \
    rm /opt/$MAVEN_ZIP

# Install gradle
ADD $GRADLE_ZIP_URL /opt/
RUN unzip /opt/$GRADLE_ZIP -d /opt/ && \
	rm /opt/$GRADLE_ZIP

# Install Android SDK
RUN mkdir -p /opt/android-sdk-linux
ADD $ANDROID_SDK_ZIP_URL /opt/android-sdk-linux
RUN unzip /opt/android-sdk-linux/$ANDROID_SDK_ZIP -d /opt/android-sdk-linux && \
	rm /opt/android-sdk-linux/$ANDROID_SDK_ZIP

# Install required build-tools
RUN cd /opt/android-sdk-linux \
#  && touch ~/.android/repositories.cfg \
  && yes | tools/bin/sdkmanager --licenses \
  && tools/bin/sdkmanager "tools" \
  && tools/bin/sdkmanager "platform-tools" \
  && tools/bin/sdkmanager "platforms;android-27" \
  && tools/bin/sdkmanager "build-tools;27.0.3" \
  && tools/bin/sdkmanager "patcher;v4" \
  && chmod -R 755 $ANDROID_HOME

# Install 32-bit compatibility for 64-bit environments
RUN apt-get install libc6:i386 libncurses5:i386 libstdc++6:i386 zlib1g:i386 -y

#====================================
# Install latest nodejs, npm, appium
# Using this workaround to install Appium -> https://github.com/appium/appium/issues/10020 -> Please remove this workaround asap
#====================================

RUN curl -sL https://deb.nodesource.com/setup_10.x | bash && \
    apt-get -qqy install nodejs && \
    npm install -g appium@${APPIUM_VERSION} --unsafe-perm=true --allow-root && \
    npm install -g appium-doctor && \
    exit 0 && \
    npm cache clean && \
    apt-get remove --purge -y npm && \
    apt-get autoremove --purge -y

#Permission nodemodules
RUN chmod -R a+rwx /usr/lib/node_modules/appium

# Cleanup
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
	
USER jenkins

# List desired Jenkins plugins here
RUN /usr/local/bin/install-plugins.sh \
   apache-httpcomponents-client-4-api \
   cucumber-testresult-plugin \
   cucumber-living-documentation \
   cucumber \
   cucumber-reports \
   gradle \
   htmlpublisher \
   junit \
   mailer \
   maven-plugin \
   pipeline-github \
   pipeline-maven \
   dashboard-view \
   pipeline-stage-view \
   parameterized-trigger \
   open-stf \
   git \
   github-oauth \
   github

# Copy credential github to jenkins_home
COPY credentials.xml "$JENKINS_HOME"

#
#USER root
#
## fix permission issue
#RUN chown -R jenkins:jenkins $ANDROID_HOME
#
#USER jenkins