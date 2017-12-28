FROM openjdk:8-jre

ENV ARDOR_VERSION="2.0.8e"
ENV ARDOR_SIGNING_KEY_ID="0xc654d7fcff18fd55"

# Install prerequisites
RUN apt-get update \
    && apt-get -y install curl unzip gettext tree \
    && rm -rf /var/lib/apt/lists

# Install AWS CLI
RUN apt-get update \
    && apt-get -y install python \
    && cd /tmp \
    && curl -L "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip" \
    && unzip awscli-bundle.zip \
    && ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws \
    && rm awscli-bundle.zip \
    && rm -rf awscli-bundle \
    && rm -rf /var/lib/apt/lists

# Install Ardor client
RUN cd /tmp \
    && curl -L "https://bitbucket.org/Jelurida/ardor/downloads/ardor-client-${ARDOR_VERSION}.zip" -o "ardor-client-${ARDOR_VERSION}.zip" \
    && curl -L "https://bitbucket.org/Jelurida/ardor/downloads/ardor-client-${ARDOR_VERSION}.zip.asc" -o "ardor-client-${ARDOR_VERSION}.zip.asc" \
    && gpg --keyserver pgpkeys.mit.edu --recv-keys ${ARDOR_SIGNING_KEY_ID} \
    && gpg --verify ardor-client-${ARDOR_VERSION}.zip.asc ardor-client-${ARDOR_VERSION}.zip \
    && unzip ardor-client-${ARDOR_VERSION}.zip \
    && mv ardor /opt/ \
    && rm ardor-client-${ARDOR_VERSION}.zip ardor-client-${ARDOR_VERSION}.zip.asc

# Add startup script and properties template
ADD ardor.sh /opt/ardor/ardor.sh
ADD ardor.properties.template /opt/ardor/conf/ardor.properties.template
ADD ardor-default.env /opt/ardor/conf/ardor-default.env

RUN ["chmod", "+x", "/opt/ardor/ardor.sh"]

# Expose default ports
EXPOSE 7874 7875 7876 443 27874 26876 26877

# Run startup script by default
CMD ["/opt/ardor/ardor.sh"]