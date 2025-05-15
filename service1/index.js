const express = require('express')
const app = express()
const port = 3001

app.get('/', (req, res) => {
  res.send('Hello World 1!')
})

app.listen(port, () => {
  console.log(`Service 1 listening on port ${port}`)
})