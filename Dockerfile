FROM debian:stretch

# Superset version
ARG SUPERSET_VERSION=0.26.3

# Configure environment
ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    PYTHONPATH=/etc/superset:/home/superset:$PYTHONPATH \
    SUPERSET_REPO=apache/incubator-superset \
    SUPERSET_VERSION=${SUPERSET_VERSION} \
    SUPERSET_HOME=/var/lib/superset

# Create superset user & install dependencies
RUN useradd -U -m superset && \
    mkdir /etc/superset  && \
    mkdir ${SUPERSET_HOME} && \
    chown -R superset:superset /etc/superset && \
    chown -R superset:superset ${SUPERSET_HOME} && \
    apt-get update && \
    apt-get install -y \
        build-essential \
        curl \
        default-libmysqlclient-dev \
        libffi-dev \
        libldap2-dev \
        libpq-dev \
        libsasl2-dev \
        libssl-dev \
        python3-dev \
	python3-venv \
        python3-pip && \
    apt-get clean && \
    rm -r /var/lib/apt/lists/*
RUN python3 -m venv superset_env
WORKDIR superset_env
RUN /bin/bash -c "source bin/activate"  && curl https://raw.githubusercontent.com/${SUPERSET_REPO}/${SUPERSET_VERSION}/requirements.txt -o requirements.txt 
RUN pip3 install pybigquery \
    	 	 superset==${SUPERSET_VERSION} \
		 idna==2.6 \
		 pyasn1==0.4.2

# Configure Filesystem
# COPY superset /usr/local/bin
VOLUME /home/superset \
       /etc/superset \
       /var/lib/superset
WORKDIR /home/superset

# COPY creds.json /var/lib/superset/
ENV GOOGLE_APPLICATION_CREDENTIALS /var/lib/superset/creds.json

# Deploy application
EXPOSE 8088
HEALTHCHECK CMD ["curl", "-f", "http://localhost:8088/health"]
CMD ["gunicorn", "-w", "2", "--timeout", "60", "-b", "0.0.0.0:8088", "--limit-request-line", "0", "--limit-request-field_size", "0", "superset:app"]
USER superset
