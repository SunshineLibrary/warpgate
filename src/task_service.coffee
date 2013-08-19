clc = require 'cli-color'
util = require 'util'
events = require 'events'
TaskQueue = require('./task_queue').TaskQueue

# TaskService listens on a task queue and selects appropriate TaskHandler
# to handle incoming tasks.
exports.TaskService = TaskService = (connectionParams, role, hostname) ->
  this.started = false
  this.handlers = {}
  this.role = role
  this.hostname = hostname
  this.taskQueue = new TaskQueue(connectionParams, role, hostname)
  return this

TaskService.prototype.start = (callback) ->
  self = this
  self.taskQueue.removeAllListeners('data')
  self.taskQueue.on 'task', (task) ->
    self.handleTask(task)
  self.taskQueue.start(->
    self.started = true
    if (callback)
      callback()
  )


TaskService.prototype.end = () ->
  this.taskQueue.end()

TaskService.prototype.handleTask = (task) ->
  handler = this.handlers[task.action]
  if handler
    handler.handleTask(task)
  else
    util.log("TaskService: No handler found for action[" + task.action + "]")

TaskService.prototype.setHandler = (action, handler) ->
  if this.started
    throw new Error('TaskService: You must set handlers before calling start() ')
  if action and handler
    this.handlers[action] = handler

TaskService.prototype.removeHandler = (action) ->
  if action and this.handlers[action]
    delete handler[action]
