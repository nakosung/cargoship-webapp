jade = require 'jade'
webmake = require 'webmake'
require 'webmake-coffee'
fs = require 'fs'

module.exports = (folder) ->
	webapp = (m,next) -> next m
	webapp.preuse = (ship) ->		
		ship.get /\.html$/, (m,next) ->
			jade.renderFile folder + '/' + m.url.replace('.html','.jade'), (err,result) ->
				if err
					console.log "HTML render error"
					console.log err
					return m.end() 
				m.end result

		ship.get /\.js$/, (m,next) ->
			webmake folder + '/' + m.url.replace('.js','.coffee'), {ext:['coffee'],sourceMap:true,cache:true}, (err,content) ->
				if err		
					console.log "JS render error"
					console.log err
					return m.end() 
				m.end content
	webapp