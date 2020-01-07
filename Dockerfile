FROM mhart/alpine-node:13
EXPOSE 1234

RUN mkdir /www
WORKDIR /www

# git n'est pas inclus dans alpine
RUN apk add --no-cache git

RUN git clone https://github.com/nbouteme/p8chan
RUN git clone https://github.com/nbouteme/p8chan-frontend

WORKDIR /www/p8chan-frontend
# workaround d'un bug, je sais pas pourquoi ca se produit, mais angular se plaint de pas trouver  @angular-devkit/build-angular
RUN npm i --only=dev
RUN npm i
RUN npm i -g @angular/cli
# Partage de définition de types entre le frontend et backend
RUN rm src/apiv1.ts
RUN ln -s ../../p8chan/src/apiv1.ts src/apiv1.ts
RUN ng build --prod

WORKDIR /www/p8chan

# hack: je pensais pas avoir à changer la config, sinon je l'aurais au
# moins rendu parametrable avec des variables d'environnement, vu que
# la deadline est passée, je vais pas modifier le code du repo github

# J'avais mis 127.0.0.1 parce que seulement nginx proxy les requetes
# vers l'app, donc elle avait pas besoin d'écouter sur 0.0.0.0, mais
# je suppose que pour docker, elle doit accepter les connexions de n'importe quel interface
RUN sed -i 's/127.0.0.1/0.0.0.0/' src/main.ts
# mongo est dans un conteneur séparé considéré comme une machine distincte avec le nom d'hote "mongo" (défini dans le compose) 
RUN sed -i 's/\/home\/lillie\/p8\/p8chan/\/www\/p8chan-frontend/;s/127.0.0.1/mongo/' src/settings.ts
RUN npm i
RUN npm i typescript@3.7.2 --save
RUN npm i -g typescript@3.7.2 --save
RUN tsc -v
RUN tsc

WORKDIR /www/p8chan/dist

# Encore un hack: comme on ne peut pas savoir
# quand  mongo est  disponible et  que l'app  n'est pas  programmée pour
# tenter de se reconnecter en cas d'échec, j'attends 5 secondes avant de lancer l'app

CMD ["/bin/sh", "-c", "sleep 5 && node ./main.js"]
