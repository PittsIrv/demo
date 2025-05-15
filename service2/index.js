const express = require('express')
const app = express()
const port = 3002

app.get('/', (req, res) => {
  res.send('Hello World 2!')
})

app.listen(port, () => {
  console.log(`Service 2 listening on port ${port}`)
})