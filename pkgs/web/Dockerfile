FROM node:10 AS mokonnet

WORKDIR /usr/src/app

COPY package*.json ./
RUN npm install

COPY . .
EXPOSE 8443

CMD [ "node", "src/index.js" ]
