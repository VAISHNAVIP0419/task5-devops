const express = require('express');
const todos = require('./data/todos.json');
const app = express();

app.get('/', (req, res) => {
  res.json({ message: "Simple Todo App", todos });
});

app.listen(3000, () => {
  console.log("Todo app running on port 3000");
});