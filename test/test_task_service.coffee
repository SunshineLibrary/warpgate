assert = require 'assert'
TaskService = require('../src/task_service').TaskService

describe 'TaskService', ->

  describe 'on start', ->
    service = new TaskService({}, 'local', 'localhost')

    before ->
      service.start()

    after ->
      service.end()

    it 'should create task queue', ->
      assert(service.taskQueue != null)

    it 'should start task queue', (done) ->
      service.taskQueue.once 'bindExchangeOk', ->
        done()

    it 'should be started', ->
      assert(service.started)

  describe 'handle message', ->
    service = null

    SimpleHandler = (done) ->
      this.handleTask = (task) ->
        done()
      return this

    beforeEach ->
      service = new TaskService({}, 'local', 'localhost')

    afterEach ->
      service.end()
      service = null

    it 'should use the correct handler', (done) ->
      service.setHandler('simple', new SimpleHandler(done))
      service.handleTask({id: 1, action: 'simple'})

    it 'handles message correctly', (done) ->
      service.setHandler('simple', new SimpleHandler(done))
      service.start(->
        service.taskQueue.exchange.publish '', {id: 1, action: 'simple'}
      )

    it 'should disallow setting handler after start', ->
      service.started = true
      assert.throws( ->
        service.setHandler('simple', new SimpleHandler(done))
      , Error)

