warpgate
========

A node.js distributed task processing service based on RabbitMQ.


``
LogTaskHandler = function() {}

LogTaskHandler.prototype.handleTask = function(task) {
    console.log(task.action)
}

warpgate = require('warpgate')

rabbitmqParams = {}

taskService = new warpgate.TaskService(rabbitmqParams, 'role', 'hostname')

taskService.setHandler('simple', new LogTaskHandler())

taskService.start()
``
