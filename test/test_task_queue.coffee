assert = require 'assert'
TaskQueue = require('../src/task_queue').TaskQueue

describe 'TaskQueue', ->
  queue= new TaskQueue({}, 'local', 'localhost')

  after () ->
    queue.end()

  describe 'on creation', ->
    it 'should set queue name', ->
      assert.equal('warpgate.host.localhost', queue.queueName)
      assert.equal('warpgate.role.local', queue.exchangeName)

  describe 'on start', ->

    before ()->
      queue.start()

    it 'should connect', (done) ->
      queue.on 'connected', -> done()

    it 'should declare queue', (done) ->
      queue.on 'queueOk', -> done()

    it 'should declare exchange', (done) ->
      queue.on 'exchangeOk', -> done()

    it 'should bind exchange', (done) ->
      queue.on 'bindExchangeOk', -> done()

  describe 'on message', ->
    beforeEach (done)->
      queue.clear(done)

    afterEach ()->
      queue.removeAllListeners 'task'

    after (done)->
      queue.clear(done)

    it 'should offer task', (done) ->
      queue.exchange.publish '', {},
        {appId: 'warpgate', messageId: '1', type: 'hello'}
      queue.once 'task', (task) ->
        assert.equal(task.action, 'hello')
        done()

    it 'should ignore non-task messages', (done) ->
      queue.exchange.publish '', {}
      queue.exchange.publish '', 'hello', {appId: 'warpgate'}
      queue.once 'task', ->
        assert(false, 'should not reach here')
      setTimeout(done, 100)

    it 'should requeue task on failure', (done) ->
      queue.exchange.publish '', {},
        {appId: 'warpgate', messageId: '1', type: 'hello'}
      queue.once 'task', (task) ->
        task.retry(0.1)
        queue.once 'task', (task) ->
          assert.equal(task.action, 'hello')
          done()

    it 'should acknowlege task on success', (done) ->
      queue.exchange.publish '', {},
        {appId: 'warpgate', messageId: '1', type: 'hello'}
      queue.once 'task', (task) ->
        task.done()
        setTimeout(done, 100)
        queue.once 'task', (task) ->
          assert(false, 'should not reach here')
