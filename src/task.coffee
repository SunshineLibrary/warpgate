# Construct a task from a json msg and appropriate ack function
# task = new Task(json, ackFn)
#
# Acknowledge and remove the task from its TaskQueue
# task.done()
#
# Put task back onto its TaskQueue after 60 seconds.
# this.retry(60)

exports.Task = Task = (id, action, params, ackFn) ->
  this.id = id
  this.action = action
  this.params = params

  this.done = () ->
    ackFn()

  this.retry = (timeout=60) ->
    fn = ()->
      ackFn(false)
    setTimeout(fn, timeout * 1000)

  return this
