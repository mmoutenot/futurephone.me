if typeof define isnt 'function' then define = require('amdefine')(module)
define [
  'moment'
  'express'
  'cookie-parser'
  'express-session'
  'body-parser'
  'multer'
  'twilio'
  'nsq-client'
  './helpers'
  './models/message'
  './models/user'
  './models/login_token'
], (
  moment, express, cookieParser, session, bodyParser, multer, Twilio,
  NSQClient, helpers, Message, User, LoginToken
) ->
  class WebServer

    constructor: ->
      @app = express()

      @app.use require("connect-assets")()
      @app.use cookieParser()
      @app.use(bodyParser.urlencoded({ extended: true }))
      @app.use(bodyParser.json())
      # TODO Using in memory session store, change for production
      @sessionStore = new session.MemoryStore()
      @app.use session
        secret: 'thisismysupersecret'
        store: @sessionStore
        resave: true
        saveUninitialized: true

      #TODO maybe use limits and rename options (https://github.com/expressjs/multer)
      @app.use multer dest: './uploads/'

      @app.use express.static __dirname + '/assets'
      @app.use '/uploads', express.static __dirname + '/uploads'

      helpers.debug 'debug mode enabled'

      # NSQ setup
      @nsq = new NSQClient
        hostname: helpers.NSQ_HOSTNAME
        debug: helpers.DEBUG

      @app.use helpers.outputRequestRoute
      @app.use helpers.requireAuthentication

      ###### TWILIO
      @twilio = Twilio helpers.TWILIO_ACCOUNT_SID, helpers.TWILIO_AUTH_TOKEN

      ###### DB
      mongoose = require './db'
      Message = require './models/message'
      User = require './models/user'

      @helpers = helpers

      @registerRoutes()
      @server = @startServer()

    startServer: ->
      appPort = helpers.PORT
      server = @app.listen appPort, ->
        console.log 'Listening on port %d', server.address().port
      server

    registerRoutes: ->
      @app.post '/twilio/callback', (req, res) ->
        messageId = req.query.message_id
        return res.send 422 unless messageId

        Message.findById messageId, (err, message) ->
          if err
            console.log err
            res.send 500
          else
            resp = new Twilio.TwimlResponse()
            resp.play message.media_uri

            message.completed_at = moment()._d
            message.state = helpers.MSG_STATE_COMPLETED

            message.save (err, message) ->
              res.header('Content-Type','text/xml').send resp.toString()

      @app.get '/seed', (req, res) ->
        userDatas = [{
            phone_number: '16155197142'
            password: '1234'
          },
          {
            phone_number: '12069638669'
            password: '1234'
          }]

        for userData in userDatas
          user = new User userData
          user.save (err, user) ->
            if err
              console.error err
            else
              helpers.debug 'seeded database with user: ' + user

          messageDatas = [{
            deliver_at: moment()._d
            original_media_path: 'fixtures/first_call.mp3'
            _user: user._id
          }]

          for messageData in messageDatas
            message = new Message messageData
            message.save (err, message) ->
              if err
                console.error err
              else
                helpers.debug 'seeded database with message: ' + message

        res.send 200

      # Login Step 1: Takes a phone_number param and sends it a validation code
      @app.post '/login/phone_number', (req, res) =>
        # went you hit this route you are logged out of any previous session
        req.session.loggedIn = false
        phone = req.body.phone_number
        token = helpers.randomToken()
        persistToken = LoginToken.create
                         phone_number: phone
                         token: token
                         expires: moment().add 'minutes', 2

        persistToken.then (loginToken, err) =>
          @twilio.sendMessage {
            from: helpers.TWILIO_FROM_PHONE
            to: phone
            body: "Hi! Enter #{ token } in Future Phone to log in."
          }, (err, response) ->
            if err
              helpers.debug err
              res.send 400
            else
              res.send 200

      # Login Step 2: Takes a login_token and phone_number and responds
      # with a session key if the token is valid
      @app.post '/login/validate_token', (req, res) =>
        phoneNumber = req.body.phone_number
        token = req.body.token
        findToken = LoginToken.findOne
          phone_number: phoneNumber
          token: token
          expires:
            $gt: moment()
        findToken.exec().then (token, err) ->
          if token
            req.session.loggedIn = true
            user = { phone_number: phoneNumber }
            User.create user, user, { upsert: true }, (err, numUpdated, rawResponse) ->
              helpers.debug "successfully logged in #{ phoneNumber }"
              res.send 200
          else
            res.send 404

      # Returns 200 if the user is logged in, else 404. Relies on
      # authentication middleware to reject unauthenticated requests.
      @app.get '/logged_in', (req, res) ->
        res.send 200

      @app.post '/messages', (req, res) =>
        params = req.body
        return res.send 422 unless params.delivery_unit and
          params.delivery_magnitude and
          params.phone_number and
          Object.keys(req.files).length is 1

        for key, file of req.files
          # we just want the first file, so we immediately return
          helpers.debug "File uploaded to #{ file.path }"

        deliver_at = helpers.calculateFutureDelivery params.delivery_unit, params.delivery_magnitude
        findUser = User.findOne phone_number: params.phone_number
        findUser.exec().then (user, err) =>
          return res.send 401 unless user

          messageParams =
            deliver_at: deliver_at._d
            original_media_path: file.path
            state: helpers.MSG_STATE_CREATED
            _user: user

          message = new Message messageParams
          message.save (err, message) =>
            if err
              console.error err
              res.send 500
            else
              helpers.debug 'created: ' + message
              @nsq.publish helpers.CONVERTER_TOPIC,
                message: message
              res.send 201

      @app.post '/logout', (req, res) ->
        req.session.destroy (err) ->
          res.send 200

  module.exports = new WebServer()
