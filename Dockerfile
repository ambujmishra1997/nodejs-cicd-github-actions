FROM node:24-alpine

WORKDIR /app

COPY src/package*.json ./

RUN npm ci --omit=dev

COPY src/ .

ENV NODE_ENV=production

EXPOSE 3000

USER node

CMD ["npm", "start"]