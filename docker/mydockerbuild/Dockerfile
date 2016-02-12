FROM docker/whalesay:latest

RUN apt-get -y update
RUN apt-get install -y fortunes

CMD /usr/games/fortune -a | cowsay
