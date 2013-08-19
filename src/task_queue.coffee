clc     = require 'cli-color'
amqp    = require 'amqp'
util    = require 'util'
events  = require 'events'
Task    = require('./task').Task

# TaskQueue receives tasks from RabbitMQ
exports.TaskQueue = TaskQueue = (connectionParams, role, hostname) ->
  unless (role and hostname)
    return null

  this.connectionParams = connectionParams
  this.queueName = 'warpgate.host.' + hostname
  this.exchangeName = 'warpgate.role.' + role

  return this

util.inherits(TaskQueue, events.EventEmitter)

# TaskQueue.start() starts a task queue by complete the following in order:
# 1. Connects to RabbitMQ server
# 2. Create a queue based on hostname
# 3. Create an exchange based on role
# 4. Bind the newly created queue to the newly created exchange
# 5. Subscribe to the queue just created
TaskQueue.prototype.start = (callback) ->
  util.log('Connecting to RabbitMQ server...')
  connect(this)
    .on 'connected', (self) ->
      util.log('Declaring listen queue: ' + self.queueName)
      declareQueue(self, -> self.emit('queueOk', self))
    .on 'queueOk', (self) ->
      util.log('Declaring exchange: ' + self.exchangeName)
      declareExchange(self, -> self.emit('exchangeOk', self))
    .on 'exchangeOk', (self) ->
      util.log('Binding ' + self.queueName + ' to ' + self.exchangeName)
      bindExchange(self, -> self.emit('bindExchangeOk', self))
    .on 'bindExchangeOk', (self) ->
      util.log(clc.green('Ready'))
      subscribe(self)
      if callback
        callback()

TaskQueue.prototype.end = () ->
  if this.connection
    this.connection.end()

# TaskQueue's message handler, transform messages into Task objects.
# Task handlers can listen on the queue's 'task' event for incoming tasks.
TaskQueue.prototype.handleMessage = (message, header, delivderInfo, m) ->
  util.log 'Received: ' + JSON.stringify(message)
  if (message.id and message.action)
    task = new Task message, (isSuccess=true) ->
      if isSuccess
        m.acknowledge()
      else
        m.reject(true)
    this.emit 'task', task

# Clears the queue by deleting it and then recreating it.
TaskQueue.prototype.clear = (callback) ->
  self = this
  self.queue.destroy()
  declareQueue self, ->
    bindExchange self, ->
      subscribe(self)
      callback()

connect = (self) ->
  self.connection = amqp.createConnection(self.connectionParams)
    .on 'ready', () ->
      self.emit('connected', self)
    .on 'error', (err) ->
      util.log('Rabbit connection error: ' + err)
  return self

declareQueue = (self, callback) ->
  queueParams = {durable: true, exclusive: false, autoDelete: false}
  self.connection.queue self.queueName, queueParams, (queue) ->
    self.queue = queue
    callback()

declareExchange = (self, callback) ->
  exchangeParams = {durable: true, type: 'fanout', autoDelete: false}
  self.connection.exchange self.exchangeName, exchangeParams, (exchange) ->
    self.exchange = exchange
    callback()

bindExchange = (self, callback) ->
  self.queue.bind(self.exchangeName, '')
  self.queue.on 'queueBindOk', ->
    callback()

subscribe = (self) ->
  self.queue.subscribe({ack:true, prefetchCount: 0},
    (message, header, deliveryInfo, m) ->
      self.handleMessage(message, header, deliveryInfo, m)
  ).addCallback((ok)->
    self.consumerTag = ok.consumerTag
  )
