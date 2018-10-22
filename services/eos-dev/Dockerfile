FROM eosio/eos-dev:v1.2.4

RUN apt-get update && apt-get install curl -y

# RUN ["cp", "-r", "/contracts", "/opt/eosio/bin/config-dir"]

# RUN echo "Initializing Chain Data, Contracts and Accounts"
# RUN /bin/bash /opt/eosio/bin/init_chain.sh

COPY ./ /opt/application

VOLUME /opt/application

WORKDIR /opt/eosio/bin

CMD /opt/application/start.sh
