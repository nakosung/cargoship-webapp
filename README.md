cargoship-webapp
================

Cargoship-webapp is an extension to cargoship which provides web-app interface to your cargoship server block.

Usage
-----

```coffeescript
cargoship = require 'cargoship'
ship = cargoship()
ship.use (require 'cargoship-webapp') __dirname + '/webapp'
```
