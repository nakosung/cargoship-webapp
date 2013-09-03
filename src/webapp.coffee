jade = require 'jade'
Coffeescript = require 'coffee-script'
fs = require 'fs'

module.exports = (folder) ->
	webapp = (m,next) -> next m
	webapp.preuse = (ship) ->		
		ship.get /\.html$/, (m,next) ->
			jade.renderFile folder + '/' + m.url.replace('.html','.jade'), (err,result) ->
				return m.end() if err
				m.end result

		ship.get /\.js$/, (m,next) ->
			fs.readFile folder + '/' + m.url.replace('.js','.coffee'), (err,result) ->
				return m.end() if err		
				m.end Coffeescript.compile String(result)		
	webapp