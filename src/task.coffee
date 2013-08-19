# Construct a task from a json msg and appropriate ack function
# task = new Task(json, ackFn)
#
# Acknowledge and remove the task from its TaskQueue
# task.done()
#
# Put task back onto its TaskQueue after 60 seconds.
# this.retry(60)

exports.Task = Task = (msg, ackFn) ->
  this.id = msg .id
  this.action = msg.action
  this.src = msg.src
  this.dest = msg.dest
  this.params= msg.params

  this.done = () ->
    ackFn()

  this.retry = (timeout=60) ->
    fn = ()->
      ackFn(false)
    setTimeout(fn, timeout * 1000)

  return this
