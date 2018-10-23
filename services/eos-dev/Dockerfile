FROM eosio/eos-dev:v1.2.4

RUN apt-get update && apt-get install curl -y

COPY ./ /opt/application

VOLUME /opt/application

WORKDIR /opt/eosio/bin

# used by start.sh
ENV DATA_DIR /root/.local/share 
ENV CONFIG_DIR /opt/application/config

CMD /opt/application/start.sh
