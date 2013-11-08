jade = require 'jade'

webmake = require 'webmake'
require 'webmake-coffee'

fs = require 'fs'
path = require 'path'
ZK = 
	ADDRESS : process.env.ZK_ADDRESS or 'localhost'
	PORT : process.env.ZK_PORT or 2181

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
		'.styl' :
			into : '.css'
			fn : (full_path,locals,next) ->
				fs.readFile full_path, 'utf8', (err,text) ->					
					return err if err

					stylus = (require 'stylus') text
					stylus.use (require 'colorspaces')()
					stylus.use (require 'nib')()

					stylus.render next


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
							console.log "saving #{file} into zookeeper"
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

							console.log result

							result.forEach saveFile

							watcher = fs.watch folder, (e,filename) ->
								saveFile filename

							client.once 'disconnected', ->
								watcher.close()
						# client.create "#{path}/#{data.role}_", item.buffer, zookeeper.CreateMode.EPHEMERAL_SEQUENTIAL, (err) ->
				client.connect()

			sync()
	webapp
