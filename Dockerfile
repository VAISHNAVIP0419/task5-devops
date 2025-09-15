# Simple Node.js Todo App Dockerfile
FROM node:18-alpine

WORKDIR /app

COPY package.json ./
RUN npm install

COPY simple_todo_app/ ./simple_todo_app/

EXPOSE 3000

CMD ["node", "simple_todo_app/src/app.js"]