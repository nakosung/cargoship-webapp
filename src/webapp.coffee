jade = require 'jade'
webmake = require 'webmake'
require 'webmake-coffee'
fs = require 'fs'

module.exports = (folder) ->
	webapp = (m,next) -> next m
	webapp.preuse = (ship) ->		
		ship.get /\.html$/, (m,next) ->
			jade.renderFile folder + '/' + m.url.replace('.html','.jade'), (err,result) ->
				return m.end() if err
				m.end result

		ship.get /\.js$/, (m,next) ->
			webmake folder + '/' + m.url.replace('.js','.coffee'), {ext:['coffee'],sourceMap:true,cache:true}, (err,content) ->
				return m.end() if err		
				m.end content
	webapp