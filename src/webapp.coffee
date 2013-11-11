jade = require 'jade'
webmake = require 'webmake'
require 'webmake-coffee'
fs = require 'fs'
path = require 'path'

ZK = 
	ADDRESS : process.env.ZK_ADDRESS or 'localhost'
	PORT : process.env.ZK_PORT or 2181

[proto,addr,port] = process.env.ZK_PORT.split(':')
if port?
	ZK.ADDRESS = addr.substr(2)
	ZK.PORT = port

zookeeper = require 'node-zookeeper-client'

module.exports = (folder) ->
	transformers = 
		'.jade' :
			into : '.html' 
			fn : (full_path,locals,next) ->
				jade.renderFile full_path, locals, next
		'.coffee' : 
			into : '.js'
			fn : (full_path,locals,next) ->
				webmake full_path, {ext:['coffee'],sourceMap:true,cache:true}, (err,content) ->
					return next err if err		
						
					content = "(function () { locals = #{JSON.stringify(locals)}; #{content}; })();"
					next null, content

	webapp = (m,next) -> next m
	webapp.preuse = (ship) ->	
		ship.once 'launch', ->	
			sync = ->
				client = zookeeper.createClient "#{ZK.ADDRESS}:#{ZK.PORT}"
				client.once 'connected', ->	
					client.once 'disconnected', sync

					base_dir = "/webapps/#{ship.user.name}"

					client.mkdirp base_dir, (err) ->				
						save = (file,content,next) ->
							content = new Buffer(content)
							p = "#{base_dir}/#{file}"
							client.exists p, (err,stat) ->
								return next err if err
								if stat
									client.setData p, content, next
								else
									client.create p, content, next
							
						saveFile = (file) ->				
							full_path = "#{folder}/#{file}"
							ext = path.extname(file)
							T = transformers[ext]
							if T?
								T.fn full_path, {}, (err,content) ->
									unless err
										compiled = file.replace(ext,T.into)
										save compiled, content, (err) ->
											if err
												console.error "#{compiled} was not saved due to error", err
											else
												console.log "#{compiled} was saved"
									else
										console.error "couldn't transform #{file}", err
							else
								console.error 'unknown ext', path.extname(file)

						fs.readdir folder, (err,result) ->
							return if err

							result.forEach saveFile
						# client.create "#{path}/#{data.role}_", item.buffer, zookeeper.CreateMode.EPHEMERAL_SEQUENTIAL, (err) ->
				client.connect()

			sync()


		for ext, T of transformers
			do (ext,T) ->				
				ship.get new RegExp("\\#{T.into}"), (m,next) ->
					console.log 'getting!'
					T.fn folder + '/' + m.url.replace(T.into,ext), m.locals or {}, (err,result) ->
						if err
							console.log "#{ext} -> #{T.into} render error"
							console.log err
							return m.end() 
						m.end result		
	webapp
