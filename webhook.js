// webhook.js
const express = require('express')
const crypto = require('crypto')
const app = express()

const SECRET = process.env.GITHUB_WEBHOOK_SECRET

app.use(express.json({
  verify: (req, res, buf) => { req.rawBody = buf }
}))

function verifySignature(req) {
  const sig = req.headers['x-hub-signature-256']
  if (!sig || !SECRET) return false
  const expected = 'sha256=' + crypto
    .createHmac('sha256', SECRET)
    .update(req.rawBody)
    .digest('hex')
  return crypto.timingSafeEqual(Buffer.from(expected), Buffer.from(sig))
}

app.post('/webhook', (req, res) => {
  if (!verifySignature(req)) {
    console.log('Rejected: invalid or missing signature')
    return res.sendStatus(403)
  }

  console.log('\n--- GitHub Event ---')
  console.log('Headers:', JSON.stringify(req.headers, null, 2))
  console.log('Event:', req.headers['x-github-event'])
  console.log(JSON.stringify(req.body, null, 2))
  res.sendStatus(200)
})

app.listen(3000, () => console.log('Listening on :3000'))