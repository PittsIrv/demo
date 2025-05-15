FROM node:18-alpine

WORKDIR /usr/src/app
COPY package.json package-lock.json ./
RUN npm ci --only=production

COPY . .
EXPOSE 3002

CMD ["node", "index.js"]