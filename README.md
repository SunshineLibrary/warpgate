warpgate
========

A node.js distributed task processing service based on RabbitMQ.


```
// Define TaskHandler
LogTaskHandler = function() {}

LogTaskHandler.prototype.handleTask = function(task) {
    console.log(task.action)
}


// RabbitMQ connection params; Use default if empty.
rabbitmqParams = {}

// Config and start TaskService
TaskService = require('warpgate').TaskService

taskService = new TaskService(rabbitmqParams, 'role', 'hostname')

taskService.setHandler('log', new LogTaskHandler())

taskService.start()
```
